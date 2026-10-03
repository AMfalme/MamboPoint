import 'package:flutter/material.dart';

/// The product search box (spec section 11).
///
/// The parent owns the [controller] so it can clear the field from elsewhere
/// (for example the "clear search" action in the no-results empty state), and
/// the parent also owns debouncing — the notifier decides how aggressively to
/// query, which keeps that policy out of the widget tree.
class SearchInput extends StatelessWidget {
  const SearchInput({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search products by name, SKU or barcode...',
    this.enabled = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      enabled: enabled,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      // Searching happens as the user types, so the field never needs to
      // demand a submit (spec section 11).
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (BuildContext context, TextEditingValue value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Clear search',
              icon: const Icon(Icons.close),
              onPressed: enabled
                  ? () {
                      controller.clear();
                      onChanged('');
                    }
                  : null,
            );
          },
        ),
      ),
    );
  }
}
