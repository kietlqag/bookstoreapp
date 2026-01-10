import 'package:flutter/material.dart';

import '../models/book.dart';
import 'app_colors.dart';
import 'price_formatter.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.compact = false,
  });

  final Book book;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 9.0 : 12.0;
    final titleLines = compact ? 1 : 2;
    final spacingSm = compact ? 2.0 : 4.0;
    final spacingMd = compact ? 5.0 : 8.0;
    final ratingIconSize = compact ? 14.0 : 16.0;
    final ratingTextStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: compact ? 12 : null,
        );
    final authorTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.gray600,
          fontSize: compact ? 11 : null,
        );
    final totalStock = book.stockQuantity > 0
        ? book.stockQuantity
        : (book.soldQuantity > 0 ? book.soldQuantity : 100);
    final sold = book.soldQuantity.clamp(0, totalStock);
    final progress = totalStock == 0 ? 0.0 : sold / totalStock;
    final progressHeight = compact ? 5.0 : 7.0;
    final discountRate = (book.discount / 100).clamp(0.0, 1.0);
    final displayPrice =
        (book.price * (1 - discountRate)).clamp(0.0, double.infinity);

    // Xét tồn kho: hết hàng khi stockQuantity <= 0
    final isOutOfStock = book.stockQuantity <= 0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final hasBoundedHeight = maxHeight.isFinite && maxHeight > 0;
        final imageHeight = hasBoundedHeight
            ? (maxHeight * (compact ? 0.48 : 0.55))
                .clamp(compact ? 110.0 : 150.0, compact ? 160.0 : 220.0)
                .toDouble()
            : (constraints.maxWidth * (compact ? 1.0 : 1.2))
                .clamp(compact ? 130.0 : 160.0, compact ? 170.0 : 220.0)
                .toDouble();

        return InkWell(
          onTap: isOutOfStock ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: ColorFiltered(
                          colorFilter: isOutOfStock
                              ? ColorFilter.mode(
                                  Colors.black.withOpacity(0.5),
                                  BlendMode.darken,
                                )
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.dst,
                                ),
                          child: Image.network(
                            book.cover,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) {
                              return Container(
                                color: AppColors.gray100,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.menu_book,
                                  color: AppColors.gray600,
                                  size: 32,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (isOutOfStock)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.red500,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'ĐÃ HẾT',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: InkWell(
                            onTap: onFavoriteTap,
                            borderRadius: BorderRadius.circular(16),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: isFavorite
                                  ? Colors.redAccent
                                  : AppColors.gray600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.category,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.orange600,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      SizedBox(height: spacingSm),
                      Text(
                        book.title,
                        maxLines: titleLines,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray900,
                            ),
                      ),
                      SizedBox(height: spacingSm),
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: authorTextStyle,
                      ),
                      SizedBox(height: spacingMd),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: ratingIconSize,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                book.rating.toStringAsFixed(1),
                                style: ratingTextStyle,
                              ),
                            ],
                          ),
                          Text(
                            formatPrice(displayPrice),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: AppColors.orange600,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacingSm),
                      isOutOfStock
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.red50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.red200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 12,
                                    color: AppColors.red600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Đã hết hàng',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.red600,
                                          fontWeight: FontWeight.w600,
                                          fontSize: compact ? 10 : 11,
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : Row(
                              children: [
                                Text(
                                  'Đã bán $sold/$totalStock',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.gray600,
                                        fontWeight: FontWeight.w600,
                                        fontSize: compact ? 10 : 11,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: progressHeight,
                                      backgroundColor: AppColors.gray100,
                                      color: AppColors.orange600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

