import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/flyer_repository.dart';
import '../../../../core/services/store_repository.dart';
import '../../../../core/services/city_repository.dart';
import '../../../../models/models.dart';

class FlyersCrudScreen extends ConsumerStatefulWidget {
  const FlyersCrudScreen({super.key});

  @override
  ConsumerState<FlyersCrudScreen> createState() => _FlyersCrudScreenState();
}

class _FlyersCrudScreenState extends ConsumerState<FlyersCrudScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flyerRepositoryProvider.notifier).fetchFlyers();
      ref.read(storeRepositoryProvider.notifier).fetchStores();
      ref.read(cityRepositoryProvider.notifier).fetchCities();
    });
  }

  void _showForm(BuildContext context, [Flyer? flyer]) {
    final titleEnCtrl = TextEditingController(text: flyer?.titleEn);
    final titleArCtrl = TextEditingController(text: flyer?.titleAr);
    final coverCtrl = TextEditingController(text: flyer?.coverImageUrl ?? 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=300&auto=format&fit=crop&q=60');
    final pdfCtrl = TextEditingController(text: flyer?.pdfUrl ?? '');
    final pagesCountCtrl = TextEditingController(text: flyer?.totalPages.toString() ?? '1');
    final fromCtrl = TextEditingController(text: flyer?.validFrom ?? '2026-07-01');
    final untilCtrl = TextEditingController(text: flyer?.validUntil ?? '2026-07-31');

    final stores = ref.read(storeRepositoryProvider).stores;
    final cities = ref.read(cityRepositoryProvider).cities;

    int? selectedStoreId = flyer?.storeId != null && stores.any((s) => s.id == flyer!.storeId)
        ? flyer!.storeId
        : (stores.isNotEmpty ? stores[0].id : null);
    int? selectedCityId = flyer?.cityId != null && cities.any((c) => c.id == flyer!.cityId)
        ? flyer!.cityId
        : (cities.isNotEmpty ? cities[0].id : null);
    bool isActive = flyer == null ? true : flyer.isActive == 1;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(flyer == null ? 'Add Flyer' : 'Edit Flyer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleEnCtrl, decoration: const InputDecoration(labelText: 'Title (EN) *')),
                    const SizedBox(height: 8),
                    TextField(controller: titleArCtrl, decoration: const InputDecoration(labelText: 'Title (AR)')),
                    const SizedBox(height: 8),
                    TextField(controller: coverCtrl, decoration: const InputDecoration(labelText: 'Cover Image URL')),
                    const SizedBox(height: 8),
                    TextField(controller: pdfCtrl, decoration: const InputDecoration(labelText: 'PDF URL (Optional)')),
                    const SizedBox(height: 8),
                    TextField(controller: pagesCountCtrl, decoration: const InputDecoration(labelText: 'Total Pages Initial'), keyboardType: TextInputType.number),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: 'Valid From (YYYY-MM-DD)'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: untilCtrl, decoration: const InputDecoration(labelText: 'Valid Until (YYYY-MM-DD)'))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedStoreId,
                      decoration: const InputDecoration(labelText: 'Store *'),
                      items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nameEn))).toList(),
                      onChanged: (val) => setDialogState(() => selectedStoreId = val),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedCityId,
                      decoration: const InputDecoration(labelText: 'City *'),
                      items: cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameEn))).toList(),
                      onChanged: (val) => setDialogState(() => selectedCityId = val),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Is Active'),
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val ?? true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final titleEn = titleEnCtrl.text.trim();
                          final titleAr = titleArCtrl.text.trim();
                          if (titleEn.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter Title (EN)'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          if (selectedStoreId == null || selectedCityId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select Store and City'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          final totalP = int.tryParse(pagesCountCtrl.text.trim()) ?? 1;

                          setDialogState(() => isSaving = true);
                          try {
                            if (flyer == null) {
                              ref.read(flyerRepositoryProvider.notifier).createFlyer(
                                    titleEn,
                                    titleAr.isNotEmpty ? titleAr : titleEn,
                                    coverCtrl.text.trim(),
                                    pdfCtrl.text.trim(),
                                    totalP,
                                    fromCtrl.text.trim(),
                                    untilCtrl.text.trim(),
                                    selectedStoreId!,
                                    selectedCityId!,
                                    isActive ? 1 : 0,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Flyer created successfully!'), backgroundColor: Colors.green),
                                );
                              }
                            } else {
                              ref.read(flyerRepositoryProvider.notifier).updateFlyer(
                                    flyer.id,
                                    titleEn,
                                    titleAr.isNotEmpty ? titleAr : titleEn,
                                    coverCtrl.text.trim(),
                                    pdfCtrl.text.trim(),
                                    totalP,
                                    fromCtrl.text.trim(),
                                    untilCtrl.text.trim(),
                                    selectedStoreId!,
                                    selectedCityId!,
                                    isActive ? 1 : 0,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Flyer updated successfully!'), backgroundColor: Colors.green),
                                );
                              }
                            }
                            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                            ref.read(flyerRepositoryProvider.notifier).fetchFlyers();
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error saving flyer: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
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
    final list = ref.watch(flyerRepositoryProvider.notifier).getFlyers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Flyers'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Flyer'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final flyer = list[index];
          return ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: Text(flyer.titleEn),
            subtitle: Text('Store: ${flyer.store?.nameEn ?? ""} | Total Pages: ${flyer.totalPages} | Views: ${flyer.viewCount}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade50, foregroundColor: Colors.orange, elevation: 0),
                  onPressed: () => context.push('/admin/flyers/${flyer.id}/pages'),
                  icon: const Icon(Icons.layers, size: 14),
                  label: const Text('Pages', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showForm(context, flyer)),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ref.read(flyerRepositoryProvider.notifier).deleteFlyer(flyer.id);
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
