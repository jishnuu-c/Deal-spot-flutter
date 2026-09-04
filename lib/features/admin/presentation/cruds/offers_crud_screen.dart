import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/offer_repository.dart';
import '../../../../core/services/store_repository.dart';
import '../../../../core/services/product_repository.dart';
import '../../../../core/services/city_repository.dart';
import '../../../../core/services/category_repository.dart';
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

  String _searchQuery = '';
  int? _selectedStoreFilter;
  String? _selectedBadgeFilter;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storeRepositoryProvider.notifier).fetchStores();
      ref.read(cityRepositoryProvider.notifier).fetchCities();
      ref.read(categoryRepositoryProvider.notifier).fetchCategories();
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
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      _loadNextPage();
    }
  }

  Future<void> _loadInitialOffers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });

    final res = await ref.read(offerRepositoryProvider.notifier).getPagedOffers(
      page: 0,
      size: _pageSize,
      search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      storeId: _selectedStoreFilter,
      badgeType: _selectedBadgeFilter,
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
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;

    final nextPage = _currentPage + 1;
    setState(() => _isLoadingMore = true);

    final res = await ref.read(offerRepositoryProvider.notifier).getPagedOffers(
      page: nextPage,
      size: _pageSize,
      search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      storeId: _selectedStoreFilter,
      badgeType: _selectedBadgeFilter,
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

  void _showForm(BuildContext context, [Offer? offer]) {
    final titleEnCtrl = TextEditingController(text: offer?.titleEn);
    final titleArCtrl = TextEditingController(text: offer?.titleAr);
    final origPriceCtrl = TextEditingController(text: offer?.originalPrice.toString() ?? '10.0');
    final offerPriceCtrl = TextEditingController(text: offer?.offerPrice.toString() ?? '5.0');
    final badgeCtrl = TextEditingController(text: offer?.badgeType ?? 'NONE');
    final fromCtrl = TextEditingController(text: offer?.validFrom ?? '2026-07-01');
    final untilCtrl = TextEditingController(text: offer?.validUntil ?? '2026-07-31');

    final stores = ref.read(storeRepositoryProvider).stores;
    final cities = ref.read(cityRepositoryProvider).cities;
    final categories = ref.read(categoryRepositoryProvider);

    int? selectedStoreId = offer?.storeId ?? (stores.isNotEmpty ? stores[0].id : null);
    int? selectedProductId = offer?.productId;
    int? selectedCityId = offer?.cityId ?? (cities.isNotEmpty ? cities[0].id : null);
    int? selectedCategoryId = offer?.categoryId ?? (categories.isNotEmpty ? categories[0].id : null);

    bool isFeatured = offer == null ? false : offer.isFeatured == 1;
    bool isFlash = offer == null ? false : offer.isFlash == 1;
    bool isActive = offer == null ? true : offer.isActive == 1;

    // Product on-demand search inside dialog
    List<Product> searchedProducts = [];
    bool isSearchingProducts = false;
    Timer? prodDebounce;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void searchProducts(String q) {
              prodDebounce?.cancel();
              prodDebounce = Timer(const Duration(milliseconds: 250), () async {
                if (q.trim().isEmpty) {
                  setDialogState(() {
                    searchedProducts = [];
                    isSearchingProducts = false;
                  });
                  return;
                }
                setDialogState(() => isSearchingProducts = true);
                final pRes = await ref.read(productRepositoryProvider.notifier).getPagedProducts(
                  page: 0,
                  size: 10,
                  search: q.trim(),
                );
                setDialogState(() {
                  searchedProducts = pRes.content;
                  isSearchingProducts = false;
                });
              });
            }

            return AlertDialog(
              title: Text(offer == null ? 'Add Offer' : 'Edit Offer'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: titleEnCtrl, decoration: const InputDecoration(labelText: 'Title (EN)')),
                      const SizedBox(height: 8),
                      TextField(controller: titleArCtrl, decoration: const InputDecoration(labelText: 'Title (AR)')),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: origPriceCtrl, decoration: const InputDecoration(labelText: 'Original Price'), keyboardType: TextInputType.number)),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: offerPriceCtrl, decoration: const InputDecoration(labelText: 'Offer Price'), keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(controller: badgeCtrl, decoration: const InputDecoration(labelText: 'Badge Type (e.g. FLASH, BOGO, FEATURED)')),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: 'Valid From'))),
                          const SizedBox(width: 8),
                          Expanded(child: TextField(controller: untilCtrl, decoration: const InputDecoration(labelText: 'Valid Until'))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedStoreId,
                        decoration: const InputDecoration(labelText: 'Store'),
                        items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nameEn))).toList(),
                        onChanged: (val) => setDialogState(() => selectedStoreId = val),
                      ),
                      const SizedBox(height: 8),
                      // Product On-Demand Search
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Search Product (Optional)',
                          hintText: 'Type product name or SKU...',
                          suffixIcon: isSearchingProducts ? const SizedBox(width: 16, height: 16, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) : null,
                        ),
                        onChanged: searchProducts,
                      ),
                      if (searchedProducts.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: searchedProducts.length,
                            itemBuilder: (ctx, i) {
                              final p = searchedProducts[i];
                              final isSelected = selectedProductId == p.id;
                              return ListTile(
                                dense: true,
                                title: Text(p.nameEn),
                                subtitle: Text('SKU: ${p.sku}'),
                                trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                                onTap: () {
                                  setDialogState(() => selectedProductId = isSelected ? null : p.id);
                                },
                              );
                            },
                          ),
                        ),
                      if (selectedProductId != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text('Selected Product ID: $selectedProductId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                              const Spacer(),
                              TextButton(onPressed: () => setDialogState(() => selectedProductId = null), child: const Text('Clear', style: TextStyle(fontSize: 12, color: Colors.red))),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedCityId,
                        decoration: const InputDecoration(labelText: 'City'),
                        items: cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameEn))).toList(),
                        onChanged: (val) => setDialogState(() => selectedCityId = val),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameEn))).toList(),
                        onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Is Featured'),
                        value: isFeatured,
                        onChanged: (val) => setDialogState(() => isFeatured = val ?? false),
                      ),
                      CheckboxListTile(
                        title: const Text('Is Flash Deal'),
                        value: isFlash,
                        onChanged: (val) => setDialogState(() => isFlash = val ?? false),
                      ),
                      CheckboxListTile(
                        title: const Text('Is Active'),
                        value: isActive,
                        onChanged: (val) => setDialogState(() => isActive = val ?? true),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedStoreId == null || selectedCityId == null || selectedCategoryId == null) return;
                    final orig = double.tryParse(origPriceCtrl.text) ?? 10.0;
                    final off = double.tryParse(offerPriceCtrl.text) ?? 5.0;

                    if (offer == null) {
                      await ref.read(offerRepositoryProvider.notifier).createOffer(
                            titleEnCtrl.text,
                            titleArCtrl.text,
                            orig,
                            off,
                            badgeCtrl.text,
                            fromCtrl.text,
                            untilCtrl.text,
                            selectedStoreId!,
                            selectedProductId,
                            selectedCategoryId!,
                            selectedCityId!,
                            isFeatured ? 1 : 0,
                            isFlash ? 1 : 0,
                            isActive ? 1 : 0,
                          );
                    } else {
                      await ref.read(offerRepositoryProvider.notifier).updateOffer(
                            offer.id,
                            titleEnCtrl.text,
                            titleArCtrl.text,
                            orig,
                            off,
                            badgeCtrl.text,
                            fromCtrl.text,
                            untilCtrl.text,
                            selectedStoreId!,
                            selectedProductId,
                            selectedCategoryId!,
                            selectedCityId!,
                            isFeatured ? 1 : 0,
                            isFlash ? 1 : 0,
                            isActive ? 1 : 0,
                          );
                    }
                    if (context.mounted) Navigator.pop(dialogCtx);
                    _loadInitialOffers();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Offers'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Offer'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search offers by title...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _offers.isEmpty
                    ? const Center(child: Text('No offers found'))
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _offers.length + (_isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          if (index >= _offers.length) {
                            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                          }
                          final offer = _offers[index];
                          return ListTile(
                            leading: const Icon(Icons.local_offer, color: Colors.green),
                            title: Text(offer.titleEn),
                            subtitle: Text('Price: ${offer.offerPrice} SAR (Original: ${offer.originalPrice} SAR) | Discount: ${offer.discountPct}% | Store: ${offer.store?.nameEn ?? ""}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade50, foregroundColor: Colors.orange, elevation: 0),
                                  onPressed: () => context.go('/admin/offers/${offer.id}/images'),
                                  icon: const Icon(Icons.photo_library, size: 14),
                                  label: const Text('Images', style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 8),
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showForm(context, offer)),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await ref.read(offerRepositoryProvider.notifier).deleteOffer(offer.id);
                                    _loadInitialOffers();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
