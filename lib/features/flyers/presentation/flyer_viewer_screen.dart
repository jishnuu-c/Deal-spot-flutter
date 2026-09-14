import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final TransformationController _transformController = TransformationController();
  bool _isZoomed = false;

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
    _transformController.dispose();
    super.dispose();
  }

  void _jumpToPage(int page) {
    if (page < 0) return;
    _resetZoom();
    setState(() => _currentPage = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleZoom() {
    setState(() {
      _isZoomed = !_isZoomed;
      if (_isZoomed) {
        _transformController.value = Matrix4.identity()..scale(2.2);
      } else {
        _resetZoom();
      }
    });
  }

  void _resetZoom() {
    _isZoomed = false;
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final flyerState = ref.watch(flyerRepositoryProvider);
    final flyer = ref.read(flyerRepositoryProvider.notifier).getFlyerById(widget.flyerId);

    if (flyer == null) {
      if (flyerState.isLoading) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF16A34A)),
          ),
        );
      }
      return Scaffold(
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 52, color: isDark ? Colors.white30 : const Color(0xFF94A3B8)),
                const SizedBox(height: 14),
                Text(
                  isRtl ? 'لم يتم العثور على البروشور' : 'Flyer Not Found',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isRtl
                      ? 'البروشور المطلوب غير متوفر أو قد انتهت فترة صلاحيته.'
                      : 'The flyer you are looking for might have expired or been removed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  onPressed: () => context.go('/stores'),
                  icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back, size: 16),
                  label: Text(
                    isRtl ? 'العودة للمتاجر' : 'Back to Stores',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Bar Card (Matching Angular .viewer-top-bar.card)
              Container(
                padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button & Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back to Store / Back to Flyers
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                            side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            if (flyer.storeId > 0) {
                              context.go('/stores/${flyer.storeId}');
                            } else {
                              context.go('/flyers');
                            }
                          },
                          icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back, size: 14),
                          label: Text(
                            flyer.storeId > 0
                                ? (isRtl ? 'العودة للمتجر' : 'Back to Store')
                                : (isRtl ? 'العودة للعروض' : 'Back to Flyers'),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                          ),
                        ),

                        // Action Icons (Zoom, PDF, Share)
                        Row(
                          children: [
                            // Zoom toggle
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: _isZoomed
                                    ? const Color(0xFF16A34A)
                                    : (isDark ? Colors.black26 : const Color(0xFFF1F5F9)),
                                foregroundColor: _isZoomed ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: Icon(_isZoomed ? Icons.zoom_out : Icons.zoom_in, size: 20),
                              tooltip: _isZoomed ? (isRtl ? 'تصغير' : 'Fit Page') : (isRtl ? 'تكبير' : 'Zoom In'),
                              onPressed: _toggleZoom,
                            ),
                            const SizedBox(width: 6),

                            // PDF Download
                            if (flyer.pdfUrl != null && flyer.pdfUrl!.isNotEmpty) ...[
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                                  foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.picture_as_pdf, size: 20),
                                tooltip: isRtl ? 'عرض PDF' : 'Download / View PDF',
                                onPressed: () async {
                                  final uri = Uri.parse(AppConfig.normalizeImageUrl(flyer.pdfUrl!));
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                              const SizedBox(width: 6),
                            ],

                            // Share
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                                foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.share, size: 18),
                              tooltip: isRtl ? 'مشاركة البروشور' : 'Share Flyer',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: 'https://dealspot.sa/flyers/${flyer.id}'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          isRtl
                                              ? 'تم نسخ رابط البروشور إلى الحافظة!'
                                              : 'Flyer link copied to clipboard!',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.3),
                    ),

                    const SizedBox(height: 8),

                    // Meta Row: Store Link Chip + Validity
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (storeName.isNotEmpty)
                          InkWell(
                            onTap: flyer.storeId > 0 ? () => context.go('/stores/${flyer.storeId}') : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.store, size: 15, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(
                                  storeName,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (storeName.isNotEmpty && flyer.validUntil.isNotEmpty)
                          Text('•', style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFFCBD5E1))),
                        if (flyer.validUntil.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event, size: 14, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                '${isRtl ? "ساري حتى:" : "Valid until:"} ${flyer.validUntil}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Main Page Viewport & Book Container (Matching Angular .book-container.card)
              if (pages.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.menu_book_rounded, size: 48, color: isDark ? Colors.white30 : const Color(0xFF94A3B8)),
                      const SizedBox(height: 14),
                      Text(
                        isRtl ? 'لا توجد صفحات ممسوحة ضوئياً بعد' : 'No pages uploaded yet',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isRtl
                            ? 'هذا البروشور لا يحتوي على صفحات ممسوحة ضوئياً في الوقت الحالي.'
                            : 'This flyer currently does not contain any scanned page images.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              else ...[
                Container(
                  height: 440,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Interactive PageView
                        PageView.builder(
                          controller: _pageController,
                          itemCount: pages.length,
                          onPageChanged: (idx) {
                            _resetZoom();
                            setState(() => _currentPage = idx);
                          },
                          itemBuilder: (context, index) {
                            final page = pages[index];
                            return GestureDetector(
                              onDoubleTap: _toggleZoom,
                              child: Container(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                padding: const EdgeInsets.all(12),
                                child: InteractiveViewer(
                                  transformationController: _transformController,
                                  minScale: 1.0,
                                  maxScale: 4.0,
                                  onInteractionEnd: (_) {
                                    final scale = _transformController.value.getMaxScaleOnAxis();
                                    setState(() {
                                      _isZoomed = scale > 1.05;
                                    });
                                  },
                                  child: Center(
                                    child: CachedNetworkImage(
                                      imageUrl: AppConfig.normalizeImageUrl(page.imageUrl),
                                      fit: BoxFit.contain,
                                      placeholder: (_, __) => Container(
                                        color: isDark ? Colors.black12 : const Color(0xFFF1F5F9),
                                      ),
                                      errorWidget: (_, __, ___) => const Center(
                                        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Left Navigation Floating Button
                        Positioned(
                          left: isRtl ? null : 12,
                          right: isRtl ? 12 : null,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _currentPage > 0 ? () => _jumpToPage(_currentPage - 1) : null,
                                borderRadius: BorderRadius.circular(9999),
                                child: AnimatedOpacity(
                                  opacity: _currentPage > 0 ? 1.0 : 0.25,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isRtl ? Icons.chevron_right : Icons.chevron_left,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Right Navigation Floating Button
                        Positioned(
                          right: isRtl ? null : 12,
                          left: isRtl ? 12 : null,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _currentPage < pages.length - 1 ? () => _jumpToPage(_currentPage + 1) : null,
                                borderRadius: BorderRadius.circular(9999),
                                child: AnimatedOpacity(
                                  opacity: _currentPage < pages.length - 1 ? 1.0 : 0.25,
                                  duration: const Duration(milliseconds: 200),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isRtl ? Icons.chevron_left : Icons.chevron_right,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Page Indicator & Progress Controller (Matching Angular .page-indicator-bar.card)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                              side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: _currentPage > 0 ? () => _jumpToPage(_currentPage - 1) : null,
                            icon: Icon(isRtl ? Icons.arrow_forward : Icons.arrow_back, size: 14),
                            label: Text(
                              isRtl ? 'السابق' : 'Prev',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),

                          // Page Badge (X of Y)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_currentPage + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isRtl ? 'من' : 'of',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${pages.length}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                              side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: _currentPage < pages.length - 1 ? () => _jumpToPage(_currentPage + 1) : null,
                            icon: Icon(isRtl ? Icons.arrow_back : Icons.arrow_forward, size: 14),
                            label: Text(
                              isRtl ? 'التالي' : 'Next',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Progress Track
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: LinearProgressIndicator(
                          value: (pages.isNotEmpty) ? (_currentPage + 1) / pages.length : 0.0,
                          backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 4. Horizontal Thumbnails Strip (Matching Angular .thumbnails-strip-card.card)
                Container(
                  padding: const EdgeInsets.all(16),
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
                      // Strip Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_stories, size: 16, color: Color(0xFF16A34A)),
                              const SizedBox(width: 6),
                              Text(
                                isRtl ? 'نظرة عامة على صفحات البروشور' : 'Flyer Pages Overview',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Text(
                            '${pages.length} ${isRtl ? "صفحة" : "pages"}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Thumbnails Row
                      SizedBox(
                        height: 92,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: pages.length,
                          itemBuilder: (context, index) {
                            final p = pages[index];
                            final isSelected = index == _currentPage;

                            return InkWell(
                              onTap: () => _jumpToPage(index),
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 68,
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF16A34A) : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF16A34A).withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: AppConfig.normalizeImageUrl(p.thumbUrl ?? p.imageUrl),
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const Icon(Icons.picture_as_pdf, color: Colors.grey, size: 20),
                                      ),
                                      Positioned(
                                        bottom: 3,
                                        right: isRtl ? null : 3,
                                        left: isRtl ? 3 : null,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A).withOpacity(0.85),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
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
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
