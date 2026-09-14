import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/services/category_repository.dart';
import '../../../core/services/store_repository.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

class StoreListScreen extends ConsumerStatefulWidget {
  const StoreListScreen({super.key});

  @override
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends ConsumerState<StoreListScreen> {
  int? _selectedCityId;
  int? _selectedCategoryId;
  bool _onlyFollowed = false;
  bool _onlyVerified = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cityRepositoryProvider.notifier).fetchCities();
      ref.read(categoryRepositoryProvider.notifier).fetchCategories();
      ref.read(storeRepositoryProvider.notifier).fetchStores();
      ref.read(storeRepositoryProvider.notifier).fetchFollowedStores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedCityId != null) count++;
    if (_selectedCategoryId != null) count++;
    if (_onlyFollowed) count++;
    if (_onlyVerified) count++;
    if (_searchQuery.trim().isNotEmpty) count++;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCityId = null;
      _selectedCategoryId = null;
      _onlyFollowed = false;
      _onlyVerified = false;
    });
  }

  void _showAuthRequiredDialog(BuildContext context, AppLocalizations tr, bool isRtl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              isRtl ? 'تسجيل الدخول مطلوب' : 'Sign in Required',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          isRtl
              ? 'يرجى تسجيل الدخول لمتابعة المتاجر وتلقي إشعارات العروض فوراً.'
              : 'Please log in to follow stores and view your personalized feed.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr.get('cancel'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/login');
            },
            child: Text(tr.get('login'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<Store> _filterStores(List<Store> allStores, List<int> followedStoreIds) {
    return allStores.where((store) {
      if (_onlyFollowed && !followedStoreIds.contains(store.id)) {
        return false;
      }
      if (_onlyVerified && store.isVerified != 1) {
        return false;
      }
      if (_selectedCityId != null && store.cityId != _selectedCityId) {
        return false;
      }
      if (_selectedCategoryId != null && store.categoryId != _selectedCategoryId) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final nameEn = store.nameEn.toLowerCase();
        final nameAr = store.nameAr.toLowerCase();
        final cityEn = (store.cityNameEn ?? store.city?.nameEn ?? '').toLowerCase();
        final cityAr = (store.cityNameAr ?? store.city?.nameAr ?? '').toLowerCase();
        final catEn = (store.categoryNameEn ?? store.category?.nameEn ?? '').toLowerCase();
        final catAr = (store.categoryNameAr ?? store.category?.nameAr ?? '').toLowerCase();

        final matches = nameEn.contains(query) ||
            nameAr.contains(query) ||
            cityEn.contains(query) ||
            cityAr.contains(query) ||
            catEn.contains(query) ||
            catAr.contains(query);

        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final storeState = ref.watch(storeRepositoryProvider);
    final allStores = storeState.stores;
    final followedStoreIds = storeState.followedStoreIds;
    final cities = ref.watch(cityRepositoryProvider).cities;
    final categories = ref.watch(categoryRepositoryProvider).where((c) => c.parentId == null && c.isActive == 1).toList();

    final filteredStores = _filterStores(allStores, followedStoreIds);
    final isLoading = storeState.isLoading;
    final isDesktop = MediaQuery.of(context).size.width >= 992;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        child: isDesktop
            ? _buildDesktopLayout(
                context: context,
                tr: tr,
                isRtl: isRtl,
                isDark: isDark,
                cities: cities,
                categories: categories,
                filteredStores: filteredStores,
                isLoading: isLoading,
                followedStoreIds: followedStoreIds,
              )
            : _buildMobileLayout(
                context: context,
                tr: tr,
                isRtl: isRtl,
                isDark: isDark,
                cities: cities,
                categories: categories,
                filteredStores: filteredStores,
                isLoading: isLoading,
                followedStoreIds: followedStoreIds,
              ),
      ),
    );
  }

  // ==========================================
  // DESKTOP LAYOUT (Sidebar + Grid)
  // ==========================================
  Widget _buildDesktopLayout({
    required BuildContext context,
    required AppLocalizations tr,
    required bool isRtl,
    required bool isDark,
    required List<City> cities,
    required List<Category> categories,
    required List<Store> filteredStores,
    required bool isLoading,
    required List<int> followedStoreIds,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          SizedBox(
            width: 290,
            child: SingleChildScrollView(
              child: _buildSidebarFilterCard(
                context: context,
                tr: tr,
                isRtl: isRtl,
                isDark: isDark,
                cities: cities,
                categories: categories,
                followedStoreIds: followedStoreIds,
              ),
            ),
          ),
          const SizedBox(width: 24),

          // Main Stores Content Area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active Summary Bar
                _buildActiveSummaryBar(
                  tr: tr,
                  isRtl: isRtl,
                  isDark: isDark,
                  cities: cities,
                  categories: categories,
                  totalStoresCount: filteredStores.length,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 16),

                // Grid / Loading / Empty
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF10B981)),
                        )
                      : filteredStores.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: _buildEmptyState(tr: tr, isRtl: isRtl, isDark: isDark),
                              ),
                            )
                          : RefreshIndicator(
                              color: const Color(0xFF10B981),
                              onRefresh: () async {
                                await ref.read(storeRepositoryProvider.notifier).fetchStores();
                                await ref.read(storeRepositoryProvider.notifier).fetchFollowedStores();
                              },
                              child: _buildStoreCardsGrid(
                                filteredStores: filteredStores,
                                isRtl: isRtl,
                                isDark: isDark,
                                tr: tr,
                                followedStoreIds: followedStoreIds,
                                crossAxisCount: 3,
                                childAspectRatio: 0.68,
                                logoHeight: 125,
                                isScrollable: true,
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MOBILE LAYOUT (Filter Bar + Trigger + Grid)
  // ==========================================
  Widget _buildMobileLayout({
    required BuildContext context,
    required AppLocalizations tr,
    required bool isRtl,
    required bool isDark,
    required List<City> cities,
    required List<Category> categories,
    required List<Store> filteredStores,
    required bool isLoading,
    required List<int> followedStoreIds,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mobile Filter Top Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Filter & Search Trigger Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () => _openMobileFilterDrawer(
                  context: context,
                  tr: tr,
                  isRtl: isRtl,
                  isDark: isDark,
                  cities: cities,
                  categories: categories,
                  followedStoreIds: followedStoreIds,
                  filteredCount: filteredStores.length,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune, size: 17),
                    const SizedBox(width: 8),
                    Text(
                      tr.get('filter_and_search'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (_activeFiltersCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_activeFiltersCount',
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Results Count on Mobile
              Text(
                isLoading
                    ? tr.get('loading')
                    : '${filteredStores.length} ${isRtl ? 'متجر' : 'stores'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // Active Chips Bar (if filters active)
        if (_activeFiltersCount > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
            ),
            child: _buildActiveChipsWrap(
              tr: tr,
              isRtl: isRtl,
              isDark: isDark,
              cities: cities,
              categories: categories,
            ),
          ),

        // Main Grid / Empty State
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                )
              : filteredStores.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildEmptyState(tr: tr, isRtl: isRtl, isDark: isDark),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF10B981),
                      onRefresh: () async {
                        await ref.read(storeRepositoryProvider.notifier).fetchStores();
                        await ref.read(storeRepositoryProvider.notifier).fetchFollowedStores();
                      },
                      child: _buildStoreCardsGrid(
                        filteredStores: filteredStores,
                        isRtl: isRtl,
                        isDark: isDark,
                        tr: tr,
                        followedStoreIds: followedStoreIds,
                        crossAxisCount: 2,
                        childAspectRatio: 0.58,
                        logoHeight: 105,
                        isScrollable: true,
                      ),
                    ),
        ),
      ],
    );
  }

  // ==========================================
  // SIDEBAR FILTER CARD (Matches Angular Aside)
  // ==========================================
  Widget _buildSidebarFilterCard({
    required BuildContext context,
    required AppLocalizations tr,
    required bool isRtl,
    required bool isDark,
    required List<City> cities,
    required List<Category> categories,
    required List<int> followedStoreIds,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront, color: Color(0xFF10B981), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          tr.get('filter_stores'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (_activeFiltersCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_activeFiltersCount',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _resetFilters,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tr.get('reset'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sidebar Body
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: _buildFilterBodyForm(
              tr: tr,
              isRtl: isRtl,
              isDark: isDark,
              cities: cities,
              categories: categories,
              followedStoreIds: followedStoreIds,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED FILTER BODY CONTROLS
  // ==========================================
  Widget _buildFilterBodyForm({
    required AppLocalizations tr,
    required bool isRtl,
    required bool isDark,
    required List<City> cities,
    required List<Category> categories,
    required List<int> followedStoreIds,
    StateSetter? setModalState,
  }) {
    void updateState(VoidCallback fn) {
      if (setModalState != null) {
        setModalState(fn);
      }
      setState(fn);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Search Keyword
        Text(
          tr.get('search_store'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _searchController,
          onChanged: (val) {
            updateState(() {
              _searchQuery = val.trim();
            });
          },
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: tr.get('search_store_names'),
            hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF10B981)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      updateState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 2. City Selector
        Text(
          tr.get('city'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _selectedCityId,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    tr.get('all_cities'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedCityId == null ? FontWeight.bold : FontWeight.normal,
                      color: _selectedCityId == null ? const Color(0xFF10B981) : null,
                    ),
                  ),
                ),
                ...cities.map((city) => DropdownMenuItem<int?>(
                      value: city.id,
                      child: Text(
                        isRtl ? city.nameAr : city.nameEn,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedCityId == city.id ? FontWeight.bold : FontWeight.normal,
                          color: _selectedCityId == city.id ? const Color(0xFF10B981) : null,
                        ),
                      ),
                    )),
              ],
              onChanged: (val) {
                updateState(() {
                  _selectedCityId = val;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 3. Category Filter + Quick Chips
        Text(
          tr.get('category'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _selectedCategoryId,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    tr.get('all_categories'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _selectedCategoryId == null ? FontWeight.bold : FontWeight.normal,
                      color: _selectedCategoryId == null ? const Color(0xFF10B981) : null,
                    ),
                  ),
                ),
                ...categories.map((cat) => DropdownMenuItem<int?>(
                      value: cat.id,
                      child: Text(
                        isRtl ? cat.nameAr : cat.nameEn,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedCategoryId == cat.id ? FontWeight.bold : FontWeight.normal,
                          color: _selectedCategoryId == cat.id ? const Color(0xFF10B981) : null,
                        ),
                      ),
                    )),
              ],
              onChanged: (val) {
                updateState(() {
                  _selectedCategoryId = val;
                });
              },
            ),
          ),
        ),

        // Category Quick Chips
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildFilterChip(
                label: tr.get('all'),
                isActive: _selectedCategoryId == null,
                isDark: isDark,
                onTap: () {
                  updateState(() {
                    _selectedCategoryId = null;
                  });
                },
              ),
              ...categories.map((cat) {
                final isActive = _selectedCategoryId == cat.id;
                return _buildFilterChip(
                  label: isRtl ? cat.nameAr : cat.nameEn,
                  isActive: isActive,
                  isDark: isDark,
                  onTap: () {
                    updateState(() {
                      _selectedCategoryId = cat.id;
                    });
                  },
                );
              }),
            ],
          ),
        ],
        const SizedBox(height: 18),

        // 4. Toggle Checkboxes Divider
        Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0), height: 1),
        const SizedBox(height: 14),

        // Followed Stores Checkbox
        InkWell(
          onTap: () {
            final isLoggedIn = ref.read(authProvider).isLoggedIn;
            if (!isLoggedIn && !_onlyFollowed) {
              _showAuthRequiredDialog(context, tr, isRtl);
              return;
            }
            updateState(() {
              _onlyFollowed = !_onlyFollowed;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _onlyFollowed,
                    activeColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      final isLoggedIn = ref.read(authProvider).isLoggedIn;
                      if (!isLoggedIn && (val ?? false)) {
                        _showAuthRequiredDialog(context, tr, isRtl);
                        return;
                      }
                      updateState(() {
                        _onlyFollowed = val ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${tr.get('followed_stores_only')} ${followedStoreIds.isNotEmpty ? '(${followedStoreIds.length})' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _onlyFollowed ? const Color(0xFF10B981) : (isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Verified Stores Checkbox
        InkWell(
          onTap: () {
            updateState(() {
              _onlyVerified = !_onlyVerified;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: _onlyVerified,
                    activeColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      updateState(() {
                        _onlyVerified = val ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr.get('verified_stores_only'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _onlyVerified ? const Color(0xFF10B981) : (isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF10B981)
              : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF10B981)
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ACTIVE SUMMARY BAR (Desktop & Mobile Chips)
  // ==========================================
  Widget _buildActiveSummaryBar({
    required AppLocalizations tr,
    required bool isRtl,
    required bool isDark,
    required List<City> cities,
    required List<Category> categories,
    required int totalStoresCount,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Info
          Row(
            children: [
              const Icon(Icons.storefront, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                  children: [
                    TextSpan(text: '${tr.get('found')} '),
                    TextSpan(
                      text: '$totalStoresCount ',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    TextSpan(text: tr.get('partner_stores')),
                  ],
                ),
              ),
            ],
          ),

          // Right Active Chips
          if (_activeFiltersCount > 0)
            _buildActiveChipsWrap(
              tr: tr,
              isRtl: isRtl,
              isDark: isDark,
              cities: cities,
              categories: categories,
            ),
        ],
      ),
    );
  }

  Widget _buildActiveChipsWrap({
    required AppLocalizations tr,
    required bool isRtl,
    required bool isDark,
    required List<City> cities,
    required List<Category> categories,
  }) {
    final selectedCity = cities.where((c) => c.id == _selectedCityId).firstOrNull;
    final selectedCat = categories.where((c) => c.id == _selectedCategoryId).firstOrNull;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // City Chip
        if (selectedCity != null)
          _buildRemovableChip(
            icon: Icons.place,
            label: isRtl ? selectedCity.nameAr : selectedCity.nameEn,
            bgColor: const Color(0xFFEFF6FF),
            textColor: const Color(0xFF1D4ED8),
            borderColor: const Color(0xFFBFDBFE),
            onRemove: () => setState(() => _selectedCityId = null),
          ),

        // Category Chip
        if (selectedCat != null)
          _buildRemovableChip(
            icon: Icons.category,
            label: isRtl ? selectedCat.nameAr : selectedCat.nameEn,
            bgColor: const Color(0xFFF0FDF4),
            textColor: const Color(0xFF166534),
            borderColor: const Color(0xFFBBF7D0),
            onRemove: () => setState(() => _selectedCategoryId = null),
          ),

        // Followed Chip
        if (_onlyFollowed)
          _buildRemovableChip(
            icon: Icons.favorite,
            label: tr.get('followed_stores'),
            bgColor: const Color(0xFFFFF1F2),
            textColor: const Color(0xFFE11D48),
            borderColor: const Color(0xFFFECDD3),
            onRemove: () => setState(() => _onlyFollowed = false),
          ),

        // Verified Chip
        if (_onlyVerified)
          _buildRemovableChip(
            icon: Icons.verified,
            label: tr.get('verified'),
            bgColor: const Color(0xFFECFDF5),
            textColor: const Color(0xFF059669),
            borderColor: const Color(0xFFA7F3D0),
            onRemove: () => setState(() => _onlyVerified = false),
          ),

        // Clear All Button
        InkWell(
          onTap: _resetFilters,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.close, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  tr.get('clear_all'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemovableChip({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: textColor),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STORE CARDS GRID
  // ==========================================
  Widget _buildStoreCardsGrid({
    required List<Store> filteredStores,
    required bool isRtl,
    required bool isDark,
    required AppLocalizations tr,
    required List<int> followedStoreIds,
    required int crossAxisCount,
    required double childAspectRatio,
    required double logoHeight,
    bool isScrollable = false,
  }) {
    return GridView.builder(
      shrinkWrap: !isScrollable,
      physics: isScrollable ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: filteredStores.length,
      itemBuilder: (context, index) {
        final store = filteredStores[index];
        return _buildStoreCard(
          context: context,
          store: store,
          isRtl: isRtl,
          isDark: isDark,
          tr: tr,
          isFollowed: followedStoreIds.contains(store.id),
          logoHeight: logoHeight,
        );
      },
    );
  }

  // ==========================================
  // STORE CARD (Exact 1:1 match with Angular)
  // ==========================================
  Widget _buildStoreCard({
    required BuildContext context,
    required Store store,
    required bool isRtl,
    required bool isDark,
    required AppLocalizations tr,
    required bool isFollowed,
    required double logoHeight,
  }) {
    final storeName = isRtl ? store.nameAr : store.nameEn;
    final categoryName = isRtl
        ? (store.categoryNameAr ?? store.category?.nameAr ?? store.categoryNameEn ?? '')
        : (store.categoryNameEn ?? store.category?.nameEn ?? '');
    final cityName = isRtl
        ? (store.cityNameAr ?? store.city?.nameAr ?? store.cityNameEn ?? '')
        : (store.cityNameEn ?? store.city?.nameEn ?? '');

    final isVerified = store.isVerified == 1 || store.verified;
    final followersCount = store.followersCount ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Image Logo Panel with Floating Verified Badge
            Stack(
              children: [
                // Logo Container
                GestureDetector(
                  onTap: () => context.go('/stores/${store.id}'),
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: Container(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.center,
                      child: store.logoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: AppConfig.normalizeImageUrl(store.logoUrl),
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.storefront,
                                size: 36,
                                color: isDark ? Colors.white30 : Colors.black26,
                              ),
                            )
                          : Icon(
                              Icons.storefront,
                              size: 36,
                              color: isDark ? Colors.white30 : Colors.black26,
                            ),
                    ),
                  ),
                ),

                // Floating Verified Badge
                if (isVerified)
                  Positioned(
                    top: 6,
                    left: isRtl ? null : 6,
                    right: isRtl ? 6 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, size: 11, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            tr.get('verified'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Divider between logo and body
            Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0), height: 1),

            // Store Body Panel
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Store Title
                  GestureDetector(
                    onTap: () => context.go('/stores/${store.id}'),
                    child: Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Category Subtitle
                  Text(
                    categoryName.isNotEmpty ? categoryName : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Counts row (Followers + City)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      // Followers tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people, size: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                '$followersCount ${tr.get('followers')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // City tag
                      if (cityName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.place, size: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  cityName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Actions Row (Follow Button + Details Chevron)
                  Row(
                    children: [
                      // Follow / Following Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final isLoggedIn = ref.read(authProvider).isLoggedIn;
                            if (!isLoggedIn) {
                              _showAuthRequiredDialog(context, tr, isRtl);
                              return;
                            }
                            ref.read(storeRepositoryProvider.notifier).toggleFollowStore(store.id);
                          },
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isFollowed
                                  ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                                  : const Color(0xFF10B981),
                              border: isFollowed
                                  ? Border.all(color: const Color(0xFF10B981), width: 1.5)
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFollowed ? Icons.check_circle : Icons.favorite_border,
                                  size: 12,
                                  color: isFollowed ? const Color(0xFF10B981) : Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    isFollowed ? tr.get('following') : tr.get('follow'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isFollowed ? const Color(0xFF10B981) : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Chevron Details Button
                      GestureDetector(
                        onTap: () => context.go('/stores/${store.id}'),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                          ),
                          child: Icon(
                            isRtl ? Icons.chevron_left : Icons.chevron_right,
                            size: 16,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // EMPTY STATE CARD
  // ==========================================
  Widget _buildEmptyState({
    required AppLocalizations tr,
    required bool isRtl,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.storefront_outlined,
            size: 52,
            color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            tr.get('no_stores_match'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr.get('no_stores_match_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(
              tr.get('reset_all_filters'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: _resetFilters,
          ),
        ],
      ),
    );
  }
  void _openMobileFilterDrawer({
    required BuildContext context,
    required AppLocalizations tr,
    required bool isRtl,
    required bool isDark,
    required List<City> cities,
    required List<Category> categories,
    required List<int> followedStoreIds,
    required int filteredCount,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allStores = ref.read(storeRepositoryProvider).stores;
            final currentFiltered = _filterStores(allStores, followedStoreIds);

            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Drawer Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront, color: Color(0xFF10B981), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                tr.get('filter_stores'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              if (_activeFiltersCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$_activeFiltersCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  _resetFilters();
                                  setModalState(() {});
                                },
                                child: Text(
                                  tr.get('reset'),
                                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Drawer Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: _buildFilterBodyForm(
                          tr: tr,
                          isRtl: isRtl,
                          isDark: isDark,
                          cities: cities,
                          categories: categories,
                          followedStoreIds: followedStoreIds,
                          setModalState: setModalState,
                        ),
                      ),
                    ),

                    // Drawer Sticky Action Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: Border(top: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                                side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.restart_alt, size: 16),
                              label: Text(tr.get('reset'), style: const TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                _resetFilters();
                                setModalState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text(
                                '${tr.get('show_stores')} (${currentFiltered.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
