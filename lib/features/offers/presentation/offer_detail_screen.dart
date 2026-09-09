import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String _activeTab = 'overview'; // 'overview' | 'specs' | 'store' | 'terms'
  bool _couponRevealed = false;
  bool _couponCopied = false;
  bool _linkCopied = false;
  bool _isLoading = true;
  Offer? _offer;

  @override
  void initState() {
    super.initState();
    _loadOfferDetails();
  }

  @override
  void didUpdateWidget(OfferDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offerId != widget.offerId) {
      setState(() {
        _isLoading = true;
        _activeImageIndex = 0;
        _activeTab = 'overview';
      });
      _loadOfferDetails();
    }
  }

  Future<void> _loadOfferDetails() async {
    // 1. Check local cache first for instant render
    final cached = ref.read(offerRepositoryProvider.notifier).getOfferById(widget.offerId);
    if (cached != null && mounted) {
      setState(() {
        _offer = cached;
        _isLoading = false;
      });
    }

    try {
      final offer = await ref.read(offerRepositoryProvider.notifier).fetchOfferById(widget.offerId);
      final finalOffer = offer ?? cached;
      if (finalOffer != null) {
        if (mounted) {
          setState(() {
            _offer = finalOffer;
          });
        }
        if (finalOffer.productId != null) {
          ref.read(productRepositoryProvider.notifier).fetchProductById(finalOffer.productId!);
          ref.read(productRepositoryProvider.notifier).fetchProductDetails(finalOffer.productId!);
        }
        if (finalOffer.storeId > 0) {
          ref.read(storeRepositoryProvider.notifier).fetchStoreById(finalOffer.storeId);
          ref.read(storeRepositoryProvider.notifier).fetchBranchesForStore(finalOffer.storeId);
          ref.read(couponRepositoryProvider.notifier).fetchCoupons(storeId: finalOffer.storeId);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openLightbox(BuildContext context, List<String> imageUrls, int initialIndex) {
    if (imageUrls.isEmpty) return;
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
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: imageUrls[index],
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                            ),
                            errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54, size: 64),
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

  void _handleSaveToggle(Offer offer, AppLocalizations tr) {
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    if (!isLoggedIn) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Text(tr.get('sign_in_required'), style: const TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(tr.get('sign_in_to_save')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr.get('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/login?returnUrl=${Uri.encodeComponent(GoRouterState.of(context).matchedLocation)}');
              },
              child: Text(tr.get('login')),
            ),
          ],
        ),
      );
      return;
    }

    ref.read(offerRepositoryProvider.notifier).toggleSaveOffer(offer.id);
    setState(() {});
  }

  void _shareOffer(Offer offer, AppLocalizations tr) {
    final title = offer.titleEn.isNotEmpty ? offer.titleEn : 'DealSpot Offer';
    final shareUrl = 'https://dealspot.sa/offers/${offer.id}';
    final shareText = '$title - $shareUrl';

    Clipboard.setData(ClipboardData(text: shareText));
    setState(() => _linkCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr.get('copied')),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _linkCopied = false);
    });
  }

  void _copyCouponCode(String code, AppLocalizations tr) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _couponCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr.get('code_copied')),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _couponCopied = false);
    });
  }

  String _getDaysRemainingText(String validUntilStr, AppLocalizations tr) {
    if (validUntilStr.isEmpty) return '';
    try {
      final today = DateTime.now();
      final dateOnlyToday = DateTime(today.year, today.month, today.day);
      final expiry = DateTime.parse(validUntilStr.split('T')[0]);
      final dateOnlyExpiry = DateTime(expiry.year, expiry.month, expiry.day);
      final diffDays = dateOnlyExpiry.difference(dateOnlyToday).inDays;

      if (diffDays < 0) {
        return tr.get('expired');
      } else if (diffDays == 0) {
        return tr.get('ends_today');
      } else if (diffDays == 1) {
        return tr.get('ends_tomorrow');
      } else {
        return '$diffDays ${tr.get('days_remaining')}';
      }
    } catch (_) {
      return '';
    }
  }

  Future<void> _openMapLocation(StoreBranch branch) async {
    final lat = branch.latitude;
    final lng = branch.longitude;
    final query = branch.addressEn ?? branch.addressLine ?? branch.branchName;

    if (lat != 0.0 && lng != 0.0) {
      // 1. Try Native Geo URI (Google Maps / Apple Maps app)
      final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
      try {
        final launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (_) {}

      // 2. Try Google Maps Web URL with external application
      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      try {
        final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (_) {}

      // 3. Fallback to platform default
      try {
        await launchUrl(webUri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    } else {
      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query.isNotEmpty ? query : 'Saudi Arabia')}');
      try {
        final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (_) {}

      try {
        await launchUrl(webUri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final offerState = ref.watch(offerRepositoryProvider);
    final offerFromRepo = offerState.offers.where((o) => o.id == widget.offerId).firstOrNull;
    final offer = (offerFromRepo != null
            ? ref.read(offerRepositoryProvider.notifier).getOfferById(widget.offerId)
            : null) ??
        _offer;

    if (offer == null) {
      if (_isLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(color: Color(0xFF16A34A)),
          ),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                tr.get('no_offers_found'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                tr.get('no_offers_match_desc'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.go('/offers'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(tr.get('explore_offers')),
              ),
            ],
          ),
        ),
      );
    }

    final product = offer.product ??
        (offer.productId != null
            ? ref.watch(productRepositoryProvider.notifier).getProductById(offer.productId!)
            : null);

    final store = offer.store ??
        (offer.storeId > 0
            ? ref.watch(storeRepositoryProvider.notifier).getStoreById(offer.storeId)
            : null);

    final branches = offer.storeId > 0
        ? ref.watch(storeRepositoryProvider.notifier).getBranchesForStore(offer.storeId)
        : <StoreBranch>[];

    final productSpecs = offer.productId != null
        ? ref.watch(productRepositoryProvider.notifier).getProductDetails(offer.productId!)
        : <ProductDetail>[];

    final coupon = ref.watch(couponRepositoryProvider.notifier).getCoupons(storeId: offer.storeId).firstOrNull;

    final isSaved = offer.isSaved == true;
    final isExpired = offer.isExpired || offer.status == 'EXPIRED';

    // Titles & Localized fields
    final offerTitle = isRtl ? (offer.titleAr.isNotEmpty ? offer.titleAr : offer.titleEn) : offer.titleEn;
    final productName = product != null
        ? (isRtl ? (product.nameAr.isNotEmpty ? product.nameAr : product.nameEn) : product.nameEn)
        : offerTitle;
    final brandName = product != null && product.brand.isNotEmpty
        ? (isRtl ? (product.brandAr.isNotEmpty ? product.brandAr : product.brand) : product.brand)
        : '';
    final storeName = store != null
        ? (isRtl ? (store.nameAr.isNotEmpty ? store.nameAr : store.nameEn) : store.nameEn)
        : '';
    final categoryName = offer.category != null
        ? (isRtl ? (offer.category!.nameAr.isNotEmpty ? offer.category!.nameAr : offer.category!.nameEn) : offer.category!.nameEn)
        : '';
    final cityName = offer.city != null
        ? (isRtl ? offer.city!.nameAr : offer.city!.nameEn)
        : (store?.city != null ? (isRtl ? store!.city!.nameAr : store!.city!.nameEn) : '');

    final offerDesc = isRtl
        ? (offer.descriptionAr ?? offer.descriptionEn ?? '')
        : (offer.descriptionEn ?? offer.descriptionAr ?? '');
    final productDesc = product != null
        ? (isRtl ? (product.descriptionAr ?? product.descriptionEn ?? '') : (product.descriptionEn ?? product.descriptionAr ?? ''))
        : '';

    // Build complete image list (Noon style: Offer image + gallery images + product images)
    final List<String> galleryImages = [];
    if (offer.imageUrl != null && offer.imageUrl!.trim().isNotEmpty) {
      final url = AppConfig.normalizeImageUrl(offer.imageUrl!);
      if (!galleryImages.contains(url)) galleryImages.add(url);
    }
    if (offer.images != null && offer.images!.isNotEmpty) {
      for (final img in offer.images!) {
        final url = AppConfig.normalizeImageUrl(img.imageUrl);
        if (url.isNotEmpty && !galleryImages.contains(url)) {
          galleryImages.add(url);
        }
      }
    }
    if (product != null) {
      if (product.primaryImageUrl.isNotEmpty) {
        final url = AppConfig.normalizeImageUrl(product.primaryImageUrl);
        if (!galleryImages.contains(url)) galleryImages.add(url);
      }
      if (product.images != null && product.images!.isNotEmpty) {
        for (final img in product.images!) {
          final url = AppConfig.normalizeImageUrl(img.imageUrl);
          if (url.isNotEmpty && !galleryImages.contains(url)) {
            galleryImages.add(url);
          }
        }
      }
    }
    if (galleryImages.isEmpty) {
      galleryImages.add(AppConfig.normalizeImageUrl(''));
    }

    final activeImgUrl = galleryImages[_activeImageIndex.clamp(0, galleryImages.length - 1)];

    final savingsAmount = offer.originalPrice > offer.offerPrice
        ? (offer.originalPrice - offer.offerPrice)
        : 0.0;

    final daysRemainingText = _getDaysRemainingText(offer.validUntil, tr);

    final similarDeals = ref
        .watch(offerRepositoryProvider.notifier)
        .getOffers(OfferFilters(categoryId: offer.categoryId))
        .where((o) => o.id != offer.id)
        .take(6)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Breadcrumb & Top Quick Actions Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF131C2E) : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => context.go('/'),
                          child: Row(
                            children: [
                              const Icon(Icons.home_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(tr.get('home'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text('›', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                        InkWell(
                          onTap: () => context.go('/offers'),
                          child: Text(tr.get('offers'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                        if (categoryName.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Text('›', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ),
                          InkWell(
                            onTap: () => context.go('/offers?categoryId=${offer.categoryId}'),
                            child: Text(
                              categoryName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Top Quick Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _handleSaveToggle(offer, tr),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSaved
                              ? const Color(0xFFDC2626).withOpacity(0.12)
                              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSaved ? const Color(0xFFDC2626) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSaved ? Icons.favorite : Icons.favorite_border,
                              color: isSaved ? const Color(0xFFDC2626) : Colors.grey,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSaved ? tr.get('saved') : tr.get('save'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isSaved ? const Color(0xFFDC2626) : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _shareOffer(offer, tr),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _linkCopied ? Icons.check : Icons.share_outlined,
                              color: _linkCopied ? const Color(0xFF16A34A) : Colors.grey,
                              size: 15,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _linkCopied ? tr.get('copied') : tr.get('share'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: _linkCopied ? const Color(0xFF16A34A) : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Expired Offer Alert Banner
          if (isExpired) ...[
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr.get('expired_banner_title'),
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${tr.get('until')}${offer.validUntil}. ${tr.get('expired_banner_desc')}',
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 3. Noon-Style Image Viewport & Gallery
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.15,
                      child: InkWell(
                        onTap: () => _openLightbox(context, galleryImages, _activeImageIndex),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: CachedNetworkImage(
                            imageUrl: activeImgUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Discount Pill (Top-Start)
                    if (offer.discountPct > 0)
                      Positioned(
                        top: 12,
                        left: isRtl ? null : 12,
                        right: isRtl ? 12 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.4), blurRadius: 6),
                            ],
                          ),
                          child: Text(
                            '${offer.discountPct.toInt()}% ${tr.get('off')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),

                    // Floating Favorite / Heart Button (Top-End)
                    Positioned(
                      top: 12,
                      right: isRtl ? null : 12,
                      left: isRtl ? 12 : null,
                      child: InkWell(
                        onTap: () => _handleSaveToggle(offer, tr),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6),
                            ],
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? const Color(0xFFEF4444) : Colors.grey.shade700,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    // Zoom icon (Bottom-End)
                    Positioned(
                      bottom: 12,
                      right: isRtl ? null : 12,
                      left: isRtl ? 12 : null,
                      child: InkWell(
                        onTap: () => _openLightbox(context, galleryImages, _activeImageIndex),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                        ),
                      ),
                    ),

                    // Image Counter (Bottom-Start)
                    if (galleryImages.length > 1)
                      Positioned(
                        bottom: 12,
                        left: isRtl ? null : 12,
                        right: isRtl ? 12 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_activeImageIndex + 1}/${galleryImages.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Thumbnails strip
                if (galleryImages.length > 1) ...[
                  const Divider(height: 1),
                  SizedBox(
                    height: 68,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      itemCount: galleryImages.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _activeImageIndex;
                        return InkWell(
                          onTap: () => setState(() => _activeImageIndex = index),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 52,
                            height: 52,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF16A34A) : Colors.grey.withOpacity(0.25),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: galleryImages[index],
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

          // 4. Center Core Info Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clickable Brand Link Row
                if (brandName.isNotEmpty) ...[
                  InkWell(
                    onTap: () {
                      final brandParam = product?.brandId != null ? 'brandId=${product!.brandId}' : 'brand=${Uri.encodeComponent(brandName)}';
                      context.go('/offers?$brandParam');
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
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
                          const SizedBox(width: 3),
                          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF16A34A)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Main Product Name / Offer Title
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // Special Offer Spotlight Card (Noon Style)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF143823), const Color(0xFF1E293B)]
                          : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.35)),
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
                        offerTitle,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                      if (offerDesc.isNotEmpty && offerDesc != offerTitle) ...[
                        const SizedBox(height: 4),
                        Text(
                          offerDesc,
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
                const SizedBox(height: 14),

                // Rating & Verified Deal Row
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '4.8',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.star, color: Color(0xFFF59E0B), size: 13),
                        ],
                      ),
                    ),
                    Text(
                      '(47 ${tr.get('ratings')})',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                    ),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 14),
                        const SizedBox(width: 3),
                        Text(
                          tr.get('verified_deal'),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                    if (offer.isFlash == 1 || offer.badgeType == 'FLASH') ...[
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt, color: Color(0xFFDC2626), size: 13),
                            const SizedBox(width: 2),
                            Text(
                              tr.get('flash_deals'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Pricing Bar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${tr.get('sar')} ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    Text(
                      offer.offerPrice.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    if (offer.originalPrice > offer.offerPrice) ...[
                      const SizedBox(width: 10),
                      Text(
                        offer.originalPrice.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 15,
                          decoration: TextDecoration.lineThrough,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                        ),
                        child: Text(
                          '${offer.discountPct.toInt()}% ${tr.get('off')}',
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Total Savings Note
                if (savingsAmount > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${tr.get('total_savings')} ${savingsAmount.toStringAsFixed(2)} ${tr.get('sar')}',
                    style: const TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                const SizedBox(height: 4),
                Text(
                  tr.get('vat_inclusive'),
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45),
                ),

                // Top Deal / Bestseller Bar
                if (categoryName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => context.go('/offers?categoryId=${offer.categoryId}'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFACC15).withOpacity(0.6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars, color: Color(0xFFCA8A04), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${tr.get('top_deal')} ${tr.get('in')} $categoryName',
                              style: const TextStyle(
                                color: Color(0xFF854D0E),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFF854D0E), size: 16),
                        ],
                      ),
                    ),
                  ),
                ],

                // Delivery & Availability Chips
                const SizedBox(height: 16),
                Text(
                  tr.get('delivery_availability'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (offer.isInStore == 1)
                      _buildDeliveryChip(Icons.storefront, tr.get('in_store'), tr.get('in_store_desc'), isDark),
                    if (offer.isOnline == 1)
                      _buildDeliveryChip(Icons.language, tr.get('online'), tr.get('online_desc'), isDark),
                    if (cityName.isNotEmpty)
                      _buildDeliveryChip(Icons.place, cityName, 'KSA', isDark),
                  ],
                ),

                // Coupons Section (if available)
                if (coupon != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    tr.get('coupons_offers'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.local_offer, color: Color(0xFF16A34A), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr.get('exclusive_voucher'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                tr.get('redeem_code_desc'),
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _couponRevealed ? const Color(0xFF047857) : const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            if (!_couponRevealed) {
                              setState(() => _couponRevealed = true);
                            } else {
                              _copyCouponCode(coupon.code, tr);
                            }
                          },
                          icon: Icon(
                            _couponRevealed ? (_couponCopied ? Icons.check : Icons.content_copy) : Icons.lock_open,
                            size: 14,
                          ),
                          label: Text(
                            _couponRevealed ? coupon.code : tr.get('reveal_code'),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 5. Retailer Store Card
          if (store != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: AppConfig.normalizeImageUrl(store.logoUrl),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey.shade200),
                          errorWidget: (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: const Color(0xFFEFF6FF),
                            child: const Icon(Icons.store, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.get('sold_by'),
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
                            ),
                            InkWell(
                              onTap: () => context.go('/stores/${store.id}'),
                              child: Text(
                                storeName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (store.isVerified == 1) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.verified, color: Color(0xFF16A34A), size: 14),
                                  const SizedBox(width: 3),
                                  Text(
                                    tr.get('verified_partner'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  InkWell(
                    onTap: () => context.go('/stores/${store.id}'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr.get('view_all_store_offers'),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFF16A34A), size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 6. Action Box (Primary CTA)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSaved ? const Color(0xFF047857) : const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _handleSaveToggle(offer, tr),
                    icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_add_outlined, size: 20),
                    label: Text(
                      isSaved ? tr.get('saved_to_favorites') : tr.get('save_to_favorites'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _shareOffer(offer, tr),
                    icon: Icon(_linkCopied ? Icons.check : Icons.share_outlined, size: 18),
                    label: Text(
                      _linkCopied ? tr.get('copied') : tr.get('share_offer'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 7. Trust & Guarantee Checklist
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildTrustRow(
                  Icons.verified_user_outlined,
                  tr.get('genuine_offer'),
                  tr.get('genuine_offer_desc'),
                  isDark,
                ),
                const Divider(height: 16),
                _buildTrustRow(
                  Icons.savings_outlined,
                  tr.get('instant_savings'),
                  tr.get('instant_savings_desc'),
                  isDark,
                ),
                if (daysRemainingText.isNotEmpty) ...[
                  const Divider(height: 16),
                  _buildTrustRow(
                    Icons.schedule_outlined,
                    daysRemainingText,
                    '${tr.get('valid_to')}${offer.validUntil}',
                    isDark,
                  ),
                ],
              ],
            ),
          ),

          // 8. Full-Width Bottom Tabs Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Tab Navigation Header
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      _buildTabButton('overview', Icons.description_outlined, tr.get('offer_overview')),
                      if (product != null || productSpecs.isNotEmpty)
                        _buildTabButton('specs', Icons.tune, tr.get('product_specs')),
                      if (branches.isNotEmpty)
                        _buildTabButton('store', Icons.place_outlined, '${tr.get('store_branches')} (${branches.length})'),
                      if ((offer.termsEn != null && offer.termsEn!.isNotEmpty) || (offer.termsAr != null && offer.termsAr!.isNotEmpty))
                        _buildTabButton('terms', Icons.gavel_outlined, tr.get('terms_rules')),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Tab Content Panes
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildActiveTabContent(
                    offer: offer,
                    product: product,
                    productSpecs: productSpecs,
                    branches: branches,
                    brandName: brandName,
                    categoryName: categoryName,
                    cityName: cityName,
                    offerDesc: offerDesc,
                    productDesc: productDesc,
                    tr: tr,
                    isDark: isDark,
                    isRtl: isRtl,
                  ),
                ),
              ],
            ),
          ),

          // 9. Similar Deals Carousel
          if (similarDeals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                tr.get('similar_deals'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: similarDeals.length,
                itemBuilder: (context, index) {
                  final deal = similarDeals[index];
                  final dTitle = isRtl ? (deal.titleAr.isNotEmpty ? deal.titleAr : deal.titleEn) : deal.titleEn;
                  final dImg = (deal.images != null && deal.images!.isNotEmpty)
                      ? deal.images!.first.imageUrl
                      : (deal.imageUrl ?? deal.product?.primaryImageUrl ?? '');

                  return Container(
                    width: 170,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => context.go('/offers/${deal.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1.3,
                                  child: CachedNetworkImage(
                                    imageUrl: AppConfig.normalizeImageUrl(dImg),
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: Colors.grey.shade200),
                                    errorWidget: (_, __, ___) => const Center(child: Icon(Icons.image)),
                                  ),
                                ),
                                if (deal.discountPct > 0)
                                  Positioned(
                                    top: 6,
                                    left: isRtl ? null : 6,
                                    right: isRtl ? 6 : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${deal.discountPct.toInt()}% ${tr.get('off')}',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.3),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        '${deal.offerPrice.toStringAsFixed(0)} ${tr.get('sar')}',
                                        style: const TextStyle(
                                          color: Color(0xFF16A34A),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (deal.originalPrice > deal.offerPrice) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          deal.originalPrice.toStringAsFixed(0),
                                          style: TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            fontSize: 10.5,
                                            color: isDark ? Colors.white38 : Colors.black38,
                                          ),
                                        ),
                                      ],
                                    ],
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
    );
  }

  Widget _buildDeliveryChip(IconData icon, String title, String subtitle, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF16A34A)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black45),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustRow(IconData icon, String title, String subtitle, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF16A34A).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF16A34A), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String tabKey, IconData icon, String label) {
    final isSelected = _activeTab == tabKey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => setState(() => _activeTab = tabKey),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF16A34A).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF16A34A) : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF16A34A) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent({
    required Offer offer,
    required Product? product,
    required List<ProductDetail> productSpecs,
    required List<StoreBranch> branches,
    required String brandName,
    required String categoryName,
    required String cityName,
    required String offerDesc,
    required String productDesc,
    required AppLocalizations tr,
    required bool isDark,
    required bool isRtl,
  }) {
    switch (_activeTab) {
      case 'overview':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (offerDesc.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 6),
                  Text(tr.get('about_offer'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                offerDesc,
                style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
              const SizedBox(height: 16),
            ],
            if (productDesc.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 6),
                  Text(tr.get('product_description'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                productDesc,
                style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
              const SizedBox(height: 16),
            ],

            // Quick Highlights 2x2 Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: [
                if (offer.discountPct > 0)
                  _buildHighlightCard(tr.get('discount'), '${offer.discountPct.toInt()}% ${tr.get('off')}', const Color(0xFF16A34A), isDark),
                if (product != null && product.unit.isNotEmpty)
                  _buildHighlightCard(tr.get('unit_size'), '${product.unitSize.toStringAsFixed(0)} ${product.unit}', isDark ? Colors.white : Colors.black87, isDark),
                if (cityName.isNotEmpty)
                  _buildHighlightCard(tr.get('city'), cityName, isDark ? Colors.white : Colors.black87, isDark),
                if (offer.validUntil.isNotEmpty)
                  _buildHighlightCard(tr.get('end_date'), offer.validUntil, isDark ? Colors.white : Colors.black87, isDark),
              ],
            ),
          ],
        );

      case 'specs':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Table(
              border: TableBorder.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              children: [
                if (product != null)
                  _buildTableRow(tr.get('product_name'), isRtl ? (product.nameAr.isNotEmpty ? product.nameAr : product.nameEn) : product.nameEn, isDark),
                if (brandName.isNotEmpty)
                  _buildTableRow(tr.get('brand'), brandName, isDark),
                if (categoryName.isNotEmpty)
                  _buildTableRow(tr.get('category'), categoryName, isDark),
                if (product != null && product.sku.isNotEmpty)
                  _buildTableRow(tr.get('sku_code'), product.sku, isDark),
                if (product != null && product.barcode.isNotEmpty)
                  _buildTableRow(tr.get('barcode'), product.barcode, isDark),
                if (product != null && product.unit.isNotEmpty)
                  _buildTableRow(tr.get('size_unit'), '${product.unitSize.toStringAsFixed(0)} ${product.unit}', isDark),
                ...productSpecs.map((spec) {
                  final k = isRtl ? (spec.attrKeyAr.isNotEmpty ? spec.attrKeyAr : spec.attrKeyEn) : spec.attrKeyEn;
                  final v = isRtl ? (spec.attrValueAr.isNotEmpty ? spec.attrValueAr : spec.attrValueEn) : spec.attrValueEn;
                  return _buildTableRow(k, v, isDark);
                }),
              ],
            ),
          ],
        );

      case 'store':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: branches.map((b) {
            final branchName = isRtl ? (b.branchName.isNotEmpty ? b.branchName : b.branchName) : b.branchName;
            final branchAddress = isRtl ? (b.addressAr ?? b.addressLine ?? '') : (b.addressEn ?? b.addressLine ?? '');
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.store, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(branchName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      ),
                    ],
                  ),
                  if (branchAddress.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(child: Text(branchAddress, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                      ],
                    ),
                  ],
                  if (b.openTime.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('${b.openTime} - ${b.closeTime}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                  if (b.contactPhone != null && b.contactPhone!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(b.contactPhone!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFF16A34A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _openMapLocation(b),
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: Text(tr.get('open_maps'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

      case 'terms':
        final termsText = isRtl
            ? (offer.termsAr ?? offer.termsEn ?? '')
            : (offer.termsEn ?? offer.termsAr ?? '');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF16A34A), size: 18),
                const SizedBox(width: 6),
                Text(tr.get('terms_rules'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              termsText.isNotEmpty ? termsText : tr.get('terms_disclaimer'),
              style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white70 : const Color(0xFF334155)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.help_outline, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr.get('terms_disclaimer'),
                      style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHighlightCard(String label, String value, Color valueColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String value, bool isDark) {
    return TableRow(
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : const Color(0xFFF8FAFC),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
