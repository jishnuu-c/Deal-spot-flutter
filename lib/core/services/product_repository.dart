import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart' hide Category;
import '../../models/models.dart';
import 'api_client.dart';
import 'category_repository.dart';

class PagedProductResult {
  final List<Product> content;
  final int totalElements;
  final int totalPages;
  final int number;

  const PagedProductResult({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
  });
}

class ProductState {
  final List<Product> products;
  final List<ProductDetail> details;
  final List<ProductImage> images;
  final bool isLoading;

  const ProductState({
    required this.products,
    required this.details,
    required this.images,
    this.isLoading = false,
  });

  ProductState copyWith({
    List<Product>? products,
    List<ProductDetail>? details,
    List<ProductImage>? images,
    bool? isLoading,
  }) {
    return ProductState(
      products: products ?? this.products,
      details: details ?? this.details,
      images: images ?? this.images,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProductNotifier extends StateNotifier<ProductState> {
  final Ref _ref;
  final ApiClient _apiClient;

  ProductNotifier(this._ref, this._apiClient)
      : super(const ProductState(
          products: [],
          details: [],
          images: [],
          isLoading: false,
        ));

  Future<void> fetchProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.get('/products/fetch-all-products');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          final rawList = response.data as List;
          final list = rawList.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
          if (list.isNotEmpty) {
            state = state.copyWith(products: list, isLoading: false);
            return;
          }
        } else if (response.data is Map && (response.data as Map).containsKey('content')) {
          final rawList = (response.data as Map)['content'] as List;
          final list = rawList.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
          state = state.copyWith(products: list, isLoading: false);
          return;
        }
      }
    } catch (_) {}

    // If fetch-all-products fails, try getting first page from /products/paged
    try {
      final pagedRes = await getPagedProducts(page: 0, size: 50);
      if (pagedRes.content.isNotEmpty) {
        state = state.copyWith(products: pagedRes.content, isLoading: false);
        return;
      }
    } catch (_) {}

