import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/store_repository.dart';
import '../../../core/services/offer_repository.dart';
import '../../../core/services/flyer_repository.dart';
import '../../../core/services/city_repository.dart';
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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storeRepositoryProvider.notifier).fetchStoreById(widget.storeId);
      ref.read(storeRepositoryProvider.notifier).fetchBranchesForStore(widget.storeId);
      ref.read(offerRepositoryProvider.notifier).fetchOffers(storeId: widget.storeId);
      ref.read(flyerRepositoryProvider.notifier).fetchFlyers(storeId: widget.storeId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openGoogleMaps(StoreBranch branch, Store store) async {
    Uri uri;
    if (branch.latitude != 0 && branch.longitude != 0) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${branch.latitude},${branch.longitude}');
    } else {
      final query = Uri.encodeComponent('${store.nameEn} ${branch.branchName}');
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        debugPrint('Could not launch maps: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final store = ref.watch(storeRepositoryProvider.notifier).getStoreById(widget.storeId);

    if (store == null) {
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF10B981)),
                ),
                const SizedBox(height: 16),
                Text(
                  isRtl ? 'جاري تحميل بيانات المتجر...' : 'Loading store details...',
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final storeName = isRtl ? (store.nameAr.isNotEmpty ? store.nameAr : store.nameEn) : (store.nameEn.isNotEmpty ? store.nameEn : store.nameAr);
    final categoryName = isRtl ? (store.category?.nameAr ?? '') : (store.category?.nameEn ?? '');
    final cityName = isRtl ? (store.city?.nameAr ?? '') : (store.city?.nameEn ?? '');
    final storeDesc = isRtl ? (store.descriptionAr ?? store.descriptionEn ?? '') : (store.descriptionEn ?? store.descriptionAr ?? '');
    final isFollowed = ref.watch(storeRepositoryProvider).followedStoreIds.contains(store.id);

    // Offers, Flyers, Branches (watching state reactively)
    ref.watch(offerRepositoryProvider);
    ref.watch(flyerRepositoryProvider);
    final offers = ref.read(offerRepositoryProvider.notifier).getOffers(OfferFilters(storeId: store.id));
    final flyers = ref.read(flyerRepositoryProvider.notifier).getFlyers().where((f) => f.storeId == store.id).toList();
    final branches = ref.read(storeRepositoryProvider.notifier).getBranchesForStore(store.id);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Top Back Button Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Align(
                    alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                    child: InkWell(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/stores');
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isRtl ? Icons.arrow_forward : Icons.arrow_back,
                              size: 16,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isRtl ? 'العودة للمتاجر' : 'Back to Stores',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Store Hero Banner Card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Logo & Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store Logo Frame
                          Container(
                            width: 76,
                            height: 76,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: store.logoUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: AppConfig.normalizeImageUrl(store.logoUrl),
                                      fit: BoxFit.contain,
                                      errorWidget: (_, __, ___) => const Icon(Icons.storefront, color: Color(0xFF10B981), size: 36),
                                    )
                                  : const Icon(Icons.storefront, color: Color(0xFF10B981), size: 36),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Store Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title & Verified Badge
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      storeName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (store.isVerified == 1)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.verified, size: 13, color: Color(0xFF10B981)),
                                            const SizedBox(width: 3),
                                            Text(
                                              isRtl ? 'موثق' : 'Verified',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Category & City
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (categoryName.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.category, size: 13, color: Color(0xFF10B981)),
                                            const SizedBox(width: 4),
                                            Text(
                                              categoryName,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: Color(0xFF10B981),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (cityName.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                          const SizedBox(width: 3),
                                          Text(
                                            cityName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),

                                // Description (if available)
                                if (storeDesc.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    storeDesc,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                  ),
                                ],

                                // Meta Specs (CR & VAT)
                                if (store.crNumber != null || store.vatNumber != null) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      if (store.crNumber != null && store.crNumber!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                          ),
                                          child: Text(
                                            'CR: ${store.crNumber}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      if (store.vatNumber != null && store.vatNumber!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                          ),
                                          child: Text(
                                            'VAT: ${store.vatNumber}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                            ),
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
                      const SizedBox(height: 16),

                      // Bottom Action Row: Followers Count (Left) & Follow Button (Right) matching Angular
                      Container(
                        padding: const EdgeInsets.only(top: 14),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Followers Count Badge (First / Left in LTR)
                            Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people, size: 18, color: Color(0xFF10B981)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${store.followersCount ?? (isFollowed ? 1 : 0)}',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isRtl ? 'متابع' : 'Followers',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Follow Button (Second / Right in LTR)
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: isFollowed
                                    ? OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF10B981),
                                          side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                        icon: const Icon(Icons.check_circle, size: 17),
                                        label: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            isRtl ? 'تتابعه' : 'Following',
                                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                                          ),
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
                                      )
                                    : ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                        icon: const Icon(Icons.favorite_border, size: 17),
                                        label: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            isRtl ? 'متابعة المتجر' : 'Follow Store',
                                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                                          ),
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Store Navigation Tabs Bar (Scrollable & Dynamic Active Colors)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    indicatorColor: const Color(0xFF10B981),
                    indicatorWeight: 3,
                    labelColor: const Color(0xFF10B981),
                    unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_offer,
                              size: 15,
                              color: _tabController.index == 0 ? const Color(0xFF10B981) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 6),
                            Text(isRtl ? 'العروض النشطة (${offers.length})' : 'Active Offers (${offers.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 15,
                              color: _tabController.index == 1 ? const Color(0xFF10B981) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 6),
                            Text(isRtl ? 'المنشورات الأسبوعية (${flyers.length})' : 'Weekly Flyers (${flyers.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.place,
                              size: 15,
                              color: _tabController.index == 2 ? const Color(0xFF10B981) : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 6),
                            Text(isRtl ? 'فروعنا (${branches.length})' : 'Branches (${branches.length})'),
                          ],
                        ),
                      ),
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
              // 1. Offers Tab Grid
              offers.isNotEmpty
                  ? GridView.builder(
                      padding: const EdgeInsets.all(14),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.50,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: offers.length,
                      itemBuilder: (context, index) {
                        final offer = offers[index];
                        return _buildOfferGridItem(context, offer, isRtl, isDark, tr);
                      },
                    )
                  : _buildEmptyTab(
                      Icons.local_offer,
                      isRtl ? 'لا توجد عروض نشطة حالياً' : 'No active offers',
                      isRtl ? 'لا توجد عروض تخفيض منشورة لهذا المتجر في الوقت الحالي.' : 'This store currently has no active discount offers published.',
                      isDark,
                    ),

              // 2. Flyers Tab Grid
              flyers.isNotEmpty
                  ? GridView.builder(
                      padding: const EdgeInsets.all(14),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.52,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: flyers.length,
                      itemBuilder: (context, index) {
                        final flyer = flyers[index];
                        return _buildFlyerGridItem(context, flyer, store, isRtl, isDark, tr);
                      },
                    )
                  : _buildEmptyTab(
                      Icons.menu_book,
                      isRtl ? 'لا توجد بروشورات متاحة' : 'No flyers available',
                      isRtl ? 'لا توجد مجلات أو نشرات عروض نشطة لهذا المتجر حالياً.' : 'This store currently has no brochures or pamphlets active.',
                      isDark,
                    ),

              // 3. Branches Tab List
              branches.isNotEmpty
                  ? ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: branches.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final branch = branches[index];
                        return _buildBranchCard(context, branch, store, isRtl, isDark);
                      },
                    )
                  : _buildEmptyTab(
                      Icons.place,
                      isRtl ? 'لا توجد فروع مسجلة' : 'No branches registered',
                      isRtl ? 'لم يتم تسجيل مواقع فروع فعلية لهذا المتجر بعد.' : 'This store has no physical locations saved in the directory.',
                      isDark,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTab(IconData icon, String title, String subtitle, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferGridItem(BuildContext context, Offer offer, bool isRtl, bool isDark, AppLocalizations tr) {
    final title = isRtl ? (offer.titleAr.isNotEmpty ? offer.titleAr : offer.titleEn) : (offer.titleEn.isNotEmpty ? offer.titleEn : offer.titleAr);
    final productName = offer.product != null
        ? (isRtl ? (offer.product!.nameAr.isNotEmpty ? offer.product!.nameAr : offer.product!.nameEn) : offer.product!.nameEn)
        : '';
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
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.push('/offers/${offer.id}'),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image container
                  Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: primaryImg != null && primaryImg.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: AppConfig.normalizeImageUrl(primaryImg),
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const Icon(Icons.image, color: Colors.grey, size: 36),
                          )
                        : const Icon(Icons.image, color: Colors.grey, size: 36),
                  ),
                  Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),

                  // Card Body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Offer Title
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Product Name Highlight Pill
                          if (productName.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [const Color(0x332563EB), const Color(0x4D1E3A8A)]
                                      : [const Color(0x142563EB), const Color(0x1F3B82F6)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark ? const Color(0x4D3B82F6) : const Color(0x262563EB),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.inventory_2, size: 10, color: Colors.white),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      productName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],

                          const Spacer(),

                          // Price Row
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                '${offer.offerPrice.toStringAsFixed(0)} ${tr.get('sar')}',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              if (offer.originalPrice > offer.offerPrice)
                                Text(
                                  '${offer.originalPrice.toStringAsFixed(0)} ${tr.get('sar')}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Card Footer: Ends Date & Flash Badge
                          Container(
                            padding: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (offer.validUntil.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      '${isRtl ? 'ينتهي:' : 'Ends:'} ${offer.validUntil.length > 10 ? offer.validUntil.substring(0, 10) : offer.validUntil}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                if (offer.isFlash == 1) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bolt, size: 10, color: Colors.white),
                                        Text(
                                          'Flash',
                                          style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ],
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
                ],
              ),

              // Floating Discount Badge
              if (offer.discountPct > 0)
                Positioned(
                  top: 8,
                  left: isRtl ? null : 8,
                  right: isRtl ? 8 : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '-${offer.discountPct.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlyerGridItem(
    BuildContext context,
    Flyer flyer,
    Store store,
    bool isRtl,
    bool isDark,
    AppLocalizations tr,
  ) {
    final title = isRtl ? (flyer.titleAr.isNotEmpty ? flyer.titleAr : flyer.titleEn) : (flyer.titleEn.isNotEmpty ? flyer.titleEn : flyer.titleAr);
    final flyerCity = isRtl
        ? (flyer.city?.nameAr ?? store.city?.nameAr ?? ref.watch(cityRepositoryProvider).selectedCity?.nameAr ?? 'دبي')
        : (flyer.city?.nameEn ?? store.city?.nameEn ?? ref.watch(cityRepositoryProvider).selectedCity?.nameEn ?? 'Dubai');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.push('/flyers/${flyer.id}'),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover Image Wrapper
                  Container(
                    height: 155,
                    width: double.infinity,
                    color: Colors.white,
                    child: flyer.coverImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: AppConfig.normalizeImageUrl(flyer.coverImageUrl),
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.menu_book, color: Colors.grey, size: 36),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.menu_book, color: Colors.grey, size: 36),
                          ),
                  ),
                  Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),

                  // Flyer Body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                          const Spacer(),

                          // Footer info (Pages count & Validity dates)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.auto_stories, size: 13, color: Color(0xFF10B981)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${flyer.totalPages} ${isRtl ? 'صفحات' : 'Pages'}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                                if (flyer.validUntil.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      '${isRtl ? 'حتى:' : 'Until:'} ${flyer.validUntil.length > 10 ? flyer.validUntil.substring(0, 10) : flyer.validUntil}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // View Flyer Button
                          SizedBox(
                            width: double.infinity,
                            height: 34,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF15803D),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => context.push('/flyers/${flyer.id}'),
                              child: Text(
                                isRtl ? 'عرض البروشور' : 'View Flyer',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Floating City Location Badge (Top-left / Top-right matching Angular)
              if (flyerCity.isNotEmpty)
                Positioned(
                  top: 8,
                  left: isRtl ? null : 8,
                  right: isRtl ? 8 : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.78),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place, color: Color(0xFF38BDF8), size: 11),
                        const SizedBox(width: 3),
                        Text(
                          flyerCity,
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
      ),
    );
  }

  Widget _buildBranchCard(BuildContext context, StoreBranch branch, Store store, bool isRtl, bool isDark) {
    final cityName = isRtl ? (branch.cityNameAr ?? '') : (branch.cityNameEn ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.place, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.branchName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    if (branch.latitude != 0 && branch.longitude != 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Lat: ${branch.latitude}, Long: ${branch.longitude}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Branch Body Info
          Column(
            children: [
              if (branch.openTime.isNotEmpty && branch.closeTime.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.schedule, size: 15, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(
                      '${isRtl ? 'أوقات العمل:' : 'Open:'} ${branch.openTime.length > 5 ? branch.openTime.substring(0, 5) : branch.openTime} - ${branch.closeTime.length > 5 ? branch.closeTime.substring(0, 5) : branch.closeTime}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (cityName.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.location_city, size: 15, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(
                      cityName,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 15, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  Text(
                    branch.active ? (isRtl ? 'فرع نشط' : 'Active Branch') : (isRtl ? 'مغلق مؤقتاً' : 'Temporarily Closed'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Branch Footer: Google Maps Button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(Icons.map, size: 17, color: isDark ? Colors.white70 : const Color(0xFF475569)),
              label: Text(
                isRtl ? 'فتح في خرائط جوجل' : 'Open in Google Maps',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              onPressed: () => _openGoogleMaps(branch, store),
            ),
          ),
        ],
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
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0), width: 1.5),
        ),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return true;
  }
}
