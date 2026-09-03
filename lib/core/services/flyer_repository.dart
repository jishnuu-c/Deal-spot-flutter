import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          isLoading: true,
        )) {
    fetchFlyers();
  }

  // Helper url since flyers are mapped at /api/flyers (outside /api/dealspot)
  String get _flyerBaseUrl => '${AppConfig.serverUrl}/api/flyers';

  Future<void> fetchFlyers() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.get('$_flyerBaseUrl/fetch-all-flyers');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => Flyer.fromJson(e as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) {
          state = state.copyWith(flyers: list, isLoading: false);
          return;
        }
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  List<Flyer> getFlyers([int? cityId]) {
    var list = state.flyers;
    if (cityId != null) {
      list = list.where((f) => f.cityId == cityId).toList();
    }
    return list.map((f) => _populateFlyer(f)).toList();
  }

  Flyer? getFlyerById(int id) {
    try {
      final idx = state.flyers.indexWhere((f) => f.id == id);
      if (idx == -1) {
        _fetchFlyerByIdRemote(id);
        return null;
      }

      final flyer = state.flyers[idx];
      final updatedFlyer = flyer.copyWith(viewCount: flyer.viewCount + 1);

      final updatedList = [...state.flyers];
      updatedList[idx] = updatedFlyer;
      state = state.copyWith(flyers: updatedList);

      _fetchPagesForFlyer(id);

      return _populateFlyer(updatedFlyer);
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchFlyerByIdRemote(int id) async {
    try {
      final response = await _apiClient.get('$_flyerBaseUrl/fetch-flyer/$id');
      if (response.statusCode == 200 && response.data != null) {
        final flyer = Flyer.fromJson(response.data as Map<String, dynamic>);
        state = state.copyWith(flyers: [...state.flyers, flyer]);
      }
    } catch (_) {}
  }

  Future<void> _fetchPagesForFlyer(int flyerId) async {
    try {
      final response = await _apiClient.get('$_flyerBaseUrl/$flyerId/pages');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => FlyerPage.fromJson(e as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) {
          final otherPages = state.pages.where((p) => p.flyerId != flyerId).toList();
          state = state.copyWith(pages: [...otherPages, ...list]);
        }
      }
    } catch (_) {}
  }

  Flyer _populateFlyer(Flyer f) {
    final store = _ref.read(storeRepositoryProvider.notifier).getStoreById(f.storeId);
    final cities = _ref.read(cityRepositoryProvider).cities;
    final pages = state.pages.where((p) => p.flyerId == f.id).toList()
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    return f.copyWith(
      store: f.store ?? store,
      city: f.city ?? cities.where((c) => c.id == f.cityId).firstOrNull,
      pages: (f.pages != null && f.pages!.isNotEmpty) ? f.pages : pages,
    );
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

  void deleteFlyer(int id) {
    state = state.copyWith(
      flyers: state.flyers.where((f) => f.id != id).toList(),
      pages: state.pages.where((p) => p.flyerId != id).toList(),
    );
  }

  // Admin CRUD - Flyer Pages
  void createFlyerPage(int flyerId, int pageNum, String url, String thumb) {
    final newId = state.pages.isEmpty ? 1 : state.pages.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    final page = FlyerPage(
      id: newId,
      flyerId: flyerId,
      pageNumber: pageNum,
      imageUrl: url,
      thumbUrl: thumb,
    );
    
    state = state.copyWith(pages: [...state.pages, page]);
    
    final idx = state.flyers.indexWhere((f) => f.id == flyerId);
    if (idx != -1) {
      final flyer = state.flyers[idx];
      if (pageNum > flyer.totalPages) {
        final updatedFlyers = [...state.flyers];
        updatedFlyers[idx] = flyer.copyWith(totalPages: pageNum);
        state = state.copyWith(flyers: updatedFlyers);
      }
    }
  }

  void deleteFlyerPage(int id) {
    final page = state.pages.where((p) => p.id == id).firstOrNull;
    if (page == null) return;

    state = state.copyWith(
      pages: state.pages.where((p) => p.id != id).toList(),
    );

    final flyerId = page.flyerId;
    final remainingPages = state.pages.where((p) => p.flyerId == flyerId).toList();
    final maxPageNum = remainingPages.isEmpty ? 0 : remainingPages.map((p) => p.pageNumber).reduce((a, b) => a > b ? a : b);
    
    final idx = state.flyers.indexWhere((f) => f.id == flyerId);
    if (idx != -1) {
      final updatedFlyers = [...state.flyers];
      updatedFlyers[idx] = updatedFlyers[idx].copyWith(totalPages: maxPageNum);
      state = state.copyWith(flyers: updatedFlyers);
    }
  }
}

final flyerRepositoryProvider = StateNotifierProvider<FlyerNotifier, FlyerState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FlyerNotifier(ref, apiClient);
});
