import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:characters/characters.dart';

import '../models/profile_service.dart';
import '../models/profile_summary.dart';
import '../widgets/app_colors.dart';
import '../widgets/header.dart';
import '../widgets/top_message.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.userId,
    required this.profile,
  });

  final int userId;
  final ProfileSummary profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final ProfileService _profileService =
      ProfileService(baseUrl: _resolveBaseUrl());
  final _picker = ImagePicker();
  late ProfileSummary _profile = widget.profile;
  bool _saving = false;

  static String _resolveBaseUrl() {
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) {
      return overrideUrl;
    }
    if (Platform.isAndroid) {
      return 'http://192.168.1.4:8080';
    }
    return 'http://localhost:8080';
  }

  String _maskEmail(String value) {
    if (value.trim().isEmpty) return 'Chưa thiết lập';
    final parts = value.split('@');
    if (parts.length != 2) return value;
    final name = parts[0];
    final domain = parts[1];
    if (name.isEmpty) return value;
    return '${name.characters.first}******@$domain';
  }

  String _maskPhone(String value) {
    if (value.trim().isEmpty) return 'Chưa thiết lập';
    if (value.length <= 2) return value;
    final last = value.substring(value.length - 2);
    return '${'*' * (value.length - 2)}$last';
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 70);
    if (file == null) return;
    final bytes = await File(file.path).readAsBytes();
    final base64Data = base64Encode(bytes);
    final ext = file.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
    setState(() {
      _profile = ProfileSummary(
        id: _profile.id,
        fullName: _profile.fullName,
        email: _profile.email,
        phoneNumber: _profile.phoneNumber,
        address: _profile.address,
        avatar: 'data:image/$ext;base64,$base64Data',
        orderCount: _profile.orderCount,
        pendingCount: _profile.pendingCount,
        waitingPickupCount: _profile.waitingPickupCount,
        shippingCount: _profile.shippingCount,
        deliveredCount: _profile.deliveredCount,
        reviewPendingCount: _profile.reviewPendingCount,
        cancelledCount: _profile.cancelledCount,
        bookCount: _profile.bookCount,
        favoriteCount: _profile.favoriteCount,
        totalSpend: _profile.totalSpend,
        monthlySpend: _profile.monthlySpend,
      );
    });
    await _saveProfile(avatarOnly: true);
  }

  Future<void> _showPickOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Chụp ảnh'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAvatar(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile({bool avatarOnly = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final updated = await _profileService.updateProfile(
        userId: widget.userId,
        fullName: _profile.fullName,
        email: _profile.email,
        phoneNumber: _profile.phoneNumber,
        address: _profile.address,
        avatar: _profile.avatar,
      );
      setState(() => _profile = updated);
      if (!avatarOnly && mounted) {
        showTopMessage(
          context,
          message: 'Đã cập nhật hồ sơ',
          type: TopMessageType.success,
        );
      }
    } catch (_) {
      if (mounted) {
        showTopMessage(
          context,
          message: 'Không cập nhật được hồ sơ',
          type: TopMessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openEditSheet({
    required String title,
    required String initialValue,
    required ValueChanged<String> onSaved,
  }) async {
    final controller = TextEditingController(text: initialValue);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onSaved(controller.text.trim());
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Lưu'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    final avatar = _profile.avatar.trim();
    if (avatar.startsWith('data:image')) {
      final base64Part = avatar.split(',').last;
      final bytes = base64Decode(base64Part);
      return ClipOval(
        child: Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover),
      );
    }
    if (avatar.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatar,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    }
    final initial =
        _profile.fullName.trim().isNotEmpty ? _profile.fullName : 'A';
    return _AvatarPlaceholder(initial: initial.characters.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(
              title: 'Sửa hồ sơ',
              showBack: true,
              onBack: () => Navigator.pop(context, true),
              titleColor: Colors.white,
              iconColor: Colors.white,
              showDivider: false,
              backgroundGradient: const LinearGradient(
                colors: [AppColors.orange600, AppColors.rose500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              titleSize: 16,
              verticalPadding: 8,
              actions: const [],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            _buildAvatar(),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: _showPickOptions,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: AppColors.orange600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Sửa'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    children: [
                      _ProfileOptionTile(
                        title: 'Tên',
                        value: _profile.fullName.isEmpty
                            ? 'Thiết lập ngay'
                            : _profile.fullName,
                        onTap: () => _openEditSheet(
                          title: 'Sửa tên',
                          initialValue: _profile.fullName,
                          onSaved: (value) {
                            setState(() {
                              _profile = ProfileSummary(
                                id: _profile.id,
                                fullName: value,
                                email: _profile.email,
                                phoneNumber: _profile.phoneNumber,
                                address: _profile.address,
                                avatar: _profile.avatar,
                                orderCount: _profile.orderCount,
                                pendingCount: _profile.pendingCount,
                                waitingPickupCount: _profile.waitingPickupCount,
                                shippingCount: _profile.shippingCount,
                                deliveredCount: _profile.deliveredCount,
                                reviewPendingCount: _profile.reviewPendingCount,
                                cancelledCount: _profile.cancelledCount,
                                bookCount: _profile.bookCount,
                                favoriteCount: _profile.favoriteCount,
                                totalSpend: _profile.totalSpend,
                                monthlySpend: _profile.monthlySpend,
                              );
                            });
                            _saveProfile();
                          },
                        ),
                      ),
                      _DividerTile(),
                      _ProfileOptionTile(
                        title: 'Địa chỉ',
                        value: _profile.address.isEmpty
                            ? 'Thiết lập ngay'
                            : _profile.address,
                        onTap: () => _openEditSheet(
                          title: 'Sửa địa chỉ',
                          initialValue: _profile.address,
                          onSaved: (value) {
                            setState(() {
                              _profile = ProfileSummary(
                                id: _profile.id,
                                fullName: _profile.fullName,
                                email: _profile.email,
                                phoneNumber: _profile.phoneNumber,
                                address: value,
                                avatar: _profile.avatar,
                                orderCount: _profile.orderCount,
                                pendingCount: _profile.pendingCount,
                                waitingPickupCount: _profile.waitingPickupCount,
                                shippingCount: _profile.shippingCount,
                                deliveredCount: _profile.deliveredCount,
                                reviewPendingCount: _profile.reviewPendingCount,
                                cancelledCount: _profile.cancelledCount,
                                bookCount: _profile.bookCount,
                                favoriteCount: _profile.favoriteCount,
                                totalSpend: _profile.totalSpend,
                                monthlySpend: _profile.monthlySpend,
                              );
                            });
                            _saveProfile();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    children: [
                      _ProfileOptionTile(
                        title: 'Số điện thoại',
                        value: _maskPhone(_profile.phoneNumber),
                        onTap: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _ContactRequestPage(
                                title: 'Đổi số điện thoại',
                                type: _ContactType.phone,
                                userId: widget.userId,
                                currentValue: _profile.phoneNumber,
                                profileService: _profileService,
                              ),
                            ),
                          );
                          if (updated == true && mounted) {
                            final summary = await _profileService
                                .fetchProfileSummary(widget.userId);
                            setState(() => _profile = summary);
                          }
                        },
                      ),
                      _DividerTile(),
                      _ProfileOptionTile(
                        title: 'Email',
                        value: _maskEmail(_profile.email),
                        onTap: () async {
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _ContactRequestPage(
                                title: 'Đổi email',
                                type: _ContactType.email,
                                userId: widget.userId,
                                currentValue: _profile.email,
                                profileService: _profileService,
                              ),
                            ),
                          );
                          if (updated == true && mounted) {
                            final summary = await _profileService
                                .fetchProfileSummary(widget.userId);
                            setState(() => _profile = summary);
                          }
                        },
                      ),
                    ],
                  ),
                  if (_saving) ...[
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ContactType { phone, email }

class _ContactRequestPage extends StatefulWidget {
  const _ContactRequestPage({
    required this.title,
    required this.type,
    required this.userId,
    required this.currentValue,
    required this.profileService,
  });

  final String title;
  final _ContactType type;
  final int userId;
  final String currentValue;
  final ProfileService profileService;

  @override
  State<_ContactRequestPage> createState() => _ContactRequestPageState();
}

class _ContactRequestPageState extends State<_ContactRequestPage> {
  final TextEditingController _valueController = TextEditingController();
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _valueController.text = widget.currentValue;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_requesting) return;
    final value = _valueController.text.trim();
    if (value == widget.currentValue.trim()) {
      showTopMessage(
        context,
        message: 'Thông tin mới phải khác hiện tại',
        type: TopMessageType.error,
      );
      return;
    }
    setState(() => _requesting = true);
    try {
      if (widget.type == _ContactType.email) {
        await widget.profileService.requestEmailChange(
          userId: widget.userId,
          email: value,
        );
      } else {
        await widget.profileService.requestPhoneChange(
          userId: widget.userId,
          phoneNumber: value,
        );
      }
      if (!mounted) return;
      showTopMessage(
        context,
        message: 'Đã gửi mã xác nhận',
        type: TopMessageType.success,
      );
      final verified = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => _ContactVerifyPage(
            title: widget.title,
            type: widget.type,
            userId: widget.userId,
            value: value,
            profileService: widget.profileService,
          ),
        ),
      );
      if (verified == true && mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      showTopMessage(
        context,
        message: 'Đã xảy ra lỗi. Vui lòng thử lại sau.',
        type: TopMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.type == _ContactType.email;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(
              title: widget.title,
              showBack: true,
              onBack: () => Navigator.pop(context),
              titleColor: Colors.white,
              iconColor: Colors.white,
              showDivider: false,
              backgroundGradient: const LinearGradient(
                colors: [AppColors.orange600, AppColors.rose500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              titleSize: 16,
              verticalPadding: 8,
              actions: const [],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ModernInput(
                    label: isEmail ? 'Email mới' : 'Số điện thoại mới',
                    controller: _valueController,
                    keyboardType: isEmail
                        ? TextInputType.emailAddress
                        : TextInputType.phone,
                    prefixIcon:
                        isEmail ? Icons.email_outlined : Icons.phone_outlined,
                  ),
                  const SizedBox(height: 16),
                  _PrimaryButton(
                    label: _requesting ? 'Đang gửi...' : 'Tiếp theo',
                    onPressed: _requesting ? null : _requestOtp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactVerifyPage extends StatefulWidget {
  const _ContactVerifyPage({
    required this.title,
    required this.type,
    required this.userId,
    required this.value,
    required this.profileService,
  });

  final String title;
  final _ContactType type;
  final int userId;
  final String value;
  final ProfileService profileService;

  @override
  State<_ContactVerifyPage> createState() => _ContactVerifyPageState();
}

class _ContactVerifyPageState extends State<_ContactVerifyPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_verifying) return;
    setState(() => _verifying = true);
    try {
      if (widget.type == _ContactType.email) {
        await widget.profileService.verifyEmailChange(
          userId: widget.userId,
          email: widget.value,
          code: _codeController.text.trim(),
        );
      } else {
        await widget.profileService.verifyPhoneChange(
          userId: widget.userId,
          phoneNumber: widget.value,
          code: _codeController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      showTopMessage(
        context,
        message: 'Đã xảy ra lỗi. Vui lòng thử lại sau.',
        type: TopMessageType.error,
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(
              title: 'Nhập mã xác nhận',
              showBack: true,
              onBack: () => Navigator.pop(context),
              titleColor: Colors.white,
              iconColor: Colors.white,
              showDivider: false,
              backgroundGradient: const LinearGradient(
                colors: [AppColors.orange600, AppColors.rose500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              titleSize: 16,
              verticalPadding: 8,
              actions: const [],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ModernInput(
                    label: 'Mã xác nhận',
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 16),
                  _PrimaryButton(
                    label: _verifying ? 'Đang xác nhận...' : 'Xác nhận',
                    onPressed: _verifying ? null : _verifyOtp,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernInput extends StatelessWidget {
  const _ModernInput({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.prefixIcon,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: AppColors.orange600),
        filled: true,
        fillColor: AppColors.gray50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange600),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  const _ProfileOptionTile({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.gray600),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}

class _DividerTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.gray200);
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.orange50,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.orange600,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
