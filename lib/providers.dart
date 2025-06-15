// Central place holding all Riverpod providers.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/sport.dart';
import 'services/sports_service.dart';

final sportsProvider = FutureProvider<List<Sport>>((ref) async {
  return SportsService().fetchSports();
});