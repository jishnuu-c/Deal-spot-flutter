import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/store_repository.dart';
import '../../../core/services/offer_repository.dart';
import '../../../core/services/flyer_repository.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

class StoreDetailScreen extends ConsumerStatefulWidget {
  final int storeId;

  const StoreDetailScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends ConsumerState<StoreDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final store = ref.watch(storeRepositoryProvider.notifier).getStoreById(widget.storeId);

    if (store == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Store not found')),
      );
    }

    final storeName = isRtl ? store.nameAr : store.nameEn;
    final categoryName = isRtl ? (store.category?.nameAr ?? '') : (store.category?.nameEn ?? '');
    final cityName = isRtl ? (store.city?.nameAr ?? '') : (store.city?.nameEn ?? '');
    final isFollowed = ref.watch(storeRepositoryProvider).followedStoreIds.contains(store.id);

    // Offers, Flyers, Branches
    final offers = ref.watch(offerRepositoryProvider.notifier).getOffers(OfferFilters(storeId: store.id));
    final flyers = ref.watch(flyerRepositoryProvider.notifier).getFlyers().where((f) => f.storeId == store.id).toList();
    final branches = ref.watch(storeRepositoryProvider.notifier).getBranchesForStore(store.id);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store Logo Frame
                          Container(
                            width: 72,
                            height: 72,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: store.logoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: AppConfig.normalizeImageUrl(store.logoUrl),
                                      fit: BoxFit.contain,
                                      errorWidget: (_, __, ___) => const Icon(Icons.storefront, color: Color(0xFF16A34A), size: 36),
                                    )
                                  : const Icon(Icons.storefront, color: Color(0xFF16A34A), size: 36),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Store Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        storeName,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                    if (store.isVerified == 1) ...[
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 18),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (categoryName.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16A34A).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          categoryName,
                                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    if (cityName.isNotEmpty) ...[
                                      Icon(Icons.place, size: 13, color: isDark ? Colors.white60 : Colors.black54),
                                      const SizedBox(width: 2),
                                      Text(
                                        cityName,
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                      ),
                                    ],
                                  ],
                                ),
                                if (store.crNumber != null || store.vatNumber != null) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      if (store.crNumber != null)
                                        Text('CR: ${store.crNumber}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      if (store.vatNumber != null)
                                        Text('VAT: ${store.vatNumber}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Follow Action Row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowed ? Colors.redAccent.withOpacity(0.15) : const Color(0xFF16A34A),
                                foregroundColor: isFollowed ? Colors.redAccent : Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: Icon(isFollowed ? Icons.favorite : Icons.favorite_border, size: 16),
                              label: Text(
                                isFollowed ? tr.get('following') : tr.get('follow'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                final isLoggedIn = ref.read(authProvider).isLoggedIn;
                                if (!isLoggedIn) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(tr.get('save_offer_login'))),
                                  );
                                  return;
                                }
                                ref.read(storeRepositoryProvider.notifier).toggleFollowStore(store.id);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people, size: 16, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(
                                  '${store.followersCount ?? (isFollowed ? 451 : 450)}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF16A34A),
                    labelColor: const Color(0xFF16A34A),
                    unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: [
                      Tab(text: '${tr.get('offers')} (${offers.length})'),
                      Tab(text: '${tr.get('flyers')} (${flyers.length})'),
                      Tab(text: '${tr.get('branches')} (${branches.length})'),
                    ],
                  ),
                  isDark: isDark,
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // 1. Offers Tab
              offers.isNotEmpty
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: offers.length,
                      itemBuilder: (context, index) {
                        final offer = offers[index];
                        return _buildOfferGridItem(context, offer, isRtl, isDark, tr);
                      },
                    )
                  : _buildEmptyTab(Icons.local_offer_outlined, isRtl ? 'لا توجد عروض حالياً لهذا المتجر' : 'No active offers for this store'),

              // 2. Flyers Tab
              flyers.isNotEmpty
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: flyers.length,
                      itemBuilder: (context, index) {
                        final flyer = flyers[index];
                        return _buildFlyerGridItem(context, flyer, isRtl, isDark, tr);
                      },
                    )
                  : _buildEmptyTab(Icons.menu_book_outlined, isRtl ? 'لا توجد منشورات لهذا المتجر' : 'No flyers for this store'),

              // 3. Branches Tab
              branches.isNotEmpty
                  ? ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: branches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final branch = branches[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.location_on, color: Color(0xFF16A34A), size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      branch.branchName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (branch.openTime.isNotEmpty && branch.closeTime.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${branch.openTime} - ${branch.closeTime}',
                                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    )
                  : _buildEmptyTab(Icons.store_outlined, isRtl ? 'لا توجد فروع مسجلة' : 'No branches listed'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTab(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildOfferGridItem(BuildContext context, Offer offer, bool isRtl, bool isDark, AppLocalizations tr) {
    final title = isRtl ? offer.titleAr : offer.titleEn;
    final primaryImg = (offer.images != null && offer.images!.isNotEmpty)
        ? offer.images!.first.imageUrl
        : offer.product?.primaryImageUrl;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go('/offers/${offer.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.35,
                child: primaryImg != null
                    ? CachedNetworkImage(imageUrl: AppConfig.normalizeImageUrl(primaryImg), fit: BoxFit.cover)
                    : const Icon(Icons.image),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${offer.offerPrice.toStringAsFixed(0)} ${tr.get('sar')}',
                      style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w900, fontSize: 13),
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

  Widget _buildFlyerGridItem(BuildContext context, Flyer flyer, bool isRtl, bool isDark, AppLocalizations tr) {
    final title = isRtl ? flyer.titleAr : flyer.titleEn;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
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
                child: CachedNetworkImage(imageUrl: AppConfig.normalizeImageUrl(flyer.coverImageUrl), fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${flyer.totalPages} ${tr.get('pages')}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
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
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final bool isDark;

  _SliverTabBarDelegate(this._tabBar, {required this.isDark});

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? const Color(0xFF131C2E) : Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
