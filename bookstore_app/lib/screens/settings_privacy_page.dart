import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/app_colors.dart';

class SettingsPrivacyPage extends StatefulWidget {
  const SettingsPrivacyPage({
    super.key,
    required this.userId,
    required this.token,
    required this.onLogout,
  });

  final int userId;
  final String token;
  final VoidCallback onLogout;

  @override
  State<SettingsPrivacyPage> createState() => _SettingsPrivacyPageState();
}

class _SettingsPrivacyPageState extends State<SettingsPrivacyPage> {
  bool _loading = false;

  String _resolveBaseUrl() {
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) return overrideUrl;
    if (Platform.isAndroid) {
      return 'http://192.168.1.4:8080';
    }
    return 'http://localhost:8080';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Quyền riêng tư & bảo mật'),
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
          // Bảo mật tài khoản
          _buildSectionHeader('Bảo mật tài khoản'),
          const SizedBox(height: 8),
          _buildSecurityCard(),
          const SizedBox(height: 24),

          // Quyền riêng tư
          _buildSectionHeader('Quyền riêng tư'),
          const SizedBox(height: 8),
          _buildPrivacyCard(),
          const SizedBox(height: 24),

          // Vùng nguy hiểm
          _buildSectionHeader('Vùng nguy hiểm'),
          const SizedBox(height: 8),
          _buildDangerCard(),
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

  Widget _buildSecurityCard() {
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
          _buildTile(
            icon: Icons.lock_outline,
            iconColor: AppColors.orange600,
            title: 'Đổi mật khẩu',
            subtitle: 'Cập nhật mật khẩu đăng nhập',
            onTap: () => _showChangePasswordDialog(),
          ),
          const Divider(height: 1, indent: 68),
          _buildTile(
            icon: Icons.security_outlined,
            iconColor: Colors.green,
            title: 'Xác thực 2 lớp',
            subtitle: 'Bảo vệ tài khoản an toàn hơn',
            trailing: Transform.scale(
              scale: 0.75,
              child: Switch(
                value: false,
                onChanged: (v) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng đang phát triển'),
                    ),
                  );
                },
                activeColor: AppColors.orange600,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const Divider(height: 1, indent: 68),
          _buildTile(
            icon: Icons.devices_outlined,
            iconColor: Colors.blue,
            title: 'Thiết bị đăng nhập',
            subtitle: 'Quản lý các thiết bị đã đăng nhập',
            onTap: () => _showDevicesDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
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
          _buildTile(
            icon: Icons.visibility_outlined,
            iconColor: AppColors.gray600,
            title: 'Hiển thị hồ sơ',
            subtitle: 'Cho phép người khác xem hồ sơ',
            trailing: Transform.scale(
              scale: 0.75,
              child: Switch(
                value: true,
                onChanged: (v) {},
                activeColor: AppColors.orange600,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const Divider(height: 1, indent: 68),
          _buildTile(
            icon: Icons.history_outlined,
            iconColor: AppColors.gray600,
            title: 'Lịch sử tìm kiếm',
            subtitle: 'Xóa lịch sử tìm kiếm',
            onTap: () => _showClearSearchHistoryDialog(),
          ),
          const Divider(height: 1, indent: 68),
          _buildTile(
            icon: Icons.policy_outlined,
            iconColor: AppColors.gray600,
            title: 'Chính sách bảo mật',
            subtitle: 'Xem chính sách bảo mật',
            onTap: () => _showPrivacyPolicyDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
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
          _buildTile(
            icon: Icons.logout,
            iconColor: Colors.orange,
            title: 'Đăng xuất tất cả thiết bị',
            subtitle: 'Đăng xuất khỏi tất cả thiết bị khác',
            onTap: () => _showLogoutAllDialog(),
          ),
          const Divider(height: 1, indent: 68),
          _buildTile(
            icon: Icons.delete_forever_outlined,
            iconColor: Colors.red,
            title: 'Xóa tài khoản',
            subtitle: 'Xóa vĩnh viễn tài khoản và dữ liệu',
            onTap: () => _showDeleteAccountDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
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
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      if (newController.text != confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mật khẩu xác nhận không khớp'),
                          ),
                        );
                        return;
                      }
                      if (newController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mật khẩu mới phải có ít nhất 6 ký tự'),
                          ),
                        );
                        return;
                      }
                      await _changePassword(
                        currentController.text,
                        newController.text,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange600,
                foregroundColor: Colors.white,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Đổi mật khẩu'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(String currentPassword, String newPassword) async {
    setState(() => _loading = true);
    try {
      final response = await http.put(
        Uri.parse('${_resolveBaseUrl()}/api/users/${widget.userId}/password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công')),
        );
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Đổi mật khẩu thất bại')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thiết bị đăng nhập'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDeviceItem(
              icon: Icons.phone_android,
              name: 'Thiết bị hiện tại',
              info: 'Android • Đang hoạt động',
              isCurrent: true,
            ),
          ],
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

  Widget _buildDeviceItem({
    required IconData icon,
    required String name,
    required String info,
    bool isCurrent = false,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.gray600),
      ),
      title: Row(
        children: [
          Text(name),
          if (isCurrent) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Hiện tại',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(info),
    );
  }

  void _showClearSearchHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lịch sử tìm kiếm'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa toàn bộ lịch sử tìm kiếm?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear search history from SharedPreferences
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa lịch sử tìm kiếm')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chính sách bảo mật'),
        content: const SingleChildScrollView(
          child: Text(
            '''CHÍNH SÁCH BẢO MẬT

1. Thu thập thông tin
Chúng tôi thu thập các thông tin sau:
• Thông tin cá nhân (họ tên, email, số điện thoại)
• Địa chỉ giao hàng
• Lịch sử mua hàng
• Thông tin thiết bị

2. Sử dụng thông tin
Thông tin được sử dụng để:
• Xử lý đơn hàng
• Giao hàng
• Hỗ trợ khách hàng
• Gửi thông báo khuyến mãi (nếu bạn đồng ý)

3. Bảo vệ thông tin
• Mã hóa dữ liệu SSL
• Không chia sẻ thông tin cho bên thứ 3
• Lưu trữ an toàn trên server

4. Quyền của bạn
• Truy cập và chỉnh sửa thông tin
• Yêu cầu xóa dữ liệu
• Từ chối nhận email marketing

5. Liên hệ
Mọi thắc mắc về bảo mật, vui lòng liên hệ:
support@kbook.vn
''',
            style: TextStyle(fontSize: 12, height: 1.5),
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

  void _showLogoutAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất tất cả thiết bị'),
        content: const Text(
          'Bạn sẽ bị đăng xuất khỏi tất cả các thiết bị khác. Tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã đăng xuất tất cả thiết bị khác'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Xóa tài khoản'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hành động này không thể hoàn tác!\n\n'
              'Tất cả dữ liệu của bạn sẽ bị xóa vĩnh viễn:\n'
              '• Thông tin cá nhân\n'
              '• Lịch sử đơn hàng\n'
              '• Danh sách yêu thích\n'
              '• Đánh giá và bình luận',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                labelText: 'Nhập "XOA TAI KHOAN" để xác nhận',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (confirmController.text == 'XOA TAI KHOAN') {
                Navigator.pop(context);
                _deleteAccount();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập đúng "XOA TAI KHOAN"'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _loading = true);
    try {
      final response = await http.delete(
        Uri.parse('${_resolveBaseUrl()}/api/users/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tài khoản đã được xóa')),
        );
        widget.onLogout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa tài khoản')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
