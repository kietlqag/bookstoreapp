import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_colors.dart';

class SettingsHelpPage extends StatefulWidget {
  const SettingsHelpPage({super.key, this.userId});

  final int? userId;

  @override
  State<SettingsHelpPage> createState() => _SettingsHelpPageState();
}

class _SettingsHelpPageState extends State<SettingsHelpPage> {
  final List<_FaqItem> _faqItems = [
    _FaqItem(
      question: 'Làm sao để đặt hàng?',
      answer:
          'Bạn có thể đặt hàng bằng cách:\n1. Chọn sách muốn mua\n2. Nhấn "Thêm vào giỏ hàng" hoặc "Mua ngay"\n3. Kiểm tra giỏ hàng và nhấn "Thanh toán"\n4. Điền thông tin giao hàng và chọn phương thức thanh toán\n5. Xác nhận đơn hàng',
    ),
    _FaqItem(
      question: 'Phí vận chuyển được tính như thế nào?',
      answer:
          'Phí vận chuyển được tính dựa trên:\n• Khoảng cách từ kho đến địa chỉ nhận hàng\n• Trọng lượng đơn hàng\n• Phương thức vận chuyển (tiêu chuẩn/nhanh)\n\nĐơn hàng từ 300.000đ được miễn phí vận chuyển.',
    ),
    _FaqItem(
      question: 'Tôi có thể hủy đơn hàng không?',
      answer:
          'Bạn có thể hủy đơn hàng khi đơn hàng đang ở trạng thái "Chờ xác nhận".\n\nSau khi đơn hàng được xác nhận và đang giao, bạn không thể hủy trực tiếp. Vui lòng liên hệ hotline để được hỗ trợ.',
    ),
    _FaqItem(
      question: 'Chính sách đổi trả như thế nào?',
      answer:
          'Chính sách đổi trả trong 7 ngày:\n• Sách còn nguyên vẹn, chưa qua sử dụng\n• Còn đầy đủ bao bì, nhãn mác\n• Có hóa đơn mua hàng\n\nLý do đổi trả hợp lệ:\n• Sách bị lỗi in ấn\n• Giao sai sản phẩm\n• Sách bị hư hỏng trong quá trình vận chuyển',
    ),
    _FaqItem(
      question: 'Làm sao để sử dụng mã giảm giá?',
      answer:
          'Để sử dụng mã giảm giá:\n1. Thêm sách vào giỏ hàng\n2. Vào trang thanh toán\n3. Nhập mã giảm giá vào ô "Mã voucher"\n4. Nhấn "Áp dụng"\n\nLưu ý: Mỗi đơn hàng chỉ áp dụng được 1 mã giảm giá.',
    ),
    _FaqItem(
      question: 'Thời gian giao hàng bao lâu?',
      answer:
          'Thời gian giao hàng dự kiến:\n• Nội thành TP.HCM: 1-2 ngày\n• Các tỉnh lân cận: 2-3 ngày\n• Các tỉnh xa: 3-5 ngày\n\nThời gian có thể thay đổi vào các dịp lễ, Tết.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Trợ giúp & hỗ trợ'),
        centerTitle: false,
        toolbarHeight: 44,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
        padding: const EdgeInsets.all(16),
        children: [
          // Liên hệ nhanh
          _buildSectionHeader('Liên hệ hỗ trợ'),
          const SizedBox(height: 8),
          _buildContactCard(),
          const SizedBox(height: 24),

          // FAQ
          _buildSectionHeader('Câu hỏi thường gặp'),
          const SizedBox(height: 8),
          _buildFaqCard(),
          const SizedBox(height: 24),

          // Thông tin thêm
          _buildSectionHeader('Thông tin khác'),
          const SizedBox(height: 8),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray700,
            ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildContactTile(
            icon: Icons.phone_outlined,
            iconColor: Colors.green,
            title: 'Hotline',
            subtitle: '1900 1234 (8:00 - 22:00)',
            onTap: () => _launchPhone('19001234'),
          ),
          const Divider(height: 1, indent: 68),
          _buildContactTile(
            icon: Icons.email_outlined,
            iconColor: Colors.blue,
            title: 'Email',
            subtitle: 'support@kbook.vn',
            onTap: () => _launchEmail('support@kbook.vn'),
          ),
          const Divider(height: 1, indent: 68),
          _buildContactTile(
            icon: Icons.chat_outlined,
            iconColor: AppColors.orange600,
            title: 'Chat với AI',
            subtitle: 'Hỗ trợ tự động 24/7',
            onTap: () {
              Navigator.pop(context);
              // AI chat is floating, will show automatically
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gray500,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionPanelList.radio(
        elevation: 0,
        expandedHeaderPadding: EdgeInsets.zero,
        children: _faqItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return ExpansionPanelRadio(
            value: index,
            canTapOnHeader: true,
            headerBuilder: (context, isExpanded) {
              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isExpanded
                        ? AppColors.orange600
                        : AppColors.orange50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    size: 18,
                    color: isExpanded ? Colors.white : AppColors.orange600,
                  ),
                ),
                title: Text(
                  item.question,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              );
            },
            body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.answer,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray700,
                        height: 1.5,
                      ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.description_outlined,
            title: 'Điều khoản sử dụng',
            onTap: () => _showInfoDialog('Điều khoản sử dụng', _termsOfService),
          ),
          const Divider(height: 1, indent: 68),
          _buildInfoTile(
            icon: Icons.info_outline,
            title: 'Về chúng tôi',
            onTap: () => _showInfoDialog('Về KBook', _aboutUs),
          ),
          const Divider(height: 1, indent: 68),
          _buildInfoTile(
            icon: Icons.star_outline,
            title: 'Đánh giá ứng dụng',
            onTap: () => _showRatingDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.gray600, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.6,
                ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đánh giá ứng dụng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bạn có hài lòng với KBook không?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (index) => InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cảm ơn bạn đã đánh giá!'),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Icon(
                      Icons.star,
                      color: AppColors.orange600,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
        ],
      ),
    );
  }

