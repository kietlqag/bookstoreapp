import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../widgets/app_colors.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/price_formatter.dart';

class CartPage extends StatefulWidget {
  const CartPage({
    super.key,
    required this.cartItems,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final List<CartItem> cartItems;
  final ValueChanged<CartItem> onIncrease;
  final ValueChanged<CartItem> onDecrease;
  final ValueChanged<CartItem> onRemove;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Set<int> _selectedIds = <int>{};

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.cartItems.map((item) => item.id));
  }

  @override
  void didUpdateWidget(covariant CartPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.cartItems.map((item) => item.id).toSet();
    _selectedIds.removeWhere((id) => !currentIds.contains(id));
    for (final id in currentIds) {
      _selectedIds.add(id);
    }
  }

  double _itemPrice(CartItem item) {
    final discountRate = (item.book.discount / 100).clamp(0.0, 1.0);
    return (item.book.price * (1 - discountRate)).clamp(0.0, double.infinity);
  }

  Future<void> _confirmDecrease(CartItem item) async {
    if (item.quantity > 1) {
      widget.onDecrease(item);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: const [
              Icon(Icons.remove_shopping_cart, color: AppColors.rose500),
              SizedBox(width: 8),
              Text('Xóa sản phẩm'),
            ],
          ),
          content: Text(
            'Xóa "${item.book.title}" khỏi giỏ hàng?',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.gray700),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gray700,
                side: const BorderSide(color: AppColors.gray200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Hủy'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.rose500,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    widget.onRemove(item);
    _selectedIds.remove(item.id);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmRemoveSelected() async {
    final selectedItems = widget.cartItems
        .where((item) => _selectedIds.contains(item.id))
        .toList();
    if (selectedItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: const [
              Icon(Icons.delete_outline, color: AppColors.rose500),
              SizedBox(width: 8),
              Text('Xóa khỏi giỏ hàng'),
            ],
          ),
          content: Text(
            'Xóa ${selectedItems.length} sản phẩm đã chọn khỏi giỏ hàng?',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.gray700),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gray700,
                side: const BorderSide(color: AppColors.gray200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Hủy'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.rose500,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    for (final item in selectedItems) {
      widget.onRemove(item);
      _selectedIds.remove(item.id);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = widget.cartItems
        .where((item) => _selectedIds.contains(item.id))
        .toList();
    final subtotal = selectedItems.fold<double>(
      0,
      (sum, item) => sum + _itemPrice(item) * item.quantity,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Giỏ hàng (${widget.cartItems.length})'),
        centerTitle: false,
        toolbarHeight: 44,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
        actions: [
          IconButton(
            onPressed: _confirmRemoveSelected,
            icon: const Icon(Icons.delete_outline),
            color: Colors.white,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.orange600, AppColors.rose500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: widget.cartItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              color: AppColors.gray100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 40,
                              color: AppColors.gray600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Giỏ hàng trống',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Hãy thêm sách để tiếp tục mua sắm.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.gray600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                        children: [
                          ...widget.cartItems.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CartItemCard(
                                item: item,
                                isSelected: _selectedIds.contains(item.id),
                                onSelected: (value) {
                                  setState(() {
                                    if (value) {
                                      _selectedIds.add(item.id);
                                    } else {
                                      _selectedIds.remove(item.id);
                                    }
                                });
                              },
                              onRemove: () => widget.onRemove(item),
                              onIncrease: () => widget.onIncrease(item),
                              onDecrease: () => _confirmDecrease(item),
                            ),
                          ),
                        ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: AppColors.gray200),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Tổng tiền',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: AppColors.gray600),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        formatPrice(subtotal),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.orange600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed:
                                        selectedItems.isEmpty ? null : () {},
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.orange600,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                    ),
                                    child: const Text('Mua ngay'),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
