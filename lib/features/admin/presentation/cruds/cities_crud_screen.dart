import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/city_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../models/models.dart';

import '../../../../core/widgets/location_picker_widget.dart';
import '../widgets/crud_loading_widget.dart';

class CitiesCrudScreen extends ConsumerStatefulWidget {
  const CitiesCrudScreen({super.key});

  @override
  ConsumerState<CitiesCrudScreen> createState() => _CitiesCrudScreenState();
}

class _CitiesCrudScreenState extends ConsumerState<CitiesCrudScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _copiedCityId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyCoords(double lat, double lng, int id, bool isRtl) {
    final text = '$lat, $lng';
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedCityId = id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRtl ? 'تم نسخ الإحداثيات: $text' : 'Coordinates copied: $text',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedCityId = null);
    });
  }

  Future<void> _openInMaps(double lat, double lng, String name) async {
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(googleMapsUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map for $name')),
        );
      }
    }
  }

  List<City> _filterCities(List<City> all) {
    if (_searchQuery.trim().isEmpty) return all;
    final q = _searchQuery.toLowerCase().trim();
    return all.where((c) {
      final nameEn = c.nameEn.toLowerCase();
      final nameAr = c.nameAr.toLowerCase();
      final region = c.regionCode.toLowerCase();
      return nameEn.contains(q) || nameAr.contains(q) || region.contains(q);
    }).toList();
  }

  void _showAddEditCityModal(BuildContext context, bool isRtl, bool isDark, [City? city]) {
    final isEditing = city != null;
    final nameEnCtrl = TextEditingController(text: city?.nameEn ?? '');
    final nameArCtrl = TextEditingController(text: city?.nameAr ?? '');
    final regionCtrl = TextEditingController(text: city?.regionCode ?? '');
    double selectedLat = city?.latitude != null && city!.latitude != 0.0 ? city.latitude : 24.7136;
    double selectedLng = city?.longitude != null && city!.longitude != 0.0 ? city.longitude : 46.6753;
    bool isActive = city == null ? true : city.isActive == 1;

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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_location_alt : Icons.add_location_alt,
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
                            ? (isRtl ? 'تعديل بيانات المدينة' : 'Edit City')
                            : (isRtl ? 'إضافة مدينة جديدة' : 'Add New City'),
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRtl
                            ? 'أدخل الاسم والرمز والإحداثيات الجغرافية.'
                            : 'Fill in names, region code and GPS coordinates.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
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
                    // Section 1: Names
                    _buildSectionLabel(isRtl ? 'أسماء المدينة' : 'CITY NAMES', isDark),
                    const SizedBox(height: 8),
                    _buildFieldLabel(isRtl ? 'الاسم بالإنجليزية *' : 'City Name (English) *', isDark),
                    const SizedBox(height: 4),
                    _buildTextField(nameEnCtrl, 'e.g. Riyadh', isDark),
                    const SizedBox(height: 10),
                    _buildFieldLabel(isRtl ? 'الاسم بالعربية *' : 'City Name (Arabic) *', isDark),
                    const SizedBox(height: 4),
                    _buildTextField(nameArCtrl, 'مثال: الرياض', isDark, isRtl: true),
                    const SizedBox(height: 16),

                    // Section 2: Region Code
                    _buildSectionLabel(isRtl ? 'رمز المنطقة' : 'REGION CODE', isDark),
                    const SizedBox(height: 8),
                    _buildFieldLabel(
                      isRtl ? 'رمز المنطقة أو المطار (RUH, JED, DMM...) *' : 'Region / Airport Code (RUH, JED, DMM…) *',
                      isDark,
                    ),
                    const SizedBox(height: 4),
                    _buildTextField(regionCtrl, 'RUH', isDark),
                    const SizedBox(height: 16),

                    // Section 3: GPS Coordinates & Map Center
                    _buildSectionLabel(isRtl ? 'الإحداثيات الجغرافية ومركز المدينة' : 'GPS COORDINATES & MAP CENTER', isDark),
                    const SizedBox(height: 8),
                    LocationPickerWidget(
                      initialLat: selectedLat,
                      initialLng: selectedLng,
                      height: 220,
                      isRtl: isRtl,
                      isDark: isDark,
                      onLocationChanged: (lat, lng) {
                        selectedLat = lat;
                        selectedLng = lng;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Section 4: Coverage Status Toggle
                    _buildSectionLabel(isRtl ? 'حالة التغطية' : 'COVERAGE STATUS', isDark),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
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
                                  isRtl ? 'تغطية نشطة' : 'Active Coverage',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  isRtl
                                      ? 'المتاجر والعروض تُربط بالمدن النشطة فقط.'
                                      : 'Stores and offers can be linked to active cities.',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.save, size: 18),
                label: Text(
                  isEditing
                      ? (isRtl ? 'حفظ التغييرات' : 'Save Changes')
                      : (isRtl ? 'إنشاء المدينة' : 'Create City'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: () async {
                  final nameEn = nameEnCtrl.text.trim();
                  final nameAr = nameArCtrl.text.trim();
                  final regionCode = regionCtrl.text.trim();
                  final lat = selectedLat;
                  final lng = selectedLng;

                  if (nameEn.isEmpty || nameAr.isEmpty || regionCode.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isRtl
                              ? 'يرجى ملء جميع الحقول المطلوبة'
                              : 'Please fill in all required fields.',
                        ),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  if (isEditing) {
                    await ref.read(cityRepositoryProvider.notifier).updateCity(
                          city.id,
                          nameEn,
                          nameAr,
                          regionCode,
                          lat,
                          lng,
                          isActive ? 1 : 0,
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isRtl ? 'تم تحديث المدينة بنجاح.' : 'City updated successfully.',
                          ),
                          backgroundColor: const Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    await ref.read(cityRepositoryProvider.notifier).createCity(
                          nameEn,
                          nameAr,
                          regionCode,
                          lat,
                          lng,
                          isActive ? 1 : 0,
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isRtl ? 'تم إضافة المدينة بنجاح.' : 'City added successfully.',
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

  void _showDeleteCityDialog(BuildContext context, City city, bool isRtl, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isRtl ? 'حذف المدينة؟' : 'Delete City?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isRtl
              ? 'هل أنت متأكد من حذف مدينة "${city.nameAr.isNotEmpty ? city.nameAr : city.nameEn}"؟ لن يتمكن التجار من ربط فروعهم بها.'
              : 'Are you sure you want to delete "${city.nameEn}"? Stores and offers will no longer be linked to this city.',
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            child: Text(isRtl ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(cityRepositoryProvider.notifier).deleteCity(city.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isRtl ? 'تم حذف المدينة.' : 'City has been deleted.'),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              isRtl ? 'نعم، احذفها' : 'Yes, Delete',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
      ),
    );
  }

  Widget _buildFieldLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cityState = ref.watch(cityRepositoryProvider);
    final allCities = cityState.cities;
    final filteredCities = _filterCities(allCities);

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () => ref.read(cityRepositoryProvider.notifier).fetchCities(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Page Header Block
                _buildHeaderBlock(context, isRtl, isDark),
                const SizedBox(height: 20),

                // 2. Toolbar (Search & Count)
                _buildToolbar(filteredCities.length, isRtl, isDark),
                const SizedBox(height: 20),

                // 3. Content List / Loading / Empty
                if (cityState.isLoading && allCities.isEmpty) ...[
                  _buildLoadingState(isRtl, isDark),
                ] else if (filteredCities.isEmpty) ...[
                  _buildEmptyState(isRtl, isDark),
                ] else ...[
                  _buildCitiesList(filteredCities, isRtl, isDark),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Page Header Block (Fully responsive on mobile and desktop)
  Widget _buildHeaderBlock(BuildContext context, bool isRtl, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final titleRow = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.travel_explore, color: Color(0xFF16A34A), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'إدارة المدن والمناطق' : 'Cities & Regions',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isRtl
                        ? 'إدارة مناطق التغطية والإحداثيات ورموز المناطق.'
                        : 'Manage coverage zones, coordinates & region codes.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          icon: const Icon(Icons.add_location_alt, size: 18),
          label: Text(
            isRtl ? 'إضافة مدينة' : 'Add City',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          onPressed: () => _showAddEditCityModal(context, isRtl, isDark),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleRow,
              const SizedBox(height: 14),
              addButton,
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleRow),
              const SizedBox(width: 16),
              addButton,
            ],
          );
        }
      },
    );
  }

  // 2. Toolbar
  Widget _buildToolbar(int count, bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  hintText: isRtl
                      ? 'ابحث بالاسم أو رمز المنطقة...'
                      : 'Search by name, Arabic name, or region code...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_city, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Text(
                  '$count ${isRtl ? 'مدينة' : 'cities'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Loading State
  Widget _buildLoadingState(bool isRtl, bool isDark) {
    return CrudLoadingWidget(
      titleEn: 'Loading Cities & Coverage Zones...',
      titleAr: 'جاري تحميل قائمة المدن ونطاقات التغطية...',
      subtitleEn: 'Fetching active coordinates and regional configurations...',
      subtitleAr: 'جاري جلب الإحداثيات والإعدادات الإقليمية من الخادم...',
      icon: Icons.location_city_rounded,
      isRtl: isRtl,
      isDark: isDark,
    );
  }

  // 4. Empty State
  Widget _buildEmptyState(bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 56,
            color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 14),
          Text(
            isRtl ? 'لا توجد مدن' : 'No cities found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? (isRtl ? 'لا توجد مدن مطابقة لبحثك.' : 'No cities match your search query.')
                : (isRtl ? 'لم يتم إضافة أي مدن حتى الآن.' : 'No cities have been configured yet. Add your first one.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16A34A),
                side: const BorderSide(color: Color(0xFF16A34A)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(isRtl ? 'مسح البحث' : 'Clear search'),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ],
        ],
      ),
    );
  }

  // 5. Unified Responsive Cities List
  Widget _buildCitiesList(List<City> cities, bool isRtl, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final city = cities[index];
        final isActive = city.isActive == 1;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? (isActive ? const Color(0xFF1E293B) : const Color(0xFF1E293B).withValues(alpha: 0.6))
                : (isActive ? Colors.white : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 440;

              final statusWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFDCFCE7))
                      : (isDark ? const Color(0xFF334155).withValues(alpha: 0.35) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isActive ? (isRtl ? 'نشط' : 'Active') : (isRtl ? 'غير نشط' : 'Inactive'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isActive ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              );

              final actionButtons = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18),
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    tooltip: isRtl ? 'فتح في الخريطة' : 'Open in Google Maps',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => _openInMaps(city.latitude, city.longitude, city.nameEn),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: const Color(0xFF2563EB),
                    tooltip: isRtl ? 'تعديل' : 'Edit',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => _showAddEditCityModal(context, isRtl, isDark, city),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: const Color(0xFFDC2626),
                    tooltip: isRtl ? 'حذف' : 'Delete',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => _showDeleteCityDialog(context, city, isRtl, isDark),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.place, color: Color(0xFF16A34A), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      city.nameEn,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      city.regionCode.isNotEmpty ? city.regionCode : 'SA',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                city.nameAr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        statusWidget,
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => _copyCoords(city.latitude, city.longitude, city.id, isRtl),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.my_location,
                                size: 12,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${city.latitude.toStringAsFixed(3)}, ${city.longitude.toStringAsFixed(3)}',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              if (_copiedCityId == city.id) ...[
                                const SizedBox(width: 4),
                                const Text(
                                  '✓ Copied',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        actionButtons,
                      ],
                    ),
                  ],
                );
              }

              // Desktop / Tablet layout
              return Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Icon(Icons.place, color: Color(0xFF16A34A), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              city.nameEn,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                city.regionCode.isNotEmpty ? city.regionCode : 'SA',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          city.nameAr,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _copyCoords(city.latitude, city.longitude, city.id, isRtl),
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.my_location,
                                size: 13,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${city.latitude.toStringAsFixed(4)}, ${city.longitude.toStringAsFixed(4)}',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (_copiedCityId == city.id)
                                const Text(
                                  '✓ Copied',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  statusWidget,
                  const SizedBox(width: 8),
                  actionButtons,
                ],
              );
            },
          ),
        );
      },
    );
  }
}
