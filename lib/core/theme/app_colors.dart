import 'package:flutter/material.dart';

/// Semantic colours for product status, stock state and destructive actions.
///
/// Every pair is chosen so the foreground reads clearly on the background
/// (spec section 31). Colour is never the only signal — the status widgets
/// also render text, so the meaning survives greyscale or colour blindness.
class AppColors {
  const AppColors._();

  // --- Positive / active -------------------------------------------
  static const Color successForeground = Color(0xFF0F5132);
  static const Color successBackground = Color(0xFFD1E7DD);

  // --- Warning / low stock -----------------------------------------
  static const Color warningForeground = Color(0xFF7A4F01);
  static const Color warningBackground = Color(0xFFFFF3CD);

  // --- Negative / out of stock / destructive -----------------------
  static const Color dangerForeground = Color(0xFFA52834);
  static const Color dangerBackground = Color(0xFFF8D7DA);

  // --- Neutral / inactive ------------------------------------------
  static const Color neutralForeground = Color(0xFF48505A);
  static const Color neutralBackground = Color(0xFFE9ECEF);

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

/// Layout breakpoints used by the responsive product list.
class AppBreakpoints {
  const AppBreakpoints._();

  /// Below this width the product table becomes a card list.
  static const double tableMinWidth = 900;

  /// Below this width filter controls stack vertically.
  static const double filterRowMinWidth = 720;
}
