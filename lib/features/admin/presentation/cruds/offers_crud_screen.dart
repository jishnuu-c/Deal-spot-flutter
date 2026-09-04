import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' hide Category;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/services/offer_repository.dart';
import '../../../../core/services/store_repository.dart';
import '../../../../core/services/product_repository.dart';
import '../../../../core/services/city_repository.dart';
import '../../../../core/services/category_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../models/models.dart';

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
    {'id': 'NONE', 'nameEn': 'NONE', 'nameAr': 'بدون'},
    {'id': 'FEATURED', 'nameEn': 'FEATURED', 'nameAr': 'مميز'},
    {'id': 'FLASH', 'nameEn': 'FLASH', 'nameAr': 'خاطف'},
    {'id': 'BOGO', 'nameEn': 'BOGO', 'nameAr': 'BOGO'},
    {'id': 'PROMO', 'nameEn': 'PROMO', 'nameAr': 'ترويجي'},
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
      final showTop = yOffset > 400;
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
            Text(isEn ? 'Extend Offer Expiration?' : 'تمديد فترة العرض؟', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                    backgroundColor: success ? Colors.green : Colors.red,
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
            Text(isEn ? 'Are you sure?' : 'هل أنت متأكد؟', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                    backgroundColor: Colors.green,
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
    final stores = ref.read(storeRepositoryProvider).stores;
    final cities = ref.read(cityRepositoryProvider).cities;
    final categories = ref.read(categoryRepositoryProvider);

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

    int? selectedStoreId = offer?.storeId != null && stores.any((s) => s.id == offer!.storeId)
        ? offer!.storeId
        : (stores.isNotEmpty ? stores[0].id : null);
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

            origPriceCtrl.addListener(() {
              setDialogState(() => calcDiscount());
            });
            offerPriceCtrl.addListener(() {
              setDialogState(() => calcDiscount());
            });

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860, maxHeight: 900),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isModalNarrow = constraints.maxWidth < 600;

                    return Column(
                      children: [
                        // Modal Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.local_offer, color: Theme.of(context).primaryColor, size: 24),
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
                        ),

                        // Modal Scrollable Body
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
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
                                  Text(isEn ? 'Retail Partner Store *' : 'المتجر الشريك *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<int>(
                                    value: selectedStoreId,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(isEn ? s.nameEn : (s.nameAr.isNotEmpty ? s.nameAr : s.nameEn), overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (val) => setDialogState(() => selectedStoreId = val),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(isEn ? 'Category *' : 'القسم الرئيسي *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<int>(
                                    value: selectedCategoryId,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(isEn ? c.nameEn : (c.nameAr.isNotEmpty ? c.nameAr : c.nameEn), overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(isEn ? 'City Scope *' : 'المدينة *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<int>(
                                    value: selectedCityId,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    items: cities.map((c) => DropdownMenuItem(value: c.id, child: Text(isEn ? c.nameEn : (c.nameAr.isNotEmpty ? c.nameAr : c.nameEn), overflow: TextOverflow.ellipsis))).toList(),
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
                                            Text(isEn ? 'Retail Partner Store *' : 'المتجر الشريك *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const SizedBox(height: 6),
                                            DropdownButtonFormField<int>(
                                              value: selectedStoreId,
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              ),
                                              items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(isEn ? s.nameEn : (s.nameAr.isNotEmpty ? s.nameAr : s.nameEn), overflow: TextOverflow.ellipsis))).toList(),
                                              onChanged: (val) => setDialogState(() => selectedStoreId = val),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(isEn ? 'Category *' : 'القسم الرئيسي *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const SizedBox(height: 6),
                                            DropdownButtonFormField<int>(
                                              value: selectedCategoryId,
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              ),
                                              items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(isEn ? c.nameEn : (c.nameAr.isNotEmpty ? c.nameAr : c.nameEn), overflow: TextOverflow.ellipsis))).toList(),
                                              onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(isEn ? 'City Scope *' : 'المدينة *', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const SizedBox(height: 6),
                                            DropdownButtonFormField<int>(
                                              value: selectedCityId,
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              ),
                                              items: cities.map((c) => DropdownMenuItem(value: c.id, child: Text(isEn ? c.nameEn : (c.nameAr.isNotEmpty ? c.nameAr : c.nameEn), overflow: TextOverflow.ellipsis))).toList(),
                                              onChanged: (val) => setDialogState(() => selectedCityId = val),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 20),

                                // 3. Catalog Linked Product Section
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey),
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
                                                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                                                const SizedBox(width: 6),
                                                Text(isEn ? 'Searching...' : 'جاري البحث...', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // If Product Selected: Show Tile Card
                                      if (selectedProduct != null)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 56,
                                                height: 56,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey.shade300),
                                                  image: selectedProduct!.primaryImageUrl.isNotEmpty
                                                      ? DecorationImage(
                                                          image: NetworkImage(AppConfig.normalizeImageUrl(selectedProduct!.primaryImageUrl)),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                ),
                                                child: selectedProduct!.primaryImageUrl.isEmpty
                                                    ? const Icon(Icons.shopping_bag_outlined, color: Colors.grey)
                                                    : null,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            isEn ? selectedProduct!.nameEn : (selectedProduct!.nameAr.isNotEmpty ? selectedProduct!.nameAr : selectedProduct!.nameEn),
                                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                                          onPressed: () => selectProduct(null),
                                                          tooltip: isEn ? 'Remove link' : 'إلغاء الربط',
                                                        ),
                                                      ],
                                                    ),
                                                    Wrap(
                                                      spacing: 6,
                                                      runSpacing: 4,
                                                      children: [
                                                        if (selectedProduct!.brand.isNotEmpty)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                                            child: Text(selectedProduct!.brand, style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                                                          ),
                                                        if (selectedProduct!.sku.isNotEmpty)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                                            child: Text('SKU: ${selectedProduct!.sku}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                                                          ),
                                                        if (selectedProduct!.unit.isNotEmpty)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                                                            child: Text('${selectedProduct!.unitSize} ${selectedProduct!.unit}', style: TextStyle(fontSize: 11, color: Colors.green.shade800)),
                                                          ),
                                                      ],
                                                    ),
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
                                            constraints: const BoxConstraints(maxHeight: 220),
                                            margin: const EdgeInsets.only(top: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
                                              boxShadow: [
                                                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
                                              ],
                                            ),
                                            child: ListView(
                                              shrinkWrap: true,
                                              children: [
                                                // General Option
                                                ListTile(
                                                  dense: true,
                                                  leading: const CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: Color(0xFFF1F5F9),
                                                    child: Icon(Icons.storefront, size: 18, color: Colors.blueGrey),
                                                  ),
                                                  title: Text(isEn ? 'General Store Promotion' : 'عرض عام للمتجر', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                  subtitle: Text(isEn ? 'No specific catalog product linked' : 'بدون ربط بمنتج محدد من الدليل', style: const TextStyle(fontSize: 11)),
                                                  trailing: const Icon(Icons.check, color: Colors.green, size: 18),
                                                  onTap: () => selectProduct(null),
                                                ),
                                                const Divider(height: 1),
                                                ...productOptions.map((prod) => ListTile(
                                                      dense: true,
                                                      leading: Container(
                                                        width: 36,
                                                        height: 36,
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(color: Colors.grey.shade300),
                                                          image: prod.primaryImageUrl.isNotEmpty
                                                              ? DecorationImage(image: NetworkImage(AppConfig.normalizeImageUrl(prod.primaryImageUrl)), fit: BoxFit.cover)
                                                              : null,
                                                        ),
                                                        child: prod.primaryImageUrl.isEmpty ? const Icon(Icons.shopping_bag, size: 18, color: Colors.grey) : null,
                                                      ),
                                                      title: Text(isEn ? prod.nameEn : (prod.nameAr.isNotEmpty ? prod.nameAr : prod.nameEn), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                      subtitle: Text('SKU: ${prod.sku} | ${prod.brand}', style: const TextStyle(fontSize: 11)),
                                                      trailing: const Icon(Icons.add_circle_outline, color: Colors.orange, size: 20),
                                                      onTap: () => selectProduct(prod),
                                                    )),
                                                if (!isSearchingProducts && productOptions.isEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.all(16),
                                                    child: Center(
                                                      child: Text(isEn ? 'No catalog products match your search.' : 'لا توجد منتجات مطابقة في الدليل.', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
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
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Theme.of(context).primaryColor, style: BorderStyle.solid),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '$discountPct%',
                                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Theme.of(context).primaryColor),
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
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: Theme.of(context).primaryColor, style: BorderStyle.solid),
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      '$discountPct%',
                                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Theme.of(context).primaryColor),
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
                                  Text(isEn ? 'Promotion Badge' : 'شارة العرض', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: selectedBadgeType,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    items: _badgeTypeOptions.map((b) => DropdownMenuItem(value: b['id'], child: Text(isEn ? b['nameEn']! : b['nameAr']!, overflow: TextOverflow.ellipsis))).toList(),
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
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(isEn ? 'Promotion Badge' : 'شارة العرض', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const SizedBox(height: 6),
                                            DropdownButtonFormField<String>(
                                              value: selectedBadgeType,
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              ),
                                              items: _badgeTypeOptions.map((b) => DropdownMenuItem(value: b['id'], child: Text(isEn ? b['nameEn']! : b['nameAr']!, overflow: TextOverflow.ellipsis))).toList(),
                                              onChanged: (val) => setDialogState(() => selectedBadgeType = val ?? 'NONE'),
                                            ),
                                          ],
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

                                // 7. Image Upload Section
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.image_outlined, size: 18, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(
                                            isEn ? 'Offer Promotional Images' : 'الصور الترويجية للعرض',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                                              child: Image.network(
                                                AppConfig.normalizeImageUrl(existingImageUrl),
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(isEn ? 'Current Active Image' : 'الصورة الحالية', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 24),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                          ),
                                          child: Column(
                                            children: [
                                              const Icon(Icons.cloud_upload_outlined, size: 36, color: Colors.orange),
                                              const SizedBox(height: 8),
                                              Text(
                                                isEn ? 'Click or Tap to upload images' : 'انقر لاختيار الصور وتحميلها',
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
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: List.generate(pickedImages.length, (idx) {
                                            return Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.memory(
                                                    pickedImageBytes[idx],
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 2,
                                                  right: 2,
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
                                                        color: Colors.red,
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

                                // 8. Flags & Toggles
                                Material(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      children: [
                                        CheckboxListTile(
                                          dense: true,
                                          title: Text(isEn ? 'Set as Featured Deal' : 'تمييز العرض في التوصيات'),
                                          value: isFeatured,
                                          onChanged: (val) => setDialogState(() => isFeatured = val ?? false),
                                        ),
                                        CheckboxListTile(
                                          dense: true,
                                          title: Text(isEn ? 'Set as Flash Deal (Limited Time)' : 'عرض خاطف لفترة محدودة'),
                                          value: isFlash,
                                          onChanged: (val) => setDialogState(() => isFlash = val ?? false),
                                        ),
                                        CheckboxListTile(
                                          dense: true,
                                          title: Text(isEn ? 'Available In-Store' : 'متاح في فروع المتجر'),
                                          value: isInStore,
                                          onChanged: (val) => setDialogState(() => isInStore = val ?? true),
                                        ),
                                        CheckboxListTile(
                                          dense: true,
                                          title: Text(isEn ? 'Available Online' : 'متاح عبر الإنترنت'),
                                          value: isOnline,
                                          onChanged: (val) => setDialogState(() => isOnline = val ?? false),
                                        ),
                                        CheckboxListTile(
                                          dense: true,
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

                        // Modal Footer
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
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
                                  backgroundColor: Theme.of(context).primaryColor,
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
                                              content: Text(isEn ? 'Please select Store, Category, and City.' : 'يرجى اختيار المتجر، القسم، والمدينة.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }

                                        final orig = double.tryParse(origPriceCtrl.text.trim()) ?? 0;
                                        final off = double.tryParse(offerPriceCtrl.text.trim()) ?? 0;
                                        final disc = orig > 0 ? (((orig - off) / orig) * 100).roundToDouble() : 0.0;

                                        setDialogState(() => isSaving = true);

                                        final success = await ref.read(offerRepositoryProvider.notifier).saveOfferMultipart(
                                          id: offer?.id,
                                          titleEn: titleEn,
                                          titleAr: titleAr,
                                          origPrice: orig,
                                          offerPrice: off,
                                          discountPct: disc,
                                          badgeType: selectedBadgeType,
                                          validFrom: fromCtrl.text.trim(),
                                          validUntil: untilCtrl.text.trim(),
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
                                              backgroundColor: success ? Colors.green : Colors.red,
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
                        ),
                      ],
                    );
                  },
                ),
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
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1300),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with Title & Action Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEn ? 'Manage Deals & Promotions' : 'إدارة العروض والتخفيضات',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isEn
                                      ? 'Create, configure, and publish promotional offers and discounts'
                                      : 'إنشاء وضبط ونشر عروض التخفيضات والصفقات الترويجية للمتاجر',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 2,
                              ),
                              onPressed: () => _showOfferModal(),
                              icon: const Icon(Icons.add, size: 20),
                              label: Text(
                                isEn ? 'Create Offer' : 'إنشاء عرض جديد',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Filters & Search Toolbar
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Search Input
                                  SizedBox(
                                    width: 280,
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: _onSearchChanged,
                                      decoration: InputDecoration(
                                        hintText: isEn ? 'Search by title, store, or category...' : 'ابحث بالعنوان، المتجر، أو القسم...',
                                        hintStyle: const TextStyle(fontSize: 13),
                                        prefixIcon: const Icon(Icons.search, size: 20),
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.close, size: 18),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  _onSearchChanged('');
                                                },
                                              )
                                            : null,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                      ),
                                    ),
                                  ),

                                  // Store Filter
                                  Container(
                                    width: 180,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade300),
                                      color: Colors.white,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<int?>(
                                        value: _selectedStoreFilter,
                                        isExpanded: true,
                                        hint: Text(isEn ? 'All Retail Stores' : 'جميع المتاجر', style: const TextStyle(fontSize: 13)),
                                        items: [
                                          DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text(isEn ? 'All Retail Stores' : 'جميع المتاجر', style: const TextStyle(fontSize: 13)),
                                          ),
                                          ...stores.map((s) => DropdownMenuItem<int?>(
                                                value: s.id,
                                                child: Text(isEn ? s.nameEn : (s.nameAr.isNotEmpty ? s.nameAr : s.nameEn), style: const TextStyle(fontSize: 13)),
                                              )),
                                        ],
                                        onChanged: (val) {
                                          setState(() => _selectedStoreFilter = val);
                                          _loadInitialOffers();
                                        },
                                      ),
                                    ),
                                  ),

                                  // Badge Filter
                                  Container(
                                    width: 150,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade300),
                                      color: Colors.white,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedBadgeFilter,
                                        isExpanded: true,
                                        items: _badgeFilterOptions.map((b) => DropdownMenuItem<String>(
                                              value: b['id'],
                                              child: Text(isEn ? b['nameEn']! : b['nameAr']!, style: const TextStyle(fontSize: 13)),
                                            )).toList(),
                                        onChanged: (val) {
                                          setState(() => _selectedBadgeFilter = val ?? '');
                                          _loadInitialOffers();
                                        },
                                      ),
                                    ),
                                  ),

                                  // Status Filter
                                  Container(
                                    width: 150,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade300),
                                      color: Colors.white,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedStatusFilter,
                                        isExpanded: true,
                                        items: _statusFilterOptions.map((s) => DropdownMenuItem<String>(
                                              value: s['id'],
                                              child: Text(isEn ? s['nameEn']! : s['nameAr']!, style: const TextStyle(fontSize: 13)),
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
                                      icon: const Icon(Icons.filter_alt_off, size: 18, color: Colors.red),
                                      label: Text(isEn ? 'Reset' : 'إعادة ضبط', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    ),

                                  // Stats Chip
                                  if (_totalElements > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isEn
                                            ? 'Showing ${_offers.length} of $_totalElements offers'
                                            : 'عرض ${_offers.length} من $_totalElements عرض',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Offers List
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(48.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_offers.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(48),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  isEn ? 'No offers registered' : 'لا توجد عروض مسجلة',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isEn
                                      ? 'Click "Create Offer" to publish your first retail promotion.'
                                      : 'انقر على "إنشاء عرض جديد" لنشر أول عرض ترويجي في النظام.',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _offers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final o = _offers[index];
                              return _buildOfferCard(o, isEn);
                            },
                          ),

                        // Load More Spinner
                        if (_isLoadingMore)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                  const SizedBox(width: 10),
                                  Text(isEn ? 'Loading more offers...' : 'جاري تحميل المزيد من العروض...', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),

                        // End of Catalog Indicator
                        if (!_isLoading && !_hasMore && _offers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEn ? 'All $_totalElements offers loaded' : 'تم عرض كافة العروض ($_totalElements)',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Scroll To Top Button
              if (_showScrollTop)
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: FloatingActionButton.small(
                    onPressed: _scrollToTop,
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.keyboard_arrow_up),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard(Offer o, bool isEn) {
    final title = isEn ? o.titleEn : (o.titleAr.isNotEmpty ? o.titleAr : o.titleEn);
    final storeName = o.store != null
        ? (isEn ? o.store!.nameEn : (o.store!.nameAr.isNotEmpty ? o.store!.nameAr : o.store!.nameEn))
        : (isEn ? 'Store #${o.storeId}' : 'متجر #${o.storeId}');
    final categoryName = o.category != null ? (isEn ? o.category!.nameEn : (o.category!.nameAr.isNotEmpty ? o.category!.nameAr : o.category!.nameEn)) : '';
    final cityName = o.city != null ? (isEn ? o.city!.nameEn : (o.city!.nameAr.isNotEmpty ? o.city!.nameAr : o.city!.nameEn)) : '';

    final imageUrl = o.primaryImageUrl;

    // Status styling
    Color statusBg = Colors.grey.shade100;
    Color statusColor = Colors.grey.shade700;
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
      statusBg = const Color(0xFFECFDF5);
      statusColor = const Color(0xFF10B981);
      statusText = isEn ? 'Active' : 'نشط';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 700;

          final leftAndCenter = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Thumbnail Box with Badge Chip
              InkWell(
                onTap: () => context.push('/offers/${o.id}'),
                child: Stack(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.grey.shade50,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                AppConfig.normalizeImageUrl(imageUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.local_offer, color: Colors.grey, size: 30),
                              )
                            : const Icon(Icons.local_offer, color: Colors.grey, size: 30),
                      ),
                    ),
                    if (o.badgeType.isNotEmpty && o.badgeType != 'NONE')
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            o.badgeType,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Center: Details
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/offers/${o.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.storefront, size: 14, color: Theme.of(context).primaryColor),
                                const SizedBox(width: 4),
                                Text(storeName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor)),
                              ],
                            ),
                          ),
                          if (categoryName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.category, size: 14, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 4),
                                  Text(categoryName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF2563EB))),
                                ],
                              ),
                            ),
                          if (cityName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.place, size: 14, color: Color(0xFF059669)),
                                  const SizedBox(width: 4),
                                  Text(cityName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF059669))),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Pricing & Validity Row
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${o.offerPrice} SAR',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).primaryColor),
                          ),
                          if (o.originalPrice > 0)
                            Text(
                              '${o.originalPrice} SAR',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough),
                            ),
                          if (o.discountPct > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${o.discountPct.toInt()}% OFF',
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          if (o.validFrom.isNotEmpty || o.validUntil.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.event, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${o.validFrom.split('T')[0]} → ',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  o.validUntil.split('T')[0],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: o.isExpired ? const Color(0xFFDC2626) : Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

          final rightGroup = Column(
            crossAxisAlignment: isNarrow ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    tooltip: isEn ? 'View Details' : 'عرض التفاصيل',
                    onPressed: () => context.push('/offers/${o.id}'),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFEF3C7),
                      foregroundColor: const Color(0xFFD97706),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.more_time, size: 18),
                    tooltip: isEn ? 'Extend Offer (+7 Days)' : 'تمديد العرض (+7 أيام)',
                    onPressed: () => _extendOffer(o),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: isEn ? 'Edit' : 'تعديل',
                    onPressed: () => _showOfferModal(o),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: isEn ? 'Delete' : 'حذف',
                    onPressed: () => _deleteOffer(o),
                  ),
                ],
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftAndCenter,
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    rightGroup.children[0], // status pill
                    rightGroup.children[2], // action buttons
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: leftAndCenter),
              const SizedBox(width: 16),
              rightGroup,
            ],
          );
        },
      ),
    );
  }
}
