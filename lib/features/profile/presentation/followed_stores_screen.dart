import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/store_repository.dart';
import '../../../core/utils/translation_service.dart';

class FollowedStoresScreen extends ConsumerWidget {
  const FollowedStoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final followedStores = ref.watch(storeRepositoryProvider.notifier).getFollowedStores();

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr.get('followed_stores'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/profile'),
          ),
        ),
        body: followedStores.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        isRtl ? 'لا توجد متاجر متابعة حتى الآن' : 'No followed stores yet',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRtl ? 'تابع متاجرك المفضلة للحصول على منشوراتها وعروضها الحصرية أولاً بأول.' : 'Follow your favorite retail shops to stay updated with their latest flyers.',
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
                        onPressed: () => context.go('/stores'),
                        child: Text(tr.get('stores')),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: followedStores.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final store = followedStores[index];
                  final storeName = isRtl ? store.nameAr : store.nameEn;
                  final categoryName = isRtl ? (store.category?.nameAr ?? '') : (store.category?.nameEn ?? '');

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (store.logoUrl.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: AppConfig.normalizeImageUrl(store.logoUrl),
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) => const Icon(Icons.storefront, color: Color(0xFF16A34A)),
                                )
                              : const Icon(Icons.storefront, color: Color(0xFF16A34A)),
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              storeName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          if (store.isVerified == 1) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 15),
                          ],
                        ],
                      ),
                      subtitle: categoryName.isNotEmpty
                          ? Text(
                              categoryName,
                              style: const TextStyle(color: Color(0xFF16A34A), fontSize: 11.5, fontWeight: FontWeight.w600),
                            )
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.redAccent),
                        onPressed: () {
                          ref.read(storeRepositoryProvider.notifier).toggleFollowStore(store.id);
                        },
                      ),
                      onTap: () => context.go('/stores/${store.id}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
