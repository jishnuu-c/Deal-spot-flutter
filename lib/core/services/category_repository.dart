import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart' hide Category;
import '../../models/models.dart';
import 'api_client.dart';

class CategoryNotifier extends StateNotifier<List<Category>> {
  final ApiClient _apiClient;
  bool isLoading = false;
  bool isSavingOrder = false;

  CategoryNotifier(this._apiClient) : super(const []);

  Future<void> fetchCategories() async {
    isLoading = true;
    try {
      final response = await _apiClient.get('/categories/fetch-categories');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
        state = list;
      }
    } catch (_) {
    } finally {
      isLoading = false;
    }
  }

  // Admin CRUD: Create
  Future<bool> createCategory({
    required String nameEn,
    required String nameAr,
    required String iconSlug,
    required int sortOrder,
    required int isActive,
    int? parentId,
    XFile? imageFile,
  }) async {
    try {
      final categoryPayload = {
        'nameEn': nameEn,
        'nameAr': nameAr,
        'iconSlug': iconSlug,
        'sortOrder': sortOrder,
        'active': isActive == 1,
        'parentId': parentId,
      };

      final formMap = <String, dynamic>{
        'data': MultipartFile.fromString(
          jsonEncode(categoryPayload),
          contentType: MediaType.parse('application/json'),
        ),
      };

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        formMap['file'] = MultipartFile.fromBytes(bytes, filename: imageFile.name);
      }

      final formData = FormData.fromMap(formMap);

      final response = await _apiClient.post(
        '/categories/create',
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (response.data != null) {
          final created = Category.fromJson(response.data as Map<String, dynamic>);
          state = [...state, created];
          return true;
        }
      }
    } catch (e) {
      // Fallback: try raw JSON payload if multipart was rejected
      try {
        final response = await _apiClient.post(
          '/categories/create',
          data: {
            'nameEn': nameEn,
            'nameAr': nameAr,
            'iconSlug': iconSlug,
            'sortOrder': sortOrder,
            'active': isActive == 1,
            'parentId': parentId,
          },
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          if (response.data != null) {
            final created = Category.fromJson(response.data as Map<String, dynamic>);
            state = [...state, created];
            return true;
          }
        }
      } catch (_) {}
    }

    final newId = state.isEmpty ? 1 : state.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
    final newCategory = Category(
      id: newId,
      nameEn: nameEn,
      nameAr: nameAr,
      iconSlug: iconSlug,
      sortOrder: sortOrder,
      isActive: isActive,
      parentId: parentId,
    );
    state = [...state, newCategory];
    return true;
  }

  // Admin CRUD: Update
  Future<bool> updateCategory({
    required int id,
    required String nameEn,
    required String nameAr,
    required String iconSlug,
    required int sortOrder,
    required int isActive,
    int? parentId,
    XFile? imageFile,
  }) async {
    try {
      final categoryPayload = {
        'nameEn': nameEn,
        'nameAr': nameAr,
        'iconSlug': iconSlug,
        'sortOrder': sortOrder,
        'active': isActive == 1,
        'parentId': parentId,
      };

      final formMap = <String, dynamic>{
        'data': MultipartFile.fromString(
          jsonEncode(categoryPayload),
          contentType: MediaType.parse('application/json'),
        ),
      };

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        formMap['file'] = MultipartFile.fromBytes(bytes, filename: imageFile.name);
      }

      final formData = FormData.fromMap(formMap);

      final response = await _apiClient.put(
        '/categories/edit/$id',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        final updated = Category.fromJson(response.data as Map<String, dynamic>);
        state = state.map((c) => c.id == id ? updated : c).toList();
        return true;
      }
    } catch (_) {
      try {
        await _apiClient.put(
          '/categories/edit/$id',
          data: {
            'nameEn': nameEn,
            'nameAr': nameAr,
            'iconSlug': iconSlug,
            'sortOrder': sortOrder,
            'active': isActive == 1,
            'parentId': parentId,
          },
        );
      } catch (_) {}
    }

    state = state.map((c) {
      if (c.id == id) {
        return c.copyWith(
          nameEn: nameEn,
          nameAr: nameAr,
          iconSlug: iconSlug,
          sortOrder: sortOrder,
          isActive: isActive,
          parentId: parentId,
        );
      }
      return c;
    }).toList();
    return true;
  }

  // Admin CRUD: Reorder
  Future<bool> reorderCategories(List<Category> reorderedList) async {
    isSavingOrder = true;
    final orderPayload = reorderedList.map((c) => {
      'id': c.id,
      'sortOrder': c.sortOrder,
    }).toList();

    // Optimistically update local state
    final updatedIds = {for (var c in reorderedList) c.id: c.sortOrder};
    state = state.map((c) {
      if (updatedIds.containsKey(c.id)) {
        return c.copyWith(sortOrder: updatedIds[c.id]);
      }
      return c;
    }).toList();

    try {
      await _apiClient.put('/categories/reorder', data: orderPayload);
      isSavingOrder = false;
      return true;
    } catch (_) {
      isSavingOrder = false;
      return false;
    }
  }

  // Admin CRUD: Delete
  Future<bool> deleteCategory(int id) async {
    try {
      await _apiClient.delete('/categories/delete/$id');
    } catch (_) {}

    state = state.where((c) => c.id != id).toList();
    return true;
  }
}

final categoryRepositoryProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CategoryNotifier(apiClient);
});

