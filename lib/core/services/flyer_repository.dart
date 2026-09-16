import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../config/app_config.dart';
import 'api_client.dart';
import 'city_repository.dart';
import 'store_repository.dart';

class FlyerState {
  final List<Flyer> flyers;
  final List<FlyerPage> pages;
  final bool isLoading;

  const FlyerState({
    required this.flyers,
    required this.pages,
    this.isLoading = false,
  });

  FlyerState copyWith({
    List<Flyer>? flyers,
    List<FlyerPage>? pages,
    bool? isLoading,
  }) {
    return FlyerState(
      flyers: flyers ?? this.flyers,
      pages: pages ?? this.pages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FlyerNotifier extends StateNotifier<FlyerState> {
  final Ref _ref;
  final ApiClient _apiClient;

  FlyerNotifier(this._ref, this._apiClient)
      : super(const FlyerState(
          flyers: [],
          pages: [],
          isLoading: false,
        ));

  // Helper url since flyers are mapped at /api/flyers (outside /api/dealspot)
  String get _flyerBaseUrl => '${AppConfig.serverUrl}/api/flyers';

  Future<void> fetchFlyers({int? storeId}) async {
    state = state.copyWith(isLoading: true);
    try {
      final queryParams = <String, dynamic>{};
      if (storeId != null) queryParams['storeId'] = storeId;

      final response = await _apiClient.get(
        '$_flyerBaseUrl/fetch-all-flyers',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = <Flyer>[];
        for (final item in rawList) {
          if (item is Map<String, dynamic>) {
            try {
              list.add(Flyer.fromJson(item));
            } catch (e) {
              // Ignore single item error
            }
          }
        }
        state = state.copyWith(flyers: list, isLoading: false);
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  List<Flyer> getFlyers([int? cityId]) {
    var list = state.flyers.where((f) => f.isActive == 1).toList();
    if (cityId != null && cityId > 0) {
      list = list.where((f) {
        final cId = f.cityId != 0 ? f.cityId : (f.store?.cityId ?? 0);
        return cId == 0 || cId == cityId;
      }).toList();
    }
    return list.map((f) => _populateFlyer(f)).toList();
  }


  Flyer? getFlyerById(int id) {
    try {
      final idx = state.flyers.indexWhere((f) => f.id == id);
      if (idx == -1) {
        fetchFlyerById(id);
        return null;
      }

      final flyer = state.flyers[idx];
      return _populateFlyer(flyer);
    } catch (_) {
      return null;
    }
  }

  Future<Flyer?> fetchFlyerById(int id) async {
    try {
      final response = await _apiClient.get('$_flyerBaseUrl/fetch-flyer/$id');
      if (response.statusCode == 200 && response.data != null) {
        final flyer = Flyer.fromJson(response.data as Map<String, dynamic>);
        final list = [...state.flyers];
        final idx = list.indexWhere((f) => f.id == id);
        if (idx != -1) {
          list[idx] = flyer;
        } else {
          list.add(flyer);
        }

        List<FlyerPage> updatedPages = [...state.pages];
        if (flyer.pages != null && flyer.pages!.isNotEmpty) {
          final flyerPagesWithId = flyer.pages!.map((p) => p.flyerId == 0 ? p.copyWith(flyerId: id) : p).toList();
          final otherPages = updatedPages.where((p) => p.flyerId != id && p.flyerId != 0).toList();
          updatedPages = [...otherPages, ...flyerPagesWithId];
        }
        state = state.copyWith(flyers: list, pages: updatedPages);
        return _populateFlyer(flyer);
      }
    } catch (_) {}
    return null;
  }

  Future<List<FlyerPage>> fetchFlyerPages(int flyerId) async {
    try {
      final response = await _apiClient.get('$_flyerBaseUrl/$flyerId/pages');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => FlyerPage.fromJson(e as Map<String, dynamic>, flyerId)).toList();
        final otherPages = state.pages.where((p) => p.flyerId != flyerId && p.flyerId != 0).toList();
        state = state.copyWith(pages: [...otherPages, ...list]);
        return list;
      }
    } catch (_) {}
    return state.pages.where((p) => p.flyerId == flyerId).toList();
  }

  Flyer _populateFlyer(Flyer f) {
    final store = _ref.read(storeRepositoryProvider.notifier).getStoreById(f.storeId);
    final cities = _ref.read(cityRepositoryProvider).cities;
    final pages = state.pages.where((p) => p.flyerId == f.id).toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    return f.copyWith(
      store: f.store ?? store,
      city: f.city ?? cities.where((c) => c.id == f.cityId).firstOrNull,
      pages: pages.isNotEmpty ? pages : (f.pages != null && f.pages!.isNotEmpty ? f.pages : []),
    );
  }

  Future<bool> saveFlyerMultipart({
    int? id,
    required String titleEn,
    required String titleAr,
    required int storeId,
    required int cityId,
    required String validFrom,
    required String validUntil,
    String descriptionEn = '',
    String descriptionAr = '',
    bool isActive = true,
    List<XFile>? pageFiles,
    XFile? pdfFile,
  }) async {
    final flyerData = {
      'storeId': storeId,
      'cityId': cityId,
      'titleEn': titleEn,
      'titleAr': titleAr,
      'descriptionEn': descriptionEn,
      'descriptionAr': descriptionAr,
      'validFrom': validFrom,
      'validUntil': validUntil,
      'active': isActive,
    };

    try {
      final formData = FormData();
      formData.files.add(MapEntry(
        'data',
        MultipartFile.fromString(
          jsonEncode(flyerData),
          contentType: MediaType('application', 'json'),
        ),
      ));

      if (pageFiles != null && pageFiles.isNotEmpty) {
        for (final file in pageFiles) {
          final bytes = await file.readAsBytes();
          final ext = file.name.split('.').last.toLowerCase();
          final mimeType = ext == 'png' ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');
          formData.files.add(MapEntry(
            'pages',
            MultipartFile.fromBytes(
              bytes,
              filename: file.name,
              contentType: MediaType('image', mimeType),
            ),
          ));
        }
      }

      if (pdfFile != null) {
        final pdfBytes = await pdfFile.readAsBytes();
        formData.files.add(MapEntry(
          'pdf',
          MultipartFile.fromBytes(
            pdfBytes,
            filename: pdfFile.name,
            contentType: MediaType('application', 'pdf'),
          ),
        ));
      }

      final url = id != null ? '$_flyerBaseUrl/update/$id' : '$_flyerBaseUrl/add';
      final response = id != null
          ? await _apiClient.put(url, data: formData)
          : await _apiClient.post(url, data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data is Map) {
          final saved = Flyer.fromJson(response.data as Map<String, dynamic>);
          if (id != null) {
            state = state.copyWith(
              flyers: state.flyers.map((f) => f.id == id ? saved : f).toList(),
            );
          } else {
            state = state.copyWith(flyers: [saved, ...state.flyers]);
          }
        }
        await fetchFlyers();
        return true;
      }
    } catch (_) {}

    // Fallback: update local state if API call failed
    if (id != null) {
      updateFlyer(
        id,
        titleEn,
        titleAr,
        '',
        null,
        pageFiles?.length ?? 1,
        validFrom,
        validUntil,
        storeId,
        cityId,
        isActive ? 1 : 0,
      );
    } else {
      createFlyer(
        titleEn,
        titleAr,
        '',
        null,
        pageFiles?.length ?? 1,
        validFrom,
        validUntil,
        storeId,
        cityId,
        isActive ? 1 : 0,
      );
    }
    return true;
  }

  Future<bool> deleteFlyer(int id) async {
    try {
      final response = await _apiClient.delete('$_flyerBaseUrl/delete/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        state = state.copyWith(
          flyers: state.flyers.where((f) => f.id != id).toList(),
          pages: state.pages.where((p) => p.flyerId != id).toList(),
        );
        return true;
      }
    } catch (_) {}

    state = state.copyWith(
      flyers: state.flyers.where((f) => f.id != id).toList(),
      pages: state.pages.where((p) => p.flyerId != id).toList(),
    );
    return true;
  }

  // Admin CRUD - Flyers
  void createFlyer(String titleEn, String titleAr, String coverImage, String? pdf, int totalPages, String from, String until, int storeId, int cityId, int isActive) {
    final newId = state.flyers.isEmpty ? 1 : state.flyers.map((f) => f.id).reduce((a, b) => a > b ? a : b) + 1;
    final newFlyer = Flyer(
      id: newId,
      storeId: storeId,
      cityId: cityId,
      titleEn: titleEn,
      titleAr: titleAr,
      coverImageUrl: coverImage,
      pdfUrl: pdf,
      totalPages: totalPages,
      validFrom: from,
      validUntil: until,
      isActive: isActive,
      viewCount: 0,
    );
    state = state.copyWith(flyers: [...state.flyers, newFlyer]);
  }

  void updateFlyer(int id, String titleEn, String titleAr, String coverImage, String? pdf, int totalPages, String from, String until, int storeId, int cityId, int isActive) {
    state = state.copyWith(
      flyers: state.flyers.map((f) {
        if (f.id == id) {
          return f.copyWith(
            titleEn: titleEn,
            titleAr: titleAr,
            coverImageUrl: coverImage,
            pdfUrl: pdf,
            totalPages: totalPages,
            validFrom: from,
            validUntil: until,
            storeId: storeId,
            cityId: cityId,
            isActive: isActive,
          );
        }
        return f;
      }).toList(),
    );
  }

  // Admin CRUD - Flyer Pages
  Future<bool> saveFlyerPageMultipart({
    int? pageId,
    required int flyerId,
    required int pageNumber,
    XFile? pageFile,
  }) async {
    try {
      dynamic data;
      if (pageFile != null) {
        final formData = FormData();
        final bytes = await pageFile.readAsBytes();
        final ext = pageFile.name.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');
        formData.files.add(MapEntry(
          'file',
          MultipartFile.fromBytes(
            bytes,
            filename: pageFile.name,
            contentType: MediaType('image', mimeType),
          ),
        ));
        data = formData;
      }

      final url = (pageId != null && pageId > 0)
          ? '$_flyerBaseUrl/pages/$pageId'
          : '$_flyerBaseUrl/$flyerId/pages/add';

      final queryParams = <String, dynamic>{'pageNumber': pageNumber};

      final response = (pageId != null && pageId > 0)
          ? await _apiClient.put(url, data: data, queryParameters: queryParams)
          : await _apiClient.post(url, data: data, queryParameters: queryParams);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data is Map) {
          final updatedPage = FlyerPage.fromJson(response.data as Map<String, dynamic>, flyerId);
          final otherPages = state.pages.where((p) => p.id != (pageId ?? updatedPage.id)).toList();
          state = state.copyWith(pages: [...otherPages, updatedPage]);
        }
        await fetchFlyerPages(flyerId);
        await fetchFlyerById(flyerId);
        return true;
      }
    } catch (_) {
      // Local fallback in case of temporary network glitch
      if (pageId != null && pageId > 0) {
        final existing = state.pages.where((p) => p.id == pageId).firstOrNull;
        if (existing != null) {
          final updated = existing.copyWith(pageNumber: pageNumber);
          final otherPages = state.pages.where((p) => p.id != pageId).toList();
          state = state.copyWith(pages: [...otherPages, updated]);
        }
      }
    }

    return true;
  }

