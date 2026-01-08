import 'package:flutter/material.dart';

import '../../models/auth_service.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/top_message.dart';

class VerifyResetPasswordPage extends StatefulWidget {
  const VerifyResetPasswordPage({
    super.key,
    required this.email,
    required this.baseUrl,
    required this.onBack,
  });

  final String email;
  final String baseUrl;
  final VoidCallback onBack;

  @override
  State<VerifyResetPasswordPage> createState() => _VerifyResetPasswordPageState();
}

class _VerifyResetPasswordPageState extends State<VerifyResetPasswordPage> {
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AuthService _authService = AuthService(baseUrl: widget.baseUrl);
  
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_otpController.text.trim().isEmpty) {
      showTopMessage(
        context,
        message: 'Vui lòng nhập mã OTP.',
        type: TopMessageType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Reset password (will verify OTP internally)
      await _authService.resetPassword(
        email: widget.email,
        code: _otpController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );
      
      if (!mounted) return;
      
      showTopMessage(
        context,
        message: 'Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại.',
        type: TopMessageType.success,
      );
      
      // Navigate back to login after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    } catch (error) {
      if (!mounted) return;
      // Extract error message from exception
      String errorMessage = 'Đã xảy ra lỗi khi đặt lại mật khẩu. Vui lòng thử lại sau.';
      final errorStr = error.toString();
      
      // AuthException.toString() returns the message directly
      if (errorStr.isNotEmpty && !errorStr.contains('Exception')) {
        errorMessage = errorStr;
      } else if (errorStr.contains('Exception: ')) {
        errorMessage = errorStr.split('Exception: ').last.trim();
      } else if (errorStr.contains(':')) {
        errorMessage = errorStr.split(':').last.trim();
      }
      
      showTopMessage(
        context,
        message: errorMessage,
        type: TopMessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.orange600, AppColors.rose500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            height: 220,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: widget.onBack,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Đặt lại mật khẩu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nhập mã OTP và mật khẩu mới.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Email: ${widget.email}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // OTP Field
                          Text(
                            'Mã OTP',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.gray700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            enabled: !_isLoading,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Nhập mã OTP (6 chữ số)',
                              hintStyle: TextStyle(fontSize: 14, color: AppColors.gray400),
                              prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.gray500),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.gray200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.gray200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.orange600, width: 1.5),
                              ),
                              filled: true,
                              fillColor: AppColors.gray50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mã OTP';
                              }
                              if (value.length != 6) {
                                return 'Mã OTP phải có 6 chữ số';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // New Password Field
                          Text(
                            'Mật khẩu mới',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.gray700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNewPassword,
                            enabled: !_isLoading,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Mật khẩu mới',
                              hintStyle: TextStyle(fontSize: 14, color: AppColors.gray400),
                              prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.gray500),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.gray500,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.gray200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.gray200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.orange600, width: 1.5),
                              ),
                              filled: true,
                              fillColor: AppColors.gray50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mật khẩu mới';
                              }
                              if (value.length < 6) {
                                return 'Mật khẩu phải có ít nhất 6 ký tự';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Confirm Password Field
                          Text(
                            'Xác nhận mật khẩu mới',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.gray700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            enabled: !_isLoading,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Xác nhận mật khẩu mới',
                              hintStyle: TextStyle(fontSize: 14, color: AppColors.gray400),
                              prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.gray500),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.gray500,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.gray200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.gray200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.orange600, width: 1.5),
                              ),
                              filled: true,
                              fillColor: AppColors.gray50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng xác nhận mật khẩu';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Mật khẩu xác nhận không khớp';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.orange600,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Đặt lại mật khẩu',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}