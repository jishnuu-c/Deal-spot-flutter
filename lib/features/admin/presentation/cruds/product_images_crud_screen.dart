import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/services/product_repository.dart';
import '../../../../models/models.dart';

class ProductImagesCrudScreen extends ConsumerWidget {
  final int productId;

  const ProductImagesCrudScreen({super.key, required this.productId});

  void _showForm(BuildContext context, WidgetRef ref) {
    final urlCtrl = TextEditingController();
    final altEnCtrl = TextEditingController();
    final altArCtrl = TextEditingController();
    final sortCtrl = TextEditingController(text: '1');
    bool isPrimary = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Product Image'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'Image URL')),
                    const SizedBox(height: 8),
                    TextField(controller: altEnCtrl, decoration: const InputDecoration(labelText: 'Alt Text (EN)')),
                    const SizedBox(height: 8),
                    TextField(controller: altArCtrl, decoration: const InputDecoration(labelText: 'Alt Text (AR)')),
                    const SizedBox(height: 8),
                    TextField(controller: sortCtrl, decoration: const InputDecoration(labelText: 'Sort Order'), keyboardType: TextInputType.number),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Set as Primary Image'),
                      value: isPrimary,
                      onChanged: (val) => setState(() => isPrimary = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final sort = int.tryParse(sortCtrl.text) ?? 1;
                    ref.read(productRepositoryProvider.notifier).createProductImage(
                          productId,
                          urlCtrl.text,
                          altEnCtrl.text.isEmpty ? null : altEnCtrl.text,
                          altArCtrl.text.isEmpty ? null : altArCtrl.text,
                          sort,
                          isPrimary ? 1 : 0,
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productRepositoryProvider.notifier).getProductById(productId);
    final images = product?.images ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${product?.nameEn ?? "Product"} - Images Library'),
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        imageUrl: img.imageUrl,
                        fit: BoxFit.cover,
                        defaultFallbackIcon: Icons.broken_image,
                      ),
                      if (img.isPrimary == 1)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
                            child: const Text('PRIMARY', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
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
                          ref.read(productRepositoryProvider.notifier).deleteProductImage(img.id);
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
