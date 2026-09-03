import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/store_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

class StoreBranchesScreen extends ConsumerStatefulWidget {
  final int storeId;

  const StoreBranchesScreen({super.key, required this.storeId});

  @override
  ConsumerState<StoreBranchesScreen> createState() => _StoreBranchesScreenState();
}

class _StoreBranchesScreenState extends ConsumerState<StoreBranchesScreen> {
  Store? _store;
  List<StoreBranch> _branches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  void _loadBranches() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = ref.read(storeRepositoryProvider.notifier).getStoreById(widget.storeId);
      final branches = ref.read(storeRepositoryProvider.notifier).getBranchesForStore(widget.storeId);
      if (mounted) {
        setState(() {
          _store = store;
          _branches = branches;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_store == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Store not found')),
      );
    }

    final store = _store!;
    final storeName = isRtl ? store.nameAr : store.nameEn;

    return Scaffold(
      appBar: AppBar(
        title: Text('$storeName - ${tr.get('branches')}'),
      ),
      body: _branches.isEmpty
          ? const Center(child: Text('No branches registered for this store.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _branches.length,
              itemBuilder: (context, index) {
                final branch = _branches[index];
                final cityName = isRtl ? (branch.city?.nameAr ?? '') : (branch.city?.nameEn ?? '');

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                branch.branchName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('City: $cityName', style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Working Hours: ${branch.openTime} - ${branch.closeTime}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 12),
                        
                        // Display simulated Map Coordinates
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Coordinates: ${branch.latitude}, ${branch.longitude}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                              ),
                              IconButton(
                                icon: const Icon(Icons.navigation, color: Colors.green, size: 20),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Simulated launching Navigation to: ${branch.branchName}')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
