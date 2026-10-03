import 'package:flutter/material.dart';

/// The top-level destinations of MamboPoint POS.
///
/// Only Products is built so far; the rest are declared here so the sidebar
/// renders the real information architecture of the product rather than a
/// placeholder, and each one can raise its own "not built yet" explanation
/// instead of looking dead.
enum AppDestination {
  // Deliberately not Icons.grid_view_rounded: that glyph is the product list's
  // own grid/table toggle, and reusing it here made two different controls
  // indistinguishable.
  dashboard(label: 'Dashboard', icon: Icons.dashboard_outlined),
  products(label: 'Products', icon: Icons.widgets_outlined),
  customers(label: 'Customers', icon: Icons.people_outline_rounded),
  sales(label: 'Sales', icon: Icons.show_chart_rounded),
  settings(label: 'Settings', icon: Icons.settings_outlined);

  const AppDestination({required this.label, required this.icon});

  /// Text shown in the sidebar and in tooltips when collapsed.
  final String label;

  final IconData icon;
}
