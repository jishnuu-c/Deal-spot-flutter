import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/auth_repository.dart';
import '../../../../core/services/coupon_repository.dart';
import '../../../../core/services/offer_repository.dart';
import '../../../../core/services/store_repository.dart';
import '../../../../core/services/product_repository.dart';
import '../../../../core/utils/translation_service.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/custom_select_widget.dart';
import '../../../../models/models.dart';
import '../widgets/crud_loading_widget.dart';

class CouponsCrudScreen extends ConsumerStatefulWidget {
  const CouponsCrudScreen({super.key});

  @override
  ConsumerState<CouponsCrudScreen> createState() => _CouponsCrudScreenState();
}

class _CouponsCrudScreenState extends ConsumerState<CouponsCrudScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  int? _selectedStoreFilter;
  String _selectedDiscountTypeFilter = '';
  String _selectedStatusFilter = 'all'; // 'all' | 'active' | 'inactive'
  bool _isLoading = true;
  int? _copiedCouponId;
  Timer? _copyTimer;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final adminUser = authState.currentAdmin;
      if (adminUser?.role == 'STORE_MANAGER' && adminUser?.storeId != null) {
        _selectedStoreFilter = adminUser!.storeId;
      }
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _copyTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final futures = <Future>[
        ref.read(couponRepositoryProvider.notifier).fetchCoupons(),
      ];
      if (ref.read(storeRepositoryProvider).stores.isEmpty) {
        futures.add(ref.read(storeRepositoryProvider.notifier).fetchStores());
      }
      if (ref.read(offerRepositoryProvider).offers.isEmpty) {
        futures.add(ref.read(offerRepositoryProvider.notifier).fetchOffers(includeExpired: true));
      }
      await Future.wait(futures);
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _searchQuery = query);
      }
    });
  }

  void _copyCouponCode(String code, int couponId, bool isRtl) {
    Clipboard.setData(ClipboardData(text: code));
    _copyTimer?.cancel();
    setState(() => _copiedCouponId = couponId);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRtl ? 'تم نسخ كود الخصم: $code' : 'Coupon code copied: $code',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    _copyTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copiedCouponId = null);
      }
    });
  }

  List<CouponCode> _getFilteredCoupons(List<CouponCode> allCoupons) {
    var list = allCoupons;
    final query = _searchQuery.toLowerCase().trim();

    if (query.isNotEmpty) {
      list = list.where((c) {
        final code = c.code.toLowerCase();
        final storeEn = (c.storeNameEn ?? c.store?.nameEn ?? '').toLowerCase();
        final storeAr = (c.storeNameAr ?? c.store?.nameAr ?? '').toLowerCase();
        final offerEn = (c.offerTitleEn ?? c.offer?.titleEn ?? '').toLowerCase();
        final offerAr = (c.offerTitleAr ?? c.offer?.titleAr ?? '').toLowerCase();
        final prodEn = (c.productNameEn ?? c.product?.nameEn ?? '').toLowerCase();
        final prodAr = (c.productNameAr ?? c.product?.nameAr ?? '').toLowerCase();
        final idStr = c.id.toString();

        return code.contains(query) ||
            storeEn.contains(query) ||
            storeAr.contains(query) ||
            offerEn.contains(query) ||
            offerAr.contains(query) ||
            prodEn.contains(query) ||
            prodAr.contains(query) ||
            idStr == query;
      }).toList();
    }

    if (_selectedStoreFilter != null) {
      list = list.where((c) => c.storeId == _selectedStoreFilter).toList();
    }

    if (_selectedDiscountTypeFilter.isNotEmpty) {
      list = list.where((c) {
        var dType = c.discountType;
        if (dType == 'PERCENTAGE') dType = 'PERCENT';
        if (dType == 'FIXED') dType = 'FIXED_SAR';
        return dType == _selectedDiscountTypeFilter;
      }).toList();
    }

    if (_selectedStatusFilter == 'active') {
      list = list.where((c) => c.active).toList();
    } else if (_selectedStatusFilter == 'inactive') {
      list = list.where((c) => !c.active).toList();
    }

    return list;
  }

  void _showAddEditCouponModal(BuildContext context, bool isRtl, bool isDark, [CouponCode? coupon]) {
    final isEditing = coupon != null;
    final stores = ref.read(storeRepositoryProvider).stores;
    final offers = ref.read(offerRepositoryProvider).offers;
    final authState = ref.read(authProvider);
    final adminUser = authState.currentAdmin;

    final defaultStoreId = (adminUser?.role == 'STORE_MANAGER' && adminUser?.storeId != null)
        ? adminUser!.storeId!
        : (coupon?.storeId ?? (stores.isNotEmpty ? stores.first.id : null));

    final codeCtrl = TextEditingController(text: coupon?.code ?? '');
    final discountValCtrl = TextEditingController(
      text: coupon != null ? coupon.discountValue.toString() : '10',
    );
    final minCartCtrl = TextEditingController(
      text: coupon?.minCartValue != null ? coupon!.minCartValue.toString() : '0',
    );
    final maxUsesCtrl = TextEditingController(
      text: coupon?.maxUses != null ? coupon!.maxUses.toString() : '100',
    );

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final futureDate = now.add(const Duration(days: 30));
    final nextMonthStr = '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';

    final validFromCtrl = TextEditingController(
      text: coupon != null ? coupon.validFrom : todayStr,
    );
    final validUntilCtrl = TextEditingController(
      text: coupon != null ? coupon.validUntil : nextMonthStr,
    );

    int? selectedStoreId = defaultStoreId;
    int? selectedOfferId = coupon?.offerId;
    String discountType = coupon?.discountType ?? 'PERCENT';
    if (discountType == 'PERCENTAGE') discountType = 'PERCENT';
    if (discountType == 'FIXED') discountType = 'FIXED_SAR';

    bool isActive = coupon == null ? true : coupon.active;

    // Product live search state
    Product? selectedProduct = coupon?.product;
    final productSearchCtrl = TextEditingController();
    List<Product> productOptions = [];
    bool isProductDropdownOpen = false;
    bool productSearchLoading = false;
    Timer? productSearchDebounce;
    bool isSaving = false;

    // If editing and product is linked by ID, find it from cached products or build stub
    if (coupon?.productId != null && selectedProduct == null) {
      final cachedProds = ref.read(productRepositoryProvider).products;
      try {
        selectedProduct = cachedProds.firstWhere((p) => p.id == coupon!.productId);
      } catch (_) {
        if (coupon?.productNameEn != null) {
          selectedProduct = Product(
            id: coupon!.productId!,
            categoryId: 0,
            brand: '',
            brandAr: '',
            sku: '',
            barcode: '',
            nameEn: coupon.productNameEn!,
            nameAr: coupon.productNameAr ?? coupon.productNameEn!,
            primaryImageUrl: '',
            unit: 'EACH',
            unitSize: 1,
            isActive: 1,
          );
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          void searchCatalogProducts(String q) {
            productSearchDebounce?.cancel();
            setModalState(() => productSearchLoading = true);
            productSearchDebounce = Timer(const Duration(milliseconds: 250), () async {
              try {
                final paged = await ref.read(productRepositoryProvider.notifier).getPagedProducts(
                  page: 0,
                  size: 30,
                  search: q.trim().isNotEmpty ? q.trim() : null,
                );
                setModalState(() {
                  productOptions = paged.content;
                  productSearchLoading = false;
                });
              } catch (_) {
                setModalState(() => productSearchLoading = false);
              }
            });
          }

          void openProductDropdown() {
            setModalState(() => isProductDropdownOpen = true);
            if (productOptions.isEmpty) {
              searchCatalogProducts(productSearchCtrl.text);
            }
          }

          final storeOptions = stores
              .map((s) => CustomSelectOption<int>(
                    value: s.id,
                    labelEn: s.nameEn,
                    labelAr: s.nameAr,
                    imageUrl: s.logoUrl,
                  ))
              .toList();

          final offerOptions = [
            CustomSelectOption<int?>(
              value: null,
              labelEn: 'Store-wide (No specific offer link)',
              labelAr: 'شامل للمتجر (بدون ربط بعرض محدد)',
            ),
            ...offers.map((o) => CustomSelectOption<int?>(
                  value: o.id,
                  labelEn: o.titleEn,
                  labelAr: o.titleAr,
                )),
          ];

          final discountTypeOptions = [
            const CustomSelectOption<String>(
              value: 'PERCENT',
              labelEn: 'PERCENT (%)',
              labelAr: 'نسبة مئوية (%)',
            ),
            const CustomSelectOption<String>(
              value: 'FIXED_SAR',
              labelEn: 'FIXED VALUE (SAR)',
              labelAr: 'مبلغ ثابت (ر.س)',
            ),
          ];

          return Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: 720,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dialog Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.confirmation_number_outlined,
                                    color: Color(0xFF10B981),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isEditing
                                        ? (isRtl ? 'تعديل كود الخصم' : 'Edit Promo Coupon')
                                        : (isRtl ? 'إنشاء كود خصم جديد' : 'Create New Promo Coupon'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            onPressed: () => Navigator.pop(dialogCtx),
                          ),
                        ],
                      ),
                    ),

                    // Dialog Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: Code & Store
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 520;

                                final codeWidget = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel(
                                      isRtl
                                          ? 'كود الخصم (أحرف إنجليزية وأرقام) *'
                                          : 'Coupon Code (UPPERCASE) *',
                                      isDark,
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: codeCtrl,
                                      textCapitalization: TextCapitalization.characters,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. EXTRA20',
                                        prefixIcon: const Icon(Icons.tag, size: 18),
                                        filled: true,
                                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      ),
                                    ),
                                  ],
                                );

                                final storeWidget = AppCustomSelect<int>(
                                  label: isRtl ? 'المتجر الشريك' : 'Retail Partner Store',
                                  isRequired: true,
                                  placeholder: isRtl ? 'اختر المتجر' : 'Select Store',
                                  selectedValue: selectedStoreId,
                                  options: storeOptions,
                                  onChanged: (val) => setModalState(() => selectedStoreId = val),
                                );

                                if (isNarrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      codeWidget,
                                      const SizedBox(height: 14),
                                      storeWidget,
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: codeWidget),
                                    const SizedBox(width: 14),
                                    Expanded(child: storeWidget),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // Row 2: Linked Offer & Linked Product
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 520;

                                final offerWidget = AppCustomSelect<int?>(
                                  label: isRtl
                                      ? 'ربط بعرض ترويجي (اختياري)'
                                      : 'Linked Offer / Promotion (Optional)',
                                  placeholder: isRtl
                                      ? 'شامل للمتجر (بدون ربط بعرض محدد)'
                                      : 'Store-wide (No specific offer link)',
                                  selectedValue: selectedOfferId,
                                  options: offerOptions,
                                  clearable: true,
                                  onChanged: (val) => setModalState(() => selectedOfferId = val),
                                );

                                final productWidget = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: _buildFieldLabel(
                                            isRtl
                                                ? 'ربط بمنتج محدد (اختياري)'
                                                : 'Linked Catalog Product (Optional)',
                                            isDark,
                                          ),
                                        ),
                                        if (productSearchLoading) ...[
                                          const SizedBox(width: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFF10B981),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isRtl ? 'جاري البحث...' : 'Searching...',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // Product Selection View
                                    if (selectedProduct != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: const Color(0xFFE2E8F0),
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: selectedProduct!.primaryImageUrl.isNotEmpty
                                                    ? AppNetworkImage(
                                                        imageUrl: selectedProduct!.primaryImageUrl,
                                                        fit: BoxFit.contain,
                                                      )
                                                    : const Icon(
                                                        Icons.shopping_bag_outlined,
                                                        color: Color(0xFF94A3B8),
                                                        size: 22,
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    isRtl
                                                        ? (selectedProduct!.nameAr.isNotEmpty
                                                            ? selectedProduct!.nameAr
                                                            : selectedProduct!.nameEn)
                                                        : selectedProduct!.nameEn,
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Wrap(
                                                    spacing: 4,
                                                    runSpacing: 4,
                                                    children: [
                                                      if (selectedProduct!.brand.isNotEmpty)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            isRtl && selectedProduct!.brandAr.isNotEmpty
                                                                ? selectedProduct!.brandAr
                                                                : selectedProduct!.brand,
                                                            style: const TextStyle(
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w600,
                                                              color: Color(0xFF10B981),
                                                            ),
                                                          ),
                                                        ),
                                                      if (selectedProduct!.sku.isNotEmpty)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                          decoration: BoxDecoration(
                                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            'SKU: ${selectedProduct!.sku}',
                                                            style: TextStyle(
                                                              fontSize: 9.5,
                                                              fontWeight: FontWeight.w600,
                                                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close, size: 18),
                                              color: const Color(0xFFEF4444),
                                              tooltip: isRtl ? 'إلغاء ربط المنتج' : 'Remove product link',
                                              onPressed: () {
                                                setModalState(() {
                                                  selectedProduct = null;
                                                  isProductDropdownOpen = false;
                                                  productSearchCtrl.clear();
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          TextField(
                                            controller: productSearchCtrl,
                                            onChanged: (val) {
                                              setModalState(() => isProductDropdownOpen = true);
                                              searchCatalogProducts(val);
                                            },
                                            onTap: openProductDropdown,
                                            style: const TextStyle(fontSize: 13),
                                            decoration: InputDecoration(
                                              hintText: isRtl
                                                  ? 'ابحث باسم المنتج، SKU أو الباركود...'
                                                  : 'Search product by name, SKU...',
                                              hintStyle: const TextStyle(fontSize: 12),
                                              prefixIcon: const Icon(Icons.search, size: 18),
                                              suffixIcon: productSearchCtrl.text.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(Icons.close, size: 16),
                                                      onPressed: () {
                                                        productSearchCtrl.clear();
                                                        searchCatalogProducts('');
                                                      },
                                                    )
                                                  : null,
                                              filled: true,
                                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            ),
                                          ),

                                          // Autocomplete Dropdown
                                          if (isProductDropdownOpen) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              constraints: const BoxConstraints(maxHeight: 200),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.12),
                                                    blurRadius: 14,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          isRtl ? 'منتجات الدليل' : 'Catalog Products',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w700,
                                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                          ),
                                                        ),
                                                        InkWell(
                                                          onTap: () => setModalState(() => isProductDropdownOpen = false),
                                                          child: const Icon(Icons.close, size: 14),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: ListView(
                                                      shrinkWrap: true,
                                                      padding: EdgeInsets.zero,
                                                      children: [
                                                        ListTile(
                                                          dense: true,
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                                          leading: const Icon(Icons.storefront, color: Color(0xFF10B981), size: 18),
                                                          title: Text(
                                                            isRtl ? 'جميع المنتجات (شامل للمتجر)' : 'All Products (Store-Wide)',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w700,
                                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                            ),
                                                          ),
                                                          trailing: const Icon(Icons.check, size: 16, color: Color(0xFF10B981)),
                                                          onTap: () {
                                                            setModalState(() {
                                                              selectedProduct = null;
                                                              isProductDropdownOpen = false;
                                                              productSearchCtrl.clear();
                                                            });
                                                          },
                                                        ),
                                                        const Divider(height: 1),
                                                        if (productOptions.isEmpty && !productSearchLoading)
                                                          Padding(
                                                            padding: const EdgeInsets.all(14),
                                                            child: Center(
                                                              child: Text(
                                                                isRtl ? 'لا توجد منتجات مطابقة' : 'No catalog products match search.',
                                                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                                              ),
                                                            ),
                                                          )
                                                        else
                                                          ...productOptions.map(
                                                            (p) => ListTile(
                                                              dense: true,
                                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                                              leading: Container(
                                                                width: 28,
                                                                height: 28,
                                                                decoration: BoxDecoration(
                                                                  color: Colors.white,
                                                                  borderRadius: BorderRadius.circular(4),
                                                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                                                ),
                                                                child: ClipRRect(
                                                                  borderRadius: BorderRadius.circular(4),
                                                                  child: p.primaryImageUrl.isNotEmpty
                                                                      ? AppNetworkImage(imageUrl: p.primaryImageUrl, fit: BoxFit.contain)
                                                                      : const Icon(Icons.shopping_bag_outlined, size: 14, color: Color(0xFF94A3B8)),
                                                                ),
                                                              ),
                                                              title: Text(
                                                                isRtl ? (p.nameAr.isNotEmpty ? p.nameAr : p.nameEn) : p.nameEn,
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              trailing: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF10B981)),
                                                              onTap: () {
                                                                setModalState(() {
                                                                  selectedProduct = p;
                                                                  isProductDropdownOpen = false;
                                                                  productSearchCtrl.clear();
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                );

                                if (isNarrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      offerWidget,
                                      const SizedBox(height: 14),
                                      productWidget,
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: offerWidget),
                                    const SizedBox(width: 14),
                                    Expanded(child: productWidget),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // Discount Parameters Card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isNarrow = constraints.maxWidth < 560;

                                  final discountTypeWidget = AppCustomSelect<String>(
                                    label: isRtl ? 'نوع الخصم' : 'Discount Type',
                                    isRequired: true,
                                    placeholder: isRtl ? 'اختر نوع الخصم' : 'Select Discount Type',
                                    selectedValue: discountType,
                                    options: discountTypeOptions,
                                    onChanged: (val) {
                                      if (val != null) {
                                        setModalState(() => discountType = val);
                                      }
                                    },
                                  );

                                  final discountValWidget = Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        isRtl
                                            ? (discountType == 'PERCENT'
                                                ? 'قيمة الخصم (%) *'
                                                : 'قيمة الخصم (ر.س) *')
                                            : (discountType == 'PERCENT'
                                                ? 'Discount Value (%) *'
                                                : 'Discount Value (SAR) *'),
                                        isDark,
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: discountValCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(fontSize: 13),
                                        decoration: _buildInputDecoration(isDark, hint: '10'),
                                      ),
                                    ],
                                  );

                                  final minCartWidget = Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel(
                                        isRtl
                                            ? 'الحد الأدنى للطلب (ر.س)'
                                            : 'Min. Cart Value (SAR)',
                                        isDark,
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: minCartCtrl,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(fontSize: 13),
                                        decoration: _buildInputDecoration(
                                          isDark,
                                          hint: isRtl ? '0 بدون حد' : '0 for no min',
                                        ),
                                      ),
                                    ],
                                  );

                                  if (isNarrow) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        discountTypeWidget,
                                        const SizedBox(height: 12),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: discountValWidget),
                                            const SizedBox(width: 10),
                                            Expanded(child: minCartWidget),
                                          ],
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 2, child: discountTypeWidget),
                                      const SizedBox(width: 12),
                                      Expanded(flex: 2, child: discountValWidget),
                                      const SizedBox(width: 12),
                                      Expanded(flex: 2, child: minCartWidget),
                                    ],
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Validity Dates & Usage Limits
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 560;

                                final maxUsesWidget = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel(
                                      isRtl ? 'أقصى عدد للاستخدام' : 'Maximum Uses Allowed',
                                      isDark,
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: maxUsesCtrl,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: _buildInputDecoration(isDark, hint: '100'),
                                    ),
                                  ],
                                );

                                final validFromWidget = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel(
                                      isRtl ? 'ساري من تاريخ *' : 'Valid From *',
                                      isDark,
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: validFromCtrl,
                                      style: const TextStyle(fontSize: 13),
                                      readOnly: true,
                                      onTap: () async {
                                        final current = DateTime.tryParse(validFromCtrl.text) ?? DateTime.now();
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: current,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2035),
                                        );
                                        if (picked != null) {
                                          setModalState(() {
                                            validFromCtrl.text =
                                                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                          });
                                        }
                                      },
                                      decoration: _buildInputDecoration(
                                        isDark,
                                        hint: 'YYYY-MM-DD',
                                        suffixIcon: const Icon(Icons.calendar_today, size: 16),
                                      ),
                                    ),
                                  ],
                                );

                                final validUntilWidget = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFieldLabel(
                                      isRtl ? 'ساري حتى تاريخ *' : 'Valid Until *',
                                      isDark,
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: validUntilCtrl,
                                      style: const TextStyle(fontSize: 13),
                                      readOnly: true,
                                      onTap: () async {
                                        final current = DateTime.tryParse(validUntilCtrl.text) ?? DateTime.now();
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: current,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2035),
                                        );
                                        if (picked != null) {
                                          setModalState(() {
                                            validUntilCtrl.text =
                                                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                          });
                                        }
                                      },
                                      decoration: _buildInputDecoration(
                                        isDark,
                                        hint: 'YYYY-MM-DD',
                                        suffixIcon: const Icon(Icons.event, size: 16),
                                      ),
                                    ),
                                  ],
                                );

                                if (isNarrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      maxUsesWidget,
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: validFromWidget),
                                          const SizedBox(width: 10),
                                          Expanded(child: validUntilWidget),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 2, child: maxUsesWidget),
                                    const SizedBox(width: 12),
                                    Expanded(flex: 2, child: validFromWidget),
                                    const SizedBox(width: 12),
                                    Expanded(flex: 2, child: validUntilWidget),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 16),

                            // Status Toggle Card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: isActive,
                                      activeColor: const Color(0xFF10B981),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (val) => setModalState(() => isActive = val ?? true),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setModalState(() => isActive = !isActive),
                                      child: Text(
                                        isRtl
                                            ? 'تفعيل كود الخصم وإتاحته للمستخدمين'
                                            : 'Coupon Active & Usable',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Dialog Footer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(isRtl ? 'إلغاء' : 'Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      final code = codeCtrl.text.trim().toUpperCase();
                                      if (code.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isRtl
                                                  ? 'يرجى إدخال كود الخصم'
                                                  : 'Valid coupon code is required',
                                            ),
                                            backgroundColor: const Color(0xFFEF4444),
                                          ),
                                        );
                                        return;
                                      }

                                      if (selectedStoreId == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isRtl ? 'يرجى اختيار المتجر' : 'Store is required',
                                            ),
                                            backgroundColor: const Color(0xFFEF4444),
                                          ),
                                        );
                                        return;
                                      }

                                      final dVal = double.tryParse(discountValCtrl.text.trim()) ?? 10.0;
                                      final minCart = double.tryParse(minCartCtrl.text.trim());
                                      final maxUses = int.tryParse(maxUsesCtrl.text.trim());
                                      final fromDate = validFromCtrl.text.trim();
                                      final untilDate = validUntilCtrl.text.trim();

                                      if (fromDate.isEmpty || untilDate.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isRtl ? 'يرجى تحديد فترة الصلاحية' : 'Validity dates are required',
                                            ),
                                            backgroundColor: const Color(0xFFEF4444),
                                          ),
                                        );
                                        return;
                                      }

                                      setModalState(() => isSaving = true);

                                      try {
                                        if (isEditing) {
                                          await ref.read(couponRepositoryProvider.notifier).updateCoupon(
                                                coupon.id,
                                                code,
                                                discountType,
                                                dVal,
                                                minCart,
                                                fromDate,
                                                untilDate,
                                                isActive ? 1 : 0,
                                                offerId: selectedOfferId,
                                                storeId: selectedStoreId,
                                                productId: selectedProduct?.id,
                                                maxUses: maxUses,
                                              );
                                        } else {
                                          await ref.read(couponRepositoryProvider.notifier).createCoupon(
                                                code,
                                                discountType,
                                                dVal,
                                                minCart,
                                                fromDate,
                                                untilDate,
                                                isActive ? 1 : 0,
                                                offerId: selectedOfferId,
                                                storeId: selectedStoreId,
                                                productId: selectedProduct?.id,
                                                maxUses: maxUses,
                                              );
                                        }

                                        if (dialogCtx.mounted) {
                                          Navigator.pop(dialogCtx);
                                        }

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isEditing
                                                    ? (isRtl
                                                        ? 'تم تحديث كود الخصم بنجاح.'
                                                        : 'Coupon code updated successfully.')
                                                    : (isRtl
                                                        ? 'تم إنشاء كود الخصم بنجاح.'
                                                        : 'Coupon code created successfully.'),
                                              ),
                                              backgroundColor: const Color(0xFF10B981),
                                            ),
                                          );
                                        }

                                        ref.read(couponRepositoryProvider.notifier).fetchCoupons();
                                      } catch (e) {
                                        setModalState(() => isSaving = false);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isRtl
                                                    ? 'فشل حفظ كود الخصم: $e'
                                                : 'Failed to save coupon code: $e',
                                              ),
                                              backgroundColor: const Color(0xFFEF4444),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save, size: 18),
                              label: Text(
                                isEditing
                                    ? (isRtl ? 'حفظ التعديلات' : 'Save Changes')
                                    : (isRtl ? 'إنشاء الكوبون' : 'Create Coupon'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
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
        },
      ),
    );
  }

  void _confirmDeleteCoupon(BuildContext context, bool isRtl, bool isDark, CouponCode coupon) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                isRtl ? 'هل أنت متأكد؟' : 'Are you sure?',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Text(
            isRtl
                ? 'هل تريد حذف كود الخصم "${coupon.code}" نهائياً؟'
                : 'Do you want to permanently delete coupon "${coupon.code}"?',
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                isRtl ? 'إلغاء' : 'Cancel',
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(couponRepositoryProvider.notifier).deleteCoupon(coupon.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isRtl ? 'تم حذف كود الخصم بنجاح.' : 'Coupon code deleted successfully.',
                        ),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isRtl ? 'فشل حذف كود الخصم: $e' : 'Failed to delete coupon: $e',
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(isRtl ? 'نعم، احذف!' : 'Yes, delete it!'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
      ),
    );
  }

  InputDecoration _buildInputDecoration(bool isDark, {String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
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
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final allCoupons = ref.watch(couponRepositoryProvider);
    final stores = ref.watch(storeRepositoryProvider).stores;
    final filteredCoupons = _getFilteredCoupons(allCoupons);

    final storeFilterOptions = [
      CustomSelectOption<int?>(
        value: null,
        labelEn: 'All Partner Stores',
        labelAr: 'جميع المتاجر',
      ),
      ...stores.map((s) => CustomSelectOption<int?>(
            value: s.id,
            labelEn: s.nameEn,
            labelAr: s.nameAr,
            imageUrl: s.logoUrl,
          )),
    ];

    final discountTypeFilterOptions = [
      const CustomSelectOption<String>(
        value: '',
        labelEn: 'All Discount Types',
        labelAr: 'جميع أنواع الخصم',
      ),
      const CustomSelectOption<String>(
        value: 'PERCENT',
        labelEn: 'Percentage (%)',
        labelAr: 'نسبة مئوية (%)',
      ),
      const CustomSelectOption<String>(
        value: 'FIXED_SAR',
        labelEn: 'Fixed Amount (SAR)',
        labelAr: 'مبلغ ثابت (ر.س)',
      ),
    ];

    final statusFilterOptions = [
      const CustomSelectOption<String>(
        value: 'all',
        labelEn: 'All Statuses',
        labelAr: 'جميع الحالات',
      ),
      const CustomSelectOption<String>(
        value: 'active',
        labelEn: 'Active',
        labelAr: 'نشط',
      ),
      const CustomSelectOption<String>(
        value: 'inactive',
        labelEn: 'Inactive',
        labelAr: 'معطل',
      ),
    ];

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
        body: RefreshIndicator(
          color: const Color(0xFF10B981),
          onRefresh: _loadData,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Block
                    _buildHeader(context, isRtl, isDark),
                    const SizedBox(height: 16),

                    // Filters Toolbar
                    _buildFiltersToolbar(
                      context,
                      isRtl,
                      isDark,
                      storeFilterOptions,
                      discountTypeFilterOptions,
                      statusFilterOptions,
                    ),
                    const SizedBox(height: 16),

                    // Content Area: Loading / Empty / Data Views
                    if (_isLoading && allCoupons.isEmpty) ...[
                      CrudLoadingWidget(
                        titleEn: 'Loading Promo Coupons...',
                        titleAr: 'جاري تحميل كوبونات الخصم...',
                        isRtl: isRtl,
                        isDark: isDark,
                      ),
                    ] else if (filteredCoupons.isEmpty) ...[
                      _buildEmptyState(isRtl, isDark),
                    ] else ...[
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 960) {
                            return _buildDesktopTable(context, filteredCoupons, isRtl, isDark);
                          } else {
                            return _buildMobileCardList(context, filteredCoupons, isRtl, isDark);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isRtl, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final titleCol = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRtl ? 'إدارة كوبونات وقسائم الخصم' : 'Manage Promo Coupons',
                    style: TextStyle(
                      fontSize: isMobile ? 17 : 21,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isRtl
                        ? 'إنشاء وتعديل أكواد الخصم الترويجية وضبط حدود الاستخدام والحد الأدنى للطلب'
                        : 'Create discount coupon codes, usage limits, and minimum cart thresholds',
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

        final addBtn = ElevatedButton.icon(
          onPressed: () => _showAddEditCouponModal(context, isRtl, isDark),
          icon: const Icon(Icons.add, size: 18),
          label: Text(isRtl ? 'إضافة كوبون جديد' : 'Add Coupon'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleCol,
              const SizedBox(height: 12),
              addBtn,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleCol),
            const SizedBox(width: 16),
            addBtn,
          ],
        );
      },
    );
  }

  Widget _buildFiltersToolbar(
    BuildContext context,
    bool isRtl,
    bool isDark,
    List<CustomSelectOption<int?>> storeOptions,
    List<CustomSelectOption<String>> discountOptions,
    List<CustomSelectOption<String>> statusOptions,
  ) {
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 850;
          final isMobile = constraints.maxWidth < 560;

          final searchWidget = TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: isRtl
                  ? 'ابحث بكود الخصم، المتجر، أو العرض...'
                  : 'Search coupon code, store, or offer...',
              hintStyle: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 19,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(50),
                borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          );

          final storeSelect = AppCustomSelect<int?>(
            options: storeOptions,
            selectedValue: _selectedStoreFilter,
            placeholder: isRtl ? 'جميع المتاجر' : 'All Partner Stores',
            clearable: true,
            onChanged: (val) {
              setState(() {
                _selectedStoreFilter = val;
              });
            },
          );

          final discountSelect = AppCustomSelect<String>(
            options: discountOptions,
            selectedValue: _selectedDiscountTypeFilter,
            placeholder: isRtl ? 'جميع أنواع الخصم' : 'All Discount Types',
            clearable: false,
            onChanged: (val) {
              setState(() {
                _selectedDiscountTypeFilter = val ?? '';
              });
            },
          );

          final statusSelect = AppCustomSelect<String>(
            options: statusOptions,
            selectedValue: _selectedStatusFilter,
            placeholder: isRtl ? 'جميع الحالات' : 'All Statuses',
            clearable: false,
            onChanged: (val) {
              setState(() {
                _selectedStatusFilter = val ?? 'all';
              });
            },
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchWidget,
                const SizedBox(height: 10),
                storeSelect,
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: discountSelect),
                    const SizedBox(width: 8),
                    Expanded(child: statusSelect),
                  ],
                ),
              ],
            );
          }

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchWidget,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(flex: 3, child: storeSelect),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: discountSelect),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: statusSelect),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchWidget),
              const SizedBox(width: 12),
              SizedBox(width: 180, child: storeSelect),
              const SizedBox(width: 8),
              SizedBox(width: 165, child: discountSelect),
              const SizedBox(width: 8),
              SizedBox(width: 140, child: statusSelect),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopTable(
    BuildContext context,
    List<CouponCode> coupons,
    bool isRtl,
    bool isDark,
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1050),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              ),
              dataRowMinHeight: 64,
              dataRowMaxHeight: 74,
              horizontalMargin: 20,
              columnSpacing: 18,
              columns: [
                const DataColumn(
                  label: Text('ID', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                DataColumn(
                  label: Text(
                    isRtl ? 'كود الخصم' : 'Coupon Code',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                DataColumn(
                  label: Text(
                    isRtl ? 'المتجر الشريك' : 'Retail Partner',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                DataColumn(
                  label: Text(
                    isRtl ? 'العرض / المنتج المرتبط' : 'Linked Offer / Item',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                DataColumn(
                  label: Text(
                    isRtl ? 'قيمة الخصم' : 'Discount Value',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                DataColumn(
                  label: Text(
                    isRtl ? 'الحد الأدنى' : 'Min Cart',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                DataColumn(
                  label: Text(
                    isRtl ? 'إحصائيات الاستخدام' : 'Usage Stats',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                DataColumn(
                  label: Text(
                    isRtl ? 'الصلاحية' : 'Validity',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                DataColumn(
                  label: Text(
                    isRtl ? 'الحالة' : 'Status',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                DataColumn(
                  label: Text(
                    isRtl ? 'الإجراءات' : 'Actions',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
              rows: coupons.map((c) {
                final isCopied = _copiedCouponId == c.id;
                final isPercent = c.discountType == 'PERCENT' || c.discountType == 'PERCENTAGE';
                final hasOffer = (c.offerTitleEn != null && c.offerTitleEn!.isNotEmpty) || (c.offer?.titleEn.isNotEmpty ?? false);
                final hasProduct = (c.productNameEn != null && c.productNameEn!.isNotEmpty) || (c.product?.nameEn.isNotEmpty ?? false);

                final offerTitle = isRtl
                    ? (c.offerTitleAr ?? c.offer?.titleAr ?? c.offerTitleEn ?? c.offer?.titleEn ?? '')
                    : (c.offerTitleEn ?? c.offer?.titleEn ?? '');
                final productTitle = isRtl
                    ? (c.productNameAr ?? c.product?.nameAr ?? c.productNameEn ?? c.product?.nameEn ?? '')
                    : (c.productNameEn ?? c.product?.nameEn ?? '');

                final storeName = isRtl
                    ? (c.storeNameAr ?? c.store?.nameAr ?? c.storeNameEn ?? c.store?.nameEn ?? 'متجر #${c.storeId}')
                    : (c.storeNameEn ?? c.store?.nameEn ?? 'Store #${c.storeId}');

                final maxU = c.maxUses ?? 0;
                final used = c.usedCount;
                final progress = maxU > 0 ? (used / maxU).clamp(0.0, 1.0) : 0.0;

                return DataRow(
                  cells: [
                    // ID
                    DataCell(
                      Text(
                        '#${c.id}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),

                    // Coupon Code Badge
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              c.code,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: Color(0xFF10B981),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _copyCouponCode(c.code, c.id, isRtl),
                              child: Icon(
                                isCopied ? Icons.check : Icons.content_copy,
                                size: 15,
                                color: isCopied ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Store Name
                    DataCell(
                      Text(
                        storeName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    // Linked Offer / Product
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasOffer)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_offer, size: 13, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  offerTitle,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          if (hasProduct)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shopping_bag, size: 13, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Text(
                                  productTitle,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          if (!hasOffer && !hasProduct)
                            Text(
                              isRtl ? 'شامل لجميع منتجات المتجر' : 'Store-wide promotion',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Discount Value
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPercent
                                ? '${c.discountValue.toStringAsFixed(c.discountValue.truncateToDouble() == c.discountValue ? 0 : 1)}%'
                                : '${c.discountValue.toStringAsFixed(c.discountValue.truncateToDouble() == c.discountValue ? 0 : 1)} SAR',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            isPercent ? 'PERCENT' : 'FIXED_SAR',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Min Cart
                    DataCell(
                      Text(
                        (c.minCartValue != null && c.minCartValue! > 0)
                            ? '${c.minCartValue!.toStringAsFixed(c.minCartValue!.truncateToDouble() == c.minCartValue ? 0 : 1)} SAR'
                            : (isRtl ? 'بدون حد' : 'No min.'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ),

                    // Usage Stats
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${c.usedCount} / ${c.maxUses != null ? c.maxUses.toString() : "∞"}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            if (c.maxUses != null && c.maxUses! > 0)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                  minHeight: 4,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Validity
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${isRtl ? "من:" : "From:"} ${c.validFrom}',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          Text(
                            '${isRtl ? "إلى:" : "Until:"} ${c.validUntil}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: c.active
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFF64748B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.active ? (isRtl ? 'نشط' : 'Active') : (isRtl ? 'معطل' : 'Inactive'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: c.active ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),

                    // Actions
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            tooltip: isRtl ? 'تعديل الكوبون' : 'Edit Coupon',
                            onPressed: () => _showAddEditCouponModal(context, isRtl, isDark, c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            color: const Color(0xFFEF4444),
                            tooltip: isRtl ? 'حذف الكوبون' : 'Delete Coupon',
                            onPressed: () => _confirmDeleteCoupon(context, isRtl, isDark, c),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCardList(
    BuildContext context,
    List<CouponCode> coupons,
    bool isRtl,
    bool isDark,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: coupons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = coupons[index];
        final isCopied = _copiedCouponId == c.id;
        final isPercent = c.discountType == 'PERCENT' || c.discountType == 'PERCENTAGE';
        final storeName = isRtl
            ? (c.storeNameAr ?? c.store?.nameAr ?? c.storeNameEn ?? c.store?.nameEn ?? 'متجر #${c.storeId}')
            : (c.storeNameEn ?? c.store?.nameEn ?? 'Store #${c.storeId}');

        final maxU = c.maxUses ?? 0;
        final used = c.usedCount;
        final progress = maxU > 0 ? (used / maxU).clamp(0.0, 1.0) : 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Code Badge, Status, and Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c.code,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _copyCouponCode(c.code, c.id, isRtl),
                          child: Icon(
                            isCopied ? Icons.check : Icons.content_copy,
                            size: 15,
                            color: isCopied ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: c.active
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFF64748B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.active ? (isRtl ? 'نشط' : 'Active') : (isRtl ? 'معطل' : 'Inactive'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: c.active ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => _showAddEditCouponModal(context, isRtl, isDark, c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                        onPressed: () => _confirmDeleteCoupon(context, isRtl, isDark, c),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (c.minCartValue != null && c.minCartValue! > 0)
                            ? '${isRtl ? "الحد الأدنى:" : "Min:"} ${c.minCartValue} SAR'
                            : (isRtl ? 'بدون حد أدنى' : 'No min. cart'),
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isPercent ? '${c.discountValue}%' : '${c.discountValue} SAR',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        isPercent ? 'PERCENT' : 'FIXED_SAR',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Usage and validity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isRtl ? "الاستخدام:" : "Usage:"} ${c.usedCount} / ${c.maxUses != null ? c.maxUses.toString() : "∞"}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                        if (c.maxUses != null && c.maxUses! > 0) ...[
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            minHeight: 4,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${c.validFrom} → ${c.validUntil}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isRtl, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 54,
              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              isRtl ? 'لا توجد كوبونات خصم مسجلة' : 'No coupon codes created',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                isRtl
                    ? 'انقر على "إضافة كوبون جديد" لإنشاء أول كود خصم ترويجي في النظام.'
                    : 'Click "Add Coupon" to create your first voucher discount code.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _showAddEditCouponModal(context, isRtl, isDark),
              icon: const Icon(Icons.add, size: 16),
              label: Text(isRtl ? 'إضافة كوبون جديد' : 'Add Coupon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
