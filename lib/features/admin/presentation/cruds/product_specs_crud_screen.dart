import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/product_repository.dart';
import '../../../../models/models.dart';

class ProductSpecsCrudScreen extends ConsumerWidget {
  final int productId;

  const ProductSpecsCrudScreen({super.key, required this.productId});

  void _showForm(BuildContext context, WidgetRef ref) {
    final keyEnCtrl = TextEditingController();
    final keyArCtrl = TextEditingController();
    final valEnCtrl = TextEditingController();
    final valArCtrl = TextEditingController();
    final sortCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Specification Attribute'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: keyEnCtrl, decoration: const InputDecoration(labelText: 'Key (EN) (e.g. Storage)')),
                const SizedBox(height: 8),
                TextField(controller: keyArCtrl, decoration: const InputDecoration(labelText: 'Key (AR)')),
                const SizedBox(height: 8),
                TextField(controller: valEnCtrl, decoration: const InputDecoration(labelText: 'Value (EN) (e.g. 256 GB)')),
                const SizedBox(height: 8),
                TextField(controller: valArCtrl, decoration: const InputDecoration(labelText: 'Value (AR)')),
                const SizedBox(height: 8),
                TextField(controller: sortCtrl, decoration: const InputDecoration(labelText: 'Sort Order'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final sort = int.tryParse(sortCtrl.text) ?? 1;
                ref.read(productRepositoryProvider.notifier).createProductDetail(
                      productId,
                      keyEnCtrl.text,
                      keyArCtrl.text,
                      valEnCtrl.text,
                      valArCtrl.text,
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
    final product = ref.watch(productRepositoryProvider.notifier).getProductById(productId);
    final details = product?.details ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${product?.nameEn ?? "Product"} - Specifications'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => _showForm(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Spec'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: details.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final detail = details[index];
          return ListTile(
            title: Text('${detail.attrKeyEn} / ${detail.attrKeyAr}'),
            subtitle: Text('Value: ${detail.attrValueEn} / ${detail.attrValueAr} | Order: ${detail.sortOrder}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                ref.read(productRepositoryProvider.notifier).deleteProductDetail(detail.id);
              },
            ),
          );
        },
      ),
    );
  }
}
