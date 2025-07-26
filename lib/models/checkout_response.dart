class CheckoutResponse {
  CheckoutResponse({
    required this.clientSecret,
    required this.intentId,
    required this.bookingId,
  });

  final String clientSecret;
  final String intentId;
  final int bookingId;

  factory CheckoutResponse.fromJson(Map<String, dynamic> j) => CheckoutResponse(
        clientSecret: j['client_secret'] as String,
        intentId: j['intent_id'] as String,
        bookingId: j['booking_id'] as int,
      );
}

