import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/offer_repository.dart';
import '../../../core/services/store_repository.dart';
import '../../../core/services/product_repository.dart';
import '../../../core/services/coupon_repository.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

class OfferDetailScreen extends ConsumerStatefulWidget {
  final int offerId;

  const OfferDetailScreen({super.key, required this.offerId});

  @override
  ConsumerState<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends ConsumerState<OfferDetailScreen> {
  int _activeImageIndex = 0;
  bool _copiedCoupon = false;

  void _openLightbox(BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (ctx) {
        int currentIndex = initialIndex;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: imageUrls.length,
                    controller: PageController(initialPage: initialIndex),
                    onPageChanged: (idx) => setDialogState(() => currentIndex = idx),
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: imageUrls[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${currentIndex + 1} / ${imageUrls.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final offer = ref.watch(offerRepositoryProvider.notifier).getOfferById(widget.offerId);

    if (offer == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Offer not found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/offers'),
                child: const Text('Back to Offers'),
              ),
            ],
          ),
        ),
      );
    }

    final isSaved = offer.isSaved == true;
    final title = isRtl ? offer.titleAr : offer.titleEn;
    final productName = offer.product != null ? (isRtl ? offer.product!.nameAr : offer.product!.nameEn) : null;
    final brandName = offer.product != null ? (isRtl ? (offer.product!.brandAr ?? offer.product!.brand) : offer.product!.brand) : null;
    final storeName = isRtl ? (offer.store?.nameAr ?? '') : (offer.store?.nameEn ?? '');
    final categoryName = isRtl ? (offer.category?.nameAr ?? '') : (offer.category?.nameEn ?? '');
    final description = isRtl ? (offer.product?.descriptionAr ?? title) : (offer.product?.descriptionEn ?? title);

    // Images list
    final List<String> imageUrls = (offer.images != null && offer.images!.isNotEmpty)
        ? offer.images!
            .map((img) => AppConfig.normalizeImageUrl(img.imageUrl))
            .where((u) => u.trim().isNotEmpty)
            .toList()
        : ((offer.product?.primaryImageUrl != null && offer.product!.primaryImageUrl!.trim().isNotEmpty)
            ? [AppConfig.normalizeImageUrl(offer.product!.primaryImageUrl!)]
            : []);

    // Product specs
    final productSpecs = offer.productId != null
        ? ref.watch(productRepositoryProvider.notifier).getProductDetails(offer.productId!)
        : <ProductDetail>[];

    // Coupons
    final coupon = ref.watch(couponRepositoryProvider.notifier).getCoupons(storeId: offer.storeId).firstOrNull;

    // Similar Deals
    final similarDeals = ref.watch(offerRepositoryProvider.notifier)
        .getOffers(OfferFilters(categoryId: offer.categoryId))
        .where((o) => o.id != offer.id)
        .take(4)
        .toList();

