import 'package:flutter/material.dart';

class FilterableMultiSelectWidget<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) labelBuilder;
  final bool Function(T) isSelected;
  final void Function(T, bool) onToggle;
  final String hintText;

  const FilterableMultiSelectWidget({
    super.key,
    required this.items,
    required this.labelBuilder,
    required this.isSelected,
    required this.onToggle,
    this.hintText = 'Cerca...',
  });

  @override
  State<FilterableMultiSelectWidget<T>> createState() =>
      _FilterableMultiSelectWidgetState<T>();
}

class _FilterableMultiSelectWidgetState<T>
    extends State<FilterableMultiSelectWidget<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController =
      ScrollController(); // Add controller
  bool _isExpanded = false;
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant FilterableMultiSelectWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always re-filter/sort because parent might have updated selection state
    _onSearchChanged();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose(); // Dispose controller
    super.dispose();
  }

  // ... (existing methods _onSearchChanged, _onFocusChanged, _toggleExpanded) ...

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        final label = widget.labelBuilder(item).toLowerCase();
        return label.startsWith(query);
      }).toList();

      // Sort: Selected first, then alphabetical (stable-ish)
      _filteredItems.sort((a, b) {
        final aSelected = widget.isSelected(a);
        final bSelected = widget.isSelected(b);
        if (aSelected != bSelected) {
          return aSelected ? -1 : 1;
        }
        // Secondary sort by label for consistency
        return widget.labelBuilder(a).compareTo(widget.labelBuilder(b));
      });
    });
  }

  void _onFocusChanged() {
    setState(() {
      if (_focusNode.hasFocus) {
        _isExpanded = true;
      }
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _focusNode.requestFocus();
      } else {
        _focusNode.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Bar with Toggle Icon
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.hintText,
            hintText: 'Digita per filtrare...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: _toggleExpanded,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onTap: () {
            setState(() {
              _isExpanded = true;
            });
          },
        ),

        const SizedBox(height: 8),

        // Dropdown List (Visible only when expanded)
        if (_isExpanded)
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _filteredItems.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Nessun risultato trovato.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController, // Attach controller
                    thumbVisibility: true,
                    child: ListView.separated(
                      controller: _scrollController, // Attach same controller
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredItems.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = widget.isSelected(item);
                        final label = widget.labelBuilder(item);

                        return ListTile(
                          title: Text(label),
                          trailing: Switch(
                            value: isSelected,
                            onChanged: (val) => widget.onToggle(item, val),
                          ),
                          onTap: () {
                            widget.onToggle(item, !isSelected);
                          },
                          tileColor: isSelected ? Colors.blue.shade50 : null,
                        );
                      },
                    ),
                  ),
          ),
      ],
    );
  }
}
