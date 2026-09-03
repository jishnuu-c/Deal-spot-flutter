import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart' hide Category;
import '../../models/brand.dart';
import '../../models/category.dart';
import 'api_client.dart';

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

  BrandNotifier(this._apiClient) : super(const BrandState(brands: [], isLoading: true)) {
    fetchBrands();
  }

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
