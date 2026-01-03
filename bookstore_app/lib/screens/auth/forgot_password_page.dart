import 'package:flutter/material.dart';

import '../../widgets/app_colors.dart';
import '../../widgets/top_message.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isValidEmail(String value) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value.trim());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    showTopMessage(
      context,
      message: 'Đã gửi link đặt lại (mô phỏng).',
      type: TopMessageType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: widget.onBack,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.arrow_back, color: AppColors.gray700),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Quên mật khẩu',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhập email để nhận link đặt lại.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.gray600),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: TextFormField(
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
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Gửi link đặt lại'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

