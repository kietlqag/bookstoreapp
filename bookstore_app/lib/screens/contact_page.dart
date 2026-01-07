import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_colors.dart';
import '../widgets/header.dart';
import 'online_support_page.dart';
import 'support_request_page.dart';
import 'support_request_list_page.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HeaderBar(
          title: 'Li\u00ean h\u1ec7',
          titleColor: Colors.white,
          backgroundGradient: const LinearGradient(
            colors: [AppColors.orange600, AppColors.rose500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          iconColor: Colors.white,
          showDivider: false,
          actions: const [],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.orange600.withOpacity(0.08),
                      AppColors.rose500.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.orange600.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange600.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Hỗ trợ trực tuyến',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.gray900,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.orange600,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '24/7',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nhận hỗ trợ nhanh chóng từ đội ngũ chăm sóc khách hàng',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.gray600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SupportButton(
                      icon: Icons.chat_bubble_outline,
                      title: 'Chat trực tuyến',
                      subtitle: 'Trò chuyện với nhân viên hỗ trợ',
                      isHighlighted: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OnlineSupportPage(userId: userId),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _SupportButton(
                      icon: Icons.history,
                      title: 'Xem yêu cầu đã gửi',
                      subtitle: 'Xem danh sách và tiến trình giải quyết',
                      isHighlighted: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SupportRequestListPage(userId: userId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                      '\u0110\u1ed9i ng\u0169 h\u1ed7 tr\u1ee3 lu\u00f4n s\u1eb5n s\u00e0ng gi\u00fap b\u1ea1n.',
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
                      onTap: () async {
                        final uri = Uri.parse('tel:1900123456');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _ContactTile(
                      icon: Icons.mail_outline,
                      title: 'Email',
                      subtitle: 'support@k-book.vn',
                      onTap: () async {
                        final uri = Uri.parse('mailto:support@k-book.vn');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final widget = Row(
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

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: widget,
      );
    }
    return widget;
  }
}

class _SupportButton extends StatelessWidget {
  const _SupportButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted ? Colors.white : AppColors.gray50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? AppColors.orange600.withOpacity(0.2)
                : AppColors.gray200,
            width: isHighlighted ? 1.5 : 1,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.orange600.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: isHighlighted
                    ? const LinearGradient(
                        colors: [AppColors.orange600, AppColors.rose500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isHighlighted
                    ? null
                    : AppColors.orange600.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: AppColors.orange600.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isHighlighted ? Colors.white : AppColors.orange600,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isHighlighted
                              ? AppColors.gray900
                              : AppColors.gray900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gray600,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isHighlighted
                  ? AppColors.orange600
                  : AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}
