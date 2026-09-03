import 'package:flutter/material.dart';

class CrudLoadingWidget extends StatefulWidget {
  final String titleEn;
  final String titleAr;
  final String? subtitleEn;
  final String? subtitleAr;
  final IconData icon;
  final bool isRtl;
  final bool isDark;

  const CrudLoadingWidget({
    super.key,
    required this.titleEn,
    required this.titleAr,
    this.subtitleEn,
    this.subtitleAr,
    this.icon = Icons.sync_rounded,
    required this.isRtl,
    required this.isDark,
  });

  @override
  State<CrudLoadingWidget> createState() => _CrudLoadingWidgetState();
}

class _CrudLoadingWidgetState extends State<CrudLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isRtl ? widget.titleAr : widget.titleEn;
    final subtitle = widget.isRtl
        ? (widget.subtitleAr ?? 'جاري مزامنة وجلب السجلات من الخادم...')
        : (widget.subtitleEn ?? 'Fetching real-time records from server...');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Prominent Hero Loading Card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Dual Ring Spinner with Center Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer subtle pulse ring
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF16A34A).withValues(
                            alpha: 0.12 * _pulseAnimation.value,
                          ),
                        ),
                      );
                    },
                  ),
                  // Progress spinner
                  const SizedBox(
                    width: 46,
                    height: 46,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                      backgroundColor: Color(0xFFDCFCE7),
                    ),
                  ),
                  // Center glowing icon
                  Icon(
                    widget.icon,
                    size: 20,
                    color: const Color(0xFF16A34A),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),

              // Animated "Connecting / Loading" Chip
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7).withValues(
                        alpha: 0.6 + (0.4 * _pulseAnimation.value),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.isRtl ? 'جاري التحميل...' : 'Loading Data...',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Animated Skeleton Shimmer Placeholder Cards
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final opacity = 0.35 + (_pulseAnimation.value * 0.45);
            return Column(
              children: List.generate(3, (index) {
                return Opacity(
                  opacity: opacity,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Skeleton Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Skeleton Text Bars
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120 + (index * 20.0),
                                height: 12,
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 80,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Skeleton Action Pills
                        Container(
                          width: 50,
                          height: 20,
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