    final savingsAmount = offer.originalPrice > offer.offerPrice ? (offer.originalPrice - offer.offerPrice) : 0.0;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(storeName.isNotEmpty ? storeName : tr.get('offers')),
          actions: [
            // Share
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: tr.get('share'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: 'https://dealspot.sa/offers/${offer.id}'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr.get('copied')), duration: const Duration(seconds: 1)),
                );
              },
            ),
            // Bookmark / Save
            IconButton(
              icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
              color: isSaved ? const Color(0xFF16A34A) : null,
              tooltip: tr.get('save'),
              onPressed: () {
                final isLoggedIn = ref.read(authProvider).isLoggedIn;
                if (!isLoggedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr.get('save_offer_login'))),
                  );
                  return;
                }
                ref.read(offerRepositoryProvider.notifier).toggleSaveOffer(offer.id);
                setState(() {});
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Breadcrumb navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.go('/'),
                      child: Text(tr.get('home'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('›', style: TextStyle(color: Colors.grey))),
                    InkWell(
                      onTap: () => context.go('/offers'),
                      child: Text(tr.get('offers'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                    if (categoryName.isNotEmpty) ...[
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('›', style: TextStyle(color: Colors.grey))),
                      Text(categoryName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ],
                ),
              ),

              // 2. Noon-style Gallery View
              if (imageUrls.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      // Main Image Frame
                      Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 1.25,
                            child: InkWell(
                              onTap: () => _openLightbox(context, imageUrls, _activeImageIndex),
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrls[_activeImageIndex.clamp(0, imageUrls.length - 1)],
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),

                          // Discount badge
                          if (offer.discountPct > 0)
                            Positioned(
                              top: 12,
                              left: isRtl ? null : 12,
                              right: isRtl ? 12 : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.3), blurRadius: 4),
                                  ],
                                ),
                                child: Text(
                                  '${offer.discountPct.toInt()}% ${tr.get('off')}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),

                          // Fullscreen Zoom hint
                          Positioned(
                            bottom: 10,
                            right: isRtl ? null : 10,
                            left: isRtl ? 10 : null,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                            ),
                          ),

                          // Image Counter
                          if (imageUrls.length > 1)
                            Positioned(
                              bottom: 10,
                              left: isRtl ? null : 10,
                              right: isRtl ? 10 : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_activeImageIndex + 1}/${imageUrls.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Thumbnail Strip
                      if (imageUrls.length > 1) ...[
                        const Divider(height: 1),
                        SizedBox(
                          height: 64,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              final isSelected = index == _activeImageIndex;
                              return InkWell(
                                onTap: () => setState(() => _activeImageIndex = index),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF16A34A) : Colors.grey.withOpacity(0.3),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrls[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Core Info Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clickable Brand Row
                    if (brandName != null) ...[
                      InkWell(
                        onTap: () => context.go('/offers?brandId=${offer.product?.brand}'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              brandName,
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 16, color: Color(0xFF16A34A)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Title / Product Name
                    Text(
                      productName ?? title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Special Offer Spotlight Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF163E27), const Color(0xFF1E293B)]
                              : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.local_offer, color: Colors.white, size: 14),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr.get('special_offer'),
                                style: const TextStyle(
                                  color: Color(0xFF15803D),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                          ),
                          if (description.isNotEmpty && description != title) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price Section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${offer.offerPrice.toStringAsFixed(0)} ${tr.get('sar')}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        if (offer.originalPrice > offer.offerPrice) ...[
                          const SizedBox(width: 10),
                          Text(
                            '${offer.originalPrice.toStringAsFixed(0)} ${tr.get('sar')}',
                            style: TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Savings Pill
                    if (savingsAmount > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                        ),
                        child: Text(
                          '${tr.get('save_badge')} ${savingsAmount.toStringAsFixed(0)} ${tr.get('sar')} (${offer.discountPct.toInt()}% ${tr.get('off')})',
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),

                    // VAT note
                    Text(
                      tr.get('vat_inclusive'),
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                    ),

                    // Flash Deal countdown bar
                    if (offer.isFlash == 1 || offer.badgeType == 'FLASH') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flash_on, color: Color(0xFFD97706), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${tr.get('flash_deals')} - ${tr.get('ends')}${offer.validUntil}',
                              style: const TextStyle(color: Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Coupon Code Snippet (if available)
              if (coupon != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF16A34A), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coupon.code,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                            ),
                            Text(
                              '${coupon.discountValue.toInt()}% extra discount${coupon.minCartValue != null ? " on min cart ${coupon.minCartValue!.toInt()} SAR" : ""}',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _copiedCoupon ? const Color(0xFF047857) : const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: coupon.code));
                          setState(() => _copiedCoupon = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(tr.get('code_copied')), duration: const Duration(seconds: 1)),
                          );
                        },
                        child: Text(
                          _copiedCoupon ? tr.get('copied') : tr.get('copy_code'),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 5. Redemption Channels
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr.get('redemption_channels'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildChannelItem(Icons.storefront, tr.get('in_store'), tr.get('in_store_desc'), isDark),
                        const SizedBox(width: 8),
                        _buildChannelItem(Icons.language, tr.get('online'), tr.get('online_desc'), isDark),
                        const SizedBox(width: 8),
                        _buildChannelItem(Icons.phone_iphone, tr.get('mobile_app'), tr.get('mobile_app_desc'), isDark),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 6. Retailer Store Info
              if (offer.store != null) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.get('store_info'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (offer.store!.logoUrl != null && offer.store!.logoUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: AppConfig.normalizeImageUrl(offer.store!.logoUrl!),
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        storeName,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (offer.store!.isVerified == 1) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 16),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Partner Retailer • KSA Verified',
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF16A34A),
                              side: const BorderSide(color: Color(0xFF16A34A)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => context.go('/stores/${offer.store!.id}'),
                            child: Text(tr.get('view_store'), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 7. Product Specifications Table
              if (productSpecs.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.get('product_specs'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Table(
                        border: TableBorder.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)),
                        children: productSpecs.map((spec) {
                          final k = isRtl ? spec.attrKeyAr : spec.attrKeyEn;
                          final v = isRtl ? spec.attrValueAr : spec.attrValueEn;
                          return TableRow(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(k, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(v, style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 8. Similar Deals
              if (similarDeals.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    tr.get('similar_deals'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 230,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: similarDeals.length,
                    itemBuilder: (context, index) {
                      final deal = similarDeals[index];
                      final dTitle = isRtl ? deal.titleAr : deal.titleEn;
                      final dImg = (deal.images != null && deal.images!.isNotEmpty)
                          ? deal.images!.first.imageUrl
                          : deal.product?.primaryImageUrl;

                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => context.go('/offers/${deal.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1.35,
                                  child: dImg != null
                                      ? CachedNetworkImage(imageUrl: AppConfig.normalizeImageUrl(dImg), fit: BoxFit.cover)
                                      : const Icon(Icons.image),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dTitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${deal.offerPrice.toStringAsFixed(0)} ${tr.get('sar')}',
                                        style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w900, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelItem(IconData icon, String title, String subtitle, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF16A34A), size: 20),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(fontSize: 8.5, color: isDark ? Colors.white54 : Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}
