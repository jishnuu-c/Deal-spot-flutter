import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/product_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  void _loadProduct() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final product = ref.read(productRepositoryProvider.notifier).getProductById(widget.productId);
      if (mounted) {
        setState(() {
          _product = product;
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

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Product not found')),
      );
    }

    final product = _product!;
    final name = isRtl ? product.nameAr : product.nameEn;
    final brand = isRtl ? product.brandAr : product.brand;
    final desc = isRtl ? (product.descriptionAr ?? '') : (product.descriptionEn ?? '');
    final images = product.images ?? [];
    final details = product.details ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images Slideshow
            if (images.isNotEmpty)
              SizedBox(
                height: 250,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final imgUrl = images[index].imageUrl;
                    return CachedNetworkImage(
                      imageUrl: AppConfig.normalizeImageUrl(imgUrl),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => Container(color: Colors.grey.shade300, child: const Icon(Icons.broken_image)),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand & Name
                  Text(
                    brand.toUpperCase(),
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Pack Size & Unit Type
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      'Unit: ${product.unitSize} ${product.unit}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    ),
                  ),
                  const Divider(height: 32),

                  // Standard properties mapping to DB columns
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn('SKU', product.sku),
                      _buildInfoColumn('Barcode', product.barcode),
                    ],
                  ),
                  const Divider(height: 32),

                  // Description
                  if (desc.isNotEmpty) ...[
                    const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 14),
                    ),
                    const Divider(height: 32),
                  ],

                  // Specs properties table
                  if (details.isNotEmpty) ...[
                    const Text('Specifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Table(
                      border: TableBorder.all(color: Colors.grey.shade200, width: 1, borderRadius: BorderRadius.circular(8)),
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(2),
                      },
                      children: details.map((d) {
                        final key = isRtl ? d.attrKeyAr : d.attrKeyEn;
                        final val = isRtl ? d.attrValueAr : d.attrValueEn;
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(val, style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
