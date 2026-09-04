import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart' hide Category;
import '../../models/brand.dart';
import '../../models/category.dart';
import 'api_client.dart';

class PagedBrandResult {
  final List<Brand> content;
  final int totalElements;
  final int totalPages;
  final int number;
  final bool isLast;

  const PagedBrandResult({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    this.isLast = false,
  });
}

class BrandState {
  final List<Brand> brands;
  final bool isLoading;

  const BrandState({
    required this.brands,
    this.isLoading = false,
  });

  BrandState copyWith({
    List<Brand>? brands,
    bool? isLoading,
  }) {
    return BrandState(
      brands: brands ?? this.brands,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BrandNotifier extends StateNotifier<BrandState> {
  final ApiClient _apiClient;

  BrandNotifier(this._apiClient) : super(const BrandState(brands: [], isLoading: false));

  Future<void> fetchBrands() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.get('/brands/fetch-brands');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => Brand.fromJson(e as Map<String, dynamic>)).toList();
        state = state.copyWith(brands: list, isLoading: false);
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  Future<PagedBrandResult> searchBrandsPaged({
    String query = '',
    int page = 0,
    int size = 20,
    bool? featured,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (query.trim().isNotEmpty) {
      queryParams['q'] = query.trim();
    }
    if (featured != null) {
      queryParams['featured'] = featured;
    }

    try {
      final response = await _apiClient.get(
        '/brands/search',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map) {
          final map = response.data as Map<String, dynamic>;
          final rawList = (map['content'] as List?) ?? [];
          final list = rawList.map((e) => Brand.fromJson(e as Map<String, dynamic>)).toList();
          final totalElements = (map['totalElements'] as num?)?.toInt() ?? list.length;
          final totalPages = (map['totalPages'] as num?)?.toInt() ?? 1;
          final number = (map['number'] as num?)?.toInt() ?? page;
          final isLast = (map['last'] as bool?) ?? ((number + 1) >= totalPages);

          final existingIds = state.brands.map((b) => b.id).toSet();
          final newBrands = list.where((b) => !existingIds.contains(b.id)).toList();
          if (newBrands.isNotEmpty) {
            state = state.copyWith(brands: [...state.brands, ...newBrands]);
          }

          return PagedBrandResult(
            content: list,
            totalElements: totalElements,
            totalPages: totalPages,
            number: number,
            isLast: isLast,
          );
        } else if (response.data is List) {
          final rawList = response.data as List;
          final list = rawList.map((e) => Brand.fromJson(e as Map<String, dynamic>)).toList();
          return PagedBrandResult(
            content: list,
            totalElements: list.length,
            totalPages: 1,
            number: 0,
            isLast: true,
          );
        }
      }
    } catch (_) {}

    // Fallback: local search
    final all = searchBrands(query, featuredOnly: featured);
    final start = page * size;
    final pagedList = start < all.length ? all.skip(start).take(size).toList() : <Brand>[];
    final totalPages = (all.length / size).ceil();
    return PagedBrandResult(
      content: pagedList,
      totalElements: all.length,
      totalPages: totalPages == 0 ? 1 : totalPages,
      number: page,
      isLast: (page + 1) >= (totalPages == 0 ? 1 : totalPages),
    );
  }

  Future<PagedBrandResult> fetchFeaturedBrandsPaged({int page = 0, int size = 15}) async {
    return searchBrandsPaged(query: '', page: page, size: size, featured: true);
  }

  List<Brand> getFeaturedBrands() {
    return state.brands.where((b) => b.featured && b.active).toList();
  }

  List<Brand> searchBrands(String query, {bool? featuredOnly}) {
    var list = state.brands.where((b) => b.active).toList();
    if (featuredOnly == true) {
      list = list.where((b) => b.featured).toList();
    }
    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((b) =>
          b.nameEn.toLowerCase().contains(q) ||
          b.nameAr.toLowerCase().contains(q) ||
          (b.descriptionEn?.toLowerCase().contains(q) ?? false) ||
          (b.descriptionAr?.toLowerCase().contains(q) ?? false)).toList();
    }
    return list;
  }

  Brand? getBrandById(int id) {
    try {
      return state.brands.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Brand?> fetchBrandById(int id) async {
    try {
      final response = await _apiClient.get('/brands/$id');
      if (response.statusCode == 200 && response.data != null) {
        final brand = Brand.fromJson(response.data as Map<String, dynamic>);
        final list = [...state.brands];
        final idx = list.indexWhere((b) => b.id == id);
        if (idx != -1) {
          list[idx] = brand;
        } else {
          list.add(brand);
        }
        state = state.copyWith(brands: list);
        return brand;
      }
    } catch (_) {}
    return getBrandById(id);
  }

  Future<bool> createBrand({
    required String nameEn,
    required String nameAr,
    String? descriptionEn,
    String? descriptionAr,
    String? websiteUrl,
    required bool featured,
    required bool active,
    List<int> categoryIds = const [],
    List<Category> categoryObjects = const [],
    XFile? logoFile,
  }) async {
    final payload = {
      'nameEn': nameEn,
      'nameAr': nameAr,
      'descriptionEn': descriptionEn ?? '',
      'descriptionAr': descriptionAr ?? '',
      'websiteUrl': websiteUrl ?? '',
      'featured': featured,
      'active': active,
      'categoryIds': categoryIds,
    };

    try {
      final formMap = <String, dynamic>{
        'data': MultipartFile.fromString(
          jsonEncode(payload),
          contentType: MediaType.parse('application/json'),
        ),
      };

      if (logoFile != null) {
        final bytes = await logoFile.readAsBytes();
        formMap['logoFile'] = MultipartFile.fromBytes(bytes, filename: logoFile.name);
      }

      final formData = FormData.fromMap(formMap);

      final response = await _apiClient.post(
        '/brands/register-brand',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          final created = Brand.fromJson(response.data as Map<String, dynamic>);
          state = state.copyWith(brands: [...state.brands, created]);
          return true;
        }
      }
    } catch (_) {
      // Fallback: raw json
      try {
        final response = await _apiClient.post(
          '/brands/register-brand',
          data: payload,
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.data != null) {
            final created = Brand.fromJson(response.data as Map<String, dynamic>);
            state = state.copyWith(brands: [...state.brands, created]);
            return true;
          }
        }
      } catch (_) {}
    }

    final newId = state.brands.isEmpty ? 1 : state.brands.map((b) => b.id).reduce((a, b) => a > b ? a : b) + 1;
    final newBrand = Brand(
      id: newId,
      nameEn: nameEn,
      nameAr: nameAr,
      descriptionEn: descriptionEn,
      descriptionAr: descriptionAr,
      websiteUrl: websiteUrl,
      featured: featured,
      active: active,
      categories: categoryObjects,
    );
    state = state.copyWith(brands: [...state.brands, newBrand]);
    return true;
  }

  Future<bool> updateBrand({
    required int id,
    required String nameEn,
    required String nameAr,
    String? descriptionEn,
    String? descriptionAr,
    String? websiteUrl,
    required bool featured,
    required bool active,
    List<int> categoryIds = const [],
    List<Category> categoryObjects = const [],
    XFile? logoFile,
    String? currentLogoUrl,
  }) async {
    final payload = {
      'nameEn': nameEn,
      'nameAr': nameAr,
      'descriptionEn': descriptionEn ?? '',
      'descriptionAr': descriptionAr ?? '',
      'websiteUrl': websiteUrl ?? '',
      'featured': featured,
      'active': active,
      'categoryIds': categoryIds,
    };

    try {
      final formMap = <String, dynamic>{
        'data': MultipartFile.fromString(
          jsonEncode(payload),
          contentType: MediaType.parse('application/json'),
        ),
      };

      if (logoFile != null) {
        final bytes = await logoFile.readAsBytes();
        formMap['logoFile'] = MultipartFile.fromBytes(bytes, filename: logoFile.name);
      }

      final formData = FormData.fromMap(formMap);

      final response = await _apiClient.patch(
        '/brands/update-brand/$id',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final updated = Brand.fromJson(response.data as Map<String, dynamic>);
        final list = [...state.brands];
        final idx = list.indexWhere((b) => b.id == id);
        if (idx != -1) {
          list[idx] = updated;
          state = state.copyWith(brands: list);
        }
        return true;
      }
    } catch (_) {
      try {
        await _apiClient.patch(
          '/brands/update-brand/$id',
          data: payload,
        );
      } catch (_) {}
    }

    final list = [...state.brands];
    final idx = list.indexWhere((b) => b.id == id);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(
        nameEn: nameEn,
        nameAr: nameAr,
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        websiteUrl: websiteUrl,
        featured: featured,
        active: active,
        categories: categoryObjects,
        logoUrl: currentLogoUrl,
      );
      state = state.copyWith(brands: list);
    }
    return true;
  }

  Future<bool> deleteBrand(int id) async {
    try {
      await _apiClient.delete('/brands/delete-brand/$id');
    } catch (_) {}

    state = state.copyWith(brands: state.brands.where((b) => b.id != id).toList());
    return true;
  }
}

final brandRepositoryProvider = StateNotifierProvider<BrandNotifier, BrandState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BrandNotifier(apiClient);
});
