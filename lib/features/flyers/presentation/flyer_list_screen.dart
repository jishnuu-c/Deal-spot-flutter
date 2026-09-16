import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/services/flyer_repository.dart';
import '../../../core/services/store_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/custom_select_widget.dart';
import '../../../models/models.dart';

class FlyerListScreen extends ConsumerStatefulWidget {
  const FlyerListScreen({super.key});

  @override
  ConsumerState<FlyerListScreen> createState() => _FlyerListScreenState();
}

class _FlyerListScreenState extends ConsumerState<FlyerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _cityScrollController = ScrollController();

  String _searchQuery = '';
  int? _selectedStoreId;
  int? _selectedCityId;
  String _sortBy = 'newest';
  final Set<int> _bookmarkedFlyerIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cityRepositoryProvider.notifier).fetchCities();
      ref.read(flyerRepositoryProvider.notifier).fetchFlyers();
      ref.read(storeRepositoryProvider.notifier).fetchStores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityScrollController.dispose();
    super.dispose();
  }

  bool _isExpired(Flyer f) {
    if (f.validUntil.isEmpty) return false;
    final until = DateTime.tryParse(f.validUntil);
    if (until == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final untilDate = DateTime(until.year, until.month, until.day);
    return untilDate.isBefore(today);
  }

  bool _isNationwide(Flyer flyer) {
    return flyer.cityId == 0 || flyer.city == null;
  }

  String _getCityBadgeText(Flyer flyer, bool isRtl) {
    if (_isNationwide(flyer)) {
      return isRtl ? 'جميع المدن' : 'All Cities';
    }
    if (isRtl) {
      return flyer.city?.nameAr.isNotEmpty == true
          ? flyer.city!.nameAr
          : (flyer.city?.nameEn.isNotEmpty == true ? flyer.city!.nameEn : 'المدينة');
    }
    return flyer.city?.nameEn.isNotEmpty == true
        ? flyer.city!.nameEn
        : (flyer.city?.nameAr.isNotEmpty == true ? flyer.city!.nameAr : 'City');
  }

  String _getSelectedCityName(List<City> cities, bool isRtl) {
    if (_selectedCityId == null) {
      return isRtl ? 'جميع المدن' : 'All Cities';
    }
    final found = cities.where((c) => c.id == _selectedCityId).firstOrNull;
    if (found == null) {
      return isRtl ? 'المدينة المحددة' : 'Selected City';
    }
    return isRtl ? found.nameAr : found.nameEn;
  }

  List<Flyer> _getFilteredFlyers(List<Flyer> allFlyers) {
    // 1. Filter out inactive and expired
    var list = allFlyers.where((f) {
      final isActive = f.isActive == 1;
      final isNotExpired = !_isExpired(f);
      return isActive && isNotExpired;
    }).toList();

    // 2. City filter
    if (_selectedCityId != null) {
      final cId = _selectedCityId!;
      list = list.where((f) {
        if (_isNationwide(f)) return true;
        return f.cityId == cId || (f.store?.cityId == cId);
      }).toList();
    }

    // 3. Store filter
    if (_selectedStoreId != null) {
      list = list.where((f) => f.storeId == _selectedStoreId).toList();
    }

    // 4. Search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((f) {
        final titleEn = f.titleEn.toLowerCase();
        final titleAr = f.titleAr.toLowerCase();
        final storeEn = (f.store?.nameEn ?? '').toLowerCase();
        final storeAr = (f.store?.nameAr ?? '').toLowerCase();
        final cityEn = (f.city?.nameEn ?? '').toLowerCase();
        final cityAr = (f.city?.nameAr ?? '').toLowerCase();
        return titleEn.contains(q) ||
            titleAr.contains(q) ||
            storeEn.contains(q) ||
            storeAr.contains(q) ||
            cityEn.contains(q) ||
            cityAr.contains(q);
      }).toList();
    }

    // 5. Sorting
    list.sort((a, b) {
      if (_sortBy == 'expiring') {
        final dateA = a.validUntil.isNotEmpty ? a.validUntil : '9999-12-31';
        final dateB = b.validUntil.isNotEmpty ? b.validUntil : '9999-12-31';
        return dateA.compareTo(dateB);
      } else if (_sortBy == 'popular') {
        return b.viewCount.compareTo(a.viewCount);
      } else if (_sortBy == 'pages') {
        return b.totalPages.compareTo(a.totalPages);
      } else {
        // 'newest' (default)
        return b.id.compareTo(a.id);
      }
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isEn = !isRtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final flyerState = ref.watch(flyerRepositoryProvider);
    final cityState = ref.watch(cityRepositoryProvider);
    final storeState = ref.watch(storeRepositoryProvider);

    final allFlyers = flyerState.flyers;
    final cities = cityState.cities;
    final stores = storeState.stores;
    final isLoading = flyerState.isLoading;

    final filteredFlyers = _getFilteredFlyers(allFlyers);
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive column count
    final crossAxisCount = screenWidth >= 1200
        ? 4
        : (screenWidth >= 860 ? 3 : (screenWidth >= 480 ? 2 : 1));
    final childAspectRatio = screenWidth >= 860
        ? 0.58
        : (screenWidth >= 480 ? 0.54 : 0.68);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () async {
            await Future.wait([
              ref.read(flyerRepositoryProvider.notifier).fetchFlyers(),
              ref.read(cityRepositoryProvider.notifier).fetchCities(),
              ref.read(storeRepositoryProvider.notifier).fetchStores(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Filters, Quick City Switcher & Indicator Container
                _buildFiltersCard(
                  cities: cities,
                  stores: stores,
                  filteredCount: filteredFlyers.length,
                  isLoading: isLoading,
                  isEn: isEn,
                  isRtl: isRtl,
                  isDark: isDark,
                  screenWidth: screenWidth,
                ),
                const SizedBox(height: 16),

                // 2. Main Content Grid / Loading / Empty State
                if (isLoading && allFlyers.isEmpty)
                  _buildLoadingState(isEn, isDark)
                else if (filteredFlyers.isEmpty)
                  _buildEmptyState(cities, isEn, isRtl, isDark)
                else
                  _buildFlyersGrid(
                    flyers: filteredFlyers,
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    isEn: isEn,
                    isRtl: isRtl,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Filters Card (Matching Angular .flyer-filters.card)
  Widget _buildFiltersCard({
    required List<City> cities,
    required List<Store> stores,
    required int filteredCount,
    required bool isLoading,
    required bool isEn,
    required bool isRtl,
    required bool isDark,
    required double screenWidth,
  }) {
    final isNarrow = screenWidth < 720;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Search Input + Store Select + Sort Select
          if (isNarrow) ...[
            // Mobile: Stacked inputs
            _buildSearchInput(isEn, isDark),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildStoreSelect(stores, isEn)),
                const SizedBox(width: 8),
                Expanded(child: _buildSortSelect(isEn)),
              ],
            ),
          ] else ...[
            // Desktop: Inline inputs
            Row(
              children: [
                Expanded(flex: 3, child: _buildSearchInput(isEn, isDark)),
                const SizedBox(width: 10),
                SizedBox(width: 190, child: _buildStoreSelect(stores, isEn)),
                const SizedBox(width: 10),
                SizedBox(width: 175, child: _buildSortSelect(isEn)),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Middle: Quick City Switcher Horizontal Pills Bar (.city-pills-container)
          if (cities.isNotEmpty) ...[
            SizedBox(
              height: 38,
              child: ListView.separated(
                controller: _cityScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: cities.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  if (idx == 0) {
                    final isSelected = _selectedCityId == null;
                    return _buildCityPill(
                      label: isEn ? 'All Cities' : 'جميع المدن',
                      icon: Icons.public,
                      isSelected: isSelected,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedCityId = null),
                    );
                  }
                  final c = cities[idx - 1];
                  final isSelected = _selectedCityId == c.id;
                  return _buildCityPill(
                    label: isEn ? c.nameEn : c.nameAr,
                    icon: Icons.place,
                    isSelected: isSelected,
                    isDark: isDark,
                    onTap: () => setState(() => _selectedCityId = c.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Bottom: Filter Summary Row (.flyer-filter-summary-row)
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Active City Filter Indicator
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedCityId == null ? Icons.public : Icons.location_on,
                        size: 15,
                        color: const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _selectedCityId == null
                              ? (isEn ? 'Showing flyers from all cities & nationwide' : 'عرض البروشورات من جميع المدن وعلى مستوى المملكة')
                              : (isEn ? 'Showing flyers for ${_getSelectedCityName(cities, isRtl)} & Nationwide' : 'عرض بروشورات ${_getSelectedCityName(cities, isRtl)} وعروض المملكة'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Count Pill
                const SizedBox(width: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$filteredCount ',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                      TextSpan(
                        text: isEn ? 'flyers available' : 'بروشور متاح',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput(bool isEn, bool isDark) {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val.trim()),
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: isEn ? 'Search flyer titles, store names, or cities...' : 'ابحث في المجلات، أسماء المتاجر، أو المدن...',
        hintStyle: TextStyle(
          fontSize: 12.5,
          color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
        ),
        prefixIcon: Icon(
          Icons.search,
          size: 19,
          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildStoreSelect(List<Store> stores, bool isEn) {
    return AppCustomSelect<int?>(
      placeholder: isEn ? 'All Retailers' : 'جميع المتاجر',
      selectedValue: _selectedStoreId,
      clearable: true,
      options: [
        CustomSelectOption<int?>(
          value: null,
          labelEn: 'All Retailers',
          labelAr: 'جميع المتاجر',
          icon: Icons.storefront,
        ),
        ...stores.map((s) => CustomSelectOption<int?>(
              value: s.id,
              labelEn: s.nameEn,
              labelAr: s.nameAr,
              imageUrl: s.logoUrl,
            )),
      ],
      onChanged: (val) => setState(() => _selectedStoreId = val),
    );
  }

  Widget _buildSortSelect(bool isEn) {
    return AppCustomSelect<String>(
      placeholder: isEn ? 'Sort By' : 'ترتيب حسب',
      selectedValue: _sortBy,
      options: [
        CustomSelectOption<String>(value: 'newest', labelEn: 'Newest Added', labelAr: 'الأحدث إضافة', icon: Icons.schedule),
        CustomSelectOption<String>(value: 'expiring', labelEn: 'Expiring Soon', labelAr: 'ينتهي قريباً', icon: Icons.alarm),
        CustomSelectOption<String>(value: 'popular', labelEn: 'Most Viewed', labelAr: 'الأكثر مشاهدة', icon: Icons.visibility),
        CustomSelectOption<String>(value: 'pages', labelEn: 'Most Pages', labelAr: 'الأكثر صفحات', icon: Icons.auto_stories),
      ],
      onChanged: (val) => setState(() => _sortBy = val ?? 'newest'),
    );
  }

  Widget _buildCityPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF16A34A)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF16A34A)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Flyers Grid (.grid-flyers matching Angular)
  Widget _buildFlyersGrid({
    required List<Flyer> flyers,
    required int crossAxisCount,
    required double childAspectRatio,
    required bool isEn,
    required bool isRtl,
    required bool isDark,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: flyers.length,
      itemBuilder: (context, index) {
        final flyer = flyers[index];
        return _buildFlyerCard(flyer, isEn, isRtl, isDark);
      },
    );
  }

  // Flyer Card (.flyer-card matching Angular)
  Widget _buildFlyerCard(
    Flyer flyer,
    bool isEn,
    bool isRtl,
    bool isDark,
  ) {
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final isNationwide = _isNationwide(flyer);
    final cityBadgeText = _getCityBadgeText(flyer, isRtl);
    final isBookmarked = _bookmarkedFlyerIds.contains(flyer.id);

    final storeName = isEn
        ? (flyer.store?.nameEn ?? 'Store')
        : (flyer.store?.nameAr ?? flyer.store?.nameEn ?? 'متجر');
    final title = isEn
        ? flyer.titleEn
        : (flyer.titleAr.isNotEmpty ? flyer.titleAr : flyer.titleEn);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
          onTap: () => context.push('/flyers/${flyer.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Image Wrapper (.flyer-image-wrapper with Floating Badges)
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      child: AppNetworkImage(
                        imageUrl: AppConfig.normalizeImageUrl(flyer.coverImageUrl),
                        fit: BoxFit.cover,
                        defaultFallbackIcon: Icons.menu_book,
                      ),
                    ),

                    // Floating City Badge (Top Start)
                    Positioned.directional(
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      top: 10,
                      start: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isNationwide
                              ? const Color(0xFF10B981).withValues(alpha: 0.92)
                              : const Color(0xFF0F172A).withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isNationwide ? Icons.public : Icons.place,
                              size: 12,
                              color: isNationwide ? Colors.white : const Color(0xFF38BDF8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cityBadgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Floating Bookmark Button (Top End)
                    Positioned.directional(
                      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                      top: 10,
                      end: 10,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isBookmarked) {
                              _bookmarkedFlyerIds.remove(flyer.id);
                            } else {
                              _bookmarkedFlyerIds.add(flyer.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(9999),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A).withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            size: 16,
                            color: isBookmarked ? const Color(0xFF16A34A) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Flyer Card Body (.flyer-card-body)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Store badge row
                    InkWell(
                      onTap: flyer.storeId > 0 ? () => context.push('/stores/${flyer.storeId}') : null,
                      child: Row(
                        children: [
                          if (flyer.store != null && flyer.store!.logoUrl.isNotEmpty) ...[
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: borderColor),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: AppNetworkImage(
                                  imageUrl: AppConfig.normalizeImageUrl(flyer.store!.logoUrl),
                                  fit: BoxFit.cover,
                                  defaultFallbackIcon: Icons.storefront,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ] else ...[
                            const Icon(Icons.storefront, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Flyer Title
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Pages count & validity row
                    Container(
                      padding: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Pages
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_stories, size: 13, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              Text(
                                '${flyer.totalPages} ${isEn ? "Pages" : "صفحات"}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                          // Validity date
                          if (flyer.validUntil.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 13,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${isEn ? "Until " : "حتى "}${flyer.validUntil}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // "View Flyer" Action Button (.btn-view-flyer)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          elevation: 0,
                        ),
                        onPressed: () => context.push('/flyers/${flyer.id}'),
                        icon: const Icon(Icons.visibility, size: 15),
                        label: Text(
                          isEn ? 'View Flyer' : 'عرض البروشور',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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

  // Loading State
  Widget _buildLoadingState(bool isEn, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(60.0),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(color: Color(0xFF16A34A)),
            const SizedBox(height: 14),
            Text(
              isEn ? 'Loading flyers...' : 'جاري تحميل البروشورات...',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty State (.empty-state card)
  Widget _buildEmptyState(
    List<City> cities,
    bool isEn,
    bool isRtl,
    bool isDark,
  ) {
    final cityName = _getSelectedCityName(cities, isRtl);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 48,
            color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 14),
          Text(
            isEn ? 'No flyers found' : 'لا توجد بروشورات متاحة',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedCityId != null
                ? (isEn
                    ? 'No active promotional flyers found for $cityName. Check out all flyers across Saudi Arabia!'
                    : 'لم يتم العثور على نشرات عروض لـ $cityName حالياً. تصفح جميع العروض في كافة المدن!')
                : (isEn
                    ? 'No promotional flyers found matching your search criteria.'
                    : 'لم يتم العثور على أي نشرات عروض تطابق معايير البحث الحالية.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          if (_selectedCityId != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () => setState(() => _selectedCityId = null),
              icon: const Icon(Icons.public, size: 16),
              label: Text(
                isEn ? 'View Flyers from All Cities' : 'عرض البروشورات من جميع المدن',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ] else if (_searchQuery.isNotEmpty || _selectedStoreId != null) ...[
            const SizedBox(height: 18),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedStoreId = null;
                });
              },
              child: Text(isEn ? 'Clear Filters' : 'مسح الفلاتر'),
            ),
          ],
        ],
      ),
    );
  }
}
