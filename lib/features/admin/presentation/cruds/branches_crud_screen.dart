import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String _selectedStatusFilter = 'ALL'; // 'ALL', 'ACTIVE', 'INACTIVE'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cityRepositoryProvider.notifier).fetchCities();
      ref.read(storeRepositoryProvider.notifier).fetchStoreById(widget.storeId);
      ref.read(storeRepositoryProvider.notifier).fetchBranchesForStore(widget.storeId);
    });
  }

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
        final addrEn = (b.addressEn ?? '').toLowerCase();
        final addrAr = (b.addressAr ?? '').toLowerCase();
        final city = (b.cityNameEn ?? b.city?.nameEn ?? '').toLowerCase();
        final cityAr = (b.cityNameAr ?? b.city?.nameAr ?? '').toLowerCase();
        final phone = (b.contactPhone ?? '').toLowerCase();
        return name.contains(query) ||
            addr.contains(query) ||
            addrEn.contains(query) ||
            addrAr.contains(query) ||
            city.contains(query) ||
            cityAr.contains(query) ||
            phone.contains(query);
      }).toList();
    }

    if (_selectedCityFilter != null) {
      list = list.where((b) => b.cityId == _selectedCityFilter).toList();
    }

    if (_selectedStatusFilter == 'ACTIVE') {
      list = list.where((b) => b.active).toList();
    } else if (_selectedStatusFilter == 'INACTIVE') {
      list = list.where((b) => !b.active).toList();
    }

    return list;
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    if (lat != 0.0 && lng != 0.0) {
      final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
      try {
        final launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (_) {}

      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      try {
        final launched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (launched) return;
      } catch (_) {}

      try {
        await launchUrl(webUri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
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
    final twentyFourSevenCount = allBranches.where((b) => b.is24Hours).length;

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () async {
            await Future.wait([
              ref.read(storeRepositoryProvider.notifier).fetchBranchesForStore(widget.storeId),
              ref.read(storeRepositoryProvider.notifier).fetchStoreById(widget.storeId),
              ref.read(cityRepositoryProvider.notifier).fetchCities(),
            ]);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 28 : 14,
              vertical: isDesktop ? 24 : 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header with Back Button and Add Button (.crud-header)
                _buildHeaderBlock(context, store, isRtl, isDark, cities, isDesktop),
                const SizedBox(height: 18),

                // 2. Summary Stats Cards Grid (.stats-grid)
                _buildStatsGrid(
                  totalCount: totalCount,
                  activeCount: activeCount,
                  twentyFourSevenCount: twentyFourSevenCount,
                  isRtl: isRtl,
                  isDark: isDark,
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: 16),

                // 3. Filters & Search Toolbar (.filter-card)
                _buildFilterToolbar(
                  cities: cities,
                  isRtl: isRtl,
                  isDark: isDark,
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: 16),

                // 4. Loading State / Empty State / Branches View
                if (storeState.isLoading && allBranches.isEmpty) ...[
                  _buildLoadingState(isRtl, isDark),
                ] else if (filteredBranches.isEmpty) ...[
                  _buildEmptyState(isRtl, isDark),
                ] else ...[
                  if (isDesktop)
                    _buildDesktopTableView(filteredBranches, isRtl, isDark, cities)
                  else
                    _buildMobileCardsView(filteredBranches, isRtl, isDark, cities),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Header Block (.crud-header)
  Widget _buildHeaderBlock(
    BuildContext context,
    Store? store,
    bool isRtl,
    bool isDark,
    List<City> cities,
    bool isDesktop,
  ) {
    final logoUrl = AppConfig.normalizeImageUrl(store?.logoUrl);
    final storeName = isRtl
        ? (store?.nameAr ?? store?.nameEn ?? 'Store #${widget.storeId}')
        : (store?.nameEn ?? store?.nameAr ?? 'Store #${widget.storeId}');

    final headerContent = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // .btn-back
        Material(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/admin/stores');
              }
            },
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                size: 20,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // .store-avatar-mini
        if (logoUrl.isNotEmpty) ...[
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                logoUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, size: 22, color: Color(0xFF16A34A)),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],

        // .header-title-group
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRtl ? 'إدارة الفروع' : 'Branch Management',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: isRtl ? 'فروع متجر ' : 'Branches for ',
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextSpan(
                      text: storeName,
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF16A34A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final addBtn = ElevatedButton.icon(
      onPressed: () => _showAddEditBranchModal(context, isRtl, isDark, cities),
      icon: const Icon(Icons.add_location_alt_rounded, size: 18),
      label: Text(
        isRtl ? 'إضافة فرع جديد' : 'Add New Branch',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.25),
      ),
    );

    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: headerContent),
            const SizedBox(width: 16),
            addBtn,
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          headerContent,
          const SizedBox(height: 12),
          addBtn,
        ],
      ),
    );
  }

  // 2. Stats Grid (.stats-grid)
  Widget _buildStatsGrid({
    required int totalCount,
    required int activeCount,
    required int twentyFourSevenCount,
    required bool isRtl,
    required bool isDark,
    required bool isDesktop,
  }) {
    final cards = [
      _buildStatCard(
        icon: Icons.location_city_rounded,
        iconColor: const Color(0xFF2563EB),
        bgColor: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFEFF6FF),
        borderColor: const Color(0xFFBFDBFE),
        count: totalCount,
        label: isRtl ? 'إجمالي الفروع' : 'Total Branches',
        isDark: isDark,
      ),
      _buildStatCard(
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF16A34A),
        bgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4),
        borderColor: const Color(0xFFBBF7D0),
        count: activeCount,
        label: isRtl ? 'فروع نشطة' : 'Active Branches',
        isDark: isDark,
      ),
      _buildStatCard(
        icon: Icons.schedule_rounded,
        iconColor: const Color(0xFFD97706),
        bgColor: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFFFBEB),
        borderColor: const Color(0xFFFDE68A),
        count: twentyFourSevenCount,
        label: isRtl ? 'فروع 24 ساعة' : '24/7 Open Branches',
        isDark: isDark,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
          const SizedBox(width: 12),
          Expanded(child: cards[2]),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 8),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 8),
        cards[2],
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required int count,
    required String label,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor.withValues(alpha: isDark ? 0.3 : 0.6)),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
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

  // 3. Search & Filter Toolbar (.filter-card)
  Widget _buildFilterToolbar({
    required List<City> cities,
    required bool isRtl,
    required bool isDark,
    required bool isDesktop,
  }) {
    final uniqueCities = <int, City>{};
    for (final c in cities) {
      uniqueCities[c.id] = c;
    }
    final safeCities = uniqueCities.values.toList();
    final validCity = safeCities.any((c) => c.id == _selectedCityFilter) ? _selectedCityFilter : null;

    final searchInput = SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: isRtl
              ? 'ابحث باسم الفرع، العنوان، المدينة، أو الهاتف...'
              : 'Search by branch name, address, city, phone...',
          hintStyle: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: Color(0xFF16A34A), width: 1.5),
          ),
        ),
      ),
    );

    final cityFilterDropdown = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: validCity,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF16A34A)),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                isRtl ? 'جميع المدن' : 'All Cities',
                style: TextStyle(
                  fontSize: 12.5,
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                )),
          ],
          onChanged: (val) => setState(() => _selectedCityFilter = val),
        ),
      ),
    );

    final statusFilterDropdown = Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatusFilter,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF16A34A)),
          items: [
            DropdownMenuItem<String>(
              value: 'ALL',
              child: Text(
                isRtl ? 'جميع الحالات' : 'All Statuses',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'ACTIVE',
              child: Text(
                isRtl ? 'نشط فقط' : 'Active Only',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            DropdownMenuItem<String>(
              value: 'INACTIVE',
              child: Text(
                isRtl ? 'غير نشط فقط' : 'Inactive Only',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
          onChanged: (val) => setState(() => _selectedStatusFilter = val ?? 'ALL'),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: searchInput),
                const SizedBox(width: 12),
                SizedBox(width: 190, child: cityFilterDropdown),
                const SizedBox(width: 12),
                SizedBox(width: 170, child: statusFilterDropdown),
              ],
            )
          : Column(
              children: [
                searchInput,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: cityFilterDropdown),
                    const SizedBox(width: 8),
                    Expanded(child: statusFilterDropdown),
                  ],
                ),
              ],
            ),
    );
  }

  // 4. Desktop Table View (.table-container.desktop-table-only)
  Widget _buildDesktopTableView(
    List<StoreBranch> branches,
    bool isRtl,
    bool isDark,
    List<City> cities,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          ),
          dataRowMinHeight: 60,
          dataRowMaxHeight: 68,
          horizontalMargin: 18,
          columnSpacing: 18,
          dividerThickness: 1,
          columns: [
            DataColumn(
              label: Text(
                'ID',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                isRtl ? 'معلومات الفرع' : 'Branch Info',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                isRtl ? 'المدينة' : 'City',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                isRtl ? 'العنوان' : 'Address',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                isRtl ? 'الموقع' : 'Location',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                isRtl ? 'ساعات العمل' : 'Hours',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                isRtl ? 'الهاتف' : 'Phone',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            DataColumn(
              label: Text(
                isRtl ? 'الحالة' : 'Status',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            DataColumn(
              label: Center(
                child: Text(
                  isRtl ? 'الإجراءات' : 'Actions',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
          rows: branches.map((b) {
            final cityName = isRtl
                ? (b.cityNameAr ?? b.city?.nameAr ?? b.cityNameEn ?? b.city?.nameEn ?? '')
                : (b.cityNameEn ?? b.city?.nameEn ?? b.cityNameAr ?? b.city?.nameAr ?? '');
            final is247 = b.is24Hours;

            return DataRow(
              color: WidgetStatePropertyAll(
                !b.active ? (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC)) : Colors.transparent,
              ),
              cells: [
                // ID
                DataCell(
                  Text(
                    '#${b.id}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                // Branch Info
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.store_rounded, size: 18, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Text(
                        b.branchName,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                // City
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFFEF4444)),
                        const SizedBox(width: 4),
                        Text(
                          cityName.isNotEmpty ? cityName : '-',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Address
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((b.addressEn ?? b.addressLine ?? '').isNotEmpty)
                          Text(
                            b.addressEn ?? b.addressLine ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        if ((b.addressAr ?? '').isNotEmpty)
                          Text(
                            b.addressAr!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        if ((b.addressEn ?? b.addressLine ?? '').isEmpty && (b.addressAr ?? '').isEmpty)
                          Text(
                            '-',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Location (Google Maps Pill Button)
                DataCell(
                  InkWell(
                    onTap: () => _openGoogleMaps(b.latitude, b.longitude),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFBFDBFE).withValues(alpha: isDark ? 0.3 : 0.8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.map_rounded, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 5),
                          Text(
                            (b.latitude != 0.0 && b.longitude != 0.0)
                                ? '${b.latitude.toStringAsFixed(2)}, ${b.longitude.toStringAsFixed(2)}'
                                : (isRtl ? 'فتح الخريطة' : 'Open Map'),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Hours
                DataCell(
                  is247
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFFDE68A).withValues(alpha: isDark ? 0.3 : 0.8),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_rounded, size: 13, color: Color(0xFFD97706)),
                              SizedBox(width: 4),
                              Text(
                                '24/7',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              Text(
                                '${b.openTime.length >= 5 ? b.openTime.substring(0, 5) : b.openTime} - ${b.closeTime.length >= 5 ? b.closeTime.substring(0, 5) : b.closeTime}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                // Phone
                DataCell(
                  (b.contactPhone != null && b.contactPhone!.isNotEmpty)
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call_rounded, size: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              b.contactPhone!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        )
                      : Text('-', style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                ),
                // Status (.status-chip)
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: b.active
                          ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4))
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: b.active
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
                            color: b.active ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          b.active ? (isRtl ? 'نشط' : 'Active') : (isRtl ? 'غير نشط' : 'Inactive'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: b.active
                                ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions (.action-buttons-wrap)
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Button
                      Tooltip(
                        message: isRtl ? 'تعديل الفرع' : 'Edit Branch',
                        child: Material(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => _showAddEditBranchModal(context, isRtl, isDark, cities, b),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Delete Button
                      Tooltip(
                        message: isRtl ? 'حذف الفرع' : 'Delete Branch',
                        child: Material(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => _showDeleteBranchDialog(context, b, isRtl, isDark),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.delete_rounded,
                                size: 16,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // 5. Mobile Cards View (.mobile-cards-only)
  Widget _buildMobileCardsView(
    List<StoreBranch> branches,
    bool isRtl,
    bool isDark,
    List<City> cities,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: branches.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final b = branches[index];
        final cityName = isRtl
            ? (b.cityNameAr ?? b.city?.nameAr ?? b.cityNameEn ?? b.city?.nameEn ?? '')
            : (b.cityNameEn ?? b.city?.nameEn ?? b.cityNameAr ?? b.city?.nameAr ?? '');
        final is247 = b.is24Hours;

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
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (.branch-card-header)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.store_rounded, color: Color(0xFF16A34A), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.branchName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '#${b.id}',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Status Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: b.active
                          ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4))
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: b.active
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
                            color: b.active ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          b.active ? (isRtl ? 'نشط' : 'Active') : (isRtl ? 'غير نشط' : 'Inactive'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: b.active
                                ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Meta Row
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // City Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFFEF4444)),
                        const SizedBox(width: 4),
                        Text(
                          cityName.isNotEmpty ? cityName : '-',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hours
                  is247
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFFDE68A).withValues(alpha: isDark ? 0.3 : 0.8),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule_rounded, size: 12, color: Color(0xFFD97706)),
                              SizedBox(width: 4),
                              Text(
                                '24/7',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              Text(
                                '${b.openTime.length >= 5 ? b.openTime.substring(0, 5) : b.openTime} - ${b.closeTime.length >= 5 ? b.closeTime.substring(0, 5) : b.closeTime}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 8),

              // Address Info
              if ((b.addressEn ?? b.addressAr ?? b.addressLine ?? '').isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.place_rounded, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isRtl
                            ? (b.addressAr ?? b.addressEn ?? b.addressLine ?? '')
                            : (b.addressEn ?? b.addressAr ?? b.addressLine ?? ''),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // Phone Info
              if (b.contactPhone != null && b.contactPhone!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.call_rounded, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      b.contactPhone!,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Footer (.branch-card-footer)
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Open Map
                    InkWell(
                      onTap: () => _openGoogleMaps(b.latitude, b.longitude),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE).withValues(alpha: isDark ? 0.3 : 0.8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.map_rounded, size: 14, color: Color(0xFF2563EB)),
                            const SizedBox(width: 5),
                            Text(
                              isRtl ? 'فتح الخريطة' : 'Open Map',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => _showAddEditBranchModal(context, isRtl, isDark, cities, b),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => _showDeleteBranchDialog(context, b, isRtl, isDark),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.delete_rounded,
                                size: 16,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 6. Loading State
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

  // 7. Empty State (.empty-card)
  Widget _buildEmptyState(bool isRtl, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, size: 28, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Text(
            isRtl ? 'لم يتم العثور على فروع' : 'No branches found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isRtl
                ? 'جرب تغيير خيارات البحث أو انقر على "إضافة فرع جديد".'
                : 'Try adjusting your search criteria or click "Add New Branch" to create one.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // 8. Add / Edit Branch Modal (.modal-card)
  void _showAddEditBranchModal(
    BuildContext context,
    bool isRtl,
    bool isDark,
    List<City> cities, [
    StoreBranch? branch,
  ]) {
    final nameCtrl = TextEditingController(text: branch?.branchName ?? '');
    final addrEnCtrl = TextEditingController(text: branch?.addressEn ?? branch?.addressLine ?? '');
    final addrArCtrl = TextEditingController(text: branch?.addressAr ?? branch?.addressLine ?? '');
    final phoneCtrl = TextEditingController(text: branch?.contactPhone ?? '');
    final latCtrl = TextEditingController(text: branch != null ? branch.latitude.toStringAsFixed(6) : '24.713600');
    final lngCtrl = TextEditingController(text: branch != null ? branch.longitude.toStringAsFixed(6) : '46.675300');
    final openCtrl = TextEditingController(text: branch != null && branch.openTime.length >= 5 ? branch.openTime.substring(0, 5) : '08:00');
    final closeCtrl = TextEditingController(text: branch != null && branch.closeTime.length >= 5 ? branch.closeTime.substring(0, 5) : '23:00');

    final uniqueCities = <int, City>{};
    for (final c in cities) {
      uniqueCities[c.id] = c;
    }
    final safeCities = uniqueCities.values.toList();
    int? selectedCityId = branch?.cityId;
    if (selectedCityId == null || !safeCities.any((c) => c.id == selectedCityId)) {
      selectedCityId = safeCities.isNotEmpty ? safeCities.first.id : null;
    }

    bool is247 = branch != null && branch.is24Hours;
    bool isActive = branch == null ? true : branch.active;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isMobile = MediaQuery.of(modalCtx).size.width < 640;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
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
                    branch == null ? Icons.add_location_alt_rounded : Icons.edit_location_alt_rounded,
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
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SizedBox(
              width: 620,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: Basic Info
                    _buildModalSectionHeader(
                      Icons.storefront_rounded,
                      isRtl ? 'المعلومات الأساسية للفرع' : 'Basic Branch Information',
                      isDark,
                    ),
                    const SizedBox(height: 10),

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
                          const SizedBox(width: 12),
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
                          const SizedBox(width: 12),
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
                    const SizedBox(height: 18),

                    // SECTION 2: Map Location & Contact
                    _buildModalSectionHeader(
                      Icons.map_rounded,
                      isRtl ? 'تحديد موقع الفرع والتواصل' : 'Map Location & Contact',
                      isDark,
                    ),
                    const SizedBox(height: 10),

                    Text(
                      isRtl ? 'حدد موقع الفرع على الخريطة *' : 'Select Branch Location on Map *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),

                    LocationPickerWidget(
                      initialLat: double.tryParse(latCtrl.text) ?? 24.7136,
                      initialLng: double.tryParse(lngCtrl.text) ?? 46.6753,
                      height: 240,
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
                    const SizedBox(height: 18),

                    // SECTION 3: Operating Schedule
                    _buildModalSectionHeader(
                      Icons.schedule_rounded,
                      isRtl ? 'أوقات وساعات العمل' : 'Operating Schedule',
                      isDark,
                    ),
                    const SizedBox(height: 10),

                    if (!is247) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
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
                                  const SizedBox(height: 5),
                                  TextField(
                                    controller: openCtrl,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.alarm_rounded, size: 16, color: Color(0xFF16A34A)),
                                      hintText: '08:00',
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                                    onChanged: (_) => setModalState(() {}),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 5,
                                    runSpacing: 4,
                                    children: [
                                      _buildPresetChip('08:00 AM', () => setModalState(() => openCtrl.text = '08:00'), openCtrl.text.startsWith('08:00'), isDark),
                                      _buildPresetChip('09:00 AM', () => setModalState(() => openCtrl.text = '09:00'), openCtrl.text.startsWith('09:00'), isDark),
                                      _buildPresetChip('10:00 AM', () => setModalState(() => openCtrl.text = '10:00'), openCtrl.text.startsWith('10:00'), isDark),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

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
                                  const SizedBox(height: 5),
                                  TextField(
                                    controller: closeCtrl,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.bedtime_rounded, size: 16, color: Color(0xFF16A34A)),
                                      hintText: '23:00',
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                                    onChanged: (_) => setModalState(() {}),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 5,
                                    runSpacing: 4,
                                    children: [
                                      _buildPresetChip('10:00 PM', () => setModalState(() => closeCtrl.text = '22:00'), closeCtrl.text.startsWith('22:00'), isDark),
                                      _buildPresetChip('11:00 PM', () => setModalState(() => closeCtrl.text = '23:00'), closeCtrl.text.startsWith('23:00'), isDark),
                                      _buildPresetChip('12:00 AM', () => setModalState(() => closeCtrl.text = '00:00'), closeCtrl.text.startsWith('00:00') || closeCtrl.text.startsWith('23:59'), isDark),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // SECTION 4: Switches & Status (.toggles-box)
                    if (isMobile) ...[
                      _buildToggleCard(
                        title: isRtl ? 'مفتوح 24/7 (على مدار الساعة)' : 'Open 24 Hours (24/7)',
                        subtitle: isRtl ? 'حدد الخيار إذا كان الفرع يعمل طوال اليوم دون إغلاق' : 'Check if this branch operates non-stop',
                        isSelected: is247,
                        onTap: () {
                          setModalState(() {
                            is247 = !is247;
                            if (is247) {
                              openCtrl.text = '00:00';
                              closeCtrl.text = '23:59';
                            } else {
                              openCtrl.text = '08:00';
                              closeCtrl.text = '23:00';
                            }
                          });
                        },
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildToggleCard(
                        title: isRtl ? 'فرع نشط ومتاح للعامة' : 'Branch Active & Published',
                        subtitle: isRtl ? 'الفروع النشطة تظهر في قائمة الفروع للمستخدمين' : 'Active branches are displayed on website and app',
                        isSelected: isActive,
                        onTap: () => setModalState(() => isActive = !isActive),
                        isDark: isDark,
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildToggleCard(
                              title: isRtl ? 'مفتوح 24/7 (على مدار الساعة)' : 'Open 24 Hours (24/7)',
                              subtitle: isRtl ? 'حدد الخيار إذا كان الفرع يعمل طوال اليوم دون إغلاق' : 'Check if this branch operates non-stop',
                              isSelected: is247,
                              onTap: () {
                                setModalState(() {
                                  is247 = !is247;
                                  if (is247) {
                                    openCtrl.text = '00:00';
                                    closeCtrl.text = '23:59';
                                  } else {
                                    openCtrl.text = '08:00';
                                    closeCtrl.text = '23:00';
                                  }
                                });
                              },
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildToggleCard(
                              title: isRtl ? 'فرع نشط ومتاح للعامة' : 'Branch Active & Published',
                              subtitle: isRtl ? 'الفروع النشطة تظهر في قائمة الفروع للمستخدمين' : 'Active branches are displayed on website and app',
                              isSelected: isActive,
                              onTap: () => setModalState(() => isActive = !isActive),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                        var openTime = is247 ? '00:00:00' : openCtrl.text.trim();
                        var closeTime = is247 ? '23:59:59' : closeCtrl.text.trim();
                        if (openTime.length == 5) openTime += ':00';
                        if (closeTime.length == 5) closeTime += ':00';

                        final addressEn = addrEnCtrl.text.trim();
                        final addressAr = addrArCtrl.text.trim();

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
                                addressEn.isNotEmpty ? addressEn : addressAr,
                                addressEn,
                                addressAr,
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
                                addressEn.isNotEmpty ? addressEn : addressAr,
                                addressEn,
                                addressAr,
                              );
                        }

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                branch == null
                                    ? (isRtl ? 'تم إضافة الفرع بنجاح' : 'Branch created successfully.')
                                    : (isRtl ? 'تم تحديث الفرع بنجاح' : 'Branch updated successfully.'),
                              ),
                              backgroundColor: const Color(0xFF16A34A),
                            ),
                          );
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 16),
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
            Icon(icon, size: 16, color: const Color(0xFF16A34A)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
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
                            fontSize: 12,
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
  Widget _buildPresetChip(String label, VoidCallback onTap, bool isSelected, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF16A34A)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF16A34A)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // Toggle Card Widget (.toggle-card)
  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4))
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF16A34A)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF16A34A) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF16A34A)
                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
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
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.3,
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

  // 9. Delete Confirmation Dialog
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
                isRtl ? 'هل أنت متأكد؟' : 'Are you sure?',
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
              ? 'هل تريد حذف هذا الفرع (${branch.branchName})؟'
              : 'Do you want to delete this store branch (${branch.branchName})?',
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
              final ok = await ref.read(storeRepositoryProvider.notifier).deleteBranch(branch.id);
              if (context.mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isRtl ? 'تم حذف الفرع بنجاح.' : 'Branch has been deleted.'),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
              }
            },
            child: Text(isRtl ? 'نعم، احذف!' : 'Yes, delete it!'),
          ),
        ],
      ),
    );
  }
}
