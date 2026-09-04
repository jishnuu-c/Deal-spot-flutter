import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart' hide Category;
import '../../models/models.dart';
import 'api_client.dart';
import 'city_repository.dart';
import 'category_repository.dart';
import 'store_repository.dart';
import 'product_repository.dart';
import 'brand_repository.dart';

class OfferFilters {
  final int? cityId;
  final int? categoryId;
  final int? mainCategoryId;
  final int? subCategoryId;
  final int? storeId;
  final int? brandId;
  final String? brandName;
  final double? minDiscount;
  final bool? isFlash;
  final bool? isFeatured;
  final bool? onlySaved;
  final String? search;

  const OfferFilters({
    this.cityId,
    this.categoryId,
    this.mainCategoryId,
    this.subCategoryId,
    this.storeId,
    this.brandId,
    this.brandName,
    this.minDiscount,
    this.isFlash,
    this.isFeatured,
    this.onlySaved,
    this.search,
  });
}

class OfferState {
  final List<Offer> offers;
  final List<OfferImage> images;
  final List<int> savedOfferIds; // Offer IDs saved by current user
  final bool isLoading;

  const OfferState({
    required this.offers,
    required this.images,
    required this.savedOfferIds,
    this.isLoading = false,
  });

  OfferState copyWith({
    List<Offer>? offers,
    List<OfferImage>? images,
    List<int>? savedOfferIds,
    bool? isLoading,
  }) {
    return OfferState(
      offers: offers ?? this.offers,
      images: images ?? this.images,
      savedOfferIds: savedOfferIds ?? this.savedOfferIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PagedOfferResult {
  final List<Offer> content;
  final int totalElements;
  final int totalPages;
  final int number;

  const PagedOfferResult({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
  });
}

class OfferNotifier extends StateNotifier<OfferState> {
  final Ref _ref;
  final ApiClient _apiClient;

  OfferNotifier(this._ref, this._apiClient)
      : super(const OfferState(
          offers: [],
          images: [],
          savedOfferIds: [],
          isLoading: false,
        ));

  Future<void> fetchOffers({int? storeId, int? cityId, bool? includeExpired}) async {
    state = state.copyWith(isLoading: true);
    try {
      final queryParams = <String, dynamic>{};
      if (storeId != null) queryParams['storeId'] = storeId;
      if (cityId != null) queryParams['cityId'] = cityId;
      if (includeExpired == true) queryParams['includeExpired'] = true;

      final response = await _apiClient.get(
        '/offers/fetch-all-offers',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
        state = state.copyWith(offers: list, isLoading: false);
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  Future<void> fetchSavedOffers() async {
    try {
      final response = await _apiClient.get('/offers/my-saved');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList.map((e) => (e['id'] as num).toInt()).toList();
        state = state.copyWith(savedOfferIds: list);
      }
    } catch (_) {}
  }

  List<Offer> getOffers([OfferFilters? filters]) {
    var list = state.offers;

    if (filters != null) {
      if (filters.onlySaved == true) {
        list = list.where((o) => state.savedOfferIds.contains(o.id)).toList();
      }
      if (filters.cityId != null) {
        list = list.where((o) => o.cityId == filters.cityId).toList();
      }
      if (filters.subCategoryId != null) {
        list = list.where((o) => o.categoryId == filters.subCategoryId).toList();
      } else if (filters.categoryId != null) {
        final allCats = _ref.read(categoryRepositoryProvider);
        final subCatIds = allCats.where((c) => c.parentId == filters.categoryId).map((c) => c.id).toSet();
        subCatIds.add(filters.categoryId!);
        list = list.where((o) => subCatIds.contains(o.categoryId)).toList();
      } else if (filters.mainCategoryId != null) {
        final allCats = _ref.read(categoryRepositoryProvider);
        final subCatIds = allCats.where((c) => c.parentId == filters.mainCategoryId).map((c) => c.id).toSet();
        subCatIds.add(filters.mainCategoryId!);
        list = list.where((o) => subCatIds.contains(o.categoryId)).toList();
      }

      if (filters.storeId != null) {
        list = list.where((o) => o.storeId == filters.storeId).toList();
      }
      if (filters.brandId != null) {
        final brand = _ref.read(brandRepositoryProvider.notifier).getBrandById(filters.brandId!);
        if (brand != null) {
          list = list.where((o) {
            final prod = o.productId != null ? _ref.read(productRepositoryProvider.notifier).getProductById(o.productId!) : null;
            return (prod?.brand.toLowerCase() == brand.nameEn.toLowerCase() ||
                    prod?.brandAr?.toLowerCase() == brand.nameAr.toLowerCase());
          }).toList();
        }
      }
      if (filters.brandName != null && filters.brandName!.isNotEmpty) {
        final bName = filters.brandName!.toLowerCase();
        list = list.where((o) {
          final prod = o.productId != null ? _ref.read(productRepositoryProvider.notifier).getProductById(o.productId!) : null;
          return (prod?.brand.toLowerCase().contains(bName) ?? false) ||
                 (prod?.brandAr?.toLowerCase().contains(bName) ?? false);
        }).toList();
      }
      if (filters.minDiscount != null && filters.minDiscount! > 0) {
        list = list.where((o) => o.discountPct >= filters.minDiscount!).toList();
      }
      if (filters.isFlash != null && filters.isFlash!) {
        list = list.where((o) => o.isFlash == 1 || o.badgeType == 'FLASH').toList();
      }
      if (filters.isFeatured != null && filters.isFeatured!) {
        list = list.where((o) => o.isFeatured == 1 || o.badgeType == 'FEATURED').toList();
      }
      if (filters.search != null && filters.search!.isNotEmpty) {
        final q = filters.search!.toLowerCase();
        list = list.where((o) {
          final store = _ref.read(storeRepositoryProvider.notifier).getStoreById(o.storeId);
          final product = o.productId != null ? _ref.read(productRepositoryProvider.notifier).getProductById(o.productId!) : null;
          final storeNameEn = store?.nameEn.toLowerCase() ?? '';
          final storeNameAr = store?.nameAr.toLowerCase() ?? '';
          final productNameEn = product?.nameEn.toLowerCase() ?? '';
          final productNameAr = product?.nameAr.toLowerCase() ?? '';
          final brandNameEn = product?.brand.toLowerCase() ?? '';
          final brandNameAr = product?.brandAr?.toLowerCase() ?? '';

          return o.titleEn.toLowerCase().contains(q) ||
              o.titleAr.toLowerCase().contains(q) ||
              storeNameEn.contains(q) ||
              storeNameAr.contains(q) ||
              productNameEn.contains(q) ||
              productNameAr.contains(q) ||
              brandNameEn.contains(q) ||
              brandNameAr.contains(q);
        }).toList();
      }
    }

    return list.map((o) => _populateOffer(o)).toList();
  }

  Offer? getOfferById(int id) {
    try {
      final idx = state.offers.indexWhere((o) => o.id == id);
      if (idx == -1) {
        fetchOfferById(id);
        return null;
      }

      final offer = state.offers[idx];
      final updatedOffer = offer.copyWith(viewCount: offer.viewCount + 1);
      
      final updatedList = [...state.offers];
      updatedList[idx] = updatedOffer;
      
      state = state.copyWith(offers: updatedList);

      return _populateOffer(updatedOffer);
    } catch (_) {
      return null;
    }
  }

  Future<PagedOfferResult> getPagedOffers({
    int page = 0,
    int size = 20,
    String? search,
    int? storeId,
    String? badgeType,
    bool? active,
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
    if (storeId != null) {
      queryParams['storeId'] = storeId;
    }
    if (badgeType != null && badgeType != 'ALL' && badgeType.isNotEmpty) {
      queryParams['badgeType'] = badgeType;
    }
    if (active != null) {
      queryParams['active'] = active;
    }

    try {
      final response = await _apiClient.get(
        '/offers/paged',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map) {
          final map = response.data as Map<String, dynamic>;
          final rawList = (map['content'] as List?) ?? [];
          final list = rawList.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
          final totalElements = (map['totalElements'] as num?)?.toInt() ?? list.length;
          final totalPages = (map['totalPages'] as num?)?.toInt() ?? 1;
          final number = (map['number'] as num?)?.toInt() ?? page;

          final existingIds = state.offers.map((o) => o.id).toSet();
          final newOffers = list.where((o) => !existingIds.contains(o.id)).toList();
          if (newOffers.isNotEmpty) {
            state = state.copyWith(offers: [...state.offers, ...newOffers]);
          }

          return PagedOfferResult(
            content: list.map((o) => _populateOffer(o)).toList(),
            totalElements: totalElements,
            totalPages: totalPages,
            number: number,
          );
        } else if (response.data is List) {
          final rawList = response.data as List;
          final list = rawList.map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
          return PagedOfferResult(
            content: list.map((o) => _populateOffer(o)).toList(),
            totalElements: list.length,
            totalPages: 1,
            number: 0,
          );
        }
      }
    } catch (_) {}

    // Fallback: If /offers/paged failed and state.offers is empty, fetch all offers first
    if (state.offers.isEmpty) {
      await fetchOffers(storeId: storeId, includeExpired: true);
    }

    // Fallback: local filtering
    final all = getOffers();
    var filtered = all;
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      filtered = filtered.where((o) =>
          o.titleEn.toLowerCase().contains(q) ||
          o.titleAr.toLowerCase().contains(q) ||
          (o.store?.nameEn.toLowerCase().contains(q) ?? false) ||
          (o.store?.nameAr.toLowerCase().contains(q) ?? false) ||
          (o.product?.nameEn.toLowerCase().contains(q) ?? false) ||
          (o.product?.nameAr.toLowerCase().contains(q) ?? false) ||
          (o.category?.nameEn.toLowerCase().contains(q) ?? false) ||
          (o.category?.nameAr.toLowerCase().contains(q) ?? false)).toList();
    }
    if (storeId != null) {
      filtered = filtered.where((o) => o.storeId == storeId).toList();
    }
    if (badgeType != null && badgeType != 'ALL' && badgeType.isNotEmpty) {
      filtered = filtered.where((o) => o.badgeType == badgeType).toList();
    }
    if (active != null) {
      filtered = filtered.where((o) => (o.isActive == 1) == active).toList();
    }
    final start = page * size;
    final pagedList = start < filtered.length ? filtered.skip(start).take(size).toList() : <Offer>[];
    final totalPages = (filtered.length / size).ceil();
    return PagedOfferResult(
      content: pagedList,
      totalElements: filtered.length,
      totalPages: totalPages == 0 ? 1 : totalPages,
      number: page,
    );
  }

  Future<Offer?> fetchOfferById(int id) async {
    try {
      final response = await _apiClient.get('/offers/fetch-offer/$id');
      if (response.statusCode == 200 && response.data != null) {
        final offer = Offer.fromJson(response.data as Map<String, dynamic>);
        final list = [...state.offers];
        final idx = list.indexWhere((o) => o.id == id);
        if (idx != -1) {
          list[idx] = offer;
        } else {
          list.add(offer);
        }
        state = state.copyWith(offers: list);
        return _populateOffer(offer);
      }
    } catch (_) {}
    return getOfferById(id);
  }

  Offer _populateOffer(Offer o) {
    final store = _ref.read(storeRepositoryProvider.notifier).getStoreById(o.storeId);
    final product = o.productId != null ? _ref.read(productRepositoryProvider.notifier).getProductById(o.productId!) : null;
    final cities = _ref.read(cityRepositoryProvider).cities;
    final categories = _ref.read(categoryRepositoryProvider);
    final images = state.images.where((img) => img.offerId == o.id).toList();

    return o.copyWith(
      store: o.store ?? store,
      product: o.product ?? product,
      city: o.city ?? cities.where((c) => c.id == o.cityId).firstOrNull,
      category: o.category ?? categories.where((c) => c.id == o.categoryId).firstOrNull,
      images: (o.images != null && o.images!.isNotEmpty)
          ? o.images
          : (images.isNotEmpty
              ? images
              : (product?.primaryImageUrl != null && product!.primaryImageUrl.isNotEmpty
                  ? [OfferImage(id: 0, offerId: o.id, imageUrl: product.primaryImageUrl, sortOrder: 1)]
                  : const [])),
      isSaved: state.savedOfferIds.contains(o.id),
    );
  }

  // Admin CRUD - Offers
  Future<bool> extendOffer(int id, [int days = 7]) async {
    try {
      final response = await _apiClient.post('/offers/$id/extend?days=$days');
      if (response.statusCode == 200) {
        // Update local state validUntil if exists
        final list = [...state.offers];
        final idx = list.indexWhere((o) => o.id == id);
        if (idx != -1) {
          final cur = list[idx];
          DateTime newUntil;
          try {
            final parsed = DateTime.parse(cur.validUntil.split('T')[0]);
            newUntil = parsed.add(Duration(days: days));
          } catch (_) {
            newUntil = DateTime.now().add(Duration(days: days));
          }
          final y = newUntil.year.toString().padLeft(4, '0');
          final m = newUntil.month.toString().padLeft(2, '0');
          final d = newUntil.day.toString().padLeft(2, '0');
          list[idx] = cur.copyWith(
            validUntil: '$y-$m-$d',
            isActive: 1,
          );
          state = state.copyWith(offers: list);
        }
        return true;
      }
    } catch (_) {}

    // Fallback local extend
    final list = [...state.offers];
    final idx = list.indexWhere((o) => o.id == id);
    if (idx != -1) {
      final cur = list[idx];
      DateTime newUntil;
      try {
        final parsed = DateTime.parse(cur.validUntil.split('T')[0]);
        newUntil = parsed.add(Duration(days: days));
      } catch (_) {
        newUntil = DateTime.now().add(Duration(days: days));
      }
      final y = newUntil.year.toString().padLeft(4, '0');
      final m = newUntil.month.toString().padLeft(2, '0');
      final d = newUntil.day.toString().padLeft(2, '0');
      list[idx] = cur.copyWith(
        validUntil: '$y-$m-$d',
        isActive: 1,
      );
      state = state.copyWith(offers: list);
      return true;
    }
    return false;
  }

  Future<bool> saveOfferMultipart({
    int? id,
    required String titleEn,
    required String titleAr,
    required double origPrice,
    required double offerPrice,
    required double discountPct,
    required String badgeType,
    required String validFrom,
    required String validUntil,
    required int storeId,
    int? productId,
    required int categoryId,
    required int cityId,
    String? descriptionEn,
    String? descriptionAr,
    String? termsEn,
    String? termsAr,
    required bool isFeatured,
    required bool isFlash,
    required bool isInStore,
    required bool isOnline,
    required bool isActive,
    List<XFile>? imageFiles,
  }) async {
    final offerDto = {
      'titleEn': titleEn,
      'titleAr': titleAr,
      'storeId': storeId,
      'categoryId': categoryId,
      'cityId': cityId,
      'productId': productId,
      'originalPrice': origPrice,
      'offerPrice': offerPrice,
      'discountPct': discountPct,
      'badgeType': badgeType,
      'validFrom': validFrom,
      'validUntil': validUntil,
      'descriptionEn': descriptionEn ?? '',
      'descriptionAr': descriptionAr ?? '',
      'termsEn': termsEn ?? '',
      'termsAr': termsAr ?? '',
      'featured': isFeatured,
      'flash': isFlash,
      'online': isOnline,
      'inStore': isInStore,
      'active': isActive,
    };

    try {
      final formMap = <String, dynamic>{
        'data': MultipartFile.fromString(
          jsonEncode(offerDto),
          contentType: MediaType.parse('application/json'),
        ),
      };

      if (imageFiles != null && imageFiles.isNotEmpty) {
        final multipartFiles = <MultipartFile>[];
        for (final img in imageFiles) {
          final bytes = await img.readAsBytes();
          multipartFiles.add(MultipartFile.fromBytes(bytes, filename: img.name));
        }
        formMap['files'] = multipartFiles;
      }

      final formData = FormData.fromMap(formMap);

      if (id != null) {
        final response = await _apiClient.put('/offers/update/$id', data: formData);
        if (response.statusCode == 200 || response.statusCode == 204) {
          if (response.data != null && response.data is Map) {
            final updated = Offer.fromJson(response.data as Map<String, dynamic>);
            final list = [...state.offers];
            final idx = list.indexWhere((o) => o.id == id);
            if (idx != -1) {
              list[idx] = updated;
              state = state.copyWith(offers: list);
            }
          }
          return true;
        }
      } else {
        final response = await _apiClient.post('/offers/create', data: formData);
        if (response.statusCode == 200 || response.statusCode == 201) {
          if (response.data != null && response.data is Map) {
            final created = Offer.fromJson(response.data as Map<String, dynamic>);
            state = state.copyWith(offers: [created, ...state.offers]);
          }
          return true;
        }
      }
    } catch (_) {
      // Fallback direct JSON call
      try {
        if (id != null) {
          await _apiClient.put('/offers/update/$id', data: offerDto);
          return true;
        } else {
          final response = await _apiClient.post('/offers/create', data: offerDto);
          if (response.statusCode == 200 || response.statusCode == 201) {
            if (response.data != null && response.data is Map) {
              final created = Offer.fromJson(response.data as Map<String, dynamic>);
              state = state.copyWith(offers: [created, ...state.offers]);
            }
            return true;
          }
        }
      } catch (_) {}
    }

    // Local fallback update/create
    if (id != null) {
      final list = [...state.offers];
      final idx = list.indexWhere((o) => o.id == id);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          titleEn: titleEn,
          titleAr: titleAr,
          originalPrice: origPrice,
          offerPrice: offerPrice,
          discountPct: discountPct,
          badgeType: badgeType,
          validFrom: validFrom,
          validUntil: validUntil,
          descriptionEn: descriptionEn,
          descriptionAr: descriptionAr,
          termsEn: termsEn,
          termsAr: termsAr,
          storeId: storeId,
          productId: productId,
          categoryId: categoryId,
          cityId: cityId,
          isFeatured: isFeatured ? 1 : 0,
          isFlash: isFlash ? 1 : 0,
          isInStore: isInStore ? 1 : 0,
          isOnline: isOnline ? 1 : 0,
          isActive: isActive ? 1 : 0,
        );
        state = state.copyWith(offers: list);
        return true;
      }
    } else {
      final newId = state.offers.isEmpty ? 1 : state.offers.map((o) => o.id).reduce((a, b) => a > b ? a : b) + 1;
      final newOffer = Offer(
        id: newId,
        storeId: storeId,
        productId: productId,
        categoryId: categoryId,
        cityId: cityId,
        titleEn: titleEn,
        titleAr: titleAr,
        originalPrice: origPrice,
        offerPrice: offerPrice,
        discountPct: discountPct,
        badgeType: badgeType,
        validFrom: validFrom,
        validUntil: validUntil,
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        termsEn: termsEn,
        termsAr: termsAr,
        isFeatured: isFeatured ? 1 : 0,
        isFlash: isFlash ? 1 : 0,
        isInStore: isInStore ? 1 : 0,
        isOnline: isOnline ? 1 : 0,
        isActive: isActive ? 1 : 0,
        viewCount: 0,
        saveCount: 0,
      );
      state = state.copyWith(offers: [newOffer, ...state.offers]);
      return true;
    }
    return false;
  }

  Future<void> createOffer(String titleEn, String titleAr, double origPrice, double offerPrice, String badge, String from, String until, int storeId, int? prodId, int categoryId, int cityId, int isFeatured, int isFlash, int isActive) async {
    final discount = origPrice > 0 ? ((origPrice - offerPrice) / origPrice * 100).roundToDouble() : 0.0;
    await saveOfferMultipart(
      titleEn: titleEn,
      titleAr: titleAr,
      origPrice: origPrice,
      offerPrice: offerPrice,
      discountPct: discount,
      badgeType: badge,
      validFrom: from,
      validUntil: until,
      storeId: storeId,
      productId: prodId,
      categoryId: categoryId,
      cityId: cityId,
      isFeatured: isFeatured == 1,
      isFlash: isFlash == 1,
      isInStore: true,
      isOnline: false,
      isActive: isActive == 1,
    );
  }

  Future<void> updateOffer(
    int id,
    String titleEn,
    String titleAr,
    double origPrice,
    double offerPrice,
    String badge,
    String from,
    String until,
    int storeId,
    int? prodId,
    int categoryId,
    int cityId,
    int isFeatured,
    int isFlash,
    int isActive,
  ) async {
    final discount = origPrice > 0
        ? ((origPrice - offerPrice) / origPrice * 100).roundToDouble()
        : 0.0;
    await saveOfferMultipart(
      id: id,
      titleEn: titleEn,
      titleAr: titleAr,
      origPrice: origPrice,
      offerPrice: offerPrice,
      discountPct: discount,
      badgeType: badge,
      validFrom: from,
      validUntil: until,
      storeId: storeId,
      productId: prodId,
      categoryId: categoryId,
      cityId: cityId,
      isFeatured: isFeatured == 1,
      isFlash: isFlash == 1,
      isInStore: true,
      isOnline: false,
      isActive: isActive == 1,
    );
  }

  Future<void> deleteOffer(int id) async {
    try {
      await _apiClient.delete('/offers/delete/$id');
    } catch (_) {}

    state = state.copyWith(
      offers: state.offers.where((o) => o.id != id).toList(),
      images: state.images.where((img) => img.offerId != id).toList(),
    );
  }

  // Offer Images CRUD
  List<OfferImage> getOfferImages(int offerId) {
    return state.images.where((i) => i.offerId == offerId).toList();
  }

  void createOfferImage(int offerId, String imageUrl, int sortOrder) {
    final newId = state.images.isEmpty ? 1 : state.images.map((i) => i.id).reduce((a, b) => a > b ? a : b) + 1;
    final img = OfferImage(
      id: newId,
      offerId: offerId,
      imageUrl: imageUrl,
      sortOrder: sortOrder,
    );
    state = state.copyWith(images: [...state.images, img]);
  }

  void addOfferImage(int offerId, String imageUrl, int sortOrder) {
    createOfferImage(offerId, imageUrl, sortOrder);
  }

  void deleteOfferImage(int id) {
    state = state.copyWith(
      images: state.images.where((i) => i.id != id).toList(),
    );
  }

  // Customer Bookmark / Save Toggle
  Future<bool> toggleSaveOffer(int offerId) async {
    final isCurrentlySaved = state.savedOfferIds.contains(offerId);
    final updatedList = List<int>.from(state.savedOfferIds);
    final offersList = [...state.offers];
    final offerIdx = offersList.indexWhere((o) => o.id == offerId);

    if (isCurrentlySaved) {
      updatedList.remove(offerId);
      if (offerIdx != -1) {
        offersList[offerIdx] = offersList[offerIdx].copyWith(saveCount: offersList[offerIdx].saveCount - 1);
      }
    } else {
      updatedList.add(offerId);
      if (offerIdx != -1) {
        offersList[offerIdx] = offersList[offerIdx].copyWith(saveCount: offersList[offerIdx].saveCount + 1);
      }
    }

    state = state.copyWith(savedOfferIds: updatedList, offers: offersList);

    try {
      await _apiClient.post('/offers/$offerId/save-toggle');
    } catch (_) {}

    return !isCurrentlySaved;
  }
}

final offerRepositoryProvider = StateNotifierProvider<OfferNotifier, OfferState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OfferNotifier(ref, apiClient);
});
