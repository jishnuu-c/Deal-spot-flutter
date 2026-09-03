import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/store_repository.dart';
import '../../../../core/services/city_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../models/models.dart';
import '../../../../core/widgets/location_picker_widget.dart';
import '../widgets/crud_loading_widget.dart';

class BranchesCrudScreen extends ConsumerStatefulWidget {
  final int storeId;

  const BranchesCrudScreen({super.key, required this.storeId});

  @override
  ConsumerState<BranchesCrudScreen> createState() => _BranchesCrudScreenState();
}

class _BranchesCrudScreenState extends ConsumerState<BranchesCrudScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  int? _selectedCityFilter;
  String _selectedStatusFilter = ''; // '', 'active', 'inactive', '247'

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<StoreBranch> _getFilteredBranches(List<StoreBranch> allBranches) {
    final query = _searchQuery.toLowerCase().trim();
    var list = allBranches;

    if (query.isNotEmpty) {
      list = list.where((b) {
        final name = b.branchName.toLowerCase();
        final addr = (b.addressLine ?? '').toLowerCase();
        final city = (b.cityNameEn ?? b.city?.nameEn ?? '').toLowerCase();
        final cityAr = (b.cityNameAr ?? b.city?.nameAr ?? '').toLowerCase();
        final phone = (b.contactPhone ?? '').toLowerCase();
        return name.contains(query) ||
            addr.contains(query) ||
            city.contains(query) ||
            cityAr.contains(query) ||
            phone.contains(query);
      }).toList();
    }

    if (_selectedCityFilter != null) {
      list = list.where((b) => b.cityId == _selectedCityFilter).toList();
    }

    if (_selectedStatusFilter == 'active') {
      list = list.where((b) => b.active).toList();
    } else if (_selectedStatusFilter == 'inactive') {
      list = list.where((b) => !b.active).toList();
    } else if (_selectedStatusFilter == '247') {
      list = list.where((b) => b.openTime == '00:00:00' && b.closeTime == '23:59:59').toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storeState = ref.watch(storeRepositoryProvider);
    final storeNotifier = ref.watch(storeRepositoryProvider.notifier);
    final store = storeNotifier.getStoreById(widget.storeId);
    final allBranches = storeNotifier.getBranchesForStore(widget.storeId);
    final cities = ref.watch(cityRepositoryProvider).cities;

    final filteredBranches = _getFilteredBranches(allBranches);

    final totalCount = allBranches.length;
    final activeCount = allBranches.where((b) => b.active).length;
    final twentyFourSevenCount = allBranches
        .where((b) => b.openTime == '00:00:00' && b.closeTime == '23:59:59')
        .length;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () async {
            await Future.wait([
              ref.read(storeRepositoryProvider.notifier).fetchBranchesForStore(widget.storeId),
              ref.read(cityRepositoryProvider.notifier).fetchCities(),
            ]);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header with Back Button, Store Profile, and Add Branch Button
                _buildHeaderBlock(context, store, isRtl, isDark, cities),
                const SizedBox(height: 14),

                // 2. Stats Grid
                _buildStatsGrid(
                  totalCount: totalCount,
                  activeCount: activeCount,
                  twentyFourSevenCount: twentyFourSevenCount,
                  isRtl: isRtl,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // 3. Search & Filter Toolbar
                _buildFilterToolbar(
                  filteredCount: filteredBranches.length,
                  cities: cities,
                  isRtl: isRtl,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // 4. Branches List / Loading / Empty
                if (storeState.isLoading && allBranches.isEmpty) ...[
                  _buildLoadingState(isRtl, isDark),
                ] else if (filteredBranches.isEmpty) ...[
                  _buildEmptyState(isRtl, isDark),
                ] else ...[
                  _buildBranchesList(filteredBranches, cities, isRtl, isDark),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Header Block with Back Button to Stores
  Widget _buildHeaderBlock(
    BuildContext context,
    Store? store,
    bool isRtl,
    bool isDark,
    List<City> cities,
  ) {
    final logoUrl = AppConfig.normalizeImageUrl(store?.logoUrl);
    final storeName = isRtl
        ? (store?.nameAr ?? store?.nameEn ?? 'Store #${widget.storeId}')
        : (store?.nameEn ?? store?.nameAr ?? 'Store #${widget.storeId}');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          final titleRow = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back Button to Stores
              Material(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => context.go('/admin/stores'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Icon(
                      isRtl ? Icons.arrow_forward : Icons.arrow_back,
                      size: 20,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Store Avatar
              if (logoUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.storefront, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isRtl ? 'إدارة الفروع' : 'Branch Management',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isRtl ? "فروع متجر" : "Branches for"} $storeName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final addBtn = ElevatedButton.icon(
            onPressed: () => _showAddEditBranchModal(context, isRtl, isDark, cities),
            icon: const Icon(Icons.add_location_alt, size: 16),
            label: Text(
              isRtl ? 'إضافة فرع جديد' : 'Add New Branch',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
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
                titleRow,
                const SizedBox(height: 10),
                addBtn,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleRow),
              const SizedBox(width: 12),
              addBtn,
            ],
          );
        },
      ),
    );
  }

  // 2. Stats Grid
  Widget _buildStatsGrid({
    required int totalCount,
    required int activeCount,
    required int twentyFourSevenCount,
    required bool isRtl,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.location_city,
            iconColor: const Color(0xFF2563EB),
            bgColor: const Color(0xFFDBEAFE),
            count: totalCount,
            label: isRtl ? 'إجمالي الفروع' : 'Total Branches',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF16A34A),
            bgColor: const Color(0xFFDCFCE7),
            count: activeCount,
            label: isRtl ? 'فروع نشطة' : 'Active Branches',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            iconColor: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
            count: twentyFourSevenCount,
            label: isRtl ? 'فروع 24 ساعة' : '24/7 Branches',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required int count,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    );
  }

  // 3. Search and Filter Toolbar
  Widget _buildFilterToolbar({
    required int filteredCount,
    required List<City> cities,
    required bool isRtl,
    required bool isDark,
  }) {
    final uniqueCities = <int, City>{};
    for (final c in cities) {
      uniqueCities[c.id] = c;
    }
    final safeCities = uniqueCities.values.toList();
    final validCity = safeCities.any((c) => c.id == _selectedCityFilter) ? _selectedCityFilter : null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: isRtl
                          ? 'ابحث باسم الفرع، العنوان، المدينة...'
                          : 'Search by branch name, address, city...',
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
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                        borderSide: BorderSide(color: Color(0xFF16A34A), width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 4),
                    Text(
                      '$filteredCount ${isRtl ? 'فرع' : 'branches'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // City Filter
              Expanded(
                child: Container(
                  height: 34,
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
                      value: validCity,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      icon: const Icon(Icons.place, size: 14, color: Color(0xFF16A34A)),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            isRtl ? 'جميع المدن' : 'All Cities',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        ...safeCities.map((City c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(
                                isRtl ? c.nameAr : c.nameEn,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            )),
                      ],
                      onChanged: (val) => setState(() => _selectedCityFilter = val),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Status Filter
              Expanded(
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      icon: const Icon(Icons.tune, size: 14, color: Color(0xFF16A34A)),
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text(
                            isRtl ? 'جميع الحالات' : 'All Statuses',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'active',
                          child: Text(
                            isRtl ? 'نشط فقط' : 'Active Only',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'inactive',
                          child: Text(
                            isRtl ? 'معطل فقط' : 'Inactive Only',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: '247',
                          child: Text(
                            isRtl ? 'مفتوح 24/7' : 'Open 24/7',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _selectedStatusFilter = val ?? ''),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Loading State
  Widget _buildLoadingState(bool isRtl, bool isDark) {
    return CrudLoadingWidget(
      titleEn: 'Loading Branch Directory...',
      titleAr: 'جاري تحميل فروع المتجر...',
      subtitleEn: 'Fetching locations, working hours and GPS coordinates...',
      subtitleAr: 'جاري جلب المواقع وساعات العمل وإحداثيات الخريطة...',
      icon: Icons.location_city_rounded,
      isRtl: isRtl,
      isDark: isDark,
    );
  }

  // 5. Empty State
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
            child: const Icon(Icons.location_off_outlined, size: 24, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          Text(
            isRtl ? 'لم يتم العثور على أي فروع' : 'No Branches Found',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isRtl
                ? 'قم بإضافة فرع جديد للمتجر أو عدّل خيارات البحث.'
                : 'Add a new branch for this store or adjust search filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Branches List
  Widget _buildBranchesList(
    List<StoreBranch> branches,
    List<City> cities,
    bool isRtl,
    bool isDark,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: branches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final b = branches[index];
        final cityName = isRtl
            ? (b.cityNameAr ?? b.city?.nameAr ?? b.cityNameEn ?? b.city?.nameEn ?? '')
            : (b.cityNameEn ?? b.city?.nameEn ?? b.cityNameAr ?? b.city?.nameAr ?? '');
        final is247 = b.openTime == '00:00:00' && b.closeTime == '23:59:59';

        return Material(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Location Pin Icon Box
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: b.active
                        ? const Color(0xFFDCFCE7)
                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: b.active
                          ? const Color(0xFF16A34A).withValues(alpha: 0.25)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: b.active ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),

                // Middle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              b.branchName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (cityName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cityName,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Address / Details
                      if (b.addressLine != null && b.addressLine!.isNotEmpty) ...[
                        Text(
                          b.addressLine!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],

                      // Working Hours & Coordinates
                      Wrap(
                        spacing: 6,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule, size: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                const SizedBox(width: 2),
                                Text(
                                  is247 ? (isRtl ? '24/7' : '24/7') : '${b.openTime.substring(0, 5)} - ${b.closeTime.substring(0, 5)}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: is247 ? const Color(0xFFD97706) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (b.contactPhone != null && b.contactPhone!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.phone, size: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  const SizedBox(width: 2),
                                  Text(
                                    b.contactPhone!,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${b.latitude.toStringAsFixed(2)}, ${b.longitude.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 9,
                                fontFamily: 'monospace',
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right Group: Status Pill & Action Buttons matching Angular
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                            b.active ? (isRtl ? 'نشط' : 'Active') : (isRtl ? 'معطل' : 'Inactive'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: b.active ? const Color(0xFF166534) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Action Buttons (Edit, Delete) matching .btn-item-action
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: isRtl ? 'تعديل الفرع' : 'Edit Branch',
                          child: Material(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(7),
                            child: InkWell(
                              onTap: () => _showAddEditBranchModal(context, isRtl, isDark, cities, b),
                              borderRadius: BorderRadius.circular(7),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 15,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),

                        Tooltip(
                          message: isRtl ? 'حذف الفرع' : 'Delete Branch',
                          child: Material(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(7),
                            child: InkWell(
                              onTap: () => _showDeleteBranchDialog(context, b, isRtl, isDark),
                              borderRadius: BorderRadius.circular(7),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 15,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add / Edit Branch Modal (Exact 4-Section Angular Parity)
  void _showAddEditBranchModal(
    BuildContext context,
    bool isRtl,
    bool isDark,
    List<City> cities, [
    StoreBranch? branch,
  ]) {
    final nameCtrl = TextEditingController(text: branch?.branchName ?? '');
    final addrEnCtrl = TextEditingController(text: branch?.addressLine ?? '');
    final addrArCtrl = TextEditingController(text: branch?.addressLine ?? '');
    final phoneCtrl = TextEditingController(text: branch?.contactPhone ?? '');
    final latCtrl = TextEditingController(text: branch != null ? branch.latitude.toStringAsFixed(6) : '24.713600');
    final lngCtrl = TextEditingController(text: branch != null ? branch.longitude.toStringAsFixed(6) : '46.675300');
    final openCtrl = TextEditingController(text: branch?.openTime ?? '08:00:00');
    final closeCtrl = TextEditingController(text: branch?.closeTime ?? '23:00:00');

    final uniqueCities = <int, City>{};
    for (final c in cities) {
      uniqueCities[c.id] = c;
    }
    final safeCities = uniqueCities.values.toList();
    int? selectedCityId = branch?.cityId;
    if (selectedCityId == null || !safeCities.any((c) => c.id == selectedCityId)) {
      selectedCityId = safeCities.isNotEmpty ? safeCities.first.id : null;
    }

    bool is247 = branch != null && (branch.openTime == '00:00:00' && branch.closeTime == '23:59:59');
    bool isActive = branch == null ? true : branch.active;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isMobile = MediaQuery.of(modalCtx).size.width < 600;

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
                    branch == null ? Icons.add_location_alt : Icons.edit_location_alt,
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
                        branch == null
                            ? (isRtl ? 'إضافة فرع جديد' : 'Add Store Branch')
                            : (isRtl ? 'تعديل بيانات الفرع' : 'Edit Branch'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRtl
                            ? 'ضبط موقع الفرع، معلومات التواصل، وساعات العمل'
                            : 'Configure branch location, contact details & operating hours',
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
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: Basic Branch Information
                    _buildModalSectionHeader(
                      Icons.storefront,
                      isRtl ? 'المعلومات الأساسية للفرع' : 'Basic Branch Information',
                      isDark,
                    ),
                    const SizedBox(height: 8),

                    if (isMobile) ...[
                      _buildModalTextField(
                        controller: nameCtrl,
                        label: isRtl ? 'اسم الفرع *' : 'Branch Name *',
                        hint: isRtl ? 'مثال: فرع العليا الرئيسي' : 'e.g. Olaya Main Branch',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildCitySelector(safeCities, selectedCityId, isRtl, isDark, (val) => setModalState(() => selectedCityId = val)),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildModalTextField(
                              controller: nameCtrl,
                              label: isRtl ? 'اسم الفرع *' : 'Branch Name *',
                              hint: isRtl ? 'مثال: فرع العليا الرئيسي' : 'e.g. Olaya Main Branch',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildCitySelector(safeCities, selectedCityId, isRtl, isDark, (val) => setModalState(() => selectedCityId = val)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),

                    if (isMobile) ...[
                      _buildModalTextField(
                        controller: addrEnCtrl,
                        label: isRtl ? 'العنوان (الإنجليزية)' : 'Address (English)',
                        hint: 'e.g. King Fahd Rd, Building 12',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildModalTextField(
                        controller: addrArCtrl,
                        label: isRtl ? 'العنوان (العربية)' : 'Address (Arabic)',
                        hint: 'مثال: طريق الملك فهد، مبنى 12',
                        isDark: isDark,
                        isRtl: true,
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildModalTextField(
                              controller: addrEnCtrl,
                              label: isRtl ? 'العنوان (الإنجليزية)' : 'Address (English)',
                              hint: 'e.g. King Fahd Rd, Building 12',
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildModalTextField(
                              controller: addrArCtrl,
                              label: isRtl ? 'العنوان (العربية)' : 'Address (Arabic)',
                              hint: 'مثال: طريق الملك فهد، مبنى 12',
                              isDark: isDark,
                              isRtl: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // SECTION 2: Map Location & Contact
                    _buildModalSectionHeader(
                      Icons.map,
                      isRtl ? 'تحديد موقع الفرع والتواصل' : 'Map Location & Contact',
                      isDark,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      isRtl ? 'حدد موقع الفرع على الخريطة *' : 'Select Branch Location on Map *',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Interactive Location Picker with OpenStreetMap, Pins, Nominatim Search, GPS Button
                    LocationPickerWidget(
                      initialLat: double.tryParse(latCtrl.text) ?? 24.7136,
                      initialLng: double.tryParse(lngCtrl.text) ?? 46.6753,
                      height: 260,
                      isRtl: isRtl,
                      isDark: isDark,
                      onLocationChanged: (lat, lng) {
                        latCtrl.text = lat.toStringAsFixed(6);
                        lngCtrl.text = lng.toStringAsFixed(6);
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildModalTextField(
                      controller: phoneCtrl,
                      label: isRtl ? 'رقم الهاتف' : 'Phone Number',
                      hint: 'e.g. +966 11 123 4567',
                      keyboardType: TextInputType.phone,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // SECTION 3: Operating Schedule
                    _buildModalSectionHeader(
                      Icons.schedule,
                      isRtl ? 'أوقات وساعات العمل' : 'Operating Schedule',
                      isDark,
                    ),
                    const SizedBox(height: 8),

                    if (!is247) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Opening Time
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isRtl ? 'وقت الافتتاح' : 'Opening Time',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: openCtrl,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.alarm, size: 16, color: Color(0xFF16A34A)),
                                          hintText: '08:00:00',
                                          filled: true,
                                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        children: [
                                          _buildPresetChip('08:00 AM', () => setModalState(() => openCtrl.text = '08:00:00'), isDark),
                                          _buildPresetChip('09:00 AM', () => setModalState(() => openCtrl.text = '09:00:00'), isDark),
                                          _buildPresetChip('10:00 AM', () => setModalState(() => openCtrl.text = '10:00:00'), isDark),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Closing Time
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isRtl ? 'وقت الإغلاق' : 'Closing Time',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: closeCtrl,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.bedtime, size: 16, color: Color(0xFF16A34A)),
                                          hintText: '23:00:00',
                                          filled: true,
                                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        children: [
                                          _buildPresetChip('10:00 PM', () => setModalState(() => closeCtrl.text = '22:00:00'), isDark),
                                          _buildPresetChip('11:00 PM', () => setModalState(() => closeCtrl.text = '23:00:00'), isDark),
                                          _buildPresetChip('12:00 AM', () => setModalState(() => closeCtrl.text = '00:00:00'), isDark),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // SECTION 4: Switches & Status (Toggle Cards matching Angular .toggles-box)
                    Row(
                      children: [
                        // Toggle Card 1: 24/7 Switch
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                is247 = !is247;
                                if (is247) {
                                  openCtrl.text = '00:00:00';
                                  closeCtrl.text = '23:59:59';
                                } else {
                                  openCtrl.text = '08:00:00';
                                  closeCtrl.text = '23:00:00';
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: is247
                                      ? const Color(0xFF16A34A)
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  width: is247 ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: is247,
                                    activeColor: const Color(0xFF16A34A),
                                    onChanged: (val) {
                                      setModalState(() {
                                        is247 = val ?? false;
                                        if (is247) {
                                          openCtrl.text = '00:00:00';
                                          closeCtrl.text = '23:59:59';
                                        } else {
                                          openCtrl.text = '08:00:00';
                                          closeCtrl.text = '23:00:00';
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isRtl ? 'مفتوح 24/7 (على مدار الساعة)' : 'Open 24 Hours (24/7)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isRtl ? 'يعمل الفرع طوال اليوم دون إغلاق' : 'Operates non-stop all day',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Toggle Card 2: Active Switch
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => isActive = !isActive),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFF16A34A)
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  width: isActive ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: isActive,
                                    activeColor: const Color(0xFF16A34A),
                                    onChanged: (val) => setModalState(() => isActive = val ?? false),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isRtl ? 'فرع نشط ومتاح للعامة' : 'Branch Active & Published',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isRtl ? 'يظهر الفرع في قائمة الفروع للمستخدمين' : 'Displayed on website and app',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                  foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(isRtl ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty || selectedCityId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isRtl ? 'يرجى إدخال اسم الفرع والمدينة' : 'Please fill branch name and city'),
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                          );
                          return;
                        }

                        final lat = double.tryParse(latCtrl.text.trim()) ?? 24.7136;
                        final lng = double.tryParse(lngCtrl.text.trim()) ?? 46.6753;
                        final openTime = is247 ? '00:00:00' : openCtrl.text.trim();
                        final closeTime = is247 ? '23:59:59' : closeCtrl.text.trim();
                        final address = addrEnCtrl.text.trim().isNotEmpty
                            ? addrEnCtrl.text.trim()
                            : (addrArCtrl.text.trim().isNotEmpty ? addrArCtrl.text.trim() : null);

                        setModalState(() => isSubmitting = true);

                        bool ok = false;
                        if (branch == null) {
                          ok = await ref.read(storeRepositoryProvider.notifier).createBranch(
                                widget.storeId,
                                selectedCityId!,
                                nameCtrl.text.trim(),
                                lat,
                                lng,
                                openTime,
                                closeTime,
                                isActive ? 1 : 0,
                                phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                address,
                              );
                        } else {
                          ok = await ref.read(storeRepositoryProvider.notifier).updateBranch(
                                branch.id,
                                selectedCityId!,
                                nameCtrl.text.trim(),
                                lat,
                                lng,
                                openTime,
                                closeTime,
                                isActive ? 1 : 0,
                                phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                                address,
                              );
                        }

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                branch == null
                                    ? (isRtl ? 'تم إضافة الفرع بنجاح' : 'Branch added successfully')
                                    : (isRtl ? 'تم تحديث الفرع بنجاح' : 'Branch updated successfully'),
                              ),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 16),
                label: Text(
                  isRtl ? 'حفظ الفرع' : 'Save Branch',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Modal Section Header
  Widget _buildModalSectionHeader(IconData icon, String title, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF16A34A)),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ],
    );
  }

  // Modal Text Field
  Widget _buildModalTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    bool isRtl = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFF16A34A), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // City Selector Dropdown
  Widget _buildCitySelector(
    List<City> safeCities,
    int? selectedCityId,
    bool isRtl,
    bool isDark,
    ValueChanged<int?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRtl ? 'المدينة *' : 'City *',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedCityId,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              items: safeCities
                  .map((c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(
                          isRtl ? c.nameAr : c.nameEn,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // Preset Time Chip
  Widget _buildPresetChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // Preset Location Chip
  Widget _buildPresetLocationChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.my_location, size: 10, color: Color(0xFF16A34A)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Delete Branch Confirmation Dialog
  void _showDeleteBranchDialog(
    BuildContext context,
    StoreBranch branch,
    bool isRtl,
    bool isDark,
  ) {
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
                isRtl ? 'حذف الفرع؟' : 'Delete Branch?',
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
              ? 'هل أنت متأكد من رغبتك في حذف فرع "${branch.branchName}"؟ لا يمكن التراجع عن هذا الإجراء.'
              : 'Are you sure you want to delete branch "${branch.branchName}"? This action cannot be undone.',
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
              await ref.read(storeRepositoryProvider.notifier).deleteBranch(branch.id);
            },
            child: Text(isRtl ? 'تأكيد الحذف' : 'Delete'),
          ),
        ],
      ),
    );
  }
}
