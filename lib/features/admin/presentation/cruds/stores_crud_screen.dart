import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' hide Category;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/services/category_repository.dart';
import '../../../../core/services/city_repository.dart';
import '../../../../core/services/store_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../models/category.dart';
import '../../../../models/city.dart';
import '../../../../models/store.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../widgets/crud_loading_widget.dart';

class StoresCrudScreen extends ConsumerStatefulWidget {
  const StoresCrudScreen({super.key});

  @override
  ConsumerState<StoresCrudScreen> createState() => _StoresCrudScreenState();
}

class _StoresCrudScreenState extends ConsumerState<StoresCrudScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedStatusFilter = ''; // '', 'verified', 'featured', 'active', 'inactive'
  int? _selectedCityFilter;
  int? _selectedCategoryFilter;

  // Pagination state (Infinite Scroll)
  int _displayedCount = 20;
  bool _loadingMore = false;
  bool _showScrollTop = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storeRepositoryProvider.notifier).fetchStores();
      ref.read(cityRepositoryProvider.notifier).fetchCities();
      ref.read(categoryRepositoryProvider.notifier).fetchCategories();
    });
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showScrollTop) {
        setState(() => _showScrollTop = show);
      }
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
        final allStores = ref.read(storeRepositoryProvider).stores;
        final filtered = _getFilteredStores(allStores);
        _loadMore(filtered.length);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMore(int totalCount) {
    if (_loadingMore || _displayedCount >= totalCount) return;
    setState(() => _loadingMore = true);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _displayedCount = (_displayedCount + 20).clamp(0, totalCount);
          _loadingMore = false;
        });
      }
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  List<Store> _getFilteredStores(List<Store> allStores) {
    final query = _searchQuery.toLowerCase().trim();
    var list = allStores;

    if (query.isNotEmpty) {
      list = list.where((s) {
        final nameEn = s.nameEn.toLowerCase();
        final nameAr = s.nameAr.toLowerCase();
        final cr = (s.crNumber ?? '').toLowerCase();
        final vat = (s.vatNumber ?? '').toLowerCase();
        final cityEn = (s.cityNameEn ?? s.city?.nameEn ?? '').toLowerCase();
        final idStr = s.id.toString();
        return nameEn.contains(query) ||
            nameAr.contains(query) ||
            cr.contains(query) ||
            vat.contains(query) ||
            cityEn.contains(query) ||
            idStr.contains(query);
      }).toList();
    }

    if (_selectedCityFilter != null) {
      list = list.where((s) => s.cityId == _selectedCityFilter).toList();
    }

    if (_selectedCategoryFilter != null) {
      list = list.where((s) => s.categoryId == _selectedCategoryFilter).toList();
    }

    if (_selectedStatusFilter == 'active') {
      list = list.where((s) => s.active).toList();
    } else if (_selectedStatusFilter == 'inactive') {
      list = list.where((s) => !s.active).toList();
    } else if (_selectedStatusFilter == 'verified') {
      list = list.where((s) => s.verified).toList();
    } else if (_selectedStatusFilter == 'featured') {
      list = list.where((s) => s.featured).toList();
    }

    return list;
  }

  void _setStatusFilter(String filter) {
    setState(() {
      _selectedStatusFilter = _selectedStatusFilter == filter ? '' : filter;
      _displayedCount = 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storeState = ref.watch(storeRepositoryProvider);
    final allStores = storeState.stores;
    final cities = ref.watch(cityRepositoryProvider).cities;
    final categories = ref.watch(categoryRepositoryProvider);
    final authState = ref.watch(authProvider);
    final isSuperAdmin = (authState.currentAdmin?.role ?? 'SUPER_ADMIN').toUpperCase() == 'SUPER_ADMIN';

    final filteredStores = _getFilteredStores(allStores);

    final totalCount = allStores.length;
    final verifiedCount = allStores.where((s) => s.verified).length;
    final featuredCount = allStores.where((s) => s.featured).length;
    final activeCount = allStores.where((s) => s.active).length;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () async {
            await Future.wait([
              ref.read(storeRepositoryProvider.notifier).fetchStores(),
              ref.read(cityRepositoryProvider.notifier).fetchCities(),
              ref.read(categoryRepositoryProvider.notifier).fetchCategories(),
            ]);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Page Header Block
                _buildHeaderBlock(context, isRtl, isDark, isSuperAdmin, cities, categories),
                const SizedBox(height: 14),

                // 2. Stats Cards Bar (Interactive Filters)
                _buildStatsGrid(
                  totalCount: totalCount,
                  verifiedCount: verifiedCount,
                  featuredCount: featuredCount,
                  activeCount: activeCount,
                  isRtl: isRtl,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // 3. Search & Dropdown Filter Toolbar
                _buildFilterToolbar(
                  filteredCount: filteredStores.length,
                  cities: cities,
                  categories: categories,
                  isRtl: isRtl,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // 4. Stores List / Loading State / Empty State
                if (storeState.isLoading && allStores.isEmpty) ...[
                  _buildLoadingState(isRtl, isDark),
                ] else if (filteredStores.isEmpty) ...[
                  _buildEmptyState(isRtl, isDark),
                ] else ...[
                  _buildStoresList(filteredStores, cities, categories, isRtl, isDark, isSuperAdmin),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        floatingActionButton: _showScrollTop
            ? FloatingActionButton.small(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                onPressed: _scrollToTop,
                child: const Icon(Icons.arrow_upward, size: 18),
              )
            : null,
      ),
    );
  }

  // 1. Header Block
  Widget _buildHeaderBlock(
    BuildContext context,
    bool isRtl,
    bool isDark,
    bool isSuperAdmin,
    List<City> cities,
    List<Category> categories,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final titleGroup = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
              ),
              child: const Icon(
                Icons.storefront,
                color: Color(0xFF16A34A),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'إدارة المتاجر والشركاء' : 'Store & Merchant Management',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isRtl
                        ? 'إدارة المتاجر المعتمدة والملفات التجارية والهوية البصرية'
                        : 'Manage verified retailers, business profiles, and brand identities',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final addButton = ElevatedButton.icon(
          onPressed: () => _showAddEditStoreModal(context, isRtl, isDark, cities, categories),
          icon: const Icon(Icons.add_business, size: 16),
          label: Text(
            isRtl ? 'إضافة متجر جديد' : 'Add Store',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleGroup,
                    if (isSuperAdmin) ...[
                      const SizedBox(height: 10),
                      addButton,
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: titleGroup),
                    if (isSuperAdmin) ...[
                      const SizedBox(width: 12),
                      addButton,
                    ],
                  ],
                ),
        );
      },
    );
  }

  // 2. Stats Grid (Clickable Filters matching Angular)
  Widget _buildStatsGrid({
    required int totalCount,
    required int verifiedCount,
    required int featuredCount,
    required int activeCount,
    required bool isRtl,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.3,
            children: [
              _buildStatCard(
                filterKey: '',
                icon: Icons.store,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFDBEAFE),
                count: totalCount,
                label: isRtl ? 'إجمالي المتاجر' : 'Total Retailers',
                isDark: isDark,
              ),
              _buildStatCard(
                filterKey: 'verified',
                icon: Icons.verified,
                iconColor: const Color(0xFF059669),
                bgColor: const Color(0xFFD1FAE5),
                count: verifiedCount,
                label: isRtl ? 'شركاء معتمدون' : 'Verified Partners',
                isDark: isDark,
              ),
              _buildStatCard(
                filterKey: 'featured',
                icon: Icons.star,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                count: featuredCount,
                label: isRtl ? 'متاجر مميزة' : 'Featured Stores',
                isDark: isDark,
              ),
              _buildStatCard(
                filterKey: 'active',
                icon: Icons.check_circle,
                iconColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFFDCFCE7),
                count: activeCount,
                label: isRtl ? 'متاجر نشطة' : 'Active Status',
                isDark: isDark,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                filterKey: '',
                icon: Icons.store,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFDBEAFE),
                count: totalCount,
                label: isRtl ? 'إجمالي المتاجر' : 'Total Retailers',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                filterKey: 'verified',
                icon: Icons.verified,
                iconColor: const Color(0xFF059669),
                bgColor: const Color(0xFFD1FAE5),
                count: verifiedCount,
                label: isRtl ? 'شركاء معتمدون' : 'Verified Partners',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                filterKey: 'featured',
                icon: Icons.star,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                count: featuredCount,
                label: isRtl ? 'متاجر مميزة' : 'Featured Stores',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                filterKey: 'active',
                icon: Icons.check_circle,
                iconColor: const Color(0xFF16A34A),
                bgColor: const Color(0xFFDCFCE7),
                count: activeCount,
                label: isRtl ? 'متاجر نشطة' : 'Active Status',
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String filterKey,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required int count,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _selectedStatusFilter == filterKey;

    return InkWell(
      onTap: () => _setStatusFilter(filterKey),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF16A34A)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Search & Filter Toolbar
  Widget _buildFilterToolbar({
    required int filteredCount,
    required List<City> cities,
    required List<Category> categories,
    required bool isRtl,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Search Input
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {
                      _searchQuery = val;
                      _displayedCount = 20;
                    }),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: isRtl
                          ? 'بحث بالاسم، السجل التجاري، الرقم الضريبي، أو المدينة...'
                          : 'Search by name, CR, VAT, or city...',
                      hintStyle: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 16,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 15),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _displayedCount = 20;
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Total Count Pill
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text(
                      '$filteredCount ${isRtl ? 'متجر' : 'stores'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Filters Row: City & Category Dropdowns
          Row(
            children: [
              // City Filter
              Expanded(
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Builder(
                    builder: (context) {
                      final uniqueCities = <int, City>{};
                      for (final c in cities) {
                        uniqueCities[c.id] = c;
                      }
                      final safeCities = uniqueCities.values.toList();
                      final validCityVal = safeCities.any((c) => c.id == _selectedCityFilter) ? _selectedCityFilter : null;

                      return DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: validCityVal,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          icon: const Icon(Icons.place, size: 14, color: Color(0xFF16A34A)),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                isRtl ? 'جميع المدن' : 'All Cities',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            ...safeCities.map((City c) => DropdownMenuItem<int?>(
                                  value: c.id,
                                  child: Text(
                                    isRtl ? c.nameAr : c.nameEn,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                )),
                          ],
                          onChanged: (val) => setState(() {
                            _selectedCityFilter = val;
                            _displayedCount = 20;
                          }),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Category Filter
              Expanded(
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Builder(
                    builder: (context) {
                      final uniqueCategories = <int, Category>{};
                      for (final cat in categories) {
                        uniqueCategories[cat.id] = cat;
                      }
                      final safeCategories = uniqueCategories.values.toList();
                      final validCatVal = safeCategories.any((cat) => cat.id == _selectedCategoryFilter) ? _selectedCategoryFilter : null;

                      return DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: validCatVal,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          icon: const Icon(Icons.category, size: 14, color: Color(0xFF16A34A)),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                isRtl ? 'جميع الفئات' : 'All Categories',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            ...safeCategories.map((Category cat) => DropdownMenuItem<int?>(
                                  value: cat.id,
                                  child: Text(
                                    isRtl ? cat.nameAr : cat.nameEn,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                )),
                          ],
                          onChanged: (val) => setState(() {
                            _selectedCategoryFilter = val;
                            _displayedCount = 20;
                          }),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Loading State
  Widget _buildLoadingState(bool isRtl, bool isDark) {
    return CrudLoadingWidget(
      titleEn: 'Loading Store & Retailer Directory...',
      titleAr: 'جاري تحميل دليل المتاجر والشركاء...',
      subtitleEn: 'Fetching verified business profiles and locations...',
      subtitleAr: 'جاري جلب الملفات التجارية المعتمدة والمواقع...',
      icon: Icons.storefront_rounded,
      isRtl: isRtl,
      isDark: isDark,
    );
  }

  // 5. Empty State
  Widget _buildEmptyState(bool isRtl, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_outlined, size: 24, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          Text(
            isRtl ? 'لم يتم العثور على متاجر' : 'No Stores Found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isRtl
                ? 'جرب تعديل خيارات البحث أو قم بإضافة متجر جديد.'
                : 'Try adjusting your search criteria or register a new store.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          if (_searchQuery.isNotEmpty || _selectedCityFilter != null || _selectedCategoryFilter != null || _selectedStatusFilter.isNotEmpty) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.refresh, size: 14),
              label: Text(isRtl ? 'إعادة ضبط الفلاتر' : 'Reset Filters', style: const TextStyle(fontSize: 11.5)),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCityFilter = null;
                  _selectedCategoryFilter = null;
                  _selectedStatusFilter = '';
                  _displayedCount = 20;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  // 6. Stores List Items
  Widget _buildStoresList(
    List<Store> stores,
    List<City> cities,
    List<Category> categories,
    bool isRtl,
    bool isDark,
    bool isSuperAdmin,
  ) {
    final displayedStores = stores.take(_displayedCount).toList();

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayedStores.length,
          separatorBuilder: (_, __) => const SizedBox(height: 7),
          itemBuilder: (context, index) {
            final s = displayedStores[index];
            final logoUrl = AppConfig.normalizeImageUrl(s.logoUrl);

            final cityName = isRtl
                ? (s.cityNameAr ?? s.city?.nameAr ?? s.cityNameEn ?? s.city?.nameEn)
                : (s.cityNameEn ?? s.city?.nameEn ?? s.cityNameAr ?? s.city?.nameAr);

            final categoryName = isRtl
                ? (s.categoryNameAr ?? s.category?.nameAr ?? s.categoryNameEn ?? s.category?.nameEn)
                : (s.categoryNameEn ?? s.category?.nameEn ?? s.categoryNameAr ?? s.category?.nameAr);

            return Material(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _showAddEditStoreModal(context, isRtl, isDark, cities, categories, s),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: Store Logo Avatar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: AppNetworkImage(
                            imageUrl: logoUrl,
                            fit: BoxFit.contain,
                            defaultFallbackIcon: Icons.storefront_outlined,
                            fallbackIconSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Middle: Identity & Metadata tags
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row with ID, Featured badge & Verified icon
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    isRtl ? (s.nameAr.isNotEmpty ? s.nameAr : s.nameEn) : s.nameEn,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#${s.id}',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                if (s.featured) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star, size: 10, color: Color(0xFFD97706)),
                                        SizedBox(width: 2),
                                        Text(
                                          'Featured',
                                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (s.verified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, size: 14, color: Color(0xFF2563EB)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 1),

                            // Secondary counterpart name
                            Text(
                              isRtl ? s.nameEn : s.nameAr,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),

                            // Metadata row (City, Category, Followers, CR)
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (cityName != null && cityName.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.place, size: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        const SizedBox(width: 2),
                                        Text(
                                          cityName,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (categoryName != null && categoryName.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.category, size: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        const SizedBox(width: 2),
                                        Text(
                                          categoryName,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (s.followersCount != null && s.followersCount! > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.people, size: 10, color: Color(0xFF166534)),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${s.followersCount}',
                                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (s.crNumber != null && s.crNumber!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Text(
                                      'CR: ${s.crNumber}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Right Group: Active Pill & Action Buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: s.active
                                  ? const Color(0xFFDCFCE7)
                                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: s.active
                                    ? const Color(0xFF16A34A).withValues(alpha: 0.25)
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: s.active ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  s.active ? (isRtl ? 'نشط' : 'Active') : (isRtl ? 'معطل' : 'Inactive'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: s.active ? const Color(0xFF166534) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Action Buttons Group matching Angular .btn-item-action (Image 2)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Manage Branches Action (Building / Domain icon)
                              Tooltip(
                                message: isRtl ? 'إدارة الفروع' : 'Manage Branches',
                                child: Material(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(7),
                                  child: InkWell(
                                    onTap: () => context.go('/admin/stores/${s.id}/branches'),
                                    borderRadius: BorderRadius.circular(7),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.domain,
                                        size: 16,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),

                              // 2. Edit Store Action (Pencil icon)
                              Tooltip(
                                message: isRtl ? 'تعديل المتجر' : 'Edit Store',
                                child: Material(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(7),
                                  child: InkWell(
                                    onTap: () => _showAddEditStoreModal(context, isRtl, isDark, cities, categories, s),
                                    borderRadius: BorderRadius.circular(7),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),

                              // 3. Delete Store Action (Trash icon - Super Admin)
                              if (isSuperAdmin) ...[
                                Tooltip(
                                  message: isRtl ? 'حذف المتجر' : 'Delete Store',
                                  child: Material(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(7),
                                    child: InkWell(
                                      onTap: () => _showDeleteStoreDialog(context, s, isRtl, isDark),
                                      borderRadius: BorderRadius.circular(7),
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(7),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Bottom Sentinel: Loading More indicator or End of Catalog pill
        if (_loadingMore) ...[
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRtl ? 'جاري تحميل المزيد من المتاجر...' : 'Loading more stores...',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else if (displayedStores.length >= stores.length && stores.length > 20) ...[
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Text(
                    isRtl
                        ? 'تم عرض كافة المتاجر (${stores.length})'
                        : 'All ${stores.length} stores loaded',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // 7. Add / Edit Store Modal (Pixel-Perfect 6 Sections matching Angular)
  void _showAddEditStoreModal(
    BuildContext context,
    bool isRtl,
    bool isDark,
    List<City> cities,
    List<Category> categories, [
    Store? store,
  ]) {
    final nameEnCtrl = TextEditingController(text: store?.nameEn ?? '');
    final nameArCtrl = TextEditingController(text: store?.nameAr ?? '');
    final descEnCtrl = TextEditingController(text: store?.descriptionEn ?? '');
    final descArCtrl = TextEditingController(text: store?.descriptionAr ?? '');
    final crCtrl = TextEditingController(text: store?.crNumber ?? '');
    final vatCtrl = TextEditingController(text: store?.vatNumber ?? '');
    final phoneCtrl = TextEditingController(text: store?.contactPhone ?? '');
    final emailCtrl = TextEditingController(text: store?.contactEmail ?? '');
    final webCtrl = TextEditingController(text: store?.website ?? '');

    // Manager account fields (for Add Store)
    final mgrNameCtrl = TextEditingController(text: store?.nameEn ?? '');
    final mgrEmailCtrl = TextEditingController(text: store?.contactEmail ?? '');
    final mgrPassCtrl = TextEditingController(text: 'Partner@123');

    // Safe initial city selection
    int? selectedCityId = store?.cityId;
    if (selectedCityId == null || !cities.any((c) => c.id == selectedCityId)) {
      selectedCityId = cities.isNotEmpty ? cities.first.id : null;
    }

    // Safe initial category selection
    int? selectedCategoryId = store?.categoryId;
    if (selectedCategoryId == null || !categories.any((c) => c.id == selectedCategoryId)) {
      selectedCategoryId = categories.isNotEmpty ? categories.first.id : null;
    }

    bool isVerified = store == null ? false : store.verified;
    bool isFeatured = store == null ? false : store.featured;
    bool isActive = store == null ? true : store.active;
    bool createManagerAccount = true;

    XFile? pickedLogoFile;
    Uint8List? pickedLogoBytes;
    String? existingLogoUrl = store?.logoUrl;

    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    store == null ? Icons.add_business : Icons.edit_note,
                    color: const Color(0xFF16A34A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store == null
                            ? (isRtl ? 'تسجيل متجر جديد' : 'Register New Store')
                            : (isRtl ? 'تعديل بيانات المتجر' : 'Edit Store Profile'),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRtl
                            ? 'أدخل بيانات الهوية والتراخيص الرسمية وتفاصيل المتجر'
                            : 'Provide store branding, official details, and localization info',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: Store Logo & Branding
                    _buildSectionHeader(
                      Icons.image,
                      isRtl ? 'شعار المتجر والهوية البصرية' : 'Store Logo & Branding',
                      isDark,
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Preview box
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: pickedLogoBytes != null
                                  ? Image.memory(pickedLogoBytes!, fit: BoxFit.contain)
                                  : AppNetworkImage(
                                      imageUrl: existingLogoUrl,
                                      fit: BoxFit.contain,
                                      defaultFallbackIcon: Icons.storefront,
                                      fallbackIconSize: 24,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Upload button
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final file = await _picker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 1024,
                                      maxHeight: 1024,
                                      imageQuality: 85,
                                    );
                                    if (file != null) {
                                      final bytes = await file.readAsBytes();
                                      setModalState(() {
                                        pickedLogoFile = file;
                                        pickedLogoBytes = bytes;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                                  label: Text(
                                    pickedLogoFile != null || (existingLogoUrl != null && existingLogoUrl!.isNotEmpty)
                                        ? (isRtl ? 'تغيير الشعار' : 'Change Logo')
                                        : (isRtl ? 'رفع شعار المتجر' : 'Upload Logo'),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF16A34A),
                                    side: const BorderSide(color: Color(0xFF16A34A)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                if (pickedLogoFile != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    pickedLogoFile!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // SECTION 2: Store Identity
                    _buildSectionHeader(
                      Icons.badge,
                      isRtl ? 'بيانات المتجر الأساسية' : 'Store Identity',
                      isDark,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: nameEnCtrl,
                            label: isRtl ? 'اسم المتجر (الإنجليزية) *' : 'Store Name (EN) *',
                            hint: 'e.g. Panda Supermarket',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: nameArCtrl,
                            label: isRtl ? 'اسم المتجر (العربية) *' : 'Store Name (AR) *',
                            hint: 'مثال: أسواق بنده',
                            isDark: isDark,
                            isRtl: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Headquarters City & Primary Category Dropdowns
                    Builder(
                      builder: (context) {
                        final uniqueCities = <int, City>{};
                        for (final c in cities) {
                          uniqueCities[c.id] = c;
                        }
                        final safeCities = uniqueCities.values.toList();
                        final validCity = safeCities.any((c) => c.id == selectedCityId)
                            ? selectedCityId
                            : (safeCities.isNotEmpty ? safeCities.first.id : null);

                        final uniqueCategories = <int, Category>{};
                        for (final cat in categories) {
                          uniqueCategories[cat.id] = cat;
                        }
                        final safeCategories = uniqueCategories.values.toList();
                        final validCat = safeCategories.any((cat) => cat.id == selectedCategoryId)
                            ? selectedCategoryId
                            : (safeCategories.isNotEmpty ? safeCategories.first.id : null);

                        return Row(
                          children: [
                            // City Selector
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isRtl ? 'المدينة الرئيسية *' : 'Headquarters City *',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: validCity,
                                        isExpanded: true,
                                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        items: safeCities
                                            .map((c) => DropdownMenuItem<int>(
                                                  value: c.id,
                                                  child: Text(
                                                    isRtl ? c.nameAr : c.nameEn,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (val) => setModalState(() => selectedCityId = val),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Category Selector
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isRtl ? 'الفئة الرئيسية *' : 'Primary Category *',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int>(
                                        value: validCat,
                                        isExpanded: true,
                                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        items: safeCategories
                                            .map((cat) => DropdownMenuItem<int>(
                                                  value: cat.id,
                                                  child: Text(
                                                    isRtl ? cat.nameAr : cat.nameEn,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (val) => setModalState(() => selectedCategoryId = val),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // Descriptions
                    _buildTextField(
                      controller: descEnCtrl,
                      label: isRtl ? 'الوصف (الإنجليزية)' : 'Description (EN)',
                      hint: 'Brief description about the retailer...',
                      maxLines: 2,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: descArCtrl,
                      label: isRtl ? 'الوصف (العربية)' : 'Description (AR)',
                      hint: 'نبذة عن المتجر بالعربية...',
                      maxLines: 2,
                      isDark: isDark,
                      isRtl: true,
                    ),
                    const SizedBox(height: 14),

                    // SECTION 3: Legal & Tax Registration
                    _buildSectionHeader(
                      Icons.gavel,
                      isRtl ? 'السجل التجاري والضرائب' : 'Legal & Tax Registration',
                      isDark,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: crCtrl,
                            label: isRtl ? 'رقم السجل التجاري (CR)' : 'CR Number',
                            hint: '1010XXXXXX',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: vatCtrl,
                            label: isRtl ? 'الرقم الضريبي (VAT)' : 'VAT Number',
                            hint: '300XXXXXXXXXXXX',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // SECTION 4: Contact & Online Presence
                    _buildSectionHeader(
                      Icons.contact_support,
                      isRtl ? 'التواصل والموقع الإلكتروني' : 'Contact & Online Presence',
                      isDark,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: phoneCtrl,
                            label: isRtl ? 'رقم الهاتف' : 'Contact Phone',
                            hint: '+966 5X XXX XXXX',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTextField(
                            controller: emailCtrl,
                            label: isRtl ? 'البريد الإلكتروني' : 'Contact Email',
                            hint: 'support@merchant.com',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildTextField(
                      controller: webCtrl,
                      label: isRtl ? 'الموقع الرسمي' : 'Official Website',
                      hint: 'https://panda.com.sa',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),

                    // SECTION 5: Store Manager Login Account (Only on New Store Creation)
                    if (store == null) ...[
                      _buildSectionHeader(
                        Icons.manage_accounts,
                        isRtl ? 'حساب مدير المتجر لتسجيل الدخول' : 'Store Manager Login Account',
                        isDark,
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Switch.adaptive(
                                  value: createManagerAccount,
                                  activeColor: const Color(0xFF16A34A),
                                  onChanged: (val) => setModalState(() => createManagerAccount = val),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isRtl ? 'إنشاء حساب مدير متجر تلقائياً' : 'Auto-create Store Manager Account',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        isRtl
                                            ? 'تفعيل حساب بصلاحية STORE_MANAGER لإدارة المتجر'
                                            : 'Provisions a STORE_MANAGER login for the merchant',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (createManagerAccount) ...[
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: mgrNameCtrl,
                                label: isRtl ? 'اسم المدير' : 'Manager Name',
                                hint: 'e.g. Ahmad Al-Harbi',
                                isDark: isDark,
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: mgrEmailCtrl,
                                label: isRtl ? 'البريد الإلكتروني للدخول' : 'Manager Login Email',
                                hint: 'manager@merchant.com',
                                isDark: isDark,
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: mgrPassCtrl,
                                label: isRtl ? 'كلمة المرور الأولية' : 'Initial Password',
                                hint: 'Partner@123',
                                isDark: isDark,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // SECTION 6: Status & Flags
                    _buildSectionHeader(
                      Icons.toggle_on,
                      isRtl ? 'الحالة والشارات' : 'Status & Badges',
                      isDark,
                    ),
                    const SizedBox(height: 8),

                    _buildToggleCard(
                      title: isRtl ? 'شريك معتمد' : 'Verified Partner',
                      subtitle: isRtl
                          ? 'إظهار شارة التوثيق الزرقاء في كافة قوائم المتجر'
                          : 'Display official verification checkmark across all store listings',
                      value: isVerified,
                      icon: Icons.verified,
                      iconColor: const Color(0xFF2563EB),
                      onChanged: (val) => setModalState(() => isVerified = val),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),

                    _buildToggleCard(
                      title: isRtl ? 'متجر مميز' : 'Featured Store',
                      subtitle: isRtl
                          ? 'إبراز هذا المتجر في الواجهة الرئيسية وأقسام المتاجر المميزة'
                          : 'Highlight this store in featured showcases and top promotional placements',
                      value: isFeatured,
                      icon: Icons.star,
                      iconColor: const Color(0xFFD97706),
                      onChanged: (val) => setModalState(() => isFeatured = val),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),

                    _buildToggleCard(
                      title: isRtl ? 'متجر نشط' : 'Active Store',
                      subtitle: isRtl
                          ? 'السماح للعملاء باستكشاف العروض والمنشورات والفروع التابعة لهذا المتجر'
                          : 'Allow users to discover offers, flyers, and branches from this store',
                      value: isActive,
                      icon: Icons.power_settings_new,
                      iconColor: const Color(0xFF16A34A),
                      onChanged: (val) => setModalState(() => isActive = val),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: Text(
                  isRtl ? 'إلغاء' : 'Cancel',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (nameEnCtrl.text.trim().isEmpty || nameArCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isRtl ? 'يرجى إدخال اسم المتجر بالعربية والإنجليزية' : 'Please provide English and Arabic store names'),
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                          );
                          return;
                        }
                        if (selectedCityId == null || selectedCategoryId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isRtl ? 'يرجى اختيار المدينة والفئة' : 'Please select city and category'),
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                          );
                          return;
                        }

                        setModalState(() => isSubmitting = true);

                        bool success = false;
                        if (store == null) {
                          success = await ref.read(storeRepositoryProvider.notifier).createStore(
                                nameEn: nameEnCtrl.text.trim(),
                                nameAr: nameArCtrl.text.trim(),
                                cityId: selectedCityId!,
                                categoryId: selectedCategoryId!,
                                descriptionEn: descEnCtrl.text.trim().isEmpty ? null : descEnCtrl.text.trim(),
                                descriptionAr: descArCtrl.text.trim().isEmpty ? null : descArCtrl.text.trim(),
                                crNumber: crCtrl.text.trim().isEmpty ? null : crCtrl.text.trim(),
                                vatNumber: vatCtrl.text.trim().isEmpty ? null : vatCtrl.text.trim(),
                                contactPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                contactEmail: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                                website: webCtrl.text.trim().isEmpty ? null : webCtrl.text.trim(),
                                isVerified: isVerified,
                                isFeatured: isFeatured,
                                isActive: isActive,
                                createManagerAccount: createManagerAccount,
                                managerName: mgrNameCtrl.text.trim().isEmpty ? null : mgrNameCtrl.text.trim(),
                                managerEmail: mgrEmailCtrl.text.trim().isEmpty ? null : mgrEmailCtrl.text.trim(),
                                managerPassword: mgrPassCtrl.text.trim().isEmpty ? null : mgrPassCtrl.text.trim(),
                                logoFile: pickedLogoFile,
                              );
                        } else {
                          success = await ref.read(storeRepositoryProvider.notifier).updateStore(
                                id: store.id,
                                nameEn: nameEnCtrl.text.trim(),
                                nameAr: nameArCtrl.text.trim(),
                                cityId: selectedCityId!,
                                categoryId: selectedCategoryId!,
                                descriptionEn: descEnCtrl.text.trim().isEmpty ? null : descEnCtrl.text.trim(),
                                descriptionAr: descArCtrl.text.trim().isEmpty ? null : descArCtrl.text.trim(),
                                crNumber: crCtrl.text.trim().isEmpty ? null : crCtrl.text.trim(),
                                vatNumber: vatCtrl.text.trim().isEmpty ? null : vatCtrl.text.trim(),
                                contactPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                contactEmail: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                                website: webCtrl.text.trim().isEmpty ? null : webCtrl.text.trim(),
                                isVerified: isVerified,
                                isFeatured: isFeatured,
                                isActive: isActive,
                                logoFile: pickedLogoFile,
                              );
                        }

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? (store == null
                                        ? (isRtl ? 'تم إنشاء المتجر بنجاح!' : 'Store Created Successfully!')
                                        : (isRtl ? 'تم تحديث بيانات المتجر بنجاح!' : 'Store Updated Successfully!'))
                                    : (isRtl ? 'فشل حفظ المتجر' : 'Failed to save store'),
                              ),
                              backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        store == null
                            ? (isRtl ? 'تسجيل المتجر' : 'Register Store')
                            : (isRtl ? 'حفظ التعديلات' : 'Save Changes'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF16A34A)),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    bool isRtl = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: const Color(0xFF16A34A),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // 8. Delete Confirmation Dialog
  void _showDeleteStoreDialog(BuildContext context, Store store, bool isRtl, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              isRtl ? 'حذف المتجر؟' : 'Delete Store?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          isRtl
              ? 'هل أنت متأكد من حذف متجر "${store.nameAr}"؟ سيتم حذف جميع الفروع والعروض والمنشورات المرتبطة به.'
              : 'Are you sure you want to delete "${store.nameEn}"? All associated branches, offers, and flyers will be removed.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              isRtl ? 'إلغاء' : 'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await ref.read(storeRepositoryProvider.notifier).deleteStore(store.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (isRtl ? 'تم حذف المتجر بنجاح' : 'Store deleted successfully.')
                          : (isRtl ? 'فشل حذف المتجر' : 'Failed to delete store.'),
                    ),
                    backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isRtl ? 'نعم، حذف' : 'Yes, Delete',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
