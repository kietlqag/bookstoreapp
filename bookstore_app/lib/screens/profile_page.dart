import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:characters/characters.dart';

import '../models/profile_service.dart';
import '../models/profile_summary.dart';
import 'edit_profile_page.dart';
import 'order_list_page.dart';
import 'review_list_page.dart';
import 'settings_notification_page.dart';
import 'settings_help_page.dart';
import 'settings_privacy_page.dart';
import '../widgets/app_colors.dart';
import '../utils/config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.onLogout,
    required this.userId,
    required this.token,
    this.reloadNotifier,
  });

  final VoidCallback onLogout;
  final int userId;
  final String token;
  final ValueNotifier<bool>? reloadNotifier;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileService _profileService =
      ProfileService(baseUrl: _resolveBaseUrl());
  ProfileSummary? _summary;
  bool _loading = false;
  String? _error;

  static String _resolveBaseUrl() {
    return AppConfig.getBaseUrlSync();
  }

  @override
  void initState() {
    super.initState();
    _loadSummary();
    // Listen to reload notifier if provided
    widget.reloadNotifier?.addListener(_onReloadRequested);
  }
  
  @override
  void dispose() {
    widget.reloadNotifier?.removeListener(_onReloadRequested);
    super.dispose();
  }
  
  void _onReloadRequested() {
    if (mounted) {
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    if (widget.userId <= 0) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _profileService.fetchProfileSummary(widget.userId);
      if (!mounted) return;
      setState(() {
        _summary = summary;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  String _formatCompactAmount(double value) {
    if (value >= 1000000) {
      final display = value / 1000000;
      final digits = display >= 10 || display % 1 == 0 ? 0 : 1;
      return '${display.toStringAsFixed(digits)}tr';
    }
    if (value >= 1000) {
      final display = value / 1000;
      final digits = display >= 10 || display % 1 == 0 ? 0 : 1;
      return '${display.toStringAsFixed(digits)}k';
    }
    return value.toStringAsFixed(0);
  }

  String _resolveRankLabel(double totalSpend) {
    if (totalSpend >= 5000000) return 'Kim cương';
    if (totalSpend >= 2000000) return 'Vàng';
    if (totalSpend >= 500000) return 'Bạc';
    return 'Đồng';
  }

  Color _resolveRankColor(String label) {
    switch (label) {
      case 'Kim cương':
        return AppColors.teal600;
      case 'Bạc':
        return AppColors.gray400;
      case 'Đồng':
        return AppColors.bronze;
      default:
        return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final displayName =
        summary?.fullName.isNotEmpty == true ? summary!.fullName : 'Khách hàng';
    final displayEmail =
        summary?.email.isNotEmpty == true ? summary!.email : 'Chưa có email';
    final orderCount = summary?.orderCount ?? 0;
    final monthlySpend = (summary?.monthlySpend ?? 0.0).toStringAsFixed(0);
    final rankLabel = _resolveRankLabel(summary?.totalSpend ?? 0.0);
    final rankColor = _resolveRankColor(rankLabel);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.orange600, AppColors.rose500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: _AvatarCircle(
                                avatarUrl: summary?.avatar ?? '',
                                fullName: displayName,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: summary == null
                                    ? null
                                    : () async {
                                        final updated =
                                            await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute<bool>(
                                            builder: (_) => EditProfilePage(
                                              userId: widget.userId,
                                              profile: summary,
                                            ),
                                          ),
                                        );
                                        if (updated == true) {
                                          _loadSummary();
                                        }
                                      },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 12,
                                    color: AppColors.orange600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayEmail,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: rankColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  rankLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileStat(
                            value: orderCount.toString(),
                            label: 'Đơn hàng đã mua',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfileStat(
                            value: '$monthlySpend VND',
                            label: 'Mua tháng',
                          ),
                        ),
                      ],
                    ),
                    if (_loading || _error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _loading
                            ? 'Đang tải thông tin...'
                            : 'Không tải được hồ sơ',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => OrderListPage(
                                userId: widget.userId,
                                initialTabIndex: 0,
                              ),
                            ),
                          );
                          // Reload summary when returning to update badge counts
                          if (mounted) {
                            _loadSummary();
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                'Đơn mua',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                'Xem lịch sử mua hàng',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.gray600,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 10,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppColors.gray600,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _OrderStatusItem(
                            icon: Icons.assignment_outlined,
                            label: 'Chờ xác nhận',
                            badgeCount: summary?.pendingCount ?? 0,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => OrderListPage(
                                    userId: widget.userId,
                                    initialTabIndex: 0,
                                  ),
                                ),
                              );
                            },
                          ),
                          _OrderStatusItem(
                            icon: Icons.inventory_2_outlined,
                            label: 'Chờ lấy hàng',
                            badgeCount: summary?.waitingPickupCount ?? 0,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => OrderListPage(
                                    userId: widget.userId,
                                    initialTabIndex: 1,
                                  ),
                                ),
                              );
                            },
                          ),
                          _OrderStatusItem(
                            icon: Icons.local_shipping_outlined,
                            label: 'Chờ giao hàng',
                            badgeCount: summary?.shippingCount ?? 0,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => OrderListPage(
                                    userId: widget.userId,
                                    initialTabIndex: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                          _OrderStatusItem(
                            icon: Icons.star_border,
                            label: 'Đánh giá',
                            badgeCount: summary?.reviewPendingCount ?? 0,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => ReviewListPage(
                                    userId: widget.userId,
                                    initialIndex: 0,
                                  ),
                                ),
                              );
                              // Reload summary when returning to update badge counts
                              if (mounted) {
                                _loadSummary();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Cài đặt',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _SettingsTile(
                        title: 'Thông báo',
                        icon: Icons.notifications_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsNotificationPage(),
                          ),
                        ),
                      ),
                      _SettingsTile(
                        title: 'Trợ giúp & hỗ trợ',
                        icon: Icons.help_outline,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsHelpPage(userId: widget.userId),
                          ),
                        ),
                      ),
                      _SettingsTile(
                        title: 'Quyền riêng tư & bảo mật',
                        icon: Icons.security_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsPrivacyPage(
                              userId: widget.userId,
                              token: widget.token,
                              onLogout: widget.onLogout,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusItem extends StatelessWidget {
  const _OrderStatusItem({
    required this.icon,
    required this.label,
    this.badgeCount,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int? badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: AppColors.gray700, size: 22),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeCount!.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.gray700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.avatarUrl,
    required this.fullName,
  });

  final String avatarUrl;
  final String fullName;

  String _initials() {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = avatarUrl.trim();
    if (trimmed.startsWith('data:image')) {
      final base64Part = trimmed.split(',').last;
      try {
        final bytes = base64Decode(base64Part);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return _AvatarFallback(initial: _initials());
      }
    }
    if (trimmed.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          trimmed,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _AvatarFallback(initial: _initials()),
        ),
      );
    }
    return _AvatarFallback(initial: _initials());
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.orange600,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gray600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray600),
          ],
        ),
      ),
    );
  }
}







