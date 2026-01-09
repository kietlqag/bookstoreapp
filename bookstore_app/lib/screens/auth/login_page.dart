import 'package:flutter/material.dart';

import '../../widgets/app_colors.dart';
import '../../widgets/top_message.dart';
import '../../models/auth_service.dart' show TwoFactorRequiredException;

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onLogin,
    required this.onVerifyOtp,
    required this.onRegister,
    required this.onForgot,
    required this.onGoogleLogin,
    required this.onFacebookLogin,
  });

  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function(String email, String code) onVerifyOtp;
  final VoidCallback onRegister;
  final VoidCallback onForgot;
  final Future<void> Function() onGoogleLogin;
  final Future<void> Function() onFacebookLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value.trim());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      await widget.onLogin(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } on TwoFactorRequiredException catch (e) {
      // Show 2FA OTP dialog
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showTwoFactorDialog(e.email, e.message);
      }
    } catch (error) {
      // Hiển thị message lỗi cụ thể từ backend
      final errorMessage = error.toString();
      showTopMessage(
        context,
        message: errorMessage.isNotEmpty 
            ? errorMessage 
            : 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.',
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

  void _showTwoFactorDialog(String email, String message) {
    final otpController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.security, color: AppColors.orange600),
              SizedBox(width: 8),
              Text('Xác thực 2 lớp'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Mã OTP',
                  hintText: 'Nhập mã 6 số',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.pop(context);
                      // Retry login
                      _submit();
                    },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final code = otpController.text.trim();
                      if (code.length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập mã OTP 6 số'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);
                      try {
                        await widget.onVerifyOtp(email, code);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error.toString().replaceFirst('Exception: ', '')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSocial(Future<void> Function() action) async {
    try {
      await action();
    } on TwoFactorRequiredException catch (e) {
      // Show 2FA OTP dialog for social login
      if (mounted) {
        _showTwoFactorDialog(e.email, e.message);
      }
    } catch (error) {
      // Hiển thị message lỗi cụ thể từ backend
      final errorMessage = error.toString();
      showTopMessage(
        context,
        message: errorMessage.isNotEmpty 
            ? errorMessage 
            : 'Đăng nhập thất bại. Vui lòng thử lại sau.',
        type: TopMessageType.error,
      );
    }
  }

  Widget _socialBadge({
    required String label,
    required Color background,
  }) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
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
            height: 260,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    24 + bottomInset,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - bottomInset,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Chào mừng trở lại',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Đăng nhập để tiếp tục mua sắm',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    hintText: 'example@email.com',
                                    prefixIcon: Icon(Icons.mail_outline),
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
                                const SizedBox(height: 16),
                                Text(
                                  'Mật khẩu',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    hintText: 'Nhập mật khẩu',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, innerConstraints) {
                                    final checkbox = Transform.scale(
                                      scale: 0.85,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? true;
                                          });
                                        },
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    );
                                    final rememberText = const Text(
                                      'Ghi nhớ đăng nhập',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12),
                                    );
                                    final forgotButton = TextButton(
                                      onPressed: widget.onForgot,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Quên mật khẩu?',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    );

                                    return Row(
                                      children: [
                                        checkbox,
                                        Expanded(child: rememberText),
                                        forgotButton,
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                FilledButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.orange600,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: Text(
                                    _isLoading
                                        ? 'Đang đăng nhập...'
                                        : 'Đăng nhập',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        'hoặc tiếp tục với',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: AppColors.gray600),
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _handleSocial(widget.onGoogleLogin),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _socialBadge(
                                              label: 'G',
                                              background: const Color(0xFFDB4437),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Google'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _handleSocial(
                                          widget.onFacebookLogin,
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _socialBadge(
                                              label: 'f',
                                              background: const Color(0xFF1877F2),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Facebook'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            const Text('Chưa có tài khoản?'),
                            TextButton(
                              onPressed: widget.onRegister,
                              child: const Text('Tạo tài khoản'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
