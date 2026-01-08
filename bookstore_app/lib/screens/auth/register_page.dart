import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/app_colors.dart';
import '../../widgets/top_message.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.onRequestOtp,
    required this.onVerifyOtp,
    required this.onResendOtp,
    required this.onGoogleRegister,
    required this.onFacebookRegister,
    required this.onLogin,
  });

  final Future<void> Function(String fullName, String email, String password)
      onRequestOtp;
  final Future<void> Function(String email, String code) onVerifyOtp;
  final Future<void> Function(String email) onResendOtp;
  final Future<void> Function() onGoogleRegister;
  final Future<void> Function() onFacebookRegister;
  final VoidCallback onLogin;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = true;
  bool _isLoading = false;
  bool _otpSent = false;
  bool _isResending = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value.trim());
  }

  Future<void> _submit() async {
    if (_otpSent) {
      await _verifyOtp();
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      showTopMessage(
        context,
        message: 'Vui lòng đồng ý với điều khoản để tiếp tục.',
        type: TopMessageType.info,
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await widget.onRequestOtp(
        _fullNameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _otpSent = true;
      });
      showTopMessage(
        context,
        message: 'Đã gửi OTP. Vui lòng kiểm tra email.',
        type: TopMessageType.success,
      );
    } catch (error) {
      showTopMessage(
        context,
        message: 'Gửi mã OTP thất bại. Vui lòng thử lại sau.',
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

  Future<void> _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6 || code.contains(RegExp(r'[^0-9]'))) {
      showTopMessage(
        context,
        message: 'Vui lòng nhập mã OTP gồm 6 chữ số.',
        type: TopMessageType.info,
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      await widget.onVerifyOtp(_emailController.text.trim(), code);
    } catch (error) {
      showTopMessage(
        context,
        message: 'Mã OTP không đúng hoặc đã hết hạn. Vui lòng thử lại.',
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

  Future<void> _resendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      showTopMessage(
        context,
        message: 'Vui lòng nhập email hợp lệ.',
        type: TopMessageType.info,
      );
      return;
    }
    setState(() {
      _isResending = true;
    });
    try {
      await widget.onResendOtp(email);
      if (!mounted) return;
      showTopMessage(
        context,
        message: 'Đã gửi lại OTP. Vui lòng kiểm tra email.',
        type: TopMessageType.success,
      );
    } catch (error) {
      showTopMessage(
        context,
        message: 'Gửi lại mã OTP thất bại. Vui lòng thử lại sau.',
        type: TopMessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _handleSocial(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      showTopMessage(
        context,
        message: 'Đăng ký thất bại. Vui lòng thử lại sau.',
        type: TopMessageType.error,
      );
    }
  }

  void _distributeOtp(String value, int startIndex) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return;
    }

    var currentIndex = startIndex;
    for (final char in digits.split('')) {
      if (currentIndex >= _otpControllers.length) {
        break;
      }
      _otpControllers[currentIndex].text = char;
      currentIndex += 1;
    }

    final nextIndex = currentIndex.clamp(0, _otpFocusNodes.length - 1);
    _otpFocusNodes[nextIndex].requestFocus();
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
            height: 240,
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tạo tài khoản',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tham gia K-Book và bắt đầu hành trình đọc sách',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 20),
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
                        if (!_otpSent) ...[
                          Text(
                            'Họ và tên',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              hintText: 'Nhập họ và tên',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập họ và tên';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
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
                              hintText: 'Tạo mật khẩu',
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
                              if (value.length < 6) {
                                return 'Mật khẩu tối thiểu 6 ký tự';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Xác nhận mật khẩu',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              hintText: 'Nhập lại mật khẩu',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirm = !_obscureConfirm;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng xác nhận mật khẩu';
                              }
                              if (value != _passwordController.text) {
                                return 'Mật khẩu không khớp';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                onChanged: (value) {
                                  setState(() => _acceptTerms = value ?? false);
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  'Tôi đồng ý với điều khoản và chính sách.',
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_otpSent) ...[
                          Text(
                            'Mã OTP',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) {
                              return SizedBox(
                                width: 44,
                                child: TextField(
                                  controller: _otpControllers[index],
                                  focusNode: _otpFocusNodes[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    counterText: '',
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(6),
                                  ],
                                  onChanged: (value) {
                                    if (value.length > 1) {
                                      _otpControllers[index].text = '';
                                      _distributeOtp(value, index);
                                      return;
                                    }
                                    if (value.isNotEmpty && index < 5) {
                                      _otpFocusNodes[index + 1].requestFocus();
                                    }
                                    if (value.isEmpty && index > 0) {
                                      _otpFocusNodes[index - 1].requestFocus();
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mã xác thực đã được gửi đến email của bạn.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.gray600),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isResending ? null : _resendOtp,
                              child: Text(
                                _isResending ? 'Đang gửi lại...' : 'Gửi lại mã',
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange600,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _otpSent
                                ? (_isLoading
                                    ? 'Đang xác thực...'
                                    : 'Xác thực OTP')
                                : (_isLoading
                                    ? 'Đang đăng ký...'
                                    : 'Đăng ký'),
                          ),
                        ),
                        if (!_otpSent) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'hoặc đăng ký bằng',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.gray600),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _handleSocial(widget.onGoogleRegister),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                  onPressed: () =>
                                      _handleSocial(widget.onFacebookRegister),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Đã có tài khoản?'),
                    TextButton(
                      onPressed: widget.onLogin,
                      child: const Text('Đăng nhập'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
