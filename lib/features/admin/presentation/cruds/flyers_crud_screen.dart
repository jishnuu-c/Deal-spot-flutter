import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/services/flyer_repository.dart';
import '../../../../core/services/store_repository.dart';
import '../../../../core/services/city_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/custom_select_widget.dart';
import '../../../../models/models.dart';
import '../widgets/crud_loading_widget.dart';

class FlyersCrudScreen extends ConsumerStatefulWidget {
  const FlyersCrudScreen({super.key});

  @override
  ConsumerState<FlyersCrudScreen> createState() => _FlyersCrudScreenState();
}

class _FlyersCrudScreenState extends ConsumerState<FlyersCrudScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  int? _selectedStoreFilter;
  int? _selectedCityFilter;
  String _selectedStatusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    final adminUser = authState.currentAdmin;
    final storeId = (adminUser?.role == 'STORE_MANAGER' && adminUser?.storeId != null)
        ? adminUser?.storeId
        : null;

    await Future.wait([
      ref.read(flyerRepositoryProvider.notifier).fetchFlyers(storeId: storeId),
      ref.read(storeRepositoryProvider.notifier).fetchStores(),
      ref.read(cityRepositoryProvider.notifier).fetchCities(),
    ]);
  }

  List<Flyer> _getFilteredFlyers(List<Flyer> flyers) {
    var list = flyers;
    final q = _searchQuery.trim().toLowerCase();

    if (q.isNotEmpty) {
      list = list.where((f) {
        final titleEn = f.titleEn.toLowerCase();
        final titleAr = f.titleAr.toLowerCase();
        final storeEn = (f.store?.nameEn ?? '').toLowerCase();
        final storeAr = (f.store?.nameAr ?? '').toLowerCase();
        final cityEn = (f.city?.nameEn ?? '').toLowerCase();
        final cityAr = (f.city?.nameAr ?? '').toLowerCase();
        return titleEn.contains(q) ||
            titleAr.contains(q) ||
            storeEn.contains(q) ||
            storeAr.contains(q) ||
            cityEn.contains(q) ||
            cityAr.contains(q);
      }).toList();
    }

    if (_selectedStoreFilter != null) {
      list = list.where((f) => f.storeId == _selectedStoreFilter).toList();
    }

    if (_selectedCityFilter != null) {
      list = list.where((f) => f.cityId == _selectedCityFilter).toList();
    }

    if (_selectedStatusFilter == 'ACTIVE') {
      list = list.where((f) => f.isActive == 1).toList();
    } else if (_selectedStatusFilter == 'INACTIVE') {
      list = list.where((f) => f.isActive == 0).toList();
    }

    return list;
  }

  void _showFlyerModal([Flyer? flyer]) {
    final isEn = ref.read(translationProvider) == AppLanguage.en;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stores = ref.read(storeRepositoryProvider).stores;
    final cities = ref.read(cityRepositoryProvider).cities;
    final authState = ref.read(authProvider);
    final adminUser = authState.currentAdmin;
    final isStoreManager = adminUser?.role == 'STORE_MANAGER' && adminUser?.storeId != null;

    final titleEnCtrl = TextEditingController(text: flyer?.titleEn ?? '');
    final titleArCtrl = TextEditingController(text: flyer?.titleAr ?? '');
    final today = DateTime.now();
    final nextWeek = today.add(const Duration(days: 7));
    final defaultFrom = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final defaultUntil = '${nextWeek.year.toString().padLeft(4, '0')}-${nextWeek.month.toString().padLeft(2, '0')}-${nextWeek.day.toString().padLeft(2, '0')}';

    final fromCtrl = TextEditingController(text: flyer?.validFrom.isNotEmpty == true ? flyer!.validFrom : defaultFrom);
    final untilCtrl = TextEditingController(text: flyer?.validUntil.isNotEmpty == true ? flyer!.validUntil : defaultUntil);

    int? selectedStoreId = flyer?.storeId ??
        (isStoreManager
            ? adminUser!.storeId
            : (stores.isNotEmpty ? stores[0].id : null));
    int? selectedCityId = flyer?.cityId ?? (cities.isNotEmpty ? cities[0].id : null);
    bool isActive = flyer == null ? true : flyer.isActive == 1;

    List<XFile> pickedPageFiles = [];
    List<Uint8List> pickedPageBytes = [];
    XFile? pickedPdfFile;
    String pdfFileName = flyer?.pdfUrl?.isNotEmpty == true ? flyer!.pdfUrl!.split('/').last : '';
    bool isSaving = false;

    // Load existing pages if editing
    List<FlyerPage> existingPages = flyer?.pages ?? [];
    if (flyer != null && existingPages.isEmpty) {
      ref.read(flyerRepositoryProvider.notifier).fetchFlyerPages(flyer.id).then((pages) {
        existingPages = pages;
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final screenWidth = MediaQuery.of(context).size.width;
            final dialogWidth = screenWidth > 860 ? 800.0 : (screenWidth > 640 ? 640.0 : double.maxFinite);
            final isModalNarrow = screenWidth < 680;

            final cardBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
            final cardBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

            return Directionality(
              textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                actionsPadding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.post_add, color: Color(0xFF16A34A), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flyer == null
                                ? (isEn ? 'Add Store Flyer' : 'إضافة منشور عروض جديد')
                                : (isEn ? 'Edit Flyer Catalogue' : 'تعديل بيانات المنشور'),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                          ),
                          Text(
                            isEn
                                ? 'Configure flyer metadata, validity period, and catalogue pages'
                                : 'تحديد بيانات المنشور، فترة الصلاحية، وتحميل صفحات العروض',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: dialogWidth,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Basic Titles
                        if (isModalNarrow) ...[
                          Text(isEn ? 'Flyer Title (English) *' : 'عنوان المنشور (الإنجليزية) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleEnCtrl,
                            decoration: InputDecoration(
                              hintText: isEn ? 'e.g. Weekly Super Saver Deals' : 'مثال: عروض التوفير الأسبوعية الكبرى',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(isEn ? 'Flyer Title (Arabic) *' : 'عنوان المنشور (العربية) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleArCtrl,
                            decoration: InputDecoration(
                              hintText: isEn ? 'Arabic title...' : 'مثال: عروض التوفير الأسبوعية الكبرى',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEn ? 'Flyer Title (English) *' : 'عنوان المنشور (الإنجليزية) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: titleEnCtrl,
                                      decoration: InputDecoration(
                                        hintText: isEn ? 'e.g. Weekly Super Saver Deals' : 'مثال: عروض التوفير الأسبوعية الكبرى',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEn ? 'Flyer Title (Arabic) *' : 'عنوان المنشور (العربية) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: titleArCtrl,
                                      decoration: InputDecoration(
                                        hintText: isEn ? 'Arabic title...' : 'مثال: عروض التوفير الأسبوعية الكبرى',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // Section 2: Store & City Selection
                        if (isModalNarrow) ...[
                          if (isStoreManager) ...[
                            Text(isEn ? 'Retailer Store' : 'المتجر المعلن', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cardBorderColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.storefront, color: Color(0xFF16A34A), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      stores.where((s) => s.id == selectedStoreId).firstOrNull?.nameEn ?? (isEn ? 'Your Store' : 'متجرك'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ] else ...[
                            AppCustomSelect<int>(
                              label: isEn ? 'Retailer Store' : 'المتجر المعلن',
                              isRequired: true,
                              placeholder: isEn ? '-- Select Retailer --' : '-- اختر المتجر --',
                              selectedValue: selectedStoreId,
                              options: stores.map((s) => CustomSelectOption<int>(
                                value: s.id,
                                labelEn: s.nameEn,
                                labelAr: s.nameAr,
                                imageUrl: s.logoUrl,
                              )).toList(),
                              onChanged: (val) => setDialogState(() => selectedStoreId = val),
                            ),
                            const SizedBox(height: 14),
                          ],
                          AppCustomSelect<int>(
                            label: isEn ? 'Target City' : 'المدينة المستهدفة',
                            isRequired: true,
                            placeholder: isEn ? '-- Select City --' : '-- اختر المدينة --',
                            selectedValue: selectedCityId,
                            options: cities.map((c) => CustomSelectOption<int>(
                              value: c.id,
                              labelEn: c.nameEn,
                              labelAr: c.nameAr,
                              icon: Icons.location_city_outlined,
                            )).toList(),
                            onChanged: (val) => setDialogState(() => selectedCityId = val),
                          ),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: isStoreManager
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(isEn ? 'Retailer Store' : 'المتجر المعلن', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: cardBgColor,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: cardBorderColor),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.storefront, color: Color(0xFF16A34A), size: 18),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    stores.where((s) => s.id == selectedStoreId).firstOrNull?.nameEn ?? (isEn ? 'Your Store' : 'متجرك'),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : AppCustomSelect<int>(
                                        label: isEn ? 'Retailer Store' : 'المتجر المعلن',
                                        isRequired: true,
                                        placeholder: isEn ? '-- Select Retailer --' : '-- اختر المتجر --',
                                        selectedValue: selectedStoreId,
                                        options: stores.map((s) => CustomSelectOption<int>(
                                          value: s.id,
                                          labelEn: s.nameEn,
                                          labelAr: s.nameAr,
                                          imageUrl: s.logoUrl,
                                        )).toList(),
                                        onChanged: (val) => setDialogState(() => selectedStoreId = val),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppCustomSelect<int>(
                                  label: isEn ? 'Target City' : 'المدينة المستهدفة',
                                  isRequired: true,
                                  placeholder: isEn ? '-- Select City --' : '-- اختر المدينة --',
                                  selectedValue: selectedCityId,
                                  options: cities.map((c) => CustomSelectOption<int>(
                                    value: c.id,
                                    labelEn: c.nameEn,
                                    labelAr: c.nameAr,
                                    icon: Icons.location_city_outlined,
                                  )).toList(),
                                  onChanged: (val) => setDialogState(() => selectedCityId = val),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // Section 3: Validity Period
                        if (isModalNarrow) ...[
                          Text(isEn ? 'Valid From *' : 'صالح من تاريخ *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: fromCtrl,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(fromCtrl.text) ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                fromCtrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              }
                            },
                            decoration: InputDecoration(
                              suffixIcon: const Icon(Icons.calendar_today, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(isEn ? 'Valid Until *' : 'صالح حتى تاريخ *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: untilCtrl,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(untilCtrl.text) ?? DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                untilCtrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              }
                            },
                            decoration: InputDecoration(
                              suffixIcon: const Icon(Icons.calendar_today, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEn ? 'Valid From *' : 'صالح من تاريخ *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: fromCtrl,
                                      readOnly: true,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.tryParse(fromCtrl.text) ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (picked != null) {
                                          fromCtrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                        }
                                      },
                                      decoration: InputDecoration(
                                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEn ? 'Valid Until *' : 'صالح حتى تاريخ *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: untilCtrl,
                                      readOnly: true,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.tryParse(untilCtrl.text) ?? DateTime.now().add(const Duration(days: 7)),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (picked != null) {
                                          untilCtrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                        }
                                      },
                                      decoration: InputDecoration(
                                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // Section 4: Page Uploads (Multiple Files)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.collections_outlined, size: 18, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEn ? 'Catalogue Page Images (Multiple Files)' : 'صور صفحات المنشور والكتالوج',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Upload Dropzone
                              InkWell(
                                onTap: () async {
                                  final picker = ImagePicker();
                                  final files = await picker.pickMultiImage();
                                  if (files.isNotEmpty) {
                                    for (final file in files) {
                                      final bytes = await file.readAsBytes();
                                      setDialogState(() {
                                        pickedPageFiles.add(file);
                                        pickedPageBytes.add(bytes);
                                      });
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4), style: BorderStyle.solid, width: 1.5),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.cloud_upload_outlined, size: 36, color: Color(0xFF16A34A)),
                                      const SizedBox(height: 8),
                                      Text(
                                        isEn
                                            ? 'Click or drop images to upload catalogue pages (JPG, PNG, WEBP)'
                                            : 'انقر أو اسحب صور صفحات الكتالوج هنا',
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Previews of newly selected page images
                              if (pickedPageBytes.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: List.generate(pickedPageBytes.length, (idx) {
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 110,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(7),
                                            child: Image.memory(pickedPageBytes[idx], fit: BoxFit.cover),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            color: Colors.black87,
                                            child: Text(
                                              idx == 0 ? 'Page 1 (Cover)' : 'Page ${idx + 1}',
                                              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 3,
                                          right: 3,
                                          child: InkWell(
                                            onTap: () {
                                              setDialogState(() {
                                                pickedPageFiles.removeAt(idx);
                                                pickedPageBytes.removeAt(idx);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.black87,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ],

                              // Existing pages when editing and no new pages picked
                              if (flyer != null && pickedPageBytes.isEmpty && existingPages.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  isEn ? 'Current Pages in Catalogue:' : 'الصفحات الحالية في الكتالوج:',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: existingPages.map((page) {
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 110,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(7),
                                            child: AppNetworkImage(
                                              imageUrl: AppConfig.normalizeImageUrl(page.imageUrl),
                                              fit: BoxFit.cover,
                                              defaultFallbackIcon: Icons.menu_book,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            color: Colors.black87,
                                            child: Text(
                                              'Page ${page.pageNumber}',
                                              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 5: PDF Brochure Document (Optional)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf_outlined, size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEn ? 'PDF Brochure Document (Optional)' : 'ملف الكتالوج صيغة PDF (اختياري)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () async {
                                  final picker = ImagePicker();
                                  final file = await picker.pickMedia();
                                  if (file != null) {
                                    setDialogState(() {
                                      pickedPdfFile = file;
                                      pdfFileName = file.name;
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.red.withValues(alpha: 0.4), style: BorderStyle.solid, width: 1.5),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.picture_as_pdf, color: Colors.red, size: 24),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          pdfFileName.isNotEmpty
                                              ? pdfFileName
                                              : (isEn ? 'Upload PDF Catalogue File' : 'تحميل كتالوج PDF'),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: pdfFileName.isNotEmpty ? (isDark ? Colors.white : Colors.black87) : Colors.red,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (pdfFileName.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () {
                                            setDialogState(() {
                                              pickedPdfFile = null;
                                              pdfFileName = '';
                                            });
                                          },
                                          child: const Icon(Icons.close, size: 16, color: Colors.grey),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 6: Active Status
                        Material(
                          color: cardBgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: cardBorderColor),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: CheckboxListTile(
                              dense: true,
                              activeColor: const Color(0xFF16A34A),
                              title: Text(
                                isEn ? 'Flyer Active & Published' : 'منشور نشط ومتاح للعملاء',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              subtitle: Text(
                                isEn
                                    ? 'Active flyers are visible in the app and website directory'
                                    : 'المنشورات النشطة تظهر للمستخدمين في صفحة العروض',
                                style: const TextStyle(fontSize: 11.5),
                              ),
                              value: isActive,
                              onChanged: (val) => setDialogState(() => isActive = val ?? true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: Text(isEn ? 'Cancel' : 'إلغاء'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final titleEn = titleEnCtrl.text.trim();
                            final titleAr = titleArCtrl.text.trim();

                            if (titleEn.isEmpty || titleAr.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEn ? 'Title (EN & AR) are required.' : 'العنوان (باللغتين) حقل مطلوب.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (selectedStoreId == null || selectedCityId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEn ? 'Store and City are required.' : 'المتجر والمدينة حقول مطلوبة.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (flyer == null && pickedPageFiles.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEn ? 'Please upload at least one catalogue page.' : 'يرجى تحميل صفحة واحدة على الأقل للمنشور.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setDialogState(() => isSaving = true);

                            final success = await ref.read(flyerRepositoryProvider.notifier).saveFlyerMultipart(
                              id: flyer?.id,
                              titleEn: titleEn,
                              titleAr: titleAr,
                              storeId: selectedStoreId!,
                              cityId: selectedCityId!,
                              validFrom: fromCtrl.text,
                              validUntil: untilCtrl.text,
                              isActive: isActive,
                              pageFiles: pickedPageFiles.isNotEmpty ? pickedPageFiles : null,
                              pdfFile: pickedPdfFile,
                            );

                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? (flyer == null ? (isEn ? 'Flyer created successfully.' : 'تم إنشاء المنشور بنجاح.') : (isEn ? 'Flyer updated successfully.' : 'تم تحديث المنشور بنجاح.'))
                                        : (isEn ? 'Failed to save flyer.' : 'فشل حفظ المنشور.'),
                                  ),
                                  backgroundColor: success ? const Color(0xFF16A34A) : Colors.red,
                                ),
                              );
                              _loadData();
                            }
                          },
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save, size: 18),
                    label: Text(
                      flyer == null
                          ? (isEn ? 'Save Catalogue' : 'حفظ المنشور')
                          : (isEn ? 'Save Changes' : 'حفظ التعديلات'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _deleteFlyer(Flyer flyer) {
    final isEn = ref.read(translationProvider) == AppLanguage.en;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEn ? 'Are you sure?' : 'هل أنت متأكد؟',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          isEn
              ? 'Do you want to delete "${flyer.titleEn}" and all its catalogue pages?'
              : 'هل تريد حذف المنشور "${flyer.titleAr.isNotEmpty ? flyer.titleAr : flyer.titleEn}" وجميع صفحاته؟',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Cancel' : 'إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(flyerRepositoryProvider.notifier).deleteFlyer(flyer.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (isEn ? 'Flyer deleted successfully.' : 'تم حذف المنشور بنجاح.')
                          : (isEn ? 'Failed to delete flyer.' : 'فشل حذف المنشور.'),
                    ),
                    backgroundColor: success ? const Color(0xFF16A34A) : Colors.red,
                  ),
                );
                _loadData();
              }
            },
            child: Text(isEn ? 'Yes, Delete!' : 'نعم، احذف!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isEn = !isRtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final flyerState = ref.watch(flyerRepositoryProvider);
    final stores = ref.watch(storeRepositoryProvider).stores;
    final cities = ref.watch(cityRepositoryProvider).cities;

    final flyers = flyerState.flyers;
    final filteredFlyers = _getFilteredFlyers(flyers);

    // Stats calculations
    final totalCatalogues = flyers.length;
    final activeFlyers = flyers.where((f) => f.isActive == 1).length;
    final totalViews = flyers.fold<int>(0, (acc, f) => acc + f.viewCount);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: _loadData,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Block
                _buildHeaderBlock(context, isEn, isDark),
                const SizedBox(height: 18),

                // 2. Summary Stats Cards
                _buildStatsGrid(
                  totalCatalogues: totalCatalogues,
                  activeFlyers: activeFlyers,
                  totalViews: totalViews,
                  isEn: isEn,
                  isDark: isDark,
                ),
                const SizedBox(height: 18),

                // 3. Filters & Search Toolbar
                _buildFilterToolbar(
                  stores: stores,
                  cities: cities,
                  isEn: isEn,
                  isDark: isDark,
                ),
                const SizedBox(height: 18),

                // 4. Content Area: Loading / Empty / Dual View
                if (flyerState.isLoading && flyers.isEmpty)
                  CrudLoadingWidget(
                    titleEn: 'Loading Flyers & Catalogues',
                    titleAr: 'جاري تحميل المنشورات والكتالوجات',
                    subtitleEn: 'Fetching latest promotional flyers from server...',
                    subtitleAr: 'جاري جلب أحدث المنشورات الترويجية من الخادم...',
                    icon: Icons.menu_book,
                    isRtl: isRtl,
                    isDark: isDark,
                  )
                else if (filteredFlyers.isEmpty)
                  _buildEmptyState(isEn, isDark)
                else
                  _buildFlyersView(filteredFlyers, isEn, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header Block
  Widget _buildHeaderBlock(BuildContext context, bool isEn, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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

          final titleInfo = Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.menu_book, color: Color(0xFF16A34A), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Store Flyers & Catalogues' : 'إدارة النشرات والعروض الأسبوعية',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 19,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEn
                          ? 'Publish weekly promotional catalogues, flyer pages, and PDF brochures'
                          : 'نشر كراسات العروض الأسبوعية، مجلات التخفيضات، وملفات PDF',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

          final createBtn = ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => _showFlyerModal(),
            icon: const Icon(Icons.post_add, size: 18),
            label: Text(
              isEn ? 'Add New Flyer' : 'إضافة منشور جديد',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleInfo,
                const SizedBox(height: 12),
                createBtn,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleInfo),
              const SizedBox(width: 14),
              createBtn,
            ],
          );
        },
      ),
    );
  }

  // Stats Grid
  Widget _buildStatsGrid({
    required int totalCatalogues,
    required int activeFlyers,
    required int totalViews,
    required bool isEn,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 550;

        final statItems = [
          _buildStatCard(
            title: isEn ? 'Total Catalogues' : 'إجمالي النشرات',
            value: totalCatalogues.toString(),
            icon: Icons.menu_book,
            color: const Color(0xFF0284C7),
            isDark: isDark,
          ),
          _buildStatCard(
            title: isEn ? 'Active Flyers' : 'نشرات نشطة',
            value: activeFlyers.toString(),
            icon: Icons.check_circle_outline,
            color: const Color(0xFF16A34A),
            isDark: isDark,
          ),
          _buildStatCard(
            title: isEn ? 'Total Views' : 'إجمالي المشاهدات',
            value: totalViews.toString(),
            icon: Icons.visibility_outlined,
            color: const Color(0xFFD97706),
            isDark: isDark,
          ),
        ];

        if (isCompact) {
          return LayoutBuilder(
            builder: (context, box) {
              final itemWidth = (box.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statItems.map((item) => SizedBox(width: itemWidth, child: item)).toList(),
              );
            },
          );
        }

        return Row(
          children: statItems
              .map((item) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: item,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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

  // Filter Toolbar
  Widget _buildFilterToolbar({
    required List<Store> stores,
    required List<City> cities,
    required bool isEn,
    required bool isDark,
  }) {
    final authState = ref.watch(authProvider);
    final isStoreManager = authState.currentAdmin?.role == 'STORE_MANAGER' && authState.currentAdmin?.storeId != null;

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
          final isMobile = constraints.maxWidth < 640;
          final searchWidth = isMobile ? double.infinity : 260.0;
          final dropdownWidth = isMobile ? (constraints.maxWidth - 10) / 2 : 160.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Search Field
                  SizedBox(
                    width: searchWidth,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: isEn ? 'Search by flyer title, store, city...' : 'ابحث بالعنوان، المتجر، المدينة...',
                        hintStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, size: 18, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      ),
                    ),
                  ),

                  // Store Filter
                  if (!isStoreManager)
                    SizedBox(
                      width: dropdownWidth,
                      child: AppCustomSelect<int?>(
                        placeholder: isEn ? 'All Stores' : 'جميع المتاجر',
                        selectedValue: _selectedStoreFilter,
                        clearable: true,
                        options: [
                          CustomSelectOption<int?>(
                            value: null,
                            labelEn: 'All Stores',
                            labelAr: 'جميع المتاجر',
                            icon: Icons.storefront,
                          ),
                          ...stores.map((s) => CustomSelectOption<int?>(
                                value: s.id,
                                labelEn: s.nameEn,
                                labelAr: s.nameAr,
                                imageUrl: s.logoUrl,
                              )),
                        ],
                        onChanged: (val) => setState(() => _selectedStoreFilter = val),
                      ),
                    ),

                  // City Filter
                  SizedBox(
                    width: dropdownWidth,
                    child: AppCustomSelect<int?>(
                      placeholder: isEn ? 'All Cities' : 'جميع المدن',
                      selectedValue: _selectedCityFilter,
                      clearable: true,
                      options: [
                        CustomSelectOption<int?>(
                          value: null,
                          labelEn: 'All Cities',
                          labelAr: 'جميع المدن',
                          icon: Icons.location_city,
                        ),
                        ...cities.map((c) => CustomSelectOption<int?>(
                              value: c.id,
                              labelEn: c.nameEn,
                              labelAr: c.nameAr,
                              icon: Icons.location_on_outlined,
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedCityFilter = val),
                    ),
                  ),

                  // Status Filter
                  SizedBox(
                    width: isMobile ? double.infinity : 140.0,
                    child: AppCustomSelect<String>(
                      placeholder: isEn ? 'All Statuses' : 'جميع الحالات',
                      selectedValue: _selectedStatusFilter,
                      options: [
                        CustomSelectOption<String>(value: 'ALL', labelEn: 'All Statuses', labelAr: 'جميع الحالات', icon: Icons.filter_list),
                        CustomSelectOption<String>(value: 'ACTIVE', labelEn: 'Active Only', labelAr: 'نشط فقط', icon: Icons.check_circle_outline),
                        CustomSelectOption<String>(value: 'INACTIVE', labelEn: 'Inactive Only', labelAr: 'غير نشط فقط', icon: Icons.cancel_outlined),
                      ],
                      onChanged: (val) => setState(() => _selectedStatusFilter = val ?? 'ALL'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState(bool isEn, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book, size: 32, color: Color(0xFF16A34A)),
          ),
          const SizedBox(height: 16),
          Text(
            isEn ? 'No flyers found' : 'لم يتم العثور على نشرات',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isEn
                ? 'Try adjusting your search criteria or click "Add New Flyer" to publish one.'
                : 'جرب تغيير خيارات البحث أو انقر على "إضافة منشور جديد".',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // Dual Responsive View
  Widget _buildFlyersView(List<Flyer> flyers, bool isEn, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 860) {
          return _buildDesktopTable(flyers, isEn, isDark);
        }
        return _buildMobileCards(flyers, isEn, isDark);
      },
    );
  }

  // Desktop Table View
  Widget _buildDesktopTable(List<Flyer> flyers, bool isEn, bool isDark) {
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final headerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 860),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(headerBg),
              horizontalMargin: 16,
              columnSpacing: 18,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 72,
              columns: [
                DataColumn(label: Text(isEn ? 'Cover' : 'الغلاف', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                const DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                DataColumn(label: Text(isEn ? 'Flyer Title' : 'عنوان المنشور', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                DataColumn(label: Text(isEn ? 'Retailer' : 'المتجر', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                DataColumn(label: Text(isEn ? 'City' : 'المدينة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                DataColumn(label: Text(isEn ? 'Pages' : 'الصفحات', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                DataColumn(label: Text(isEn ? 'Validity Period' : 'فترة الصلاحية', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                DataColumn(label: Text(isEn ? 'Views' : 'المشاهدات', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                DataColumn(label: Text(isEn ? 'Status' : 'الحالة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                DataColumn(label: Text(isEn ? 'Actions' : 'الإجراءات', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
              ],
              rows: flyers.map((f) {
                final isActive = f.isActive == 1;

                return DataRow(
                  cells: [
                    // Cover
                    DataCell(
                      Container(
                        width: 44,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: borderColor),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: AppNetworkImage(
                            imageUrl: AppConfig.normalizeImageUrl(f.coverImageUrl),
                            fit: BoxFit.cover,
                            defaultFallbackIcon: Icons.menu_book,
                          ),
                        ),
                      ),
                    ),

                    // ID
                    DataCell(
                      Text(
                        '#${f.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),

                    // Flyer Title
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEn ? f.titleEn : (f.titleAr.isNotEmpty ? f.titleAr : f.titleEn),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isEn && f.titleAr.isNotEmpty)
                              Text(f.titleAr, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                            if (!isEn && f.titleEn.isNotEmpty)
                              Text(f.titleEn, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),

                    // Retailer
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.storefront, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text(
                              isEn
                                  ? (f.store?.nameEn ?? 'Store #${f.storeId}')
                                  : (f.store?.nameAr ?? f.store?.nameEn ?? 'متجر #${f.storeId}'),
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // City
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 13, color: Colors.grey),
                            const SizedBox(width: 3),
                            Text(
                              isEn ? (f.city?.nameEn ?? 'City #${f.cityId}') : (f.city?.nameAr ?? f.city?.nameEn ?? 'مدينة #${f.cityId}'),
                              style: const TextStyle(fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Pages
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_stories, size: 13, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Text(
                              '${f.totalPages} ${isEn ? 'pages' : 'صفحات'}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Validity Period
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_available, size: 12, color: Color(0xFF16A34A)),
                              const SizedBox(width: 3),
                              Text(f.validFrom, style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_busy, size: 12, color: Colors.red),
                              const SizedBox(width: 3),
                              Text(f.validUntil, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Views
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility, size: 14, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(f.viewCount.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                    // Status
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF16A34A).withValues(alpha: 0.12) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF16A34A) : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isActive ? (isEn ? 'Active' : 'نشط') : (isEn ? 'Inactive' : 'غير نشط'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isActive ? const Color(0xFF16A34A) : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                            tooltip: isEn ? 'Edit Flyer' : 'تعديل المنشور',
                            onPressed: () => _showFlyerModal(f),
                          ),
                          // Manage Pages
                          IconButton(
                            icon: const Icon(Icons.auto_stories_outlined, size: 18, color: Color(0xFF16A34A)),
                            tooltip: isEn ? 'Manage Pages' : 'إدارة الصفحات',
                            onPressed: () => context.push('/admin/flyers/${f.id}/pages'),
                          ),
                          // Delete
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                            tooltip: isEn ? 'Delete Flyer' : 'حذف المنشور',
                            onPressed: () => _deleteFlyer(f),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // Mobile Responsive Cards View
  Widget _buildMobileCards(List<Flyer> flyers, bool isEn, bool isDark) {
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: flyers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final f = flyers[idx];
        final isActive = f.isActive == 1;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Cover Thumbnail + Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 94,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: AppNetworkImage(
                        imageUrl: AppConfig.normalizeImageUrl(f.coverImageUrl),
                        fit: BoxFit.cover,
                        defaultFallbackIcon: Icons.menu_book,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#${f.id}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF16A34A).withValues(alpha: 0.12) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? (isEn ? 'Active' : 'نشط') : (isEn ? 'Inactive' : 'غير نشط'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? const Color(0xFF16A34A) : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isEn ? f.titleEn : (f.titleAr.isNotEmpty ? f.titleAr : f.titleEn),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.storefront, size: 12, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 3),
                                  Text(
                                    isEn ? (f.store?.nameEn ?? 'Store') : (f.store?.nameAr ?? 'متجر'),
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                  const SizedBox(width: 3),
                                  Text(
                                    isEn ? (f.city?.nameEn ?? 'City') : (f.city?.nameAr ?? 'مدينة'),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Details Badges Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_stories, size: 12, color: Color(0xFF0284C7)),
                            const SizedBox(width: 3),
                            Text(
                              '${f.totalPages} ${isEn ? 'pages' : 'صفحات'}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.visibility, size: 13, color: Color(0xFFD97706)),
                          const SizedBox(width: 3),
                          Text('${f.viewCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(f.validFrom, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const Text(' → ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(f.validUntil, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Footer Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFF16A34A)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => context.push('/admin/flyers/${f.id}/pages'),
                      icon: const Icon(Icons.auto_stories, size: 16),
                      label: Text(
                        isEn ? 'Manage Pages' : 'إدارة الصفحات',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                    onPressed: () => _showFlyerModal(f),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                    onPressed: () => _deleteFlyer(f),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
