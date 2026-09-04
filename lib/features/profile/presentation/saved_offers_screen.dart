import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/offer_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

class SavedOffersScreen extends ConsumerStatefulWidget {
  const SavedOffersScreen({super.key});

  @override
  ConsumerState<SavedOffersScreen> createState() => _SavedOffersScreenState();
}

class _SavedOffersScreenState extends ConsumerState<SavedOffersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(offerRepositoryProvider.notifier).fetchOffers();
      ref.read(offerRepositoryProvider.notifier).fetchSavedOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final savedOffers = ref.watch(offerRepositoryProvider.notifier).getOffers(
      const OfferFilters(onlySaved: true),
    );

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.get('saved_offers'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/profile'),
          ),
        ),
        body: savedOffers.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        isRtl ? 'لا توجد عروض محفوظة حتى الآن' : 'No saved offers yet',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRtl ? 'احفظ عروضك المفضلة للرجوع إليها بسرعة في أي وقت.' : 'Save your favorite discounts to access them quickly anytime.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => context.go('/offers'),
                        child: Text(tr.get('explore_offers')),
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.60,
                ),
                itemCount: savedOffers.length,
                itemBuilder: (context, index) {
                  final offer = savedOffers[index];
                  return _buildGridCard(context, ref, offer, isRtl, isDark, tr);
                },
              ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, WidgetRef ref, Offer offer, bool isRtl, bool isDark, AppLocalizations tr) {
    final title = isRtl ? offer.titleAr : offer.titleEn;
    final storeName = isRtl ? (offer.store?.nameAr ?? '') : (offer.store?.nameEn ?? '');
    final imageUrl = (offer.images != null && offer.images!.isNotEmpty)
        ? offer.images!.first.imageUrl
        : (offer.product?.primaryImageUrl ?? '');

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
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.35,
                    child: CachedNetworkImage(
                      imageUrl: AppConfig.normalizeImageUrl(imageUrl),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: isRtl ? null : 6,
                    left: isRtl ? 6 : null,
                    child: InkWell(
                      onTap: () => ref.read(offerRepositoryProvider.notifier).toggleSaveOffer(offer.id),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bookmark, color: Color(0xFF16A34A), size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (storeName.isNotEmpty)
                      Text(
                        storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, height: 1.2),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${offer.offerPrice.toStringAsFixed(0)} ${tr.get('sar')}',
                          style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        if (offer.originalPrice > offer.offerPrice) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${offer.originalPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
