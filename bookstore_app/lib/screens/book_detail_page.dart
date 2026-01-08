import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/book_service.dart';
import '../models/cart_item.dart';
import '../models/review.dart';
import '../models/review_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_colors.dart';
import '../widgets/header.dart';
import '../widgets/price_formatter.dart';
import '../widgets/top_message.dart';
import 'package:bookstore_app/screens/checkout_page.dart';

class BookDetailPage extends StatefulWidget {
  const BookDetailPage({
    super.key,
    required this.book,
    required this.bookService,
    required this.reviewService,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onAddToCart,
    required this.userId,
  });

  final Book book;
  final BookService bookService;
  final ReviewService reviewService;
  final bool isFavorite;
  final Future<bool> Function(Book book) onToggleFavorite;
  final void Function(Book book, int quantity) onAddToCart;
  final int userId;

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  String _activeTab = 'description';
  bool _isFavorite = false;
  Book? _book;
  List<Review> _reviews = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _isFavorite = widget.isFavorite;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await widget.bookService.fetchBook(widget.book.id);
      final reviews = await widget.reviewService.fetchReviews(widget.book.id);
      if (!mounted) return;
      setState(() {
        _book = detail;
        _reviews = reviews;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<int?> _selectQuantity(Book book, String actionLabel) {
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        int quantity = 1;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chọn số lượng',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () {
                                setModalState(() {
                                  quantity -= 1;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppColors.orange600,
                      ),
                      Text(
                        quantity.toString(),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        onPressed: () {
                          setModalState(() {
                            quantity += 1;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppColors.orange600,
                      ),
                      const Spacer(),
                      Text(
                        formatPrice(
                          (book.price *
                                  (1 -
                                      (book.discount / 100)
                                          .clamp(0.0, 1.0)) *
                                  quantity)
                              .clamp(0.0, double.infinity),
                        ),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.orange600,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(quantity),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleAddToCart() async {
    final book = _book ?? widget.book;
    final selected = await _selectQuantity(book, 'Thêm vào giỏ');
    if (!mounted || selected == null || selected <= 0) return;
    widget.onAddToCart(book, selected);
    showTopMessage(
      context,
      message: 'Đã thêm vào giỏ hàng',
      type: TopMessageType.success,
    );
  }

  Future<void> _handleBuyNow() async {
    final book = _book ?? widget.book;
    final selected = await _selectQuantity(book, 'Mua ngay');
    if (!mounted || selected == null || selected <= 0) return;
    final item = CartItem(id: 0, book: book, quantity: selected);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutPage(items: [item], userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = _book ?? widget.book;
    final discountRate = (book.discount / 100).clamp(0.0, 1.0);
    final discountedPrice =
        (book.price * (1 - discountRate)).clamp(0.0, double.infinity);
    final discountPercent = book.discount > 0 ? book.discount.round() : 0;
    final totalStock = book.stockQuantity > 0
        ? book.stockQuantity
        : (book.soldQuantity > 0 ? book.soldQuantity : 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(
              showBack: true,
              onBack: () {
                // Sử dụng rootNavigator để đảm bảo pop đúng route
                final navigator = Navigator.of(context, rootNavigator: true);
                if (navigator.canPop()) {
                  navigator.pop();
                } else {
                  // Nếu không pop được, thử pop với context thường
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                }
              },
              backgroundGradient: const LinearGradient(
                colors: [AppColors.orange600, AppColors.rose500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              iconColor: Colors.white,
              titleColor: Colors.white,
              showDivider: false,
              verticalPadding: 10,
              actions: [
                _RoundIconButton(
                  icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.redAccent : AppColors.gray600,
                  onTap: () async {
                    try {
                      final next = await widget.onToggleFavorite(book);
                      if (!mounted) return;
                      setState(() {
                        _isFavorite = next;
                      });
                    } catch (error) {
                      showTopMessage(
                        context,
                        message: 'Đã xảy ra lỗi. Vui lòng thử lại sau.',
                        type: TopMessageType.error,
                      );
                    }
                  },
                ),
                const SizedBox(width: 10),
                const _RoundIconButton(
                  icon: Icons.share_outlined,
                  color: AppColors.gray600,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 20,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.gray100, Colors.white],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 180,
                        height: 260,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          book.cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: AppColors.gray100,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.menu_book_rounded,
                                size: 48,
                                color: AppColors.gray600,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.category,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: AppColors.orange600,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tác giả: ${book.author}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.gray600),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.gray200),
                              bottom: BorderSide(color: AppColors.gray200),
                            ),
                          ),
                          child: Row(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 20,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    book.rating.toStringAsFixed(1),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${book.reviewCount} đánh giá)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.gray600),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 1,
                                height: 16,
                                color: AppColors.gray200,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                totalStock > 0
                                    ? 'Đã bán ${book.soldQuantity}/$totalStock'
                                    : 'Chưa có dữ liệu bán',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.gray600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              formatPrice(discountedPrice),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: AppColors.orange600,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            if (book.discount > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                formatPrice(book.price),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.gray600,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '-$discountPercent%',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _TabButton(
                              label: 'Mô tả',
                              isActive: _activeTab == 'description',
                              onTap: () {
                                setState(() {
                                  _activeTab = 'description';
                                });
                              },
                            ),
                            const SizedBox(width: 20),
                            _TabButton(
                              label: 'Chi tiết',
                              isActive: _activeTab == 'details',
                              onTap: () {
                                setState(() {
                                  _activeTab = 'details';
                                });
                              },
                            ),
                            const SizedBox(width: 20),
                            _TabButton(
                              label: 'Đánh giá',
                              isActive: _activeTab == 'reviews',
                              onTap: () {
                                setState(() {
                                  _activeTab = 'reviews';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_activeTab == 'description')
                          Text(
                            book.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.gray600, height: 1.5),
                          ),
                        if (_activeTab == 'details')
                          _DetailsList(
                            publisher: book.publisher,
                            year: book.year,
                            pages: book.pages,
                            language: book.language,
                          ),
                        if (_activeTab == 'reviews')
                          _ReviewList(reviews: _reviews),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _AddToCartBar(
        onAddToCart: _handleAddToCart,
        onBuyNow: _handleBuyNow,
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isActive ? AppColors.orange600 : AppColors.gray600,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 2,
            color: isActive ? AppColors.orange600 : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _DetailsList extends StatelessWidget {
  const _DetailsList({
    required this.publisher,
    required this.year,
    required this.pages,
    required this.language,
  });

  final String? publisher;
  final int? year;
  final int? pages;
  final String? language;

  @override
  Widget build(BuildContext context) {
    final details = [
      _DetailRow(label: 'Nhà xuất bản', value: publisher ?? '-'),
      _DetailRow(label: 'Năm', value: year?.toString() ?? '-'),
      _DetailRow(
        label: 'Số trang',
        value: pages != null ? '$pages trang' : '-',
      ),
      _DetailRow(label: 'Ngôn ngữ', value: language ?? '-'),
    ];
    return Column(children: details);
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.gray600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({required this.reviews});

  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: AppColors.gray300,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đánh giá',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy là người đầu tiên đánh giá sản phẩm này',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: reviews.map((review) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.gray200)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.gray100,
                child: Text(
                  review.userName.isNotEmpty
                      ? review.userName.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: AppColors.gray700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName.isNotEmpty
                          ? review.userName
                          : 'Người dùng',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (review.createdAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.formatRelativeTime(review.createdAt!),
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.gray500),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          size: 14,
                          color: index < review.rating.round()
                              ? const Color(0xFFF59E0B)
                              : AppColors.gray200,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.comment,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.gray600),
                    ),
                    if (review.images.isNotEmpty || review.videos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...review.images.map((imageUrl) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 72,
                                height: 72,
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.gray100,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.image_outlined,
                                      size: 18,
                                      color: AppColors.gray500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          ...review.videos.map((_) {
                            return Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppColors.gray100,
                                border: Border.all(color: AppColors.gray200),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.play_circle_outline,
                                size: 22,
                                color: AppColors.gray600,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAddToCart,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Thêm vào giỏ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.orange600),
                  foregroundColor: AppColors.orange600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onBuyNow,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Mua ngay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
