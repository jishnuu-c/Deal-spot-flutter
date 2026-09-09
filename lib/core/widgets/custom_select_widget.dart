import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'app_network_image.dart';

class CustomSelectOption<T> {
  final T value;
  final String labelEn;
  final String? labelAr;
  final String? imageUrl;
  final IconData? icon;
  final bool disabled;

  const CustomSelectOption({
    required this.value,
    required this.labelEn,
    this.labelAr,
    this.imageUrl,
    this.icon,
    this.disabled = false,
  });

  String getLabel(bool isEn) {
    if (!isEn && labelAr != null && labelAr!.trim().isNotEmpty) {
      return labelAr!;
    }
    return labelEn;
  }
}

class AppCustomSelect<T> extends StatefulWidget {
  final List<CustomSelectOption<T>> options;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final String placeholder;
  final String? label;
  final bool isRequired;
  final bool clearable;
  final bool searchable;
  final bool enabled;
  final String? errorText;
  final double maxHeight;

  const AppCustomSelect({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.placeholder = '-- Select --',
    this.label,
    this.isRequired = false,
    this.clearable = false,
    this.searchable = true,
    this.enabled = true,
    this.errorText,
    this.maxHeight = 240,
  });

  @override
  State<AppCustomSelect<T>> createState() => _AppCustomSelectState<T>();
}

class _AppCustomSelectState<T> extends State<AppCustomSelect<T>> {
  bool _isOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _searchQuery = '';
        _searchCtrl.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _searchFocusNode.canRequestFocus) {
            _searchFocusNode.requestFocus();
          }
        });
      }
    });
  }

  void _closeDropdown() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
        _searchQuery = '';
        _searchCtrl.clear();
      });
    }
  }

  void _selectOption(CustomSelectOption<T>? opt) {
    widget.onChanged(opt?.value);
    _closeDropdown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEn = Localizations.localeOf(context).languageCode != 'ar';

    // Find currently selected option
    CustomSelectOption<T>? selectedOpt;
    for (final opt in widget.options) {
      if (opt.value == widget.selectedValue) {
        selectedOpt = opt;
        break;
      }
    }

    // Filter options
    final filtered = widget.options.where((opt) {
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.trim().toLowerCase();
      final nameEn = opt.labelEn.toLowerCase();
      final nameAr = (opt.labelAr ?? '').toLowerCase();
      return nameEn.contains(query) || nameAr.contains(query);
    }).toList();

    const primaryGreen = Color(0xFF10B981);
    final borderColor = _isOpen
        ? primaryGreen
        : (widget.errorText != null ? Colors.red : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)));
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final searchBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text.rich(
            TextSpan(
              text: widget.label!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
              children: [
                if (widget.isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
        ],

        // Main Wrapper
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: _isOpen ? 1.5 : 1.0),
            boxShadow: _isOpen
                ? [
                    BoxShadow(
                      color: primaryGreen.withValues(alpha: 0.15),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trigger Box
              InkWell(
                onTap: widget.enabled ? _toggleDropdown : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Selected Option Thumbnail or Icon
                      if (selectedOpt != null && selectedOpt.imageUrl != null && selectedOpt.imageUrl!.trim().isNotEmpty) ...[
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsetsDirectional.only(end: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: AppNetworkImage(
                              imageUrl: AppConfig.normalizeImageUrl(selectedOpt.imageUrl!),
                              fit: BoxFit.contain,
                              defaultFallbackIcon: Icons.storefront,
                            ),
                          ),
                        ),
                      ] else if (selectedOpt != null && selectedOpt.icon != null) ...[
                        Icon(selectedOpt.icon, size: 20, color: primaryGreen),
                        const SizedBox(width: 8),
                      ],

                      // Label / Placeholder
                      Expanded(
                        child: Text(
                          selectedOpt != null
                              ? selectedOpt.getLabel(isEn)
                              : widget.placeholder,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selectedOpt != null ? FontWeight.w600 : FontWeight.w500,
                            color: selectedOpt != null ? textColor : mutedColor,
                          ),
                        ),
                      ),

                      // Clear Button (if enabled)
                      if (widget.clearable && selectedOpt != null && widget.enabled) ...[
                        InkWell(
                          onTap: () {
                            widget.onChanged(null);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(Icons.close, size: 16, color: mutedColor),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],

                      // Chevron Icon
                      Icon(
                        _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 20,
                        color: _isOpen ? primaryGreen : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating / Expanded Dropdown Content
              if (_isOpen) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search Bar
                      if (widget.searchable && widget.options.length > 3) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: searchBgColor,
                            border: Border(
                              bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 18, color: mutedColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  focusNode: _searchFocusNode,
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                  style: TextStyle(fontSize: 13, color: textColor),
                                  decoration: InputDecoration(
                                    hintText: isEn ? 'Search options...' : 'بحث في الخيارات...',
                                    hintStyle: TextStyle(fontSize: 13, color: mutedColor),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                  ),
                                ),
                              ),
                              if (_searchCtrl.text.isNotEmpty)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _searchCtrl.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Icon(Icons.close, size: 16, color: mutedColor),
                                ),
                            ],
                          ),
                        ),
                      ],

                      // Options List
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: widget.maxHeight),
                        child: filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_off, size: 24, color: mutedColor),
                                    const SizedBox(height: 6),
                                    Text(
                                      isEn ? 'No matching options' : 'لا توجد خيارات مطابقة',
                                      style: TextStyle(fontSize: 12, color: mutedColor),
                                    ),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: filtered.map((opt) {
                                    final isSelected = opt.value == widget.selectedValue;

                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: opt.disabled ? null : () => _selectOption(opt),
                                        hoverColor: primaryGreen.withValues(alpha: 0.08),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? (isDark
                                                    ? primaryGreen.withValues(alpha: 0.2)
                                                    : const Color(0xFFECFDF5))
                                                : Colors.transparent,
                                          ),
                                          child: Row(
                                            children: [
                                              // Thumbnail / Icon
                                              if (opt.imageUrl != null && opt.imageUrl!.trim().isNotEmpty) ...[
                                                Container(
                                                  width: 22,
                                                  height: 22,
                                                  margin: const EdgeInsetsDirectional.only(end: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(
                                                      color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                                                    ),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(3),
                                                    child: AppNetworkImage(
                                                      imageUrl: AppConfig.normalizeImageUrl(opt.imageUrl!),
                                                      fit: BoxFit.contain,
                                                      defaultFallbackIcon: Icons.storefront,
                                                    ),
                                                  ),
                                                ),
                                              ] else if (opt.icon != null) ...[
                                                Icon(opt.icon, size: 18, color: isSelected ? primaryGreen : mutedColor),
                                                const SizedBox(width: 8),
                                              ],

                                              // Label
                                              Expanded(
                                                child: Text(
                                                  opt.getLabel(isEn),
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                    color: isSelected
                                                        ? primaryGreen
                                                        : (opt.disabled ? mutedColor : textColor),
                                                  ),
                                                ),
                                              ),

                                              // Checkmark on selected
                                              if (isSelected)
                                                const Icon(
                                                  Icons.check,
                                                  size: 18,
                                                  color: primaryGreen,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Error message if any
        if (widget.errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: const TextStyle(color: Colors.red, fontSize: 11),
          ),
        ],
      ],
    );
  }
}
