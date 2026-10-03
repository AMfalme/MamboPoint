import 'package:flutter/material.dart';

/// Semantic colours for product status, stock state and destructive actions.
///
/// Every pair is chosen so the foreground reads clearly on the background
/// (spec section 31). Colour is never the only signal — the status widgets
/// also render text, so the meaning survives greyscale or colour blindness.
class AppColors {
  const AppColors._();

  // --- Brand identity -------------------------------------------------
  // Taken straight from the MamboPoint POS logo so the interface, the mark and
  // the wordmark always read as one system.
  /// Deep teal: the wordmark ink and the dark end of the mark gradient.
  static const Color brandTeal = Color(0xFF0E6F6C);

  /// Mint: the light end of the mark gradient and the POS accent.
  static const Color brandMint = Color(0xFF63E6B3);

  /// Darkest teal, used for gradients and hover states on the mark.
  static const Color brandTealDeep = Color(0xFF0A4F4D);

  // --- Positive / active -------------------------------------------
  // Muted enterprise tones: calm on white, text still passes contrast.
  static const Color successForeground = Color(0xFF1B6B3A);
  static const Color successBackground = Color(0xFFE5F2E8);

  // --- Warning / low stock -----------------------------------------
  static const Color warningForeground = Color(0xFF7A4D00);
  static const Color warningBackground = Color(0xFFFBF0D3);

  // --- Negative / out of stock / destructive -----------------------
  static const Color dangerForeground = Color(0xFF9E2B25);
  static const Color dangerBackground = Color(0xFFF9E3E0);

  // --- Neutral / inactive ------------------------------------------
  static const Color neutralForeground = Color(0xFF5B6470);
  static const Color neutralBackground = Color(0xFFEEF1F4);

  // --- Informational ------------------------------------------------
  static const Color infoForeground = Color(0xFF0B5394);
  static const Color infoBackground = Color(0xFFD6E6F7);
}

/// Consistent spacing scale. Using a scale rather than ad-hoc numbers is what
/// makes the interface feel deliberate (spec section 3).
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Standard padding for page bodies and cards.
  static const EdgeInsets pagePadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}

/// How the product list is laid out.
///
/// Grid is the merchandising view a shopkeeper scans at the till; table is the
/// dense view for working through stock, pricing and metadata. The choice is
/// presentation only — it never affects which products are loaded or filtered.
enum ProductViewMode { grid, table }

/// Layout breakpoints used by the responsive product list.
///
/// Grid and table are both offered on every screen that has room; on a phone the
/// grid wins because a table cannot fit, and the toggle is hidden rather than
/// offering a mode that would not render.
class AppBreakpoints {
  const AppBreakpoints._();

  /// Below this width the product table becomes a card list.
  static const double tableMinWidth = 900;

  /// Below this width filter controls stack vertically.
  static const double filterRowMinWidth = 720;

  /// Below this width the header stacks and the brand lockup goes compact.
  static const double headerStackWidth = 560;

  /// Below this width the grid would be cramped, so the stacked card list is
  /// used instead.
  static const double gridMinWidth = 520;

  // --- POS shell ------------------------------------------------------
  // The sidebar and the transaction panel are optional furniture around the
  // product list, so each one has a width at which it stops being affordable.

  /// Below this width the navigation sidebar defaults to its icon rail rather
  /// than taking a readable slice out of the product grid. An explicit toggle
  /// always wins over this default.
  static const double sidebarRailWidth = 1000;

  /// Below this width the transaction panel floats over the content instead of
  /// sitting in the layout beside it, so the grid keeps the full width.
  static const double transactionInlineMinWidth = 900;

  /// Standard width of the expanded sidebar.
  static const double sidebarWidth = 236;

  /// Width of the collapsed sidebar: icons plus padding.
  static const double sidebarRailWidthCollapsed = 72;

  /// Standard width of the expanded transaction panel.
  static const double transactionWidth = 340;

  /// Width of the collapsed transaction panel rail.
  static const double transactionRailWidth = 60;
}
