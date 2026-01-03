import 'package:flutter/material.dart';

import '../widgets/app_colors.dart';
import '../widgets/header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      _ProfileMenuItem(
        icon: Icons.shopping_bag_outlined,
        label: 'Đơn hàng',
        description: 'Xem tất cả đơn',
        color: const Color(0xFFDBEAFE),
        iconColor: const Color(0xFF2563EB),
      ),
      _ProfileMenuItem(
        icon: Icons.favorite_border,
        label: 'Yêu thích',
        description: 'Sách đã lưu',
        color: const Color(0xFFFEE2E2),
        iconColor: const Color(0xFFDC2626),
      ),
      _ProfileMenuItem(
        icon: Icons.location_on_outlined,
        label: 'Địa chỉ',
        description: 'Địa chỉ đã lưu',
        color: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
      ),
      _ProfileMenuItem(
        icon: Icons.credit_card_outlined,
        label: 'Thanh toán',
        description: 'Quản lý thẻ',
        color: const Color(0xFFEDE9FE),
        iconColor: const Color(0xFF7C3AED),
      ),
    ];

    final settingsItems = [
      'Thông báo',
      'Trợ giúp & hỗ trợ',
      'Quyền riêng tư & bảo mật',
    ];

    return Column(
      children: [
        const HeaderBar(title: 'Hồ sơ'),
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: AppColors.orange600,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: AppColors.orange600,
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
                                'Nguyễn Văn A',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'nguyenvana@email.com',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                'Thành viên Vàng',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _ProfileStat(value: '24', label: 'Đơn hàng'),
                        _ProfileStat(value: '156', label: 'Sách'),
                        _ProfileStat(value: '12', label: 'Yêu thích'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                    children: menuItems
                        .map((item) => _ProfileMenuTile(item: item))
                        .toList(),
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
                    children: settingsItems
                        .map((title) => _SettingsTile(title: title))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: onLogout,
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
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final Color iconColor;
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({required this.item});

  final _ProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.gray600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.gray600),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.settings_outlined, color: AppColors.gray600),
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

