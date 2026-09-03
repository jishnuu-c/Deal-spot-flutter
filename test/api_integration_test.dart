import 'package:flutter_test/flutter_test.dart';
import 'package:dealspot_flutter/core/config/app_config.dart';
import 'package:dealspot_flutter/models/models.dart';

void main() {
  group('Data Models & DTO Deserialization', () {
    test('Offer.fromJson correctly parses Spring Boot DTO flat & nested structures', () {
      final jsonDto = {
        'id': 101,
        'titleEn': 'Summer Super Saver Discount',
        'titleAr': 'خصم الصيف التوفيري الممتاز',
        'originalPrice': 200.0,
        'offerPrice': 149.0,
        'discountPct': 25.5,
        'badgeType': 'FLASH',
        'validFrom': '2026-06-01',
        'validUntil': '2026-06-30',
        'storeId': 10,
        'storeNameEn': 'Lulu Hypermarket',
        'storeNameAr': 'لولو هايبرماركت',
        'storeLogoUrl': 'uploads/stores/lulu.png',
        'storeVerified': true,
        'productId': 55,
        'productNameEn': 'Basmati Rice 5kg',
        'productNameAr': 'أرز بسمتي 5 كجم',
        'productPrimaryImageUrl': 'uploads/products/rice.png',
        'brandNameEn': 'Abu Kass',
        'brandNameAr': 'أبو كاس',
        'categoryId': 2,
        'categoryNameEn': 'Groceries',
        'categoryNameAr': 'بقالة',
        'cityId': 1,
        'cityNameEn': 'Riyadh',
        'cityNameAr': 'الرياض',
        'featured': true,
        'flash': true,
        'active': true,
        'viewCount': 420,
        'saveCount': 85,
        'isSaved': true,
      };

      final offer = Offer.fromJson(jsonDto);

      expect(offer.id, equals(101));
      expect(offer.titleEn, equals('Summer Super Saver Discount'));
      expect(offer.store?.nameEn, equals('Lulu Hypermarket'));
      expect(offer.product?.nameEn, equals('Basmati Rice 5kg'));
      expect(offer.product?.brand, equals('Abu Kass'));
      expect(offer.isFeatured, equals(1));
      expect(offer.isFlash, equals(1));
      expect(offer.isSaved, isTrue);
    });

    test('Store.fromJson correctly parses Store DTO with all extended metadata and flags', () {
      final jsonDto = {
        'id': 12,
        'nameEn': 'Panda Supermarket',
        'nameAr': 'أسواق بنده',
        'logoUrl': 'uploads/stores/panda.png',
        'cityId': 1,
        'categoryId': 2,
        'cityNameEn': 'Riyadh',
        'cityNameAr': 'الرياض',
        'categoryNameEn': 'Supermarkets',
        'categoryNameAr': 'سوبرماركت',
        'descriptionEn': 'Leading grocery chain in Saudi Arabia',
        'descriptionAr': 'سلسلة أسواق التجزئة الرائدة في المملكة',
        'crNumber': '1010123456',
        'vatNumber': '300123456700003',
        'contactPhone': '+966501234567',
        'contactEmail': 'info@panda.com.sa',
        'website': 'https://panda.com.sa',
        'isVerified': true,
        'featured': true,
        'active': true,
        'followersCount': 1250,
        'isFollowed': true,
      };

      final store = Store.fromJson(jsonDto);

      expect(store.id, equals(12));
      expect(store.nameEn, equals('Panda Supermarket'));
      expect(store.nameAr, equals('أسواق بنده'));
      expect(store.cityNameEn, equals('Riyadh'));
      expect(store.categoryNameEn, equals('Supermarkets'));
      expect(store.crNumber, equals('1010123456'));
      expect(store.vatNumber, equals('300123456700003'));
      expect(store.contactPhone, equals('+966501234567'));
      expect(store.contactEmail, equals('info@panda.com.sa'));
      expect(store.website, equals('https://panda.com.sa'));
      expect(store.isVerified, equals(1));
      expect(store.isActive, equals(1));
      expect(store.featured, isTrue);
      expect(store.active, isTrue);
      expect(store.verified, isTrue);
      expect(store.followersCount, equals(1250));
      expect(store.isFollowed, isTrue);
    });

    test('Flyer.fromJson correctly parses Flyer DTO', () {
      final jsonDto = {
        'id': 5,
        'storeId': 12,
        'storeNameEn': 'Panda Supermarket',
        'storeNameAr': 'باندا سوبرماركت',
        'cityId': 1,
        'titleEn': 'Weekly Mega Deals Flyer',
        'titleAr': 'بروشور العروض الأسبوعية الكبرى',
        'coverImageUrl': 'uploads/flyers/panda_cover.jpg',
        'totalPages': 16,
        'validFrom': '2026-06-01',
        'validUntil': '2026-06-07',
        'active': true,
        'viewCount': 1200,
      };

      final flyer = Flyer.fromJson(jsonDto);

      expect(flyer.id, equals(5));
      expect(flyer.titleEn, equals('Weekly Mega Deals Flyer'));
      expect(flyer.totalPages, equals(16));
      expect(flyer.store?.nameEn, equals('Panda Supermarket'));
    });

    test('CouponCode.fromJson correctly parses Coupon DTO', () {
      final jsonDto = {
        'id': 8,
        'code': 'DEALSPOT20',
        'discountType': 'PERCENTAGE',
        'discountValue': 20.0,
        'validFrom': '2026-01-01',
        'validUntil': '2026-12-31',
        'active': true,
      };

      final coupon = CouponCode.fromJson(jsonDto);

      expect(coupon.id, equals(8));
      expect(coupon.code, equals('DEALSPOT20'));
      expect(coupon.discountValue, equals(20.0));
      expect(coupon.isActive, equals(1));
    });

    test('PartnerRequest.fromJson correctly parses Partner Request DTO', () {
      final jsonDto = {
        'id': 7,
        'applicantName': 'Ahmed Al-Shehri',
        'applicantEmail': 'ahmed@store.sa',
        'applicantPhone': '+966501234567',
        'storeNameEn': 'Al Raya Supermarket',
        'storeNameAr': 'سوبرماركت الراية',
        'descriptionEn': 'Leading grocery store chain across western province',
        'descriptionAr': 'سلسلة متاجر مواد غذائية رائدة',
        'cityId': 1,
        'cityNameEn': 'Riyadh',
        'cityNameAr': 'الرياض',
        'categoryId': 3,
        'categoryNameEn': 'Supermarket & Groceries',
        'categoryNameAr': 'سوبرماركت ومواد غذائية',
        'crNumber': '1010998877',
        'vatNumber': '300123456700003',
        'website': 'https://alraya.com.sa',
        'status': 'PENDING',
        'createdAt': '2026-06-15T10:30:00',
      };

      final req = PartnerRequest.fromJson(jsonDto);

      expect(req.id, equals(7));
      expect(req.applicantName, equals('Ahmed Al-Shehri'));
      expect(req.applicantEmail, equals('ahmed@store.sa'));
      expect(req.storeNameEn, equals('Al Raya Supermarket'));
      expect(req.storeNameAr, equals('سوبرماركت الراية'));
      expect(req.crNumber, equals('1010998877'));
      expect(req.vatNumber, equals('300123456700003'));
      expect(req.status, equals(PartnerRequestStatus.PENDING));
      expect(req.cityNameEn, equals('Riyadh'));
      expect(req.categoryNameEn, equals('Supermarket & Groceries'));
    });

    test('City.fromJson correctly parses City DTO and handles active state', () {
      final jsonDto = {
        'id': 1,
        'nameEn': 'Riyadh',
        'nameAr': 'الرياض',
        'regionCode': 'RUH',
        'latitude': 24.7136,
        'longitude': 46.6753,
        'active': true,
      };

      final city = City.fromJson(jsonDto);

      expect(city.id, equals(1));
      expect(city.nameEn, equals('Riyadh'));
      expect(city.nameAr, equals('الرياض'));
      expect(city.regionCode, equals('RUH'));
      expect(city.latitude, equals(24.7136));
      expect(city.longitude, equals(46.6753));
      expect(city.isActive, equals(1));
    });

    test('Category.fromJson correctly parses Parent & Sub Category DTOs', () {
      final parentJson = {
        'id': 1,
        'parentId': null,
        'nameEn': 'Electronics',
        'nameAr': 'الإلكترونيات',
        'iconSlug': 'devices',
        'sortOrder': 1,
        'active': true,
      };

      final subJson = {
        'id': 10,
        'parentId': 1,
        'nameEn': 'Smartphones',
        'nameAr': 'الهواتف الذكية',
        'iconSlug': 'phone_android',
        'sortOrder': 1,
        'active': true,
      };

      final parentCat = Category.fromJson(parentJson);
      final subCat = Category.fromJson(subJson);

      expect(parentCat.id, equals(1));
      expect(parentCat.parentId, isNull);
      expect(parentCat.nameEn, equals('Electronics'));
      expect(parentCat.iconSlug, equals('devices'));
      expect(parentCat.isActive, equals(1));

      expect(subCat.id, equals(10));
      expect(subCat.parentId, equals(1));
      expect(subCat.nameEn, equals('Smartphones'));
      expect(subCat.isActive, equals(1));
    });

    test('Brand.fromJson correctly parses Brand DTO with nested categories & flags', () {
      final brandJson = {
        'id': 12,
        'nameEn': 'Samsung',
        'nameAr': 'سامسونج',
        'descriptionEn': 'South Korean multinational manufacturing conglomerate',
        'descriptionAr': 'تكتل شركات كوري جنوبي متعدد الجنسيات',
        'logoUrl': 'uploads/brands/samsung.png',
        'websiteUrl': 'https://www.samsung.com',
        'featured': true,
        'active': true,
        'categories': [
          {
            'id': 1,
            'nameEn': 'Electronics',
            'nameAr': 'الإلكترونيات',
            'iconSlug': 'devices',
            'sortOrder': 1,
            'active': true,
          },
          {
            'id': 10,
            'parentId': 1,
            'nameEn': 'Smartphones',
            'nameAr': 'الهواتف الذكية',
            'iconSlug': 'phone_android',
            'sortOrder': 1,
            'active': true,
          }
        ]
      };

      final brand = Brand.fromJson(brandJson);

      expect(brand.id, equals(12));
      expect(brand.nameEn, equals('Samsung'));
      expect(brand.nameAr, equals('سامسونج'));
      expect(brand.featured, isTrue);
      expect(brand.active, isTrue);
      expect(brand.websiteUrl, equals('https://www.samsung.com'));
      expect(brand.categories.length, equals(2));
      expect(brand.categories.first.nameEn, equals('Electronics'));
      expect(brand.categories.last.nameEn, equals('Smartphones'));
    });

    test('AppConfig.normalizeImageUrl prepends server URL for relative paths', () {
      expect(AppConfig.normalizeImageUrl(null), isEmpty);
      expect(AppConfig.normalizeImageUrl(''), isEmpty);
      expect(AppConfig.normalizeImageUrl('https://example.com/logo.png'), equals('https://example.com/logo.png'));
      expect(AppConfig.normalizeImageUrl('http://example.com/logo.png'), equals('http://example.com/logo.png'));
      expect(AppConfig.normalizeImageUrl('uploads/stores/logo.png'), equals('${AppConfig.filePath}uploads/stores/logo.png'));
    });
  });
}
