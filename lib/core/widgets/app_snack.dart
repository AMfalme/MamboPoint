import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Consistent success/error/info feedback (spec section 29).
///
/// Uses a Material [SnackBar] so the same mechanism works on Android, web and
/// desktop, and never a browser alert. Messages are expected to be the
/// user-safe strings produced by `mapError`.
class AppSnack {
  const AppSnack._();

  static void success(BuildContext context, String message) => _show(
    context,
    message,
    background: AppColors.successBackground,
    foreground: AppColors.successForeground,
    icon: Icons.check_circle_outline,
  );

  static void error(BuildContext context, String message) => _show(
    context,
    message,
    background: AppColors.dangerBackground,
    foreground: AppColors.dangerForeground,
    icon: Icons.error_outline,
  );

  static void info(BuildContext context, String message) => _show(
    context,
    message,
    background: AppColors.infoBackground,
    foreground: AppColors.infoForeground,
    icon: Icons.info_outline,
  );

  static void _show(
    BuildContext context,
    String message, {
    required Color background,
    required Color foreground,
    required IconData icon,
  }) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: background,
          content: Row(
            children: <Widget>[
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
