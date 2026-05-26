import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_service.dart';
import 'game_model.dart';

// ── GamesState ────────────────────────────────────────────────────────────────
class GamesState {
  final List<Game> games;
  final bool hasMore;
  final bool isLoadingMore;
  final String? selectedTag; // null = "All" / no filter

  const GamesState({
    required this.games,
    required this.hasMore,
    this.isLoadingMore = false,
    this.selectedTag,
  });

  GamesState copyWith({
    List<Game>? games,
    bool? hasMore,
    bool? isLoadingMore,
    Object? selectedTag = _keep, // use sentinel to allow explicit null
  }) {
    return GamesState(
      games: games ?? this.games,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedTag: selectedTag == _keep ? this.selectedTag : selectedTag as String?,
    );
  }

  static const Object _keep = Object();
}

// ── GamesNotifier ─────────────────────────────────────────────────────────────
class GamesNotifier extends AsyncNotifier<GamesState> {
  final _api = ApiService();

  @override
  Future<GamesState> build() async {
    // First load: no excludes, no tag filter
    return _fetch([], tag: null);
  }

  // ── Internal: build URL and fetch one batch ────────────────────────────────
  Future<GamesState> _fetch(List<String> excludeIds, {String? tag}) async {
    final params = <String>['limit=10'];
    if (excludeIds.isNotEmpty) params.add('exclude=${excludeIds.join(',')}');
    if (tag != null && tag.isNotEmpty) params.add('tag=$tag');

    final response = await _api.get('/games/feed?${params.join('&')}');
    final List? raw = response.data['games'];
    final bool hasMore = response.data['hasMore'] ?? false;
    final games = raw?.map((json) => Game.fromJson(json)).toList() ?? [];
    return GamesState(games: games, hasMore: hasMore, selectedTag: tag);
  }

  // ── setTag: reset state and fetch fresh with a new tag filter ─────────────
  // Called when user taps a chip in SwipeScreen. Sets AsyncLoading so the
  // skeleton shows while the request is in flight.
  Future<void> setTag(String? tag) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch([], tag: tag));
  }

  // ── fetchNextPage: append next batch, keeping existing cards ──────────────
  Future<void> fetchNextPage() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final excludeIds = current.games.map((g) => g.id).toList();
      final params = <String>[
        'limit=10',
        'exclude=${excludeIds.join(',')}',
      ];
      if (current.selectedTag != null) params.add('tag=${current.selectedTag}');

      final response = await _api.get('/games/feed?${params.join('&')}');
      final List? raw = response.data['games'];
      final bool hasMore = response.data['hasMore'] ?? false;
      final newGames = raw?.map((json) => Game.fromJson(json)).toList() ?? [];

      state = AsyncData(GamesState(
        games: [...current.games, ...newGames],
        hasMore: hasMore,
        selectedTag: current.selectedTag,
      ));
    } catch (e) {
      debugPrint('fetchNextPage error: $e');
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final gamesProvider = AsyncNotifierProvider<GamesNotifier, GamesState>(
  GamesNotifier.new,
);
