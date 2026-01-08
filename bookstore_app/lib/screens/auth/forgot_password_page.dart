import 'package:flutter/material.dart';

import '../../models/auth_service.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/top_message.dart';
import 'verify_reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
    required this.onBack,
    required this.baseUrl,
  });

  final VoidCallback onBack;
  final String baseUrl;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AuthService _authService = AuthService(baseUrl: widget.baseUrl);
  bool _isLoading = false;

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value.trim());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.forgotPassword(email: _emailController.text.trim());
      if (!mounted) return;
      
      // Navigate to verify reset password page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => VerifyResetPasswordPage(
            email: _emailController.text.trim(),
            baseUrl: widget.baseUrl,
            onBack: widget.onBack,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      // Extract error message from exception
      String errorMessage = 'Đã xảy ra lỗi khi gửi mã OTP. Vui lòng thử lại sau.';
      
      // AuthException.toString() returns the message directly
      final errorStr = error.toString();
      
      // Try to extract the actual error message
      if (errorStr.contains('Exception: ')) {
        errorMessage = errorStr.split('Exception: ').last.trim();
      } else if (errorStr.contains(':')) {
        // Split by colon and get the last part, but skip common prefixes
        final parts = errorStr.split(':');
        if (parts.length > 1) {
          errorMessage = parts.sublist(1).join(':').trim();
        } else {
          errorMessage = errorStr.trim();
        }
      } else if (errorStr.isNotEmpty) {
        errorMessage = errorStr.trim();
      }
      
      // Remove common prefixes if present
      errorMessage = errorMessage
          .replaceAll(RegExp(r'^Error:\s*'), '')
          .replaceAll(RegExp(r'^AuthException:\s*'), '')
          .trim();
      
      if (errorMessage.isEmpty) {
        errorMessage = 'Đã xảy ra lỗi khi gửi mã OTP. Vui lòng thử lại sau.';
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
                    'Quên mật khẩu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nhập email để nhận mã OTP đặt lại mật khẩu.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
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
                          Text(
                            'Email',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.gray700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'example@email.com',
                              hintStyle: TextStyle(fontSize: 14, color: AppColors.gray400),
                              prefixIcon: Icon(Icons.mail_outline, size: 20, color: AppColors.gray500),
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
                                return 'Vui lòng nhập email';
                              }
                              if (!_isValidEmail(value)) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submit,
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
                                      'Gửi mã OTP',
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

