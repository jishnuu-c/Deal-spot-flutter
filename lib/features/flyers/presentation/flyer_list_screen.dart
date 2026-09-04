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

    final cityId = ref.watch(cityRepositoryProvider).selectedCity?.id;
    final allFlyers = ref.watch(flyerRepositoryProvider.notifier).getFlyers(cityId);

    final flyers = allFlyers.where((f) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final storeName = isRtl ? (f.store?.nameAr.toLowerCase() ?? '') : (f.store?.nameEn.toLowerCase() ?? '');
        final title = isRtl ? f.titleAr.toLowerCase() : f.titleEn.toLowerCase();
        return storeName.contains(q) || title.contains(q);
      }
      return true;
    }).toList();

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.get('flyers'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: Column(
          children: [
            // Search & Filter Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: isRtl ? 'ابحث عن عروض ومجلات المتاجر...' : 'Search flyer titles or store names...',
                  hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF16A34A), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
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
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),

            // Flyers Grid
            Expanded(
              child: flyers.isNotEmpty
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: flyers.length,
                      itemBuilder: (context, index) {
                        final flyer = flyers[index];
                        return _buildFlyerCard(context, flyer, isRtl, isDark, tr);
                      },
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.menu_book_outlined, size: 56, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              isRtl ? 'لا توجد بروشورات متاحة' : 'No flyers found',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isRtl ? 'لم يتم العثور على أي نشرات عروض تطابق معايير البحث.' : 'No promotional flyers found matching your criteria.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.go('/flyers/${flyer.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image & Open button overlay
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.25,
                    child: CachedNetworkImage(
                      imageUrl: AppConfig.normalizeImageUrl(flyer.coverImageUrl),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.picture_as_pdf, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: isRtl ? null : 8,
                    left: isRtl ? 8 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_stories, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${flyer.totalPages} ${tr.get('pages')}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Content Body
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store badge
                    if (storeName.isNotEmpty)
                      Row(
                        children: [
                          if (flyer.store?.logoUrl != null && flyer.store!.logoUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: AppConfig.normalizeImageUrl(flyer.store!.logoUrl!),
                                width: 14,
                                height: 14,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),

                    // Title
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.2),
                    ),
                    const SizedBox(height: 6),

                    // Expiry
                    if (flyer.validUntil.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.event, size: 11, color: isDark ? Colors.white38 : Colors.black38),
                          const SizedBox(width: 3),
                          Text(
                            '${tr.get('until')} ${flyer.validUntil}',
                            style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white38 : Colors.black38),
                          ),
                        ],
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
