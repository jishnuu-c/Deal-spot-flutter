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
import '../widgets/crud_loading_widget.dart';

class AdminProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const AdminProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<AdminProductDetailScreen> createState() => _AdminProductDetailScreenState();
}

class _AdminProductDetailScreenState extends ConsumerState<AdminProductDetailScreen> {
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

    _initFormData();
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
      _selectedUnit = product.unit.isNotEmpty ? product.unit : 'EACH';
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

              // 3. Main Content: Edit Form Mode OR View Mode Grid
              if (_isEditMode) ...[
                _buildEditForm(product, categories, brands, isRtl, isDark),
              ] else ...[
                _buildViewDetailsGrid(product, brandName, categoryPath, specs, isRtl, isDark),
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          final backBtn = InkWell(
            onTap: () => context.go('/admin/products'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    isRtl ? 'العودة للمنتجات' : 'Back to Products',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle Edit Mode Button
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    if (!_isEditMode) _initFormData();
                    _isEditMode = !_isEditMode;
                  });
                },
                icon: Icon(_isEditMode ? Icons.close : Icons.edit, size: 14),
                label: Text(
                  _isEditMode
                      ? (isRtl ? 'إلغاء التعديل' : 'Cancel Edit')
                      : (isRtl ? 'تعديل المنتج' : 'Edit Product'),
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditMode ? const Color(0xFF64748B) : const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 6),

