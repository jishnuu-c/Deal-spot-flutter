import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/services/offer_repository.dart';
import '../../../../core/services/store_repository.dart';
import '../../../../core/services/product_repository.dart';
import '../../../../core/services/city_repository.dart';
import '../../../../core/services/category_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/custom_select_widget.dart';
import '../../../../models/models.dart';
import '../widgets/crud_loading_widget.dart';

class OffersCrudScreen extends ConsumerStatefulWidget {
  const OffersCrudScreen({super.key});

  @override
  ConsumerState<OffersCrudScreen> createState() => _OffersCrudScreenState();
}

class _OffersCrudScreenState extends ConsumerState<OffersCrudScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const int _pageSize = 20;
  List<Offer> _offers = [];
  int _currentPage = 0;
  int _totalElements = 0;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  bool _showScrollTop = false;

  String _searchQuery = '';
  int? _selectedStoreFilter;
  String _selectedBadgeFilter = '';
  String _selectedStatusFilter = '';
  Timer? _searchDebounce;

  static const List<Map<String, String>> _badgeFilterOptions = [
    {'id': '', 'nameEn': 'All Badges', 'nameAr': 'جميع الشارات'},
    {'id': 'NONE', 'nameEn': 'Standard (NONE)', 'nameAr': 'عادي'},
    {'id': 'FEATURED', 'nameEn': 'FEATURED', 'nameAr': 'مميز'},
    {'id': 'FLASH', 'nameEn': 'FLASH', 'nameAr': 'صفقة خاطفة'},
    {'id': 'BOGO', 'nameEn': 'BOGO', 'nameAr': 'اشتر 1 واحصل 1'},
    {'id': 'PROMO', 'nameEn': 'PROMO', 'nameAr': 'ترويجي'},
    {'id': 'CLEARANCE', 'nameEn': 'CLEARANCE', 'nameAr': 'تصفية'},
    {'id': 'PERCENT_OFF', 'nameEn': 'PERCENT_OFF', 'nameAr': 'نسبة خصم'},
  ];

  static const List<Map<String, String>> _statusFilterOptions = [
    {'id': '', 'nameEn': 'All Statuses', 'nameAr': 'جميع الحالات'},
    {'id': 'ACTIVE', 'nameEn': 'Active Only', 'nameAr': 'نشط فقط'},
    {'id': 'EXPIRED', 'nameEn': 'Expired Only', 'nameAr': 'منتهي فقط'},
    {'id': 'UPCOMING', 'nameEn': 'Upcoming Only', 'nameAr': 'قادم فقط'},
    {'id': 'DISABLED', 'nameEn': 'Disabled', 'nameAr': 'معطل'},
  ];

  static const List<Map<String, String>> _badgeTypeOptions = [
    {'id': 'NONE', 'nameEn': 'Standard (NONE)', 'nameAr': 'عادي (بدون شارة)'},
    {'id': 'PERCENT_OFF', 'nameEn': 'Percentage Off (PERCENT_OFF)', 'nameAr': 'نسبة خصم (PERCENT_OFF)'},
    {'id': 'FLASH', 'nameEn': 'Flash Deal (FLASH)', 'nameAr': 'صفقة خاطفة (FLASH)'},
    {'id': 'NEW', 'nameEn': 'New Arrival (NEW)', 'nameAr': 'جديد (NEW)'},
    {'id': 'BOGO', 'nameEn': 'Buy 1 Get 1 (BOGO)', 'nameAr': 'اشتر 1 واحصل على 1 (BOGO)'},
    {'id': 'CLEARANCE', 'nameEn': 'Clearance (CLEARANCE)', 'nameAr': 'تصفية (CLEARANCE)'},
    {'id': 'COUPON', 'nameEn': 'Coupon Deal (COUPON)', 'nameAr': 'عرض كوبون (COUPON)'},
    {'id': 'FEATURED', 'nameEn': 'Featured Deal (FEATURED)', 'nameAr': 'عرض مميز (FEATURED)'},
    {'id': 'PROMO', 'nameEn': 'Special Promo (PROMO)', 'nameAr': 'عرض ترويجي (PROMO)'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final adminUser = authState.currentAdmin;
      if (adminUser?.role == 'STORE_MANAGER' && adminUser?.storeId != null) {
        _selectedStoreFilter = adminUser!.storeId;
      }
      ref.read(storeRepositoryProvider.notifier).fetchStores();
      ref.read(cityRepositoryProvider.notifier).fetchCities();
      ref.read(categoryRepositoryProvider.notifier).fetchCategories();
      ref.read(offerRepositoryProvider.notifier).fetchOffers(includeExpired: true);
      _loadInitialOffers();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final yOffset = _scrollController.position.pixels;
      final showTop = yOffset > 300;
      if (showTop != _showScrollTop) {
        setState(() => _showScrollTop = showTop);
      }

      if (yOffset >= _scrollController.position.maxScrollExtent - 250) {
        _loadNextPage();
      }
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _loadInitialOffers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });

    bool? activeFilter;
    if (_selectedStatusFilter == 'ACTIVE') activeFilter = true;
    if (_selectedStatusFilter == 'DISABLED') activeFilter = false;

    try {
      final res = await ref.read(offerRepositoryProvider.notifier).getPagedOffers(
        page: 0,
        size: _pageSize,
        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
        storeId: _selectedStoreFilter,
        badgeType: _selectedBadgeFilter.isNotEmpty ? _selectedBadgeFilter : null,
        active: activeFilter,
        sortBy: 'createdAt',
        direction: 'desc',
      );

      if (mounted) {
        setState(() {
          _offers = res.content;
          _totalElements = res.totalElements;
          _totalPages = res.totalPages;
          _hasMore = (0 + 1) < res.totalPages;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;

    final nextPage = _currentPage + 1;
    setState(() => _isLoadingMore = true);

    bool? activeFilter;
    if (_selectedStatusFilter == 'ACTIVE') activeFilter = true;
    if (_selectedStatusFilter == 'DISABLED') activeFilter = false;

    try {
      final res = await ref.read(offerRepositoryProvider.notifier).getPagedOffers(
        page: nextPage,
        size: _pageSize,
        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
        storeId: _selectedStoreFilter,
        badgeType: _selectedBadgeFilter.isNotEmpty ? _selectedBadgeFilter : null,
        active: activeFilter,
        sortBy: 'createdAt',
        direction: 'desc',
      );

      if (mounted) {
        setState(() {
          _offers = [..._offers, ...res.content];
          _currentPage = res.number;
          _totalElements = res.totalElements;
          _totalPages = res.totalPages;
          _hasMore = (res.number + 1) < res.totalPages;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _searchQuery = value);
        _loadInitialOffers();
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedStoreFilter = null;
      _selectedBadgeFilter = '';
      _selectedStatusFilter = '';
    });
    _loadInitialOffers();
  }

  void _extendOffer(Offer offer) {
    final isEn = ref.read(translationProvider) == AppLanguage.en;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.more_time, color: Color(0xFFD97706), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEn ? 'Extend Offer Expiration?' : 'تمديد فترة العرض؟',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          isEn
              ? 'Extend "${offer.titleEn}" by +7 days and activate it?'
              : 'هل تريد تمديد فترة العرض "${offer.titleAr.isNotEmpty ? offer.titleAr : offer.titleEn}" بـ +7 أيام وتفعيله؟',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Cancel' : 'إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(offerRepositoryProvider.notifier).extendOffer(offer.id, 7);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (isEn ? 'Offer extended by +7 days.' : 'تم تمديد العرض بنجاح بـ +7 أيام.')
                          : (isEn ? 'Failed to extend offer.' : 'فشل تمديد العرض.'),
                    ),
                    backgroundColor: success ? const Color(0xFF16A34A) : Colors.red,
                  ),
                );
                _loadInitialOffers();
              }
            },
            child: Text(isEn ? 'Yes, Extend (+7 Days)' : 'نعم، تمديد (+7 أيام)'),
          ),
        ],
      ),
    );
  }

  void _deleteOffer(Offer offer) {
    final isEn = ref.read(translationProvider) == AppLanguage.en;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isEn ? 'Are you sure?' : 'هل أنت متأكد؟',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          isEn
              ? 'Do you really want to delete "${offer.titleEn}"?'
              : 'هل تريد حقاً حذف العرض الترويجي "${offer.titleAr.isNotEmpty ? offer.titleAr : offer.titleEn}"؟',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Cancel' : 'إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(offerRepositoryProvider.notifier).deleteOffer(offer.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEn ? 'Offer deleted successfully.' : 'تم حذف العرض بنجاح.'),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                );
                _loadInitialOffers();
              }
            },
            child: Text(isEn ? 'Yes, Delete!' : 'نعم، احذف!'),
          ),
        ],
      ),
    );
  }

  void _showOfferModal([Offer? offer]) {
    final isEn = ref.read(translationProvider) == AppLanguage.en;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stores = ref.read(storeRepositoryProvider).stores;
    final cities = ref.read(cityRepositoryProvider).cities;
    final categories = ref.read(categoryRepositoryProvider);
    final authState = ref.read(authProvider);
    final adminUser = authState.currentAdmin;
    final isStoreManager = adminUser?.role == 'STORE_MANAGER' && adminUser?.storeId != null;

    final titleEnCtrl = TextEditingController(text: offer?.titleEn ?? '');
    final titleArCtrl = TextEditingController(text: offer?.titleAr ?? '');
    final origPriceCtrl = TextEditingController(text: offer != null ? offer.originalPrice.toString() : '0');
    final offerPriceCtrl = TextEditingController(text: offer != null ? offer.offerPrice.toString() : '0');
    final descEnCtrl = TextEditingController(text: offer?.descriptionEn ?? '');
    final descArCtrl = TextEditingController(text: offer?.descriptionAr ?? '');
    final termsEnCtrl = TextEditingController(text: offer?.termsEn ?? '');
    final termsArCtrl = TextEditingController(text: offer?.termsAr ?? '');

    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final nextWeek = now.add(const Duration(days: 7));
    final nextWeekStr = '${nextWeek.year.toString().padLeft(4, '0')}-${nextWeek.month.toString().padLeft(2, '0')}-${nextWeek.day.toString().padLeft(2, '0')}';

    final fromCtrl = TextEditingController(text: offer?.validFrom.isNotEmpty == true ? offer!.validFrom.split('T')[0] : todayStr);
    final untilCtrl = TextEditingController(text: offer?.validUntil.isNotEmpty == true ? offer!.validUntil.split('T')[0] : nextWeekStr);

    int? selectedStoreId;
    if (isStoreManager) {
      selectedStoreId = adminUser!.storeId;
    } else if (offer?.storeId != null && stores.any((s) => s.id == offer!.storeId)) {
      selectedStoreId = offer!.storeId;
    } else if (stores.isNotEmpty) {
      selectedStoreId = stores[0].id;
    }

    int? selectedCategoryId = offer?.categoryId != null && categories.any((c) => c.id == offer!.categoryId)
        ? offer!.categoryId
        : (categories.isNotEmpty ? categories[0].id : null);
    int? selectedCityId = offer?.cityId != null && cities.any((c) => c.id == offer!.cityId)
        ? offer!.cityId
        : (cities.isNotEmpty ? cities[0].id : null);

    String selectedBadgeType = offer?.badgeType ?? 'NONE';
    if (!_badgeTypeOptions.any((b) => b['id'] == selectedBadgeType)) {
      selectedBadgeType = 'NONE';
    }

    bool isFeatured = offer?.isFeatured == 1;
    bool isFlash = offer?.isFlash == 1;
    bool isInStore = offer?.isInStore == 1 || offer == null;
    bool isOnline = offer?.isOnline == 1;
    bool isActive = offer?.isActive == 1 || offer == null;

    Product? selectedProduct = offer?.product;
    int? selectedProductId = offer?.productId;

    if (selectedProduct == null && selectedProductId != null) {
      selectedProduct = ref.read(productRepositoryProvider.notifier).getProductById(selectedProductId);
    }

    List<XFile> pickedImages = [];
    List<Uint8List> pickedImageBytes = [];
    String? existingImageUrl = offer?.primaryImageUrl.isNotEmpty == true ? offer!.primaryImageUrl : null;

    int discountPct = 0;
    void calcDiscount() {
      final orig = double.tryParse(origPriceCtrl.text.trim()) ?? 0;
      final off = double.tryParse(offerPriceCtrl.text.trim()) ?? 0;
      if (orig > 0 && off >= 0 && off <= orig) {
        discountPct = (((orig - off) / orig) * 100).round();
      } else {
        discountPct = 0;
      }
    }
    calcDiscount();

    VoidCallback? updateDiscountCallback;
    origPriceCtrl.addListener(() {
      calcDiscount();
      updateDiscountCallback?.call();
    });
    offerPriceCtrl.addListener(() {
      calcDiscount();
      updateDiscountCallback?.call();
    });

    bool isSaving = false;

    // Autocomplete product state
    final productSearchCtrl = TextEditingController();
    List<Product> productOptions = [];
    bool isSearchingProducts = false;
    bool isProductDropdownOpen = false;
    Timer? productSearchDebounce;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            updateDiscountCallback = () {
              if (dialogCtx.mounted) setDialogState(() {});
            };

            void onProductSearchInput(String query) {
              productSearchDebounce?.cancel();
              productSearchDebounce = Timer(const Duration(milliseconds: 250), () async {
                setDialogState(() {
                  isSearchingProducts = true;
                  isProductDropdownOpen = true;
                });
                final res = await ref.read(productRepositoryProvider.notifier).getPagedProducts(
                  page: 0,
                  size: 30,
                  search: query.trim().isNotEmpty ? query.trim() : null,
                );
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    productOptions = res.content;
                    isSearchingProducts = false;
                  });
                }
              });
            }

            void selectProduct(Product? prod) {
              setDialogState(() {
                selectedProduct = prod;
                selectedProductId = prod?.id;
                isProductDropdownOpen = false;
                productSearchCtrl.clear();
              });
            }

            final screenWidth = MediaQuery.of(context).size.width;
            final dialogWidth = screenWidth > 860 ? 800.0 : (screenWidth > 640 ? 640.0 : double.maxFinite);
            final isModalNarrow = screenWidth < 680;

            final cardBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
            final cardBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

            if (selectedProduct == null && selectedProductId != null) {
              ref.read(productRepositoryProvider.notifier).fetchProductById(selectedProductId!).then((p) {
                if (p != null && dialogCtx.mounted && selectedProduct == null) {
                  setDialogState(() {
                    selectedProduct = p;
                  });
                }
              });
            }

            return Directionality(
              textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                actionsPadding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_offer, color: Color(0xFF16A34A), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        offer == null
                            ? (isEn ? 'Create Promotion Deal' : 'إنشاء عرض ترويجي جديد')
                            : (isEn ? 'Edit Promotion Deal' : 'تعديل العرض الترويجي'),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: dialogWidth,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Bilingual Titles
                        if (isModalNarrow) ...[
                          Text(isEn ? 'Offer Title (EN) *' : 'عنوان العرض (الإنجليزية) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleEnCtrl,
                            decoration: InputDecoration(
                              hintText: isEn ? 'e.g. 50% Off Smart TVs' : 'مثال: خصم 50% على الشاشات الذكية',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(isEn ? 'Offer Title (AR) *' : 'عنوان العرض (العربية) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleArCtrl,
                            decoration: InputDecoration(
                              hintText: isEn ? 'Arabic title...' : 'مثال: خصم 50% على الشاشات الذكية',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEn ? 'Offer Title (EN) *' : 'عنوان العرض (الإنجليزية) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: titleEnCtrl,
                                      decoration: InputDecoration(
                                        hintText: isEn ? 'e.g. 50% Off Smart TVs' : 'مثال: خصم 50% على الشاشات الذكية',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEn ? 'Offer Title (AR) *' : 'عنوان العرض (العربية) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: titleArCtrl,
                                      decoration: InputDecoration(
                                        hintText: isEn ? 'Arabic title...' : 'مثال: خصم 50% على الشاشات الذكية',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 18),

                        // 2. Store, Category, City Scope
                        if (isModalNarrow) ...[
                          if (isStoreManager) ...[
                            Text(isEn ? 'Store & Branches' : 'المتجر والفروع التابعة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cardBorderColor),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.storefront, color: Color(0xFF16A34A), size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            stores.where((s) => s.id == selectedStoreId).firstOrNull?.nameEn ?? (isEn ? 'Your Store' : 'متجرك'),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFF16A34A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.verified_user, size: 12, color: Color(0xFF16A34A)),
                                        const SizedBox(width: 3),
                                        Text(isEn ? 'Your Store' : 'متجرك', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ] else ...[
                            AppCustomSelect<int>(
                              label: isEn ? 'Retail Partner Store' : 'المتجر الشريك',
                              isRequired: true,
                              placeholder: isEn ? 'Select Store' : 'اختر المتجر',
                              selectedValue: selectedStoreId,
                              options: stores.map((s) => CustomSelectOption<int>(
                                value: s.id,
                                labelEn: s.nameEn,
                                labelAr: s.nameAr,
                                imageUrl: s.logoUrl,
                              )).toList(),
                              onChanged: (val) => setDialogState(() => selectedStoreId = val),
                            ),
                            const SizedBox(height: 14),
                          ],
                          AppCustomSelect<int>(
                            label: isEn ? 'Category' : 'القسم الرئيسي',
                            isRequired: true,
                            placeholder: isEn ? 'Select Category' : 'اختر القسم',
                            selectedValue: selectedCategoryId,
                            options: categories.map((c) => CustomSelectOption<int>(
                              value: c.id,
                              labelEn: c.nameEn,
                              labelAr: c.nameAr,
                              imageUrl: c.imageUrl,
                              icon: Icons.category_outlined,
                            )).toList(),
                            onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                          ),
                          const SizedBox(height: 14),
                          AppCustomSelect<int>(
                            label: isEn ? 'City Scope' : 'المدينة',
                            isRequired: true,
                            placeholder: isEn ? 'Select City' : 'اختر المدينة',
                            selectedValue: selectedCityId,
                            options: cities.map((c) => CustomSelectOption<int>(
                              value: c.id,
                              labelEn: c.nameEn,
                              labelAr: c.nameAr,
                              icon: Icons.location_city_outlined,
                            )).toList(),
                            onChanged: (val) => setDialogState(() => selectedCityId = val),
                          ),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isStoreManager) ...[
                                      Text(isEn ? 'Store & Branches' : 'المتجر والفروع التابعة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: cardBgColor,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: cardBorderColor),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.storefront, color: Color(0xFF16A34A), size: 18),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      stores.where((s) => s.id == selectedStoreId).firstOrNull?.nameEn ?? (isEn ? 'Your Store' : 'متجرك'),
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: const Color(0xFF16A34A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.verified_user, size: 12, color: Color(0xFF16A34A)),
                                                  const SizedBox(width: 3),
                                                  Text(isEn ? 'Your Store' : 'متجرك', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      AppCustomSelect<int>(
                                        label: isEn ? 'Retail Partner Store' : 'المتجر الشريك',
                                        isRequired: true,
                                        placeholder: isEn ? 'Select Store' : 'اختر المتجر',
                                        selectedValue: selectedStoreId,
                                        options: stores.map((s) => CustomSelectOption<int>(
                                          value: s.id,
                                          labelEn: s.nameEn,
                                          labelAr: s.nameAr,
                                          imageUrl: s.logoUrl,
                                        )).toList(),
                                        onChanged: (val) => setDialogState(() => selectedStoreId = val),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppCustomSelect<int>(
                                  label: isEn ? 'Category' : 'القسم الرئيسي',
                                  isRequired: true,
                                  placeholder: isEn ? 'Select Category' : 'اختر القسم',
                                  selectedValue: selectedCategoryId,
                                  options: categories.map((c) => CustomSelectOption<int>(
                                    value: c.id,
                                    labelEn: c.nameEn,
                                    labelAr: c.nameAr,
                                    imageUrl: c.imageUrl,
                                    icon: Icons.category_outlined,
                                  )).toList(),
                                  onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppCustomSelect<int>(
                                  label: isEn ? 'City Scope' : 'المدينة',
                                  isRequired: true,
                                  placeholder: isEn ? 'Select City' : 'اختر المدينة',
                                  selectedValue: selectedCityId,
                                  options: cities.map((c) => CustomSelectOption<int>(
                                    value: c.id,
                                    labelEn: c.nameEn,
                                    labelAr: c.nameAr,
                                    icon: Icons.location_city_outlined,
                                  )).toList(),
                                  onChanged: (val) => setDialogState(() => selectedCityId = val),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // 3. Catalog Linked Product Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isEn ? 'Catalog Linked Product (Optional)' : 'ربط بمنتج من الدليل (اختياري)',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  if (isSearchingProducts)
                                    Row(
                                      children: [
                                        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A))),
                                        const SizedBox(width: 6),
                                        Text(isEn ? 'Searching...' : 'جاري البحث...', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // If Product Selected: Show Tile Card with All Details Matching Angular
                              if (selectedProduct != null)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: selectedProduct!.primaryImageUrl.isNotEmpty
                                              ? AppNetworkImage(
                                                  imageUrl: AppConfig.normalizeImageUrl(selectedProduct!.primaryImageUrl),
                                                  fit: BoxFit.contain,
                                                  defaultFallbackIcon: Icons.shopping_bag_outlined,
                                                )
                                              : const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 28),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        isEn ? selectedProduct!.nameEn : (selectedProduct!.nameAr.isNotEmpty ? selectedProduct!.nameAr : selectedProduct!.nameEn),
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                      ),
                                                      if (isEn && selectedProduct!.nameAr.isNotEmpty)
                                                        Text(selectedProduct!.nameAr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                      if (!isEn && selectedProduct!.nameEn.isNotEmpty)
                                                        Text(selectedProduct!.nameEn, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                    ],
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () => selectProduct(null),
                                                  borderRadius: BorderRadius.circular(16),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withValues(alpha: 0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.close, size: 16, color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                if (selectedProduct!.brand.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.25)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.verified, size: 12, color: Color(0xFF16A34A)),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          isEn ? selectedProduct!.brand : (selectedProduct!.brandAr.isNotEmpty ? selectedProduct!.brandAr : selectedProduct!.brand),
                                                          style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (selectedProduct!.sku.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                                    child: Text('SKU: ${selectedProduct!.sku}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                                                  ),
                                                if (selectedProduct!.barcode.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                                    child: Text('UPC: ${selectedProduct!.barcode}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                                                  ),
                                                if (selectedProduct!.unit.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                                    child: Text('${selectedProduct!.unitSize} ${selectedProduct!.unit}', style: const TextStyle(fontSize: 11)),
                                                  ),
                                              ],
                                            ),
                                            if ((isEn ? selectedProduct!.descriptionEn : selectedProduct!.descriptionAr)?.isNotEmpty == true) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                (isEn ? selectedProduct!.descriptionEn : selectedProduct!.descriptionAr)!,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // If No Product Selected: Show Search Autocomplete
                              if (selectedProduct == null) ...[
                                TextField(
                                  controller: productSearchCtrl,
                                  onChanged: onProductSearchInput,
                                  onTap: () {
                                    if (productOptions.isEmpty) {
                                      onProductSearchInput('');
                                    } else {
                                      setDialogState(() => isProductDropdownOpen = true);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: isEn ? 'Search product by name, brand, SKU or barcode...' : 'ابحث باسم المنتج، الماركة، الرمز (SKU) أو الباركود...',
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    suffixIcon: productSearchCtrl.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear, size: 18),
                                            onPressed: () {
                                              productSearchCtrl.clear();
                                              onProductSearchInput('');
                                            },
                                          )
                                        : null,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                                if (isProductDropdownOpen)
                                  Container(
                                    constraints: const BoxConstraints(maxHeight: 260),
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: cardBorderColor),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 5)),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: cardBgColor,
                                            border: Border(bottom: BorderSide(color: cardBorderColor)),
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                isEn ? 'CATALOG PRODUCTS' : 'منتجات الدليل',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5),
                                              ),
                                              InkWell(
                                                onTap: () => setDialogState(() => isProductDropdownOpen = false),
                                                child: const Icon(Icons.close, size: 16, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSearchingProducts)
                                          const Padding(
                                            padding: EdgeInsets.all(20),
                                            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                                          )
                                        else if (productOptions.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Center(
                                              child: Text(
                                                isEn ? 'No products found matching query' : 'لم يتم العثور على منتجات مطابقة',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ),
                                          )
                                        else
                                          Flexible(
                                            child: ListView.separated(
                                              shrinkWrap: true,
                                              itemCount: productOptions.length,
                                              separatorBuilder: (_, __) => Divider(height: 1, color: cardBorderColor),
                                              itemBuilder: (context, idx) {
                                                final p = productOptions[idx];
                                                final pName = isEn ? p.nameEn : (p.nameAr.isNotEmpty ? p.nameAr : p.nameEn);
                                                return InkWell(
                                                  onTap: () => selectProduct(p),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 36,
                                                          height: 36,
                                                          decoration: BoxDecoration(
                                                            color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: (p.images != null && p.images!.isNotEmpty)
                                                              ? ClipRRect(
                                                                  borderRadius: BorderRadius.circular(6),
                                                                  child: AppNetworkImage(
                                                                    imageUrl: p.images!.first.imageUrl.startsWith('http')
                                                                        ? p.images!.first.imageUrl
                                                                        : '${AppConfig.filePath}${p.images!.first.imageUrl}',
                                                                    fit: BoxFit.cover,
                                                                  ),
                                                                )
                                                              : const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                pName,
                                                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              if (p.brand?.isNotEmpty == true || p.category != null)
                                                                Text(
                                                                  [if (p.brand?.isNotEmpty == true) p.brand, if (p.category != null) (isEn ? p.category!.nameEn : p.category!.nameAr)].join(' • '),
                                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 4. Pricing Card with Auto Computed Discount
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardBorderColor),
                          ),
                          child: isModalNarrow
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEn ? 'Original Price (SAR) *' : 'السعر الأصلي (ر.س) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: origPriceCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(isEn ? 'Offer Price (SAR) *' : 'سعر العرض (ر.س) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: offerPriceCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(isEn ? 'Discount % (Auto Calculated)' : 'نسبة الخصم % (محسوبة تلقائياً)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$discountPct%',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF16A34A)),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(isEn ? 'Original Price (SAR) *' : 'السعر الأصلي (ر.س) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(height: 6),
                                          TextField(
                                            controller: origPriceCtrl,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            onChanged: (_) => setDialogState(() => calcDiscount()),
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(isEn ? 'Offer Price (SAR) *' : 'سعر العرض (ر.س) *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(height: 6),
                                          TextField(
                                            controller: offerPriceCtrl,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            onChanged: (_) => setDialogState(() => calcDiscount()),
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(isEn ? 'Discount % (Auto Calculated)' : 'نسبة الخصم % (محسوبة تلقائياً)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '$discountPct%',
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF16A34A)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 20),

                        // 5. Promotion Badge & Validity Dates
                        if (isModalNarrow) ...[
                          AppCustomSelect<String>(
                            label: isEn ? 'Promotion Badge' : 'شارة العرض',
                            placeholder: isEn ? 'Select Badge' : 'اختر الشارة',
                            selectedValue: selectedBadgeType,
                            options: _badgeTypeOptions.map((b) => CustomSelectOption<String>(
                              value: b['id']!,
                              labelEn: b['nameEn']!,
                              labelAr: b['nameAr']!,
                              icon: Icons.local_offer_outlined,
                            )).toList(),
                            onChanged: (val) => setDialogState(() => selectedBadgeType = val ?? 'NONE'),
                          ),
                          const SizedBox(height: 14),
                          Text(isEn ? 'Valid From *' : 'ساري من تاريخ *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: fromCtrl,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(fromCtrl.text) ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                fromCtrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              }
                            },
                            decoration: InputDecoration(
                              suffixIcon: const Icon(Icons.calendar_today, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(isEn ? 'Valid Until *' : 'ساري حتى تاريخ *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: untilCtrl,
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(untilCtrl.text) ?? DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                untilCtrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              }
                            },
                            decoration: InputDecoration(
                              suffixIcon: const Icon(Icons.calendar_today, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: AppCustomSelect<String>(
                                  label: isEn ? 'Promotion Badge' : 'شارة العرض',
                                  placeholder: isEn ? 'Select Badge' : 'اختر الشارة',
                                  selectedValue: selectedBadgeType,
                                  options: _badgeTypeOptions.map((b) => CustomSelectOption<String>(
                                    value: b['id']!,
                                    labelEn: b['nameEn']!,
                                    labelAr: b['nameAr']!,
                                    icon: Icons.local_offer_outlined,
                                  )).toList(),
                                  onChanged: (val) => setDialogState(() => selectedBadgeType = val ?? 'NONE'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEn ? 'Valid From *' : 'ساري من تاريخ *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: fromCtrl,
                                      readOnly: true,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.tryParse(fromCtrl.text) ?? DateTime.now(),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (picked != null) {
                                          fromCtrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                        }
                                      },
                                      decoration: InputDecoration(
                                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEn ? 'Valid Until *' : 'ساري حتى تاريخ *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: untilCtrl,
                                      readOnly: true,
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.tryParse(untilCtrl.text) ?? DateTime.now().add(const Duration(days: 7)),
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2030),
                                        );
                                        if (picked != null) {
                                          untilCtrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                        }
                                      },
                                      decoration: InputDecoration(
                                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // 6. Descriptions (Optional)
                        if (isModalNarrow) ...[
                          Text(isEn ? 'Description (EN)' : 'الوصف (الإنجليزية)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: descEnCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: isEn ? 'Describe offer details...' : 'اكتب تفاصيل العرض...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(isEn ? 'Description (AR)' : 'الوصف (العربية)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: descArCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: isEn ? 'اكتب تفاصيل العرض...' : 'اكتب تفاصيل العرض...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEn ? 'Description (EN)' : 'الوصف (الإنجليزية)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: descEnCtrl,
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        hintText: isEn ? 'Describe offer details...' : 'اكتب تفاصيل العرض...',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.all(12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEn ? 'Description (AR)' : 'الوصف (العربية)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: descArCtrl,
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        hintText: isEn ? 'اكتب تفاصيل العرض...' : 'اكتب تفاصيل العرض...',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.all(12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // 7. Terms & Conditions (Optional)
                        if (isModalNarrow) ...[
                          Text(isEn ? 'Terms & Conditions (EN)' : 'الشروط والأحكام (الإنجليزية)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: termsEnCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: isEn ? 'Offer terms & conditions...' : 'الشروط والأحكام...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(isEn ? 'Terms & Conditions (AR)' : 'الشروط والأحكام (العربية)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: termsArCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: isEn ? 'الشروط والأحكام...' : 'الشروط والأحكام...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEn ? 'Terms & Conditions (EN)' : 'الشروط والأحكام (الإنجليزية)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: termsEnCtrl,
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        hintText: isEn ? 'Offer terms & conditions...' : 'الشروط والأحكام...',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.all(12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEn ? 'Terms & Conditions (AR)' : 'الشروط والأحكام (العربية)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: termsArCtrl,
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        hintText: isEn ? 'الشروط والأحكام...' : 'الشروط والأحكام...',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.all(12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // 8. Image Upload Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.image_outlined, size: 18, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isEn ? 'Offer Promotional Images' : 'الصور الترويجية للعرض',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Existing Image Preview
                              if (existingImageUrl != null && pickedImages.isEmpty) ...[
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: AppNetworkImage(
                                        imageUrl: AppConfig.normalizeImageUrl(existingImageUrl),
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        defaultFallbackIcon: Icons.broken_image,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(isEn ? 'Current Active Image' : 'الصورة الحالية', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Dropzone
                              InkWell(
                                onTap: () async {
                                  final picker = ImagePicker();
                                  final files = await picker.pickMultiImage();
                                  if (files.isNotEmpty) {
                                    for (final f in files) {
                                      final bytes = await f.readAsBytes();
                                      pickedImages.add(f);
                                      pickedImageBytes.add(bytes);
                                    }
                                    setDialogState(() {});
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 22),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: cardBorderColor, style: BorderStyle.solid),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.cloud_upload_outlined, size: 36, color: Color(0xFF16A34A)),
                                      const SizedBox(height: 8),
                                      Text(
                                        isEn ? 'Click or Drag images to upload' : 'انقر لاختيار الصور وتحميلها',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('PNG, JPG, WEBP (Max 5MB)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),

                              // Previews Grid
                              if (pickedImages.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: List.generate(pickedImages.length, (idx) {
                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.memory(
                                            pickedImageBytes[idx],
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 3,
                                          right: 3,
                                          child: InkWell(
                                            onTap: () {
                                              setDialogState(() {
                                                pickedImages.removeAt(idx);
                                                pickedImageBytes.removeAt(idx);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.black87,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 9. Flags & Toggles Grid
                        Material(
                          color: cardBgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: cardBorderColor),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  dense: true,
                                  activeColor: const Color(0xFF16A34A),
                                  title: Text(isEn ? 'Set as Featured Deal' : 'تمييز العرض في التوصيات'),
                                  value: isFeatured,
                                  onChanged: (val) => setDialogState(() => isFeatured = val ?? false),
                                ),
                                CheckboxListTile(
                                  dense: true,
                                  activeColor: const Color(0xFF16A34A),
                                  title: Text(isEn ? 'Set as Flash Deal (Limited Time)' : 'عرض خاطف لفترة محدودة'),
                                  value: isFlash,
                                  onChanged: (val) => setDialogState(() => isFlash = val ?? false),
                                ),
                                CheckboxListTile(
                                  dense: true,
                                  activeColor: const Color(0xFF16A34A),
                                  title: Text(isEn ? 'Available In-Store' : 'متاح في فروع المتجر'),
                                  value: isInStore,
                                  onChanged: (val) => setDialogState(() => isInStore = val ?? true),
                                ),
                                CheckboxListTile(
                                  dense: true,
                                  activeColor: const Color(0xFF16A34A),
                                  title: Text(isEn ? 'Available Online' : 'متاح عبر الإنترنت'),
                                  value: isOnline,
                                  onChanged: (val) => setDialogState(() => isOnline = val ?? false),
                                ),
                                CheckboxListTile(
                                  dense: true,
                                  activeColor: const Color(0xFF16A34A),
                                  title: Text(isEn ? 'Active Status' : 'حالة النشاط (مفعل)', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  value: isActive,
                                  onChanged: (val) => setDialogState(() => isActive = val ?? true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(isEn ? 'Cancel' : 'إلغاء'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final titleEn = titleEnCtrl.text.trim();
                            final titleAr = titleArCtrl.text.trim();
                            if (titleEn.isEmpty || titleAr.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEn ? 'Please provide titles in both languages.' : 'يرجى إدخال العنوان باللغتين.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (selectedStoreId == null || selectedCategoryId == null || selectedCityId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEn ? 'Store, category and city are required.' : 'المتجر والقسم والمدينة حقول مطلوبة.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final origPrice = double.tryParse(origPriceCtrl.text.trim()) ?? 0.0;
                            final offPrice = double.tryParse(offerPriceCtrl.text.trim()) ?? 0.0;

                            setDialogState(() => isSaving = true);

                            final success = await ref.read(offerRepositoryProvider.notifier).saveOfferMultipart(
                              id: offer?.id,
                              titleEn: titleEn,
                              titleAr: titleAr,
                              origPrice: origPrice,
                              offerPrice: offPrice,
                              discountPct: discountPct.toDouble(),
                              badgeType: selectedBadgeType,
                              validFrom: fromCtrl.text,
                              validUntil: untilCtrl.text,
                              storeId: selectedStoreId!,
                              productId: selectedProductId,
                              categoryId: selectedCategoryId!,
                              cityId: selectedCityId!,
                              descriptionEn: descEnCtrl.text.trim(),
                              descriptionAr: descArCtrl.text.trim(),
                              termsEn: termsEnCtrl.text.trim(),
                              termsAr: termsArCtrl.text.trim(),
                              isFeatured: isFeatured,
                              isFlash: isFlash,
                              isInStore: isInStore,
                              isOnline: isOnline,
                              isActive: isActive,
                              imageFiles: pickedImages.isNotEmpty ? pickedImages : null,
                            );

                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? (offer == null ? (isEn ? 'Offer created successfully.' : 'تم إنشاء العرض بنجاح.') : (isEn ? 'Offer updated successfully.' : 'تم تحديث العرض بنجاح.'))
                                        : (isEn ? 'Failed to save offer.' : 'فشل حفظ العرض.'),
                                  ),
                                  backgroundColor: success ? const Color(0xFF16A34A) : Colors.red,
                                ),
                              );
                              _loadInitialOffers();
                            }
                          },
                    icon: isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save, size: 18),
                    label: Text(
                      offer == null
                          ? (isEn ? 'Create Offer' : 'إنشاء العرض')
                          : (isEn ? 'Save Changes' : 'حفظ التعديلات'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isEn = !isRtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stores = ref.watch(storeRepositoryProvider).stores;

    // Metrics calculation
    final totalCount = _totalElements > 0 ? _totalElements : _offers.length;
    final activeCount = _offers.where((o) => o.isActive == 1 && !o.isExpired).length;
    final flashCount = _offers.where((o) => o.badgeType == 'FLASH' || o.isFlash == 1).length;
    final expiredCount = _offers.where((o) => o.isExpired).length;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF16A34A),
          onRefresh: () async {
            await Future.wait([
              _loadInitialOffers(),
              ref.read(storeRepositoryProvider.notifier).fetchStores(),
              ref.read(cityRepositoryProvider.notifier).fetchCities(),
              ref.read(categoryRepositoryProvider.notifier).fetchCategories(),
            ]);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Block with Responsive Layout
                _buildHeaderBlock(context, isEn, isRtl, isDark),
                const SizedBox(height: 14),

                // 2. Stats & Metrics Cards
                _buildStatsGrid(
                  totalCount: totalCount,
                  activeCount: activeCount,
                  flashCount: flashCount,
                  expiredCount: expiredCount,
                  isEn: isEn,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // 3. Search & Filter Toolbar
                _buildFilterToolbar(
                  stores: stores,
                  isEn: isEn,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                // 4. Content Area: Loading / Empty / Offers List
                if (_isLoading && _offers.isEmpty) ...[
                  CrudLoadingWidget(
                    titleEn: 'Loading Offers & Promotions',
                    titleAr: 'جاري تحميل العروض والصفقات الترويجية',
                    subtitleEn: 'Fetching latest real-time deals and retail promotions...',
                    subtitleAr: 'جاري جلب أحدث الصفقات والعروض الترويجية من الخوادم...',
                    icon: Icons.local_offer_outlined,
                    isRtl: isRtl,
                    isDark: isDark,
                  ),
                ] else if (_offers.isEmpty) ...[
                  _buildEmptyState(isEn, isDark),
                ] else ...[
                  _buildOffersList(isEn, isDark),
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

  // 1. Responsive Header Block
  Widget _buildHeaderBlock(BuildContext context, bool isEn, bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          final titleInfo = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.local_offer, color: Color(0xFF16A34A), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Manage Deals & Promotions' : 'إدارة العروض والتخفيضات',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 19,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEn
                          ? 'Create, configure, and publish promotional offers and discounts'
                          : 'إنشاء وضبط ونشر عروض التخفيضات والصفقات الترويجية للمتاجر',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final createBtn = ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => _showOfferModal(),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(
              isEn ? 'Create Offer' : 'إنشاء عرض جديد',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleInfo,
                const SizedBox(height: 12),
                createBtn,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: titleInfo),
              const SizedBox(width: 14),
              createBtn,
            ],
          );
        },
      ),
    );
  }

  // 2. Metrics / Stats Grid
  Widget _buildStatsGrid({
    required int totalCount,
    required int activeCount,
    required int flashCount,
    required int expiredCount,
    required bool isEn,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 550;

        final statItems = [
          _buildStatCard(
            title: isEn ? 'Total Deals' : 'إجمالي العروض',
            value: totalCount.toString(),
            icon: Icons.local_offer_outlined,
            color: const Color(0xFF16A34A),
            isDark: isDark,
          ),
          _buildStatCard(
            title: isEn ? 'Active Deals' : 'العروض النشطة',
            value: activeCount.toString(),
            icon: Icons.check_circle_outline,
            color: const Color(0xFF0284C7),
            isDark: isDark,
          ),
          _buildStatCard(
            title: isEn ? 'Flash & Special' : 'العروض الخاطفة',
            value: flashCount.toString(),
            icon: Icons.bolt_outlined,
            color: const Color(0xFFD97706),
            isDark: isDark,
          ),
          _buildStatCard(
            title: isEn ? 'Expired Deals' : 'العروض المنتهية',
            value: expiredCount.toString(),
            icon: Icons.history_toggle_off,
            color: const Color(0xFFDC2626),
            isDark: isDark,
          ),
        ];

        if (isCompact) {
          return LayoutBuilder(
            builder: (context, box) {
              final itemWidth = (box.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: statItems.map((item) => SizedBox(width: itemWidth, child: item)).toList(),
              );
            },
          );
        }

        return Row(
          children: statItems.map((item) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: item))).toList(),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
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

  // 3. Search & Filter Toolbar
  Widget _buildFilterToolbar({
    required List<Store> stores,
    required bool isEn,
    required bool isDark,
  }) {
    final authState = ref.watch(authProvider);
    final isStoreManager = authState.currentAdmin?.role == 'STORE_MANAGER' && authState.currentAdmin?.storeId != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final searchWidth = isMobile ? double.infinity : 260.0;
          final isNarrowPhone = constraints.maxWidth < 360;
          final dropdownWidth = isNarrowPhone ? double.infinity : (isMobile ? (constraints.maxWidth - 10) / 2 : 160.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Search Field
                  SizedBox(
                    width: searchWidth,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: isEn ? 'Search by title, store, or category...' : 'ابحث بالعنوان، المتجر، أو القسم...',
                        hintStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, size: 18, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      ),
                    ),
                  ),

                  // Store Filter Dropdown (Hidden for Store Manager)
                  if (!isStoreManager)
                    Container(
                      width: dropdownWidth,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _selectedStoreFilter,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          hint: Text(
                            isEn ? 'All Retail Stores' : 'جميع المتاجر',
                            style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(isEn ? 'All Retail Stores' : 'جميع المتاجر', overflow: TextOverflow.ellipsis),
                            ),
                            ...stores.map((s) => DropdownMenuItem<int?>(
                                  value: s.id,
                                  child: Text(isEn ? s.nameEn : (s.nameAr.isNotEmpty ? s.nameAr : s.nameEn), overflow: TextOverflow.ellipsis),
                                )),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedStoreFilter = val);
                            _loadInitialOffers();
                          },
                        ),
                      ),
                    ),

                  // Badge Filter Dropdown
                  Container(
                    width: dropdownWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBadgeFilter,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        items: _badgeFilterOptions.map((b) => DropdownMenuItem<String>(
                              value: b['id'],
                              child: Text(isEn ? b['nameEn']! : b['nameAr']!, overflow: TextOverflow.ellipsis),
                            )).toList(),
                        onChanged: (val) {
                          setState(() => _selectedBadgeFilter = val ?? '');
                          _loadInitialOffers();
                        },
                      ),
                    ),
                  ),

                  // Status Filter Dropdown
                  Container(
                    width: dropdownWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatusFilter,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        items: _statusFilterOptions.map((s) => DropdownMenuItem<String>(
                              value: s['id'],
                              child: Text(isEn ? s['nameEn']! : s['nameAr']!, overflow: TextOverflow.ellipsis),
                            )).toList(),
                        onChanged: (val) {
                          setState(() => _selectedStatusFilter = val ?? '');
                          _loadInitialOffers();
                        },
                      ),
                    ),
                  ),

                  // Reset Filters Button
                  if (_searchQuery.isNotEmpty || _selectedStoreFilter != null || _selectedBadgeFilter.isNotEmpty || _selectedStatusFilter.isNotEmpty)
                    TextButton.icon(
                      onPressed: _clearAllFilters,
                      icon: const Icon(Icons.filter_alt_off, size: 16, color: Colors.red),
                      label: Text(isEn ? 'Reset' : 'إعادة ضبط', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),

                  // Stats Count Chip
                  if (_totalElements > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isEn
                            ? 'Showing ${_offers.length} of $_totalElements offers'
                            : 'عرض ${_offers.length} من $_totalElements عرض',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // 4. Offers List
  Widget _buildOffersList(bool isEn, bool isDark) {
    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _offers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final o = _offers[index];
            return _buildOfferCard(o, isEn, isDark);
          },
        ),

        // Load More Spinner
        if (_isLoadingMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A))),
                  const SizedBox(width: 10),
                  Text(isEn ? 'Loading more offers...' : 'جاري تحميل المزيد من العروض...', style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
                ],
              ),
            ),
          ),

        // End of Catalog Indicator
        if (!_isLoading && !_hasMore && _offers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      isEn ? 'All $_totalElements offers loaded' : 'تم عرض كافة العروض ($_totalElements)',
                      style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Offer Card Item
  Widget _buildOfferCard(Offer o, bool isEn, bool isDark) {
    final title = isEn ? o.titleEn : (o.titleAr.isNotEmpty ? o.titleAr : o.titleEn);
    final storeName = o.store != null
        ? (isEn ? o.store!.nameEn : (o.store!.nameAr.isNotEmpty ? o.store!.nameAr : o.store!.nameEn))
        : (isEn ? 'Store #${o.storeId}' : 'متجر #${o.storeId}');
    final categoryName = o.category != null ? (isEn ? o.category!.nameEn : (o.category!.nameAr.isNotEmpty ? o.category!.nameAr : o.category!.nameEn)) : '';
    final cityName = o.city != null ? (isEn ? o.city!.nameEn : (o.city!.nameAr.isNotEmpty ? o.city!.nameAr : o.city!.nameEn)) : '';
    final imageUrl = o.primaryImageUrl;

    // Status styling
    Color statusBg = isDark ? const Color(0xFF334155) : Colors.grey.shade100;
    Color statusColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700;
    String statusText = isEn ? 'Disabled' : 'معطل';

    if (o.isExpired) {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFD97706);
      statusText = isEn ? 'Expired' : 'منتهي';
    } else if (o.isUpcoming) {
      statusBg = const Color(0xFFEFF6FF);
      statusColor = const Color(0xFF2563EB);
      statusText = isEn ? 'Upcoming' : 'قادم';
    } else if (o.isActive == 1) {
      statusBg = const Color(0xFFDCFCE7);
      statusColor = const Color(0xFF16A34A);
      statusText = isEn ? 'Active' : 'نشط';
    }

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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;

          final thumbnailAndInfo = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Image Thumbnail with Badge Overlay
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => context.push('/offers/${o.id}'),
                child: Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                        color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl.isNotEmpty
                            ? AppNetworkImage(
                                imageUrl: AppConfig.normalizeImageUrl(imageUrl),
                                fit: BoxFit.cover,
                                defaultFallbackIcon: Icons.local_offer,
                              )
                            : const Icon(Icons.local_offer, color: Colors.grey, size: 28),
                      ),
                    ),
                    if (o.badgeType.isNotEmpty && o.badgeType != 'NONE')
                      Positioned(
                        bottom: 3,
                        left: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            o.badgeType,
                            style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Center: Details
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/offers/${o.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      // Store & Category Pills
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.storefront, size: 12, color: Color(0xFF16A34A)),
                                const SizedBox(width: 3),
                                Text(
                                  storeName,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          ),
                          if (categoryName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.category, size: 12, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 3),
                                  Text(
                                    categoryName,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF2563EB)),
                                  ),
                                ],
                              ),
                            ),
                          if (cityName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.place, size: 12, color: Color(0xFF059669)),
                                  const SizedBox(width: 3),
                                  Text(
                                    cityName,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF059669)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Pricing & Validity Row
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${o.offerPrice} SAR',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                          ),
                          if (o.originalPrice > 0)
                            Text(
                              '${o.originalPrice} SAR',
                              style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500, decoration: TextDecoration.lineThrough),
                            ),
                          if (o.discountPct > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${o.discountPct.toInt()}% OFF',
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 10.5, fontWeight: FontWeight.w800),
                              ),
                            ),
                          if (o.validFrom.isNotEmpty || o.validUntil.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.event, size: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      '${o.validFrom.split('T')[0]} → ${o.validUntil.split('T')[0]}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: o.isExpired ? const Color(0xFFDC2626) : (isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade800),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

          final actionButtons = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. View Details (Eye icon)
              _buildActionButton(
                icon: Icons.visibility_outlined,
                tooltip: isEn ? 'View Details' : 'عرض التفاصيل',
                isDark: isDark,
                hoverColor: const Color(0xFF2563EB),
                onPressed: () => context.push('/offers/${o.id}'),
              ),
              const SizedBox(width: 6),

              // 2. Extend Offer (+7 Days clock icon)
              _buildActionButton(
                icon: Icons.more_time,
                tooltip: isEn ? 'Extend Offer (+7 Days)' : 'تمديد العرض (+7 أيام)',
                isDark: isDark,
                hoverColor: const Color(0xFFD97706),
                onPressed: () => _extendOffer(o),
              ),
              const SizedBox(width: 6),

              // 3. Edit (Pencil icon)
              _buildActionButton(
                icon: Icons.edit_outlined,
                tooltip: isEn ? 'Edit' : 'تعديل',
                isDark: isDark,
                hoverColor: const Color(0xFF16A34A),
                onPressed: () => _showOfferModal(o),
              ),
              const SizedBox(width: 6),

              // 4. Delete (Trash icon)
              _buildActionButton(
                icon: Icons.delete_outline,
                tooltip: isEn ? 'Delete' : 'حذف',
                isDark: isDark,
                hoverColor: const Color(0xFFDC2626),
                onPressed: () => _deleteOffer(o),
              ),
            ],
          );

          final statusPill = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
              ],
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                thumbnailAndInfo,
                const SizedBox(height: 10),
                Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    statusPill,
                    actionButtons,
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: thumbnailAndInfo),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  statusPill,
                  const SizedBox(height: 10),
                  actionButtons,
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // Empty State Widget
  Widget _buildEmptyState(bool isEn, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_offer_outlined, size: 48, color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            isEn ? 'No offers registered' : 'لا توجد عروض مسجلة',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            isEn
                ? 'Click "Create Offer" to publish your first retail promotion.'
                : 'انقر على "إنشاء عرض جديد" لنشر أول عرض ترويجي في النظام.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _showOfferModal(),
            icon: const Icon(Icons.add, size: 18),
            label: Text(isEn ? 'Create Offer' : 'إنشاء عرض جديد', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Action Button Builder matching Angular
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback onPressed,
    required Color hoverColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 18,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
