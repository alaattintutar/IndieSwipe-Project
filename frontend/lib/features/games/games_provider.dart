import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_service.dart';
import 'game_model.dart';

// ── GamesState ────────────────────────────────────────────────────────────────
// A plain data class that holds everything SwipeScreen needs to know:
//   games        → the accumulated list (grows as pages are fetched)
//   page         → which page we last loaded
//   hasMore      → whether the backend still has more games to give
//   isLoadingMore → prevents duplicate fetchNextPage() calls
class GamesState {
  final List<Game> games;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const GamesState({
    required this.games,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  GamesState copyWith({
    List<Game>? games,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return GamesState(
      games: games ?? this.games,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// ── GamesNotifier ─────────────────────────────────────────────────────────────
// AsyncNotifier is the Riverpod 2.x way to combine "async initial load"
// with "methods that mutate state later".
//
//   build()           → called once on first watch; fetches page 1
//   fetchNextPage()   → appends the next page to the existing game list;
//                       called by SwipeScreen when ≤3 cards remain
class GamesNotifier extends AsyncNotifier<GamesState> {
  final _api = ApiService();

  @override
  Future<GamesState> build() async {
    // Always start fresh from page 1 when the provider is first created
    // (or after a ref.invalidate / ref.refresh).
    return _loadPage(1);
  }

  // ── Internal helper: fetch one page from the backend ──────────────────────
  Future<GamesState> _loadPage(int page) async {
    final response = await _api.get('/games/feed?page=$page&limit=10');
    final List? raw = response.data['games'];
    final bool hasMore = response.data['hasMore'] ?? false;
    final games = raw?.map((json) => Game.fromJson(json)).toList() ?? [];
    return GamesState(games: games, page: page, hasMore: hasMore);
  }

  // ── Public method: append the next page ───────────────────────────────────
  // SwipeScreen calls this when the user is 3 cards from the end.
  // We keep existing cards visible (no loading spinner) and silently append.
  Future<void> fetchNextPage() async {
    final current = state.value;

    // Guard: bail out if state isn't ready, already fetching, or no pages left
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    // Flip the flag so double-triggers from rapid swiping are ignored
    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.page + 1;
      final response = await _api.get('/games/feed?page=$nextPage&limit=10');
      final List? raw = response.data['games'];
      final bool hasMore = response.data['hasMore'] ?? false;
      final newGames = raw?.map((json) => Game.fromJson(json)).toList() ?? [];

      // Spread operator appends new games AFTER existing ones — no reset
      state = AsyncData(GamesState(
        games: [...current.games, ...newGames],
        page: nextPage,
        hasMore: hasMore,
      ));
    } catch (_) {
      // On network error just clear the flag; next swipe will retry
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

// Module-level constant so SwipeScreen (.watch) and the save button (.read)
// both reference the exact same provider instance.
final gamesProvider = AsyncNotifierProvider<GamesNotifier, GamesState>(
  GamesNotifier.new,
);
