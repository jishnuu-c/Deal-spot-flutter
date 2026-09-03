import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/services/category_repository.dart';
import '../../../core/services/store_repository.dart';
import '../../../core/services/brand_repository.dart';
import '../../../core/services/offer_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

class OfferListScreen extends ConsumerStatefulWidget {
  final int? categoryIdFilter;

  const OfferListScreen({super.key, this.categoryIdFilter});

  @override
  ConsumerState<OfferListScreen> createState() => _OfferListScreenState();
}

class _OfferListScreenState extends ConsumerState<OfferListScreen> {
  int? _selectedCityId;
  int? _selectedMainCategoryId;
  int? _selectedSubCategoryId;
  int? _selectedStoreId;
  int? _selectedBrandId;
  String? _selectedBrandName;
  double _minDiscount = 0.0;
  bool _showFlashOnly = false;
  bool _showFeaturedOnly = false;
  bool _onlySaved = false;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMainCategoryId = widget.categoryIdFilter;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters['category'] != null) {
      _selectedMainCategoryId = int.tryParse(uri.queryParameters['category']!);
    }
    if (uri.queryParameters['categoryId'] != null) {
      _selectedMainCategoryId = int.tryParse(uri.queryParameters['categoryId']!);
    }
    if (uri.queryParameters['store'] != null) {
      _selectedStoreId = int.tryParse(uri.queryParameters['store']!);
    }
    if (uri.queryParameters['brandId'] != null) {
      _selectedBrandId = int.tryParse(uri.queryParameters['brandId']!);
    }
    if (uri.queryParameters['flash'] == 'true') {
      _showFlashOnly = true;
    }
    if (uri.queryParameters['featured'] == 'true') {
      _showFeaturedOnly = true;
    }
    if (uri.queryParameters['search'] != null) {
      _searchQuery = uri.queryParameters['search']!;
      _searchController.text = _searchQuery;
    }
    if (uri.queryParameters['q'] != null) {
      _searchQuery = uri.queryParameters['q']!;
      _searchController.text = _searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedCityId = null;
      _selectedMainCategoryId = null;
      _selectedSubCategoryId = null;
      _selectedStoreId = null;
      _selectedBrandId = null;
      _selectedBrandName = null;
      _minDiscount = 0.0;
      _showFlashOnly = false;
      _showFeaturedOnly = false;
      _onlySaved = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _openFilterBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = ref.read(localizationsProvider);
    final isRtl = ref.read(translationProvider) == AppLanguage.ar;

    final cities = ref.read(cityRepositoryProvider).cities;
    final allCategories = ref.read(categoryRepositoryProvider);
    final mainCats = allCategories.where((c) => c.parentId == null).toList();
    final stores = ref.read(storeRepositoryProvider).stores;
    final brands = ref.read(brandRepositoryProvider).brands;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableSubCats = _selectedMainCategoryId != null
                ? allCategories.where((c) => c.parentId == _selectedMainCategoryId).toList()
                : <Category>[];

            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.filter_alt, color: Color(0xFF16A34A), size: 22),
                            const SizedBox(width: 8),
                            Text(
                              tr.get('filter_offers'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                _resetFilters();
                                setModalState(() {});
                              },
                              child: Text(
                                tr.get('reset'),
                                style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),

                    // Body
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          // 1. City Filter
                          Text(tr.get('filter_by_city'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int?>(
                            value: _selectedCityId,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                            ),
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(tr.get('all_cities')),
                              ),
                              ...cities.map((c) => DropdownMenuItem<int?>(
                                    value: c.id,
                                    child: Text(isRtl ? c.nameAr : c.nameEn),
                                  )),
                            ],
                            onChanged: (val) {
                              setModalState(() => _selectedCityId = val);
                              setState(() => _selectedCityId = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // 2. Main Category Filter
                          Text(tr.get('main_category'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int?>(
                            value: _selectedMainCategoryId,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                            ),
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(tr.get('all_main_categories')),
                              ),
                              ...mainCats.map((c) => DropdownMenuItem<int?>(
                                    value: c.id,
                                    child: Text(isRtl ? c.nameAr : c.nameEn),
                                  )),
                            ],
                            onChanged: (val) {
                              setModalState(() {
                                _selectedMainCategoryId = val;
                                _selectedSubCategoryId = null;
                              });
                              setState(() {
                                _selectedMainCategoryId = val;
                                _selectedSubCategoryId = null;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // 3. Subcategories (if selected main category has children)
                          if (availableSubCats.isNotEmpty) ...[
                            Text(tr.get('subcategory'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text(tr.get('all')),
                                  selected: _selectedSubCategoryId == null,
                                  onSelected: (_) {
                                    setModalState(() => _selectedSubCategoryId = null);
                                    setState(() => _selectedSubCategoryId = null);
                                  },
                                ),
                                ...availableSubCats.map((sub) {
                                  final isSel = _selectedSubCategoryId == sub.id;
                                  return ChoiceChip(
                                    label: Text(isRtl ? sub.nameAr : sub.nameEn),
                                    selected: isSel,
                                    selectedColor: const Color(0xFF16A34A),
                                    labelStyle: TextStyle(
                                      color: isSel ? Colors.white : null,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (_) {
                                      setModalState(() => _selectedSubCategoryId = sub.id);
                                      setState(() => _selectedSubCategoryId = sub.id);
                                    },
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 4. Retail Store
                          Text(tr.get('retail_store'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int?>(
                            value: _selectedStoreId,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                            ),
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(tr.get('all_stores')),
                              ),
                              ...stores.map((s) => DropdownMenuItem<int?>(
                                    value: s.id,
                                    child: Text(isRtl ? s.nameAr : s.nameEn),
                                  )),
                            ],
                            onChanged: (val) {
                              setModalState(() => _selectedStoreId = val);
                              setState(() => _selectedStoreId = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // 5. Brand Filter
                          Text(tr.get('brand'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int?>(
                            value: _selectedBrandId,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                            ),
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(tr.get('all_brands')),
                              ),
                              ...brands.map((b) => DropdownMenuItem<int?>(
                                    value: b.id,
                                    child: Text(isRtl ? b.nameAr : b.nameEn),
                                  )),
                            ],
                            onChanged: (val) {
                              setModalState(() => _selectedBrandId = val);
                              setState(() => _selectedBrandId = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // 6. Minimum Discount Slider
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(tr.get('min_discount'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(
                                '${_minDiscount.toInt()}%',
                                style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                            ],
                          ),
                          Slider(
                            value: _minDiscount,
                            min: 0,
                            max: 70,
                            divisions: 14,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (val) {
                              setModalState(() => _minDiscount = val);
                              setState(() => _minDiscount = val);
                            },
                          ),
                          const SizedBox(height: 12),

                          // 7. Deal Type Toggles
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(tr.get('saved_offers_only'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            value: _onlySaved,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (v) {
                              setModalState(() => _onlySaved = v ?? false);
                              setState(() => _onlySaved = v ?? false);
                            },
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(tr.get('flash_deals_only'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            value: _showFlashOnly,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (v) {
                              setModalState(() => _showFlashOnly = v ?? false);
                              setState(() => _showFlashOnly = v ?? false);
                            },
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(tr.get('featured_only'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            value: _showFeaturedOnly,
                            activeColor: const Color(0xFF16A34A),
                            onChanged: (v) {
                              setModalState(() => _showFeaturedOnly = v ?? false);
                              setState(() => _showFeaturedOnly = v ?? false);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
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
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final globalCityId = ref.watch(cityRepositoryProvider).selectedCity?.id;
    final activeCityId = _selectedCityId ?? globalCityId;

    final allCategories = ref.watch(categoryRepositoryProvider);
    final stores = ref.watch(storeRepositoryProvider).stores;
    final brands = ref.watch(brandRepositoryProvider).brands;

    // Filter offers
    final offers = ref.watch(offerRepositoryProvider.notifier).getOffers(
      OfferFilters(
        cityId: activeCityId,
        mainCategoryId: _selectedMainCategoryId,
        subCategoryId: _selectedSubCategoryId,
        storeId: _selectedStoreId,
        brandId: _selectedBrandId,
        brandName: _selectedBrandName,
        minDiscount: _minDiscount > 0 ? _minDiscount : null,
        isFlash: _showFlashOnly ? true : null,
        isFeatured: _showFeaturedOnly ? true : null,
        onlySaved: _onlySaved ? true : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      ),
    );

    final hasActiveFilters = _selectedMainCategoryId != null ||
        _selectedSubCategoryId != null ||
        _selectedStoreId != null ||
        _selectedBrandId != null ||
        _minDiscount > 0 ||
        _showFlashOnly ||
        _showFeaturedOnly ||
        _onlySaved ||
        _searchQuery.isNotEmpty;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.get('offers'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          actions: [
            // Filter trigger button with active indicator
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _openFilterBottomSheet(context),
                ),
                if (hasActiveFilters)
                  Positioned(
                    top: 10,
                    right: isRtl ? null : 10,
                    left: isRtl ? 10 : null,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Active filters & results bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_offer, color: Color(0xFF16A34A), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${tr.get('found')} ${offers.length} ${tr.get('promotional_offers')}',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      if (hasActiveFilters)
                        InkWell(
                          onTap: _resetFilters,
                          child: Text(
                            tr.get('clear_all'),
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),

                  // Active Filter Badges Strip
                  if (hasActiveFilters) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedMainCategoryId != null) ...[
                            _buildActiveChip(
                              label: isRtl
                                  ? (allCategories.where((c) => c.id == _selectedMainCategoryId).firstOrNull?.nameAr ?? '')
                                  : (allCategories.where((c) => c.id == _selectedMainCategoryId).firstOrNull?.nameEn ?? ''),
                              onRemove: () => setState(() => _selectedMainCategoryId = null),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_selectedSubCategoryId != null) ...[
                            _buildActiveChip(
                              label: isRtl
                                  ? (allCategories.where((c) => c.id == _selectedSubCategoryId).firstOrNull?.nameAr ?? '')
                                  : (allCategories.where((c) => c.id == _selectedSubCategoryId).firstOrNull?.nameEn ?? ''),
                              onRemove: () => setState(() => _selectedSubCategoryId = null),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_selectedStoreId != null) ...[
                            _buildActiveChip(
                              label: isRtl
                                  ? (stores.where((s) => s.id == _selectedStoreId).firstOrNull?.nameAr ?? '')
                                  : (stores.where((s) => s.id == _selectedStoreId).firstOrNull?.nameEn ?? ''),
                              onRemove: () => setState(() => _selectedStoreId = null),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_selectedBrandId != null) ...[
                            _buildActiveChip(
                              label: isRtl
                                  ? (brands.where((b) => b.id == _selectedBrandId).firstOrNull?.nameAr ?? '')
                                  : (brands.where((b) => b.id == _selectedBrandId).firstOrNull?.nameEn ?? ''),
                              onRemove: () => setState(() => _selectedBrandId = null),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_minDiscount > 0) ...[
                            _buildActiveChip(
                              label: '≥ ${_minDiscount.toInt()}% Off',
                              onRemove: () => setState(() => _minDiscount = 0),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_showFlashOnly) ...[
                            _buildActiveChip(
                              label: tr.get('flash_deals_only'),
                              onRemove: () => setState(() => _showFlashOnly = false),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_showFeaturedOnly) ...[
                            _buildActiveChip(
                              label: tr.get('featured_only'),
                              onRemove: () => setState(() => _showFeaturedOnly = false),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (_onlySaved) ...[
                            _buildActiveChip(
                              label: tr.get('saved_offers_only'),
                              onRemove: () => setState(() => _onlySaved = false),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Offers Grid or Empty State
            Expanded(
              child: offers.isNotEmpty
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.58,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: offers.length,
                      itemBuilder: (context, index) {
                        final offer = offers[index];
                        return _buildOfferGridCard(context, offer, isRtl, isDark, tr);
                      },
                    )
                  : _buildEmptyState(isDark, tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChip({required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 13, color: Color(0xFF16A34A)),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferGridCard(
    BuildContext context,
    Offer offer,
    bool isRtl,
    bool isDark,
    AppLocalizations tr,
  ) {
    final isSaved = offer.isSaved == true;
    final storeName = isRtl ? (offer.store?.nameAr ?? '') : (offer.store?.nameEn ?? '');
    final offerTitle = isRtl ? offer.titleAr : offer.titleEn;
    final productName = offer.product != null ? (isRtl ? offer.product!.nameAr : offer.product!.nameEn) : null;
    final primaryImg = (offer.images != null && offer.images!.isNotEmpty)
        ? offer.images!.first.imageUrl
        : offer.product?.primaryImageUrl;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go('/offers/${offer.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image container with discount, badges & actions
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.35,
                    child: Container(
                      color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                      child: primaryImg != null
                          ? CachedNetworkImage(
                              imageUrl: AppConfig.normalizeImageUrl(primaryImg),
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                            )
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),

                  // Discount badge
                  if (offer.discountPct > 0)
                    Positioned(
                      top: 8,
                      left: isRtl ? null : 8,
                      right: isRtl ? 8 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '-${offer.discountPct.toInt()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),

                  // Badges top right
                  Positioned(
                    top: 6,
                    right: isRtl ? null : 6,
                    left: isRtl ? 6 : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (offer.isFlash == 1)
                          Container(
                            padding: const EdgeInsets.all(4),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.bolt, color: Colors.white, size: 13),
                          ),
                        if (offer.isFeatured == 1)
                          Container(
                            padding: const EdgeInsets.all(4),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.star, color: Colors.white, size: 13),
                          ),

                        // Bookmark
                        InkWell(
                          onTap: () {
                            ref.read(offerRepositoryProvider.notifier).toggleSaveOffer(offer.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                            ),
                            child: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: isSaved ? const Color(0xFF16A34A) : Colors.black54,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Body content
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store badge
                    if (storeName.isNotEmpty)
                      Row(
                        children: [
                          if (offer.store?.logoUrl != null && offer.store!.logoUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: CachedNetworkImage(
                                imageUrl: AppConfig.normalizeImageUrl(offer.store!.logoUrl!),
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
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                          if (offer.store?.isVerified == 1)
                            const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 13),
                        ],
                      ),
                    const SizedBox(height: 4),

                    // Title
                    Text(
                      offerTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.2),
                    ),
                    const SizedBox(height: 4),

                    // Product Box
                    if (productName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2, size: 11, color: Color(0xFF16A34A)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),

                    // Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${offer.offerPrice.toStringAsFixed(0)} ${tr.get('sar')}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                        ),
                        if (offer.originalPrice > offer.offerPrice) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${offer.originalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Valid until
                    if (offer.validUntil.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 11, color: isDark ? Colors.white38 : Colors.black38),
                          const SizedBox(width: 3),
                          Text(
                            '${tr.get('until')} ${offer.validUntil}',
                            style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white38 : Colors.black38),
                          ),
                        ],
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
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations tr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off_outlined, size: 56, color: Colors.grey.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              tr.get('no_offers_match'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              tr.get('no_offers_match_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(tr.get('reset_all_filters')),
            ),
          ],
        ),
      ),
    );
  }
}
