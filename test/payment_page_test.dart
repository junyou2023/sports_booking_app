import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:sports_booking_app/models/slot.dart';
import 'package:sports_booking_app/screens/payment_page.dart';
import 'package:sports_booking_app/services/api_client.dart';

class MockDio extends Mock implements Dio {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter.stripe/paymentsheet');
  Stripe.publishableKey = 'test';

  final slotJson = {
    'id': 1,
    'sport': {'id': 1, 'name': 'Tennis', 'banner': '', 'description': ''},
    'activity': 1,
    'facility': null,
    'title': 'Slot',
    'location': 'Loc',
    'begins_at': DateTime(2024, 1, 1).toIso8601String(),
    'ends_at': DateTime(2024, 1, 1, 1).toIso8601String(),
    'capacity': 10,
    'price': 5.0,
    'rating': 4.0,
    'seats_left': 10,
  };

  testWidgets('network error shows readable message', (tester) async {
    final mock = MockDio();
    apiClient = mock;
    when(() => mock.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenThrow(DioException(
      requestOptions: RequestOptions(path: 'merchant/slots/1/'),
      response: Response(
          requestOptions: RequestOptions(path: 'merchant/slots/1/'),
          statusCode: 404),
    ));
    when(() => mock.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
            requestOptions: RequestOptions(path: 'payments/checkout/'),
            message: 'SocketException'));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async => null);

    final slot = Slot.fromJson(slotJson);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: PaymentPage(slot: slot)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pay & Book'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('SocketException'), findsOneWidget);
    expect(find.textContaining('null: null'), findsNothing);
  });
}
