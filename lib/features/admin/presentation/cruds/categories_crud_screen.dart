import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' hide Category;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/category_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../models/category.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../widgets/crud_loading_widget.dart';

class CategoriesCrudScreen extends ConsumerStatefulWidget {
  const CategoriesCrudScreen({super.key});

  @override
  ConsumerState<CategoriesCrudScreen> createState() => _CategoriesCrudScreenState();
}

class _CategoriesCrudScreenState extends ConsumerState<CategoriesCrudScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String _activeTab = 'parent'; // 'parent' or 'sub'
  int? _selectedParentFilter;
  bool _isSavingOrder = false;
  final ImagePicker _picker = ImagePicker();

  int _displayedCount = 20;
  bool _loadingMore = false;
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryRepositoryProvider.notifier).fetchCategories();
    });
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showScrollTop) {
        setState(() => _showScrollTop = show);
      }
      if (_scrollController.hasClients &&
          _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
        final allCategories = ref.read(categoryRepositoryProvider);
        final filtered = _getFilteredCategories(allCategories);
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

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  static const List<Map<String, String>> _commonIcons = [
    {'slug': 'shopping_bag', 'label': 'Shopping'},
    {'slug': 'restaurant', 'label': 'Food'},
    {'slug': 'devices', 'label': 'Electronics'},
    {'slug': 'local_offer', 'label': 'Offers'},
    {'slug': 'checkroom', 'label': 'Fashion'},
    {'slug': 'directions_car', 'label': 'Auto'},
    {'slug': 'sports_esports', 'label': 'Gaming'},
    {'slug': 'home', 'label': 'Home'},
    {'slug': 'fitness_center', 'label': 'Fitness'},
    {'slug': 'pets', 'label': 'Pets'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  IconData _getIconData(String slug) {
    switch (slug.toLowerCase().trim()) {
      case 'shopping_bag':
      case 'shopping_cart':
        return Icons.shopping_bag_outlined;
      case 'restaurant':
      case 'food':
        return Icons.restaurant_outlined;
      case 'devices':
      case 'electronics':
      case 'phone':
        return Icons.devices_outlined;
      case 'local_offer':
      case 'offer':
      case 'tag':
        return Icons.local_offer_outlined;
      case 'checkroom':
      case 'fashion':
      case 'clothes':
        return Icons.checkroom_outlined;
      case 'directions_car':
      case 'car':
      case 'auto':
        return Icons.directions_car_outlined;
      case 'sports_esports':
      case 'gaming':
      case 'games':
        return Icons.sports_esports_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'fitness_center':
      case 'gym':
        return Icons.fitness_center_outlined;
      case 'pets':
        return Icons.pets_outlined;
      case 'flight':
      case 'travel':
        return Icons.flight_outlined;
      case 'hotel':
        return Icons.hotel_outlined;
      case 'local_hospital':
      case 'health':
        return Icons.local_hospital_outlined;
      case 'movie':
      case 'entertainment':
        return Icons.movie_outlined;
      case 'book':
        return Icons.book_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  List<Category> _getParentCategories(List<Category> all) {
    return all.where((Category c) => c.parentId == null).toList()
      ..sort((Category a, Category b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<Category> _getSubCategories(List<Category> all) {
    return all.where((Category c) => c.parentId != null).toList()
      ..sort((Category a, Category b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<Category> _getFilteredCategories(List<Category> all) {
    List<Category> list;
    if (_activeTab == 'parent') {
      list = _getParentCategories(all);
    } else {
      list = _getSubCategories(all);
      if (_selectedParentFilter != null) {
        list = list.where((Category c) => c.parentId == _selectedParentFilter).toList();
      }
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((Category c) {
        final nameEn = c.nameEn.toLowerCase();
        final nameAr = c.nameAr.toLowerCase();
        final slug = c.iconSlug.toLowerCase();
        return nameEn.contains(q) || nameAr.contains(q) || slug.contains(q);
      }).toList();
    }

    return list;
  }

  Future<void> _moveItem(int currentIndex, int targetIndex, List<Category> displayedList, bool isRtl) async {
    if (targetIndex < 0 || targetIndex >= displayedList.length || currentIndex == targetIndex) return;

    final reordered = List<Category>.from(displayedList);
    final item = reordered.removeAt(currentIndex);
    reordered.insert(targetIndex, item);

    final updatedList = <Category>[];
    for (int i = 0; i < reordered.length; i++) {
      updatedList.add(reordered[i].copyWith(sortOrder: i + 1));
    }

    setState(() => _isSavingOrder = true);
    final success = await ref.read(categoryRepositoryProvider.notifier).reorderCategories(updatedList);
    if (mounted) {
      setState(() => _isSavingOrder = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isRtl ? 'تم حفظ الترتيب بنجاح' : 'Category order saved!'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    }
  }

  void _showAddEditCategoryModal(BuildContext context, bool isRtl, bool isDark, [Category? cat]) {
    final isEditing = cat != null;
    final allCategories = ref.read(categoryRepositoryProvider);
    final parentCategories = _getParentCategories(allCategories);

    final nameEnCtrl = TextEditingController(text: cat?.nameEn ?? '');
    final nameArCtrl = TextEditingController(text: cat?.nameAr ?? '');
    final iconSlugCtrl = TextEditingController(text: cat?.iconSlug ?? 'folder');
    final sortOrderCtrl = TextEditingController(
      text: cat?.sortOrder.toString() ??
          (_activeTab == 'parent' ? (parentCategories.length + 1).toString() : (_getSubCategories(allCategories).length + 1).toString()),
    );

    final availableParents = parentCategories.where((Category p) => cat == null || p.id != cat.id).toList();
    int? selectedParentId = (cat?.parentId != null && availableParents.any((p) => p.id == cat!.parentId))
        ? cat!.parentId
        : (_activeTab == 'sub' ? (_selectedParentFilter != null && availableParents.any((p) => p.id == _selectedParentFilter) ? _selectedParentFilter : (availableParents.isNotEmpty ? availableParents.first.id : null)) : null);
    bool isActive = cat == null ? true : cat.isActive == 1;
    XFile? pickedImage;
    Uint8List? pickedImageBytes;
    String existingImageUrl = cat != null ? AppConfig.normalizeImageUrl(cat.imageUrl) : '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
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
                    isEditing ? Icons.edit : Icons.add_box_outlined,
                    color: const Color(0xFF16A34A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing
                            ? (isRtl ? 'تعديل بيانات الفئة' : 'Edit Category')
                            : (isRtl ? 'إضافة فئة جديدة' : 'Add New Category'),
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRtl
                            ? 'إدخال مسميات الفئة، التسلسل الهرمي، وترتيب العرض والأيقونة.'
                            : 'Configure titles, hierarchy, sort order, and visual icon.',
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
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Basic Information / Category Names
                    _buildSectionLabel(isRtl ? 'مسميات الفئة' : 'CATEGORY NAMES', isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(isRtl ? 'اسم الفئة (بالإنجليزية) *' : 'Category Name (EN) *', isDark),
                              const SizedBox(height: 4),
                              _buildTextField(nameEnCtrl, 'e.g. Electronics', isDark),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(isRtl ? 'اسم الفئة (بالعربية) *' : 'Category Name (AR) *', isDark),
                              const SizedBox(height: 4),
                              _buildTextField(nameArCtrl, 'مثال: الإلكترونيات', isDark, isRtl: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 2: Hierarchy & Sorting
                    _buildSectionLabel(isRtl ? 'التسلسل الهرمي والترتيب' : 'HIERARCHY & SORTING', isDark),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Parent Category Picker Dropdown
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(isRtl ? 'القسم الرئيسي' : 'Parent Category', isDark),
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
                                    value: selectedParentId,
                                    isExpanded: true,
                                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF16A34A), size: 20),
                                    items: [
                                      DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text(
                                          isRtl ? 'بدون (قسم رئيسي)' : 'None (Root Category)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      ...parentCategories
                                          .where((Category p) => cat == null || p.id != cat.id)
                                          .map((Category p) => DropdownMenuItem<int?>(
                                                value: p.id,
                                                child: Text(
                                                  isRtl ? '${p.nameAr} (${p.nameEn})' : '${p.nameEn} (${p.nameAr})',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              )),
                                    ],
                                    onChanged: (val) => setModalState(() => selectedParentId = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Sort Order Input
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(isRtl ? 'ترتيب الظهور *' : 'Display Sort Order *', isDark),
                              const SizedBox(height: 4),
                              _buildTextField(sortOrderCtrl, '1', isDark, isNumber: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Section 3: Icon & Media Asset (Matching Angular exactly)
                    _buildSectionLabel(isRtl ? 'الأيقونة والصورة' : 'ICON & MEDIA ASSET', isDark),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Material Icon Slug Input + Preview
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(isRtl ? 'رمز الأيقونة (Material Icon) *' : 'Material Icon Slug *', isDark),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Icon(
                                      _getIconData(iconSlugCtrl.text),
                                      color: const Color(0xFF16A34A),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: TextField(
                                      controller: iconSlugCtrl,
                                      onChanged: (_) => setModalState(() {}),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'folder, shopping_bag...',
                                        hintStyle: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Right: Category Image File Upload (Angular file upload trigger & preview)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel(isRtl ? 'صورة الفئة (اختياري)' : 'Category Image (Optional)', isDark),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // Choose Image Button
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        try {
                                          final file = await _picker.pickImage(source: ImageSource.gallery);
                                          if (file != null) {
                                            final bytes = await file.readAsBytes();
                                            setModalState(() {
                                              pickedImage = file;
                                              pickedImageBytes = bytes;
                                            });
                                          }
                                        } catch (_) {}
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 38,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.cloud_upload_outlined, size: 16, color: Color(0xFF16A34A)),
                                            const SizedBox(width: 5),
                                            Flexible(
                                              child: Text(
                                                pickedImage != null
                                                    ? (isRtl ? 'تم اختيار صورة' : 'Image Selected')
                                                    : (isRtl ? 'اختر صورة' : 'Choose Image'),
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

                                  // Preview Thumbnail
                                  if (pickedImageBytes != null || existingImageUrl.isNotEmpty) ...[
                                    const SizedBox(width: 6),
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
                                          child: pickedImageBytes != null
                                              ? Image.memory(pickedImageBytes!, fit: BoxFit.cover)
                                              : AppNetworkImage(
                                                  imageUrl: existingImageUrl,
                                                  fit: BoxFit.cover,
                                                  defaultFallbackIcon: Icons.category_outlined,
                                                  fallbackIconSize: 18,
                                                ),
                                        ),
                                        if (pickedImage != null)
                                          Positioned(
                                            top: -2,
                                            right: -2,
                                            child: InkWell(
                                              onTap: () {
                                                setModalState(() {
                                                  pickedImage = null;
                                                  pickedImageBytes = null;
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
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Quick Icon suggestions
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: _commonIcons.map((ic) {
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          backgroundColor: iconSlugCtrl.text == ic['slug']
                              ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                          side: BorderSide(
                            color: iconSlugCtrl.text == ic['slug']
                                ? const Color(0xFF16A34A)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          avatar: Icon(_getIconData(ic['slug']!), size: 13, color: const Color(0xFF16A34A)),
                          label: Text(
                            ic['label']!,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                          onPressed: () {
                            setModalState(() {
                              iconSlugCtrl.text = ic['slug']!;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Section 4: Visibility & Status (Exact Angular Toggle)
                    _buildSectionLabel(isRtl ? 'الحالة والظهور' : 'VISIBILITY & STATUS', isDark),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Switch(
                            value: isActive,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (val) => setModalState(() => isActive = val),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRtl ? 'حالة الفئة النشطة' : 'Active Status',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  isRtl
                                      ? 'الفئات النشطة تظهر في واجهة المستخدم وقوائم التصفية.'
                                      : 'Active categories appear across customer search filters and storefront catalogs.',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
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
                      : (isRtl ? 'إنشاء الفئة' : 'Create Category'),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                onPressed: () async {
                  final nameEn = nameEnCtrl.text.trim();
                  final nameAr = nameArCtrl.text.trim();
                  final iconSlug = iconSlugCtrl.text.trim().isEmpty ? 'folder' : iconSlugCtrl.text.trim();
                  final sortOrder = int.tryParse(sortOrderCtrl.text.trim()) ?? 1;

                  if (nameEn.isEmpty || nameAr.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isRtl ? 'يرجى إدخال اسم الفئة بالإنجليزية والعربية' : 'Please fill in English and Arabic category names.',
                        ),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                    return;
                  }

                  // Duplicate check
                  final isDuplicate = allCategories.any((c) {
                    if (isEditing && c.id == cat.id) return false;
                    return c.nameEn.toLowerCase().trim() == nameEn.toLowerCase() ||
                        c.nameAr.toLowerCase().trim() == nameAr.toLowerCase();
                  });

                  if (isDuplicate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isRtl
                              ? 'توجد فئة بهذا الاسم العربي أو الإنجليزي مسبقاً!'
                              : 'A category with this English or Arabic name already exists!',
                        ),
                        backgroundColor: const Color(0xFFF59E0B),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  if (isEditing) {
                    final success = await ref.read(categoryRepositoryProvider.notifier).updateCategory(
                          id: cat.id,
                          nameEn: nameEn,
                          nameAr: nameAr,
                          iconSlug: iconSlug,
                          sortOrder: sortOrder,
                          isActive: isActive ? 1 : 0,
                          parentId: selectedParentId,
                          imageFile: pickedImage,
                        );
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isRtl ? 'تم تعديل الفئة بنجاح.' : 'Category updated successfully.',
                          ),
                          backgroundColor: const Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    final success = await ref.read(categoryRepositoryProvider.notifier).createCategory(
                          nameEn: nameEn,
                          nameAr: nameAr,
                          iconSlug: iconSlug,
                          sortOrder: sortOrder,
                          isActive: isActive ? 1 : 0,
                          parentId: selectedParentId,
                          imageFile: pickedImage,
                        );
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isRtl ? 'تم إنشاء الفئة بنجاح.' : 'Category created successfully.',
                          ),
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

  void _showDeleteCategoryDialog(BuildContext context, Category cat, bool isRtl, bool isDark) {
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
              isRtl ? 'تأكيد الحذف' : 'Delete Category?',
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
              ? 'هل أنت متأكد من حذف "${cat.nameAr}"؟ قد يؤثر ذلك على المنتجات والعروض المرتبطة بها.'
              : 'Are you sure you want to delete "${cat.nameEn}"? This may affect linked products and offers.',
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
              final success = await ref.read(categoryRepositoryProvider.notifier).deleteCategory(cat.id);
              if (mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isRtl ? 'تم حذف الفئة بنجاح.' : 'Category deleted successfully.',
                    ),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(isRtl ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
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

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    bool isRtl = false,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: false) : TextInputType.text,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCategories = ref.watch(categoryRepositoryProvider);
    final parentCategories = _getParentCategories(allCategories);
    final subCategories = _getSubCategories(allCategories);
    final filteredCategories = _getFilteredCategories(allCategories);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () => ref.read(categoryRepositoryProvider.notifier).fetchCategories(),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Page Header Block
                _buildHeaderBlock(context, isRtl, isDark),
                const SizedBox(height: 14),

                // 2. Tabs & Filter Toolbar
                _buildNavAndFiltersCard(parentCategories.length, subCategories.length, parentCategories, filteredCategories.length, isRtl, isDark),
                const SizedBox(height: 12),

                // 3. Reorder Info Banner
                _buildReorderBanner(isRtl, isDark),
                const SizedBox(height: 12),

                // 4. Content List / Loading State / Empty State
                if (allCategories.isEmpty && ref.read(categoryRepositoryProvider.notifier).isLoading) ...[
                  _buildLoadingState(isRtl, isDark),
                ] else if (filteredCategories.isEmpty) ...[
                  _buildEmptyState(isRtl, isDark),
                ] else ...[
                  _buildCategoriesList(filteredCategories, parentCategories, isRtl, isDark),
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

  // 1. Header Block
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
                border: Border.all(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                ),
              ),
              child: const Icon(Icons.category, color: Color(0xFF16A34A), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'إدارة الفئات والأقسام' : 'Categories Management',
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
                        ? 'تنظيم وتصنيف المنتجات والعروض، الأقسام وترتيب الظهور.'
                        : 'Organize catalog hierarchy, parent categories, and display order.',
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
          icon: const Icon(Icons.add_circle_outline, size: 16),
          label: Text(
            isRtl ? 'إضافة فئة جديدة' : 'Add Category',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
          onPressed: () => _showAddEditCategoryModal(context, isRtl, isDark),
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

  Widget _buildNavAndFiltersCard(
    int parentCount,
    int subCount,
    List<Category> parentCategories,
    int filteredCount,
    bool isRtl,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Tabs (Parent vs Sub)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Parent Tab
                InkWell(
                  onTap: () => setState(() {
                    _activeTab = 'parent';
                    _displayedCount = 20;
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _activeTab == 'parent'
                          ? const Color(0xFFDCFCE7)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _activeTab == 'parent'
                            ? const Color(0xFF16A34A).withValues(alpha: 0.25)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder,
                          size: 15,
                          color: _activeTab == 'parent'
                              ? const Color(0xFF16A34A)
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isRtl ? 'الأقسام الرئيسية' : 'Parent Categories',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _activeTab == 'parent' ? FontWeight.w800 : FontWeight.w600,
                            color: _activeTab == 'parent'
                                ? const Color(0xFF16A34A)
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _activeTab == 'parent'
                                ? const Color(0xFF16A34A)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$parentCount',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _activeTab == 'parent'
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Subcategories Tab
                InkWell(
                  onTap: () => setState(() {
                    _activeTab = 'sub';
                    _displayedCount = 20;
                  }),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _activeTab == 'sub'
                          ? const Color(0xFFDCFCE7)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _activeTab == 'sub'
                            ? const Color(0xFF16A34A).withValues(alpha: 0.25)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          size: 15,
                          color: _activeTab == 'sub'
                              ? const Color(0xFF16A34A)
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isRtl ? 'الأقسام الفرعية' : 'Subcategories',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _activeTab == 'sub' ? FontWeight.w800 : FontWeight.w600,
                            color: _activeTab == 'sub'
                                ? const Color(0xFF16A34A)
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _activeTab == 'sub'
                                ? const Color(0xFF16A34A)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$subCount',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _activeTab == 'sub'
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Total Items Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.layers,
                  size: 14,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(width: 5),
                Text(
                  '$filteredCount ${isRtl ? 'عنصر' : 'Items'}',
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

          // Filters Row
          Row(
            children: [
              Expanded(
                child: SizedBox(
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
                      hintText: isRtl ? 'ابحث باسم الفئة (AR/EN)...' : 'Search by category name (EN/AR)...',
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
                                setState(() {
                                  _searchQuery = '';
                                  _displayedCount = 20;
                                });
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
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),

              if (_activeTab == 'sub') ...[
                const SizedBox(width: 6),
                Container(
                  height: 36,
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
                      value: _selectedParentFilter,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      icon: const Icon(Icons.filter_list, size: 15, color: Color(0xFF16A34A)),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            isRtl ? 'جميع الأقسام الرئيسية' : 'All Parent Categories',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        ...parentCategories.map((Category p) => DropdownMenuItem<int?>(
                              value: p.id,
                              child: Text(
                                isRtl ? p.nameAr : p.nameEn,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            )),
                      ],
                      onChanged: (val) => setState(() {
                        _selectedParentFilter = val;
                        _displayedCount = 20;
                      }),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 3. Reorder Info Banner
  Widget _buildReorderBanner(bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF059669).withValues(alpha: 0.3) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_vert, size: 16, color: Color(0xFF16A34A)),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                ),
                children: [
                  TextSpan(
                    text: isRtl ? 'ترتيب الفئات: ' : 'Display Reordering: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: isRtl
                        ? 'استخدم الأسهم (▲ ▼) لحفظ الترتيب تلقائياً.'
                        : 'Drag handles (⋮⋮) or tap (▲ ▼) arrows to reorder.',
                  ),
                ],
              ),
            ),
          ),
          if (_isSavingOrder) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF15803D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 9,
                    height: 9,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isRtl ? 'جاري الحفظ...' : 'Saving...',
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 4. Loading State
  Widget _buildLoadingState(bool isRtl, bool isDark) {
    return CrudLoadingWidget(
      titleEn: 'Loading Categories & Taxonomy...',
      titleAr: 'جاري تحميل الأقسام وهيكل التصنيفات...',
      subtitleEn: 'Fetching category hierarchy and assigned icons...',
      subtitleAr: 'جاري جلب هيكلية الأقسام والأيقونات المخصصة...',
      icon: Icons.category_rounded,
      isRtl: isRtl,
      isDark: isDark,
    );
  }

  // 4. Empty State
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
            child: const Icon(Icons.category_outlined, size: 24, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          Text(
            isRtl ? 'لم يتم العثور على أي فئات' : 'No Categories Found',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty || _selectedParentFilter != null
                ? (isRtl ? 'لا توجد فئات مطابقة للبحث أو الفلتر المحدد.' : 'No categories match your active filter or search query.')
                : (isRtl ? 'لم يتم تكوين أي فئات حتى الآن. انقر على "إضافة فئة" للبدء.' : 'No categories configured yet. Click "Add Category" to get started.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          if (_searchQuery.isNotEmpty || _selectedParentFilter != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.refresh, size: 14),
              label: Text(isRtl ? 'إعادة ضبط الفلاتر' : 'Reset Filters', style: const TextStyle(fontSize: 11.5)),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedParentFilter = null;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  // 5. Category Card (with infinite scroll pagination)
  Widget _buildCategoriesList(
    List<Category> displayedCategories,
    List<Category> parentCategories,
    bool isRtl,
    bool isDark,
  ) {
    final itemsToRender = displayedCategories.take(_displayedCount).toList();

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemsToRender.length,
          separatorBuilder: (_, __) => const SizedBox(height: 7),
          itemBuilder: (context, index) {
            final cat = itemsToRender[index];
            final isActive = cat.isActive == 1;

            final parent = cat.parentId != null
                ? parentCategories.firstWhere((Category p) => p.id == cat.parentId, orElse: () => cat)
                : null;

            final normalizedImg = AppConfig.normalizeImageUrl(cat.imageUrl);

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Drag Handle & Mini Reorder Arrows
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: index > 0
                            ? () => _moveItem(index, index - 1, displayedCategories, isRtl)
                            : null,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.arrow_drop_up,
                            size: 16,
                            color: index > 0
                                ? const Color(0xFF16A34A)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: index < displayedCategories.length - 1
                            ? () => _moveItem(index, index + 1, displayedCategories, isRtl)
                            : null,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: index < displayedCategories.length - 1
                                ? const Color(0xFF16A34A)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),

                  // Media Avatar Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: AppNetworkImage(
                        imageUrl: normalizedImg,
                        fit: BoxFit.cover,
                        defaultFallbackIcon: _getIconData(cat.iconSlug),
                        fallbackIconSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Category Names & Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with sort order & slug pill
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                cat.nameEn,
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
                                '#${cat.sortOrder}',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  cat.iconSlug,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),

                        // Arabic Name
                        Text(
                          cat.nameAr,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),

                        // Subcategory parent indicator
                        if (parent != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.subdirectory_arrow_right,
                                size: 12,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  '${isRtl ? 'تابع لقسم' : 'Child of'}: ${isRtl ? parent.nameAr : parent.nameEn}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Right Stack: Status Badge & Actions
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFDCFCE7)
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
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
                                color: isActive ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isActive ? (isRtl ? 'نشط' : 'Active') : (isRtl ? 'غير نشط' : 'Inactive'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isActive ? const Color(0xFF166534) : const Color(0xFF64748B),
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
                            onTap: () => _showAddEditCategoryModal(context, isRtl, isDark, cat),
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
                            onTap: () => _showDeleteCategoryDialog(context, cat, isRtl, isDark),
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
                    isRtl ? 'جاري تحميل المزيد من الفئات...' : 'Loading more categories...',
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
        ] else if (itemsToRender.length >= displayedCategories.length && displayedCategories.length > 20) ...[
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
                        ? 'تم عرض كافة الفئات (${displayedCategories.length})'
                        : 'All ${displayedCategories.length} categories loaded',
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
