import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/offer_repository.dart';
import '../../../../models/models.dart';

class OfferImagesCrudScreen extends ConsumerWidget {
  final int offerId;

  const OfferImagesCrudScreen({super.key, required this.offerId});

  void _showForm(BuildContext context, WidgetRef ref) {
    final urlCtrl = TextEditingController();
    final sortCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Offer Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Image URL')),
              const SizedBox(height: 8),
              TextField(controller: sortCtrl, decoration: const InputDecoration(labelText: 'Sort Order'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final sort = int.tryParse(sortCtrl.text) ?? 1;
                ref.read(offerRepositoryProvider.notifier).createOfferImage(
                      offerId,
                      urlCtrl.text,
                      sort,
                    );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = ref.watch(offerRepositoryProvider.notifier).getOfferById(offerId);
    final images = offer?.images ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${offer?.titleEn ?? "Offer"} - Images'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => _showForm(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Image'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final img = images[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: AppConfig.normalizeImageUrl(img.imageUrl),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order: ${img.sortOrder}', style: const TextStyle(fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                        onPressed: () {
                          ref.read(offerRepositoryProvider.notifier).deleteOfferImage(img.id);
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