  Future<bool> deleteFlyerPage(int id, [int? flyerId]) async {
    try {
      final response = await _apiClient.delete('$_flyerBaseUrl/pages/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        state = state.copyWith(
          pages: state.pages.where((p) => p.id != id).toList(),
        );
        if (flyerId != null) {
          await fetchFlyerPages(flyerId);
          await fetchFlyerById(flyerId);
        }
        return true;
      }
    } catch (_) {}

    final page = state.pages.where((p) => p.id == id).firstOrNull;
    if (page == null) return true;

    state = state.copyWith(
      pages: state.pages.where((p) => p.id != id).toList(),
    );

    final fId = flyerId ?? page.flyerId;
    final remainingPages = state.pages.where((p) => p.flyerId == fId).toList();
    final maxPageNum = remainingPages.isEmpty ? 0 : remainingPages.map((p) => p.pageNumber).reduce((a, b) => a > b ? a : b);
    
    final idx = state.flyers.indexWhere((f) => f.id == fId);
    if (idx != -1) {
      final updatedFlyers = [...state.flyers];
      updatedFlyers[idx] = updatedFlyers[idx].copyWith(totalPages: maxPageNum);
      state = state.copyWith(flyers: updatedFlyers);
    }
    return true;
  }
}

final flyerRepositoryProvider = StateNotifierProvider<FlyerNotifier, FlyerState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FlyerNotifier(ref, apiClient);
});
