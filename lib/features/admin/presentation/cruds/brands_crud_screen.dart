import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' hide Category;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/brand_repository.dart';
import '../../../../core/services/category_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../models/brand.dart';
import '../../../../models/category.dart';
import '../widgets/crud_loading_widget.dart';

class BrandsCrudScreen extends ConsumerStatefulWidget {
  const BrandsCrudScreen({super.key});

  @override
  ConsumerState<BrandsCrudScreen> createState() => _BrandsCrudScreenState();
}

class _BrandsCrudScreenState extends ConsumerState<BrandsCrudScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  String _searchQuery = '';
  String _activeFilter = 'ALL'; // 'ALL' | 'ACTIVE' | 'FEATURED' | 'INACTIVE'
  bool _showScrollTop = false;
  int _displayedCount = 20;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showScrollTop) {
        setState(() => _showScrollTop = show);
      }
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
        final allBrands = ref.read(brandRepositoryProvider).brands;
        final filtered = _getFilteredBrands(allBrands);
        _loadMore(filtered.length);
      }
    });
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

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  List<Brand> _getFilteredBrands(List<Brand> allBrands) {
    var list = allBrands;

    // 1. Status/Featured filter
    if (_activeFilter == 'ACTIVE') {
      list = list.where((b) => b.active).toList();
    } else if (_activeFilter == 'FEATURED') {
      list = list.where((b) => b.featured).toList();
    } else if (_activeFilter == 'INACTIVE') {
      list = list.where((b) => !b.active).toList();
    }

    // 2. Search query filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((b) {
        final nameEn = b.nameEn.toLowerCase();
        final nameAr = b.nameAr.toLowerCase();
        final idStr = b.id.toString();
        final descEn = b.descriptionEn?.toLowerCase() ?? '';
        final descAr = b.descriptionAr?.toLowerCase() ?? '';
        final website = b.websiteUrl?.toLowerCase() ?? '';
        final inCats = b.categories.any((c) =>
            c.nameEn.toLowerCase().contains(q) || c.nameAr.toLowerCase().contains(q));

        return nameEn.contains(q) ||
            nameAr.contains(q) ||
            idStr == q ||
            descEn.contains(q) ||
            descAr.contains(q) ||
            website.contains(q) ||
            inCats;
      }).toList();
    }

    return list;
  }

  int _getActiveCount(List<Brand> all) => all.where((b) => b.active).length;
  int _getFeaturedCount(List<Brand> all) => all.where((b) => b.featured).length;
  int _getInactiveCount(List<Brand> all) => all.where((b) => !b.active).length;

  void _showAddEditBrandModal(BuildContext context, bool isRtl, bool isDark, [Brand? brand]) {
    final isEditing = brand != null;
    final allCategories = ref.read(categoryRepositoryProvider);

    final nameEnCtrl = TextEditingController(text: brand?.nameEn ?? '');
    final nameArCtrl = TextEditingController(text: brand?.nameAr ?? '');
    final websiteCtrl = TextEditingController(text: brand?.websiteUrl ?? '');
    final descEnCtrl = TextEditingController(text: brand?.descriptionEn ?? '');
    final descArCtrl = TextEditingController(text: brand?.descriptionAr ?? '');
    final catSearchCtrl = TextEditingController();

    List<int> selectedCategoryIds = brand?.categories.map((c) => c.id).toList() ?? [];
    bool isActive = brand == null ? true : brand.active;
    bool isFeatured = brand?.featured ?? false;
    bool isCatDropdownOpen = false;

    XFile? pickedLogoFile;
    Uint8List? pickedLogoBytes;
    String existingLogoUrl = brand?.logoUrl != null ? AppConfig.normalizeImageUrl(brand!.logoUrl) : '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final catSearch = catSearchCtrl.text.toLowerCase().trim();
          final filteredCategories = catSearch.isEmpty
              ? allCategories
              : allCategories.where((c) =>
                  c.nameEn.toLowerCase().contains(catSearch) ||
                  c.nameAr.toLowerCase().contains(catSearch)).toList();

          final selectedCategoryObjects = allCategories
              .where((c) => selectedCategoryIds.contains(c.id))
              .toList();

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
                    isEditing ? Icons.edit_note : Icons.add_business,
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
                        isEditing
                            ? (isRtl ? 'تعديل بيانات العلامة التجارية' : 'Edit Brand Partner')
                            : (isRtl ? 'إضافة علامة تجارية شريكة' : 'Add New Brand Partner'),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRtl
                            ? 'حدد هوية العلامة التجارية والتصنيفات والموقع والشعار الرسمي.'
                            : 'Configure brand identity, categories, website and official logo.',
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
              width: 540,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Brand Names
                    _buildSectionHeader(Icons.badge_outlined, isRtl ? 'أسماء العلامة التجارية' : 'Brand Names', isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(isRtl ? 'اسم الماركة بالإنجليزية *' : 'Brand Name (EN) *', isDark),
                              const SizedBox(height: 4),
                              _buildTextField(nameEnCtrl, 'e.g. Samsung', isDark),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(isRtl ? 'اسم الماركة بالعربية *' : 'Brand Name (AR) *', isDark),
                              const SizedBox(height: 4),
                              _buildTextField(nameArCtrl, 'مثال: سامسونج', isDark, isRtl: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 2: Website
                    _buildSectionHeader(Icons.language, isRtl ? 'الموقع الرسمي' : 'Official Website', isDark),
                    const SizedBox(height: 8),
                    _buildFieldLabel(isRtl ? 'رابط الموقع الإلكتروني' : 'Website URL', isDark),
                    const SizedBox(height: 4),
                    TextField(
                      controller: websiteCtrl,
                      keyboardType: TextInputType.url,
                      style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'https://www.samsung.com',
                        hintStyle: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.link, size: 16, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF16A34A), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 3: Assigned Categories Multi-Select
                    _buildSectionHeader(Icons.category_outlined, isRtl ? 'التصنيفات المرتبطة' : 'Assigned Categories', isDark),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFieldLabel(isRtl ? 'اختر التصنيفات' : 'Select Categories', isDark),
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                setModalState(() {
                                  selectedCategoryIds = allCategories.map((c) => c.id).toList();
                                });
                              },
                              child: Text(
                                isRtl ? 'تحديد الكل' : 'Select All',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                              ),
                            ),
                            const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8))),
                            InkWell(
                              onTap: () {
                                setModalState(() {
                                  selectedCategoryIds = [];
                                });
                              },
                              child: Text(
                                isRtl ? 'مسح' : 'Clear',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Multi-Select Container Box
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Chips display row
                          InkWell(
                            onTap: () => setModalState(() => isCatDropdownOpen = !isCatDropdownOpen),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: selectedCategoryObjects.isEmpty
                                        ? Text(
                                            isRtl ? 'انقر لاختيار التصنيفات...' : 'Click to select categories...',
                                            style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                          )
                                        : Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: selectedCategoryObjects.map((c) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFDCFCE7),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      isRtl ? (c.nameAr.isNotEmpty ? c.nameAr : c.nameEn) : c.nameEn,
                                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    InkWell(
                                                      onTap: () {
                                                        setModalState(() {
                                                          selectedCategoryIds.remove(c.id);
                                                        });
                                                      },
                                                      child: const Icon(Icons.close, size: 12, color: Color(0xFF166534)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                  ),
                                  Icon(
                                    isCatDropdownOpen ? Icons.expand_less : Icons.expand_more,
                                    size: 18,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Dropdown selector panel
                          if (isCatDropdownOpen) ...[
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: TextField(
                                controller: catSearchCtrl,
                                onChanged: (_) => setModalState(() {}),
                                style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: isRtl ? 'ابحث في التصنيفات...' : 'Search categories...',
                                  hintStyle: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                  prefixIcon: const Icon(Icons.search, size: 14),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 140),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredCategories.length,
                                itemBuilder: (context, index) {
                                  final cat = filteredCategories[index];
                                  final isSelected = selectedCategoryIds.contains(cat.id);
                                  return InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        if (isSelected) {
                                          selectedCategoryIds.remove(cat.id);
                                        } else {
                                          selectedCategoryIds.add(cat.id);
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: Checkbox(
                                              value: isSelected,
                                              activeColor: const Color(0xFF16A34A),
                                              onChanged: (val) {
                                                setModalState(() {
                                                  if (val == true) {
                                                    selectedCategoryIds.add(cat.id);
                                                  } else {
                                                    selectedCategoryIds.remove(cat.id);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              isRtl ? (cat.nameAr.isNotEmpty ? cat.nameAr : cat.nameEn) : cat.nameEn,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          if (cat.parentId != null)
                                            Text(
                                              isRtl ? '(فرعي)' : '(Sub)',
                                              style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 4: Brand Descriptions
                    _buildSectionHeader(Icons.description_outlined, isRtl ? 'وصف العلامة التجارية' : 'Brand Description', isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(isRtl ? 'الوصف بالإنجليزية' : 'Description (EN)', isDark),
                              const SizedBox(height: 4),
                              TextField(
                                controller: descEnCtrl,
                                maxLines: 2,
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: 'Short description about the brand in English...',
                                  hintStyle: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF16A34A), width: 1.5)),
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
                              _buildFieldLabel(isRtl ? 'الوصف بالعربية' : 'Description (AR)', isDark),
                              const SizedBox(height: 4),
                              TextField(
                                controller: descArCtrl,
                                maxLines: 2,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  hintText: 'وصف موجز عن العلامة التجارية بالعربية...',
                                  hintStyle: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF16A34A), width: 1.5)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 5: Brand Logo
                    _buildSectionHeader(Icons.image_outlined, isRtl ? 'شعار الماركة' : 'Brand Logo', isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              try {
                                final file = await _picker.pickImage(source: ImageSource.gallery);
                                if (file != null) {
                                  final bytes = await file.readAsBytes();
                                  setModalState(() {
                                    pickedLogoFile = file;
                                    pickedLogoBytes = bytes;
                                  });
                                }
                              } catch (_) {}
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_upload_outlined, size: 16, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      pickedLogoFile != null
                                          ? (isRtl ? 'تم اختيار الشعار' : 'Logo Selected')
                                          : (isRtl ? 'اختر الشعار' : 'Choose Logo'),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (pickedLogoBytes != null || existingLogoUrl.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Stack(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF16A34A)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: pickedLogoBytes != null
                                    ? Image.memory(pickedLogoBytes!, fit: BoxFit.cover)
                                    : CachedNetworkImage(
                                        imageUrl: existingLogoUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 18),
                                      ),
                              ),
                              if (pickedLogoFile != null)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        pickedLogoFile = null;
                                        pickedLogoBytes = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(1),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDC2626),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 10, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 6: Status & Featured
                    _buildSectionHeader(Icons.tune, isRtl ? 'الحالة والتمييز' : 'Status & Featured', isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Active Switch
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Switch(
                                  value: isActive,
                                  activeColor: const Color(0xFF16A34A),
                                  onChanged: (val) => setModalState(() => isActive = val),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isRtl ? 'شريك نشط' : 'Active Partner',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        isRtl ? 'إظهار في الكتالوج' : 'Show in catalogue',
                                        style: TextStyle(fontSize: 9.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Featured Switch
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Switch(
                                  value: isFeatured,
                                  activeColor: const Color(0xFFF59E0B),
                                  onChanged: (val) => setModalState(() => isFeatured = val),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isRtl ? 'علامة مميزة' : 'Featured Brand',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        isRtl ? 'إبراز في الرئيسية' : 'Highlight on Home',
                                        style: TextStyle(fontSize: 9.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(isRtl ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.save, size: 16),
                label: Text(
                  isEditing
                      ? (isRtl ? 'حفظ التعديلات' : 'Save Changes')
                      : (isRtl ? 'إنشاء الماركة' : 'Create Brand'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                onPressed: () async {
                  final nameEn = nameEnCtrl.text.trim();
                  final nameAr = nameArCtrl.text.trim();

                  if (nameEn.isEmpty || nameAr.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isRtl ? 'يرجى إدخال اسم الماركة بالإنجليزية والعربية' : 'Please fill in English and Arabic brand names.',
                        ),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  if (isEditing) {
                    final success = await ref.read(brandRepositoryProvider.notifier).updateBrand(
                          id: brand.id,
                          nameEn: nameEn,
                          nameAr: nameAr,
                          descriptionEn: descEnCtrl.text.trim().isNotEmpty ? descEnCtrl.text.trim() : null,
                          descriptionAr: descArCtrl.text.trim().isNotEmpty ? descArCtrl.text.trim() : null,
                          websiteUrl: websiteCtrl.text.trim().isNotEmpty ? websiteCtrl.text.trim() : null,
                          featured: isFeatured,
                          active: isActive,
                          categoryIds: selectedCategoryIds,
                          categoryObjects: selectedCategoryObjects,
                          logoFile: pickedLogoFile,
                          currentLogoUrl: brand.logoUrl,
                        );
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isRtl ? 'تم تحديث العلامة التجارية بنجاح.' : 'Brand updated successfully.'),
                          backgroundColor: const Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    final success = await ref.read(brandRepositoryProvider.notifier).createBrand(
                          nameEn: nameEn,
                          nameAr: nameAr,
                          descriptionEn: descEnCtrl.text.trim().isNotEmpty ? descEnCtrl.text.trim() : null,
                          descriptionAr: descArCtrl.text.trim().isNotEmpty ? descArCtrl.text.trim() : null,
                          websiteUrl: websiteCtrl.text.trim().isNotEmpty ? websiteCtrl.text.trim() : null,
                          featured: isFeatured,
                          active: isActive,
                          categoryIds: selectedCategoryIds,
                          categoryObjects: selectedCategoryObjects,
                          logoFile: pickedLogoFile,
                        );
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isRtl ? 'تمت إضافة العلامة التجارية بنجاح.' : 'Brand added successfully.'),
                          backgroundColor: const Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteBrandDialog(BuildContext context, Brand brand, bool isRtl, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 8),
            Text(
              isRtl ? 'هل أنت متأكد؟' : 'Are you sure?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          isRtl
              ? 'هل تريد حذف "${brand.nameAr}"؟ قد يؤثر ذلك على المنتجات والعروض المرتبطة بها.'
              : 'Do you want to delete "${brand.nameEn}"? This may affect linked products and offers.',
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(brandRepositoryProvider.notifier).deleteBrand(brand.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isRtl ? 'تم حذف العلامة التجارية.' : 'Brand has been deleted.'),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(isRtl ? 'نعم، احذفها!' : 'Yes, delete it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF16A34A)),
        const SizedBox(width: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
      ],
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

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    bool isRtl = false,
  }) {
    return TextField(
      controller: controller,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      style: TextStyle(
        fontSize: 12.5,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 11.5,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color(0xFF16A34A), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandState = ref.watch(brandRepositoryProvider);
    final allBrands = brandState.brands;
    final filteredBrands = _getFilteredBrands(allBrands);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () async {
            await Future.wait([
              ref.read(brandRepositoryProvider.notifier).fetchBrands(),
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
                // 1. Page Header
                _buildHeaderBlock(context, isRtl, isDark),
                const SizedBox(height: 14),

                // 2. Stats & Filters Card
                _buildNavAndFiltersCard(
                  allBrands: allBrands,
                  filteredCount: filteredBrands.length,
                  isRtl: isRtl,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // 3. Brands List or Empty State
                if (brandState.isLoading && allBrands.isEmpty) ...[
                  _buildLoadingState(isRtl, isDark),
                ] else if (filteredBrands.isEmpty) ...[
                  _buildEmptyState(isRtl, isDark),
                ] else ...[
                  _buildBrandsList(filteredBrands, isRtl, isDark),
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

  // 1. Page Header Block
  Widget _buildHeaderBlock(BuildContext context, bool isRtl, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final titleRow = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.verified, color: Color(0xFF16A34A), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'إدارة العلامات التجارية الشريكة' : 'Brand Partners',
                    style: TextStyle(
                      fontSize: isMobile ? 16.5 : 19.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isRtl
                        ? 'إدارة العلامات التجارية الموثقة والشعارات والتصنيفات والمواقع الرسمية.'
                        : 'Manage verified partner brands, logos, categories and official websites.',
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
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          icon: const Icon(Icons.add_circle, size: 16),
          label: Text(
            isRtl ? 'إضافة علامة تجارية' : 'Add New Brand',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
          onPressed: () => _showAddEditBrandModal(context, isRtl, isDark),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleRow,
              const SizedBox(height: 10),
              addButton,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleRow),
            const SizedBox(width: 14),
            addButton,
          ],
        );
      },
    );
  }

  // 2. Stats & Filter Toolbar
  Widget _buildNavAndFiltersCard({
    required List<Brand> allBrands,
    required int filteredCount,
    required bool isRtl,
    required bool isDark,
  }) {
    final activeCount = _getActiveCount(allBrands);
    final featuredCount = _getFeaturedCount(allBrands);
    final inactiveCount = _getInactiveCount(allBrands);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Filter Tabs & Showing Pill
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterTab(
                  label: isRtl ? 'جميع الماركات' : 'All Brands',
                  icon: Icons.loyalty,
                  count: allBrands.length,
                  filterKey: 'ALL',
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildFilterTab(
                  label: isRtl ? 'نشطة' : 'Active',
                  icon: Icons.check_circle,
                  count: activeCount,
                  filterKey: 'ACTIVE',
                  iconColor: const Color(0xFF16A34A),
                  pillBg: const Color(0xFF16A34A),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildFilterTab(
                  label: isRtl ? 'مميزة' : 'Featured',
                  icon: Icons.star,
                  count: featuredCount,
                  filterKey: 'FEATURED',
                  iconColor: const Color(0xFFF59E0B),
                  pillBg: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
                const SizedBox(width: 6),
                _buildFilterTab(
                  label: isRtl ? 'غير نشطة' : 'Inactive',
                  icon: Icons.pause_circle,
                  count: inactiveCount,
                  filterKey: 'INACTIVE',
                  iconColor: const Color(0xFF94A3B8),
                  pillBg: const Color(0xFF64748B),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Items Total Counter Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront, size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 5),
                Text(
                  isRtl
                      ? 'عرض $filteredCount من ${allBrands.length}'
                      : 'Showing $filteredCount of ${allBrands.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Search Bar
          SizedBox(
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
                    ? 'ابحث باسم الماركة، الاسم بالعربي، التصنيف أو المعرف...'
                    : 'Search brands by name, Arabic name, category or ID...',
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
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                  borderSide: BorderSide(color: Color(0xFF16A34A), width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required IconData icon,
    required int count,
    required String filterKey,
    Color? iconColor,
    Color? pillBg,
    required bool isDark,
  }) {
    final isSelected = _activeFilter == filterKey;
    return InkWell(
      onTap: () => setState(() {
        _activeFilter = filterKey;
        _displayedCount = 20;
      }),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCFCE7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF16A34A).withValues(alpha: 0.25) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFF16A34A) : (iconColor ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF16A34A) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF16A34A)
                    : (pillBg ?? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected || pillBg != null
                      ? Colors.white
                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading State
  Widget _buildLoadingState(bool isRtl, bool isDark) {
    return CrudLoadingWidget(
      titleEn: 'Loading Brand Catalogue & Profiles...',
      titleAr: 'جاري تحميل العلامات التجارية والملفات التعريفية...',
      subtitleEn: 'Fetching verified brands, logos and category tags...',
      subtitleAr: 'جاري جلب الماركات الموثقة والشعارات والأقسام المرتبطة...',
      icon: Icons.loyalty_rounded,
      isRtl: isRtl,
      isDark: isDark,
    );
  }

  // Empty State
  Widget _buildEmptyState(bool isRtl, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
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
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.loyalty, size: 24, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          Text(
            isRtl ? 'لا توجد علامات تجارية' : 'No brands found',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty || _activeFilter != 'ALL'
                ? (isRtl ? 'لم يتم العثور على أي علامات تجارية مطابقة لبحثك.' : 'No brands match your current search query.')
                : (isRtl ? 'لم يتم إضافة أي علامات تجارية بعد. أضف علامتك التجارية الأولى.' : 'No brand partners configured yet. Add your first brand partner.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          if (_searchQuery.isNotEmpty || _activeFilter != 'ALL') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.refresh, size: 14),
              label: Text(isRtl ? 'إعادة ضبط البحث' : 'Reset Filters', style: const TextStyle(fontSize: 11.5)),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _activeFilter = 'ALL';
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  // 3. Brands List Items (Pixel-perfect matching Angular with infinite scroll)
  Widget _buildBrandsList(List<Brand> brands, bool isRtl, bool isDark) {
    final displayedBrands = brands.take(_displayedCount).toList();

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayedBrands.length,
          separatorBuilder: (_, __) => const SizedBox(height: 7),
          itemBuilder: (context, index) {
            final b = displayedBrands[index];
            final logoUrl = AppConfig.normalizeImageUrl(b.logoUrl);

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left: Brand Logo Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: logoUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF16A34A)),
                                ),
                              ),
                              errorWidget: (_, __, ___) => const Icon(Icons.loyalty_outlined, color: Color(0xFF94A3B8), size: 20),
                            )
                          : const Icon(Icons.loyalty_outlined, color: Color(0xFF94A3B8), size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Middle: Identity, categories & website
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with ID and Featured badge
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                b.nameEn,
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
                                'ID: #${b.id}',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            if (b.featured) ...[
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
                          ],
                        ),
                        const SizedBox(height: 1),

                        // Arabic Name
                        Text(
                          b.nameAr,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),

                        // Categories & Website metadata row
                        if (b.categories.isNotEmpty || (b.websiteUrl != null && b.websiteUrl!.isNotEmpty)) ...[
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ...b.categories.take(3).map((c) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isRtl ? (c.nameAr.isNotEmpty ? c.nameAr : c.nameEn) : c.nameEn,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                );
                              }),
                              if (b.categories.length > 3)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '+${b.categories.length - 3}',
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                                  ),
                                ),
                              if (b.websiteUrl != null && b.websiteUrl!.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.language, size: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                    const SizedBox(width: 2),
                                    Text(
                                      b.websiteUrl!
                                          .replaceFirst('https://', '')
                                          .replaceFirst('http://', '')
                                          .replaceFirst('www.', '')
                                          .split('/')
                                          .first,
                                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Right Group: Active Pill & Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: b.active
                              ? const Color(0xFFDCFCE7)
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: b.active
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
                                color: b.active ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              b.active ? (isRtl ? 'نشط' : 'Active') : (isRtl ? 'غير نشط' : 'Inactive'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: b.active ? const Color(0xFF166534) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _showAddEditBrandModal(context, isRtl, isDark, b),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 15,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          InkWell(
                            onTap: () => _showDeleteBrandDialog(context, b, isRtl, isDark),
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.all(3),
                              child: Icon(
                                Icons.delete_outline,
                                size: 15,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
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
                    isRtl ? 'جاري تحميل المزيد من العلامات التجارية...' : 'Loading more brands...',
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
        ] else if (displayedBrands.length >= brands.length && brands.length > 20) ...[
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
                        ? 'تم عرض كافة العلامات التجارية (${brands.length})'
                        : 'All ${brands.length} brands loaded',
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
}
