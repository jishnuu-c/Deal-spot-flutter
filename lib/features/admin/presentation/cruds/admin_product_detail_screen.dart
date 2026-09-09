import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' hide Category;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImageFile = file;
        _pickedImageBytes = bytes;
      });
    }
  }

  Future<void> _quickToggleActive(Product product) async {
    final isRtl = ref.read(translationProvider) == AppLanguage.ar;
    final newActive = product.isActive == 1 ? 0 : 1;

    final success = await ref.read(productRepositoryProvider.notifier).updateProduct(
          id: product.id,
          nameEn: product.nameEn,
          nameAr: product.nameAr,
          brandId: product.brandId,
          brand: product.brand,
          brandAr: product.brandAr,
          sku: product.sku,
          barcode: product.barcode,
          primaryImage: product.primaryImageUrl,
          unit: product.unit,
          size: product.unitSize,
          categoryId: product.categoryId,
          isActive: newActive,
          descEn: product.descriptionEn,
          descAr: product.descriptionAr,
        );

    if (success && mounted) {
      setState(() => _isActive = newActive == 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newActive == 1
                ? (isRtl ? 'تم تفعيل المنتج' : 'Product Activated')
                : (isRtl ? 'تم إلغاء تفعيل المنتج' : 'Product Deactivated'),
          ),
          backgroundColor: newActive == 1 ? const Color(0xFF16A34A) : const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteProduct(BuildContext context, Product product, bool isRtl, bool isDark) async {
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
              ? 'هل أنت متأكد من رغبتك في حذف هذا المنتج (${product.nameAr.isNotEmpty ? product.nameAr : product.nameEn})؟ لا يمكن التراجع عن هذا الإجراء.'
              : 'Are you sure you want to delete this product (${product.nameEn})? This action cannot be undone.',
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
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isRtl ? 'تم حذف المنتج بنجاح.' : 'Deleted Successfully'),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
                context.go('/admin/products');
              }
            },
            child: Text(isRtl ? 'نعم، احذف' : 'Yes, Delete'),
          ),
        ],
      ),
    );
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
            titleEn: 'Loading product details...',
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
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 28 : 14,
            vertical: isDesktop ? 24 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Action Bar (.top-action-bar)
              _buildTopActionBar(context, product, isRtl, isDark, isDesktop),
              const SizedBox(height: 18),

              // 2. Hero / Overview Card (.hero-card)
              _buildHeroCard(product, brandName, categoryPath, isRtl, isDark, isDesktop),
              const SizedBox(height: 18),

              if (_isEditMode) ...[
                // EDIT MODE FORM (.edit-mode-container)
                _buildEditForm(context, categories, brands, isRtl, isDark, isDesktop),
              ] else ...[
                // VIEW MODE DETAILS GRID (.details-grid-container)
                _buildViewModeGrid(context, product, brandName, categoryPath, specs, isRtl, isDark, isDesktop),
              ],
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Top Action Bar (.top-action-bar)
  Widget _buildTopActionBar(BuildContext context, Product product, bool isRtl, bool isDark, bool isDesktop) {
    final backBtn = Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/admin/products');
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                size: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              const SizedBox(width: 6),
              Text(
                isRtl ? 'العودة للمنتجات' : 'Back to Products',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final breadcrumbs = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: isRtl ? 'الدليل' : 'Catalogue',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          TextSpan(
            text: '  /  ',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          TextSpan(
            text: isRtl ? (product.nameAr.isNotEmpty ? product.nameAr : product.nameEn) : product.nameEn,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final actionButtons = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
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
          icon: Icon(_isEditMode ? Icons.close_rounded : Icons.edit_rounded, size: 16),
          label: Text(
            _isEditMode ? (isRtl ? 'إلغاء التعديل' : 'Cancel Edit') : (isRtl ? 'تعديل المنتج' : 'Edit Product'),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isEditMode ? const Color(0xFF64748B) : const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            elevation: 0,
          ),
        ),

        // Specs Button (.btn-specs)
        ElevatedButton.icon(
          onPressed: () => context.push('/admin/product-specs/${product.id}/details'),
          icon: const Icon(Icons.list_alt_rounded, size: 16),
          label: Text(
            isRtl ? 'المواصفات' : 'Specs',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFEFF6FF),
            foregroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.4 : 0.25)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            elevation: 0,
          ),
        ),

        // Delete Button (.btn-danger-outline)
        Material(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => _deleteProduct(context, product, isRtl, isDark),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.delete_rounded,
                size: 17,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      backBtn,
                      const SizedBox(width: 16),
                      Expanded(child: breadcrumbs),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                actionButtons,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    backBtn,
                    const SizedBox(width: 10),
                    Expanded(child: breadcrumbs),
                  ],
                ),
                const SizedBox(height: 12),
                actionButtons,
              ],
            ),
    );
  }

  // 2. Hero Card (.hero-card)
  Widget _buildHeroCard(Product product, String brandName, String categoryPath, bool isRtl, bool isDark, bool isDesktop) {
    final imgUrl = _pickedImageBytes != null ? '' : AppConfig.normalizeImageUrl(product.primaryImageUrl);
    final isInactive = product.isActive == 0;

    final imageWidget = Container(
      width: isDesktop ? 140 : 110,
      height: isDesktop ? 140 : 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: _pickedImageBytes != null
                ? Image.memory(_pickedImageBytes!, fit: BoxFit.contain)
                : (imgUrl.isNotEmpty
                    ? AppNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.contain,
                        defaultFallbackIcon: Icons.inventory_2_rounded,
                        fallbackIconSize: 42,
                      )
                    : const Icon(Icons.inventory_2_rounded, size: 42, color: Color(0xFF94A3B8))),
          ),
          if (_isEditMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: InkWell(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          isRtl ? 'تغيير الصورة' : 'Change Photo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final heroDetails = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Badges (.hero-top-badges)
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Status Pill (Interactive toggle with click)
            Tooltip(
              message: isRtl ? 'انقر لتغيير الحالة' : 'Click to toggle status',
              child: InkWell(
                onTap: () => _quickToggleActive(product),
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: !isInactive
                        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4))
                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: !isInactive
                          ? const Color(0xFFBBF7D0).withValues(alpha: isDark ? 0.3 : 0.8)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: !isInactive ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        !isInactive ? (isRtl ? 'نشط' : 'Active') : (isRtl ? 'غير نشط' : 'Inactive'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: !isInactive
                              ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D))
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ID Pill (.id-pill)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                '#${product.id}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                ),
              ),
            ),

            // Brand Pill (.tag-pill.brand-pill)
            if (brandName.isNotEmpty && brandName != '-')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF16A34A).withValues(alpha: isDark ? 0.3 : 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_rounded, size: 13, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text(
                      brandName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),

            // Category Pill (.tag-pill.cat-pill)
            if (categoryPath.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.3 : 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.category_rounded, size: 13, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(
                      categoryPath,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Product Titles
        Text(
          product.nameEn,
          style: TextStyle(
            fontSize: isDesktop ? 22 : 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.3,
            height: 1.25,
          ),
        ),
        if (product.nameAr.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            product.nameAr,
            style: TextStyle(
              fontSize: isDesktop ? 16 : 14,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 10),

        // Meta Chips Row (.hero-meta-chips)
        Container(
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              if (product.sku.isNotEmpty)
                _buildMetaChip('SKU:', product.sku, isDark, isMonospace: true),
              if (product.barcode.isNotEmpty)
                _buildMetaChip('UPC / Barcode:', product.barcode, isDark, isMonospace: true),
              _buildMetaChip(
                isRtl ? 'الحجم / الوحدة:' : 'Unit Size:',
                '${product.unitSize} ${product.unit}',
                isDark,
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isDesktop ? 22 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imageWidget,
                const SizedBox(width: 22),
                Expanded(child: heroDetails),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: imageWidget),
                const SizedBox(height: 14),
                heroDetails,
              ],
            ),
    );
  }

  Widget _buildMetaChip(String label, String value, bool isDark, {bool isMonospace = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: isMonospace ? 'monospace' : null,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  // 3. View Mode Grid (.details-grid-container)
  Widget _buildViewModeGrid(
    BuildContext context,
    Product product,
    String brandName,
    String categoryPath,
    List<ProductDetail> specs,
    bool isRtl,
    bool isDark,
    bool isDesktop,
  ) {
    final card1 = _buildGeneralInfoCard(product, brandName, categoryPath, isRtl, isDark);
    final card2 = _buildDescriptionsCard(product, isRtl, isDark);
    final card3 = _buildSpecsSummaryCard(context, product, specs, isRtl, isDark);

    if (isDesktop) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: card1),
              const SizedBox(width: 16),
              Expanded(child: card2),
            ],
          ),
          const SizedBox(height: 16),
          card3,
        ],
      );
    }

    return Column(
      children: [
        card1,
        const SizedBox(height: 14),
        card2,
        const SizedBox(height: 14),
        card3,
      ],
    );
  }

  // General Product Information Card
  Widget _buildGeneralInfoCard(Product product, String brandName, String categoryPath, bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.info_rounded, color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isRtl ? 'المعلومات العامة للمنتج' : 'General Product Information',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 16),
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                tooltip: isRtl ? 'تعديل التفاصيل' : 'Edit Details',
                onPressed: () => setState(() => _isEditMode = true),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Info Rows (.info-rows-list)
          _buildInfoRowItem(isRtl ? 'الاسم بالإنجليزية' : 'English Name', product.nameEn, isDark),
          _buildInfoRowItem(isRtl ? 'الاسم بالعربية' : 'Arabic Name', product.nameAr.isNotEmpty ? product.nameAr : '-', isDark),
          _buildInfoRowItem(isRtl ? 'الماركة التجارية' : 'Brand Name', brandName.isNotEmpty ? brandName : '-', isDark, isBrandPill: true),
          _buildInfoRowItem(isRtl ? 'تصنيف القسم' : 'Category Path', categoryPath.isNotEmpty ? categoryPath : '-', isDark, isCatPill: true),
          _buildInfoRowItem(isRtl ? 'رمز SKU' : 'SKU Code', product.sku.isNotEmpty ? product.sku : '-', isDark, isMonospace: true),
          _buildInfoRowItem(isRtl ? 'الباركود' : 'Barcode (UPC/EAN)', product.barcode.isNotEmpty ? product.barcode : '-', isDark, isMonospace: true),
          _buildInfoRowItem(isRtl ? 'وحدة القياس والسعة' : 'Unit & Capacity', '${product.unitSize} ${product.unit}', isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRowItem(String label, String value, bool isDark, {bool isMonospace = false, bool isBrandPill = false, bool isCatPill = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 10),
          if (isBrandPill && value != '-')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
              ),
            )
          else if (isCatPill && value != '-')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
              ),
            )
          else
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
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

  // Product Descriptions Card
  Widget _buildDescriptionsCard(Product product, bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_rounded, color: Color(0xFF16A34A), size: 18),
              const SizedBox(width: 8),
              Text(
                isRtl ? 'وصف ومميزات المنتج' : 'Product Descriptions',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // English Description Block
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENGLISH DESCRIPTION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (product.descriptionEn?.isNotEmpty ?? false)
                      ? product.descriptionEn!
                      : (isRtl ? 'لا يوجد وصف بالإنجليزية.' : 'No description provided in English.'),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Arabic Description Block
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الوصف بالعربية',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (product.descriptionAr?.isNotEmpty ?? false)
                      ? product.descriptionAr!
                      : (isRtl ? 'لا يوجد وصف بالعربية.' : 'No description provided in Arabic.'),
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Technical Specifications Card
  Widget _buildSpecsSummaryCard(BuildContext context, Product product, List<ProductDetail> specs, bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.list_alt_rounded, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isRtl ? 'المواصفات الفنية' : 'Technical Specifications',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/admin/product-specs/${product.id}/details'),
                    icon: const Icon(Icons.tune_rounded, size: 14),
                    label: Text(
                      isRtl ? 'إدارة المواصفات' : 'Manage Specs',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          if (specs.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Icon(Icons.tune_rounded, size: 32, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  Text(
                    isRtl
                        ? 'لم يتم إضافة مواصفات فنية لهذا المنتج بعد.'
                        : 'No technical specifications added for this product yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/admin/product-specs/${product.id}/details'),
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: Text(isRtl ? 'إضافة مواصفات' : 'Add Specs', style: const TextStyle(fontSize: 11.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth >= 700 ? 3 : (constraints.maxWidth >= 450 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3.2,
                  ),
                  itemCount: specs.length,
                  itemBuilder: (ctx, idx) {
                    final s = specs[idx];
                    final keyName = isRtl
                        ? (s.attrKeyAr.isNotEmpty ? s.attrKeyAr : s.attrKeyEn)
                        : s.attrKeyEn;
                    final valName = isRtl
                        ? (s.attrValueAr.isNotEmpty ? s.attrValueAr : s.attrValueEn)
                        : s.attrValueEn;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 13, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  keyName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            valName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // 4. Edit Mode Form (.edit-mode-container)
  Widget _buildEditForm(
    BuildContext context,
    List<Category> allCategories,
    List<Brand> brands,
    bool isRtl,
    bool isDark,
    bool isDesktop,
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

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
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
          if (isDesktop)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: Color(0xFF16A34A), size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isRtl ? 'تعديل بيانات المنتج' : 'Edit Product Catalogue Entry',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: _isSaving
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(
                    _isSaving
                        ? (isRtl ? 'جاري الحفظ...' : 'Saving...')
                        : (isRtl ? 'حفظ التغييرات' : 'Save Changes'),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  onPressed: _isSaving ? null : () => _submitProductEdit(liveBrands),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: Color(0xFF16A34A), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isRtl ? 'تعديل بيانات المنتج' : 'Edit Product Catalogue Entry',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: _isSaving
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(
                    _isSaving
                        ? (isRtl ? 'جاري الحفظ...' : 'Saving...')
                        : (isRtl ? 'حفظ التغييرات' : 'Save Changes'),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  onPressed: _isSaving ? null : () => _submitProductEdit(liveBrands),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Brand Selector (Searchable with logos)
          _buildFieldLabel(isRtl ? 'الماركة التجارية *' : 'Brand Partner *', isDark),
          const SizedBox(height: 6),
          SearchableBrandSelector(
            selectedBrandId: _selectedBrandId,
            brands: liveBrands,
            onChanged: (val) => setState(() => _selectedBrandId = val),
            isRtl: isRtl,
            isDark: isDark,
            placeholder: isRtl ? '-- اختر الماركة --' : '-- Select Brand --',
            isRequired: true,
          ),
          const SizedBox(height: 14),

          // Names Row
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(isRtl ? 'الاسم بالإنجليزية *' : 'Name (English) *', isDark),
                      const SizedBox(height: 6),
                      _buildTextField(_nameEnCtrl, 'e.g. Almarai Fresh Milk 2L', isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(isRtl ? 'الاسم بالعربية *' : 'Name (Arabic) *', isDark),
                      const SizedBox(height: 6),
                      _buildTextField(_nameArCtrl, 'مثال: حليب المراعي طازج 2 لتر', isDark, isRtl: true),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            _buildFieldLabel(isRtl ? 'الاسم بالإنجليزية *' : 'Name (English) *', isDark),
            const SizedBox(height: 6),
            _buildTextField(_nameEnCtrl, 'e.g. Almarai Fresh Milk 2L', isDark),
            const SizedBox(height: 12),
            _buildFieldLabel(isRtl ? 'الاسم بالعربية *' : 'Name (Arabic) *', isDark),
            const SizedBox(height: 6),
            _buildTextField(_nameArCtrl, 'مثال: حليب المراعي طازج 2 لتر', isDark, isRtl: true),
          ],
          const SizedBox(height: 14),

          // Category Step 1 & Step 2
          if (isDesktop)
            Row(
              children: [
                Expanded(child: _buildMainCatDropdown(mainCategories, isRtl, isDark)),
                const SizedBox(width: 14),
                Expanded(child: _buildSubCatDropdown(availableSubcategories, isRtl, isDark)),
              ],
            )
          else ...[
            _buildMainCatDropdown(mainCategories, isRtl, isDark),
            const SizedBox(height: 12),
            _buildSubCatDropdown(availableSubcategories, isRtl, isDark),
          ],
          const SizedBox(height: 14),

          // Codes & Measurements Section Header
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Text(
                  isRtl ? 'الرموز والمقاسات' : 'Codes & Measurements',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // SKU & Barcode
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(isRtl ? 'رمز المنتج (SKU)' : 'SKU Code', isDark),
                      const SizedBox(height: 6),
                      _buildTextField(_skuCtrl, 'MILK-ALM-2L', isDark, isMonospace: true),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(isRtl ? 'الباركود (Barcode)' : 'Barcode (EAN/UPC)', isDark),
                      const SizedBox(height: 6),
                      _buildTextField(_barcodeCtrl, '6281007010012', isDark, isMonospace: true),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            _buildFieldLabel(isRtl ? 'رمز المنتج (SKU)' : 'SKU Code', isDark),
            const SizedBox(height: 6),
            _buildTextField(_skuCtrl, 'MILK-ALM-2L', isDark, isMonospace: true),
            const SizedBox(height: 12),
            _buildFieldLabel(isRtl ? 'الباركود (Barcode)' : 'Barcode (EAN/UPC)', isDark),
            const SizedBox(height: 6),
            _buildTextField(_barcodeCtrl, '6281007010012', isDark, isMonospace: true),
          ],
          const SizedBox(height: 14),

          // Unit & Unit Size
          if (isDesktop)
            Row(
              children: [
                Expanded(child: _buildUnitDropdown(isRtl, isDark)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(isRtl ? 'حجم / سعة الوحدة' : 'Unit Size / Capacity', isDark),
                      const SizedBox(height: 6),
                      _buildTextField(_unitSizeCtrl, '1', isDark, isNumber: true),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            _buildUnitDropdown(isRtl, isDark),
            const SizedBox(height: 12),
            _buildFieldLabel(isRtl ? 'حجم / سعة الوحدة' : 'Unit Size / Capacity', isDark),
            const SizedBox(height: 6),
            _buildTextField(_unitSizeCtrl, '1', isDark, isNumber: true),
          ],
          const SizedBox(height: 14),

          // Active Status Toggle
          _buildToggleCard(
            title: isRtl ? 'حالة تفعيل المنتج' : 'Active Product Status',
            subtitle: isRtl
                ? 'إظهار المنتج في دليل العروض والمنتجات العامة'
                : 'Make product visible across public app & deal catalogues',
            isSelected: _isActive,
            onTap: () => setState(() => _isActive = !_isActive),
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // Descriptions
          _buildFieldLabel(isRtl ? 'الوصف بالإنجليزية' : 'Description (English)', isDark),
          const SizedBox(height: 6),
          _buildTextArea(_descEnCtrl, 'Enter product description in English...', isDark),
          const SizedBox(height: 12),
          _buildFieldLabel(isRtl ? 'الوصف بالعربية' : 'Description (Arabic)', isDark),
          const SizedBox(height: 6),
          _buildTextArea(_descArCtrl, 'أدخل وصف ومميزات المنتج بالعربية...', isDark, isRtl: true),
          const SizedBox(height: 20),

          // Footer Actions
          Align(
            alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
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
                  child: Text(isRtl ? 'إلغاء' : 'Cancel'),
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
                      : const Icon(Icons.save_rounded, size: 16),
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

  Widget _buildMainCatDropdown(List<Category> mainCategories, bool isRtl, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStepBadge('1'),
            const SizedBox(width: 6),
            _buildFieldLabel(isRtl ? 'القسم الرئيسي *' : 'Main Category *', isDark),
          ],
        ),
        const SizedBox(height: 6),
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
                  fontSize: 12,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
              items: mainCategories.map((c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(
                      isRtl ? c.nameAr : c.nameEn,
                      style: TextStyle(
                        fontSize: 12.5,
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
  }

  Widget _buildSubCatDropdown(List<Category> availableSubcategories, bool isRtl, bool isDark) {
    return Column(
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
        const SizedBox(height: 6),
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
                  fontSize: 12,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
              items: availableSubcategories.map((c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(
                      isRtl ? c.nameAr : c.nameEn,
                      style: TextStyle(
                        fontSize: 12.5,
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
  }

  Widget _buildUnitDropdown(bool isRtl, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(isRtl ? 'وحدة القياس' : 'Measurement Unit', isDark),
        const SizedBox(height: 6),
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
                        fontSize: 12,
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
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(isRtl ? 'تم تحديث المنتج بنجاح.' : 'Product Updated'),
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
        borderRadius: BorderRadius.circular(9999),
      ),
      alignment: Alignment.center,
      child: Text(
        step,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }

  Widget _buildFieldLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
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
        fontSize: 12.5,
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
      style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4))
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF16A34A)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Switch(
              value: isSelected,
              onChanged: (_) => onTap(),
              activeColor: const Color(0xFF16A34A),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D))
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
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
}
