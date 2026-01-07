import 'package:flutter/material.dart';

import 'app_colors.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.orange600 : AppColors.gray50,
            borderRadius: BorderRadius.circular(20),
            border: isActive
                ? null
                : Border.all(
                    color: AppColors.gray200,
                    width: 1,
                  ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.orange600.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: isActive ? Colors.white : AppColors.gray700,
            ),
          ),
        ),
      ),
    );
  }
}

