import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import 'api_client.dart';
import 'category_repository.dart';

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
          isLoading: true,
        )) {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.get('/products/fetch-all-products');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) {
          state = state.copyWith(products: list, isLoading: false);
          return;
        }
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
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

  List<ProductDetail> getProductDetails(int productId) {
    final existing = state.details.where((d) => d.productId == productId).toList();
    if (existing.isEmpty) {
      _fetchProductDetailsRemote(productId);
    }
    return existing;
  }

  Future<void> _fetchProductDetailsRemote(int productId) async {
    try {
      final response = await _apiClient.get('/products/get-product-details/$productId');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => ProductDetail.fromJson(e as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) {
          state = state.copyWith(details: [...state.details, ...list]);
        }
      }
    } catch (_) {}
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
  Future<void> createProduct(String nameEn, String nameAr, String brand, String brandAr, String sku, String barcode, String primaryImage, String unit, double size, int categoryId, int isActive, String? descEn, String? descAr) async {
    try {
      final response = await _apiClient.post(
        '/products/add-product',
        data: {
          'data': {
            'nameEn': nameEn,
            'nameAr': nameAr,
            'brand': brand,
            'brandAr': brandAr,
            'sku': sku,
            'barcode': barcode,
            'primaryImageUrl': primaryImage,
            'unit': unit,
            'unitSize': size,
            'categoryId': categoryId,
            'active': isActive == 1,
            'descriptionEn': descEn,
            'descriptionAr': descAr,
          }
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final created = Product.fromJson(response.data as Map<String, dynamic>);
        state = state.copyWith(products: [...state.products, created]);
        return;
      }
    } catch (_) {}

    final newId = state.products.isEmpty ? 1 : state.products.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    final newProduct = Product(
      id: newId,
      categoryId: categoryId,
      brand: brand,
      brandAr: brandAr,
      sku: sku,
      barcode: barcode,
      nameEn: nameEn,
      nameAr: nameAr,
      descriptionEn: descEn,
      descriptionAr: descAr,
      primaryImageUrl: primaryImage,
      unit: unit,
      unitSize: size,
      isActive: isActive,
    );
    state = state.copyWith(products: [...state.products, newProduct]);
  }

  Future<void> updateProduct(int id, String nameEn, String nameAr, String brand, String brandAr, String sku, String barcode, String primaryImage, String unit, double size, int categoryId, int isActive, String? descEn, String? descAr) async {
    try {
      await _apiClient.put(
        '/products/update-product/$id',
        data: {
          'data': {
            'nameEn': nameEn,
            'nameAr': nameAr,
            'brand': brand,
            'brandAr': brandAr,
            'sku': sku,
            'barcode': barcode,
            'primaryImageUrl': primaryImage,
            'unit': unit,
            'unitSize': size,
            'categoryId': categoryId,
            'active': isActive == 1,
            'descriptionEn': descEn,
            'descriptionAr': descAr,
          }
        },
      );
    } catch (_) {}

    state = state.copyWith(
      products: state.products.map((p) {
        if (p.id == id) {
          return p.copyWith(
            nameEn: nameEn,
            nameAr: nameAr,
            brand: brand,
            brandAr: brandAr,
            sku: sku,
            barcode: barcode,
            primaryImageUrl: primaryImage,
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

  void deleteProductDetail(int id) {
    state = state.copyWith(
      details: state.details.where((d) => d.productId != id).toList(),
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
