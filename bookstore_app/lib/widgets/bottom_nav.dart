import 'package:flutter/material.dart';

import 'app_colors.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    this.cartCount = 0,
  });

  final String activeTab;
  final ValueChanged<String> onTabSelected;
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(id: 'home', label: 'Trang chủ', icon: Icons.home_rounded),
      _NavItem(
        id: 'cart',
        label: 'Giỏ hàng',
        icon: Icons.shopping_cart_outlined,
      ),
      _NavItem(id: 'contact', label: 'Liên hệ', icon: Icons.support_agent),
      _NavItem(id: 'profile', label: 'Tôi', icon: Icons.person_outline),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final isActive = activeTab == item.id;
            return InkWell(
              onTap: () => onTabSelected(item.id),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          item.icon,
                          size: 24,
                          color:
                              isActive ? AppColors.orange600 : AppColors.gray600,
                        ),
                        if (item.id == 'cart' && cartCount > 0)
                          Positioned(
                            right: -8,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                cartCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isActive
                                ? AppColors.orange600
                                : AppColors.gray600,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}
