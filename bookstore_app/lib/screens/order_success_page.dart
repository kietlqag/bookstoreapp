import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../widgets/app_colors.dart';
import '../widgets/price_formatter.dart';
import 'home_page.dart';
import 'order_list_page.dart';

class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({
    super.key,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.productDiscount,
    required this.shippingDiscount,
    required this.total,
    this.orderId,
    this.shippingAddressNew,
    this.shippingAddressOld,
    this.phoneNumber,
    this.paymentLabel,
  });

  final int userId;
  final List<CartItem> items;
  final double subtotal;
  final double shippingFee;
  final double productDiscount;
  final double shippingDiscount;
  final double total;
  final int? orderId;
  final String? shippingAddressNew;
  final String? shippingAddressOld;
  final String? phoneNumber;
  final String? paymentLabel;

  @override
  Widget build(BuildContext context) {
    final orderText =
        orderId != null ? 'M\u00e3 \u0111\u01a1n #$orderId' : null;
    final dateText =
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    final phoneText = phoneNumber?.trim().isNotEmpty == true
        ? phoneNumber!
        : 'Ch\u01b0a c\u00f3';
    final paymentText = paymentLabel?.trim().isNotEmpty == true
        ? paymentLabel!
        : 'Ch\u01b0a ch\u1ecdn';
    return Scaffold(
      appBar: AppBar(
        title: const Text('\u0110\u1eb7t h\u00e0ng th\u00e0nh c\u00f4ng'),
        centerTitle: false,
        toolbarHeight: 44,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HomePage.setActiveTab('home');
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 15,
            ),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.orange50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: AppColors.orange600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '\u0110\u1eb7t h\u00e0ng th\u00e0nh c\u00f4ng',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
              ),
              const SizedBox(height: 6),
            ],
          ),
          const SizedBox(height: 12),
          _InvoiceCard(
            orderId: orderText ?? '--',
            dateText: dateText,
            phoneText: phoneText,
            paymentText: paymentText,
            shippingAddressNew: shippingAddressNew,
            shippingAddressOld: shippingAddressOld,
            items: items,
            subtotal: subtotal,
            shippingFee: shippingFee,
            productDiscount: productDiscount,
            shippingDiscount: shippingDiscount,
            total: total,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderListPage(userId: userId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Xem \u0111\u01a1n h\u00e0ng'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange600,
                    side: const BorderSide(color: AppColors.orange600),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HomePage.setActiveTab('home');
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Trang ch\u1ee7'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.orderId,
    required this.dateText,
    required this.phoneText,
    required this.paymentText,
    required this.shippingAddressNew,
    required this.shippingAddressOld,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.productDiscount,
    required this.shippingDiscount,
    required this.total,
  });

  final String orderId;
  final String dateText;
  final String phoneText;
  final String paymentText;
  final String? shippingAddressNew;
  final String? shippingAddressOld;
  final List<CartItem> items;
  final double subtotal;
  final double shippingFee;
  final double productDiscount;
  final double shippingDiscount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _InfoRow(label: 'M\u00e3 \u0111\u01a1n', value: orderId),
          _InfoRow(label: 'Ng\u00e0y', value: dateText),
          _InfoRow(label: 'S\u1ed1 \u0111i\u1ec7n tho\u1ea1i', value: phoneText),
          _InfoRow(
            label: '\u0110\u1ecba ch\u1ec9 m\u1edbi',
            value: shippingAddressNew?.trim().isNotEmpty == true
                ? shippingAddressNew!
                : 'Ch\u01b0a c\u00f3',
          ),
          _InfoRow(
            label: '\u0110\u1ecba ch\u1ec9 c\u0169',
            value: shippingAddressOld?.trim().isNotEmpty == true
                ? shippingAddressOld!
                : 'Ch\u01b0a c\u00f3',
          ),
          _InfoRow(label: 'Thanh to\u00e1n', value: paymentText),
          const Divider(height: 24, color: AppColors.gray200),
          const SizedBox(height: 4),
          ...items.map((item) => _ItemRow(item: item)),
          const Divider(height: 24, color: AppColors.gray200),
          _InfoRow(
            label: 'T\u1ea1m t\u00ednh',
            value: formatPrice(subtotal),
            alignRight: true,
          ),
          _InfoRow(
            label: 'Ph\u00ed v\u1eadn chuy\u1ec3n',
            value: formatPrice(shippingFee),
            alignRight: true,
          ),
          _InfoRow(
            label: 'Gi\u1ea3m gi\u00e1 s\u1ea3n ph\u1ea9m',
            value: productDiscount == 0
                ? formatPrice(0)
                : '-${formatPrice(productDiscount)}',
            alignRight: true,
          ),
          _InfoRow(
            label: 'Gi\u1ea3m ph\u00ed v\u1eadn chuy\u1ec3n',
            value: shippingDiscount == 0
                ? formatPrice(0)
                : '-${formatPrice(shippingDiscount)}',
            alignRight: true,
          ),
          const Divider(height: 24, color: AppColors.gray200),
          _InfoRow(
            label: 'T\u1ed5ng c\u1ed9ng',
            value: formatPrice(total),
            isEmphasis: true,
            alignRight: true,
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final price = item.book.price * (1 - (item.book.discount / 100));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.book.cover,
              width: 48,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 60,
                color: AppColors.gray100,
                alignment: Alignment.center,
                child: const Icon(Icons.menu_book, color: AppColors.gray600),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'x${item.quantity}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.gray600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatPrice(price),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final bool isEmphasis;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: AppColors.gray600);
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w600,
          color: AppColors.gray900,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: labelStyle),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
