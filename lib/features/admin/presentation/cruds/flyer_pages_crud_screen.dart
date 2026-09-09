import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/flyer_repository.dart';
import '../../../../core/services/store_repository.dart';
import '../../../../core/services/city_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../models/models.dart';
import '../widgets/crud_loading_widget.dart';

class FlyerPagesCrudScreen extends ConsumerStatefulWidget {
  final int flyerId;

  const FlyerPagesCrudScreen({
    super.key,
    required this.flyerId,
  });

  @override
  ConsumerState<FlyerPagesCrudScreen> createState() => _FlyerPagesCrudScreenState();
}

class _FlyerPagesCrudScreenState extends ConsumerState<FlyerPagesCrudScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        ref.read(flyerRepositoryProvider.notifier).fetchFlyerById(widget.flyerId),
        ref.read(flyerRepositoryProvider.notifier).fetchFlyerPages(widget.flyerId),
        ref.read(storeRepositoryProvider.notifier).fetchStores(),
        ref.read(cityRepositoryProvider.notifier).fetchCities(),
      ]);
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Flyer? _getFlyer() {
    final flyerState = ref.watch(flyerRepositoryProvider);
    final list = flyerState.flyers;
    return list.where((f) => f.id == widget.flyerId).firstOrNull;
  }

  List<FlyerPage> _getPages() {
    final flyerState = ref.watch(flyerRepositoryProvider);
    var pages = flyerState.pages.where((p) => p.flyerId == widget.flyerId).toList();
    if (pages.isEmpty) {
      final flyer = _getFlyer();
      if (flyer?.pages != null && flyer!.pages!.isNotEmpty) {
        pages = List<FlyerPage>.from(flyer.pages!);
      }
    }
    pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    return pages;
  }

  String _getPageImageUrl(FlyerPage page) {
    final url = page.imageUrl.isNotEmpty ? page.imageUrl : page.thumbUrl;
    return AppConfig.normalizeImageUrl(url);
  }

  void _showAddEditModal([FlyerPage? page]) {
    final isEn = ref.read(translationProvider) == AppLanguage.en;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = !isEn;
    final pages = _getPages();
    final nextNumber = page != null
        ? page.pageNumber
        : (pages.isEmpty ? 1 : pages.map((p) => p.pageNumber).reduce((a, b) => a > b ? a : b) + 1);

    final pageNumberCtrl = TextEditingController(text: nextNumber.toString());
    XFile? pickedFile;
    Uint8List? pickedBytes;
    bool isSaving = false;
    String? existingImageUrl = page != null ? _getPageImageUrl(page) : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
          final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          page != null
                              ? (isEn ? 'Edit Catalogue Page' : 'تعديل صفحة الكتالوج')
                              : (isEn ? 'Upload Catalogue Sheet' : 'رفع صفحة كتالوج جديدة'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEn
                              ? 'Set sheet index position and choose image file'
                              : 'حدد رقم وترتيب الصفحة واختر ملف الصورة',
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: isSaving ? null : () => Navigator.pop(dialogCtx),
                    borderRadius: BorderRadius.circular(7),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.close, size: 20, color: mutedColor),
                    ),
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
                      // Page Number
                      Text(
                        isEn ? 'Page Number / Index *' : 'رقم / ترتيب الصفحة *',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: pageNumberCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 13.5, color: textColor),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          hintText: '1',
                          hintStyle: TextStyle(color: mutedColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: borderColor, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Page Image File
                      Text(
                        isEn ? 'Page Image File *' : 'ملف صورة الصفحة *',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Upload Dropzone
                      InkWell(
                        onTap: () async {
                          try {
                            final img = await _picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1920,
                              maxHeight: 1920,
                              imageQuality: 85,
                            );
                            if (img != null) {
                              final bytes = await img.readAsBytes();
                              setModalState(() {
                                pickedFile = img;
                                pickedBytes = bytes;
                              });
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to pick image: $e')),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: borderColor,
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.cloud_upload_outlined,
                                size: 36,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isEn
                                    ? 'Select page image (JPG, PNG, WEBP)'
                                    : 'اختر صورة الصفحة (JPG, PNG, WEBP)',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Image Preview Thumbnail
                      if (pickedBytes != null || (existingImageUrl != null && existingImageUrl.isNotEmpty)) ...[
                        const SizedBox(height: 14),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 140,
                                height: 180,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: pickedBytes != null
                                    ? Image.memory(
                                        pickedBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : AppNetworkImage(
                                        imageUrl: existingImageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isEn ? 'Page Preview' : 'معاينة الصفحة',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    foregroundColor: textColor,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: borderColor),
                    ),
                  ),
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: Text(
                    isEn ? 'Cancel' : 'إلغاء',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final pNum = int.tryParse(pageNumberCtrl.text.trim()) ?? 1;
                          if (page == null && pickedFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEn ? 'Please choose an image file.' : 'يرجى اختيار ملف الصورة.',
                                ),
                                backgroundColor: Colors.orange.shade800,
                              ),
                            );
                            return;
                          }

                          setModalState(() => isSaving = true);
                          try {
                            final success = await ref
                                .read(flyerRepositoryProvider.notifier)
                                .saveFlyerPageMultipart(
                                  pageId: page?.id,
                                  flyerId: widget.flyerId,
                                  pageNumber: pNum,
                                  pageFile: pickedFile,
                                );

                            if (mounted && dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? (page != null
                                            ? (isEn ? 'Page updated successfully' : 'تم تحديث الصفحة بنجاح')
                                            : (isEn ? 'Page added successfully' : 'تمت إضافة الصفحة بنجاح'))
                                        : (isEn ? 'Failed to save page' : 'فشل حفظ الصفحة'),
                                  ),
                                  backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                                ),
                              );
                              _loadData();
                            }
                          } catch (e) {
                            if (dialogCtx.mounted) {
                              setModalState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, size: 16),
                  label: Text(
                    isEn ? 'Save Page' : 'حفظ الصفحة',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDeletePage(FlyerPage page) {
    final isEn = ref.read(translationProvider) == AppLanguage.en;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = !isEn;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                isEn ? 'Delete Page?' : 'حذف الصفحة؟',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Text(
            isEn
                ? 'Are you sure you want to delete this catalogue sheet?'
                : 'هل أنت متأكد من رغبتك في حذف هذه الصفحة من الكتالوج؟',
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                isEn ? 'Cancel' : 'إلغاء',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                final success = await ref
                    .read(flyerRepositoryProvider.notifier)
                    .deleteFlyerPage(page.id, widget.flyerId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? (isEn ? 'Page deleted' : 'تم حذف الصفحة')
                            : (isEn ? 'Failed to delete page' : 'فشل حذف الصفحة'),
                      ),
                      backgroundColor: success ? const Color(0xFF10B981) : Colors.red,
                    ),
                  );
                  _loadData();
                }
              },
              child: Text(
                isEn ? 'Yes, delete it!' : 'نعم، احذف!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = ref.watch(translationProvider) == AppLanguage.en;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = !isEn;
    final flyer = _getFlyer();
    final pages = _getPages();

    final flyerTitle = isEn
        ? (flyer?.titleEn.isNotEmpty == true ? flyer!.titleEn : flyer?.titleAr ?? 'Flyer #${widget.flyerId}')
        : (flyer?.titleAr.isNotEmpty == true ? flyer!.titleAr : flyer?.titleEn ?? 'منشور #${widget.flyerId}');

    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        width: double.infinity,
        color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching Angular .crud-header
              Container(
                padding: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;

                    final headerLeft = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Back Button (.btn-back)
                        InkWell(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/admin/flyers');
                            }
                          },
                          borderRadius: BorderRadius.circular(11),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                              size: 20,
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title Group (.header-title-group)
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEn ? 'CATALOGUE PAGES' : 'صفحات الكتالوج',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontSize: 18.5,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: -0.3,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: isEn ? 'Pages for ' : 'صفحات منشور ',
                                    ),
                                    TextSpan(
                                      text: flyerTitle,
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final addBtn = ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        elevation: 0,
                        shadowColor: const Color(0xFF10B981).withValues(alpha: 0.25),
                      ),
                      onPressed: () => _showAddEditModal(),
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                      label: Text(
                        isEn ? 'Add Page Image' : 'إضافة صفحة كتالوج',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          headerLeft,
                          const SizedBox(height: 14),
                          addBtn,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: headerLeft),
                        const SizedBox(width: 16),
                        addBtn,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Loading State
              if (_isLoading)
                CrudLoadingWidget(
                  titleEn: 'Loading catalogue pages...',
                  titleAr: 'جاري تحميل صفحات الكتالوج...',
                  isRtl: isRtl,
                  isDark: isDark,
                )
              // Empty State (.empty-card)
              else if (pages.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        size: 48,
                        color: mutedColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isEn ? 'No pages uploaded yet' : 'لا توجد صفحات مرفوعة بعد',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isEn
                            ? 'Click "Add Page Image" above to upload scanned catalogue sheets.'
                            : 'انقر على "إضافة صفحة كتالوج" أعلاه لرفع صفحات العروض.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                )
              // Scanned Pages Grid (.pages-grid)
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width < 340
                        ? 1
                        : (width < 620
                            ? 2
                            : (width < 960
                                ? 3
                                : (width < 1280 ? 4 : 5)));

                    final cardHeight = crossAxisCount == 1
                        ? 350.0
                        : (crossAxisCount == 2 ? 305.0 : 325.0);
                    final imageHeight = crossAxisCount == 1
                        ? 250.0
                        : (crossAxisCount == 2 ? 195.0 : 215.0);

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: cardHeight,
                      ),
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        final imgUrl = _getPageImageUrl(page);
                        final isCover = page.pageNumber == 1;

                        return Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Image Wrapper (.page-image-wrapper)
                              SizedBox(
                                height: imageHeight,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      child: imgUrl.isNotEmpty
                                          ? AppNetworkImage(
                                              imageUrl: imgUrl,
                                              fit: BoxFit.cover,
                                              defaultFallbackIcon: Icons.menu_book,
                                            )
                                          : Center(
                                              child: Icon(
                                                Icons.image_not_supported_outlined,
                                                size: 36,
                                                color: mutedColor,
                                              ),
                                            ),
                                    ),
                                    // Floating Page Number Pill (.page-num-pill)
                                    Positioned(
                                      top: 8,
                                      left: isRtl ? null : 8,
                                      right: isRtl ? 8 : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.description,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isCover
                                                  ? (isEn ? 'Page 1 (Cover)' : 'صفحة 1 (الغلاف)')
                                                  : (isEn ? 'Page ${page.pageNumber}' : 'صفحة ${page.pageNumber}'),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Page Card Body (.page-card-body)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.tag,
                                      size: 14,
                                      color: mutedColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isEn ? 'Page Position: ' : 'ترتيب الصفحة: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      '#${page.pageNumber}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(),

                              // Page Card Footer (.page-card-footer)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  border: Border(top: BorderSide(color: borderColor)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Edit Action Button (btn-item-edit)
                                    Material(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(8),
                                      child: InkWell(
                                        onTap: () => _showAddEditModal(page),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: borderColor),
                                          ),
                                          child: Icon(
                                            Icons.edit_rounded,
                                            size: 16,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Delete Action Button (btn-item-del)
                                    Material(
                                      color: surfaceColor,
                                      borderRadius: BorderRadius.circular(8),
                                      child: InkWell(
                                        onTap: () => _confirmDeletePage(page),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: borderColor),
                                          ),
                                          child: Icon(
                                            Icons.delete_rounded,
                                            size: 16,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
          ),
        ),
      ),
    );
  }
}