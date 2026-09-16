import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppToast {
  static void showError(
    BuildContext context,
    dynamic error, {
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = _parseErrorMessage(error);
    _show(
      context: context,
      title: title ?? 'Authentication Error',
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: const Color(0xFF1E1014),
      borderColor: AppColors.error.withValues(alpha: 0.5),
      iconColor: AppColors.error,
      duration: duration,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      title: title ?? 'Success',
      message: message,
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: const Color(0xFF0D1E16),
      borderColor: AppColors.success.withValues(alpha: 0.5),
      iconColor: AppColors.success,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      title: title ?? 'Notice',
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: const Color(0xFF0F1829),
      borderColor: AppColors.primaryLight.withValues(alpha: 0.5),
      iconColor: AppColors.goldLight,
      duration: duration,
    );
  }

  static void _show({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color borderColor,
    required Color iconColor,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        duration: duration,
        width: isDesktop ? 440 : null,
        margin: isDesktop ? null : const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _parseErrorMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred.';
    final raw = error.toString();

    // Map common Firebase auth errors to friendly user-facing messages
    if (raw.contains('invalid-credential') ||
        raw.contains('wrong-password') ||
        raw.contains('user-not-found')) {
      return 'Incorrect email or password. Please verify and try again.';
    }
    if (raw.contains('popup-closed-by-user')) {
      return 'Google sign-in popup was closed before completing.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Unable to connect. Please check your internet connection.';
    }
    if (raw.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'An account already exists with this email. Please sign in.';
    }
    if (raw.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password.';
    }
    if (raw.contains('user-disabled')) {
      return 'This account has been disabled. Please contact an administrator.';
    }
    if (raw.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled. Please contact support.';
    }

    // Strip [firebase_auth/...] tags if present
    final cleaned = raw.replaceAll(RegExp(r'\[.*?\]\s*'), '').trim();
    if (cleaned.startsWith('Exception:')) {
      return cleaned.substring(10).trim();
    }
    return cleaned.isNotEmpty ? cleaned : 'An error occurred. Please try again.';
  }
}
