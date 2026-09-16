import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/models.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/services/flyer_repository.dart';
import '../../../core/services/offer_repository.dart';
import '../../../core/services/product_repository.dart';
import '../../../core/services/store_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../core/widgets/app_network_image.dart';

class SearchOverlayModal extends ConsumerStatefulWidget {
  final String initialQuery;

  const SearchOverlayModal({
    super.key,
    this.initialQuery = '',
  });

  static Future<void> show(BuildContext context, {String initialQuery = ''}) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SearchOverlayModal(initialQuery: initialQuery),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.05);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  ConsumerState<SearchOverlayModal> createState() => _SearchOverlayModalState();
}

class _SearchOverlayModalState extends ConsumerState<SearchOverlayModal> {
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  bool _isSearching = false;
  List<String> _recentSearches = [];

  List<Store> _suggestedStores = [];
  List<Product> _suggestedProducts = [];
  List<Offer> _suggestedOffers = [];
  List<Flyer> _suggestedFlyers = [];

  final List<Map<String, String>> _trendingSearches = const [
    {'en': 'iPhone 16 Pro', 'ar': 'آيفون 16 برو'},
    {'en': 'Lulu Hypermarket', 'ar': 'لولو هايبرماركت'},
    {'en': 'Smart TVs', 'ar': 'شاشات ذكية'},
    {'en': 'Panda Offers', 'ar': 'عروض بنده'},
    {'en': 'Grocery Discounts', 'ar': 'عروض المقاضي'},
    {'en': 'AirPods & Audio', 'ar': 'سماعات ايربودز'},
    {'en': 'Perfumes & Oud', 'ar': 'عطور وبخور'},
    {'en': 'Carrefour Deals', 'ar': 'عروض كارفور'},
  ];

  final List<Map<String, dynamic>> _quickCategories = const [
    {
      'nameEn': 'All Offers',
      'nameAr': 'جميع العروض',
      'icon': Icons.local_offer,
      'route': '/offers',
    },
    {
      'nameEn': 'Flyers & Booklets',
      'nameAr': 'المجلات والبروشورات',
      'icon': Icons.menu_book,
      'route': '/flyers',
    },
    {
      'nameEn': 'Browse Stores',
      'nameAr': 'تصفح المتاجر',
      'icon': Icons.storefront,
      'route': '/stores',
    },
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialQuery);
    _loadRecentSearches();

