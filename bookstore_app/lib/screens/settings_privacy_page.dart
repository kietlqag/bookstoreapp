import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/app_colors.dart';
import '../models/profile_service.dart';
import '../models/profile_summary.dart';

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
  ProfileSummary? _profile;
  bool _loadingProfile = true;
  late final ProfileService _profileService = ProfileService(baseUrl: _resolveBaseUrl());

  String _resolveBaseUrl() {
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) return overrideUrl;
    if (Platform.isAndroid) {
      return 'http://192.168.1.155:8080';
    }
    return 'http://localhost:8080';
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile when page becomes visible again (e.g., after editing profile)
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.fetchProfileSummary(widget.userId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _loadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
        });
      }
    }
  }

  bool get _hasEmail => _profile?.email != null && _profile!.email.trim().isNotEmpty;

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
            subtitle: _loadingProfile
                ? 'Đang tải...'
                : (_hasEmail 
                    ? 'Cập nhật mật khẩu đăng nhập'
                    : 'Vui lòng cập nhật email trước'),
            onTap: _loadingProfile
                ? null
                : (_hasEmail 
                    ? () => _showChangePasswordDialog()
                    : () => _showEmailRequiredDialog()),
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

  void _showEmailRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email_outlined, color: AppColors.orange600),
            SizedBox(width: 8),
            Text('Cập nhật email'),
          ],
        ),
        content: const Text(
          'Để đổi mật khẩu, bạn cần cập nhật email trước.\n\n'
          'Vui lòng quay lại trang hồ sơ và cập nhật email trong phần chỉnh sửa hồ sơ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close settings page to go back to profile
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Quay lại hồ sơ'),
          ),
        ],
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
                      // Validate inputs
                      if (currentController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập mật khẩu hiện tại'),
                          ),
                        );
                        return;
                      }
                      if (newController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập mật khẩu mới'),
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
                      if (newController.text != confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mật khẩu xác nhận không khớp'),
                          ),
                        );
                        return;
                      }
                      if (currentController.text == newController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mật khẩu mới phải khác mật khẩu hiện tại'),
                          ),
                        );
                        return;
                      }
                      final success = await _changePassword(
                        currentController.text,
                        newController.text,
                      );
                      if (context.mounted && success) {
                        Navigator.pop(context);
                      }
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

  Future<bool> _changePassword(String currentPassword, String newPassword) async {
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

      if (!mounted) return false;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công'),
            backgroundColor: Colors.green,
          ),
        );
        return true;
      } else {
        String errorMessage = 'Đổi mật khẩu thất bại';
        bool isEmailRequired = false;
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['message'] ?? errorMessage;
          isEmailRequired = data['code'] == 'EMAIL_REQUIRED' || 
                           errorMessage.contains('email') ||
                           errorMessage.contains('Email');
        } catch (_) {
          // If JSON decode fails, use default message
        }
        
        if (isEmailRequired && response.statusCode == 400) {
          // Reload profile to check email status
          await _loadProfile();
          // Show email required dialog
          if (mounted) {
            _showEmailRequiredDialog();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDeleteAccountDialog() async {
    // Kiểm tra email trước
    if (!_hasEmail) {
      _showEmailRequiredDialog();
      return;
    }

    final confirmController = TextEditingController();
    final otpController = TextEditingController();
    bool showOtpStep = false;
    bool sendingOtp = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Xóa tài khoản'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!showOtpStep) ...[
                  const Text(
                    'Hành động này không thể hoàn tác!\n\n'
                    'Tài khoản của bạn sẽ bị vô hiệu hóa:\n'
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
                ] else ...[
                  const Text(
                    'Mã OTP đã được gửi đến email của bạn.\n'
                    'Vui lòng nhập mã OTP để xác nhận xóa tài khoản.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Mã OTP',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 6,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sendingOtp || _loading
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: sendingOtp || _loading
                  ? null
                  : () async {
                      if (!showOtpStep) {
                        if (confirmController.text != 'XOA TAI KHOAN') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập đúng "XOA TAI KHOAN"'),
                            ),
                          );
                          return;
                        }
                        // Gửi OTP
                        setDialogState(() => sendingOtp = true);
                        try {
                          await _profileService.requestAccountDeletion(
                            userId: widget.userId,
                            token: widget.token,
                          );
                          setDialogState(() {
                            sendingOtp = false;
                            showOtpStep = true;
                          });
                        } catch (e) {
                          setDialogState(() => sendingOtp = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã xảy ra lỗi: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else {
                        // Xác nhận OTP và xóa tài khoản
                        final code = otpController.text.trim();
                        if (code.isEmpty || code.length != 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập mã OTP hợp lệ'),
                            ),
                          );
                          return;
                        }
                        final success = await _verifyAndDeleteAccount(code);
                        if (context.mounted && success) {
                          Navigator.pop(context);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: sendingOtp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(showOtpStep ? 'Xác nhận xóa' : 'Tiếp tục'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _verifyAndDeleteAccount(String code) async {
    setState(() => _loading = true);
    try {
      final success = await _profileService.verifyAccountDeletion(
        userId: widget.userId,
        code: code,
        token: widget.token,
      );

      if (!mounted) return false;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tài khoản đã được xóa'),
            backgroundColor: Colors.green,
          ),
        );
        // Đăng xuất sau 1 giây
        Future.delayed(const Duration(seconds: 1), () {
          widget.onLogout();
        });
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác nhận thất bại'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
