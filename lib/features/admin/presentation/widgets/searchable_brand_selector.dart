import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../models/brand.dart';

class SearchableBrandSelector extends StatelessWidget {
  final int? selectedBrandId;
  final List<Brand> brands;
  final ValueChanged<int?> onChanged;
  final bool isRtl;
  final bool isDark;
  final String? placeholder;
  final bool isRequired;

  const SearchableBrandSelector({
    super.key,
    required this.selectedBrandId,
    required this.brands,
    required this.onChanged,
    required this.isRtl,
    required this.isDark,
    this.placeholder,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBrand = brands.where((b) => b.id == selectedBrandId).firstOrNull;
    final selectedName = selectedBrand != null
        ? (isRtl ? (selectedBrand.nameAr.isNotEmpty ? selectedBrand.nameAr : selectedBrand.nameEn) : selectedBrand.nameEn)
        : null;
    final selectedLogo = selectedBrand != null ? AppConfig.normalizeImageUrl(selectedBrand.logoUrl) : null;

    final defaultPlaceholder = placeholder ?? (isRtl ? '-- اختر الماركة --' : '-- Select Brand --');

    return InkWell(
      onTap: () => _showBrandPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          children: [
            if (selectedLogo != null && selectedLogo.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: 24,
                  height: 24,
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  child: AppNetworkImage(
                    imageUrl: selectedLogo,
                    fit: BoxFit.contain,
                    defaultFallbackIcon: Icons.storefront,
                    fallbackIconSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ] else ...[
              Icon(
                Icons.storefront,
                size: 16,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                selectedName ?? defaultPlaceholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selectedBrand != null ? FontWeight.w600 : FontWeight.normal,
                  color: selectedBrand != null
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _showBrandPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: _BrandPickerSheet(
            brands: brands,
            selectedBrandId: selectedBrandId,
            onSelected: (id) {
              onChanged(id);
              Navigator.pop(ctx);
            },
            isRtl: isRtl,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _BrandPickerSheet extends StatefulWidget {
  final List<Brand> brands;
  final int? selectedBrandId;
  final ValueChanged<int?> onSelected;
  final bool isRtl;
  final bool isDark;

  const _BrandPickerSheet({
    required this.brands,
    required this.selectedBrandId,
    required this.onSelected,
    required this.isRtl,
    required this.isDark,
  });

  @override
  State<_BrandPickerSheet> createState() => _BrandPickerSheetState();
}

class _BrandPickerSheetState extends State<_BrandPickerSheet> {
  late TextEditingController _searchCtrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.brands.where((b) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return b.nameEn.toLowerCase().contains(q) ||
          b.nameAr.toLowerCase().contains(q) ||
          b.id.toString() == q;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.storefront, size: 20, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isRtl ? 'اختر الماركة التجارية' : 'Select Brand Partner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _query = val.trim()),
              style: TextStyle(
                fontSize: 12.5,
                color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: widget.isRtl ? 'ابحث عن الماركة...' : 'Search brand by name or ID...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),

          // Brand List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, size: 36, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 8),
                        Text(
                          widget.isRtl ? 'لا توجد ماركات مطابقة' : 'No matching brands found',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                    itemBuilder: (ctx, i) {
                      final b = filtered[i];
                      final isSelected = b.id == widget.selectedBrandId;
                      final name = widget.isRtl
                          ? (b.nameAr.isNotEmpty ? b.nameAr : b.nameEn)
                          : b.nameEn;
                      final secName = widget.isRtl
                          ? (b.nameEn)
                          : (b.nameAr.isNotEmpty ? b.nameAr : '');
                      final logoUrl = AppConfig.normalizeImageUrl(b.logoUrl);

                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: const Color(0xFFDCFCE7).withValues(alpha: 0.3),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 36,
                            height: 36,
                            color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            child: AppNetworkImage(
                              imageUrl: logoUrl,
                              fit: BoxFit.contain,
                              defaultFallbackIcon: Icons.storefront,
                              fallbackIconSize: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF16A34A)
                                : (widget.isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                        subtitle: secName.isNotEmpty
                            ? Text(
                                secName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              )
                            : null,
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18)
                            : null,
                        onTap: () => widget.onSelected(b.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
