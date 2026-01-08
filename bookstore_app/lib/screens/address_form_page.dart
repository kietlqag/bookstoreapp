import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/address.dart';
import '../models/address_service.dart';
import '../widgets/app_colors.dart';
import 'location_picker_page.dart';

class AddressFormPage extends StatefulWidget {
  const AddressFormPage({
    super.key,
    required this.userId,
    this.initialAddress,
  });

  final int userId;
  final Address? initialAddress;

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class AddressFormResult {
  const AddressFormResult({
    this.address,
    this.deleted = false,
  });

  final Address? address;
  final bool deleted;
}

class _AddressFormPageState extends State<AddressFormPage> {
  LocationSelection? _selectedRegion;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  late final AddressService _addressService =
      AddressService(baseUrl: _resolveBaseUrl());
  Address? _originalAddress;
  bool _saving = false;
  bool _setDefault = false;

  @override
  void initState() {
    super.initState();
    _originalAddress = widget.initialAddress;
    if (_originalAddress != null) {
      _fullNameController.text = _originalAddress!.fullName;
      _phoneController.text = _originalAddress!.phoneNumber;
      _streetController.text = _extractStreet(
        _originalAddress!.addressLineNew?.isNotEmpty == true
            ? _originalAddress!.addressLineNew!
            : _originalAddress!.addressLine,
      );
      _setDefault = _originalAddress!.isDefault;
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<LocationSelection>(
      MaterialPageRoute(
        builder: (_) => const LocationPickerPage(),
      ),
    );
    if (result == null || result.displayName.isEmpty) return;
    setState(() {
      _selectedRegion = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _originalAddress != null;
    final candidateNewLine = _originalAddress?.addressLineNew?.isNotEmpty == true
        ? _originalAddress!.addressLineNew!
        : null;
    final candidateOldLine = _originalAddress?.addressLine;
    final currentNewLine = (candidateNewLine != null &&
            _splitDetailAndAdmin(candidateNewLine).length > 1)
        ? candidateNewLine
        : (candidateOldLine ?? candidateNewLine);
    final currentOldLine = _originalAddress?.addressLine;
    final currentParts = currentNewLine == null
        ? const <String>[]
        : _splitDetailAndAdmin(currentNewLine);
    final currentAdminLine = currentParts.length > 1 ? currentParts[1] : null;
    final oldParts = currentOldLine == null
        ? const <String>[]
        : _splitDetailAndAdmin(currentOldLine);
    final oldAdminLine = oldParts.length > 1 ? oldParts[1] : currentOldLine;
    final streetText = _streetController.text.trim();
    final canSubmit = _fullNameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _streetController.text.trim().isNotEmpty &&
        (_selectedRegion != null || isEditing) &&
        !_saving;
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text(isEditing ? 'S\u1eeda \u0111\u1ecba ch\u1ec9' : '\u0110\u1ecba ch\u1ec9 m\u1edbi'),
        centerTitle: false,
        toolbarHeight: 44,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          _SectionCard(
            title: 'Th\u00f4ng tin',
            child: Column(
              children: [
                _FormInput(
                  controller: _fullNameController,
                  hintText: 'H\u1ecd v\u00e0 t\u00ean',
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.name,
                  onChanged: (_) => setState(() {}),
                ),
                const _DividerLine(),
                _FormInput(
                  controller: _phoneController,
                  hintText: 'S\u1ed1 \u0111i\u1ec7n tho\u1ea1i',
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                ),
                const _DividerLine(),
                InkWell(
                  onTap: _openLocationPicker,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedRegion == null
                                  ? isEditing
                                      ? (currentAdminLine ??
                                          currentNewLine ??
                                          '')
                                      : 'T\u1ec9nh/Th\u00e0nh ph\u1ed1, Qu\u1eadn/Huy\u1ec7n, Ph\u01b0\u1eddng/X\u00e3'
                                  : _selectedRegion!.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: _selectedRegion == null
                                        ? AppColors.gray600
                                        : AppColors.gray900,
                                  ),
                            ),
                            if (_selectedRegion?.oldDisplayName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'C\u0169: ${_selectedRegion!.oldDisplayName!}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.gray600),
                              ),
                            ] else if (isEditing &&
                                oldAdminLine != null &&
                                oldAdminLine.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'C\u0169: $oldAdminLine',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.gray600),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.gray400,
                      ),
                    ],
                  ),
                ),
                const _DividerLine(),
                _FormInput(
                  controller: _streetController,
                  hintText: 'T\u00ean \u0111\u01b0\u1eddng, T\u00f2a nh\u00e0, S\u1ed1 nh\u00e0.',
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.streetAddress,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\u0110\u1eb7t l\u00e0m \u0111\u1ecba ch\u1ec9 m\u1eb7c \u0111\u1ecbnh',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Transform.scale(
                  scale: 0.5,
                  child: Switch(
                    value: _setDefault,
                    onChanged: (value) {
                      setState(() {
                        _setDefault = value;
                      });
                    },
                    activeColor: AppColors.orange600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.gray200)),
          ),
          child: Row(
            children: [
              if (isEditing) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _deleteAddress,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rose500,
                      side: const BorderSide(color: AppColors.rose500),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('X\u00f3a'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: canSubmit ? _saveAddress : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canSubmit ? AppColors.orange600 : AppColors.gray200,
                    foregroundColor:
                        canSubmit ? Colors.white : AppColors.gray600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 18),
                            const SizedBox(width: 6),
                            Text(isEditing ? 'C\u1eadp nh\u1eadt' : 'Ho\u00e0n th\u00e0nh'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Future<void> _saveAddress() async {
    final region = _selectedRegion;
    setState(() {
      _saving = true;
    });
    try {
      final street = _streetController.text.trim();
      String? addressLineNew;
      String? addressLineOld;
      if (region != null) {
        if (_mergeApiKey.isNotEmpty) {
          addressLineNew = await _convertAddressLine(
            streetAddress: street,
            provinceCode: region.provinceCode,
            districtCode: region.districtCode,
            wardCode: region.wardCode,
          );
        }
        addressLineNew ??= region.displayName.isNotEmpty
            ? '$street, ${region.displayName}'
            : null;
        addressLineOld = region.oldDisplayName != null
            ? '$street, ${region.oldDisplayName}'
            : '$street, ${region.displayName}';
      } else if (_originalAddress != null) {
        addressLineOld = _replaceStreet(_originalAddress!.addressLine, street);
        if (_originalAddress!.addressLineNew?.isNotEmpty == true) {
          addressLineNew = _replaceStreet(
            _originalAddress!.addressLineNew!,
            street,
          );
        }
      }
      if (addressLineOld == null || addressLineOld.trim().isEmpty) {
        setState(() {
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy địa chỉ sau khi tìm kiếm.')),
        );
        return;
      }
      final fullName = _fullNameController.text.trim();
      final phoneNumber = _phoneController.text.trim();
      final address = _originalAddress == null
          ? await _addressService.createAddress(
              userId: widget.userId,
              fullName: fullName,
              phoneNumber: phoneNumber,
              addressLine: addressLineOld,
              addressLineNew: addressLineNew,
              isDefault: _setDefault,
            )
          : await _addressService.updateAddress(
              addressId: _originalAddress!.id,
              userId: widget.userId,
              fullName: fullName,
              phoneNumber: phoneNumber,
              addressLine: addressLineOld,
              addressLineNew: addressLineNew,
              isDefault: _setDefault,
            );
      if (!mounted) return;
      Navigator.pop(context, AddressFormResult(address: address));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lưu địa chỉ thất bại.')),
      );
    }
  }

  Future<void> _deleteAddress() async {
    if (_originalAddress == null) return;
    setState(() {
      _saving = true;
    });
    try {
      await _addressService.deleteAddress(
        addressId: _originalAddress!.id,
        userId: widget.userId,
      );
      if (!mounted) return;
      Navigator.pop(context, const AddressFormResult(deleted: true));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa địa chỉ thất bại.')),
      );
    }
  }
  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  static const String _mergeApiKey = String.fromEnvironment('TTP_API_KEY');
  static const String _mergeBaseUrl = 'https://tinhthanhpho.com/api/v1';

  static String _extractStreet(String value) {
    final parts = _splitDetailAndAdmin(value);
    if (parts.isEmpty) return value.trim();
    return parts.first.trim();
  }

  static String _replaceStreet(String fullAddress, String street) {
    final trimmedStreet = street.trim();
    if (fullAddress.trim().isEmpty) return trimmedStreet;
    final parts = fullAddress.split(',');
    if (parts.isEmpty) return trimmedStreet;
    parts[0] = trimmedStreet;
    return parts.map((part) => part.trim()).join(', ');
  }

  static List<String> _splitDetailAndAdmin(String value) {
    final parts = value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length <= 1) {
      return [value.trim()];
    }
    const adminPrefixes = [
      'xã ',
      'phường ',
      'thị trấn ',
      'thị xã ',
      'thành phố ',
      'huyện ',
      'quận ',
      'tỉnh ',
      'đặc khu ',
    ];
    var adminStart = -1;
    for (var i = 0; i < parts.length; i++) {
      final lower = parts[i].toLowerCase();
      if (adminPrefixes.any(lower.startsWith)) {
        adminStart = i;
        break;
      }
    }
    if (adminStart <= 0) {
      return [parts.first, parts.skip(1).join(', ')];
    }
    return [
      parts.take(adminStart).join(', '),
      parts.skip(adminStart).join(', '),
    ];
  }

  static String _formatWithType(String name, String type) {
    if (name.isEmpty) return '';
    if (type.isEmpty || name.startsWith(type)) {
      return name;
    }
    return '$type $name';
  }

  static String _formatAddressPart(dynamic part) {
    if (part is Map<String, dynamic>) {
      final name = part['name']?.toString() ?? '';
      final type = part['type']?.toString() ?? '';
      return _formatWithType(name, type);
    }
    return part?.toString() ?? '';
  }

  static String? _buildAddressFromNewBlock(
    Map<String, dynamic> newBlock,
    String streetAddress,
  ) {
    final wardPart = _formatAddressPart(
      newBlock['ward'] ?? newBlock['new_ward'],
    );
    final districtPart = _formatAddressPart(
      newBlock['district'] ?? newBlock['new_district'],
    );
    final provincePart = _formatAddressPart(
      newBlock['province'] ?? newBlock['new_province'],
    );
    final parts = <String>[];
    final trimmedStreet = streetAddress.trim();
    if (trimmedStreet.isNotEmpty) {
      parts.add(trimmedStreet);
    }
    if (wardPart.isNotEmpty) {
      parts.add(wardPart);
    }
    if (districtPart.isNotEmpty) {
      parts.add(districtPart);
    }
    if (provincePart.isNotEmpty) {
      parts.add(provincePart);
    }
    if (parts.length < 2) return null;
    return parts.join(', ');
  }

  Future<String?> _convertAddressLine({
    required String streetAddress,
    required String provinceCode,
    required String districtCode,
    required String wardCode,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$_mergeBaseUrl/convert/address');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.headers.set('Authorization', 'Bearer $_mergeApiKey');
      request.headers.set('Accept', 'application/json');
      request.write(jsonEncode({
        'provinceCode': provinceCode,
        'districtCode': districtCode,
        'wardCode': wardCode,
        'streetAddress': streetAddress,
      }));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      if (body.isEmpty) return null;
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['success'] == false) {
        return null;
      }
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        final newBlock = data['new'];
        if (newBlock is Map<String, dynamic>) {
          final composed = _buildAddressFromNewBlock(newBlock, streetAddress);
          if (composed != null && composed.isNotEmpty) {
            return composed;
          }
          final fullAddress = newBlock['fullAddress']?.toString() ??
              newBlock['full_address']?.toString();
          if (fullAddress != null && fullAddress.isNotEmpty) {
            return fullAddress;
          }
        }
        return data['new_address']?.toString() ??
            data['newAddress']?.toString() ??
            data['new_address_line']?.toString() ??
            data['address_new']?.toString() ??
            data['full_address']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    this.title,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final String? title;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  const _FormInput({
    required this.controller,
    required this.hintText,
    this.textInputAction,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodySmall,
        decoration: InputDecoration(
          hintText: hintText,
          isDense: true,
          filled: false,
          border: InputBorder.none,
          hintStyle:
              Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.gray600,
                  ),
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: AppColors.gray200),
    );
  }
}