    state = state.copyWith(isLoading: false);
  }

  Future<PagedProductResult> getPagedProducts({
    int page = 0,
    int size = 20,
    String? search,
    int? categoryId,
    int? brandId,
    String sortBy = 'createdAt',
    String direction = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'direction': direction,
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (categoryId != null) {
      queryParams['categoryId'] = categoryId;
    }
    if (brandId != null) {
      queryParams['brandId'] = brandId;
    }

    try {
      final response = await _apiClient.get(
        '/products/paged',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map) {
          final map = response.data as Map<String, dynamic>;
          final rawList = (map['content'] as List?) ?? [];
          final list = rawList.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
          final totalElements = (map['totalElements'] as num?)?.toInt() ?? list.length;
          final totalPages = (map['totalPages'] as num?)?.toInt() ?? 1;
          final number = (map['number'] as num?)?.toInt() ?? page;

          // Merge loaded products into state
          final existingIds = state.products.map((p) => p.id).toSet();
          final newProducts = list.where((p) => !existingIds.contains(p.id)).toList();
          if (newProducts.isNotEmpty) {
            state = state.copyWith(products: [...state.products, ...newProducts]);
          }

          return PagedProductResult(
            content: list,
            totalElements: totalElements,
            totalPages: totalPages,
            number: number,
          );
        } else if (response.data is List) {
          final rawList = response.data as List;
          final list = rawList.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
          return PagedProductResult(
            content: list,
            totalElements: list.length,
            totalPages: 1,
            number: 0,
          );
        }
      }
    } catch (e) {
      // Fallback to local products filter if offline or error
      final all = getProducts();
      var filtered = all;
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        filtered = filtered.where((p) =>
            p.nameEn.toLowerCase().contains(q) ||
            p.nameAr.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.barcode.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q)).toList();
      }
      if (categoryId != null) {
        filtered = filtered.where((p) => p.categoryId == categoryId).toList();
      }
      if (brandId != null) {
        filtered = filtered.where((p) => p.brandId == brandId).toList();
      }
      final start = page * size;
      final pagedList = start < filtered.length ? filtered.skip(start).take(size).toList() : <Product>[];
      final totalPages = (filtered.length / size).ceil();
      return PagedProductResult(
        content: pagedList,
        totalElements: filtered.length,
        totalPages: totalPages == 0 ? 1 : totalPages,
        number: page,
      );
    }

    return PagedProductResult(
      content: [],
      totalElements: 0,
      totalPages: 0,
      number: page,
    );
  }

  List<Product> getProducts() {
    return state.products.map((p) => _populateProduct(p)).toList();
  }

  Product? getProductById(int id) {
    try {
      final product = state.products.firstWhere((p) => p.id == id);
      return _populateProduct(product);
    } catch (_) {
      return null;
    }
  }

  Future<Product?> fetchProductById(int productId) async {
    try {
      final response = await _apiClient.get('/products/fetch-product/$productId');
      if (response.statusCode == 200 && response.data != null) {
        final product = Product.fromJson(response.data as Map<String, dynamic>);
        final list = [...state.products];
        final idx = list.indexWhere((p) => p.id == productId);
        if (idx != -1) {
          list[idx] = product;
        } else {
          list.add(product);
        }
        state = state.copyWith(products: list);
        return _populateProduct(product);
      }
    } catch (_) {}
    return getProductById(productId);
  }

  Future<List<ProductDetail>> fetchProductDetails(int productId) async {
    try {
      final response = await _apiClient.get('/products/get-product-details/$productId');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => ProductDetail.fromJson(e as Map<String, dynamic>)).toList();
        final otherDetails = state.details.where((d) => d.productId != productId).toList();
        state = state.copyWith(details: [...otherDetails, ...list]);
        return list;
      }
    } catch (_) {}
    return state.details.where((d) => d.productId == productId).toList();
  }

  Future<List<AttributeKey>> fetchAttributeKeys() async {
    try {
      final response = await _apiClient.get('/products/fetch-attribute-keys');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        return rawList.map((e) => AttributeKey.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> addAttributeKey(String attrKeyEn, String attrKeyAr) async {
    try {
      final response = await _apiClient.post(
        '/products/add-key',
        data: {
          'attrKeyEn': attrKeyEn,
          'attrKeyAr': attrKeyAr,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  List<ProductDetail> getProductDetails(int productId) {
    return state.details.where((d) => d.productId == productId).toList();
  }

  Future<bool> saveProductSpecs(int productId, List<ProductDetail> specs) async {
    final product = getProductById(productId) ?? await fetchProductById(productId);
    if (product == null) return false;

    final payload = {
      'id': product.id,
      'nameEn': product.nameEn,
      'nameAr': product.nameAr,
      'brandId': product.brandId,
      'categoryId': product.categoryId,
      'sku': product.sku,
      'barcode': product.barcode,
      'unit': product.unit,
      'unitSize': product.unitSize,
      'descriptionEn': product.descriptionEn ?? '',
      'descriptionAr': product.descriptionAr ?? '',
      'active': product.isActive == 1,
      'details': specs.map((s) => {
        'attrKeyEn': s.attrKeyEn,
        'attrKeyAr': s.attrKeyAr,
        'attrValueEn': s.attrValueEn,
        'attrValueAr': s.attrValueAr,
        'sortOrder': s.sortOrder,
      }).toList(),
    };

    try {
      final formMap = <String, dynamic>{
        'data': MultipartFile.fromString(
          jsonEncode(payload),
          contentType: MediaType.parse('application/json'),
        ),
      };

      final formData = FormData.fromMap(formMap);
      final response = await _apiClient.put(
        '/products/update-product/$productId',
        data: formData,
      );
      if (response.statusCode == 200) {
        await fetchProductById(productId);
        await fetchProductDetails(productId);
        return true;
      }
    } catch (_) {
      try {
        final response = await _apiClient.put(
          '/products/update-product/$productId',
          data: {'data': payload},
        );
        if (response.statusCode == 200) {
          await fetchProductById(productId);
          await fetchProductDetails(productId);
          return true;
        }
      } catch (_) {}
    }

    // Local fallback
    final otherDetails = state.details.where((d) => d.productId != productId).toList();
    state = state.copyWith(details: [...otherDetails, ...specs]);
    return true;
  }

  List<ProductImage> getProductImages(int productId) {
    return state.images.where((i) => i.productId == productId).toList();
  }

  Product _populateProduct(Product p) {
    final categories = _ref.read(categoryRepositoryProvider);
    final details = state.details.where((d) => d.productId == p.id).toList();
    final images = state.images.where((i) => i.productId == p.id).toList();

    return p.copyWith(
      category: p.category ?? categories.where((c) => c.id == p.categoryId).firstOrNull,
      details: details,
      images: images.isEmpty
          ? (p.primaryImageUrl.isNotEmpty
              ? [ProductImage(id: 0, productId: p.id, imageUrl: p.primaryImageUrl, sortOrder: 1, isPrimary: 1)]
              : const [])
          : images,
    );
  }

  // Admin CRUD - Products
  Future<bool> createProduct({
    required String nameEn,
    required String nameAr,
    int? brandId,
    required String brand,
    required String brandAr,
    String? sku,
    String? barcode,
    String? primaryImage,
    required String unit,
    required double size,
    required int categoryId,
    required int isActive,
    String? descEn,
    String? descAr,
    XFile? imageFile,
  }) async {
    final payload = {
      'nameEn': nameEn,
      'nameAr': nameAr,
      if (brandId != null) 'brandId': brandId,
      'brand': brand,
      'brandAr': brandAr,
      'sku': sku ?? '',
      'barcode': barcode ?? '',
      'primaryImageUrl': primaryImage ?? '',
      'unit': unit,
      'unitSize': size,
      'categoryId': categoryId,
      'active': isActive == 1,
      'descriptionEn': descEn ?? '',
      'descriptionAr': descAr ?? '',
    };

    try {
      final formMap = <String, dynamic>{
        'data': MultipartFile.fromString(
          jsonEncode(payload),
          contentType: MediaType.parse('application/json'),
        ),
      };

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        formMap['file'] = MultipartFile.fromBytes(bytes, filename: imageFile.name);
      }

      final formData = FormData.fromMap(formMap);
      final response = await _apiClient.post(
        '/products/add-product',
        data: formData,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          final created = Product.fromJson(response.data as Map<String, dynamic>);
          state = state.copyWith(products: [...state.products, created]);
          return true;
        }
      }
    } catch (_) {
      try {
        final response = await _apiClient.post(
          '/products/add-product',
          data: {'data': payload},
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.data != null) {
            final created = Product.fromJson(response.data as Map<String, dynamic>);
            state = state.copyWith(products: [...state.products, created]);
            return true;
          }
        }
      } catch (_) {}
    }

    final newId = state.products.isEmpty ? 1 : state.products.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    final newProduct = Product(
      id: newId,
      categoryId: categoryId,
      brandId: brandId,
      brand: brand,
      brandAr: brandAr,
      sku: sku ?? '',
      barcode: barcode ?? '',
      nameEn: nameEn,
      nameAr: nameAr,
      descriptionEn: descEn,
      descriptionAr: descAr,
      primaryImageUrl: primaryImage ?? '',
      unit: unit,
      unitSize: size,
      isActive: isActive,
    );
    state = state.copyWith(products: [...state.products, newProduct]);
    return true;
  }

  Future<bool> updateProduct({
    required int id,
    required String nameEn,
    required String nameAr,
    int? brandId,
    required String brand,
    required String brandAr,
    String? sku,
    String? barcode,
    String? primaryImage,
    required String unit,
    required double size,
    required int categoryId,
    required int isActive,
    String? descEn,
    String? descAr,
    XFile? imageFile,
  }) async {
    final payload = {
      'id': id,
      'nameEn': nameEn,
      'nameAr': nameAr,
      if (brandId != null) 'brandId': brandId,
      'brand': brand,
      'brandAr': brandAr,
      'sku': sku ?? '',
      'barcode': barcode ?? '',
      'primaryImageUrl': primaryImage ?? '',
      'unit': unit,
      'unitSize': size,
      'categoryId': categoryId,
      'active': isActive == 1,
      'descriptionEn': descEn ?? '',
      'descriptionAr': descAr ?? '',
    };

    try {
      final formMap = <String, dynamic>{
        'data': MultipartFile.fromString(
          jsonEncode(payload),
          contentType: MediaType.parse('application/json'),
        ),
      };

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        formMap['file'] = MultipartFile.fromBytes(bytes, filename: imageFile.name);
      }

      final formData = FormData.fromMap(formMap);
      final response = await _apiClient.put(
        '/products/update-product/$id',
        data: formData,
      );
      if (response.statusCode == 200 && response.data != null) {
        final updated = Product.fromJson(response.data as Map<String, dynamic>);
        final list = [...state.products];
        final idx = list.indexWhere((p) => p.id == id);
        if (idx != -1) {
          list[idx] = updated;
          state = state.copyWith(products: list);
        }
        return true;
      }
    } catch (_) {
      try {
        await _apiClient.put(
          '/products/update-product/$id',
          data: {'data': payload},
        );
      } catch (_) {}
    }

    state = state.copyWith(
      products: state.products.map((p) {
        if (p.id == id) {
          return p.copyWith(
            nameEn: nameEn,
            nameAr: nameAr,
            brandId: brandId ?? p.brandId,
            brand: brand,
            brandAr: brandAr,
            sku: sku ?? p.sku,
            barcode: barcode ?? p.barcode,
            primaryImageUrl: primaryImage ?? p.primaryImageUrl,
            unit: unit,
            unitSize: size,
            categoryId: categoryId,
            isActive: isActive,
            descriptionEn: descEn,
            descriptionAr: descAr,
          );
        }
        return p;
      }).toList(),
    );
    return true;
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _apiClient.delete('/products/delete-product/$id');
    } catch (_) {}
    state = state.copyWith(
      products: state.products.where((p) => p.id != id).toList(),
      details: state.details.where((d) => d.productId != id).toList(),
      images: state.images.where((i) => i.productId != id).toList(),
    );
  }

  // Admin CRUD - Details (Specs)
  void createProductDetail(int productId, String keyEn, String keyAr, String valEn, String valAr, int sort) {
    final newId = state.details.isEmpty ? 1 : state.details.map((d) => d.id).reduce((a, b) => a > b ? a : b) + 1;
    final detail = ProductDetail(
      id: newId,
      productId: productId,
      attrKeyEn: keyEn,
      attrKeyAr: keyAr,
      attrValueEn: valEn,
      attrValueAr: valAr,
      sortOrder: sort,
    );
    state = state.copyWith(details: [...state.details, detail]);
  }

  void updateProductDetail(int id, String keyEn, String keyAr, String valEn, String valAr, int sort) {
    state = state.copyWith(
      details: state.details.map((d) {
        if (d.id == id) {
          return d.copyWith(
            attrKeyEn: keyEn,
            attrKeyAr: keyAr,
            attrValueEn: valEn,
            attrValueAr: valAr,
            sortOrder: sort,
          );
        }
        return d;
      }).toList(),
    );
  }

  void deleteProductDetail(int id) {
    state = state.copyWith(
      details: state.details.where((d) => d.id != id).toList(),
    );
  }

  // Admin CRUD - Alternate Images
  void createProductImage(int productId, String url, String? altEn, String? altAr, int sort, int isPrimary) {
    final newId = state.images.isEmpty ? 1 : state.images.map((i) => i.id).reduce((a, b) => a > b ? a : b) + 1;
    
    // If setting to primary, unset previous primary
    List<ProductImage> list = state.images;
    if (isPrimary == 1) {
      list = list.map((i) => i.productId == productId ? i.copyWith(isPrimary: 0) : i).toList();
    }

    final newImg = ProductImage(
      id: newId,
      productId: productId,
      imageUrl: url,
      altTextEn: altEn,
      altTextAr: altAr,
      sortOrder: sort,
      isPrimary: isPrimary,
    );
    
    state = state.copyWith(images: [...list, newImg]);
  }

  void deleteProductImage(int id) {
    state = state.copyWith(
      images: state.images.where((i) => i.id != id).toList(),
    );
  }
}

final productRepositoryProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductNotifier(ref, apiClient);
});
