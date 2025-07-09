// lib/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/sport.dart';
import 'models/slot.dart';
import 'services/sports_service.dart';
import 'services/slot_service.dart';
import 'services/auth_service.dart';

// ───────── Sports list ─────────
final sportsProvider = FutureProvider<List<Sport>>((ref) async {
  return sportsService.fetchSports();
});

// ───────── Slots for one sport ─────────
final slotsProvider = FutureProvider.family<List<Slot>, int>((ref, sportId) {
  return slotService.fetchBySport(sportId);
});

final authProvider = Provider<AuthService>((ref) => authService);
