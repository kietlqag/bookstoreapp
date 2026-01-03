import 'package:flutter/material.dart';

import '../../widgets/app_colors.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.onGetStarted,
    required this.onLogin,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final features = [
      _Feature(
        icon: Icons.auto_awesome,
        title: 'Hơn 10.000 đầu sách',
        description: 'Khám phá từ văn học đến khoa học',
        color: AppColors.orange600,
      ),
      _Feature(
        icon: Icons.trending_up,
        title: 'Giá tốt nhất',
        description: 'Ưu đãi độc quyền cho thành viên',
        color: const Color(0xFF2563EB),
      ),
      _Feature(
        icon: Icons.bolt,
        title: 'Giao hàng nhanh',
        description: 'Miễn phí ship đơn từ 150K',
        color: const Color(0xFF16A34A),
      ),
      _Feature(
        icon: Icons.shield,
        title: 'Thanh toán an toàn',
        description: 'Dữ liệu của bạn được bảo vệ',
        color: const Color(0xFF7C3AED),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.orange600, AppColors.rose500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.menu_book,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
        'K-Book',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Khám phá tri thức với hàng ngàn tựa sách chọn lọc',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      ...features.map((feature) => _FeatureCard(feature: feature)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.orange600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: onGetStarted,
                        child: const Text('Bắt đầu'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Tôi đã có tài khoản'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tiếp tục nghĩa là bạn đồng ý với điều khoản và chính sách.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
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
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(feature.icon, color: feature.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

