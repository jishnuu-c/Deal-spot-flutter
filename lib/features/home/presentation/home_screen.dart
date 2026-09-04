import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/services/category_repository.dart';
import '../../../core/services/offer_repository.dart';
import '../../../core/services/flyer_repository.dart';
import '../../../core/services/brand_repository.dart';
import '../../../core/services/store_repository.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _brandScrollController = ScrollController();
  List<Brand> _featuredBrands = [];
  int _brandPage = 0;
  bool _brandHasMore = true;
  bool _brandLoading = false;
  bool _brandLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _brandScrollController.addListener(_onBrandScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _brandScrollController.removeListener(_onBrandScroll);
    _brandScrollController.dispose();
    super.dispose();
  }

  void _onBrandScroll() {
    if (_brandScrollController.hasClients &&
        _brandScrollController.position.pixels >=
            _brandScrollController.position.maxScrollExtent - 60) {
      if (_brandHasMore && !_brandLoading && !_brandLoadingMore) {
        _loadNextBrandPage();
      }
    }
  }

  Future<void> _loadInitialData() async {
    ref.read(cityRepositoryProvider.notifier).fetchCities();
    ref.read(categoryRepositoryProvider.notifier).fetchCategories();
    ref.read(offerRepositoryProvider.notifier).fetchOffers();
    ref.read(flyerRepositoryProvider.notifier).fetchFlyers();
    ref.read(storeRepositoryProvider.notifier).fetchStores();
    ref.read(offerRepositoryProvider.notifier).fetchSavedOffers();
    _loadFeaturedBrands(page: 0);
  }

  Future<void> _loadFeaturedBrands({int page = 0}) async {
    if (page == 0) {
      setState(() => _brandLoading = true);
    } else {
      setState(() => _brandLoadingMore = true);
    }

    final res = await ref.read(brandRepositoryProvider.notifier).fetchFeaturedBrandsPaged(
      page: page,
      size: 15,
    );

    if (mounted) {
      setState(() {
        if (page == 0) {
          _featuredBrands = res.content;
        } else {
          final existingIds = _featuredBrands.map((b) => b.id).toSet();
          final newItems = res.content.where((b) => !existingIds.contains(b.id)).toList();
          _featuredBrands.addAll(newItems);
        }
        _brandPage = res.number;
        _brandHasMore = !res.isLast && (res.number + 1 < res.totalPages);
        _brandLoading = false;
        _brandLoadingMore = false;
      });
    }
  }

  Future<void> _loadNextBrandPage() async {
    if (_brandLoadingMore || !_brandHasMore) return;
    _loadFeaturedBrands(page: _brandPage + 1);
  }

  IconData _getIconForCategory(Category cat) {
    final slug = (cat.iconSlug.isNotEmpty ? cat.iconSlug : cat.nameEn).toLowerCase().trim();
    final name = cat.nameEn.toLowerCase().trim();

    if (slug.contains('supermarket') || slug.contains('grocer') || name.contains('supermarket') || name.contains('grocer')) {
      return Icons.shopping_cart;
    }
    if (slug.contains('device') || slug.contains('electron') || name.contains('electron') || slug.contains('smart tv') || name.contains('tv')) {
      return Icons.devices;
    }
    if (slug.contains('smart phone') || slug.contains('smartphone') || slug.contains('phone') || name.contains('phone')) {
      return Icons.smartphone;
    }
    if (slug.contains('restaurant') || slug.contains('food') || slug.contains('dining') || name.contains('restaurant') || name.contains('food')) {
      return Icons.restaurant;
    }
    if (slug.contains('checkroom') || slug.contains('fashion') || slug.contains('cloth') || slug.contains('apparel') || name.contains('fashion') || name.contains('apparel') || name.contains('cloth')) {
      return Icons.checkroom;
    }
    if (slug.contains('chair') || slug.contains('furnit') || slug.contains('home') || name.contains('home') || name.contains('furnit')) {
      return Icons.chair;
    }
    if (slug.contains('health') || slug.contains('beauty') || name.contains('health') || name.contains('beauty') || name.contains('care')) {
      return Icons.health_and_safety;
    }
    if (slug.contains('book') || slug.contains('station') || name.contains('book') || name.contains('station')) {
      return Icons.menu_book;
    }
    if (slug.contains('sport') || slug.contains('fit') || name.contains('sport') || name.contains('fit')) {
      return Icons.fitness_center;
    }
    if (slug.contains('auto') || slug.contains('car') || name.contains('auto') || name.contains('car')) {
      return Icons.directions_car;
    }
    if (slug.contains('pharmacy') || name.contains('pharmacy') || name.contains('medicine')) {
      return Icons.local_pharmacy;
    }
    if (slug.contains('baby') || slug.contains('toy') || slug.contains('kid') || name.contains('baby') || name.contains('toy') || name.contains('kid')) {
      return Icons.child_care;
    }
    if (slug.contains('bakery') || name.contains('bakery')) {
      return Icons.bakery_dining;
    }
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Reactively watch selected city
    final cityState = ref.watch(cityRepositoryProvider);
    final selectedCity = cityState.selectedCity;
    final cityId = selectedCity?.id;
    final cityName = selectedCity != null ? (isRtl ? selectedCity.nameAr : selectedCity.nameEn) : '';

    // Load data filtered by selected city
    final allCategories = ref.watch(categoryRepositoryProvider).where((c) => c.isActive == 1).toList();
    final mainCategories = allCategories.where((c) => c.parentId == null).toList();
    
    final featuredOffers = ref.watch(offerRepositoryProvider.notifier).getOffers(OfferFilters(cityId: cityId, isFeatured: true));
    final flashDeals = ref.watch(offerRepositoryProvider.notifier).getOffers(OfferFilters(cityId: cityId, isFlash: true));
    final latestOffers = ref.watch(offerRepositoryProvider.notifier).getOffers(OfferFilters(cityId: cityId));
    final activeFlyers = ref.watch(flyerRepositoryProvider.notifier).getFlyers(cityId);
    final featuredBrands = _featuredBrands.isNotEmpty
        ? _featuredBrands
        : ref.watch(brandRepositoryProvider.notifier).getFeaturedBrands();
    final stores = ref.watch(storeRepositoryProvider.notifier).getStores(cityId: cityId);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadInitialData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Section
              _buildHeroSection(context, isDark, isRtl, cityName, tr),

              const SizedBox(height: 20),

              // 2. Browse by Category Horizontal Scroll
              if (mainCategories.isNotEmpty) ...[
                _buildSectionHeader(
                  title: tr.get('browse_by_category'),
                  onSeeAll: () => context.go('/offers'),
                  seeAllLabel: tr.get('see_all'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 96,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: mainCategories.length,
                    itemBuilder: (context, index) {
                      final cat = mainCategories[index];
                      final catName = isRtl ? cat.nameAr : cat.nameEn;
                      final hasImg = cat.imageUrl != null && cat.imageUrl!.trim().isNotEmpty;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: InkWell(
                          onTap: () => context.go('/offers?categoryId=${cat.id}'),
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF16A34A).withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: hasImg
                                    ? CachedNetworkImage(
                                        imageUrl: AppConfig.normalizeImageUrl(cat.imageUrl!),
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Icon(
                                          _getIconForCategory(cat),
                                          color: const Color(0xFF15803D),
                                          size: 26,
                                        ),
                                      )
                                    : Icon(
                                        _getIconForCategory(cat),
                                        color: const Color(0xFF15803D),
                                        size: 26,
                                      ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  catName,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Flash Deals (Horizontal Slider)
              if (flashDeals.isNotEmpty) ...[
                _buildSectionHeader(
                  title: tr.get('flash_deals'),
                  badgeText: tr.get('limited_time'),
                  badgeColor: const Color(0xFFF59E0B),
                  onSeeAll: () => context.go('/offers?flash=true'),
                  seeAllLabel: tr.get('see_all'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 310,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: flashDeals.length,
                    itemBuilder: (context, index) {
                      final deal = flashDeals[index];
                      return Container(
                        width: 210,
                        margin: const EdgeInsets.only(right: 14, bottom: 6),
                        child: _buildOfferCard(context, ref, deal, isRtl, isDark, tr),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 4. Featured Stores & Brands (Horizontal Scroll)
              if (featuredBrands.isNotEmpty || stores.isNotEmpty) ...[
                _buildSectionHeader(
                  title: tr.get('featured_stores_brands'),
                  badgeText: tr.get('top_picks'),
                  badgeColor: const Color(0xFF16A34A),
                  onSeeAll: () => context.go('/stores'),
                  seeAllLabel: tr.get('see_all'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 96,
                  child: ListView.builder(
                    controller: _brandScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: featuredBrands.length + stores.length,
                    itemBuilder: (context, index) {
                      if (index < featuredBrands.length) {
                        final b = featuredBrands[index];
                        final bName = isRtl ? b.nameAr : b.nameEn;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: InkWell(
                            onTap: () => context.go('/offers?brandId=${b.id}'),
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: (b.logoUrl != null && b.logoUrl!.isNotEmpty)
                                        ? CachedNetworkImage(
                                            imageUrl: AppConfig.normalizeImageUrl(b.logoUrl),
                                            fit: BoxFit.contain,
                                            errorWidget: (_, __, ___) => const Icon(Icons.loyalty, color: Color(0xFF16A34A)),
                                          )
                                        : const Icon(Icons.loyalty, color: Color(0xFF16A34A)),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: 65,
                                  child: Text(
                                    bName,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        final s = stores[index - featuredBrands.length];
                        final sName = isRtl ? s.nameAr : s.nameEn;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: InkWell(
                            onTap: () => context.go('/stores/${s.id}'),
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: s.logoUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: AppConfig.normalizeImageUrl(s.logoUrl),
                                            fit: BoxFit.contain,
                                            errorWidget: (_, __, ___) => const Icon(Icons.storefront, color: Color(0xFF16A34A)),
                                          )
                                        : const Icon(Icons.storefront, color: Color(0xFF16A34A)),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: 65,
                                  child: Text(
                                    sName,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 5. Weekly Flyers & Brochures Grid
              if (activeFlyers.isNotEmpty) ...[
                _buildSectionHeader(
                  title: tr.get('weekly_flyers'),
                  onSeeAll: () => context.go('/flyers'),
                  seeAllLabel: tr.get('see_all'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: activeFlyers.length,
                    itemBuilder: (context, index) {
                      final flyer = activeFlyers[index];
                      return Container(
                        width: 170,
                        margin: const EdgeInsets.only(right: 14, bottom: 6),
                        child: _buildFlyerCard(context, flyer, isRtl, isDark, tr),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 6. Featured Offers Grid
              if (featuredOffers.isNotEmpty) ...[
                _buildSectionHeader(
                  title: tr.get('featured_offers'),
                  badgeText: tr.get('best_savings'),
                  badgeColor: const Color(0xFF16A34A),
                  onSeeAll: () => context.go('/offers?featured=true'),
                  seeAllLabel: tr.get('see_all'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: featuredOffers.take(4).length,
                    itemBuilder: (context, index) {
                      final offer = featuredOffers[index];
                      return _buildOfferCard(context, ref, offer, isRtl, isDark, tr);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 7. Latest Discounts Grid
              _buildSectionHeader(
                title: tr.get('latest_offers'),
                onSeeAll: () => context.go('/offers'),
                seeAllLabel: tr.get('view_all'),
              ),
              const SizedBox(height: 12),
              if (latestOffers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: latestOffers.length,
                    itemBuilder: (context, index) {
                      final offer = latestOffers[index];
                      return _buildOfferCard(context, ref, offer, isRtl, isDark, tr);
                    },
                  ),
                )
              else
                _buildEmptyState(isDark, tr),
            ],
          ),
        ),
      ),
    );
  }

  // Hero Section
  Widget _buildHeroSection(BuildContext context, bool isDark, bool isRtl, String cityName, AppLocalizations tr) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F2E1E), const Color(0xFF131C2E)]
              : [const Color(0xFF065F46), const Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City badge
          if (cityName.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${tr.get('deals_in')} $cityName',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // Title
          Text(
            '${tr.get('hero_title')} $cityName',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            tr.get('hero_desc'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // CTA Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/offers'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF065F46),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.explore, size: 16),
                  label: Text(
                    tr.get('explore_offers'),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/flyers'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.menu_book, size: 16),
                  label: Text(
                    tr.get('view_flyers'),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader({
    required String title,
    String? badgeText,
    Color? badgeColor,
    VoidCallback? onSeeAll,
    String? seeAllLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? const Color(0xFF16A34A)).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (badgeColor ?? const Color(0xFF16A34A)).withOpacity(0.3)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor ?? const Color(0xFF16A34A),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: const Color(0xFF16A34A),
              ),
              child: Text(
                seeAllLabel ?? 'See All',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // Offer Card matching Angular
  Widget _buildOfferCard(
    BuildContext context,
    WidgetRef ref,
    Offer offer,
    bool isRtl,
    bool isDark,
    AppLocalizations tr,
  ) {
    final isSaved = offer.isSaved == true;
    final storeName = isRtl ? (offer.store?.nameAr ?? '') : (offer.store?.nameEn ?? '');
    final offerTitle = isRtl ? offer.titleAr : offer.titleEn;
    final productName = offer.product != null ? (isRtl ? offer.product!.nameAr : offer.product!.nameEn) : null;
    final primaryImg = (offer.images != null && offer.images!.isNotEmpty)
        ? offer.images!.first.imageUrl
        : offer.product?.primaryImageUrl;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go('/offers/${offer.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with discount badge & save button
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.35,
                    child: Container(
                      color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                      child: primaryImg != null
                          ? CachedNetworkImage(
                              imageUrl: AppConfig.normalizeImageUrl(primaryImg),
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                            )
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),

                  // Discount badge
                  if (offer.discountPct > 0)
                    Positioned(
                      top: 8,
                      left: isRtl ? null : 8,
                      right: isRtl ? 8 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '-${offer.discountPct.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Save Bookmark button
                  Positioned(
                    top: 8,
                    right: isRtl ? null : 8,
                    left: isRtl ? 8 : null,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          ref.read(offerRepositoryProvider.notifier).toggleSaveOffer(offer.id);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black54 : Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            size: 16,
                            color: isSaved ? const Color(0xFF16A34A) : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Info Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store badge row
                      if (storeName.isNotEmpty)
                        Row(
                          children: [
                            if (offer.store?.logoUrl != null && offer.store!.logoUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: AppConfig.normalizeImageUrl(offer.store!.logoUrl!),
                                  width: 14,
                                  height: 14,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                storeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ),
                            if (offer.store?.isVerified == 1)
                              const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 13),
                          ],
                        ),
                    const SizedBox(height: 4),

                    // Offer Title
                    Text(
                      offerTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Product Name Box (Prominent)
                    if (productName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2, size: 11, color: Color(0xFF16A34A)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),

                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${offer.offerPrice.toStringAsFixed(0)} ${tr.get('sar')}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        if (offer.originalPrice > offer.offerPrice) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${offer.originalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Valid until
                    if (offer.validUntil.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 11, color: isDark ? Colors.white38 : Colors.black38),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '${tr.get('until')} ${offer.validUntil}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  // Flyer Card matching Angular
  Widget _buildFlyerCard(
    BuildContext context,
    Flyer flyer,
    bool isRtl,
    bool isDark,
    AppLocalizations tr,
  ) {
    final storeName = isRtl ? (flyer.store?.nameAr ?? '') : (flyer.store?.nameEn ?? '');
    final flyerTitle = isRtl ? flyer.titleAr : flyer.titleEn;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go('/flyers/${flyer.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: AppConfig.normalizeImageUrl(flyer.coverImageUrl),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.picture_as_pdf, color: Colors.grey),
                    ),
                    Positioned(
                      bottom: 6,
                      right: isRtl ? null : 6,
                      left: isRtl ? 6 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${flyer.totalPages} ${tr.get('pages')}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (storeName.isNotEmpty)
                      Text(
                        storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      flyerTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState(bool isDark, AppLocalizations tr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.local_offer_outlined, size: 48, color: Colors.grey.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text(
            tr.get('no_offers_found'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            tr.get('no_offers_city'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
