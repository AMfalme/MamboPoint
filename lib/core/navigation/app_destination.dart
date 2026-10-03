import 'package:flutter/material.dart';

/// The top-level destinations of MamboPoint POS.
///
/// Only Products is built so far; the rest are declared here so the sidebar
/// renders the real information architecture of the product rather than a
/// placeholder, and each one can raise its own "not built yet" explanation
/// instead of looking dead.
enum AppDestination {
  dashboard(label: 'Dashboard', icon: Icons.grid_view_rounded),
  products(label: 'Products', icon: Icons.widgets_outlined),
  customers(label: 'Customers', icon: Icons.people_outline_rounded),
  sales(label: 'Sales', icon: Icons.show_chart_rounded),
  settings(label: 'Settings', icon: Icons.settings_outlined);

  const AppDestination({required this.label, required this.icon});

  /// Text shown in the sidebar and in tooltips when collapsed.
  final String label;

  final IconData icon;
}
