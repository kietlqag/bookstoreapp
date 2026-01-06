import 'dart:convert';
import 'dart:io';

class PaymentInitiateResponse {
  const PaymentInitiateResponse({
    required this.transactionId,
    required this.provider,
    this.txnRef,
    this.paymentUrl,
    this.deeplink,
    this.qrCodeUrl,
    this.deeplinkMiniApp,
    this.qrImageUrl,
    this.qrContent,
    this.orderId,
  });

  final int transactionId;
  final String provider;
  final String? txnRef;
  final String? paymentUrl;
  final String? deeplink;
  final String? qrCodeUrl;
  final String? deeplinkMiniApp;
  final String? qrImageUrl;
  final String? qrContent;
  final int? orderId;

  factory PaymentInitiateResponse.fromJson(Map<String, dynamic> json) {
    final transaction = json['transaction'] as Map<String, dynamic>? ?? const {};
    return PaymentInitiateResponse(
      transactionId: transaction['id'] as int? ?? 0,
      provider: transaction['provider']?.toString() ?? '',
      txnRef: json['txnRef']?.toString() ??
          transaction['txnRef']?.toString(),
      paymentUrl: json['paymentUrl']?.toString(),
      deeplink: json['deeplink']?.toString(),
      qrCodeUrl: json['qrCodeUrl']?.toString(),
      deeplinkMiniApp: json['deeplinkMiniApp']?.toString(),
      qrImageUrl: json['qrImageUrl']?.toString(),
      qrContent: json['qrContent']?.toString(),
      orderId: json['orderId'] as int?,
    );
  }
}

class PaymentService {
  PaymentService({required this.baseUrl});

  final String baseUrl;

  Future<PaymentInitiateResponse> initiatePayment({
    required String methodCode,
    required double amount,
    Map<String, dynamic>? orderPayload,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/payments/initiate');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'methodCode': methodCode,
        'amount': amount,
        'orderPayload': orderPayload,
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PaymentServiceException('Request failed.');
      }
      if (body.isEmpty) {
        throw PaymentServiceException('Empty response.');
      }
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        throw PaymentServiceException('Invalid response format.');
      }
      return PaymentInitiateResponse.fromJson(data);
    } on SocketException {
      throw PaymentServiceException('Cannot connect to server.');
    } on FormatException {
      throw PaymentServiceException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }

  Future<PaymentStatus> fetchPaymentStatus(String txnRef) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/payments/transactions/$txnRef');
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PaymentServiceException('Request failed.');
      }
      if (body.isEmpty) {
        throw PaymentServiceException('Empty response.');
      }
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        throw PaymentServiceException('Invalid response format.');
      }
      return PaymentStatus.fromJson(data);
    } on SocketException {
      throw PaymentServiceException('Cannot connect to server.');
    } on FormatException {
      throw PaymentServiceException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }
}

class PaymentServiceException implements Exception {
  PaymentServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PaymentStatus {
  const PaymentStatus({
    required this.status,
    required this.orderId,
  });

  final String status;
  final int? orderId;

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      status: json['status']?.toString() ?? '',
      orderId: json['orderId'] as int?,
    );
  }
}
