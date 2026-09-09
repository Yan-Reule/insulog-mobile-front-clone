import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

enum AppNotificationType { success, error, warning, info }

class AppNotification {
  AppNotification._();

  static Future<void> success(BuildContext context, String message) {
    return _show(context, message, AppNotificationType.success);
  }

  static Future<void> error(BuildContext context, String message) {
    return _show(context, message, AppNotificationType.error);
  }

  static Future<void> warning(BuildContext context, String message) {
    return _show(context, message, AppNotificationType.warning);
  }

  static Future<void> info(BuildContext context, String message) {
    return _show(context, message, AppNotificationType.info);
  }

  static Future<void> _show(
    BuildContext context,
    String message,
    AppNotificationType type,
  ) async {
    final style = _NotificationStyle.from(type);

    await Flushbar<void>(
      flushbarPosition: FlushbarPosition.TOP,
      flushbarStyle: FlushbarStyle.FLOATING,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      maxWidth: 520,
      borderRadius: BorderRadius.circular(12),
      backgroundColor: style.color,
      boxShadows: [
        BoxShadow(
          color: style.color.withValues(alpha: 0.22),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      icon: Icon(style.icon, color: Colors.white, size: 20),
      shouldIconPulse: false,
      message: message,
      messageColor: Colors.white,
      messageSize: 14,
      duration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 260),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      dismissDirection: FlushbarDismissDirection.VERTICAL,
      isDismissible: true,
    ).show(context);
  }
}

class _NotificationStyle {
  const _NotificationStyle({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  factory _NotificationStyle.from(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.success => const _NotificationStyle(
        color: Color(0xFF3EA75F),
        icon: Icons.check_circle_outline_rounded,
      ),
      AppNotificationType.error => const _NotificationStyle(
        color: Color(0xFFD84A4A),
        icon: Icons.error_outline_rounded,
      ),
      AppNotificationType.warning => const _NotificationStyle(
        color: Color(0xFFE59A23),
        icon: Icons.warning_amber_rounded,
      ),
      AppNotificationType.info => const _NotificationStyle(
        color: Color(0xFF3F7FC4),
        icon: Icons.info_outline_rounded,
      ),
    };
  }
}
