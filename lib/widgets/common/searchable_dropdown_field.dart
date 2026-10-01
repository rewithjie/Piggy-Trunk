import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Item definition for SearchableDropdownField
class SearchableDropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final String? badge;
  final Color? badgeColor;
  final IconData? icon;
  final Color? iconColor;
  final bool isEnabled;
  final String? disabledTooltip;
  final String? searchKeywords;

  const SearchableDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.badge,
    this.badgeColor,
    this.icon,
    this.iconColor,
    this.isEnabled = true,
    this.disabledTooltip,
    this.searchKeywords,
  });
}

/// A modern, searchable dropdown / combobox field tailored for PiggyTrunk Admin Web & Mobile.
/// Allows typing to filter in real-time, displays badges & status icons, and supports keyboard navigation.
class SearchableDropdownField<T> extends StatefulWidget {
  final T? value;
  final List<SearchableDropdownItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final String searchHintText;
  final bool isDark;
  final Color? fieldBg;
  final Color? fieldBorder;
  final Color? fieldFocus;
  final Color? fieldText;
  final Color? mutedColor;
  final Color? cardBg;
  final Color? cardBorder;
  final bool enabled;
  final IconData? defaultPrefixIcon;
  final double maxMenuHeight;
  final bool showClearButton;
  final T? unassignedValue;
  final String? Function(T?)? validator;

  const SearchableDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.searchHintText = 'Type to search...',
    this.isDark = false,
    this.fieldBg,
    this.fieldBorder,
    this.fieldFocus,
    this.fieldText,
    this.mutedColor,
    this.cardBg,
    this.cardBorder,
    this.enabled = true,
    this.defaultPrefixIcon,
    this.maxMenuHeight = 320,
    this.showClearButton = true,
    this.unassignedValue,
    this.validator,
  });

  @override
  State<SearchableDropdownField<T>> createState() => _SearchableDropdownFieldState<T>();
}

