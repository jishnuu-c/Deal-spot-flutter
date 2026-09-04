import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/coupon_repository.dart';
import '../../../../core/services/offer_repository.dart';
import '../../../../core/services/store_repository.dart';
import '../../../../core/services/product_repository.dart';
import '../../../../models/models.dart';

class CouponsCrudScreen extends ConsumerStatefulWidget {
  const CouponsCrudScreen({super.key});

  @override
  ConsumerState<CouponsCrudScreen> createState() => _CouponsCrudScreenState();
}

class _CouponsCrudScreenState extends ConsumerState<CouponsCrudScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(couponRepositoryProvider.notifier).fetchCoupons();
      ref.read(storeRepositoryProvider.notifier).fetchStores();
      ref.read(offerRepositoryProvider.notifier).fetchOffers();
    });
  }

  void _showForm(BuildContext context, [CouponCode? cc]) {
    final codeCtrl = TextEditingController(text: cc?.code);
    final valCtrl = TextEditingController(text: cc?.discountValue.toString() ?? '10.0');
    final minCartCtrl = TextEditingController(text: cc?.minCartValue?.toString() ?? '100.0');
    final fromCtrl = TextEditingController(text: cc?.validFrom ?? '2026-07-01');
    final untilCtrl = TextEditingController(text: cc?.validUntil ?? '2026-07-31');
    final maxUsesCtrl = TextEditingController(text: cc?.maxUses?.toString() ?? '100');

    final offers = ref.read(offerRepositoryProvider).offers;
    final stores = ref.read(storeRepositoryProvider).stores;
    final products = ref.read(productRepositoryProvider).products;

    int? selectedOfferId = cc?.offerId;
    int? selectedStoreId = cc?.storeId;
    int? selectedProductId = cc?.productId;
    String discountType = cc?.discountType ?? 'PERCENTAGE';
    bool isActive = cc == null ? true : cc.isActive == 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(cc == null ? 'Add Coupon' : 'Edit Coupon'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Coupon Code (e.g. EXTRA10)')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: discountType,
                      decoration: const InputDecoration(labelText: 'Discount Type'),
                      items: const [
                        DropdownMenuItem(value: 'PERCENTAGE', child: Text('PERCENTAGE')),
                        DropdownMenuItem(value: 'FIXED', child: Text('FIXED')),
                        DropdownMenuItem(value: 'FREE_SHIPPING', child: Text('FREE SHIPPING')),
                      ],
                      onChanged: (val) => setState(() => discountType = val ?? 'PERCENTAGE'),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: valCtrl, decoration: const InputDecoration(labelText: 'Discount Value'), keyboardType: TextInputType.number),
                    const SizedBox(height: 8),
                    TextField(controller: minCartCtrl, decoration: const InputDecoration(labelText: 'Min Cart Value'), keyboardType: TextInputType.number),
                    const SizedBox(height: 8),
                    TextField(controller: maxUsesCtrl, decoration: const InputDecoration(labelText: 'Max Uses Limit'), keyboardType: TextInputType.number),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: 'Valid From'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: untilCtrl, decoration: const InputDecoration(labelText: 'Valid Until'))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      value: selectedOfferId,
                      decoration: const InputDecoration(labelText: 'Offer Limit (Optional)'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('All Offers')),
                        ...offers.map((o) => DropdownMenuItem<int?>(value: o.id, child: Text(o.titleEn))),
                      ],
                      onChanged: (val) => setState(() => selectedOfferId = val),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      value: selectedStoreId,
                      decoration: const InputDecoration(labelText: 'Store Limit (Optional)'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('All Stores')),
                        ...stores.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.nameEn))),
                      ],
                      onChanged: (val) => setState(() => selectedStoreId = val),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      value: selectedProductId,
                      decoration: const InputDecoration(labelText: 'Product Limit (Optional)'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('All Products')),
                        ...products.map((p) => DropdownMenuItem<int?>(value: p.id, child: Text(p.nameEn))),
                      ],
                      onChanged: (val) => setState(() => selectedProductId = val),
                    ),
                    const SizedBox(height: 8),
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
                    final val = double.tryParse(valCtrl.text) ?? 0.0;
                    final min = double.tryParse(minCartCtrl.text);
                    final max = int.tryParse(maxUsesCtrl.text);

                    if (cc == null) {
                      ref.read(couponRepositoryProvider.notifier).createCoupon(
                            codeCtrl.text,
                            discountType,
                            val,
                            min,
                            fromCtrl.text,
                            untilCtrl.text,
                            isActive ? 1 : 0,
                            offerId: selectedOfferId,
                            storeId: selectedStoreId,
                            productId: selectedProductId,
                            maxUses: max,
                          );
                    } else {
                      ref.read(couponRepositoryProvider.notifier).updateCoupon(
                            cc.id,
                            codeCtrl.text,
                            discountType,
                            val,
                            min,
                            fromCtrl.text,
                            untilCtrl.text,
                            isActive ? 1 : 0,
                            offerId: selectedOfferId,
                            storeId: selectedStoreId,
                            productId: selectedProductId,
                            maxUses: max,
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
  Widget build(BuildContext context) {
    final list = ref.watch(couponRepositoryProvider.notifier).getCoupons();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Coupons'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Coupon'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final cc = list[index];
          return ListTile(
            leading: const Icon(Icons.card_giftcard, color: Colors.indigo),
            title: Text('${cc.code} (${cc.discountType}: ${cc.discountValue})'),
            subtitle: Text('Min Cart: ${cc.minCartValue ?? 0} SAR | Limit: ${cc.usedCount}/${cc.maxUses ?? "∞"} uses | Valid until: ${cc.validUntil}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showForm(context, cc)),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ref.read(couponRepositoryProvider.notifier).deleteCoupon(cc.id);
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