              // Specs Navigation Button
              InkWell(
                onTap: () => context.go('/admin/product-specs/${product.id}/details'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.list_alt, size: 14, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 4),
                      Text(
                        isRtl ? 'المواصفات' : 'Specs',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                tooltip: isRtl ? 'حذف المنتج' : 'Delete Product',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showDeleteDialog(context, product, isRtl, isDark),
              ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                backBtn,
                const SizedBox(height: 8),
                actions,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              backBtn,
              actions,
            ],
          );
        },
      ),
    );
  }

  // 2. Hero / Header Card matching Angular .hero-card
  Widget _buildHeroCard(Product product, String brandName, String categoryPath, bool isRtl, bool isDark) {
    final imgUrl = _pickedImageBytes != null
        ? null
        : AppConfig.normalizeImageUrl(_existingImageUrl ?? product.primaryImageUrl);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          final imageBox = Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: isNarrow ? double.infinity : 120,
                  height: 120,
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  child: _pickedImageBytes != null
                      ? Image.memory(_pickedImageBytes!, fit: BoxFit.contain)
                      : (imgUrl != null && imgUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imgUrl,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => const Icon(Icons.inventory_2, size: 36, color: Color(0xFF94A3B8)),
                            )
                          : const Icon(Icons.inventory_2, size: 36, color: Color(0xFF94A3B8))),
                ),
              ),
              if (_isEditMode)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: InkWell(
                    onTap: () async {
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
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_camera, size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          );

          final detailsContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badges Row
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Status Pill (Clickable Quick Toggle)
                  InkWell(
                    onTap: () async {
                      final newActive = product.isActive == 1 ? 0 : 1;
                      await ref.read(productRepositoryProvider.notifier).updateProduct(
                            id: product.id,
                            nameEn: product.nameEn,
                            nameAr: product.nameAr,
                            brandId: product.brandId,
                            brand: product.brand,
                            brandAr: product.brandAr,
                            unit: product.unit,
                            size: product.unitSize,
                            categoryId: product.categoryId,
                            isActive: newActive,
                          );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: product.isActive == 1
                            ? const Color(0xFFDCFCE7)
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: product.isActive == 1
                              ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: product.isActive == 1 ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.isActive == 1 ? (isRtl ? 'نشط' : 'Active') : (isRtl ? 'غير نشط' : 'Inactive'),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: product.isActive == 1 ? const Color(0xFF166534) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ID Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${product.id}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),

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
                          const Icon(Icons.storefront, size: 11, color: Color(0xFF92400E)),
                          const SizedBox(width: 3),
                          Text(
                            brandName,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                          ),
                        ],
                      ),
                    ),

                  if (categoryPath.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category_outlined, size: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          const SizedBox(width: 3),
                          Text(
                            categoryPath,
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
              const SizedBox(height: 6),

              // Title EN & Title AR
              Text(
                product.nameEn,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              if (product.nameAr.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  product.nameAr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Meta Chips Row
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (product.sku.isNotEmpty)
                    _buildMetaChip('SKU:', product.sku, isMonospace: true, isDark: isDark),
                  if (product.barcode.isNotEmpty)
                    _buildMetaChip('UPC/Barcode:', product.barcode, isMonospace: true, isDark: isDark),
                  _buildMetaChip(
                    isRtl ? 'الحجم / الوحدة:' : 'Unit Size:',
                    '${product.unitSize} ${product.unit}',
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imageBox,
                const SizedBox(height: 12),
                detailsContent,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              imageBox,
              const SizedBox(width: 14),
              Expanded(child: detailsContent),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetaChip(String label, String value, {bool isMonospace = false, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              fontFamily: isMonospace ? 'monospace' : null,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Edit Form Mode matching Angular edit-mode-container
  Widget _buildEditForm(
    Product product,
    List<Category> allCategories,
    List<Brand> brands,
    bool isRtl,
    bool isDark,
  ) {
    final mainCats = allCategories.where((c) => c.parentId == null).toList();
    final availableSubCats = _selectedMainCatId != null
        ? allCategories.where((c) => c.parentId == _selectedMainCatId).toList()
        : <Category>[];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 6),
              Text(
                isRtl ? 'تعديل بيانات المنتج' : 'Edit Product Catalogue Entry',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Brand Selector
          _buildFieldLabel(isRtl ? 'الماركة التجارية *' : 'Brand Partner *', isDark),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedBrandId,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                items: brands.map((b) => DropdownMenuItem<int?>(
                      value: b.id,
                      child: Text(
                        isRtl ? (b.nameAr.isNotEmpty ? b.nameAr : b.nameEn) : b.nameEn,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    )).toList(),
                onChanged: (val) => setState(() => _selectedBrandId = val),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Product Names
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel(isRtl ? 'الاسم بالإنجليزية *' : 'Name (English) *', isDark),
                    const SizedBox(height: 4),
                    _buildTextField(_nameEnCtrl, 'e.g. Fresh Milk 2L', isDark),
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
                    _buildTextField(_nameArCtrl, 'مثال: حليب طازج 2 لتر', isDark, isRtl: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category Hierarchy
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel(isRtl ? 'القسم الرئيسي *' : 'Main Category *', isDark),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _selectedMainCatId,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          items: mainCats.map((c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(isRtl ? c.nameAr : c.nameEn, style: const TextStyle(fontSize: 12)),
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
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel(isRtl ? 'القسم الفرعي' : 'Subcategory', isDark),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _selectedSubCatId,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          hint: Text(
                            availableSubCats.isEmpty
                                ? (isRtl ? '-- لا توجد أقسام فرعية --' : '-- No Subcategories --')
                                : (isRtl ? '-- اختياري --' : '-- Optional --'),
                            style: const TextStyle(fontSize: 11),
                          ),
                          items: availableSubCats.map((c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(isRtl ? c.nameAr : c.nameEn, style: const TextStyle(fontSize: 12)),
                              )).toList(),
                          onChanged: availableSubCats.isEmpty ? null : (val) => setState(() => _selectedSubCatId = val),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Codes & Unit
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('SKU', isDark),
                    const SizedBox(height: 4),
                    _buildTextField(_skuCtrl, 'MILK-2L', isDark, isMonospace: true),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel(isRtl ? 'الباركود' : 'Barcode (EAN/UPC)', isDark),
                    const SizedBox(height: 4),
                    _buildTextField(_barcodeCtrl, '6281007010012', isDark, isMonospace: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel(isRtl ? 'وحدة القياس' : 'Measurement Unit', isDark),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedUnit,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          items: unitOptions.map((u) => DropdownMenuItem<String>(
                                value: u['id'],
                                child: Text(isRtl ? u['nameAr']! : u['nameEn']!, style: const TextStyle(fontSize: 12)),
                              )).toList(),
                          onChanged: (val) => setState(() => _selectedUnit = val ?? 'EACH'),
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
                    _buildFieldLabel(isRtl ? 'حجم / سعة الوحدة' : 'Unit Size / Capacity', isDark),
                    const SizedBox(height: 4),
                    _buildTextField(_unitSizeCtrl, '1', isDark, isNumber: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active Status Toggle Card
          _buildToggleCard(
            title: isRtl ? 'حالة تفعيل المنتج' : 'Active Product Status',
            subtitle: isRtl ? 'إظهار المنتج في دليل العروض والمنتجات العامة' : 'Make product visible across public app & deal catalogues',
            isSelected: _isActive,
            onTap: () => setState(() => _isActive = !_isActive),
            isDark: isDark,
            isRtl: isRtl,
          ),
          const SizedBox(height: 12),

          // Descriptions
          _buildFieldLabel(isRtl ? 'الوصف بالإنجليزية' : 'Description (English)', isDark),
          const SizedBox(height: 4),
          _buildTextArea(_descEnCtrl, 'Enter product description in English...', isDark),
          const SizedBox(height: 10),

          _buildFieldLabel(isRtl ? 'الوصف بالعربية' : 'Description (Arabic)', isDark),
          const SizedBox(height: 4),
          _buildTextArea(_descArCtrl, 'أدخل وصف المنتج بالعربية...', isDark, isRtl: true),
          const SizedBox(height: 16),

          // Footer Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : () => setState(() => _isEditMode = false),
                child: Text(isRtl ? 'إلغاء' : 'Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : () => _saveProduct(product),
                icon: _isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 16),
                label: Text(isRtl ? 'حفظ بيانات المنتج' : 'Save Product Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct(Product product) async {
    final nameEn = _nameEnCtrl.text.trim();
    final nameAr = _nameArCtrl.text.trim();
    final finalCatId = _selectedSubCatId ?? _selectedMainCatId;

    if (_selectedBrandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brand partner is required.'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }
    if (nameEn.isEmpty || nameAr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('English and Arabic product names are required.'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }
    if (finalCatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    setState(() => _isSaving = true);

    final brands = ref.read(brandRepositoryProvider).brands;
    final selectedBrandObj = brands.where((b) => b.id == _selectedBrandId).firstOrNull;

    final ok = await ref.read(productRepositoryProvider.notifier).updateProduct(
          id: product.id,
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
          categoryId: finalCatId,
          isActive: _isActive ? 1 : 0,
          descEn: _descEnCtrl.text.trim().isNotEmpty ? _descEnCtrl.text.trim() : null,
          descAr: _descArCtrl.text.trim().isNotEmpty ? _descArCtrl.text.trim() : null,
          imageFile: _pickedImageFile,
        );

    setState(() {
      _isSaving = false;
      if (ok) _isEditMode = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully.'), backgroundColor: Color(0xFF16A34A)),
      );
    }
  }

  // 4. View Details Grid Mode matching Angular .details-grid-container
  Widget _buildViewDetailsGrid(
    Product product,
    String brandName,
    String categoryPath,
    List<ProductDetail> specs,
    bool isRtl,
    bool isDark,
  ) {
    return Column(
      children: [
        // Card 1: General Product Information
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isRtl ? 'المعلومات العامة للمنتج' : 'General Product Information',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    onPressed: () => setState(() {
                      _initFormData();
                      _isEditMode = true;
                    }),
                  ),
                ],
              ),
              const Divider(height: 16),
              _buildInfoRow(isRtl ? 'الاسم بالإنجليزية' : 'English Name', product.nameEn, isDark),
              _buildInfoRow(isRtl ? 'الاسم بالعربية' : 'Arabic Name', product.nameAr.isNotEmpty ? product.nameAr : '-', isDark),
              _buildInfoRow(isRtl ? 'الماركة التجارية' : 'Brand Name', brandName.isNotEmpty ? brandName : '-', isDark),
              _buildInfoRow(isRtl ? 'تصنيف القسم' : 'Category Path', categoryPath.isNotEmpty ? categoryPath : '-', isDark),
              _buildInfoRow('SKU', product.sku.isNotEmpty ? product.sku : '-', isDark, isMono: true),
              _buildInfoRow(isRtl ? 'الباركود' : 'Barcode (UPC/EAN)', product.barcode.isNotEmpty ? product.barcode : '-', isDark, isMono: true),
              _buildInfoRow(isRtl ? 'وحدة القياس والسعة' : 'Unit & Capacity', '${product.unitSize} ${product.unit}', isDark),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Card 2: Descriptions
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, size: 18, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isRtl ? 'وصف ومميزات المنتج' : 'Product Descriptions',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              _buildDescBlock(
                'English Description',
                product.descriptionEn?.isNotEmpty == true ? product.descriptionEn! : (isRtl ? 'لا يوجد وصف بالإنجليزية.' : 'No description provided in English.'),
                isDark,
              ),
              const SizedBox(height: 10),
              _buildDescBlock(
                'الوصف بالعربية',
                product.descriptionAr?.isNotEmpty == true ? product.descriptionAr! : (isRtl ? 'لا يوجد وصف بالعربية.' : 'No description provided in Arabic.'),
                isDark,
                isRtl: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Card 3: Technical Specifications
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.list_alt, size: 18, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isRtl ? 'المواصفات الفنية' : 'Technical Specifications',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => context.go('/admin/product-specs/${product.id}/details'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tune, size: 13, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 4),
                          Text(
                            isRtl ? 'إدارة المواصفات' : 'Manage Specs',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              if (specs.isNotEmpty) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: specs.map((s) {
                    final keyLabel = isRtl
                        ? (s.attrKeyAr.isNotEmpty ? s.attrKeyAr : s.attrKeyEn)
                        : s.attrKeyEn;
                    final valLabel = isRtl
                        ? (s.attrValueAr.isNotEmpty ? s.attrValueAr : s.attrValueEn)
                        : s.attrValueEn;

                    return Container(
                      width: 260,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  keyLabel,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  valLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const Icon(Icons.tune, size: 28, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 6),
                      Text(
                        isRtl
                            ? 'لم يتم إضافة مواصفات فنية لهذا المنتج بعد.'
                            : 'No technical specifications added for this product yet.',
                        style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/admin/product-specs/${product.id}/details'),
                        icon: const Icon(Icons.add, size: 14),
                        label: Text(isRtl ? 'إضافة مواصفات' : 'Add Specs', style: const TextStyle(fontSize: 11.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
                fontFamily: isMono ? 'monospace' : null,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescBlock(String langTag, String text, bool isDark, {bool isRtl = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              langTag,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Helpers
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

  Widget _buildTextField(TextEditingController ctrl, String hint, bool isDark, {bool isRtl = false, bool isMonospace = false, bool isNumber = false}) {
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

  void _showDeleteDialog(BuildContext context, Product product, bool isRtl, bool isDark) {
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
                isRtl ? 'هل أنت متأكد؟' : 'Are you sure?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Text(
          isRtl ? 'جميع العروض المرتبطة بهذا المنتج ستفقد بياناته.' : 'All active offers linking to this item will lose their product specifications.',
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
              if (context.mounted) {
                context.go('/admin/products');
              }
            },
            child: Text(isRtl ? 'نعم، احذف!' : 'Yes, delete it!'),
          ),
        ],
      ),
    );
  }
}
