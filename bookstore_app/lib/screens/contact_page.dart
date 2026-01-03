import 'package:flutter/material.dart';

import '../widgets/app_colors.dart';
import '../widgets/header.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HeaderBar(title: 'Liên hệ'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cần hỗ trợ?',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đội ngũ hỗ trợ luôn sẵn sàng giúp bạn.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.gray600),
                    ),
                    const SizedBox(height: 16),
                    _ContactTile(
                      icon: Icons.phone_in_talk_outlined,
                      title: 'Hotline',
                      subtitle: '1900 123 456',
                    ),
                    const SizedBox(height: 12),
                    _ContactTile(
                      icon: Icons.mail_outline,
                      title: 'Email',
                      subtitle: 'support@k-book.vn',
                    ),
                    const SizedBox(height: 12),
                    _ContactTile(
                      icon: Icons.location_on_outlined,
                      title: 'Cửa hàng',
                      subtitle: '120 Nguyễn Huệ, Quận 1, TP.HCM',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giờ làm việc',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thứ 2 - Thứ 7: 08:00 - 20:00',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.gray600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chủ nhật: 09:00 - 18:00',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.gray600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.orange600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.gray600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
