import 'dart:io';

import 'package:flutter/material.dart';

import '../models/address.dart';
import '../models/address_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/header.dart';
import 'address_form_page.dart';

class AddressListPage extends StatefulWidget {
  const AddressListPage({
    super.key,
    required this.addresses,
    required this.selectedAddressId,
    required this.userId,
  });

  final List<Address> addresses;
  final int selectedAddressId;
  final int userId;

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  late List<Address> _addresses;
  late int _selectedAddressId;
  Address? _pendingDefaultAddress;
  late final AddressService _addressService =
      AddressService(baseUrl: _resolveBaseUrl());

  @override
  void initState() {
    super.initState();
    _addresses = List<Address>.from(widget.addresses);
    _selectedAddressId = widget.selectedAddressId;
  }

  static String _resolveBaseUrl() {
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) {
      return overrideUrl;
    }
    if (Platform.isAndroid) {
      return 'http://192.168.1.155:8080';
    }
    return 'http://localhost:8080';
  }

  static List<String> _splitAddressLines(String value) {
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
      final detail = parts.first;
      final admin = parts.skip(1).join(', ');
      return [detail, admin];
    }
    final detail = parts.take(adminStart).join(', ');
    final admin = parts.skip(adminStart).join(', ');
    return [detail, admin];
  }

  static List<Widget> _buildAddressLines({
    required String label,
    required String value,
    required BuildContext context,
    required TextStyle? labelStyle,
    required TextStyle? valueStyle,
  }) {
    final lines = _splitAddressLines(value);
    final firstLine = label.isEmpty
        ? lines.first
        : '$label ${lines.first}';
    final widgets = <Widget>[
      Text.rich(
        TextSpan(
          text: label.isEmpty ? firstLine : '$label ',
          style: labelStyle,
          children: label.isEmpty
              ? null
              : [
                  TextSpan(
                    text: lines.first,
                    style: valueStyle,
                  ),
                ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ];
    if (lines.length > 1) {
      widgets.add(Text(
        lines[1],
        style: valueStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ));
    }
    return widgets;
  }

  Future<void> _applyDefault(Address address) async {
    setState(() {
      _addresses = _addresses
          .map((item) => item.copyWith(isDefault: item.id == address.id))
          .toList();
      _pendingDefaultAddress = address;
      _selectedAddressId = address.id;
    });
    await _addressService.setDefaultAddress(
      userId: widget.userId,
      addressId: address.id,
    );
  }

  void _handleBack() {
    final selected = _addresses.firstWhere(
      (address) => address.id == _selectedAddressId,
      orElse: () => _addresses.isNotEmpty
          ? _addresses.first
          : Address(
              id: 0,
              fullName: '',
              phoneNumber: '',
              addressLine: '',
            ),
    );
    if (selected.id == 0) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(
      context,
      AddressSelection(
        address: selected,
        setAsDefault: _pendingDefaultAddress?.id == selected.id,
      ),
    );
  }

  Future<void> _openEditAddress(Address address) async {
    final result = await Navigator.of(context).push<AddressFormResult>(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(
          userId: widget.userId,
          initialAddress: address,
        ),
      ),
    );
    if (result == null) return;
    if (result.deleted) {
      setState(() {
        _addresses.removeWhere((item) => item.id == address.id);
        if (_selectedAddressId == address.id && _addresses.isNotEmpty) {
          _selectedAddressId = _addresses.first.id;
        }
        if (_addresses.isEmpty) {
          _selectedAddressId = 0;
        }
      });
      return;
    }
    final updated = result.address;
    if (updated == null) return;
    setState(() {
      _addresses = _addresses
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
      if (updated.isDefault) {
        _addresses = _addresses
            .map((item) => item.copyWith(isDefault: item.id == updated.id))
            .toList();
      }
      _selectedAddressId = updated.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(
              title: 'Địa chỉ của tôi',
              showBack: true,
              onBack: _handleBack,
              titleColor: Colors.white,
              iconColor: Colors.white,
              backgroundGradient: const LinearGradient(
                colors: [AppColors.orange600, AppColors.rose500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              showDivider: false,
              verticalPadding: 6,
              actions: const [],
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: _addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final address = _addresses[index];
                  final isSelected = address.id == _selectedAddressId;
                  return InkWell(
                    onTap: () => Navigator.pop(
                      context,
                      AddressSelection(address: address),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.orange600
                              : AppColors.gray200,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: AppColors.orange600,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${address.fullName} | ${address.phoneNumber}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (address.addressLineNew != null &&
                                    address.addressLineNew!.isNotEmpty) ...[
                                  ..._buildAddressLines(
                                    label: 'Mới:',
                                    value: address.addressLineNew!,
                                    context: context,
                                    labelStyle: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.gray700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    valueStyle: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.gray700,
                                          fontWeight: FontWeight.w400,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  ..._buildAddressLines(
                                    label: 'Cũ:',
                                    value: address.addressLine,
                                    context: context,
                                    labelStyle: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.gray600,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                    valueStyle: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.gray600,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                        ),
                                  ),
                                ] else
                                  ..._buildAddressLines(
                                    label: '',
                                    value: address.addressLine,
                                    context: context,
                                    labelStyle: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.gray600),
                                    valueStyle: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.gray600),
                                  ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    if (address.isDefault)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.orange50,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Mặc định',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: AppColors.orange600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      )
                                    else
                                      TextButton(
                                        onPressed: () => _applyDefault(address),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        child: const Text('Đặt làm mặc định'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? AppColors.orange600
                                    : AppColors.gray400,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _openEditAddress(address),
                                child: Text(
                                  'Sửa',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.gray600,
                                        fontSize: 11,
                                      ),
                                ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final createdResult =
                        await Navigator.of(context).push<AddressFormResult>(
                      MaterialPageRoute(
                        builder: (_) => AddressFormPage(userId: widget.userId),
                      ),
                    );
                    final created = createdResult?.address;
                    if (created == null) return;
                    setState(() {
                      if (created.isDefault) {
                        _addresses = _addresses
                            .map((item) => item.copyWith(isDefault: false))
                            .toList();
                        _pendingDefaultAddress = created;
                      }
                      _addresses.removeWhere((item) => item.id == created.id);
                      _addresses = [created, ..._addresses];
                      _selectedAddressId = created.id;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm địa chỉ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange600,
                    side: const BorderSide(color: AppColors.orange600),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}











