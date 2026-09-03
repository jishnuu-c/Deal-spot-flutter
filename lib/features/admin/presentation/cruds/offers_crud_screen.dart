import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/offer_repository.dart';
import '../../../../core/services/store_repository.dart';
import '../../../../core/services/product_repository.dart';
import '../../../../core/services/city_repository.dart';
import '../../../../core/services/category_repository.dart';
import '../../../../models/models.dart';

class OffersCrudScreen extends ConsumerWidget {
  const OffersCrudScreen({super.key});

  void _showForm(BuildContext context, WidgetRef ref, [Offer? offer]) {
    final titleEnCtrl = TextEditingController(text: offer?.titleEn);
    final titleArCtrl = TextEditingController(text: offer?.titleAr);
    final origPriceCtrl = TextEditingController(text: offer?.originalPrice.toString() ?? '10.0');
    final offerPriceCtrl = TextEditingController(text: offer?.offerPrice.toString() ?? '5.0');
    final badgeCtrl = TextEditingController(text: offer?.badgeType ?? 'NONE');
    final fromCtrl = TextEditingController(text: offer?.validFrom ?? '2026-07-01');
    final untilCtrl = TextEditingController(text: offer?.validUntil ?? '2026-07-31');

    final stores = ref.read(storeRepositoryProvider).stores;
    final products = ref.read(productRepositoryProvider).products;
    final cities = ref.read(cityRepositoryProvider).cities;
    final categories = ref.read(categoryRepositoryProvider);

    int? selectedStoreId = offer?.storeId ?? (stores.isNotEmpty ? stores[0].id : null);
    int? selectedProductId = offer?.productId;
    int? selectedCityId = offer?.cityId ?? (cities.isNotEmpty ? cities[0].id : null);
    int? selectedCategoryId = offer?.categoryId ?? (categories.isNotEmpty ? categories[0].id : null);

    bool isFeatured = offer == null ? false : offer.isFeatured == 1;
    bool isFlash = offer == null ? false : offer.isFlash == 1;
    bool isActive = offer == null ? true : offer.isActive == 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(offer == null ? 'Add Offer' : 'Edit Offer'),
              content: SingleChildScrollView(
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
                    TextField(controller: badgeCtrl, decoration: const InputDecoration(labelText: 'Badge Type (e.g. FLASH, BOGO)')),
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
                      onChanged: (val) => setState(() => selectedStoreId = val),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      value: selectedProductId,
                      decoration: const InputDecoration(labelText: 'Associated Product (Optional)'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('None')),
                        ...products.map((p) => DropdownMenuItem<int?>(value: p.id, child: Text(p.nameEn))),
                      ],
                      onChanged: (val) => setState(() => selectedProductId = val),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedCityId,
                      decoration: const InputDecoration(labelText: 'City'),
                      items: cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameEn))).toList(),
                      onChanged: (val) => setState(() => selectedCityId = val),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameEn))).toList(),
                      onChanged: (val) => setState(() => selectedCategoryId = val),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Is Featured'),
                      value: isFeatured,
                      onChanged: (val) => setState(() => isFeatured = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Is Flash Deal'),
                      value: isFlash,
                      onChanged: (val) => setState(() => isFlash = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Is Active'),
                      value: isActive,
                      onChanged: (val) => setState(() => isActive = val ?? true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedStoreId == null || selectedCityId == null || selectedCategoryId == null) return;
                    final orig = double.tryParse(origPriceCtrl.text) ?? 10.0;
                    final off = double.tryParse(offerPriceCtrl.text) ?? 5.0;

                    if (offer == null) {
                      ref.read(offerRepositoryProvider.notifier).createOffer(
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
                      ref.read(offerRepositoryProvider.notifier).updateOffer(
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
                    Navigator.pop(context);
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
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(offerRepositoryProvider.notifier).getOffers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Offers'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => _showForm(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Add Offer'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final offer = list[index];
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
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showForm(context, ref, offer)),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ref.read(offerRepositoryProvider.notifier).deleteOffer(offer.id);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
