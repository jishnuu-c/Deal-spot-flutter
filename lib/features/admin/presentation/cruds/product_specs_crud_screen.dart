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
  void _openAddEditModal(BuildContext context, bool isRtl, bool isDark, [ProductDetail? detail]) {
    final isEditing = detail != null;
    final keyEnCtrl = TextEditingController(text: detail?.attrKeyEn ?? '');
    final keyArCtrl = TextEditingController(text: detail?.attrKeyAr ?? '');
    final valEnCtrl = TextEditingController(text: detail?.attrValueEn ?? '');
    final valArCtrl = TextEditingController(text: detail?.attrValueAr ?? '');
    final sortCtrl = TextEditingController(text: '${detail?.sortOrder ?? 1}');

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
                  // Keys EN & AR
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.save, size: 16),
              label: Text(
                isEditing
                    ? (isRtl ? 'تحديث المواصفة' : 'Update Spec')
                    : (isRtl ? 'إضافة المواصفة' : 'Add Spec'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                final keyEn = keyEnCtrl.text.trim();
                final keyAr = keyArCtrl.text.trim();
                final valEn = valEnCtrl.text.trim();
                final valAr = valArCtrl.text.trim();
                final sort = int.tryParse(sortCtrl.text.trim()) ?? 1;

                if (keyEn.isEmpty || valEn.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Key (EN) and Value (EN) are required.'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                  return;
                }

                if (isEditing) {
                  ref.read(productRepositoryProvider.notifier).updateProductDetail(
                        detail.id,
                        keyEn,
                        keyAr,
                        valEn,
                        valAr,
                        sort,
                      );
                } else {
                  ref.read(productRepositoryProvider.notifier).createProductDetail(
                        widget.productId,
                        keyEn,
                        keyAr,
                        valEn,
                        valAr,
                        sort,
                      );
                }

                Navigator.pop(ctx);
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
    final product = ref.watch(productRepositoryProvider.notifier).getProductById(widget.productId);
    final specs = product?.details ?? [];

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
                        InkWell(
                          onTap: () => context.go('/admin/products/${widget.productId}/details'),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_back, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  isRtl ? 'العودة لتفاصيل المنتج' : 'Back to Product Details',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isRtl ? 'المواصفات الفنية للمنتج' : 'Technical Specifications',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (product != null) ...[
                              Text(
                                ': ${product.nameEn}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7C3AED),
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
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
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
                          titles,
                          const SizedBox(height: 10),
                          addBtn,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: titles),
                        const SizedBox(width: 12),
                        addBtn,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Specs Grid or Empty View matching Angular .specs-wrapper
              if (specs.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.tune, color: Color(0xFF7C3AED), size: 24),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isRtl ? 'لا توجد مواصفات فنية' : 'No Specifications Added',
                        style: TextStyle(
                          fontSize: 15,
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
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () => _openAddEditModal(context, isRtl, isDark),
                        icon: const Icon(Icons.add, size: 15),
                        label: Text(isRtl ? 'إضافة مواصفة' : 'Add Specification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final s = specs[index];

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          // Key & Value
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                                    const SizedBox(width: 6),
                                    Text(
                                      s.attrKeyEn,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (s.attrKeyAr.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${s.attrKeyAr})',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      s.attrValueEn,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                      ),
                                    ),
                                    if (s.attrValueAr.isNotEmpty) ...[
                                      Text(
                                        ' / ${s.attrValueAr}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Sort Badge & Actions
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${s.sortOrder}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                onPressed: () => _openAddEditModal(context, isRtl, isDark, s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
                                onPressed: () => _showDeleteDialog(context, s, isRtl, isDark),
                              ),
                            ],
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
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
      ),
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
