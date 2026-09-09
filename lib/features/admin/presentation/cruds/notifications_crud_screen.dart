import 'dart:async';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/services/coupon_repository.dart';
import '../../../../core/services/flyer_repository.dart';
import '../../../../core/services/notification_repository.dart';
import '../../../../core/services/offer_repository.dart';
import '../../../../core/services/product_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../core/widgets/custom_select_widget.dart';
import '../../../../models/models.dart';
import '../widgets/crud_loading_widget.dart';

class NotificationsCrudScreen extends ConsumerStatefulWidget {
  const NotificationsCrudScreen({super.key});

  @override
  ConsumerState<NotificationsCrudScreen> createState() => _NotificationsCrudScreenState();
}

class _NotificationsCrudScreenState extends ConsumerState<NotificationsCrudScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  String _searchQuery = '';
  String _selectedTypeFilter = 'ALL';
  String _selectedChannelFilter = 'ALL';

  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      ref.read(offerRepositoryProvider.notifier).fetchOffers();
      ref.read(flyerRepositoryProvider.notifier).fetchFlyers();
      ref.read(productRepositoryProvider.notifier).fetchProducts();
      ref.read(couponRepositoryProvider.notifier).fetchCoupons();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await ref.read(notificationRepositoryProvider.notifier).fetchAllNotifications(
          page: _currentPage,
          size: _pageSize,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          type: _selectedTypeFilter != 'ALL' ? _selectedTypeFilter : null,
          channel: _selectedChannelFilter != 'ALL' ? _selectedChannelFilter : null,
        );
  }

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim();
          _currentPage = 0;
        });
        _loadData();
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedTypeFilter = 'ALL';
      _selectedChannelFilter = 'ALL';
      _currentPage = 0;
    });
    _loadData();
  }

  // --- Helpers for Notification Styles ---
  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'FLASH_DEAL':
        return Icons.bolt_rounded;
      case 'PRICE_DROP':
        return Icons.trending_down_rounded;
      case 'OFFER_EXPIRY':
        return Icons.timer_outlined;
      case 'NEW_FLYER':
        return Icons.menu_book_rounded;
      case 'COUPON_ALERT':
        return Icons.confirmation_number_outlined;
      case 'PRODUCT_ALERT':
        return Icons.inventory_2_outlined;
      default:
        return Icons.campaign_rounded;
    }
  }

  String _getTypeLabel(String type, bool isRtl) {
    switch (type.toUpperCase()) {
      case 'FLASH_DEAL':
        return isRtl ? 'عرض خاص' : 'FLASH DEAL';
      case 'PRICE_DROP':
        return isRtl ? 'تخفيض سعر' : 'PRICE DROP';
      case 'OFFER_EXPIRY':
        return isRtl ? 'انتهاء عرض' : 'OFFER EXPIRY';
      case 'NEW_FLYER':
        return isRtl ? 'مجلة جديدة' : 'NEW FLYER';
      case 'COUPON_ALERT':
        return isRtl ? 'كوبون خصم' : 'COUPON ALERT';
      case 'PRODUCT_ALERT':
        return isRtl ? 'تنبيه منتج' : 'PRODUCT ALERT';
      default:
        return isRtl ? 'إعلان نظام' : 'SYSTEM';
    }
  }

  Color _getTypeBgColor(String type, bool isDark) {
    switch (type.toUpperCase()) {
      case 'FLASH_DEAL':
        return isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFEE2E2);
      case 'PRICE_DROP':
        return isDark ? const Color(0xFF14532D).withValues(alpha: 0.35) : const Color(0xFFDCFCE7);
      case 'OFFER_EXPIRY':
        return isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.35) : const Color(0xFFFFEDD5);
      case 'NEW_FLYER':
        return isDark ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7);
      case 'COUPON_ALERT':
        return isDark ? const Color(0xFF581C87).withValues(alpha: 0.35) : const Color(0xFFF3E8FF);
      default:
        return isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    }
  }

  Color _getTypeTextColor(String type, bool isDark) {
    switch (type.toUpperCase()) {
      case 'FLASH_DEAL':
        return isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
      case 'PRICE_DROP':
        return isDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A);
      case 'OFFER_EXPIRY':
        return isDark ? const Color(0xFFFDBA74) : const Color(0xFFEA580C);
      case 'NEW_FLYER':
        return isDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706);
      case 'COUPON_ALERT':
        return isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA);
      default:
        return isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    }
  }

  IconData _getChannelIcon(String channel) {
    switch (channel.toUpperCase()) {
      case 'PUSH':
        return Icons.notifications_active_outlined;
      case 'EMAIL':
        return Icons.email_outlined;
      case 'SMS':
        return Icons.sms_outlined;
      default:
        return Icons.campaign_outlined;
    }
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '—';
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('MMM d, yyyy • h:mm a').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  // --- Delete Confirmation ---
  Future<void> _deleteNotification(Notification notif, bool isRtl, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isRtl ? 'حذف سجل الإشعار؟' : 'Delete Notification Log?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isRtl
              ? 'هل أنت متأكد من رغبتك في حذف سجل الإشعار #${notif.id} نهائياً؟'
              : 'Are you sure you want to permanently delete notification record #${notif.id}?',
          style: TextStyle(
            fontSize: 13.5,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              isRtl ? 'إلغاء' : 'Cancel',
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isRtl ? 'نعم، احذف' : 'Yes, Delete',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(notificationRepositoryProvider.notifier).deleteNotification(notif.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isRtl ? 'تم حذف الإشعار بنجاح' : 'Notification deleted successfully'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isRtl ? 'فشل الحذف: $e' : 'Failed to delete: $e'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // --- Compose & Broadcast Modal with Live Push Preview ---
  void _showBroadcastModal(BuildContext context, bool isRtl, bool isDark) {
    final formKey = GlobalKey<FormState>();
    final titleEnCtrl = TextEditingController();
    final titleArCtrl = TextEditingController();
    final bodyEnCtrl = TextEditingController();
    final bodyArCtrl = TextEditingController();
    final deepLinkCtrl = TextEditingController();
    final targetUserIdCtrl = TextEditingController();
    final productSearchCtrl = TextEditingController();

    String selectedType = 'FLASH_DEAL';
    String selectedChannel = 'PUSH';
    String selectedRefType = 'OFFER';
    int? selectedRefId;
    String selectedTargetAudience = 'ALL';

    int productPage = 0;
    const int productPageSize = 6;
    bool isSubmitting = false;
    String? submitError;

    final refTypeOptions = [
      CustomSelectOption<String>(
        value: 'OFFER',
        labelEn: 'Related Offer',
        labelAr: 'عرض مرتبط',
        icon: Icons.local_offer_outlined,
      ),
      CustomSelectOption<String>(
        value: 'FLYER',
        labelEn: 'Related Flyer',
        labelAr: 'مجلة عروض مرتبطة',
        icon: Icons.menu_book_rounded,
      ),
      CustomSelectOption<String>(
        value: 'PRODUCT',
        labelEn: 'Related Product',
        labelAr: 'منتج مرتبط',
        icon: Icons.inventory_2_outlined,
      ),
      CustomSelectOption<String>(
        value: 'COUPON',
        labelEn: 'Related Coupon',
        labelAr: 'كوبون مرتبط',
        icon: Icons.confirmation_number_outlined,
      ),
      CustomSelectOption<String>(
        value: 'SYSTEM',
        labelEn: 'General / No Entity',
        labelAr: 'عام / بدون ارتباط',
        icon: Icons.campaign_rounded,
      ),
    ];

    final typeOptions = [
      CustomSelectOption<String>(value: 'FLASH_DEAL', labelEn: 'Flash Deal Announcement', labelAr: 'عرض خاص محدود', icon: Icons.bolt_rounded),
      CustomSelectOption<String>(value: 'PRICE_DROP', labelEn: 'Price Drop Alert', labelAr: 'تخفيض في السعر', icon: Icons.trending_down_rounded),
      CustomSelectOption<String>(value: 'OFFER_EXPIRY', labelEn: 'Offer Expiry Alert', labelAr: 'تنبيه انتهاء العرض', icon: Icons.timer_outlined),
      CustomSelectOption<String>(value: 'NEW_FLYER', labelEn: 'New Flyer Release', labelAr: 'مجلة عروض جديدة', icon: Icons.menu_book_rounded),
      CustomSelectOption<String>(value: 'COUPON_ALERT', labelEn: 'Coupon & Promo Code', labelAr: 'كوبون ورمز خصم', icon: Icons.confirmation_number_outlined),
      CustomSelectOption<String>(value: 'PRODUCT_ALERT', labelEn: 'Product Alert', labelAr: 'تنبيه منتج', icon: Icons.inventory_2_outlined),
      CustomSelectOption<String>(value: 'SYSTEM', labelEn: 'System Announcement', labelAr: 'إعلان من النظام', icon: Icons.campaign_rounded),
    ];

    final channelOptions = [
      CustomSelectOption<String>(value: 'PUSH', labelEn: 'Push Notification (App & Web)', labelAr: 'إشعار فوري (تطبيق وموقع)', icon: Icons.notifications_active_outlined),
      CustomSelectOption<String>(value: 'EMAIL', labelEn: 'Email Notification', labelAr: 'بريد إلكتروني', icon: Icons.email_outlined),
      CustomSelectOption<String>(value: 'SMS', labelEn: 'SMS Text Message', labelAr: 'رسالة نصية SMS', icon: Icons.sms_outlined),
    ];

    final audienceOptions = [
      CustomSelectOption<String>(value: 'ALL', labelEn: 'All Registered Customers (Broadcast)', labelAr: 'كافة العملاء المسجلين (بث عام)', icon: Icons.group_rounded),
      CustomSelectOption<String>(value: 'USER', labelEn: 'Specific User by ID', labelAr: 'مستخدم محدد بالمعرف', icon: Icons.person_outline_rounded),
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          final offers = ref.read(offerRepositoryProvider).offers;
          final flyers = ref.read(flyerRepositoryProvider).flyers;
          final allProducts = ref.read(productRepositoryProvider).products;
          final coupons = ref.read(couponRepositoryProvider);

          final screenWidth = MediaQuery.of(context).size.width;
          final dialogWidth = screenWidth > 1100 ? 1020.0 : (screenWidth > 768 ? 760.0 : double.maxFinite);

          // Filter products for paginated search
          final qProduct = productSearchCtrl.text.trim().toLowerCase();
          final filteredProducts = allProducts.where((p) {
            if (qProduct.isEmpty) return true;
            return p.nameEn.toLowerCase().contains(qProduct) ||
                p.nameAr.toLowerCase().contains(qProduct) ||
                (p.brand?.toLowerCase().contains(qProduct) ?? false);
          }).toList();

          final totalProductPages = (filteredProducts.length / productPageSize).ceil().clamp(1, 9999);
          final safeProductPage = productPage.clamp(0, totalProductPages - 1);
          final paginatedProducts = filteredProducts.skip(safeProductPage * productPageSize).take(productPageSize).toList();

          // Auto-fill logic from selected entity
          void autoFillFromEntity() {
            if (selectedRefId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isRtl ? 'يرجى اختيار عنصر أولاً' : 'Please select an item first'),
                  backgroundColor: const Color(0xFFD97706),
                ),
              );
              return;
            }

            if (selectedRefType == 'OFFER') {
              final o = offers.where((x) => x.id == selectedRefId).firstOrNull;
              if (o != null) {
                setModalState(() {
                  titleEnCtrl.text = '🔥 Hot Deal: ${o.titleEn}';
                  titleArCtrl.text = '🔥 عرض خاص: ${o.titleAr}';
                  bodyEnCtrl.text = 'Exclusive price of ${o.offerPrice} SAR on ${o.titleEn}! Limited time deal, tap to explore.';
                  bodyArCtrl.text = 'سعر مميز يبدأ من ${o.offerPrice} ريال على ${o.titleAr}! لفترة محدودة، اضغط للتفاصيل.';
                  deepLinkCtrl.text = '/offers/$selectedRefId';
                  selectedType = 'FLASH_DEAL';
                });
              }
            } else if (selectedRefType == 'FLYER') {
              final f = flyers.where((x) => x.id == selectedRefId).firstOrNull;
              if (f != null) {
                setModalState(() {
                  titleEnCtrl.text = '📰 New Flyer: ${f.titleEn}';
                  titleArCtrl.text = '📰 مجلة عروض جديدة: ${f.titleAr}';
                  bodyEnCtrl.text = 'Explore the latest promotion flyer and save big on your weekly groceries!';
                  bodyArCtrl.text = 'تصفح أحدث مجلات العروض ووفر في مشترياتك اليومية والأسبوعية!';
                  deepLinkCtrl.text = '/flyers/$selectedRefId';
                  selectedType = 'NEW_FLYER';
                });
              }
            } else if (selectedRefType == 'PRODUCT') {
              final p = allProducts.where((x) => x.id == selectedRefId).firstOrNull;
              if (p != null) {
                setModalState(() {
                  titleEnCtrl.text = '⭐ Price Alert: ${p.nameEn}';
                  titleArCtrl.text = '⭐ تنبيه سعر: ${p.nameAr}';
                  bodyEnCtrl.text = 'Check out the best available deals for ${p.nameEn} across stores near you.';
                  bodyArCtrl.text = 'اكتشف أفضل العروض والأسعار لمنتج ${p.nameAr} في المتاجر القريبة منك.';
                  deepLinkCtrl.text = '/products/$selectedRefId';
                  selectedType = 'PRICE_DROP';
                });
              }
            } else if (selectedRefType == 'COUPON') {
              final c = coupons.where((x) => x.id == selectedRefId).firstOrNull;
              if (c != null) {
                setModalState(() {
                  titleEnCtrl.text = '🎟️ Promo Code: ${c.code}';
                  titleArCtrl.text = '🎟️ كود خصم جديد: ${c.code}';
                  bodyEnCtrl.text = 'Use discount coupon code ${c.code} for instant extra savings at checkout!';
                  bodyArCtrl.text = 'استخدم كود الخصم ${c.code} للحصول على توفير فوري إضافي عند الدفع!';
                  deepLinkCtrl.text = '/coupons';
                  selectedType = 'COUPON_ALERT';
                });
              }
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isRtl ? 'تمت التعبئة التلقائية بنجاح!' : 'Auto-Filled successfully!'),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 1),
              ),
            );
          }

          final isWide = screenWidth > 768;

          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Dialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              elevation: 24,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isWide ? 24 : 12,
                vertical: isWide ? 24 : 16,
              ),
              child: Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.90,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Modal Header ---
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 24 : 16,
                        vertical: isWide ? 18 : 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: isWide ? 44 : 38,
                            height: isWide ? 44 : 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              Icons.campaign_rounded,
                              color: const Color(0xFF10B981),
                              size: isWide ? 24 : 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isRtl ? 'صياغة وبث إشعار للمستخدمين' : 'Compose & Broadcast Notification',
                                  style: TextStyle(
                                    fontSize: isWide ? 17 : 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isRtl
                                      ? 'ربط العروض والمجلات والمنتجات وإرسال التنبيهات الفورية للمستخدمين.'
                                      : 'Link contextual offers/flyers/products and deliver real-time notifications.',
                                  style: TextStyle(
                                    fontSize: isWide ? 12 : 11,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => Navigator.pop(modalCtx),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Modal Body Scrollable ---
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isWide ? 24 : 14),
                        child: Form(
                          key: formKey,
                          child: Builder(
                            builder: (context) {
                              // Left Column: Form Fields
                              final formFieldsColumn = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (submitError != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFFCA5A5)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              submitError!,
                                              style: const TextStyle(
                                                color: Color(0xFFDC2626),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // 1. Entity Linker Box
                                  Container(
                                    padding: EdgeInsets.all(isWide ? 16 : 12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF10B981).withValues(alpha: 0.05)
                                          : const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.link_rounded, size: 18, color: Color(0xFF10B981)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                isRtl ? 'ربط عرض أو عنصر ذي صلة' : 'Link Related Deal / Entity',
                                                style: TextStyle(
                                                  fontSize: isWide ? 13.5 : 12.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Item Type Selector
                                        _buildFieldLabel(isRtl ? 'نوع العنصر' : 'Item Type', true, isDark),
                                        const SizedBox(height: 6),
                                        AppCustomSelect<String>(
                                          options: refTypeOptions,
                                          selectedValue: selectedRefType,
                                          onChanged: (val) {
                                            if (val != null) {
                                              setModalState(() {
                                                selectedRefType = val;
                                                selectedRefId = null;
                                                if (val == 'OFFER') deepLinkCtrl.text = '/offers';
                                                if (val == 'FLYER') deepLinkCtrl.text = '/flyers';
                                                if (val == 'PRODUCT') deepLinkCtrl.text = '/products';
                                                if (val == 'COUPON') deepLinkCtrl.text = '/coupons';
                                                if (val == 'SYSTEM') deepLinkCtrl.text = '';
                                              });
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 12),

                                        // Dynamic Pickers
                                        if (selectedRefType == 'OFFER') ...[
                                          _buildFieldLabel(isRtl ? 'اختر العرض *' : 'Select Offer *', true, isDark),
                                          const SizedBox(height: 6),
                                          AppCustomSelect<int?>(
                                            options: offers
                                                .map((o) => CustomSelectOption<int?>(
                                                      value: o.id,
                                                      labelEn: '${o.titleEn} (${o.offerPrice} SAR)',
                                                      labelAr: '${o.titleAr} (${o.offerPrice} ريال)',
                                                    ))
                                                .toList(),
                                            selectedValue: selectedRefId,
                                            placeholder: isRtl ? '-- اختر العرض --' : '-- Select Offer --',
                                            onChanged: (val) {
                                              setModalState(() {
                                                selectedRefId = val;
                                                if (val != null) deepLinkCtrl.text = '/offers/$val';
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                        ] else if (selectedRefType == 'FLYER') ...[
                                          _buildFieldLabel(isRtl ? 'اختر مجلة العروض *' : 'Select Flyer *', true, isDark),
                                          const SizedBox(height: 6),
                                          AppCustomSelect<int?>(
                                            options: flyers
                                                .map((f) => CustomSelectOption<int?>(
                                                      value: f.id,
                                                      labelEn: f.titleEn,
                                                      labelAr: f.titleAr,
                                                    ))
                                                .toList(),
                                            selectedValue: selectedRefId,
                                            placeholder: isRtl ? '-- اختر المجلة --' : '-- Select Flyer --',
                                            onChanged: (val) {
                                              setModalState(() {
                                                selectedRefId = val;
                                                if (val != null) deepLinkCtrl.text = '/flyers/$val';
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                        ] else if (selectedRefType == 'PRODUCT') ...[
                                          _buildFieldLabel(isRtl ? 'بحث واختيار المنتج *' : 'Search & Select Product *', true, isDark),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                TextField(
                                                  controller: productSearchCtrl,
                                                  onChanged: (_) => setModalState(() => productPage = 0),
                                                  decoration: InputDecoration(
                                                    hintText: isRtl ? 'ابحث عن المنتجات...' : 'Search products...',
                                                    hintStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                                    suffixIcon: productSearchCtrl.text.isNotEmpty
                                                        ? IconButton(
                                                            icon: const Icon(Icons.close_rounded, size: 16),
                                                            onPressed: () {
                                                              productSearchCtrl.clear();
                                                              setModalState(() => productPage = 0);
                                                            },
                                                          )
                                                        : null,
                                                    isDense: true,
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                    enabledBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                if (paginatedProducts.isEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    child: Center(
                                                      child: Text(
                                                        isRtl ? 'لم يتم العثور على منتجات' : 'No products found matching query',
                                                        style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  ...paginatedProducts.map((p) {
                                                    final isSelected = selectedRefId == p.id;
                                                    return InkWell(
                                                      onTap: () {
                                                        setModalState(() {
                                                          selectedRefId = p.id;
                                                          deepLinkCtrl.text = '/products/${p.id}';
                                                        });
                                                      },
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Container(
                                                        margin: const EdgeInsets.symmetric(vertical: 2),
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                                        decoration: BoxDecoration(
                                                          color: isSelected
                                                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(
                                                            color: isSelected ? const Color(0xFF10B981) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                '${isRtl ? p.nameAr : p.nameEn} ${p.brand != null ? "[${p.brand}]" : ""}',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                                  color: isSelected
                                                                      ? const Color(0xFF10B981)
                                                                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                                                ),
                                                              ),
                                                            ),
                                                            if (isSelected)
                                                              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                if (totalProductPages > 1) ...[
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        isRtl
                                                            ? 'صفحة ${safeProductPage + 1} من $totalProductPages'
                                                            : 'Page ${safeProductPage + 1} of $totalProductPages',
                                                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                                      ),
                                                      Row(
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.chevron_left_rounded, size: 18),
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(),
                                                            onPressed: safeProductPage > 0
                                                                ? () => setModalState(() => productPage = safeProductPage - 1)
                                                                : null,
                                                          ),
                                                          const SizedBox(width: 8),
                                                          IconButton(
                                                            icon: const Icon(Icons.chevron_right_rounded, size: 18),
                                                            padding: EdgeInsets.zero,
                                                            constraints: const BoxConstraints(),
                                                            onPressed: safeProductPage < totalProductPages - 1
                                                                ? () => setModalState(() => productPage = safeProductPage + 1)
                                                                : null,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                        ] else if (selectedRefType == 'COUPON') ...[
                                          _buildFieldLabel(isRtl ? 'اختر الكوبون *' : 'Select Coupon *', true, isDark),
                                          const SizedBox(height: 6),
                                          AppCustomSelect<int?>(
                                            options: coupons
                                                .map((c) => CustomSelectOption<int?>(
                                                      value: c.id,
                                                      labelEn: '${c.code} (${c.discountValue}% Off)',
                                                      labelAr: '${c.code} (خصم ${c.discountValue}%)',
                                                    ))
                                                .toList(),
                                            selectedValue: selectedRefId,
                                            placeholder: isRtl ? '-- اختر الكوبون --' : '-- Select Coupon --',
                                            onChanged: (val) {
                                              setModalState(() {
                                                selectedRefId = val;
                                                if (val != null) deepLinkCtrl.text = '/coupons';
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                        ],

                                        // Quick Auto-Fill Action Button
                                        if (selectedRefId != null)
                                          InkWell(
                                            onTap: autoFillFromEntity,
                                            borderRadius: BorderRadius.circular(10),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: const Color(0xFF10B981).withValues(alpha: 0.6),
                                                  width: 1.4,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFF10B981)),
                                                  const SizedBox(width: 6),
                                                  Flexible(
                                                    child: Text(
                                                      isRtl ? 'تعبئة العنوان والنص تلقائياً' : 'Auto-Fill Title & Message',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF10B981),
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Type & Channel Row
                                  if (isWide)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildFieldLabel(isRtl ? 'نوع الإشعار *' : 'Notification Type *', true, isDark),
                                              const SizedBox(height: 6),
                                              AppCustomSelect<String>(
                                                options: typeOptions,
                                                selectedValue: selectedType,
                                                onChanged: (val) {
                                                  if (val != null) setModalState(() => selectedType = val);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildFieldLabel(isRtl ? 'قناة الوصول *' : 'Delivery Channel *', true, isDark),
                                              const SizedBox(height: 6),
                                              AppCustomSelect<String>(
                                                options: channelOptions,
                                                selectedValue: selectedChannel,
                                                onChanged: (val) {
                                                  if (val != null) setModalState(() => selectedChannel = val);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    _buildFieldLabel(isRtl ? 'نوع الإشعار *' : 'Notification Type *', true, isDark),
                                    const SizedBox(height: 6),
                                    AppCustomSelect<String>(
                                      options: typeOptions,
                                      selectedValue: selectedType,
                                      onChanged: (val) {
                                        if (val != null) setModalState(() => selectedType = val);
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _buildFieldLabel(isRtl ? 'قناة الوصول *' : 'Delivery Channel *', true, isDark),
                                    const SizedBox(height: 6),
                                    AppCustomSelect<String>(
                                      options: channelOptions,
                                      selectedValue: selectedChannel,
                                      onChanged: (val) {
                                        if (val != null) setModalState(() => selectedChannel = val);
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 16),

                                  // Titles (English & Arabic)
                                  _buildFieldLabel(isRtl ? 'العنوان (الإنجليزية) *' : 'Title (English) *', true, isDark),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: titleEnCtrl,
                                    onChanged: (_) => setModalState(() {}),
                                    decoration: _buildInputDecoration(
                                      hint: 'e.g. Flash 50% Off on Fresh Produce!',
                                      icon: Icons.title_rounded,
                                      isDark: isDark,
                                    ),
                                    validator: (val) => (val == null || val.trim().isEmpty) ? 'English title is required' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  _buildFieldLabel(isRtl ? 'العنوان (العربية) *' : 'Title (Arabic) *', true, isDark),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: titleArCtrl,
                                    onChanged: (_) => setModalState(() {}),
                                    decoration: _buildInputDecoration(
                                      hint: 'مثال: خصم 50% على المنتجات الطازجة لفترة محدودة!',
                                      icon: Icons.title_rounded,
                                      isDark: isDark,
                                    ),
                                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Arabic title is required' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  // Message Bodies
                                  if (isWide)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildFieldLabel(isRtl ? 'نص الرسالة (الإنجليزية)' : 'Message Body (English)', false, isDark),
                                              const SizedBox(height: 6),
                                              TextFormField(
                                                controller: bodyEnCtrl,
                                                maxLines: 2,
                                                onChanged: (_) => setModalState(() {}),
                                                decoration: _buildInputDecoration(
                                                  hint: 'Detailed notification message in English...',
                                                  icon: Icons.subject_rounded,
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildFieldLabel(isRtl ? 'نص الرسالة (العربية)' : 'Message Body (Arabic)', false, isDark),
                                              const SizedBox(height: 6),
                                              TextFormField(
                                                controller: bodyArCtrl,
                                                maxLines: 2,
                                                onChanged: (_) => setModalState(() {}),
                                                decoration: _buildInputDecoration(
                                                  hint: 'نص الإشعار التفصيلي بالعربية...',
                                                  icon: Icons.subject_rounded,
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    _buildFieldLabel(isRtl ? 'نص الرسالة (الإنجليزية)' : 'Message Body (English)', false, isDark),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: bodyEnCtrl,
                                      maxLines: 2,
                                      onChanged: (_) => setModalState(() {}),
                                      decoration: _buildInputDecoration(
                                        hint: 'Detailed notification message in English...',
                                        icon: Icons.subject_rounded,
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildFieldLabel(isRtl ? 'نص الرسالة (العربية)' : 'Message Body (Arabic)', false, isDark),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: bodyArCtrl,
                                      maxLines: 2,
                                      onChanged: (_) => setModalState(() {}),
                                      decoration: _buildInputDecoration(
                                        hint: 'نص الإشعار التفصيلي بالعربية...',
                                        icon: Icons.subject_rounded,
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),

                                  // Deep Link & Audience
                                  if (isWide)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildFieldLabel(isRtl ? 'رابط التوجيه المباشر' : 'In-App Deep Link URL', false, isDark),
                                              const SizedBox(height: 6),
                                              TextFormField(
                                                controller: deepLinkCtrl,
                                                onChanged: (_) => setModalState(() {}),
                                                decoration: _buildInputDecoration(
                                                  hint: '/offers/123 or /flyers/45',
                                                  icon: Icons.link_rounded,
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildFieldLabel(isRtl ? 'الجمهور المستهدف' : 'Target Audience', true, isDark),
                                              const SizedBox(height: 6),
                                              AppCustomSelect<String>(
                                                options: audienceOptions,
                                                selectedValue: selectedTargetAudience,
                                                onChanged: (val) {
                                                  if (val != null) setModalState(() => selectedTargetAudience = val);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  else ...[
                                    _buildFieldLabel(isRtl ? 'رابط التوجيه المباشر' : 'In-App Deep Link URL', false, isDark),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: deepLinkCtrl,
                                      onChanged: (_) => setModalState(() {}),
                                      decoration: _buildInputDecoration(
                                        hint: '/offers/123 or /flyers/45',
                                        icon: Icons.link_rounded,
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildFieldLabel(isRtl ? 'الجمهور المستهدف' : 'Target Audience', true, isDark),
                                    const SizedBox(height: 6),
                                    AppCustomSelect<String>(
                                      options: audienceOptions,
                                      selectedValue: selectedTargetAudience,
                                      onChanged: (val) {
                                        if (val != null) setModalState(() => selectedTargetAudience = val);
                                      },
                                    ),
                                  ],

                                  if (selectedTargetAudience == 'USER') ...[
                                    const SizedBox(height: 16),
                                    _buildFieldLabel(isRtl ? 'معرف المستخدم المستهدف *' : 'Target User ID *', true, isDark),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: targetUserIdCtrl,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setModalState(() {}),
                                      decoration: _buildInputDecoration(
                                        hint: 'e.g. 101',
                                        icon: Icons.person_search_rounded,
                                        isDark: isDark,
                                      ),
                                      validator: (val) => (val == null || int.tryParse(val.trim()) == null)
                                          ? 'Valid user ID required'
                                          : null,
                                    ),
                                  ],
                                ],
                              );

                              // Right Column: Live Push Notification Preview Card
                              final livePreviewColumn = Container(
                                padding: EdgeInsets.all(isWide ? 18 : 14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.devices_rounded,
                                          size: 18,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isRtl ? 'معاينة الإشعار الفوري' : 'Live Alert Preview',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Mobile Push Notification Simulated Box
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                                            blurRadius: 14,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Icon(Icons.campaign_rounded, size: 14, color: Color(0xFF10B981)),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    const Text(
                                                      'DealSpot',
                                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                          color: _getTypeBgColor(selectedType, isDark),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          selectedType,
                                                          style: TextStyle(
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.w800,
                                                            color: _getTypeTextColor(selectedType, isDark),
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isRtl ? 'الآن' : 'now',
                                                style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            (isRtl ? titleArCtrl.text : titleEnCtrl.text).isNotEmpty
                                                ? (isRtl ? titleArCtrl.text : titleEnCtrl.text)
                                                : (isRtl ? 'إشعار عرض خاص' : 'Flash Deal Notification'),
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            (isRtl ? bodyArCtrl.text : bodyEnCtrl.text).isNotEmpty
                                                ? (isRtl ? bodyArCtrl.text : bodyEnCtrl.text)
                                                : (isRtl
                                                    ? 'اضغط لاستكشاف الخصومات الحصرية المتاحة الآن على ديل سبوت!'
                                                    : 'Tap to explore exclusive discounts available now on DealSpot!'),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                              height: 1.35,
                                            ),
                                          ),
                                          if (deepLinkCtrl.text.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.open_in_new_rounded, size: 11, color: Color(0xFF10B981)),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      deepLinkCtrl.text,
                                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // Audience Coverage Summary
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(Icons.group_rounded, size: 18, color: Color(0xFF2563EB)),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  isRtl ? 'نطاق الجمهور' : 'Audience Coverage',
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  selectedTargetAudience == 'ALL'
                                                      ? (isRtl ? 'كافة مستخدمي ديل سبوت المسجلين' : 'All Registered DealSpot Customers')
                                                      : (isRtl ? 'مستخدم محدد #${targetUserIdCtrl.text.isEmpty ? "-" : targetUserIdCtrl.text}' : 'Single User #${targetUserIdCtrl.text.isEmpty ? "-" : targetUserIdCtrl.text}'),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                              );

                              if (isWide) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 7, child: formFieldsColumn),
                                    const SizedBox(width: 24),
                                    Expanded(flex: 5, child: livePreviewColumn),
                                  ],
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  formFieldsColumn,
                                  const SizedBox(height: 20),
                                  livePreviewColumn,
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // --- Modal Footer ---
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 24 : 16,
                        vertical: isWide ? 16 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: Border(
                          top: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isWide) ...[
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: isSubmitting ? null : () => Navigator.pop(modalCtx),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  isRtl ? 'إلغاء' : 'Cancel',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        if (formKey.currentState?.validate() != true) return;
                                        setModalState(() {
                                          isSubmitting = true;
                                          submitError = null;
                                        });

                                        try {
                                          final payload = BroadcastNotificationPayload(
                                            titleEn: titleEnCtrl.text.trim(),
                                            titleAr: titleArCtrl.text.trim(),
                                            bodyEn: bodyEnCtrl.text.trim().isNotEmpty ? bodyEnCtrl.text.trim() : null,
                                            bodyAr: bodyArCtrl.text.trim().isNotEmpty ? bodyArCtrl.text.trim() : null,
                                            type: selectedType,
                                            channel: selectedChannel,
                                            refType: selectedRefType != 'SYSTEM' ? selectedRefType : null,
                                            refId: selectedRefId,
                                            deepLink: deepLinkCtrl.text.trim().isNotEmpty ? deepLinkCtrl.text.trim() : null,
                                            targetUserId: selectedTargetAudience == 'USER' ? int.tryParse(targetUserIdCtrl.text.trim()) : null,
                                          );

                                          await ref.read(notificationRepositoryProvider.notifier).broadcastNotification(payload);

                                          if (modalCtx.mounted) Navigator.pop(modalCtx);

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(isRtl ? 'تم إرسال الإشعار بنجاح!' : 'Notification Broadcast Sent!'),
                                                backgroundColor: const Color(0xFF10B981),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                            _loadData();
                                          }
                                        } catch (e) {
                                          setModalState(() {
                                            isSubmitting = false;
                                            submitError = e.toString();
                                          });
                                        }
                                      },
                                icon: isSubmitting
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.send_rounded, size: 15),
                                label: Text(
                                  isRtl ? 'إرسال الإشعار' : 'Send Broadcast Now',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  elevation: 1,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ] else ...[
                            OutlinedButton(
                              onPressed: isSubmitting ? null : () => Navigator.pop(modalCtx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                isRtl ? 'إلغاء' : 'Cancel',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (formKey.currentState?.validate() != true) return;
                                      setModalState(() {
                                        isSubmitting = true;
                                        submitError = null;
                                      });

                                      try {
                                        final payload = BroadcastNotificationPayload(
                                          titleEn: titleEnCtrl.text.trim(),
                                          titleAr: titleArCtrl.text.trim(),
                                          bodyEn: bodyEnCtrl.text.trim().isNotEmpty ? bodyEnCtrl.text.trim() : null,
                                          bodyAr: bodyArCtrl.text.trim().isNotEmpty ? bodyArCtrl.text.trim() : null,
                                          type: selectedType,
                                          channel: selectedChannel,
                                          refType: selectedRefType != 'SYSTEM' ? selectedRefType : null,
                                          refId: selectedRefId,
                                          deepLink: deepLinkCtrl.text.trim().isNotEmpty ? deepLinkCtrl.text.trim() : null,
                                          targetUserId: selectedTargetAudience == 'USER' ? int.tryParse(targetUserIdCtrl.text.trim()) : null,
                                        );

                                        await ref.read(notificationRepositoryProvider.notifier).broadcastNotification(payload);

                                        if (modalCtx.mounted) Navigator.pop(modalCtx);

                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(isRtl ? 'تم إرسال الإشعار بنجاح!' : 'Notification Broadcast Sent!'),
                                              backgroundColor: const Color(0xFF10B981),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          _loadData();
                                        }
                                      } catch (e) {
                                        setModalState(() {
                                          isSubmitting = false;
                                          submitError = e.toString();
                                        });
                                      }
                                    },
                              icon: isSubmitting
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send_rounded, size: 16),
                              label: Text(
                                isRtl ? 'إرسال الإشعار الآن' : 'Send Broadcast Now',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      prefixIcon: Icon(
        icon,
        size: 18,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 12.5,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildFieldLabel(String label, bool isRequired, bool isDark) {
    return RichText(
      text: TextSpan(
        text: label.replaceAll(' *', ''),
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final notifState = ref.watch(notificationRepositoryProvider);
    final offers = ref.watch(offerRepositoryProvider).offers;
    final flyers = ref.watch(flyerRepositoryProvider).flyers;

    final notifications = notifState.notifications;
    final totalCount = notifState.totalCount;
    final totalPages = (totalCount / _pageSize).ceil().clamp(1, 9999);

    final typeFilterOptions = [
      CustomSelectOption<String>(value: 'ALL', labelEn: 'All Types', labelAr: 'جميع الأنواع'),
      CustomSelectOption<String>(value: 'FLASH_DEAL', labelEn: 'Flash Deal Announcement', labelAr: 'عرض خاص محدود', icon: Icons.bolt_rounded),
      CustomSelectOption<String>(value: 'PRICE_DROP', labelEn: 'Price Drop Alert', labelAr: 'تخفيض في السعر', icon: Icons.trending_down_rounded),
      CustomSelectOption<String>(value: 'OFFER_EXPIRY', labelEn: 'Offer Expiry Alert', labelAr: 'تنبيه انتهاء العرض', icon: Icons.timer_outlined),
      CustomSelectOption<String>(value: 'NEW_FLYER', labelEn: 'New Flyer Release', labelAr: 'مجلة عروض جديدة', icon: Icons.menu_book_rounded),
      CustomSelectOption<String>(value: 'COUPON_ALERT', labelEn: 'Coupon & Promo Code', labelAr: 'كوبون ورمز خصم', icon: Icons.confirmation_number_outlined),
      CustomSelectOption<String>(value: 'PRODUCT_ALERT', labelEn: 'Product Alert', labelAr: 'تنبيه منتج', icon: Icons.inventory_2_outlined),
      CustomSelectOption<String>(value: 'SYSTEM', labelEn: 'System Announcement', labelAr: 'إعلان من النظام', icon: Icons.campaign_rounded),
    ];

    final channelFilterOptions = [
      CustomSelectOption<String>(value: 'ALL', labelEn: 'All Channels', labelAr: 'جميع القنوات'),
      CustomSelectOption<String>(value: 'PUSH', labelEn: 'Push Notification (App & Web)', labelAr: 'إشعار فوري (تطبيق وموقع)', icon: Icons.notifications_active_outlined),
      CustomSelectOption<String>(value: 'EMAIL', labelEn: 'Email Notification', labelAr: 'بريد إلكتروني', icon: Icons.email_outlined),
      CustomSelectOption<String>(value: 'SMS', labelEn: 'SMS Text Message', labelAr: 'رسالة نصية SMS', icon: Icons.sms_outlined),
    ];

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF10B981),
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Header Row
                      _buildHeader(context, isRtl, isDark),
                      const SizedBox(height: 20),

                      // 2. Stats Grid
                      _buildStatsGrid(totalCount, offers.length, flyers.length, isRtl, isDark),
                      const SizedBox(height: 20),

                      // 3. Filters Toolbar
                      _buildFiltersToolbar(context, typeFilterOptions, channelFilterOptions, isRtl, isDark),
                      const SizedBox(height: 20),

                      // 4. Content Area (Unified Responsive Notifications List)
                      if (notifState.isLoading && notifications.isEmpty) ...[
                        CrudLoadingWidget(
                          titleEn: 'Loading notifications log...',
                          titleAr: 'جاري تحميل سجل الإشعارات...',
                          isRtl: isRtl,
                          isDark: isDark,
                        ),
                      ] else if (notifications.isEmpty) ...[
                        _buildEmptyState(isRtl, isDark),
                      ] else ...[
                        _buildNotificationsList(context, notifications, isRtl, isDark),
                        if (totalPages > 1) ...[
                          const SizedBox(height: 16),
                          _buildPaginationFooter(totalPages, totalCount, isRtl, isDark),
                        ],
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Header ---
  Widget _buildHeader(BuildContext context, bool isRtl, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        final titleCol = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  color: Color(0xFF10B981),
                  size: 26,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isRtl ? 'إدارة وبث الإشعارات' : 'Notification Delivery & Broadcast',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isRtl
                  ? 'إرسال تنبيهات العروض المباشرة والمجلات والرسائل للمستخدمين ومتابعة سجلات الوصول.'
                  : 'Send contextual deal alerts, flyer releases, and announcements to customers.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        );

        final broadcastBtn = ElevatedButton.icon(
          onPressed: () => _showBroadcastModal(context, isRtl, isDark),
          icon: const Icon(Icons.send_rounded, size: 18),
          label: Text(isRtl ? 'صياغة وبث إشعار جديد' : 'Compose & Broadcast Notification'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: const Color(0xFF10B981).withValues(alpha: 0.35),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleCol,
              const SizedBox(height: 14),
              broadcastBtn,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleCol),
            const SizedBox(width: 16),
            broadcastBtn,
          ],
        );
      },
    );
  }

  // --- 2. Stats Grid ---
  Widget _buildStatsGrid(int totalCount, int offersCount, int flyersCount, bool isRtl, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;

        final cards = [
          _buildStatCard(
            title: isRtl ? 'إجمالي الإشعارات المسلمة' : 'Delivered Alerts',
            count: '$totalCount',
            icon: Icons.mark_email_read_rounded,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFD1FAE5),
            isDark: isDark,
          ),
          _buildStatCard(
            title: isRtl ? 'العروض النشطة المتاحة للربط' : 'Linkable Active Offers',
            count: '$offersCount',
            icon: Icons.notifications_active_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFD1FAE5),
            isDark: isDark,
          ),
          _buildStatCard(
            title: isRtl ? 'المجلات المتاحة للربط' : 'Linkable Active Flyers',
            count: '$flyersCount',
            icon: Icons.menu_book_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            isDark: isDark,
          ),
        ];

        if (isMobile) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: c,
                    ))
                .toList(),
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.15) : iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
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

  // --- 3. Filters Toolbar ---
  Widget _buildFiltersToolbar(
    BuildContext context,
    List<CustomSelectOption<String>> typeFilterOptions,
    List<CustomSelectOption<String>> channelFilterOptions,
    bool isRtl,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 720;

          final searchInput = SizedBox(
            width: isMobile ? double.infinity : 320,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: isRtl ? 'ابحث بالعنوان، المستخدم، أو البريد...' : 'Search by title, recipient user, or email...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 17),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          );

          final typeDropdown = SizedBox(
            width: isMobile ? double.infinity : 190,
            child: AppCustomSelect<String>(
              options: typeFilterOptions,
              selectedValue: _selectedTypeFilter,
              placeholder: isRtl ? 'جميع الأنواع' : 'All Types',
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedTypeFilter = val;
                    _currentPage = 0;
                  });
                  _loadData();
                }
              },
            ),
          );

          final channelDropdown = SizedBox(
            width: isMobile ? double.infinity : 180,
            child: AppCustomSelect<String>(
              options: channelFilterOptions,
              selectedValue: _selectedChannelFilter,
              placeholder: isRtl ? 'جميع القنوات' : 'All Channels',
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedChannelFilter = val;
                    _currentPage = 0;
                  });
                  _loadData();
                }
              },
            ),
          );

          final applyBtn = ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.filter_alt_rounded, size: 16),
            label: Text(isRtl ? 'تطبيق' : 'Apply'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );

          final resetBtn = OutlinedButton(
            onPressed: _clearFilters,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Icon(Icons.restart_alt_rounded, size: 18),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchInput,
                const SizedBox(height: 10),
                typeDropdown,
                const SizedBox(height: 10),
                channelDropdown,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: applyBtn),
                    const SizedBox(width: 8),
                    resetBtn,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              searchInput,
              const SizedBox(width: 10),
              typeDropdown,
              const SizedBox(width: 10),
              channelDropdown,
              const SizedBox(width: 10),
              applyBtn,
              const SizedBox(width: 8),
              resetBtn,
            ],
          );
        },
      ),
    );
  }

  // --- 4. Responsive Unified Notifications List ---
  Widget _buildNotificationsList(
    BuildContext context,
    List<Notification> notifications,
    bool isRtl,
    bool isDark,
  ) {
    return Column(
      children: notifications.map((notif) {
        final isBroadcast = notif.userFullName == null || notif.userFullName!.isEmpty;
        final title = isRtl ? notif.titleAr : notif.titleEn;
        final body = isRtl ? (notif.bodyAr ?? notif.bodyEn) : (notif.bodyEn ?? notif.bodyAr);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 640;

              final avatarBox = Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isBroadcast
                      ? (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFEFF6FF))
                      : (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isBroadcast
                        ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                        : const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: isBroadcast
                      ? Icon(Icons.campaign_rounded, size: 22, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB))
                      : Text(
                          notif.userFullName!.isNotEmpty ? notif.userFullName![0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                          ),
                        ),
                ),
              );

              final infoWrap = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        title.isNotEmpty ? title : 'Notification #${notif.id}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          '#${notif.id}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getTypeBgColor(notif.type, isDark),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _getTypeLabel(notif.type, isRtl),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _getTypeTextColor(notif.type, isDark),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getChannelIcon(notif.channel), size: 12, color: const Color(0xFF2563EB)),
                            const SizedBox(width: 3),
                            Text(
                              notif.channel,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (body != null && body.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Meta Row
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline_rounded, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(
                              '${notif.userFullName ?? (notif.userId > 0 ? "User #${notif.userId}" : (isRtl ? "بث لكافة العملاء" : "Broadcast (All Users)"))}${notif.userEmail != null ? " (${notif.userEmail})" : ""}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (notif.deepLink != null && notif.deepLink!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.link_rounded, size: 13, color: Color(0xFF10B981)),
                              const SizedBox(width: 3),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 120),
                                child: Text(
                                  notif.deepLink!,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              _formatDate(notif.sentAt),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );

              final rightActions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: notif.read
                          ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5))
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: notif.read
                            ? const Color(0xFF059669).withValues(alpha: 0.4)
                            : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: notif.read ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          notif.read ? (isRtl ? 'مقروء' : 'Read') : (isRtl ? 'غير مقروء' : 'Unread'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: notif.read
                                ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: const Color(0xFFDC2626),
                    onPressed: () => _deleteNotification(notif, isRtl, isDark),
                    splashRadius: 18,
                    tooltip: isRtl ? 'حذف سجل الإشعار' : 'Delete notification log',
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        avatarBox,
                        const SizedBox(width: 12),
                        Expanded(child: infoWrap),
                      ],
                    ),
                    const Divider(height: 16),
                    Align(
                      alignment: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                      child: rightActions,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatarBox,
                  const SizedBox(width: 14),
                  Expanded(child: infoWrap),
                  const SizedBox(width: 14),
                  rightActions,
                ],
              );
            },
          ),
        );
      }).toList(),
    );
  }

  // --- 5. Pagination Footer ---
  Widget _buildPaginationFooter(int totalPages, int totalCount, bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isRtl
                ? 'الصفحة ${_currentPage + 1} من $totalPages ($totalCount إشعار)'
                : 'Page ${_currentPage + 1} of $totalPages ($totalCount items)',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed: _currentPage > 0
                    ? () {
                        setState(() => _currentPage--);
                        _loadData();
                      }
                    : null,
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: _currentPage < totalPages - 1
                    ? () {
                        setState(() => _currentPage++);
                        _loadData();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 6. Empty State ---
  Widget _buildEmptyState(bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 56,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            isRtl ? 'لم يتم العثور على إشعارات' : 'No Notifications Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isRtl ? 'قم بصياغة وإرسال إشعار جديد للمستخدمين.' : 'Compose and broadcast a contextual deal or flyer notification to users.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => _showBroadcastModal(context, isRtl, isDark),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(isRtl ? 'إرسال أول إشعار' : 'Broadcast First Notification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
