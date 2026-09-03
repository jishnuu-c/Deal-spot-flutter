import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/services/category_repository.dart';
import '../../../core/services/store_repository.dart';
import '../../../core/services/auth_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

class StoreListScreen extends ConsumerStatefulWidget {
  const StoreListScreen({super.key});

  @override
  ConsumerState<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends ConsumerState<StoreListScreen> {
  int? _selectedCategoryId;
  bool _onlyFollowed = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    final categories = ref.watch(categoryRepositoryProvider).where((c) => c.isActive == 1 && c.parentId == null).toList();
    
    final allStores = ref.watch(storeRepositoryProvider.notifier).getStores(
      cityId: cityId,
      categoryId: _selectedCategoryId,
    );

    final followedStoreIds = ref.watch(storeRepositoryProvider).followedStoreIds;

    // Filter by search query & followed
    final stores = allStores.where((s) {
      if (_onlyFollowed && !followedStoreIds.contains(s.id)) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return s.nameEn.toLowerCase().contains(q) || s.nameAr.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isRtl ? 'دليل المتاجر' : 'Store Directory', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: Column(
          children: [
            // Filter Bar (Search + Horizontal Category & Followed Chips)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
              ),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: isRtl ? 'ابحث عن اسم المتجر...' : 'Search store names...',
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
                  const SizedBox(height: 10),

                  // Horizontal Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // All Retailers
                        ChoiceChip(
                          label: Text(isRtl ? 'جميع المتاجر' : 'All Retailers'),
                          selected: !_onlyFollowed && _selectedCategoryId == null,
                          selectedColor: const Color(0xFF16A34A),
                          labelStyle: TextStyle(
                            color: (!_onlyFollowed && _selectedCategoryId == null) ? Colors.white : null,
                            fontWeight: (!_onlyFollowed && _selectedCategoryId == null) ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _onlyFollowed = false;
                              _selectedCategoryId = null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),

                        // Followed Stores Chip
                        ChoiceChip(
                          avatar: Icon(
                            Icons.favorite,
                            size: 16,
                            color: _onlyFollowed ? Colors.white : Colors.redAccent,
                          ),
                          label: Text('${tr.get('followed_stores')} (${followedStoreIds.length})'),
                          selected: _onlyFollowed,
                          selectedColor: Colors.redAccent,
                          labelStyle: TextStyle(
                            color: _onlyFollowed ? Colors.white : null,
                            fontWeight: _onlyFollowed ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _onlyFollowed = true;
                              _selectedCategoryId = null;
                            });
                          },
                        ),
                        const SizedBox(width: 8),

                        // Category Chips
                        ...categories.map((cat) {
                          final isSel = !_onlyFollowed && _selectedCategoryId == cat.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(isRtl ? cat.nameAr : cat.nameEn),
                              selected: isSel,
                              selectedColor: const Color(0xFF16A34A),
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : null,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _onlyFollowed = false;
                                  _selectedCategoryId = cat.id;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Store Grid
            Expanded(
              child: stores.isNotEmpty
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: stores.length,
                      itemBuilder: (context, index) {
                        final store = stores[index];
                        return _buildStoreCard(context, ref, store, isRtl, isDark, tr);
                      },
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.storefront_outlined, size: 56, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              isRtl ? 'لم يتم العثور على متاجر' : 'No stores found',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isRtl ? 'جرب مسح معايير البحث لاستعراض كافة المتاجر.' : 'Try adjusting or clearing your filters to view all retailers.',
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

  Widget _buildStoreCard(
    BuildContext context,
    WidgetRef ref,
    Store store,
    bool isRtl,
    bool isDark,
    AppLocalizations tr,
  ) {
    final storeName = isRtl ? store.nameAr : store.nameEn;
    final catName = isRtl ? (store.category?.nameAr ?? '') : (store.category?.nameEn ?? '');
    final cityName = isRtl ? (store.city?.nameAr ?? '') : (store.city?.nameEn ?? '');
    final isFollowed = ref.watch(storeRepositoryProvider).followedStoreIds.contains(store.id);

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
          onTap: () => context.go('/stores/${store.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Verified badge + Logo Container
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: 90,
                    width: double.infinity,
                    color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                    alignment: Alignment.center,
                    child: store.logoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: AppConfig.normalizeImageUrl(store.logoUrl),
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const Icon(Icons.storefront, size: 36, color: Colors.grey),
                          )
                        : const Icon(Icons.storefront, size: 36, color: Colors.grey),
                  ),

                  // Verified
                  if (store.isVerified == 1)
                    Positioned(
                      top: 8,
                      right: isRtl ? null : 8,
                      left: isRtl ? 8 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 12),
                            const SizedBox(width: 3),
                            Text(
                              isRtl ? 'معتمد' : 'Verified',
                              style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Store Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            storeName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          if (catName.isNotEmpty)
                            Text(
                              catName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? Colors.white60 : const Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(height: 2),
                          if (cityName.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.place, size: 11, color: Colors.grey),
                                const SizedBox(width: 2),
                                Text(
                                  cityName,
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Follow button
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowed ? Colors.redAccent.withOpacity(0.12) : const Color(0xFF16A34A),
                            foregroundColor: isFollowed ? Colors.redAccent : Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: Icon(isFollowed ? Icons.favorite : Icons.favorite_border, size: 14),
                          label: Text(
                            isFollowed ? tr.get('following') : tr.get('follow'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            final isLoggedIn = ref.read(authProvider).isLoggedIn;
                            if (!isLoggedIn) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(tr.get('save_offer_login'))),
                              );
                              return;
                            }
                            ref.read(storeRepositoryProvider.notifier).toggleFollowStore(store.id);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
