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
import '../widgets/searchable_brand_selector.dart';

class AdminProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const AdminProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<AdminProductDetailScreen> createState() => _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends ConsumerState<AdminProductDetailScreen> {
  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isSaving = false;

  // Form Controllers
  late TextEditingController _nameEnCtrl;
  late TextEditingController _nameArCtrl;
  late TextEditingController _skuCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _unitSizeCtrl;
  late TextEditingController _descEnCtrl;
  late TextEditingController _descArCtrl;

  int? _selectedBrandId;
  int? _selectedMainCatId;
  int? _selectedSubCatId;
  String _selectedUnit = 'EACH';
  bool _isActive = true;

  XFile? _pickedImageFile;
  Uint8List? _pickedImageBytes;
  String? _existingImageUrl;

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

  @override
  void initState() {
    super.initState();
    _nameEnCtrl = TextEditingController();
    _nameArCtrl = TextEditingController();
    _skuCtrl = TextEditingController();
    _barcodeCtrl = TextEditingController();
    _unitSizeCtrl = TextEditingController(text: '1');
    _descEnCtrl = TextEditingController();
    _descArCtrl = TextEditingController();

    final initialProduct = ref.read(productRepositoryProvider.notifier).getProductById(widget.productId);
    _isLoading = initialProduct == null;
    _initFormData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final hasInitial = ref.read(productRepositoryProvider.notifier).getProductById(widget.productId) != null;
    if (!hasInitial && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      await Future.wait([
        ref.read(productRepositoryProvider.notifier).fetchProductById(widget.productId),
        ref.read(productRepositoryProvider.notifier).fetchProductDetails(widget.productId),
        ref.read(categoryRepositoryProvider.notifier).fetchCategories(),
        ref.read(brandRepositoryProvider.notifier).fetchBrands(),
      ]);
    } catch (_) {}

    if (mounted) {
      _initFormData();
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameEnCtrl.dispose();
    _nameArCtrl.dispose();
    _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    _unitSizeCtrl.dispose();
    _descEnCtrl.dispose();
    _descArCtrl.dispose();
    super.dispose();
  }

  void _initFormData() {
    final product = ref.read(productRepositoryProvider.notifier).getProductById(widget.productId);
    final categories = ref.read(categoryRepositoryProvider);
    final brands = ref.read(brandRepositoryProvider).brands;

    if (product != null) {
      _nameEnCtrl.text = product.nameEn;
      _nameArCtrl.text = product.nameAr;
      _skuCtrl.text = product.sku;
      _barcodeCtrl.text = product.barcode;
      _unitSizeCtrl.text = '${product.unitSize}';
      _descEnCtrl.text = product.descriptionEn ?? '';
      _descArCtrl.text = product.descriptionAr ?? '';
      _isActive = product.isActive == 1;
      final rawUnit = product.unit.toUpperCase().trim();
      if (rawUnit == 'L' || rawUnit == 'LITER' || rawUnit == 'LITERS' || rawUnit == 'LITRES') {
        _selectedUnit = 'LITRE';
      } else if (rawUnit == 'PIECE' || rawUnit == 'PIECES' || rawUnit == 'PCS') {
        _selectedUnit = 'EACH';
      } else if (rawUnit == 'G' || rawUnit == 'GRAMS') {
        _selectedUnit = 'GRAM';
      } else if (rawUnit == 'KG' || rawUnit == 'KGS' || rawUnit == 'KILOGRAMS') {
        _selectedUnit = 'KG';
      } else if (rawUnit == 'ML' || rawUnit == 'MILLILITERS') {
        _selectedUnit = 'ML';
      } else if (unitOptions.any((u) => u['id'] == rawUnit)) {
        _selectedUnit = rawUnit;
      } else {
        _selectedUnit = 'EACH';
      }
      _existingImageUrl = product.primaryImageUrl;

      _selectedBrandId = product.brandId;
      if (_selectedBrandId == null && product.brand.isNotEmpty) {
        final b = brands.where((b) => b.nameEn.toLowerCase() == product.brand.toLowerCase()).firstOrNull;
        if (b != null) _selectedBrandId = b.id;
      }

      final cat = categories.where((c) => c.id == product.categoryId).firstOrNull;
      if (cat != null) {
        if (cat.parentId != null) {
          _selectedMainCatId = cat.parentId;
          _selectedSubCatId = cat.id;
        } else {
          _selectedMainCatId = cat.id;
          _selectedSubCatId = null;
        }
      }
    }
  }

  String _getCategoryPath(Category? cat, List<Category> allCategories, bool isRtl) {
    if (cat == null) return '';
    if (cat.parentId != null) {
      final parent = allCategories.where((c) => c.id == cat.parentId).firstOrNull;
      final parentName = isRtl ? (parent?.nameAr ?? parent?.nameEn ?? '') : (parent?.nameEn ?? parent?.nameAr ?? '');
      final subName = isRtl ? cat.nameAr : cat.nameEn;
      return '$parentName › $subName';
    }
    return isRtl ? cat.nameAr : cat.nameEn;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final product = ref.watch(productRepositoryProvider.notifier).getProductById(widget.productId);
    final categories = ref.watch(categoryRepositoryProvider);
    final brands = ref.watch(brandRepositoryProvider).brands;

    if (_isLoading && product == null) {
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
          body: CrudLoadingWidget(
            isRtl: isRtl,
            isDark: isDark,
            titleEn: 'Loading Product Details...',
            titleAr: 'جاري تحميل تفاصيل المنتج...',
            subtitleEn: 'Fetching item specifications, images and attributes...',
            subtitleAr: 'جاري جلب المواصفات والخصائص والصور الخاصة بالمنتج...',
          ),
        ),
      );
    }

