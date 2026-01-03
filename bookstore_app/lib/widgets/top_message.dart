import 'package:flutter/material.dart';

import 'app_colors.dart';

enum TopMessageType { info, success, error }

void showTopMessage(
  BuildContext context, {
  required String message,
  TopMessageType type = TopMessageType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;

  final entry = OverlayEntry(
    builder: (context) => _TopMessageEntry(message: message, type: type),
  );

  overlay.insert(entry);
  Future.delayed(duration, () {
    if (entry.mounted) {
      entry.remove();
    }
  });
}

class _TopMessageEntry extends StatelessWidget {
  const _TopMessageEntry({
    required this.message,
    required this.type,
  });

  final String message;
  final TopMessageType type;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final theme = Theme.of(context);

    Color background;
    IconData icon;
    switch (type) {
      case TopMessageType.success:
        background = AppColors.orange600;
        icon = Icons.check_circle_outline;
        break;
      case TopMessageType.error:
        background = AppColors.rose500;
        icon = Icons.error_outline;
        break;
      case TopMessageType.info:
      default:
        background = AppColors.gray900;
        icon = Icons.info_outline;
    }

    return Positioned(
      top: padding.top + 12,
      left: 16,
      right: 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * -12),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
