import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' hide Category;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/product_repository.dart';
import '../../../../core/services/category_repository.dart';
import '../../../../core/services/brand_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../models/models.dart';
import '../../../../models/brand.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../widgets/crud_loading_widget.dart';

class ProductsCrudScreen extends ConsumerStatefulWidget {
  const ProductsCrudScreen({super.key});

  @override
  ConsumerState<ProductsCrudScreen> createState() => _ProductsCrudScreenState();
}

class _ProductsCrudScreenState extends ConsumerState<ProductsCrudScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  static const int _pageSize = 20;

  // Pagination & Lazy Loading State
  List<Product> _products = [];
  int _totalElements = 0;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _displayedCount = 20;

  String _searchQuery = '';
  int? _selectedCategoryFilter;
  int? _selectedBrandFilter;
  bool _showSuggestions = false;
  List<Product> _suggestions = [];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryRepositoryProvider.notifier).fetchCategories();
      ref.read(brandRepositoryProvider.notifier).fetchBrands();
      _loadInitialProducts();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 350) {
      _loadNextPage();
    }
  }

  Future<void> _loadInitialProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });

    final res = await ref.read(productRepositoryProvider.notifier).getPagedProducts(
      page: 0,
      size: _pageSize,
      search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      categoryId: _selectedCategoryFilter,
      brandId: _selectedBrandFilter,
      sortBy: 'createdAt',
      direction: 'desc',
    );

    if (mounted) {
      setState(() {
        _products = res.content;
        _totalElements = res.totalElements;
        _totalPages = res.totalPages;
        _hasMore = (0 + 1) < res.totalPages;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;

    final nextPage = _currentPage + 1;
    setState(() => _isLoadingMore = true);

    final res = await ref.read(productRepositoryProvider.notifier).getPagedProducts(
      page: nextPage,
      size: _pageSize,
      search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      categoryId: _selectedCategoryFilter,
      brandId: _selectedBrandFilter,
      sortBy: 'createdAt',
      direction: 'desc',
    );

    if (mounted) {
      setState(() {
        _products = [..._products, ...res.content];
        _currentPage = res.number;
        _totalElements = res.totalElements;
        _totalPages = res.totalPages;
        _hasMore = (res.number + 1) < res.totalPages;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _showSuggestions = query.trim().isNotEmpty;
        });
        _fetchSuggestions(query);
        _loadInitialProducts();
      }
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final res = await ref.read(productRepositoryProvider.notifier).getPagedProducts(
      page: 0,
      size: 6,
      search: query.trim(),
      sortBy: 'nameEn',
      direction: 'asc',
    );
    if (mounted) {
      setState(() => _suggestions = res.content);
    }
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategoryFilter = null;
      _selectedBrandFilter = null;
      _showSuggestions = false;
      _suggestions = [];
    });
    _loadInitialProducts();
  }

  // 10 Standard Unit Options matching Angular Products CRUD
  static const List<Map<String, String>> unitOptions = [
    {'id': 'EACH', 'nameEn': 'Pieces (pcs / each)', 'nameAr': 'حبة / قطعة'},
    {'id': 'KG', 'nameEn': 'Kilograms (kg)', 'nameAr': 'كيلوجرام (كجم)'},
    {'id': 'GRAM', 'nameEn': 'Grams (g)', 'nameAr': 'جرام (جم)'},
    {'id': 'LITRE', 'nameEn': 'Liters (L)', 'nameAr': 'لتر'},
    {'id': 'ML', 'nameEn': 'Milliliters (ml)', 'nameAr': 'مليلتر'},
    {'id': 'PACK', 'nameEn': 'Pack', 'nameAr': 'عبوة / باقة'},
    {'id': 'BOX', 'nameEn': 'Box', 'nameAr': 'صندوق / كرتون'},
    {'id': 'PAIR', 'nameEn': 'Pair', 'nameAr': 'زوج'},
    {'id': 'SET', 'nameEn': 'Set', 'nameAr': 'طقم / مجموعة'},
    {'id': 'BUNCH', 'nameEn': 'Bunch', 'nameAr': 'عنقود'},
  ];

  List<Product> _getFilteredProducts(List<Product> allProducts) {
    final query = _searchQuery.toLowerCase().trim();
    var list = allProducts;

    if (query.isNotEmpty) {
      list = list.where((p) {
        final nameEn = p.nameEn.toLowerCase();
        final nameAr = p.nameAr.toLowerCase();
        final sku = p.sku.toLowerCase();
        final barcode = p.barcode.toLowerCase();
        final brand = p.brand.toLowerCase();
        final brandAr = p.brandAr.toLowerCase();
        final idStr = p.id.toString();
        return nameEn.contains(query) ||
            nameAr.contains(query) ||
            sku.contains(query) ||
            barcode.contains(query) ||
            brand.contains(query) ||
            brandAr.contains(query) ||
            idStr.contains(query);
      }).toList();
    }

    if (_selectedCategoryFilter != null) {
      list = list.where((p) => p.categoryId == _selectedCategoryFilter).toList();
    }

    if (_selectedBrandFilter != null) {
      list = list.where((p) {
        if (p.brandId != null) return p.brandId == _selectedBrandFilter;
        return false;
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.watch(categoryRepositoryProvider);
    final brandState = ref.watch(brandRepositoryProvider);
    final brands = brandState.brands;

    // Use loaded paged products directly for optimal performance and zero lag
    final effectiveProducts = _products;
    final totalCount = _totalElements;
    final activeCount = effectiveProducts.where((p) => p.isActive == 1).length;
    final suggestions = _suggestions;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () async {
            await Future.wait([
              _loadInitialProducts(),
              ref.read(productRepositoryProvider.notifier).fetchProducts(),
              ref.read(categoryRepositoryProvider.notifier).fetchCategories(),
              ref.read(brandRepositoryProvider.notifier).fetchBrands(),
            ]);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Block matching Angular .crud-header
                _buildHeaderBlock(context, isRtl, isDark, categories, brands),
                const SizedBox(height: 14),

                // 2. Stats Grid matching Angular
                _buildStatsGrid(
                  totalCount: totalCount,
                  activeCount: activeCount,
                  isRtl: isRtl,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // 3. Search & Filter Toolbar matching Angular .filter-card
                _buildFilterToolbar(
                  filteredCount: effectiveProducts.length,
                  totalCount: totalCount,
                  categories: categories,
                  brands: brands,
                  suggestions: suggestions,
                  isRtl: isRtl,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // 4. Products List matching Angular .products-list-view
                if (_isLoading && effectiveProducts.isEmpty) ...[
                  _buildLoadingState(isRtl, isDark),
                ] else if (effectiveProducts.isEmpty) ...[
                  _buildEmptyState(isRtl, isDark),
                ] else ...[
                  _buildProductsList(
                    products: effectiveProducts,
                    totalFilteredCount: totalCount,
                    hasMore: _hasMore,
                    isLoadingMore: _isLoadingMore,
                    onLoadMore: () {
                      if (_products.isNotEmpty) {
                        _loadNextPage();
                      } else {
                        setState(() => _displayedCount = (_displayedCount + _pageSize).clamp(0, totalCount));
                      }
                    },
                    categories: categories,
                    brands: brands,
                    isRtl: isRtl,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Header Block
  Widget _buildHeaderBlock(
    BuildContext context,
    bool isRtl,
    bool isDark,
    List<Category> categories,
    List<Brand> brands,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          final titleInfo = Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: Color(0xFF16A34A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRtl ? 'دليل المنتجات' : 'Product Catalogue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isRtl
                          ? 'إدارة المنتجات الرئيسية، الباركودات، المواصفات والأقسام'
                          : 'Manage master products, barcodes, specs and categories',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final addBtn = ElevatedButton.icon(
            onPressed: () => _showAddEditProductModal(context, isRtl, isDark, categories, brands),
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              isRtl ? 'إضافة منتج' : 'Add Product',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleInfo,
                const SizedBox(height: 12),
                addBtn,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleInfo),
              const SizedBox(width: 16),
              addBtn,
            ],
          );
        },
      ),
    );
  }

  // 2. Stats Grid
  Widget _buildStatsGrid({
    required int totalCount,
    required int activeCount,
    required bool isRtl,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_2_outlined,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            count: totalCount,
            labelEn: 'Total Products',
            labelAr: 'إجمالي المنتجات',
            isRtl: isRtl,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_outline,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
            count: activeCount,
            labelEn: 'Active Products',
            labelAr: 'المنتجات النشطة',
            isRtl: isRtl,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required int count,
    required String labelEn,
    required String labelAr,
    required bool isRtl,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  isRtl ? labelAr : labelEn,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Search & Filter Toolbar with Responsive Layout (Prevents Overflow)
  Widget _buildFilterToolbar({
    required int filteredCount,
    required int totalCount,
    required List<Category> categories,
    required List<Brand> brands,
    required List<Product> suggestions,
    required bool isRtl,
    required bool isDark,
  }) {
    final safeCategories = categories.where((c) => c.id != 0).toList();
    final validCat = safeCategories.any((c) => c.id == _selectedCategoryFilter) ? _selectedCategoryFilter : null;
    final hasActiveFilter = _searchQuery.isNotEmpty || _selectedCategoryFilter != null || _selectedBrandFilter != null;

    final searchField = SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        onTap: () {
          if (_searchQuery.trim().isNotEmpty) {
            setState(() => _showSuggestions = true);
          }
        },
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: isRtl
              ? 'ابحث بالاسم، الماركة، SKU، الباركود أو الرقم...'
              : 'Search by name, brand, SKU, barcode, ID...',
          hintStyle: TextStyle(
            fontSize: 11.5,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 17,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 15),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFF16A34A), width: 1.5),
          ),
        ),
      ),
    );

    final suggestionsWidget = (_showSuggestions && suggestions.isNotEmpty)
        ? Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 14, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        isRtl ? 'المنتجات المقترحة' : 'Suggested Products',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${suggestions.length})',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => setState(() => _showSuggestions = false),
                        child: const Icon(Icons.close, size: 14, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),
                ...suggestions.map((p) {
                  final imgUrl = AppConfig.normalizeImageUrl(p.primaryImageUrl);
                  return InkWell(
                    onTap: () {
                      _searchController.text = isRtl ? (p.nameAr.isNotEmpty ? p.nameAr : p.nameEn) : p.nameEn;
                      _onSearchChanged(_searchController.text);
                      setState(() => _showSuggestions = false);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 32,
                              height: 32,
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              child: AppNetworkImage(
                                imageUrl: imgUrl,
                                fit: BoxFit.contain,
                                defaultFallbackIcon: Icons.inventory_2,
                                fallbackIconSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRtl ? (p.nameAr.isNotEmpty ? p.nameAr : p.nameEn) : p.nameEn,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (p.brand.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          isRtl ? (p.brandAr.isNotEmpty ? p.brandAr : p.brand) : p.brand,
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    if (p.sku.isNotEmpty) ...[
                                      Text(
                                        'SKU: ${p.sku}',
                                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      'ID: #${p.id}',
                                      style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new, size: 14, color: Color(0xFF16A34A)),
                            onPressed: () {
                              setState(() => _showSuggestions = false);
                              context.push('/admin/products/${p.id}/details');
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          )
        : const SizedBox.shrink();

    // Dropdown for Category
    final categoryDropdown = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: validCat,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: const Icon(Icons.category_outlined, size: 14, color: Color(0xFF16A34A)),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                isRtl ? 'جميع الأقسام' : 'All Categories',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            ...safeCategories.map((Category cat) {
              final parent = cat.parentId != null ? safeCategories.where((c) => c.id == cat.parentId).firstOrNull : null;
              final label = parent != null
                  ? (isRtl ? '${parent.nameAr} › ${cat.nameAr}' : '${parent.nameEn} › ${cat.nameEn}')
                  : (isRtl ? cat.nameAr : cat.nameEn);
              return DropdownMenuItem<int?>(
                value: cat.id,
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              );
            }),
          ],
          onChanged: (val) {
            setState(() => _selectedCategoryFilter = val);
            _loadInitialProducts();
          },
        ),
      ),
    );

    // Dropdown for Brand
    final brandDropdown = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedBrandFilter,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: const Icon(Icons.storefront, size: 14, color: Color(0xFF16A34A)),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                isRtl ? 'جميع الماركات' : 'All Brands',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            ...brands.map((Brand b) => DropdownMenuItem<int?>(
                  value: b.id,
                  child: Text(
                    isRtl ? (b.nameAr.isNotEmpty ? b.nameAr : b.nameEn) : b.nameEn,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                )),
          ],
          onChanged: (val) {
            setState(() => _selectedBrandFilter = val);
            _loadInitialProducts();
          },
        ),
      ),
    );

    // Stats Pill
    final statsPill = Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2, size: 13, color: Color(0xFF16A34A)),
          const SizedBox(width: 4),
          Text(
            '$filteredCount / $totalCount',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );

    // Clear Button
    final clearButton = InkWell(
      onTap: _clearAllFilters,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt_off, size: 13, color: Color(0xFFDC2626)),
            const SizedBox(width: 4),
            Text(
              isRtl ? 'إلغاء' : 'Clear',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                suggestionsWidget,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: categoryDropdown),
                    const SizedBox(width: 8),
                    Expanded(child: brandDropdown),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    statsPill,
                    if (hasActiveFilter) clearButton,
                  ],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              suggestionsWidget,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(flex: 3, child: categoryDropdown),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: brandDropdown),
                  const SizedBox(width: 8),
                  statsPill,
                  if (hasActiveFilter) ...[
                    const SizedBox(width: 8),
                    clearButton,
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // 4. Loading State
  Widget _buildLoadingState(bool isRtl, bool isDark) {
    return CrudLoadingWidget(
      isRtl: isRtl,
      isDark: isDark,
      titleEn: 'Loading Product Catalog...',
      titleAr: 'جاري تحميل دليل المنتجات...',
      subtitleEn: 'Fetching items, categories, barcodes and specifications...',
      subtitleAr: 'جاري جلب المنتجات، الأقسام، الباركودات والمواصفات...',
    );
  }

  // 5. Empty State
  Widget _buildEmptyState(bool isRtl, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inventory_2_outlined, size: 28, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Text(
            isRtl ? 'لا توجد منتجات مطابقة' : 'No Products Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isRtl
                ? 'لا توجد منتجات تطابق معايير البحث أو الفلترة الحالية.'
                : 'No products match your search or filters.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _clearAllFilters,
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(isRtl ? 'إعادة ضبط الفلاتر' : 'Reset Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Products List matching Angular .products-list-view & .product-list-item
  Widget _buildProductsList({
    required List<Product> products,
    required int totalFilteredCount,
    required bool hasMore,
    required bool isLoadingMore,
    required VoidCallback onLoadMore,
    required List<Category> categories,
    required List<Brand> brands,
    required bool isRtl,
    required bool isDark,
  }) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final p = products[index];
            final imgUrl = AppConfig.normalizeImageUrl(p.primaryImageUrl);

            // Category hierarchy resolution
            final cat = p.category ?? categories.where((c) => c.id == p.categoryId).firstOrNull;
            String catDisplay = '';
            if (cat != null) {
              if (cat.parentId != null) {
                final parent = categories.where((c) => c.id == cat.parentId).firstOrNull;
                final parentName = isRtl ? (parent?.nameAr ?? parent?.nameEn ?? '') : (parent?.nameEn ?? parent?.nameAr ?? '');
                final subName = isRtl ? cat.nameAr : cat.nameEn;
                catDisplay = '$parentName › $subName';
              } else {
                catDisplay = isRtl ? cat.nameAr : cat.nameEn;
              }
            }

            final brandName = isRtl ? (p.brandAr.isNotEmpty ? p.brandAr : p.brand) : p.brand;
            final isInactive = p.isActive == 0;

            return Opacity(
              opacity: isInactive ? 0.75 : 1.0,
              child: Material(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Clickable Item Row (navigates to details)
                      InkWell(
                        onTap: () => context.push('/admin/products/${p.id}/details'),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Product Image Avatar Box
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: AppNetworkImage(
                                  imageUrl: imgUrl,
                                  fit: BoxFit.contain,
                                  defaultFallbackIcon: Icons.inventory_2,
                                  fallbackIconSize: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Title, Localized Name, and ID
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          isRtl ? (p.nameAr.isNotEmpty ? p.nameAr : p.nameEn) : p.nameEn,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'ID: #${p.id}',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    isRtl ? (p.nameEn) : (p.nameAr.isNotEmpty ? p.nameAr : ''),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Status Pill (Active / Inactive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isInactive
                                    ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))
                                    : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isInactive
                                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                                      : const Color(0xFF16A34A).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isInactive ? const Color(0xFF94A3B8) : const Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isInactive ? (isRtl ? 'غير نشط' : 'Inactive') : (isRtl ? 'نشط' : 'Active'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isInactive
                                          ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                                          : const Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Meta Chips & Actions Row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 500;

                          final tags = Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Brand Badge
                              if (brandName.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.storefront, size: 10.5, color: Color(0xFF92400E)),
                                      const SizedBox(width: 3),
                                      Text(
                                        brandName,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Category Hierarchy Badge
                              if (catDisplay.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        size: 10.5,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        catDisplay,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // SKU Tag
                              if (p.sku.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    'SKU: ${p.sku}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),

                              // UPC / Barcode Tag
                              if (p.barcode.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    'UPC: ${p.barcode}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),

                              // Unit Size
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  '${p.unitSize} ${p.unit}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          );

                          final actionButtons = Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. View Details Button
                              _buildActionButton(
                                icon: Icons.visibility_outlined,
                                iconColor: const Color(0xFF2563EB),
                                tooltip: isRtl ? 'عرض التفاصيل' : 'View Details',
                                onTap: () => context.push('/admin/products/${p.id}/details'),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 5),

                              // 2. Edit Product Button
                              _buildActionButton(
                                icon: Icons.edit_outlined,
                                iconColor: const Color(0xFF16A34A),
                                tooltip: isRtl ? 'تعديل المنتج' : 'Edit Product',
                                onTap: () => _showAddEditProductModal(context, isRtl, isDark, categories, brands, p),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 5),

                              // 3. Technical Specs Button
                              _buildActionButton(
                                icon: Icons.list_alt,
                                iconColor: const Color(0xFF8B5CF6),
                                tooltip: isRtl ? 'المواصفات الفنية' : 'Technical Specs',
                                onTap: () => context.push('/admin/product-specs/${p.id}/details'),
                                isDark: isDark,
                              ),
                              const SizedBox(width: 5),

                              // 4. Delete Product Button
                              _buildActionButton(
                                icon: Icons.delete_outline,
                                iconColor: const Color(0xFFDC2626),
                                tooltip: isRtl ? 'حذف المنتج' : 'Delete Product',
                                onTap: () => _showDeleteProductDialog(context, p, isRtl, isDark),
                                isDark: isDark,
                              ),
                            ],
                          );

                          if (isNarrow) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                tags,
                                const SizedBox(height: 8),
                                Align(alignment: Alignment.centerRight, child: actionButtons),
                              ],
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: tags),
                              const SizedBox(width: 8),
                              actionButtons,
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (hasMore) ...[
          if (isLoadingMore) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRtl ? 'جاري تحميل المزيد من المنتجات...' : 'Loading more products...',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            InkWell(
              onTap: onLoadMore,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.expand_more, size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text(
                      isRtl
                          ? 'عرض المزيد (${products.length} من $totalFilteredCount)'
                          : 'Load More (${products.length} of $totalFilteredCount)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ] else if (totalFilteredCount > _pageSize) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: Text(
              isRtl ? 'تم عرض جميع الـ $totalFilteredCount منتج' : 'Showing all $totalFilteredCount products',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: iconColor),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Add / Edit Product Modal matching 100% Angular Parity
  // ============================================================
  void _showAddEditProductModal(
    BuildContext context,
    bool isRtl,
    bool isDark,
    List<Category> allCategories,
    List<Brand> brands, [
    Product? product,
  ]) {
    final isEditing = product != null;

    final nameEnCtrl = TextEditingController(text: product?.nameEn ?? '');
    final nameArCtrl = TextEditingController(text: product?.nameAr ?? '');
    final skuCtrl = TextEditingController(text: product?.sku ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final unitSizeCtrl = TextEditingController(text: product != null ? '${product.unitSize}' : '1');
    final descEnCtrl = TextEditingController(text: product?.descriptionEn ?? '');
    final descArCtrl = TextEditingController(text: product?.descriptionAr ?? '');

    int? selectedBrandId = product?.brandId;
    if (selectedBrandId == null && product != null && product.brand.isNotEmpty) {
      final b = brands.where((b) => b.nameEn.toLowerCase() == product.brand.toLowerCase()).firstOrNull;
      if (b != null) selectedBrandId = b.id;
    }

    int? selectedMainCatId;
    int? selectedSubCatId;

    if (product != null) {
      final cat = allCategories.where((c) => c.id == product.categoryId).firstOrNull;
      if (cat != null) {
        if (cat.parentId != null) {
          selectedMainCatId = cat.parentId;
          selectedSubCatId = cat.id;
        } else {
          selectedMainCatId = cat.id;
          selectedSubCatId = null;
        }
      }
    }

    String selectedUnit = product?.unit ?? 'EACH';
    if (!unitOptions.any((u) => u['id'] == selectedUnit)) {
      selectedUnit = 'EACH';
    }

    bool isActive = product != null ? product.isActive == 1 : true;
    XFile? pickedImageFile;
    Uint8List? pickedImageBytes;
    String? existingImageUrl = product?.primaryImageUrl;

    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final mainCategories = allCategories.where((c) => c.parentId == null).toList();
          final availableSubcategories = selectedMainCatId != null
              ? allCategories.where((c) => c.parentId == selectedMainCatId).toList()
              : <Category>[];

          final selectedMainCatObj = allCategories.where((c) => c.id == selectedMainCatId).firstOrNull;
          final selectedSubCatObj = allCategories.where((c) => c.id == selectedSubCatId).firstOrNull;

          String assignedCategoryName = '';
          if (selectedMainCatObj != null) {
            final mainName = isRtl ? selectedMainCatObj.nameAr : selectedMainCatObj.nameEn;
            if (selectedSubCatObj != null) {
              final subName = isRtl ? selectedSubCatObj.nameAr : selectedSubCatObj.nameEn;
              assignedCategoryName = '$mainName ➔ $subName';
            } else {
              assignedCategoryName = mainName;
            }
          }

          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.inventory_2, color: Color(0xFF16A34A), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? (isRtl ? 'تعديل بيانات المنتج' : 'Edit Product')
                              : (isRtl ? 'إضافة منتج جديد' : 'Add New Product'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          isRtl
                              ? 'قم بتعبئة تفاصيل المنتج الرئيسي لإضافته إلى دليل العروض'
                              : 'Fill out master product details to populate deals catalog',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1: BRAND PARTNER
                      _buildSectionHeader(
                        icon: Icons.storefront,
                        title: isRtl ? 'الماركة / الشريك التجاري' : 'Brand Partner',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildFieldLabel(isRtl ? 'اختر الماركة التجارية *' : 'Select Brand Partner *', isDark),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                            value: selectedBrandId,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            hint: Text(
                              isRtl ? '-- اختر الماركة --' : '-- Choose Brand --',
                              style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                            ),
                            items: brands.map((b) {
                              final logo = AppConfig.normalizeImageUrl(b.logoUrl);
                              return DropdownMenuItem<int?>(
                                value: b.id,
                                child: Row(
                                  children: [
                                    if (logo.isNotEmpty) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          logo,
                                          width: 20,
                                          height: 20,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.storefront, size: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Text(
                                        isRtl ? (b.nameAr.isNotEmpty ? b.nameAr : b.nameEn) : b.nameEn,
                                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) => setDialogState(() => selectedBrandId = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SECTION 2: PRODUCT NAMES
                      _buildSectionHeader(
                        icon: Icons.title,
                        title: isRtl ? 'اسم المنتج' : 'Product Names',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(isRtl ? 'الاسم بالإنجليزية *' : 'Name (English) *', isDark),
                                const SizedBox(height: 4),
                                _buildTextField(
                                  nameEnCtrl,
                                  isRtl ? 'مثال: Fresh Milk 1L' : 'e.g. Fresh Milk 1L',
                                  isDark,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(isRtl ? 'الاسم بالعربية *' : 'Name (Arabic) *', isDark),
                                const SizedBox(height: 4),
                                _buildTextField(
                                  nameArCtrl,
                                  isRtl ? 'مثال: حليب طازج 1 لتر' : 'e.g. حليب طازج 1 لتر',
                                  isDark,
                                  isRtl: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // SECTION 3: CATEGORY HIERARCHY
                      _buildSectionHeader(
                        icon: Icons.category,
                        title: isRtl ? 'تصنيف القسم' : 'Category Classification',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(isRtl ? '1. القسم الرئيسي *' : '1. Main Category *', isDark),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int?>(
                                      value: selectedMainCatId,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      hint: Text(
                                        isRtl ? '-- اختر القسم الرئيسي --' : '-- Choose Main --',
                                        style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                      ),
                                      items: mainCategories.map((c) => DropdownMenuItem<int?>(
                                            value: c.id,
                                            child: Text(
                                              isRtl ? c.nameAr : c.nameEn,
                                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                            ),
                                          )).toList(),
                                      onChanged: (val) {
                                        setDialogState(() {
                                          selectedMainCatId = val;
                                          selectedSubCatId = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(isRtl ? '2. القسم الفرعي' : '2. Subcategory', isDark),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int?>(
                                      value: selectedSubCatId,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      hint: Text(
                                        availableSubcategories.isEmpty
                                            ? (isRtl ? '-- لا توجد أقسام فرعية --' : '-- No Subcategories --')
                                            : (isRtl ? '-- اختياري --' : '-- Optional Sub --'),
                                        style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                      ),
                                      items: availableSubcategories.map((c) => DropdownMenuItem<int?>(
                                            value: c.id,
                                            child: Text(
                                              isRtl ? c.nameAr : c.nameEn,
                                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                            ),
                                          )).toList(),
                                      onChanged: availableSubcategories.isEmpty
                                          ? null
                                          : (val) => setDialogState(() => selectedSubCatId = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (assignedCategoryName.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${isRtl ? "القسم المخصص: " : "Assigned: "}$assignedCategoryName',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // SECTION 4: CODES & MEASUREMENTS
                      _buildSectionHeader(
                        icon: Icons.qr_code,
                        title: isRtl ? 'الرموز ووحدات القياس' : 'Codes & Measurements',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(isRtl ? 'رمز المنتج (SKU)' : 'Product SKU', isDark),
                                const SizedBox(height: 4),
                                _buildTextField(
                                  skuCtrl,
                                  'e.g. MILK-1L',
                                  isDark,
                                  isMonospace: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(isRtl ? 'الباركود (UPC/EAN)' : 'Barcode (UPC/EAN)', isDark),
                                const SizedBox(height: 4),
                                _buildTextField(
                                  barcodeCtrl,
                                  '6281007010014',
                                  isDark,
                                  isMonospace: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(isRtl ? 'وحدة القياس *' : 'Measurement Unit *', isDark),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedUnit,
                                      isExpanded: true,
                                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      items: unitOptions.map((u) => DropdownMenuItem<String>(
                                            value: u['id'],
                                            child: Text(
                                              isRtl ? u['nameAr']! : u['nameEn']!,
                                              style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                            ),
                                          )).toList(),
                                      onChanged: (val) => setDialogState(() => selectedUnit = val ?? 'EACH'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel(isRtl ? 'حجم / سعة الوحدة *' : 'Unit Size / Capacity *', isDark),
                                const SizedBox(height: 4),
                                _buildTextField(
                                  unitSizeCtrl,
                                  '1',
                                  isDark,
                                  isNumber: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // SECTION 5: PRODUCT IMAGE
                      _buildSectionHeader(
                        icon: Icons.image_outlined,
                        title: isRtl ? 'صورة المنتج' : 'Product Photo',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildImageDropzone(
                        pickedBytes: pickedImageBytes,
                        existingUrl: existingImageUrl,
                        onPick: () async {
                          final picker = ImagePicker();
                          final file = await picker.pickImage(source: ImageSource.gallery);
                          if (file != null) {
                            final bytes = await file.readAsBytes();
                            setDialogState(() {
                              pickedImageFile = file;
                              pickedImageBytes = bytes;
                            });
                          }
                        },
                        onRemove: () {
                          setDialogState(() {
                            pickedImageFile = null;
                            pickedImageBytes = null;
                            existingImageUrl = null;
                          });
                        },
                        isRtl: isRtl,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // SECTION 6: DESCRIPTIONS
                      _buildSectionHeader(
                        icon: Icons.description_outlined,
                        title: isRtl ? 'الوصف والتفاصيل' : 'Descriptions',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildFieldLabel(isRtl ? 'الوصف بالإنجليزية' : 'Description (English)', isDark),
                      const SizedBox(height: 4),
                      _buildTextArea(
                        descEnCtrl,
                        isRtl ? 'أدخل وصف المنتج بالإنجليزية...' : 'Enter product description in English...',
                        isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildFieldLabel(isRtl ? 'الوصف بالعربية' : 'Description (Arabic)', isDark),
                      const SizedBox(height: 4),
                      _buildTextArea(
                        descArCtrl,
                        isRtl ? 'أدخل وصف المنتج بالعربية...' : 'Enter product description in Arabic...',
                        isDark,
                        isRtl: true,
                      ),
                      const SizedBox(height: 16),

                      // SECTION 7: ACTIVE TOGGLE CARD
                      _buildToggleCard(
                        title: isRtl ? 'تفعيل المنتج' : 'Active Product',
                        subtitle: isRtl ? 'إظهار المنتج في دليل العروض والمنتجات العامة' : 'Make product visible across public catalogues and deals',
                        isSelected: isActive,
                        onTap: () => setDialogState(() => isActive = !isActive),
                        isDark: isDark,
                        isRtl: isRtl,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: Text(isRtl ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save, size: 16),
                  label: Text(
                    isEditing
                        ? (isRtl ? 'حفظ التعديلات' : 'Save Changes')
                        : (isRtl ? 'إضافة المنتج' : 'Add Product'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final nameEn = nameEnCtrl.text.trim();
                          final nameAr = nameArCtrl.text.trim();
                          final finalCategoryId = selectedSubCatId ?? selectedMainCatId;

                          if (selectedBrandId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a brand partner.'), backgroundColor: Color(0xFFDC2626)),
                            );
                            return;
                          }
                          if (nameEn.isEmpty || nameAr.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('English and Arabic product names are required.'), backgroundColor: Color(0xFFDC2626)),
                            );
                            return;
                          }
                          if (finalCategoryId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a category.'), backgroundColor: Color(0xFFDC2626)),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          final selectedBrandObj = brands.where((b) => b.id == selectedBrandId).firstOrNull;

                          bool success = false;
                          if (isEditing) {
                            success = await ref.read(productRepositoryProvider.notifier).updateProduct(
                                  id: product.id,
                                  nameEn: nameEn,
                                  nameAr: nameAr,
                                  brandId: selectedBrandId,
                                  brand: selectedBrandObj?.nameEn ?? '',
                                  brandAr: selectedBrandObj?.nameAr ?? '',
                                  sku: skuCtrl.text.trim().isNotEmpty ? skuCtrl.text.trim() : null,
                                  barcode: barcodeCtrl.text.trim().isNotEmpty ? barcodeCtrl.text.trim() : null,
                                  primaryImage: existingImageUrl,
                                  unit: selectedUnit,
                                  size: double.tryParse(unitSizeCtrl.text.trim()) ?? 1.0,
                                  categoryId: finalCategoryId,
                                  isActive: isActive ? 1 : 0,
                                  descEn: descEnCtrl.text.trim().isNotEmpty ? descEnCtrl.text.trim() : null,
                                  descAr: descArCtrl.text.trim().isNotEmpty ? descArCtrl.text.trim() : null,
                                  imageFile: pickedImageFile,
                                );
                          } else {
                            success = await ref.read(productRepositoryProvider.notifier).createProduct(
                                  nameEn: nameEn,
                                  nameAr: nameAr,
                                  brandId: selectedBrandId!,
                                  brand: selectedBrandObj?.nameEn ?? '',
                                  brandAr: selectedBrandObj?.nameAr ?? '',
                                  sku: skuCtrl.text.trim().isNotEmpty ? skuCtrl.text.trim() : null,
                                  barcode: barcodeCtrl.text.trim().isNotEmpty ? barcodeCtrl.text.trim() : null,
                                  primaryImage: existingImageUrl,
                                  unit: selectedUnit,
                                  size: double.tryParse(unitSizeCtrl.text.trim()) ?? 1.0,
                                  categoryId: finalCategoryId,
                                  isActive: isActive ? 1 : 0,
                                  descEn: descEnCtrl.text.trim().isNotEmpty ? descEnCtrl.text.trim() : null,
                                  descAr: descArCtrl.text.trim().isNotEmpty ? descArCtrl.text.trim() : null,
                                  imageFile: pickedImageFile,
                                );
                          }

                          setDialogState(() => isSubmitting = false);

                          if (success && context.mounted) {
                            Navigator.pop(ctx);
                            _loadInitialProducts();
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF16A34A)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint,
    bool isDark, {
    bool isRtl = false,
    bool isMonospace = false,
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      style: TextStyle(
        fontSize: 12,
        fontFamily: isMonospace ? 'monospace' : null,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF16A34A), width: 1.5)),
      ),
    );
  }

  Widget _buildTextArea(TextEditingController ctrl, String hint, bool isDark, {bool isRtl = false}) {
    return TextField(
      controller: ctrl,
      maxLines: 3,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        contentPadding: const EdgeInsets.all(10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF16A34A), width: 1.5)),
      ),
    );
  }

  Widget _buildImageDropzone({
    Uint8List? pickedBytes,
    String? existingUrl,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    required bool isRtl,
    required bool isDark,
  }) {
    final normExisting = AppConfig.normalizeImageUrl(existingUrl);
    final hasImage = pickedBytes != null || normExisting.isNotEmpty;

    if (hasImage) {
      return Container(
        height: 110,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
              child: Container(
                width: 110,
                height: 110,
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                child: pickedBytes != null
                    ? Image.memory(pickedBytes, fit: BoxFit.contain)
                    : AppNetworkImage(imageUrl: normExisting, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'تم تحديد صورة المنتج' : 'Product image selected',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: onPick,
                        icon: const Icon(Icons.change_circle, size: 14),
                        label: Text(isRtl ? 'تغيير' : 'Change', style: const TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 28, color: Color(0xFF16A34A)),
            const SizedBox(height: 6),
            Text(
              isRtl ? 'انقر لاختيار صورة المنتج' : 'Click to select product image',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              isRtl ? 'يدعم PNG, JPG حتى 5MB' : 'Supports PNG, JPG up to 5MB',
              style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required bool isRtl,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4))
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF16A34A) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF16A34A) : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: isSelected ? const Color(0xFF16A34A) : const Color(0xFF94A3B8), width: 1.5),
              ),
              alignment: Alignment.center,
              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
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
                      color: isSelected ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D)) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteProductDialog(BuildContext context, Product product, bool isRtl, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isRtl ? 'حذف المنتج' : 'Delete Product',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Text(
          isRtl
              ? 'هل أنت متأكد من حذف المنتج "${product.nameAr.isNotEmpty ? product.nameAr : product.nameEn}"؟'
              : 'Are you sure you want to delete "${product.nameEn}"?',
          style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(productRepositoryProvider.notifier).deleteProduct(product.id);
              _loadInitialProducts();
            },
            child: Text(isRtl ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }
}