class _SearchableDropdownFieldState<T> extends State<SearchableDropdownField<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  Color get _bg => widget.fieldBg ?? (widget.isDark ? const Color(0xFF1A2B44) : const Color(0xFFF5F8FE));
  Color get _border => widget.fieldBorder ?? (widget.isDark ? const Color(0xFF28405D) : const Color(0xFFC9D8EC));
  Color get _focus => widget.fieldFocus ?? (widget.isDark ? const Color(0xFF88A7CE) : const Color(0xFF315C8F));
  Color get _text => widget.fieldText ?? (widget.isDark ? Colors.white : const Color(0xFF18314F));
  Color get _muted => widget.mutedColor ?? (widget.isDark ? const Color(0xFF9AB1CB) : const Color(0xFF6F8096));
  Color get _menuBg => widget.cardBg ?? (widget.isDark ? const Color(0xFF132238) : Colors.white);
  Color get _menuBorder => widget.cardBorder ?? (widget.isDark ? const Color(0xFF28405D) : const Color(0xFFD7E3F3));

  SearchableDropdownItem<T>? get _selectedItem {
    try {
      return widget.items.firstWhere((item) => item.value == widget.value);
    } catch (_) {
      return null;
    }
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (_isOpen) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final spaceBelow = screenHeight - (offset.dy + size.height) - mediaQuery.viewInsets.bottom;
    final openUpwards = spaceBelow < 260 && offset.dy > spaceBelow;

    setState(() => _isOpen = true);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Barrier to detect outside clicks
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Floating Dropdown Menu
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: openUpwards
                    ? Offset(0, -widget.maxMenuHeight - 8)
                    : Offset(0, size.height + 6),
                child: Material(
                  color: Colors.transparent,
                  child: _DropdownMenuContent<T>(
                    items: widget.items,
                    selectedValue: widget.value,
                    searchHintText: widget.searchHintText,
                    isDark: widget.isDark,
                    menuBg: _menuBg,
                    menuBorder: _menuBorder,
                    fieldText: _text,
                    mutedColor: _muted,
                    accentColor: _focus,
                    maxHeight: widget.maxMenuHeight,
                    onSelect: (val) {
                      widget.onChanged(val);
                      _closeDropdown();
                    },
                    onClose: _closeDropdown,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem;
    final isUnassigned = widget.unassignedValue != null && widget.value == widget.unassignedValue;
    final hasSelection = selected != null && !isUnassigned;

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: widget.enabled ? _toggleDropdown : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.enabled ? _bg : _bg.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isOpen ? _focus : _border,
              width: _isOpen ? 1.5 : 1.0,
            ),
            boxShadow: _isOpen
                ? [
                    BoxShadow(
                      color: _focus.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Prefix icon
              Icon(
                selected?.icon ?? widget.defaultPrefixIcon ?? Icons.arrow_drop_down_circle_outlined,
                size: 18,
                color: isUnassigned
                    ? _muted
                    : (selected?.iconColor ??
                        (widget.isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)),
              ),
              const SizedBox(width: 10),

              // Selected text & badge
              Expanded(
                child: selected != null
                    ? Row(
                        children: [
                          Flexible(
                            child: Text(
                              selected.label,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: isUnassigned ? _muted : _text,
                                fontSize: 13.5,
                                fontWeight: isUnassigned ? FontWeight.w500 : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (selected.badge != null && selected.badge!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: widget.isDark
                                    ? const Color(0xFF1E293B)
                                    : (selected.badgeColor ?? PiggyTrunkTheme.ptPrimary).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: widget.isDark
                                      ? const Color(0xFF334155)
                                      : (selected.badgeColor ?? PiggyTrunkTheme.ptPrimary).withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                selected.badge!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isDark
                                      ? const Color(0xFFE2E8F0)
                                      : (selected.badgeColor ?? PiggyTrunkTheme.ptPrimary),
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    : Text(
                        widget.hintText ?? 'Select...',
                        style: GoogleFonts.plusJakartaSans(
                          color: _muted,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),

              // Quick Clear button if something is selected
              if (widget.showClearButton && hasSelection && widget.enabled && widget.unassignedValue != null)
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 16, color: _muted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  splashRadius: 16,
                  tooltip: 'Reset to unassigned',
                  onPressed: () {
                    widget.onChanged(widget.unassignedValue);
                  },
                ),

              const SizedBox(width: 4),

              // Dropdown chevron arrow
              Icon(
                _isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: _isOpen ? _focus : _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownMenuContent<T> extends StatefulWidget {
  final List<SearchableDropdownItem<T>> items;
  final T? selectedValue;
  final String searchHintText;
  final bool isDark;
  final Color menuBg;
  final Color menuBorder;
  final Color fieldText;
  final Color mutedColor;
  final Color accentColor;
  final double maxHeight;
  final ValueChanged<T> onSelect;
  final VoidCallback onClose;

  const _DropdownMenuContent({
    required this.items,
    required this.selectedValue,
    required this.searchHintText,
    required this.isDark,
    required this.menuBg,
    required this.menuBorder,
    required this.fieldText,
    required this.mutedColor,
    required this.accentColor,
    required this.maxHeight,
    required this.onSelect,
    required this.onClose,
  });

  @override
  State<_DropdownMenuContent<T>> createState() => _DropdownMenuContentState<T>();
}

class _DropdownMenuContentState<T> extends State<_DropdownMenuContent<T>> {
  late final TextEditingController _searchCtrl;
  late final FocusNode _searchFocusNode;
  final ScrollController _scrollCtrl = ScrollController();
  String _query = '';
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _searchFocusNode = FocusNode(onKeyEvent: _handleSearchKeyEvent);

    // Auto-focus the search bar immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<SearchableDropdownItem<T>> get _filteredItems {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((item) {
      final labelMatch = item.label.toLowerCase().contains(q);
      final subMatch = item.subtitle?.toLowerCase().contains(q) ?? false;
      final badgeMatch = item.badge?.toLowerCase().contains(q) ?? false;
      final keyMatch = item.searchKeywords?.toLowerCase().contains(q) ?? false;
      return labelMatch || subMatch || badgeMatch || keyMatch;
    }).toList();
  }

  KeyEventResult _handleSearchKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final filtered = _filteredItems;
    if (filtered.isEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.onClose();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _focusedIndex = (_focusedIndex + 1).clamp(0, filtered.length - 1);
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _focusedIndex = (_focusedIndex - 1).clamp(0, filtered.length - 1);
      });
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_focusedIndex >= 0 && _focusedIndex < filtered.length) {
        final item = filtered[_focusedIndex];
        if (item.isEnabled) {
          widget.onSelect(item.value);
        }
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      decoration: BoxDecoration(
        color: widget.menuBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.menuBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.5 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input Header
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : const Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(
                    color: widget.menuBorder.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFF1E324F)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isDark
                        ? const Color(0xFF334F73)
                        : const Color(0xFFCBD5E1),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocusNode,
                        style: GoogleFonts.plusJakartaSans(
                          color: widget.fieldText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.searchHintText,
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: widget.mutedColor.withValues(alpha: 0.8),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
                        onChanged: (text) {
                          setState(() {
                            _query = text.trim();
                            _focusedIndex = 0;
                          });
                        },
                        onSubmitted: (_) {
                          if (filtered.isNotEmpty) {
                            final enabledItem = filtered.firstWhere((i) => i.isEnabled, orElse: () => filtered.first);
                            if (enabledItem.isEnabled) {
                              widget.onSelect(enabledItem.value);
                            }
                          }
                        },
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchCtrl.clear();
                            _query = '';
                            _focusedIndex = 0;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: widget.mutedColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: widget.mutedColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),



            // Items List or Empty View
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: widget.mutedColor.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search_off_rounded,
                              size: 26,
                              color: widget.mutedColor.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No matching raisers found for "$_query"',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: widget.fieldText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try searching with a different name or keyword',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: widget.mutedColor,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = item.value == widget.selectedValue;
                        final isKeyboardFocused = index == _focusedIndex;
                        final iconCol = !item.isEnabled
                            ? widget.mutedColor.withValues(alpha: 0.5)
                            : (item.iconColor ??
                                (isSelected
                                    ? (widget.isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
                                    : (widget.isDark ? const Color(0xFFCBD5E1) : PiggyTrunkTheme.ptPrimary)));

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: item.isEnabled ? () => widget.onSelect(item.value) : null,
                            borderRadius: BorderRadius.circular(10),
                            hoverColor: widget.accentColor.withValues(alpha: 0.08),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (widget.isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFE8F1FC))
                                    : (isKeyboardFocused
                                        ? widget.accentColor.withValues(alpha: 0.08)
                                        : Colors.transparent),
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected
                                    ? Border.all(
                                        color: widget.isDark
                                            ? const Color(0xFF475569)
                                            : PiggyTrunkTheme.ptPrimary.withValues(alpha: 0.4),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  // Left Icon Badge / Avatar
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: iconCol.withValues(alpha: widget.isDark ? 0.16 : 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      item.icon ?? Icons.person_outline_rounded,
                                      size: 16,
                                      color: iconCol,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Main Label and Subtitle/Notice
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.label,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: !item.isEnabled
                                                ? widget.mutedColor.withValues(alpha: 0.55)
                                                : (isSelected
                                                    ? (widget.isDark ? Colors.white : PiggyTrunkTheme.ptPrimary)
                                                    : widget.fieldText),
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          ),
                                        ),
                                        if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.subtitle!,
                                            style: GoogleFonts.plusJakartaSans(
                                              color: !item.isEnabled
                                                  ? widget.mutedColor.withValues(alpha: 0.5)
                                                  : widget.mutedColor,
                                              fontSize: 11.5,
                                              fontStyle: item.isEnabled ? FontStyle.normal : FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Badge (e.g. Batch name or status)
                                  if (item.badge != null && item.badge!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: item.badgeColor?.withValues(alpha: widget.isDark ? 0.18 : 0.12) ??
                                            (widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: item.badgeColor?.withValues(alpha: 0.3) ??
                                              (widget.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        item.badge!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: item.badgeColor ??
                                              (widget.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Right Indicator (Checkmark if selected, lock if disabled)
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: widget.isDark
                                            ? Colors.white.withValues(alpha: 0.15)
                                            : PiggyTrunkTheme.ptPrimary.withValues(alpha: 0.18),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 13,
                                        color: widget.isDark ? Colors.white : PiggyTrunkTheme.ptPrimary,
                                      ),
                                    ),
                                  ] else if (!item.isEnabled) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.lock_outline_rounded,
                                      size: 14,
                                      color: widget.mutedColor.withValues(alpha: 0.5),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
