import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/product_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../models/models.dart';
import '../widgets/crud_loading_widget.dart';

class ProductSpecsCrudScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductSpecsCrudScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductSpecsCrudScreen> createState() => _ProductSpecsCrudScreenState();
}

class _ProductSpecsCrudScreenState extends ConsumerState<ProductSpecsCrudScreen> {
  bool _isLoading = true;
  List<AttributeKey> _attributeKeys = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final results = await Future.wait([
      ref.read(productRepositoryProvider.notifier).fetchProductById(widget.productId),
      ref.read(productRepositoryProvider.notifier).fetchProductDetails(widget.productId),
      ref.read(productRepositoryProvider.notifier).fetchAttributeKeys(),
    ]);

    if (mounted) {
      setState(() {
        _attributeKeys = results[2] as List<AttributeKey>;
        _isLoading = false;
      });
    }
  }

  void _openAddEditModal(BuildContext context, bool isRtl, bool isDark, [ProductDetail? detail]) {
    final isEditing = detail != null;
    final keyEnCtrl = TextEditingController(text: detail?.attrKeyEn ?? '');
    final keyArCtrl = TextEditingController(text: detail?.attrKeyAr ?? '');
    final valEnCtrl = TextEditingController(text: detail?.attrValueEn ?? '');
    final valArCtrl = TextEditingController(text: detail?.attrValueAr ?? '');
    final sortCtrl = TextEditingController(text: '${detail?.sortOrder ?? 1}');

    int? selectedKeyId;
    if (detail != null && _attributeKeys.isNotEmpty) {
      final match = _attributeKeys.where((k) =>
          k.attrKeyEn.toLowerCase() == detail.attrKeyEn.toLowerCase() ||
          (detail.attrKeyAr.isNotEmpty && k.attrKeyAr == detail.attrKeyAr)).firstOrNull;
      if (match != null) {
        selectedKeyId = match.id;
      }
    }

    bool isCustomKey = detail != null && selectedKeyId == null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          actionsPadding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune, color: Color(0xFF7C3AED), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEditing
                      ? (isRtl ? 'تعديل المواصفة' : 'Edit Specification')
                      : (isRtl ? 'إضافة مواصفة جديدة' : 'Add Specification'),
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
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attribute Key Preset Dropdown or Custom
                  if (_attributeKeys.isNotEmpty && !isCustomKey) ...[
                    _buildFieldLabel(isRtl ? 'اختر خاصية من القائمة' : 'Select Attribute Key', isDark),
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
                          value: selectedKeyId,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          hint: Text(
                            isRtl ? '-- اختر خاصية --' : '-- Choose Key --',
                            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          ),
                          items: [
                            ..._attributeKeys.map((k) => DropdownMenuItem<int?>(
                                  value: k.id,
                                  child: Text(
                                    isRtl ? (k.attrKeyAr.isNotEmpty ? '${k.attrKeyAr} (${k.attrKeyEn})' : k.attrKeyEn) : '${k.attrKeyEn} (${k.attrKeyAr})',
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                  ),
                                )),
                          ],
                          onChanged: (val) {
                            setDialogState(() {
                              selectedKeyId = val;
                              if (val != null) {
                                final keyObj = _attributeKeys.where((k) => k.id == val).firstOrNull;
                                if (keyObj != null) {
                                  keyEnCtrl.text = keyObj.attrKeyEn;
                                  keyArCtrl.text = keyObj.attrKeyAr;
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setDialogState(() => isCustomKey = true),
                        icon: const Icon(Icons.add, size: 14),
                        label: Text(isRtl ? 'إدخال خاصية مخصصة' : 'Enter Custom Key', style: const TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF7C3AED)),
                      ),
                    ),
                  ] else ...[
                    // Custom Keys EN & AR
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(isRtl ? 'المواصفة (بالإنجليزية) *' : 'Attribute Key (EN) *', isDark),
                              const SizedBox(height: 4),
                              _buildTextField(keyEnCtrl, 'e.g. Storage / Color / Weight', isDark),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(isRtl ? 'المواصفة (بالعربية)' : 'Attribute Key (AR)', isDark),
                              const SizedBox(height: 4),
                              _buildTextField(keyArCtrl, 'مثال: السعة / اللون / الوزن', isDark, isRtl: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_attributeKeys.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setDialogState(() => isCustomKey = false),
                          icon: const Icon(Icons.list, size: 14),
                          label: Text(isRtl ? 'اختر من القائمة' : 'Select from List', style: const TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF7C3AED)),
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),

                  // Values EN & AR
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(isRtl ? 'القيمة (بالإنجليزية) *' : 'Attribute Value (EN) *', isDark),
                            const SizedBox(height: 4),
                            _buildTextField(valEnCtrl, 'e.g. 256 GB / Midnight Black', isDark),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel(isRtl ? 'القيمة (بالعربية)' : 'Attribute Value (AR)', isDark),
                            const SizedBox(height: 4),
                            _buildTextField(valArCtrl, 'مثال: 256 جيجابايت / أسود', isDark, isRtl: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sort Order
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel(isRtl ? 'ترتيب العرض' : 'Sort Order', isDark),
                      const SizedBox(height: 4),
                      _buildTextField(sortCtrl, '1', isDark, isNumber: true),
                    ],
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.save, size: 15),
              label: Text(
                isEditing
                    ? (isRtl ? 'حفظ التعديل' : 'Save Spec')
                    : (isRtl ? 'إضافة المواصفة' : 'Add Spec'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                final keyEn = keyEnCtrl.text.trim();
                final keyAr = keyArCtrl.text.trim();
                final valEn = valEnCtrl.text.trim();
                final valAr = valArCtrl.text.trim();
                final sort = int.tryParse(sortCtrl.text.trim()) ?? 1;

                if (keyEn.isEmpty && keyAr.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide an attribute key name.'), backgroundColor: Color(0xFFDC2626)),
                  );
                  return;
                }
                if (valEn.isEmpty && valAr.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide an attribute value.'), backgroundColor: Color(0xFFDC2626)),
                  );
                  return;
                }

                final kEn = keyEn.isNotEmpty ? keyEn : keyAr;
                final kAr = keyAr.isNotEmpty ? keyAr : keyEn;
                final vEn = valEn.isNotEmpty ? valEn : valAr;
                final vAr = valAr.isNotEmpty ? valAr : valEn;

                if (isCustomKey && keyEn.isNotEmpty && keyAr.isNotEmpty) {
                  ref.read(productRepositoryProvider.notifier).addAttributeKey(keyEn, keyAr);
                }

                if (isEditing) {
                  ref.read(productRepositoryProvider.notifier).updateProductDetail(
                        detail.id,
                        kEn,
                        kAr,
                        vEn,
                        vAr,
                        sort,
                      );
                } else {
                  ref.read(productRepositoryProvider.notifier).createProductDetail(
                        widget.productId,
                        kEn,
                        kAr,
                        vEn,
                        vAr,
                        sort,
                      );
                }

                Navigator.pop(ctx);
                final currentSpecs = ref.read(productRepositoryProvider).details.where((d) => d.productId == widget.productId).toList();
                ref.read(productRepositoryProvider.notifier).saveProductSpecs(widget.productId, currentSpecs);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ProductDetail detail, bool isRtl, bool isDark) {
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
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isRtl ? 'حذف المواصفة' : 'Delete Specification',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Text(
          isRtl ? 'هل أنت متأكد من حذف هذه المواصفة الفنية؟' : 'Are you sure you want to delete this specification?',
          style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(productRepositoryProvider.notifier).deleteProductDetail(detail.id);
              final currentSpecs = ref.read(productRepositoryProvider).details.where((d) => d.productId == widget.productId).toList();
              ref.read(productRepositoryProvider.notifier).saveProductSpecs(widget.productId, currentSpecs);
            },
            child: Text(isRtl ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repoState = ref.watch(productRepositoryProvider);
    final product = ref.watch(productRepositoryProvider.notifier).getProductById(widget.productId);
    final specs = repoState.details.where((d) => d.productId == widget.productId).toList();

    if (_isLoading && product == null) {
      return Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
          body: CrudLoadingWidget(
            isRtl: isRtl,
            isDark: isDark,
            titleEn: 'Loading Technical Specifications...',
            titleAr: 'جاري تحميل المواصفات الفنية...',
            subtitleEn: 'Fetching attribute keys and specification values...',
            subtitleAr: 'جاري جلب الخصائص والمواصفات الفنية الخاصة بالمنتج...',
          ),
        ),
      );
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card matching Angular .crud-header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 650;

                    final titles = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/admin/products');
                            }
                          },
                          icon: const Icon(Icons.arrow_back, size: 15),
                          label: Text(
                            isRtl ? 'العودة' : 'Back',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              isRtl ? 'المواصفات الفنية' : 'Technical Specifications',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            if (product != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                ': ${isRtl ? (product.nameAr.isNotEmpty ? product.nameAr : product.nameEn) : product.nameEn}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isRtl
                              ? 'إدارة الضبط والخصائص الفنية للقيم الخاصة بهذا المنتج.'
                              : 'Configure key-value specifications and technical attributes for this product.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    );

                    final addBtn = ElevatedButton.icon(
                      onPressed: () => _openAddEditModal(context, isRtl, isDark),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        isRtl ? 'إضافة مواصفة' : 'Add Specification',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 0,
                      ),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          titles,
                          const SizedBox(height: 12),
                          addBtn,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: titles),
                        const SizedBox(width: 14),
                        addBtn,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Specs List Grid matching Angular
              if (specs.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tune, size: 28, color: Color(0xFF7C3AED)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isRtl ? 'لا توجد مواصفات فنية' : 'No Specifications Added',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRtl
                            ? 'أضف أول مواصفة فنية لهذا المنتج (مثل: السعة، اللون، الوزن).'
                            : 'Add your first technical specification for this product (e.g. Storage, Color, Weight).',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openAddEditModal(context, isRtl, isDark),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(isRtl ? 'إضافة مواصفة' : 'Add Specification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final s = specs[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left Key & Values
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDE9FE),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle, size: 11, color: Color(0xFF7C3AED)),
                                          const SizedBox(width: 4),
                                          Text(
                                            s.attrKeyEn.isNotEmpty ? s.attrKeyEn : 'Specification',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF7C3AED),
                                            ),
                                          ),
                                          if (s.attrKeyAr.isNotEmpty) ...[
                                            const SizedBox(width: 3),
                                            Text(
                                              '(${s.attrKeyAr})',
                                              style: const TextStyle(fontSize: 10, color: Color(0xFF7C3AED)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        s.attrValueEn.isNotEmpty ? s.attrValueEn : '-',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    if (s.attrValueAr.isNotEmpty) ...[
                                      Text(
                                        ' / ${s.attrValueAr}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Sort Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${s.sortOrder}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Edit & Delete Buttons
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF16A34A)),
                            onPressed: () => _openAddEditModal(context, isRtl, isDark, s),
                            tooltip: isRtl ? 'تعديل' : 'Edit',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                            onPressed: () => _showDeleteDialog(context, s, isRtl, isDark),
                            tooltip: isRtl ? 'حذف' : 'Delete',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
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

  Widget _buildTextField(TextEditingController ctrl, String hint, bool isDark, {bool isRtl = false, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
      ),
    );
  }
}
