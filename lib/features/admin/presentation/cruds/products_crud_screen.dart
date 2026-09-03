import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/product_repository.dart';
import '../../../../core/services/category_repository.dart';
import '../../../../core/services/brand_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../models/models.dart';
import '../widgets/crud_loading_widget.dart';

class ProductsCrudScreen extends ConsumerStatefulWidget {
  const ProductsCrudScreen({super.key});

  @override
  ConsumerState<ProductsCrudScreen> createState() => _ProductsCrudScreenState();
}

class _ProductsCrudScreenState extends ConsumerState<ProductsCrudScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  int? _selectedCategoryFilter;
  String _selectedBrandFilter = '';
  String _selectedStatusFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
        return nameEn.contains(query) ||
            nameAr.contains(query) ||
            sku.contains(query) ||
            barcode.contains(query) ||
            brand.contains(query);
      }).toList();
    }

    if (_selectedCategoryFilter != null) {
      list = list.where((p) => p.categoryId == _selectedCategoryFilter).toList();
    }

    if (_selectedBrandFilter.isNotEmpty) {
      list = list.where((p) => p.brand.toLowerCase() == _selectedBrandFilter.toLowerCase()).toList();
    }

    if (_selectedStatusFilter == 'active') {
      list = list.where((p) => p.isActive == 1).toList();
    } else if (_selectedStatusFilter == 'inactive') {
      list = list.where((p) => p.isActive == 0).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productState = ref.watch(productRepositoryProvider);
    final allProducts = ref.watch(productRepositoryProvider.notifier).getProducts();
    final categories = ref.watch(categoryRepositoryProvider);

    final filteredProducts = _getFilteredProducts(allProducts);

    final totalCount = allProducts.length;
    final activeCount = allProducts.where((p) => p.isActive == 1).length;

    // Unique Brands for Filter
    final uniqueBrands = allProducts.map((p) => p.brand).where((b) => b.isNotEmpty).toSet().toList();

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () async {
            await Future.wait([
              ref.read(productRepositoryProvider.notifier).fetchProducts(),
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
                // 1. Header Block
                _buildHeaderBlock(context, isRtl, isDark, categories),
                const SizedBox(height: 14),

                // 2. Stats Grid
                _buildStatsGrid(
                  totalCount: totalCount,
                  activeCount: activeCount,
                  isRtl: isRtl,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // 3. Search & Filter Toolbar
                _buildFilterToolbar(
                  filteredCount: filteredProducts.length,
                  categories: categories,
                  brands: uniqueBrands,
                  isRtl: isRtl,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // 4. Products List
                if (productState.isLoading && allProducts.isEmpty) ...[
                  _buildLoadingState(isRtl, isDark),
                ] else if (filteredProducts.isEmpty) ...[
                  _buildEmptyState(isRtl, isDark),
                ] else ...[
                  _buildProductsList(filteredProducts, categories, isRtl, isDark),
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
  ) {
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          final titleGroup = Row(
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
                  Icons.inventory_2,
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
                      isRtl ? 'دليل المنتجات والمواصفات' : 'Product Catalog Management',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isRtl
                          ? 'إدارة المنتجات، الأرقام التسلسلية، الفئات والباركود'
                          : 'Manage global products, SKUs, barcode mappings and categories',
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
            onPressed: () => _showAddEditProductModal(context, isRtl, isDark, categories),
            icon: const Icon(Icons.add_shopping_cart, size: 16),
            label: Text(
              isRtl ? 'إضافة منتج جديد' : 'Add Product',
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

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleGroup,
                const SizedBox(height: 10),
                addButton,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleGroup),
              const SizedBox(width: 12),
              addButton,
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
            icon: Icons.inventory_2,
            iconColor: const Color(0xFF2563EB),
            bgColor: const Color(0xFFDBEAFE),
            count: totalCount,
            label: isRtl ? 'إجمالي المنتجات' : 'Total Products',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF16A34A),
            bgColor: const Color(0xFFDCFCE7),
            count: activeCount,
            label: isRtl ? 'منتجات نشطة' : 'Active Products',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required int count,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
    );
  }

  // 3. Search and Filter Toolbar
  Widget _buildFilterToolbar({
    required int filteredCount,
    required List<Category> categories,
    required List<String> brands,
    required bool isRtl,
    required bool isDark,
  }) {
    final uniqueCategories = <int, Category>{};
    for (final c in categories) {
      uniqueCategories[c.id] = c;
    }
    final safeCategories = uniqueCategories.values.toList();
    final validCat = safeCategories.any((c) => c.id == _selectedCategoryFilter) ? _selectedCategoryFilter : null;

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
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: isRtl
                          ? 'ابحث باسم المنتج، الباركود، SKU، الماركة...'
                          : 'Search by product name, barcode, SKU, brand...',
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
                                setState(() => _searchQuery = '');
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
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                        borderSide: BorderSide(color: Color(0xFF16A34A), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

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
                    const Icon(Icons.inventory_2, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text(
                      '$filteredCount ${isRtl ? 'منتج' : 'items'}',
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

          Row(
            children: [
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
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: validCat,
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
                      onChanged: (val) => setState(() => _selectedCategoryFilter = val),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Status Filter
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
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      icon: const Icon(Icons.tune, size: 14, color: Color(0xFF16A34A)),
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text(
                            isRtl ? 'جميع الحالات' : 'All Statuses',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'active',
                          child: Text(
                            isRtl ? 'نشط فقط' : 'Active Only',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'inactive',
                          child: Text(
                            isRtl ? 'معطل فقط' : 'Inactive Only',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedStatusFilter = val ?? ''),
                    ),
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
      titleEn: 'Loading Product Catalog...',
      titleAr: 'جاري تحميل دليل المنتجات...',
      subtitleEn: 'Fetching items, categories, barcodes and specifications...',
      subtitleAr: 'جاري جلب المنتجات والفئات والباركود والمواصفات...',
      icon: Icons.inventory_2_rounded,
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
            child: const Icon(Icons.inventory_outlined, size: 24, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          Text(
            isRtl ? 'لم يتم العثور على أي منتجات' : 'No Products Found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isRtl
                ? 'قم بإضافة منتج جديد أو تعديل معايير البحث والتصفية.'
                : 'Add a new product or adjust search criteria.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Products List
  Widget _buildProductsList(
    List<Product> products,
    List<Category> categories,
    bool isRtl,
    bool isDark,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = products[index];
        final imgUrl = AppConfig.normalizeImageUrl(p.primaryImageUrl);
        final cat = p.category ?? categories.where((c) => c.id == p.categoryId).firstOrNull;
        final catName = isRtl ? (cat?.nameAr ?? cat?.nameEn ?? '') : (cat?.nameEn ?? cat?.nameAr ?? '');
        final brandName = isRtl ? (p.brandAr.isNotEmpty ? p.brandAr : p.brand) : p.brand;

        return Material(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: imgUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imgUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF16A34A)),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Icon(Icons.inventory_2, color: Color(0xFF94A3B8), size: 22),
                          )
                        : const Icon(Icons.inventory_2, color: Color(0xFF94A3B8), size: 22),
                  ),
                ),
                const SizedBox(width: 10),

                // Middle Info
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
                              '#${p.id}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),

                      // Metadata Tags Row
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          if (brandName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                brandName,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          if (catName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                catName,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          if (p.sku.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SKU: ${p.sku}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontFamily: 'monospace',
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          if (p.unitSize > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${p.unitSize} ${p.unit}',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right Group: Status Pill & Actions matching Angular .btn-item-action
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.isActive == 1
                            ? const Color(0xFFDCFCE7)
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: p.isActive == 1
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
                              color: p.isActive == 1 ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            p.isActive == 1 ? (isRtl ? 'نشط' : 'Active') : (isRtl ? 'معطل' : 'Inactive'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: p.isActive == 1 ? const Color(0xFF166534) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Action Buttons matching Angular
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // View Details Action
                        Tooltip(
                          message: isRtl ? 'عرض التفاصيل' : 'View Details',
                          child: Material(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(7),
                            child: InkWell(
                              onTap: () => context.go('/admin/products/${p.id}/details'),
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
                                  Icons.visibility_outlined,
                                  size: 15,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),

                        // Edit Action
                        Tooltip(
                          message: isRtl ? 'تعديل المنتج' : 'Edit Product',
                          child: Material(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(7),
                            child: InkWell(
                              onTap: () => _showAddEditProductModal(context, isRtl, isDark, categories, p),
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
                                  size: 15,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),

                        // Delete Action
                        Tooltip(
                          message: isRtl ? 'حذف المنتج' : 'Delete Product',
                          child: Material(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(7),
                            child: InkWell(
                              onTap: () => _showDeleteProductDialog(context, p, isRtl, isDark),
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
                                  size: 15,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add / Edit Product Modal
  void _showAddEditProductModal(
    BuildContext context,
    bool isRtl,
    bool isDark,
    List<Category> categories, [
    Product? product,
  ]) {
    final nameEnCtrl = TextEditingController(text: product?.nameEn ?? '');
    final nameArCtrl = TextEditingController(text: product?.nameAr ?? '');
    final brandEnCtrl = TextEditingController(text: product?.brand ?? '');
    final brandArCtrl = TextEditingController(text: product?.brandAr ?? '');
    final skuCtrl = TextEditingController(text: product?.sku ?? '');
    final barcodeCtrl = TextEditingController(text: product?.barcode ?? '');
    final imgCtrl = TextEditingController(text: product?.primaryImageUrl ?? '');
    final unitCtrl = TextEditingController(text: product?.unit ?? 'pcs');
    final sizeCtrl = TextEditingController(text: product?.unitSize.toString() ?? '1.0');
    final descEnCtrl = TextEditingController(text: product?.descriptionEn ?? '');
    final descArCtrl = TextEditingController(text: product?.descriptionAr ?? '');

    final uniqueCategories = <int, Category>{};
    for (final c in categories) {
      uniqueCategories[c.id] = c;
    }
    final safeCategories = uniqueCategories.values.toList();
    int? selectedCatId = product?.categoryId;
    if (selectedCatId == null || !safeCategories.any((c) => c.id == selectedCatId)) {
      selectedCatId = safeCategories.isNotEmpty ? safeCategories.first.id : null;
    }

    bool isActive = product == null ? true : product.isActive == 1;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2, color: Color(0xFF16A34A), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    product == null
                        ? (isRtl ? 'إضافة منتج جديد' : 'Add New Product')
                        : (isRtl ? 'تعديل بيانات المنتج' : 'Edit Product'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameEnCtrl,
                            decoration: InputDecoration(
                              labelText: isRtl ? 'اسم المنتج (EN) *' : 'Name (EN) *',
                              hintText: 'e.g. Fresh Milk 1L',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: nameArCtrl,
                            decoration: InputDecoration(
                              labelText: isRtl ? 'اسم المنتج (AR) *' : 'Name (AR) *',
                              hintText: 'حليب طازج 1 لتر',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: brandEnCtrl,
                            decoration: InputDecoration(
                              labelText: isRtl ? 'الماركة (EN)' : 'Brand (EN)',
                              hintText: 'Almarai',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: brandArCtrl,
                            decoration: InputDecoration(
                              labelText: isRtl ? 'الماركة (AR)' : 'Brand (AR)',
                              hintText: 'المراعي',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Category Dropdown
                    DropdownButtonFormField<int>(
                      value: selectedCatId,
                      decoration: InputDecoration(
                        labelText: isRtl ? 'الفئة *' : 'Category *',
                      ),
                      items: safeCategories
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(isRtl ? c.nameAr : c.nameEn),
                              ))
                          .toList(),
                      onChanged: (val) => setModalState(() => selectedCatId = val),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: skuCtrl,
                            decoration: InputDecoration(
                              labelText: 'SKU',
                              hintText: 'ALM-MILK-1L',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: barcodeCtrl,
                            decoration: InputDecoration(
                              labelText: isRtl ? 'الباركود' : 'Barcode',
                              hintText: '6281007010014',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: sizeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isRtl ? 'حجم الوحدة' : 'Unit Size',
                              hintText: '1.0',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: unitCtrl,
                            decoration: InputDecoration(
                              labelText: isRtl ? 'نوع الوحدة' : 'Unit Type',
                              hintText: 'pcs, L, kg',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: imgCtrl,
                      decoration: InputDecoration(
                        labelText: isRtl ? 'رابط الصورة' : 'Image URL',
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 10),

                    TextField(
                      controller: descEnCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: isRtl ? 'الوصف (EN)' : 'Description (EN)',
                      ),
                    ),
                    const SizedBox(height: 10),

                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        isRtl ? 'حالة المنتج (نشط)' : 'Product Status (Active)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      value: isActive,
                      activeColor: const Color(0xFF16A34A),
                      onChanged: (val) => setModalState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isRtl ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (nameEnCtrl.text.trim().isEmpty || selectedCatId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isRtl ? 'يرجى إدخال اسم المنتج والفئة' : 'Please fill product name and category')),
                    );
                    return;
                  }

                  final size = double.tryParse(sizeCtrl.text.trim()) ?? 1.0;

                  if (product == null) {
                    await ref.read(productRepositoryProvider.notifier).createProduct(
                          nameEnCtrl.text.trim(),
                          nameArCtrl.text.trim(),
                          brandEnCtrl.text.trim(),
                          brandArCtrl.text.trim(),
                          skuCtrl.text.trim(),
                          barcodeCtrl.text.trim(),
                          imgCtrl.text.trim(),
                          unitCtrl.text.trim(),
                          size,
                          selectedCatId!,
                          isActive ? 1 : 0,
                          descEnCtrl.text.trim().isEmpty ? null : descEnCtrl.text.trim(),
                          descArCtrl.text.trim().isEmpty ? null : descArCtrl.text.trim(),
                        );
                  } else {
                    await ref.read(productRepositoryProvider.notifier).updateProduct(
                          product.id,
                          nameEnCtrl.text.trim(),
                          nameArCtrl.text.trim(),
                          brandEnCtrl.text.trim(),
                          brandArCtrl.text.trim(),
                          skuCtrl.text.trim(),
                          barcodeCtrl.text.trim(),
                          imgCtrl.text.trim(),
                          unitCtrl.text.trim(),
                          size,
                          selectedCatId!,
                          isActive ? 1 : 0,
                          descEnCtrl.text.trim().isEmpty ? null : descEnCtrl.text.trim(),
                          descArCtrl.text.trim().isEmpty ? null : descArCtrl.text.trim(),
                        );
                  }
                  if (mounted) {
                    Navigator.pop(ctx);
                  }
                },
                child: Text(isRtl ? 'حفظ المنتج' : 'Save Product'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Delete Product Dialog
  void _showDeleteProductDialog(
    BuildContext context,
    Product product,
    bool isRtl,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isRtl ? 'حذف المنتج؟' : 'Delete Product?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isRtl
              ? 'هل أنت متأكد من رغبتك في حذف "${product.nameEn}"؟'
              : 'Are you sure you want to delete "${product.nameEn}"?',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(productRepositoryProvider.notifier).deleteProduct(product.id);
            },
            child: Text(isRtl ? 'تأكيد الحذف' : 'Delete'),
          ),
        ],
      ),
    );
  }
}
