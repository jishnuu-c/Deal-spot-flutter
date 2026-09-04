import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/flyer_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

class FlyerViewerScreen extends ConsumerStatefulWidget {
  final int flyerId;

  const FlyerViewerScreen({super.key, required this.flyerId});

  @override
  ConsumerState<FlyerViewerScreen> createState() => _FlyerViewerScreenState();
}

class _FlyerViewerScreenState extends ConsumerState<FlyerViewerScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flyerRepositoryProvider.notifier).fetchFlyerById(widget.flyerId);
      ref.read(flyerRepositoryProvider.notifier).fetchFlyerPages(widget.flyerId);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jumpToPage(int page) {
    setState(() => _currentPage = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final flyer = ref.watch(flyerRepositoryProvider.notifier).getFlyerById(widget.flyerId);

    if (flyer == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(isRtl ? 'لم يتم العثور على البروشور' : 'Flyer not found', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/flyers'),
                child: Text(tr.get('view_flyers')),
              ),
            ],
          ),
        ),
      );
    }

    final pages = flyer.pages ?? [];
    final title = isRtl ? flyer.titleAr : flyer.titleEn;
    final storeName = isRtl ? (flyer.store?.nameAr ?? '') : (flyer.store?.nameEn ?? '');

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          actions: [
            // Share Flyer
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: tr.get('share'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: 'https://dealspot.sa/flyers/${flyer.id}'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr.get('copied')), duration: const Duration(seconds: 1)),
                );
              },
            ),
          ],
        ),
        body: pages.isEmpty
            ? Center(child: Text(isRtl ? 'لا توجد صفحات لهذا البروشور' : 'No flyer pages available'))
            : Column(
                children: [
                  // Store & Expiry Header Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (storeName.isNotEmpty)
                          InkWell(
                            onTap: () => context.go('/stores/${flyer.storeId}'),
                            child: Row(
                              children: [
                                const Icon(Icons.store, size: 16, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(
                                  storeName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        if (flyer.validUntil.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.event, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '${tr.get('valid_to')} ${flyer.validUntil}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Linear Progress Bar
                  LinearProgressIndicator(
                    value: (pages.isNotEmpty) ? (_currentPage + 1) / pages.length : 0.0,
                    backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                    minHeight: 3,
                  ),

                  // Main Interactive Page Viewer
                  Expanded(
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: pages.length,
                          onPageChanged: (idx) => setState(() => _currentPage = idx),
                          itemBuilder: (context, index) {
                            final page = pages[index];
                            return InteractiveViewer(
                              minScale: 0.8,
                              maxScale: 4.0,
                              child: Center(
                                child: CachedNetworkImage(
                                  imageUrl: AppConfig.normalizeImageUrl(page.imageUrl),
                                  fit: BoxFit.contain,
                                  placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                ),
                              ),
                            );
                          },
                        ),

                        // Floating Previous Arrow
                        if (_currentPage > 0)
                          Positioned(
                            left: isRtl ? null : 12,
                            right: isRtl ? 12 : null,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: InkWell(
                                onTap: () => _jumpToPage(_currentPage - 1),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isRtl ? Icons.chevron_right : Icons.chevron_left,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Floating Next Arrow
                        if (_currentPage < pages.length - 1)
                          Positioned(
                            right: isRtl ? null : 12,
                            left: isRtl ? 12 : null,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: InkWell(
                                onTap: () => _jumpToPage(_currentPage + 1),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isRtl ? Icons.chevron_left : Icons.chevron_right,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Page Navigation Controls Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border(top: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _currentPage > 0 ? () => _jumpToPage(_currentPage - 1) : null,
                          icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back, size: 14),
                          label: Text(isRtl ? 'السابق' : 'Prev'),
                        ),

                        // Page badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_currentPage + 1} / ${pages.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 13),
                          ),
                        ),

                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _currentPage < pages.length - 1 ? () => _jumpToPage(_currentPage + 1) : null,
                          icon: Icon(isRtl ? Icons.arrow_back : Icons.arrow_forward, size: 14),
                          label: Text(isRtl ? 'التالي' : 'Next'),
                        ),
                      ],
                    ),
                  ),

                  // Thumbnails Strip
                  Container(
                    height: 72,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: isDark ? const Color(0xFF131C2E) : const Color(0xFFF1F5F9),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        final p = pages[index];
                        final isSelected = index == _currentPage;

                        return InkWell(
                          onTap: () => _jumpToPage(index),
                          child: Container(
                            width: 44,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF16A34A) : Colors.grey.withOpacity(0.3),
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: AppConfig.normalizeImageUrl(p.thumbUrl ?? p.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
