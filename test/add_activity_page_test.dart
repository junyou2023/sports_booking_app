import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:image_picker/image_picker.dart';
import 'package:sports_booking_app/services/api_client.dart';
import 'package:sports_booking_app/screens/add_activity_page.dart';
import 'package:sports_booking_app/services/activity_service.dart';
import 'package:sports_booking_app/providers/org_provider.dart';

class _ThrowingActivityService extends ActivityService {
  @override
  Future<void> createActivity(
      int sport,
      int discipline,
      int? variant,
      String title,
      String description,
      int difficulty,
      int duration,
      double basePrice,
      {required int organizationId,
      XFile? imageFile}) async {
    throw Exception('boom');
  }
}

void main() {
  testWidgets('non DioException surfaces as snackbar', (tester) async {
    apiClient = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response(requestOptions: options, data: []));
      }));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        orgsProvider.overrideWith((ref) async => [
              {'id': 1, 'name': 'Org'}
            ]),
        selectedOrgProvider.overrideWith((ref) => StateController<int?>(1)),
      ],
      child: MaterialApp(home: AddActivityPage(service: _ThrowingActivityService())),
    ));
    await tester.pumpAndSettle();

    final state = tester.state<_AddActivityPageState>(find.byType(AddActivityPage));
    state.sportId = 1;
    state.disciplineId = 1;
    state.titleCtrl.text = 'T';
    state.descCtrl.text = 'D';
    state.durationCtrl.text = '60';
    state.priceCtrl.text = '10';
    await tester.tap(find.text('Create'));
    await tester.pump();
    expect(find.textContaining('Create activity failed'), findsOneWidget);
  });
}
