import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import 'app_colors.dart';
import 'price_formatter.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onSelected,
    required this.onRemove,
    required this.onIncrease,
    required this.onDecrease,
  });

  final CartItem item;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onRemove;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final discountRate = (item.book.discount / 100).clamp(0.0, 1.0);
    final displayPrice =
        (item.book.price * (1 - discountRate)).clamp(0.0, double.infinity);
    final hasDiscount = item.book.discount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 26,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelected(value ?? false),
                  activeColor: AppColors.orange600,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 70,
              height: 96,
              child: Image.network(
                item.book.cover,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: AppColors.gray100,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.menu_book,
                      color: AppColors.gray600,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.book.author,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.gray600),
                ),
                const SizedBox(height: 6),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            formatPrice(displayPrice),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.orange600,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _QuantityButton(
                          icon: Icons.remove,
                          onTap: onDecrease,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            item.quantity.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        _QuantityButton(icon: Icons.add, onTap: onIncrease),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.gray100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppColors.gray700),
      ),
    );
  }
}