  static const _termsOfService = '''
ĐIỀU KHOẢN SỬ DỤNG

1. Giới thiệu
Chào mừng bạn đến với KBook. Bằng việc sử dụng ứng dụng, bạn đồng ý tuân thủ các điều khoản sau.

2. Tài khoản người dùng
• Bạn phải cung cấp thông tin chính xác khi đăng ký
• Bạn chịu trách nhiệm bảo mật tài khoản của mình
• Không được chia sẻ tài khoản cho người khác

3. Đặt hàng và thanh toán
• Giá sản phẩm có thể thay đổi mà không cần báo trước
• Đơn hàng chỉ được xác nhận khi thanh toán thành công
• Chúng tôi có quyền hủy đơn hàng nếu phát hiện gian lận

4. Giao hàng
• Thời gian giao hàng là ước tính, không phải cam kết
• Bạn cần kiểm tra hàng trước khi nhận

5. Đổi trả
• Áp dụng trong 7 ngày kể từ ngày nhận hàng
• Sản phẩm phải còn nguyên vẹn, chưa qua sử dụng

6. Quyền sở hữu trí tuệ
• Tất cả nội dung trên ứng dụng thuộc quyền sở hữu của KBook
• Không được sao chép, phân phối mà không có sự cho phép
''';

  static const _aboutUs = '''
VỀ KBOOK

KBook là ứng dụng mua sách trực tuyến hàng đầu Việt Nam, cung cấp hàng ngàn đầu sách từ các nhà xuất bản uy tín.

SỨ MỆNH
Mang tri thức đến gần hơn với mọi người thông qua việc cung cấp sách chất lượng với giá cả hợp lý.

CAM KẾT
• Sách chính hãng 100%
• Giao hàng nhanh chóng
• Đổi trả dễ dàng
• Hỗ trợ khách hàng 24/7

LIÊN HỆ
• Hotline: 1900 1234
• Email: support@kbook.vn
• Website: www.kbook.vn

Phiên bản: 1.0.0
© 2024 KBook. All rights reserved.
''';
}

class _FaqItem {
  final String question;
  final String answer;

  _FaqItem({required this.question, required this.answer});
}
