import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_service.dart';
import 'game_model.dart';

// ── GamesState ────────────────────────────────────────────────────────────────
// No 'page' field — we identify position by the IDs already loaded.
// The backend uses those IDs as an exclude list, so it always returns
// a correct next batch regardless of how seenGames has grown.
class GamesState {
  final List<Game> games;
  final bool hasMore;
  final bool isLoadingMore;

  const GamesState({
    required this.games,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  GamesState copyWith({
    List<Game>? games,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return GamesState(
      games: games ?? this.games,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// ── GamesNotifier ─────────────────────────────────────────────────────────────
class GamesNotifier extends AsyncNotifier<GamesState> {
  final _api = ApiService();

  @override
  Future<GamesState> build() async {
    // First load: no games in the stack yet → no excludeIds
    return _fetch([]);
  }

  // ── Internal: call the feed endpoint with a list of IDs to skip ───────────
  Future<GamesState> _fetch(List<String> excludeIds) async {
    final query = excludeIds.isNotEmpty
        ? '/games/feed?exclude=${excludeIds.join(',')}&limit=10'
        : '/games/feed?limit=10';

    final response = await _api.get(query);
    final List? raw = response.data['games'];
    final bool hasMore = response.data['hasMore'] ?? false;
    final games = raw?.map((json) => Game.fromJson(json)).toList() ?? [];
    return GamesState(games: games, hasMore: hasMore);
  }

  // ── Public: append next batch without touching existing cards ─────────────
  Future<void> fetchNextPage() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      // Send all currently loaded IDs — backend returns fresh games only
      final excludeIds = current.games.map((g) => g.id).toList();
      final response = await _api.get(
        '/games/feed?exclude=${excludeIds.join(',')}&limit=10',
      );
      final List? raw = response.data['games'];
      final bool hasMore = response.data['hasMore'] ?? false;
      final newGames = raw?.map((json) => Game.fromJson(json)).toList() ?? [];

      // Spread operator appends new games after existing ones
      state = AsyncData(GamesState(
        games: [...current.games, ...newGames],
        hasMore: hasMore,
      ));
    } catch (_) {
      // Clear loading flag so the next swipe can retry
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final gamesProvider = AsyncNotifierProvider<GamesNotifier, GamesState>(
  GamesNotifier.new,
);
