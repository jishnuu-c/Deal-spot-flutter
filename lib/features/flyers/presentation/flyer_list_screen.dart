import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/services/flyer_repository.dart';
import '../../../core/services/store_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

class FlyerListScreen extends ConsumerStatefulWidget {
  const FlyerListScreen({super.key});

  @override
  ConsumerState<FlyerListScreen> createState() => _FlyerListScreenState();
}

class _FlyerListScreenState extends ConsumerState<FlyerListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cityRepositoryProvider.notifier).fetchCities();
      ref.read(flyerRepositoryProvider.notifier).fetchFlyers();
      ref.read(storeRepositoryProvider.notifier).fetchStores();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final flyerState = ref.watch(flyerRepositoryProvider);
    final cityState = ref.watch(cityRepositoryProvider);
    final selectedCity = cityState.selectedCity;
    final cityId = selectedCity?.id;
    final allFlyers = ref.read(flyerRepositoryProvider.notifier).getFlyers(cityId);
    final isLoading = flyerState.isLoading;

    final flyers = allFlyers.where((f) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final storeName = isRtl ? (f.store?.nameAr.toLowerCase() ?? '') : (f.store?.nameEn.toLowerCase() ?? '');
        final title = isRtl ? f.titleAr.toLowerCase() : f.titleEn.toLowerCase();
        return storeName.contains(q) || title.contains(q);
      }
      return true;
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 1200 ? 4 : (screenWidth >= 768 ? 3 : 2);
    final childAspectRatio = screenWidth >= 768 ? 0.72 : 0.65;

    final cityName = selectedCity != null ? (isRtl ? selectedCity.nameAr : selectedCity.nameEn) : '';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Column(
          children: [
            // Search & City Filter Bar (Matching Angular .flyer-filters.card)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: isRtl ? 'ابحث عن عروض ومجلات المتاجر...' : 'Search flyer titles or store names...',
                      hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF16A34A), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9999),
                        borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9999),
                        borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9999),
                        borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                      ),
                    ),
                  ),

                  // Active Filter & Count Row
                  if (selectedCity != null || !isLoading) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Active City Chip
                        if (selectedCity != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.place, size: 14, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(
                                  cityName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {
                                    ref.read(cityRepositoryProvider.notifier).selectCity(null);
                                  },
                                  child: const Icon(Icons.close, size: 14, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          )
                        else
                          const SizedBox.shrink(),

                        // Count Pill
                        if (!isLoading)
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${flyers.length} ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                TextSpan(
                                  text: isRtl ? 'بروشور' : 'flyers',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Flyers Grid / Loading / Empty State
            Expanded(
              child: isLoading && allFlyers.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF16A34A),
                      onRefresh: () async {
                        await ref.read(flyerRepositoryProvider.notifier).fetchFlyers();
                        await ref.read(storeRepositoryProvider.notifier).fetchStores();
                      },
                      child: flyers.isNotEmpty
                          ? GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: childAspectRatio,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: flyers.length,
                              itemBuilder: (context, index) {
                                final flyer = flyers[index];
                                return _buildFlyerCard(context, flyer, isRtl, isDark, tr);
                              },
                            )
                          : SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(24.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.menu_book_rounded, size: 56, color: isDark ? Colors.white30 : const Color(0xFF94A3B8)),
                                    const SizedBox(height: 16),
                                    Text(
                                      isRtl ? 'لا توجد بروشورات متاحة' : 'No flyers found',
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      selectedCity != null
                                          ? (isRtl
                                              ? 'لم يتم العثور على أي نشرات عروض في $cityName.'
                                              : 'No promotional flyers found in $cityName.')
                                          : (isRtl
                                              ? 'لم يتم العثور على أي نشرات عروض تطابق معايير البحث.'
                                              : 'No promotional flyers found matching your search criteria.'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                    ),
                                    if (selectedCity != null) ...[
                                      const SizedBox(height: 18),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF16A34A),
                                          side: const BorderSide(color: Color(0xFF16A34A)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                        onPressed: () {
                                          ref.read(cityRepositoryProvider.notifier).selectCity(null);
                                        },
                                        icon: const Icon(Icons.public, size: 16),
                                        label: Text(
                                          isRtl ? 'عرض البروشورات من جميع المدن' : 'View Flyers from All Cities',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    ] else if (_searchQuery.isNotEmpty) ...[
                                      const SizedBox(height: 18),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                        child: Text(tr.get('clear_all')),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlyerCard(
    BuildContext context,
    Flyer flyer,
    bool isRtl,
    bool isDark,
    AppLocalizations tr,
  ) {
    final storeName = isRtl ? (flyer.store?.nameAr ?? '') : (flyer.store?.nameEn ?? '');
    final title = isRtl ? flyer.titleAr : flyer.titleEn;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.go('/flyers/${flyer.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Image & Open button overlay (Matching Angular .flyer-image-wrapper)
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      padding: const EdgeInsets.all(8),
                      child: CachedNetworkImage(
                        imageUrl: AppConfig.normalizeImageUrl(flyer.coverImageUrl),
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(Icons.picture_as_pdf, color: Colors.grey, size: 36),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: isRtl ? null : 8,
                      left: isRtl ? 8 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_stories, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${flyer.totalPages} ${isRtl ? "صفحات" : "Pages"}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Body (Matching Angular .flyer-card-body)
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(
                    top: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Store badge row
                    if (storeName.isNotEmpty)
                      InkWell(
                        onTap: flyer.storeId > 0 ? () => context.go('/stores/${flyer.storeId}') : null,
                        child: Row(
                          children: [
                            if (flyer.store?.logoUrl != null && flyer.store!.logoUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: AppConfig.normalizeImageUrl(flyer.store!.logoUrl!),
                                  width: 16,
                                  height: 16,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Expanded(
                              child: Text(
                                storeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 5),

                    // Title
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.25),
                    ),
                    const SizedBox(height: 8),

                    // Card Footer (Pages count & Validity dates)
                    Container(
                      padding: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_stories, size: 12, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${flyer.totalPages} ${isRtl ? "صفحات" : "Pages"}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (flyer.validUntil.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${isRtl ? "حتى:" : "Until:"} ${flyer.validUntil}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: isRtl ? TextAlign.left : TextAlign.right,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}

