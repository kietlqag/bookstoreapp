class Address {
  const Address({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine,
    this.addressLineNew,
    this.isDefault = false,
  });

  final int id;
  final String fullName;
  final String phoneNumber;
  final String addressLine;
  final String? addressLineNew;
  final bool isDefault;

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      fullName: json['fullName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      addressLine: json['addressLine']?.toString() ?? '',
      addressLineNew: json['addressLineNew']?.toString(),
      isDefault: json['isDefault'] == true,
    );
  }

  Address copyWith({
    String? fullName,
    String? phoneNumber,
    String? addressLine,
    String? addressLineNew,
    bool? isDefault,
  }) {
    return Address(
      id: id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLine: addressLine ?? this.addressLine,
      addressLineNew: addressLineNew ?? this.addressLineNew,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class AddressSelection {
  const AddressSelection({
    required this.address,
    this.setAsDefault = false,
  });

  final Address address;
  final bool setAsDefault;
}
