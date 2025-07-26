// lib/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/sport.dart';
import 'models/slot.dart';
import 'models/booking.dart';
import 'services/sports_service.dart';
import 'services/slot_service.dart';
import 'services/booking_service.dart';
import 'services/auth_service.dart';
import 'services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models/profile.dart';
import 'services/profile_service.dart';
import 'utils/cache_for.dart';

// ───────── Sports list ─────────
final sportsProvider = FutureProvider<List<Sport>>((ref) async {
  return sportsService.fetchSports();
});

// ───────── Slots for one sport ─────────
final slotsProvider = FutureProvider.family<List<Slot>, int>((ref, sportId) {
  return slotService.fetchBySport(sportId);
});

/// Upcoming slots for an activity, used to limit available dates.
final activitySlotsProvider =
    FutureProvider.autoDispose.family<List<Slot>, int>((ref, activityId) {
  ref.cacheFor(const Duration(minutes: 5));
  return slotService.fetchByActivity(activityId);
});

class SlotsByDateParams {
  const SlotsByDateParams({required this.activityId, required this.date});
  final int activityId;
  final DateTime date;

  @override
  bool operator ==(Object other) {
    return other is SlotsByDateParams &&
        other.activityId == activityId &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(activityId, date);
}

final slotsByDateProvider =
    FutureProvider.autoDispose.family<List<Slot>, SlotsByDateParams>((ref, params) {
  ref.cacheFor(const Duration(minutes: 5));
  return slotService.fetchByActivityDate(params.activityId, params.date);
});


enum AuthStatus { unauthenticated, authenticating, authenticated }

class AuthNotifier extends StateNotifier<AuthStatus> {
  AuthNotifier() : super(AuthStatus.unauthenticated) {
    _load();
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _load() async {
    final token = await _storage.read(key: 'access');
    if (token != null) {
      apiClient.options.headers['Authorization'] = 'Bearer $token';
      state = AuthStatus.authenticated;
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthStatus.authenticating;
    await authService.login(email, password);
    state = AuthStatus.authenticated;
  }

  Future<void> register(String email, String p1, String p2) async {
    state = AuthStatus.authenticating;
    await authService.register(email, p1, p2);
    state = AuthStatus.authenticated;
  }

  Future<void> registerProvider(String email, String p1, String p2, String name, String phone, String address) async {
    state = AuthStatus.authenticating;
    await authService.registerProvider(email, p1, p2, name, phone, address);
    state = AuthStatus.authenticated;
  }

  Future<void> loginWithGoogle() async {
    state = AuthStatus.authenticating;
    await authService.loginWithGoogle();
    state = AuthStatus.authenticated;
  }

  Future<void> logout() async {

    await authService.logout();
    state = AuthStatus.unauthenticated;
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStatus>((ref) => AuthNotifier());

final profileProvider = FutureProvider<Profile>((ref) async {
  return profileService.fetch();
});

class WishlistNotifier extends StateNotifier<Set<int>> {
  WishlistNotifier() : super({});
  void toggle(int id) {
    if (state.contains(id)) {
      final newState = Set<int>.from(state)..remove(id);
      state = newState;
    } else {
      state = {...state, id};
    }
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, Set<int>>(
  (ref) => WishlistNotifier(),
);

final bookingsProvider = FutureProvider<List<Booking>>((ref) async {
  return bookingService.fetchMine();
});
