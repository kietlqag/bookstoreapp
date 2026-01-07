import 'package:flutter/material.dart';

import '../widgets/app_colors.dart';
import '../widgets/header.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HeaderBar(title: 'Li\u00ean h\u1ec7'),
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
                      'C\u1ea7n h\u1ed7 tr\u1ee3?',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'D\u1ed9i ng\u0169 h\u1ed7 tr\u1ee3 lu\u00f4n s\u1eb5n s\u00e0ng gi\u00fap b\u1ea1n.',
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
                      title: 'C\u1eeda h\u00e0ng',
                      subtitle: '120 Nguy\u1ec5n Hu\u1ec7, Qu\u1eadn 1, TP.HCM',
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
                      'Gi\u1edd l\u00e0m vi\u1ec7c',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Th\u1ee9 2 - Th\u1ee9 7: 08:00 - 20:00',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.gray600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ch\u1ee7 nh\u1eadt: 09:00 - 18:00',
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