    // Ensure data repositories have data loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      ref.read(storeRepositoryProvider.notifier).fetchStores();
      ref.read(offerRepositoryProvider.notifier).fetchOffers();
      ref.read(flyerRepositoryProvider.notifier).fetchFlyers();
      if (_textController.text.trim().length >= 2) {
        _performSearch(_textController.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('dealspot_recent_searches');
      if (saved != null && mounted) {
        setState(() {
          _recentSearches = saved;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveRecentSearch(String term) async {
    final clean = term.trim();
    if (clean.isEmpty) return;
    try {
      final current = _recentSearches.where((s) => s.toLowerCase() != clean.toLowerCase()).toList();
      final updated = [clean, ...current].take(10).toList();
      if (mounted) {
        setState(() {
          _recentSearches = updated;
        });
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dealspot_recent_searches', updated);
    } catch (_) {}
  }

  Future<void> _removeRecentSearch(String term) async {
    try {
      final updated = _recentSearches.where((s) => s != term).toList();
      if (mounted) {
        setState(() {
          _recentSearches = updated;
        });
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dealspot_recent_searches', updated);
    } catch (_) {}
  }

  Future<void> _clearRecentSearches() async {
    try {
      if (mounted) {
        setState(() {
          _recentSearches = [];
        });
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('dealspot_recent_searches');
    } catch (_) {}
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        _performSearch(value.trim());
      }
    });
  }

  void _performSearch(String query) async {
    final cleanQ = query.trim();
    if (cleanQ.length < 2) {
      if (mounted) {
        setState(() {
          _suggestedOffers = [];
          _suggestedStores = [];
          _suggestedProducts = [];
          _suggestedFlyers = [];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final qLower = cleanQ.toLowerCase();

    // 1. Stores filter
    final allStores = ref.read(storeRepositoryProvider).stores;
    final filteredStores = allStores.where((s) {
      return (s.nameEn.toLowerCase().contains(qLower)) ||
          (s.nameAr.toLowerCase().contains(qLower)) ||
          (s.descriptionEn?.toLowerCase().contains(qLower) ?? false) ||
          (s.descriptionAr?.toLowerCase().contains(qLower) ?? false);
    }).take(4).toList();

    // 2. Offers filter
    final allOffers = ref.read(offerRepositoryProvider).offers;
    final filteredOffers = allOffers.where((o) {
      return (o.titleEn.toLowerCase().contains(qLower)) ||
          (o.titleAr.toLowerCase().contains(qLower)) ||
          (o.store?.nameEn.toLowerCase().contains(qLower) ?? false) ||
          (o.store?.nameAr.toLowerCase().contains(qLower) ?? false) ||
          (o.descriptionEn?.toLowerCase().contains(qLower) ?? false) ||
          (o.descriptionAr?.toLowerCase().contains(qLower) ?? false);
    }).take(6).toList();

    // 3. Flyers filter
    final allFlyers = ref.read(flyerRepositoryProvider.notifier).getFlyers();
    final filteredFlyers = allFlyers.where((f) {
      return (f.titleEn.toLowerCase().contains(qLower)) ||
          (f.titleAr.toLowerCase().contains(qLower)) ||
          (f.store?.nameEn.toLowerCase().contains(qLower) ?? false) ||
          (f.store?.nameAr.toLowerCase().contains(qLower) ?? false);
    }).take(4).toList();

    // 4. Products search
    List<Product> products = [];
    try {
      final pagedRes = await ref.read(productRepositoryProvider.notifier).getPagedProducts(
        page: 0,
        size: 6,
        search: cleanQ,
      );
      products = pagedRes.content;
    } catch (_) {
      final cachedProducts = ref.read(productRepositoryProvider).products;
      products = cachedProducts.where((p) {
        return (p.nameEn.toLowerCase().contains(qLower)) ||
            (p.nameAr.toLowerCase().contains(qLower)) ||
            (p.brand.toLowerCase().contains(qLower)) ||
            (p.brandAr.toLowerCase().contains(qLower));
      }).take(6).toList();
    }

    if (mounted) {
      setState(() {
        _suggestedStores = filteredStores;
        _suggestedOffers = filteredOffers;
        _suggestedFlyers = filteredFlyers;
        _suggestedProducts = products;
        _isSearching = false;
      });
    }
  }

  void _applySearch(String term) {
    final clean = term.trim();
    if (clean.isEmpty) return;
    _saveRecentSearch(clean);
    Navigator.of(context).pop();
    context.go('/offers?search=${Uri.encodeComponent(clean)}');
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _textController.text.trim();
    final hasQuery = query.length >= 2;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFC),
        body: SafeArea(
          child: Column(
            children: [
              // Top Search Modal Header (Matching Angular .search-modal-header)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : const Color(0xFFEEF0F3),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Back Button
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(9999),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        child: Icon(
                          isRtl ? Icons.arrow_forward : Icons.arrow_back,
                          size: 22,
                          color: isDark ? Colors.white : const Color(0xFF374151),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Search Pill Input Wrapper
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: const Color(0xFF16A34A).withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              size: 20,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                textInputAction: TextInputAction.search,
                                onChanged: _onSearchChanged,
                                onSubmitted: (val) {
                                  if (val.trim().isNotEmpty) {
                                    _applySearch(val);
                                  }
                                },
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : const Color(0xFF111827),
                                ),
                                decoration: InputDecoration(
                                  hintText: isRtl
                                      ? 'ابحث عن العروض، المتاجر، البروشورات...'
                                      : 'Search offers, stores, flyers, brands...',
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.normal,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_textController.text.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  _textController.clear();
                                  _onSearchChanged('');
                                },
                                borderRadius: BorderRadius.circular(9999),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Search Action Button
                    ElevatedButton(
                      onPressed: () {
                        if (_textController.text.trim().isNotEmpty) {
                          _applySearch(_textController.text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isRtl ? 'بحث' : 'Search',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Modal Body
              Expanded(
                child: hasQuery ? _buildSearchResults(isDark, isRtl, query) : _buildInitialState(isDark, isRtl),
              ),

              // Sticky Bottom Action Bar (When results / query exist)
              if (hasQuery)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _applySearch(query),
                      icon: const Icon(Icons.search, size: 18),
                      label: Text(
                        isRtl
                            ? 'عرض جميع نتائج البحث لـ "$query"'
                            : 'See all results for "$query"',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // STATE 1: Initial State (No query or < 2 chars)
  Widget _buildInitialState(bool isDark, bool isRtl) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Recent Searches
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFF16A34A), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    isRtl ? 'عمليات البحث الأخيرة' : 'Recent Searches',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _clearRecentSearches,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFFEF4444),
                ),
                child: Text(
                  isRtl ? 'مسح السجل' : 'Clear All',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((term) {
              return InkWell(
                onTap: () => _applySearch(term),
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  padding: const EdgeInsets.only(left: 10, right: 6, top: 6, bottom: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history,
                        size: 14,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        term,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _removeRecentSearch(term),
                        borderRadius: BorderRadius.circular(9999),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Popular & Trending Searches
        Row(
          children: [
            const Icon(Icons.local_fire_department, color: Color(0xFFF97316), size: 18),
            const SizedBox(width: 8),
            Text(
              isRtl ? 'الأكثر رواجاً وبحثاً' : 'Popular & Trending Searches',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trendingSearches.map((item) {
            final label = isRtl ? item['ar']! : item['en']!;
            return InkWell(
              onTap: () => _applySearch(label),
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, size: 14, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Quick Explore Categories
        Row(
          children: [
            const Icon(Icons.category, color: Color(0xFF3B82F6), size: 18),
            const SizedBox(width: 8),
            Text(
              isRtl ? 'تصفح سريع' : 'Quick Explore',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: _quickCategories.map((cat) {
            final name = isRtl ? cat['nameAr'] as String : cat['nameEn'] as String;
            final icon = cat['icon'] as IconData;
            final route = cat['route'] as String;

            return Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(route);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: const Color(0xFF16A34A), size: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // STATE 2: Live Search Suggestions
  Widget _buildSearchResults(bool isDark, bool isRtl, String query) {
    final hasMatches = _suggestedStores.isNotEmpty ||
        _suggestedProducts.isNotEmpty ||
        _suggestedOffers.isNotEmpty ||
        _suggestedFlyers.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Direct Keyword Search Suggestion Row
        InkWell(
          onTap: () => _applySearch(query),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF16A34A).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF16A34A), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      children: [
                        TextSpan(text: isRtl ? 'البحث عن ' : 'Search for '),
                        TextSpan(
                          text: '"$query"',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        TextSpan(text: isRtl ? ' في جميع العروض' : ' in all deals'),
                      ],
                    ),
                  ),
                ),
                Icon(
                  isRtl ? Icons.north_west : Icons.north_east,
                  size: 16,
                  color: const Color(0xFF16A34A),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Loading State
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isRtl ? 'جاري البحث في العروض والمتاجر...' : 'Searching deals, stores & flyers...',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (!_isSearching) ...[
          // Stores Section
          if (_suggestedStores.isNotEmpty) ...[
            _buildSectionHeader(
              title: isRtl ? 'المتاجر' : 'Stores',
              icon: Icons.storefront,
              color: const Color(0xFF3B82F6),
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            ..._suggestedStores.map((store) {
              final name = isRtl ? store.nameAr : store.nameEn;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 42,
                      height: 42,
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      child: AppNetworkImage(
                        imageUrl: store.logoUrl,
                        fit: BoxFit.contain,
                        defaultFallbackIcon: Icons.storefront,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isRtl ? 'متجر' : 'Store',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    isRtl ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onTap: () {
                    _saveRecentSearch(name);
                    Navigator.of(context).pop();
                    context.go('/stores/${store.id}');
                  },
                ),
              );
            }),
            const SizedBox(height: 14),
          ],

          // Products Section
          if (_suggestedProducts.isNotEmpty) ...[
            _buildSectionHeader(
              title: isRtl ? 'المنتجات والسلع' : 'Products & Items',
              icon: Icons.inventory_2,
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            ..._suggestedProducts.map((prod) {
              final name = isRtl ? prod.nameAr : prod.nameEn;
              final brand = isRtl
                  ? (prod.brandAr.isNotEmpty ? prod.brandAr : prod.sku)
                  : (prod.brand.isNotEmpty ? prod.brand : prod.sku);
              final imgUrl = prod.primaryImageUrl.isNotEmpty
                  ? prod.primaryImageUrl
                  : ((prod.images != null && prod.images!.isNotEmpty) ? prod.images!.first.imageUrl : null);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 42,
                      height: 42,
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      child: AppNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.cover,
                        defaultFallbackIcon: Icons.inventory_2,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: brand.isNotEmpty
                      ? Text(
                          brand,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        )
                      : null,
                  trailing: ElevatedButton(
                    onPressed: () {
                      _saveRecentSearch(name);
                      Navigator.of(context).pop();
                      context.go('/offers?search=${Uri.encodeComponent(name)}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A).withOpacity(0.12),
                      foregroundColor: const Color(0xFF16A34A),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isRtl ? 'عرض' : 'View',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),
          ],

          // Offers Section
          if (_suggestedOffers.isNotEmpty) ...[
            _buildSectionHeader(
              title: isRtl ? 'العروض والتخفيضات' : 'Offers & Discounts',
              icon: Icons.local_offer,
              color: const Color(0xFF16A34A),
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            ..._suggestedOffers.map((offer) {
              final title = isRtl ? offer.titleAr : offer.titleEn;
              final storeName = isRtl
                  ? (offer.store?.nameAr ?? offer.store?.nameEn)
                  : (offer.store?.nameEn ?? offer.store?.nameAr);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 42,
                      height: 42,
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      child: AppNetworkImage(
                        imageUrl: offer.imageUrl,
                        fit: BoxFit.cover,
                        defaultFallbackIcon: Icons.local_offer,
                      ),
                    ),
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      if (storeName != null) ...[
                        Expanded(
                          child: Text(
                            storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (offer.discountPct > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${offer.discountPct.toInt()}%',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Icon(
                    isRtl ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onTap: () {
                    _saveRecentSearch(title);
                    Navigator.of(context).pop();
                    context.go('/offers/${offer.id}');
                  },
                ),
              );
            }),
            const SizedBox(height: 14),
          ],

          // Flyers Section
          if (_suggestedFlyers.isNotEmpty) ...[
            _buildSectionHeader(
              title: isRtl ? 'المجلات والبروشورات' : 'Flyers & Booklets',
              icon: Icons.menu_book,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            ..._suggestedFlyers.map((flyer) {
              final title = isRtl ? flyer.titleAr : flyer.titleEn;
              final storeName = isRtl
                  ? (flyer.store?.nameAr ?? flyer.store?.nameEn)
                  : (flyer.store?.nameEn ?? flyer.store?.nameAr);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 42,
                      height: 42,
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      child: AppNetworkImage(
                        imageUrl: flyer.coverImageUrl,
                        fit: BoxFit.cover,
                        defaultFallbackIcon: Icons.menu_book,
                      ),
                    ),
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: storeName != null
                      ? Text(
                          storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        )
                      : null,
                  trailing: Icon(
                    isRtl ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onTap: () {
                    _saveRecentSearch(title);
                    Navigator.of(context).pop();
                    context.go('/flyers/${flyer.id}');
                  },
                ),
              );
            }),
            const SizedBox(height: 14),
          ],

          // Empty State
          if (!hasMatches)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off,
                      size: 36,
                      color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isRtl ? 'لم يتم العثور على نتائج مباشرة' : 'No exact matches found',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRtl
                        ? 'جرب استخدام كلمات بحث مختلفة أو تصفح كافة العروض.'
                        : 'Try searching with different keywords or browse all deals.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _applySearch(query),
                    icon: const Icon(Icons.search, size: 16),
                    label: Text(
                      isRtl ? 'البحث في كافة العروض على أية حال' : 'Search in all offers anyway',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