    if (product == null) {
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                Text(
                  isRtl ? 'المنتج غير موجود' : 'Product Not Found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => context.go('/admin/products'),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text(isRtl ? 'العودة للمنتجات' : 'Back to Products'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cat = product.category ?? categories.where((c) => c.id == product.categoryId).firstOrNull;
    final categoryPath = _getCategoryPath(cat, categories, isRtl);

    final brandObj = brands.where((b) => b.id == product.brandId || b.nameEn.toLowerCase() == product.brand.toLowerCase()).firstOrNull;
    final brandName = isRtl ? (brandObj?.nameAr ?? product.brandAr) : (brandObj?.nameEn ?? product.brand);

    final specs = product.details ?? [];

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Action Bar matching Angular .top-action-bar
              _buildTopActionBar(context, product, isRtl, isDark),
              const SizedBox(height: 12),

              // 2. Hero / Header Card matching Angular .hero-card
              _buildHeroCard(product, brandName, categoryPath, isRtl, isDark),
              const SizedBox(height: 14),

              if (_isEditMode) ...[
                // EDIT MODE FORM
                _buildEditForm(context, categories, brands, isRtl, isDark),
              ] else ...[
                // VIEW MODE
                // 3. General Information Card matching Angular .info-card
                _buildGeneralInfoCard(product, brandName, categoryPath, isRtl, isDark),
                const SizedBox(height: 14),

                // 4. Descriptions Card (EN & AR) matching Angular
                _buildDescriptionsCard(product, isRtl, isDark),
                const SizedBox(height: 14),

                // 5. Technical Specifications Card matching Angular
                _buildSpecsSummaryCard(context, product, specs, isRtl, isDark),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Action Bar
  Widget _buildTopActionBar(BuildContext context, Product product, bool isRtl, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final backBtn = OutlinedButton.icon(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/products');
            }
          },
          icon: const Icon(Icons.arrow_back, size: 16),
          label: Text(
            isRtl ? 'العودة للمنتجات' : 'Back to Products',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );

        final actionButtons = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Technical Specs Button
            ElevatedButton.icon(
              onPressed: () => context.push('/admin/product-specs/${product.id}/details'),
              icon: const Icon(Icons.list_alt, size: 15),
              label: Text(
                isRtl ? 'المواصفات الفنية' : 'Technical Specs',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 0,
              ),
            ),

            // Edit / Cancel Edit Button
            ElevatedButton.icon(
              onPressed: () {
                if (_isEditMode) {
                  setState(() {
                    _isEditMode = false;
                    _initFormData();
                  });
                } else {
                  setState(() => _isEditMode = true);
                }
              },
              icon: Icon(_isEditMode ? Icons.close : Icons.edit, size: 15),
              label: Text(
                _isEditMode ? (isRtl ? 'إلغاء التعديل' : 'Cancel Edit') : (isRtl ? 'تعديل البيانات' : 'Edit Product'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEditMode ? const Color(0xFF64748B) : const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 0,
              ),
            ),
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              backBtn,
              const SizedBox(height: 8),
              actionButtons,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            backBtn,
            actionButtons,
          ],
        );
      },
    );
  }

  // 2. Hero Card
  Widget _buildHeroCard(Product product, String brandName, String categoryPath, bool isRtl, bool isDark) {
    final imgUrl = AppConfig.normalizeImageUrl(product.primaryImageUrl);
    final isInactive = product.isActive == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Large Avatar Box
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              child: AppNetworkImage(
                imageUrl: imgUrl,
                fit: BoxFit.contain,
                defaultFallbackIcon: Icons.inventory_2,
                fallbackIconSize: 32,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Titles & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isRtl ? (product.nameAr.isNotEmpty ? product.nameAr : product.nameEn) : product.nameEn,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ID: #${product.id}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isRtl ? product.nameEn : (product.nameAr.isNotEmpty ? product.nameAr : ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),

                // Meta Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (brandName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          brandName,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                        ),
                      ),
                    if (categoryPath.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          categoryPath,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isInactive ? const Color(0xFFF1F5F9) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isInactive ? (isRtl ? 'غير نشط' : 'Inactive') : (isRtl ? 'نشط' : 'Active'),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isInactive ? const Color(0xFF64748B) : const Color(0xFF166534),
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
    );
  }

  // 3. General Information Card
  Widget _buildGeneralInfoCard(Product product, String brandName, String categoryPath, bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRtl ? 'المعلومات الأساسية' : 'General Product Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          _buildInfoRow(isRtl ? 'الماركة' : 'Brand', brandName.isNotEmpty ? brandName : '-', isDark),
          _buildInfoRow(isRtl ? 'القسم' : 'Category', categoryPath.isNotEmpty ? categoryPath : '-', isDark),
          _buildInfoRow(isRtl ? 'رمز المنتج (SKU)' : 'SKU', product.sku.isNotEmpty ? product.sku : '-', isDark, isMonospace: true),
          _buildInfoRow(isRtl ? 'الباركود (UPC/EAN)' : 'Barcode', product.barcode.isNotEmpty ? product.barcode : '-', isDark, isMonospace: true),
          _buildInfoRow(isRtl ? 'وحدة القياس' : 'Measurement Unit', '${product.unitSize} ${product.unit}', isDark),
          _buildInfoRow(
            isRtl ? 'حالة التفعيل' : 'Status',
            product.isActive == 1 ? (isRtl ? 'نشط (معروض)' : 'Active') : (isRtl ? 'غير نشط' : 'Inactive'),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: isMonospace ? 'monospace' : null,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Descriptions Card
  Widget _buildDescriptionsCard(Product product, bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 16, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRtl ? 'الوصف والتفاصيل' : 'Descriptions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Text(
            isRtl ? 'الوصف بالإنجليزية:' : 'English Description:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              (product.descriptionEn?.isNotEmpty ?? false) ? product.descriptionEn! : (isRtl ? 'لا يوجد وصف بالإنجليزية.' : 'No English description provided.'),
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            isRtl ? 'الوصف بالعربية:' : 'Arabic Description:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              (product.descriptionAr?.isNotEmpty ?? false) ? product.descriptionAr! : (isRtl ? 'لا يوجد وصف بالعربية.' : 'No Arabic description provided.'),
              textDirection: TextDirection.rtl,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Specs Summary Card
  Widget _buildSpecsSummaryCard(BuildContext context, Product product, List<ProductDetail> specs, bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.list_alt, size: 16, color: Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  Text(
                    isRtl ? 'المواصفات الفنية' : 'Technical Specifications',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${specs.length}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED)),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => context.push('/admin/product-specs/${product.id}/details'),
                icon: const Icon(Icons.settings, size: 14),
                label: Text(isRtl ? 'إدارة المواصفات' : 'Manage Specs'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 12),

          if (specs.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.tune, size: 28, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  Text(
                    isRtl ? 'لا توجد مواصفات فنية مسجلة لهذا المنتج' : 'No technical specifications recorded for this product',
                    style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/admin/product-specs/${product.id}/details'),
                    icon: const Icon(Icons.add, size: 14),
                    label: Text(isRtl ? 'إضافة مواصفات' : 'Add Specifications'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: specs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final s = specs[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${s.sortOrder}',
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          isRtl ? (s.attrKeyAr.isNotEmpty ? s.attrKeyAr : s.attrKeyEn) : s.attrKeyEn,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          isRtl ? (s.attrValueAr.isNotEmpty ? s.attrValueAr : s.attrValueEn) : s.attrValueEn,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // EDIT FORM MATCHING ANGULAR 100% EXACTLY
  Widget _buildEditForm(
    BuildContext context,
    List<Category> allCategories,
    List<Brand> brands,
    bool isRtl,
    bool isDark,
  ) {
    final liveCategories = ref.watch(categoryRepositoryProvider).isNotEmpty
        ? ref.watch(categoryRepositoryProvider)
        : allCategories;
    final liveBrands = ref.watch(brandRepositoryProvider).brands.isNotEmpty
        ? ref.watch(brandRepositoryProvider).brands
        : brands;

    final mainCategories = liveCategories.where((c) => c.parentId == null).toList();
    final availableSubcategories = _selectedMainCatId != null
        ? liveCategories.where((c) => c.parentId == _selectedMainCatId).toList()
        : <Category>[];

    final selectedMainCatObj = liveCategories.where((c) => c.id == _selectedMainCatId).firstOrNull;
    final selectedSubCatObj = liveCategories.where((c) => c.id == _selectedSubCatId).firstOrNull;

    String assignedCategoryPath = '';
    if (selectedMainCatObj != null) {
      final mainName = isRtl ? selectedMainCatObj.nameAr : selectedMainCatObj.nameEn;
      if (selectedSubCatObj != null) {
        final subName = isRtl ? selectedSubCatObj.nameAr : selectedSubCatObj.nameEn;
        assignedCategoryPath = '$mainName ➔ $subName';
      } else {
        assignedCategoryPath = mainName;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;
              final headerInfo = Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.edit_note, color: Color(0xFF16A34A), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRtl ? 'تعديل بيانات المنتج' : 'Edit Product Catalogue Entry',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          isRtl ? 'أدخل تفاصيل المنتج والقسم والمواصفات' : 'Fill in product details, category, and specs',
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

              final saveBtn = ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: _isSaving
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 15),
                label: Text(
                  _isSaving
                      ? (isRtl ? 'جاري الحفظ...' : 'Saving...')
                      : (isRtl ? 'حفظ التغييرات' : 'Save Changes'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: _isSaving ? null : () => _submitProductEdit(liveBrands),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerInfo,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: saveBtn),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: headerInfo),
                  const SizedBox(width: 10),
                  saveBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ==================== SECTION 1: BRAND ====================
          _buildSectionHeader(
            icon: Icons.storefront,
            title: isRtl ? 'الماركة' : 'Brand',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildFieldLabel(isRtl ? 'الماركة التجارية *' : 'Brand Partner *', isDark),
          const SizedBox(height: 4),
          SearchableBrandSelector(
            selectedBrandId: _selectedBrandId,
            brands: liveBrands,
            onChanged: (val) => setState(() => _selectedBrandId = val),
            isRtl: isRtl,
            isDark: isDark,
            placeholder: isRtl ? '-- اختر الماركة --' : '-- Select Brand --',
            isRequired: true,
          ),
          const SizedBox(height: 16),

          // ==================== SECTION 2: PRODUCT NAMES ====================
          _buildSectionHeader(
            icon: Icons.badge_outlined,
            title: isRtl ? 'الاسم والتعريف' : 'Names & Identification',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              final enField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(isRtl ? 'الاسم بالإنجليزية *' : 'Name (English) *', isDark),
                  const SizedBox(height: 4),
                  _buildTextField(_nameEnCtrl, 'e.g. Almarai Fresh Milk 2L', isDark),
                ],
              );

              final arField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(isRtl ? 'الاسم بالعربية *' : 'Name (Arabic) *', isDark),
                  const SizedBox(height: 4),
                  _buildTextField(_nameArCtrl, 'مثال: حليب المراعي طازج 2 لتر', isDark, isRtl: true),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    enField,
                    const SizedBox(height: 10),
                    arField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: enField),
                  const SizedBox(width: 10),
                  Expanded(child: arField),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // ==================== SECTION 3: CATEGORY HIERARCHY ====================
          _buildSectionHeader(
            icon: Icons.account_tree_outlined,
            title: isRtl ? 'القسم' : 'Category',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              final step1Widget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStepBadge('1'),
                      const SizedBox(width: 6),
                      _buildFieldLabel(isRtl ? 'القسم الرئيسي *' : 'Main Category *', isDark),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 42,
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
                        value: (_selectedMainCatId != null && mainCategories.any((c) => c.id == _selectedMainCatId))
                            ? _selectedMainCatId
                            : null,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        hint: Text(
                          isRtl ? '-- اختر القسم الرئيسي --' : '-- Select Main Category --',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                        items: mainCategories.map((c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(
                                isRtl ? c.nameAr : c.nameEn,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            )).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedMainCatId = val;
                            _selectedSubCatId = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              );

              final step2Widget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStepBadge('2'),
                      const SizedBox(width: 6),
                      _buildFieldLabel(isRtl ? 'القسم الفرعي' : 'Subcategory', isDark),
                      if (_selectedMainCatId != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${availableSubcategories.length}',
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 42,
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
                        value: (_selectedSubCatId != null && availableSubcategories.any((c) => c.id == _selectedSubCatId))
                            ? _selectedSubCatId
                            : null,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        hint: Text(
                          availableSubcategories.isEmpty
                              ? (isRtl ? '-- لا توجد أقسام فرعية --' : '-- No Subcategories --')
                              : (isRtl ? '-- قسم فرعي اختياري --' : '-- Optional Subcategory --'),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                        items: availableSubcategories.map((c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(
                                isRtl ? c.nameAr : c.nameEn,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            )).toList(),
                        onChanged: (_selectedMainCatId == null || availableSubcategories.isEmpty)
                            ? null
                            : (val) => setState(() => _selectedSubCatId = val),
                      ),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    step1Widget,
                    const SizedBox(height: 10),
                    step2Widget,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: step1Widget),
                  const SizedBox(width: 10),
                  Expanded(child: step2Widget),
                ],
              );
            },
          ),
          if (assignedCategoryPath.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${isRtl ? "القسم المخصص: " : "Assigned: "}$assignedCategoryPath',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // ==================== SECTION 4: CODES & MEASUREMENTS ====================
          _buildSectionHeader(
            icon: Icons.qr_code_2_outlined,
            title: isRtl ? 'الرموز والمقاسات' : 'Codes & Measurements',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              final skuField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(isRtl ? 'رمز المنتج (SKU)' : 'SKU Code', isDark),
                  const SizedBox(height: 4),
                  _buildTextField(
                    _skuCtrl,
                    'MILK-ALM-2L',
                    isDark,
                    isMonospace: true,
                  ),
                ],
              );

              final barcodeField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(isRtl ? 'الباركود (Barcode)' : 'Barcode (EAN/UPC)', isDark),
                  const SizedBox(height: 4),
                  _buildTextField(
                    _barcodeCtrl,
                    '6281007010012',
                    isDark,
                    isMonospace: true,
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    skuField,
                    const SizedBox(height: 10),
                    barcodeField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: skuField),
                  const SizedBox(width: 10),
                  Expanded(child: barcodeField),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              final unitField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(isRtl ? 'وحدة القياس' : 'Measurement Unit', isDark),
                  const SizedBox(height: 4),
                  Container(
                    height: 42,
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
                        value: unitOptions.any((u) => u['id'] == _selectedUnit) ? _selectedUnit : 'EACH',
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: unitOptions.map((u) => DropdownMenuItem<String>(
                              value: u['id'],
                              child: Text(
                                isRtl ? u['nameAr']! : u['nameEn']!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            )).toList(),
                        onChanged: (val) => setState(() => _selectedUnit = val ?? 'EACH'),
                      ),
                    ),
                  ),
                ],
              );

              final unitSizeField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel(isRtl ? 'حجم / سعة الوحدة' : 'Unit Size / Capacity', isDark),
                  const SizedBox(height: 4),
                  _buildTextField(_unitSizeCtrl, '1', isDark, isNumber: true),
                ],
              );

              if (isNarrow) {
                return Column(
                  children: [
                    unitField,
                    const SizedBox(height: 10),
                    unitSizeField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: unitField),
                  const SizedBox(width: 10),
                  Expanded(child: unitSizeField),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // ==================== SECTION 5: PRODUCT IMAGE ====================
          _buildSectionHeader(
            icon: Icons.image_outlined,
            title: isRtl ? 'صورة المنتج' : 'Product Photo',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildImageDropzone(
            pickedBytes: _pickedImageBytes,
            existingUrl: _existingImageUrl,
            onPick: () async {
              final picker = ImagePicker();
              final file = await picker.pickImage(source: ImageSource.gallery);
              if (file != null) {
                final bytes = await file.readAsBytes();
                setState(() {
                  _pickedImageFile = file;
                  _pickedImageBytes = bytes;
                });
              }
            },
            onRemove: () {
              setState(() {
                _pickedImageFile = null;
                _pickedImageBytes = null;
                _existingImageUrl = null;
              });
            },
            isRtl: isRtl,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // ==================== SECTION 6: DESCRIPTIONS ====================
          _buildSectionHeader(
            icon: Icons.description_outlined,
            title: isRtl ? 'الوصف' : 'Descriptions',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildFieldLabel(isRtl ? 'الوصف بالإنجليزية' : 'Description (English)', isDark),
          const SizedBox(height: 4),
          _buildTextArea(_descEnCtrl, 'Enter product description in English...', isDark),
          const SizedBox(height: 10),
          _buildFieldLabel(isRtl ? 'الوصف بالعربية' : 'Description (Arabic)', isDark),
          const SizedBox(height: 4),
          _buildTextArea(_descArCtrl, 'أدخل وصف ومميزات المنتج بالعربية...', isDark, isRtl: true),
          const SizedBox(height: 16),

          // ==================== SECTION 7: STATUS TOGGLE ====================
          _buildSectionHeader(
            icon: Icons.tune_outlined,
            title: isRtl ? 'حالة التفعيل' : 'Status & Visibility',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildToggleCard(
            title: isRtl ? 'حالة تفعيل المنتج' : 'Active Product Status',
            subtitle: isRtl
                ? 'إظهار المنتج في دليل العروض والمنتجات العامة'
                : 'Make product visible across public app & deal catalogues',
            isSelected: _isActive,
            onTap: () => setState(() => _isActive = !_isActive),
            isDark: isDark,
            isRtl: isRtl,
          ),
          const SizedBox(height: 20),

          // Footer Actions
          Align(
            alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () {
                          _initFormData();
                          setState(() => _isEditMode = false);
                        },
                  child: Text(isRtl ? 'إلغاء' : 'Cancel', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: _isSaving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save, size: 16),
                  label: Text(
                    _isSaving
                        ? (isRtl ? 'جاري الحفظ...' : 'Saving...')
                        : (isRtl ? 'حفظ بيانات المنتج' : 'Save Product Details'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: _isSaving ? null : () => _submitProductEdit(liveBrands),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProductEdit(List<Brand> liveBrands) async {
    final isRtl = ref.read(translationProvider) == AppLanguage.ar;
    final nameEn = _nameEnCtrl.text.trim();
    final nameAr = _nameArCtrl.text.trim();
    final finalCategoryId = _selectedSubCatId ?? _selectedMainCatId;

    if (_selectedBrandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRtl ? 'يرجى اختيار الماركة التجارية.' : 'Please select a brand partner.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }
    if (nameEn.isEmpty || nameAr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRtl ? 'يرجى إدخال اسم المنتج بالإنجليزية والعربية.' : 'Please provide English and Arabic product names.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }
    if (finalCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRtl ? 'يرجى اختيار القسم.' : 'Please select a category.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final selectedBrandObj = liveBrands.where((b) => b.id == _selectedBrandId).firstOrNull;

    final success = await ref.read(productRepositoryProvider.notifier).updateProduct(
          id: widget.productId,
          nameEn: nameEn,
          nameAr: nameAr,
          brandId: _selectedBrandId,
          brand: selectedBrandObj?.nameEn ?? '',
          brandAr: selectedBrandObj?.nameAr ?? '',
          sku: _skuCtrl.text.trim().isNotEmpty ? _skuCtrl.text.trim() : null,
          barcode: _barcodeCtrl.text.trim().isNotEmpty ? _barcodeCtrl.text.trim() : null,
          primaryImage: _existingImageUrl,
          unit: _selectedUnit,
          size: double.tryParse(_unitSizeCtrl.text.trim()) ?? 1.0,
          categoryId: finalCategoryId,
          isActive: _isActive ? 1 : 0,
          descEn: _descEnCtrl.text.trim().isNotEmpty ? _descEnCtrl.text.trim() : null,
          descAr: _descArCtrl.text.trim().isNotEmpty ? _descArCtrl.text.trim() : null,
          imageFile: _pickedImageFile,
        );

    if (success && mounted) {
      await _loadData();
      setState(() {
        _isSaving = false;
        _isEditMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(isRtl ? 'تم تحديث المنتج بنجاح.' : 'Product updated successfully.'),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } else if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildStepBadge(String step) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        step,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
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
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            ),
          ),
        ),
      ],
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

  Widget _buildFieldLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, bool isDark, {bool isRtl = false, bool isMonospace = false, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      style: TextStyle(fontSize: 12, fontFamily: isMonospace ? 'monospace' : null, color: isDark ? Colors.white : const Color(0xFF0F172A)),
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
          color: isSelected ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4)) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF16A34A) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)), width: isSelected ? 1.5 : 1),
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isSelected ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D)) : (isDark ? Colors.white : const Color(0xFF0F172A))),
                  ),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
