import 'package:dio/dio.dart';
import 'api_client.dart';

class MerchantBookingService { // R2
  Future<Map<String, dynamic>> fetchPaged({ // R2
    String? cursor,
    String? status,
    bool? paid,
    String? createdAfter,
    String? createdBefore,
    int? activityId,
  }) async {
    final params = <String, dynamic>{};
    if (cursor != null) params['cursor'] = cursor;
    if (status != null) params['status'] = status;
    if (paid != null) params['paid'] = paid.toString();
    if (createdAfter != null) params['created_after'] = createdAfter;
    if (createdBefore != null) params['created_before'] = createdBefore;
    if (activityId != null) params['activity'] = activityId;
    final res = await apiClient.get('/merchant/bookings/paged/', queryParameters: params);
    return res.data as Map<String, dynamic>;
  }

  Future<void> cancel(int id) async { // R2
    await apiClient.post('/merchant/bookings/' + id.toString() + '/cancel/');
  }
}

final merchantBookingService = MerchantBookingService(); // R2
