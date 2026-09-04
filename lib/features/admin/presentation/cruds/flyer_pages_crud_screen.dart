import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/services/flyer_repository.dart';
import '../../../../models/models.dart';

class FlyerPagesCrudScreen extends ConsumerStatefulWidget {
  final int flyerId;

  const FlyerPagesCrudScreen({super.key, required this.flyerId});

  @override
  ConsumerState<FlyerPagesCrudScreen> createState() => _FlyerPagesCrudScreenState();
}

class _FlyerPagesCrudScreenState extends ConsumerState<FlyerPagesCrudScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flyerRepositoryProvider.notifier).fetchFlyerById(widget.flyerId);
      ref.read(flyerRepositoryProvider.notifier).fetchFlyerPages(widget.flyerId);
    });
  }

  void _showForm(BuildContext context) {
    final pageNumCtrl = TextEditingController(text: '1');
    final imgCtrl = TextEditingController();
    final thumbCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Flyer Page'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: pageNumCtrl, decoration: const InputDecoration(labelText: 'Page Number'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'Page Image URL')),
              const SizedBox(height: 8),
              TextField(controller: thumbCtrl, decoration: const InputDecoration(labelText: 'Thumbnail Image URL')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final pageNum = int.tryParse(pageNumCtrl.text) ?? 1;
                ref.read(flyerRepositoryProvider.notifier).createFlyerPage(
                      widget.flyerId,
                      pageNum,
                      imgCtrl.text,
                      thumbCtrl.text,
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
  Widget build(BuildContext context) {
    final flyer = ref.watch(flyerRepositoryProvider.notifier).getFlyerById(widget.flyerId);
    final pages = flyer?.pages ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${flyer?.titleEn ?? "Flyer"} - Sheets'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Page'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: pages.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final page = pages[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AppNetworkImage(
                imageUrl: page.thumbUrl,
                width: 40,
                height: 50,
                fit: BoxFit.cover,
                defaultFallbackIcon: Icons.picture_as_pdf,
              ),
            ),
            title: Text('Page Sheet #${page.pageNumber}'),
            subtitle: Text('Full Image: ${page.imageUrl}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                ref.read(flyerRepositoryProvider.notifier).deleteFlyerPage(page.id);
              },
            ),
          );
        },
      ),
    );
  }
}
