import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/services/category_repository.dart';
import '../../../core/services/offer_repository.dart';
import '../../../core/services/flyer_repository.dart';
import '../../../core/services/brand_repository.dart';
import '../../../core/services/store_repository.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../models/models.dart';

/// Representation of an item in the Featured Stores & Brands carousel
class FeaturedItem {
  final int id;
  final String nameEn;
  final String nameAr;
  final String? logoUrl;
  final bool isStore;

  const FeaturedItem({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.logoUrl,
    required this.isStore,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _brandScrollController = ScrollController();
  List<Brand> _pagedBrands = [];
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
    // Dispatch network fetchers
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
          _pagedBrands = res.content;
        } else {
          final existingIds = _pagedBrands.map((b) => b.id).toSet();
          final newItems = res.content.where((b) => !existingIds.contains(b.id)).toList();
          _pagedBrands.addAll(newItems);
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

  void _handleToggleSaveOffer(BuildContext context, Offer offer) {
    final authState = ref.read(authProvider);
    final tr = ref.read(localizationsProvider);

    if (!authState.isLoggedIn) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.bookmark_border, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  tr.get('login'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            tr.language == AppLanguage.en
                ? 'Please sign in to save offers to your favorites.'
                : 'يرجى تسجيل الدخول لحفظ العروض في المفضلة.',
            style: const TextStyle(fontSize: 14),
          ),
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
                context.go('/login');
              },
              child: Text(tr.get('login')),
            ),
          ],
        ),
      );
      return;
    }

    ref.read(offerRepositoryProvider.notifier).toggleSaveOffer(offer.id);
  }

  IconData _getIconForCategory(Category cat) {
    final slug = (cat.iconSlug.isNotEmpty ? cat.iconSlug : cat.nameEn).toLowerCase().trim();
    final name = cat.nameEn.toLowerCase().trim();

    if (slug.contains('supermarket') || slug.contains('grocer') || name.contains('supermarket') || name.contains('grocer')) {
      return Icons.shopping_cart;
    }
    if (slug.contains('device') || slug.contains('electron') || name.contains('electron') || slug.contains('tv') || name.contains('tv')) {
      return Icons.devices;
    }
    if (slug.contains('smart phone') || slug.contains('smartphone') || slug.contains('phone') || name.contains('phone')) {
      return Icons.smartphone;
    }
    if (slug.contains('restaurant') || slug.contains('food') || slug.contains('dining') || name.contains('restaurant') || name.contains('food')) {
      return Icons.restaurant;
    }
    if (slug.contains('checkroom') || slug.contains('fashion') || slug.contains('cloth') || slug.contains('apparel') || name.contains('fashion') || name.contains('cloth')) {
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

    // Reactively watch Riverpod states
    final cityState = ref.watch(cityRepositoryProvider);
    final selectedCity = cityState.selectedCity;
    final cityId = selectedCity?.id;
    final cityName = selectedCity != null ? (isRtl ? selectedCity.nameAr : selectedCity.nameEn) : '';

    final categories = ref.watch(categoryRepositoryProvider);
    final mainCategories = categories.where((c) => c.isActive == 1 && c.parentId == null).toList();

    // Watching repositories ensures automatic rebuild on state change
    ref.watch(offerRepositoryProvider);
    ref.watch(flyerRepositoryProvider);
    ref.watch(storeRepositoryProvider);
    ref.watch(brandRepositoryProvider);

    final flashDeals = ref.read(offerRepositoryProvider.notifier).getFlashDeals(cityId: cityId);
    final featuredOffers = ref.read(offerRepositoryProvider.notifier).getFeaturedOffers(cityId: cityId);
    final latestOffers = ref.read(offerRepositoryProvider.notifier).getLatestOffers(cityId: cityId, limit: 12);
    final activeFlyers = ref.read(flyerRepositoryProvider.notifier).getFlyers(cityId);

    // Combine featured brands and featured stores (matching Angular)
    final storeState = ref.watch(storeRepositoryProvider);
    final featStores = storeState.stores
        .where((s) => s.featured && s.isActive == 1 && (cityId == null || cityId == 0 || s.cityId == 0 || s.cityId == cityId))
        .map((s) => FeaturedItem(
              id: s.id,
              nameEn: s.nameEn,
              nameAr: s.nameAr,
              logoUrl: s.logoUrl,
              isStore: true,
            ))
        .toList();

    final featBrands = (_pagedBrands.isNotEmpty
            ? _pagedBrands
            : ref.read(brandRepositoryProvider.notifier).getFeaturedBrands())
        .map((b) => FeaturedItem(
              id: b.id,
              nameEn: b.nameEn,
              nameAr: b.nameAr,
              logoUrl: b.logoUrl,
              isStore: false,
            ))
        .toList();

    final combinedFeatured = [...featBrands, ...featStores];

    return Scaffold(
      body: RefreshIndicator(
        color: const Color(0xFF16A34A),
        onRefresh: () async {
          await _loadInitialData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Section Banner
              _buildHeroSection(context, isDark, isRtl, cityName, tr),

              const SizedBox(height: 16),

              // 2. Categories Horizontal Scroll
              if (mainCategories.isNotEmpty) ...[
                _buildSectionHeader(
                  title: tr.get('browse_by_category'),
                  onSeeAll: () => context.go('/offers'),
                  seeAllLabel: tr.get('see_all'),
                ),
                const SizedBox(height: 12),
                _buildCategoriesScroll(mainCategories, isRtl, isDark),
                const SizedBox(height: 20),
              ],

              // 3. Flash Deals (Horizontal Slider)
              if (flashDeals.isNotEmpty) ...[
                _buildSectionHeader(
                  title: tr.get('flash_deals'),
                  badgeText: tr.get('limited_time'),
                  badgeColor: const Color(0xFFEA580C),
                  onSeeAll: () => context.go('/offers?flash=true'),
                  seeAllLabel: tr.get('see_all'),
                ),
                const SizedBox(height: 12),
                _buildFlashDealsSlider(flashDeals, isRtl, isDark, tr),
                const SizedBox(height: 24),
              ],

              // 4. Featured Stores & Brands (Horizontal Scroll with infinite pagination)
              if (combinedFeatured.isNotEmpty) ...[
                _buildSectionHeader(
                  title: tr.get('featured_stores_brands'),
                  badgeText: tr.get('top_picks'),
                  badgeColor: const Color(0xFF16A34A),
                  onSeeAll: () => context.go('/stores'),
                  seeAllLabel: tr.get('see_all'),
                ),
                const SizedBox(height: 12),
                _buildFeaturedBrandsScroll(combinedFeatured, isRtl, isDark),
                const SizedBox(height: 24),
              ],

              // 5. Weekly Flyers & Brochures Horizontal Carousel
              if (activeFlyers.isNotEmpty) ...[
                _buildSectionHeader(
                  title: tr.get('weekly_flyers'),
                  onSeeAll: () => context.go('/flyers'),
                  seeAllLabel: tr.get('see_all'),
                ),
                const SizedBox(height: 12),
                _buildFlyersSlider(activeFlyers, isRtl, isDark, tr),
                const SizedBox(height: 24),
              ],

              // 6. Featured Offers Grid (2-columns)
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
                      childAspectRatio: 0.56,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: featuredOffers.take(6).length,
                    itemBuilder: (context, index) {
                      final offer = featuredOffers[index];
                      return _buildOfferCard(context, offer, isRtl, isDark, tr, isFeaturedBadge: true);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 7. Latest Discounts Grid (2-columns)
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
                      childAspectRatio: 0.56,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: latestOffers.length,
                    itemBuilder: (context, index) {
                      final offer = latestOffers[index];
                      return _buildOfferCard(context, offer, isRtl, isDark, tr);
                    },
                  ),
                )
              else
                _buildEmptyState(isDark, tr, cityName),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Hero Section
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
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF047857).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City pill badge
          if (cityName.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
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

          // Hero Title with city name
          Text(
            isRtl
                ? '${AppConfig.heroTitleAr} $cityName'
                : '${AppConfig.heroTitleEn} $cityName',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),

          // Hero Description
          Text(
            isRtl ? AppConfig.heroDescriptionAr : AppConfig.heroDescriptionEn,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/offers'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF065F46),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
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
                    padding: const EdgeInsets.symmetric(vertical: 11),
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

  // 2. Categories Scroll
  Widget _buildCategoriesScroll(List<Category> categories, bool isRtl, bool isDark) {
    return SizedBox(
      height: 98,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
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
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E3A2F), const Color(0xFF142D23)]
                            : [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImg
                        ? AppNetworkImage(
                            imageUrl: cat.imageUrl,
                            fit: BoxFit.cover,
                            defaultFallbackIcon: _getIconForCategory(cat),
                          )
                        : Icon(
                            _getIconForCategory(cat),
                            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
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
    );
  }

  // 3. Flash Deals Horizontal Slider
  Widget _buildFlashDealsSlider(List<Offer> flashDeals, bool isRtl, bool isDark, AppLocalizations tr) {
    return SizedBox(
      height: 315,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: flashDeals.length,
        itemBuilder: (context, index) {
          final deal = flashDeals[index];
          return Container(
            width: 215,
            margin: const EdgeInsets.only(right: 14, bottom: 6),
            child: _buildOfferCard(context, deal, isRtl, isDark, tr, isFlashCard: true),
          );
        },
      ),
    );
  }

  // 4. Featured Stores & Brands Scroll
  Widget _buildFeaturedBrandsScroll(List<FeaturedItem> items, bool isRtl, bool isDark) {
    return SizedBox(
      height: 98,
      child: ListView.builder(
        controller: _brandScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length + (_brandLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF16A34A)),
                ),
              ),
            );
          }

          final item = items[index];
          final itemName = isRtl ? item.nameAr : item.nameEn;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () {
                if (item.isStore) {
                  context.go('/stores/${item.id}');
                } else {
                  context.go('/offers?brandId=${item.id}');
                }
              },
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
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (item.logoUrl != null && item.logoUrl!.trim().isNotEmpty)
                          ? AppNetworkImage(
                              imageUrl: item.logoUrl,
                              fit: BoxFit.contain,
                              defaultFallbackIcon: item.isStore ? Icons.storefront : Icons.loyalty,
                            )
                          : Icon(
                              item.isStore ? Icons.storefront : Icons.loyalty,
                              color: const Color(0xFF16A34A),
                              size: 26,
                            ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: 65,
                    child: Text(
                      itemName,
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
        },
      ),
    );
  }

  // 5. Flyers Slider
  Widget _buildFlyersSlider(List<Flyer> flyers, bool isRtl, bool isDark, AppLocalizations tr) {
    return SizedBox(
      height: 275,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: flyers.length,
        itemBuilder: (context, index) {
          final flyer = flyers[index];
          return Container(
            width: 185,
            margin: const EdgeInsets.only(right: 14, bottom: 6),
            child: _buildFlyerCard(context, flyer, isRtl, isDark, tr),
          );
        },
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
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                  ),
                ),
                if (badgeText != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? const Color(0xFF16A34A)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (badgeColor ?? const Color(0xFF16A34A)).withValues(alpha: 0.3)),
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

  // Offer Card (Mobile Optimized matching Angular)
  Widget _buildOfferCard(
    BuildContext context,
    Offer offer,
    bool isRtl,
    bool isDark,
    AppLocalizations tr, {
    bool isFlashCard = false,
    bool isFeaturedBadge = false,
  }) {
    final isSaved = offer.isSaved == true;
    final storeName = isRtl ? (offer.store?.nameAr ?? '') : (offer.store?.nameEn ?? '');
    final offerTitle = isRtl ? offer.titleAr : offer.titleEn;
    final productName = offer.product != null ? (isRtl ? offer.product!.nameAr : offer.product!.nameEn) : null;
    final primaryImg = offer.primaryImageUrl;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFlashCard
              ? const Color(0xFFEA580C).withValues(alpha: 0.35)
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                      child: AppNetworkImage(
                        imageUrl: primaryImg,
                        fit: BoxFit.cover,
                        defaultFallbackIcon: Icons.local_offer_outlined,
                      ),
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
                              color: const Color(0xFFDC2626).withValues(alpha: 0.3),
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
                        onTap: () => _handleToggleSaveOffer(context, offer),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black54 : Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
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
              Padding(
                padding: const EdgeInsets.all(9.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Store badge row
                      if (storeName.isNotEmpty)
                        InkWell(
                          onTap: () {
                            if (offer.storeId > 0) {
                              context.go('/stores/${offer.storeId}');
                            }
                          },
                          child: Row(
                            children: [
                              if (offer.store != null && offer.store!.logoUrl.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: AppNetworkImage(
                                    imageUrl: offer.store!.logoUrl,
                                    width: 14,
                                    height: 14,
                                    fit: BoxFit.cover,
                                    defaultFallbackIcon: Icons.storefront,
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
                      if (productName != null && productName.isNotEmpty)
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
                              offer.originalPrice.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Valid date / footer
                      if (offer.validUntil.isNotEmpty) ...[
                        const SizedBox(height: 3),
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

                      if (isFeaturedBadge) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tr.get('featured_offers'),
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Flyer Card (Matching Angular .flyer-card)
  Widget _buildFlyerCard(
    BuildContext context,
    Flyer flyer,
    bool isRtl,
    bool isDark,
    AppLocalizations tr,
  ) {
    final storeName = isRtl ? (flyer.store?.nameAr ?? '') : (flyer.store?.nameEn ?? '');
    final flyerTitle = isRtl ? flyer.titleAr : flyer.titleEn;
    final storeLogo = flyer.store?.logoUrl;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.go('/flyers/${flyer.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cover Image Area with clean container and Pages badge
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      child: AppNetworkImage(
                        imageUrl: flyer.coverImageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        defaultFallbackIcon: Icons.auto_stories,
                      ),
                    ),

                    // Pages Count Badge
                    Positioned(
                      bottom: 8,
                      right: isRtl ? null : 8,
                      left: isRtl ? 8 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_stories, color: Colors.white, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              '${flyer.totalPages} ${isRtl ? "صفحات" : "Pages"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Divider
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),

              // 3. Info Body (Matching Angular .flyer-card-body)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Store badge row
                    if (storeName.isNotEmpty)
                      Row(
                        children: [
                          if (storeLogo != null && storeLogo.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: AppNetworkImage(
                                imageUrl: storeLogo,
                                width: 14,
                                height: 14,
                                fit: BoxFit.cover,
                                defaultFallbackIcon: Icons.storefront,
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
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          if (flyer.store?.isVerified == 1)
                            const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 12),
                        ],
                      ),
                    const SizedBox(height: 3),

                    // Flyer Title
                    Text(
                      flyerTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // View Flyer Button (Matching Angular .btn-view-flyer)
                    Container(
                      width: double.infinity,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          isRtl ? 'عرض البروشور' : 'View Flyer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
  Widget _buildEmptyState(bool isDark, AppLocalizations tr, String cityName) {
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
          Icon(Icons.local_offer_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text(
            tr.get('no_offers_found'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            cityName.isNotEmpty
                ? '${tr.get('no_offers_city')} ($cityName)'
                : tr.get('no_offers_city'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
