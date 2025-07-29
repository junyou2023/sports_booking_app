import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/activity.dart';
import '../models/paginated.dart';
import '../services/favorite_service.dart';
import '../widgets/auth_sheet.dart';
import '../utils/snackbar.dart';
import '../providers.dart';

class FavoriteIdsNotifier extends StateNotifier<Set<int>> {
  FavoriteIdsNotifier(this.ref) : super(<int>{}) {
    ref.listen<AuthStatus>(authNotifierProvider, (prev, next) {
      if (next == AuthStatus.unauthenticated) {
        state = <int>{};
      } else if (next == AuthStatus.authenticated) {
        load();
      }
    });
  }

  final Ref ref;

  Future<void> load() async {
    try {
      final ids = await favoriteService.fetchFavoriteIds();
      state = ids;
    } catch (_) {}
  }

  bool isFav(int id) => state.contains(id);

  Future<void> toggle(BuildContext context, int id) async {
    final wasFav = state.contains(id);
    if (wasFav) {
      state = Set<int>.from(state)..remove(id);
    } else {
      state = {...state, id};
    }
    try {
      final fav = await favoriteService.toggle(id);
      if (fav) {
        state = {...state, id};
      } else {
        state = Set<int>.from(state)..remove(id);
      }
    } on UnauthorizedError {
      state = wasFav ? {...state, id} : (Set<int>.from(state)..remove(id));
      showAuthSheet(context);
    } on FriendlyError catch (e) {
      state = wasFav ? {...state, id} : (Set<int>.from(state)..remove(id));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } on DioException catch (e) {
      state = wasFav ? {...state, id} : (Set<int>.from(state)..remove(id));
      if (context.mounted) showApiError(context, e, 'Favorite');
    }
  }
}

final favoriteIdsProvider =
    StateNotifierProvider<FavoriteIdsNotifier, Set<int>>((ref) {
  return FavoriteIdsNotifier(ref);
});

final favoriteCountProvider = Provider<int>((ref) {
  return ref.watch(favoriteIdsProvider).length;
});

final favoritesPageProvider =
    FutureProvider.family<Paginated<Activity>, int>((ref, page) async {
  return favoriteService.listFavorites(page: page);
});
