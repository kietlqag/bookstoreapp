import 'package:flutter/material.dart';

import 'app_colors.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    this.title,
    this.showBack = false,
    this.onBack,
    this.actions,
    this.onFavoriteTap,
    this.onNotificationTap,
    this.notificationCount,
    this.favoriteCount,
    this.backgroundGradient,
    this.backgroundColor,
    this.titleColor,
    this.iconColor,
    this.showDivider = true,
    this.middle,
    this.titleFlex = 2,
    this.middleFlex = 5,
    this.leadingSpacing = 0,
    this.horizontalPadding = 16,
    this.verticalPadding = 10,
    this.titlePadding = EdgeInsets.zero,
    this.titleSize,
  });

  final String? title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onNotificationTap;
  final int? notificationCount;
  final int? favoriteCount;
  final Gradient? backgroundGradient;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? iconColor;
  final bool showDivider;
  final Widget? middle;
  final int titleFlex;
  final int middleFlex;
  final double leadingSpacing;
  final double horizontalPadding;
  final double verticalPadding;
  final EdgeInsets titlePadding;
  final double? titleSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        gradient: backgroundGradient,
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.gray200))
            : null,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Row(
        children: [
          if (showBack && onBack != null)
            _IconButton(
              icon: Icons.arrow_back,
              onPressed: onBack!,
              iconColor: iconColor,
            ),
          if (showBack && onBack != null) const SizedBox(width: 12),
          if (title != null)
            Flexible(
              flex: titleFlex,
              child: Padding(
                padding: titlePadding,
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppColors.gray900,
                        fontSize: titleSize,
                      ),
                ),
              ),
            )
          else
            SizedBox(width: leadingSpacing),
          if (middle != null) ...[
            const SizedBox(width: 6),
            Expanded(flex: middleFlex, child: middle!),
            const SizedBox(width: 6),
          ],
          if (actions != null) ...[
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            ),
          ] else ...[
            const Spacer(),
            Row(
              children: [
                _NotificationButton(
                  iconColor: iconColor,
                  count: notificationCount ?? 0,
                  onPressed: onNotificationTap,
                ),
                SizedBox(width: 6),
                _FavoriteButton(
                  iconColor: iconColor,
                  count: favoriteCount ?? 0,
                  onPressed: onFavoriteTap,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    this.onPressed,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? AppColors.gray700,
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    this.iconColor,
    this.count = 0,
    this.onPressed,
  });

  final Color? iconColor;
  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _IconButton(
          icon: Icons.notifications_none,
          iconColor: iconColor,
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 2,
            top: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
              constraints: const BoxConstraints(minWidth: 12),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.orange600,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    this.iconColor,
    this.count = 0,
    this.onPressed,
  });

  final Color? iconColor;
  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _IconButton(
          icon: Icons.favorite_border,
          iconColor: iconColor,
          onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 2,
            top: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
              ),
              constraints: const BoxConstraints(minWidth: 12),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.orange600,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

