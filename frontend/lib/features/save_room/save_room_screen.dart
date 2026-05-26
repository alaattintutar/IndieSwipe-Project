import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../games/game_model.dart';
import '../games/game_detail_sheet.dart';

// ── Provider ──────────────────────────────────────────────────────────────────
final savedGamesProvider = FutureProvider<List<Game>>((ref) async {
  final api = ApiService();
  final response = await api.get('/games/saved');
  final List data = response.data['games'];
  return data.map((json) => Game.fromJson(json)).toList();
});

// ── SaveRoomScreen ─────────────────────────────────────────────────────────────
class SaveRoomScreen extends ConsumerWidget {
  const SaveRoomScreen({super.key});

  // ── Delete a saved game ────────────────────────────────────────────────────
  // Calls DELETE /api/games/saved/:gameId, then invalidates the provider so
  // the grid refreshes automatically.
  Future<void> _deleteGame(
      BuildContext context, WidgetRef ref, String gameId) async {
    try {
      final api = ApiService();
      await api.delete('/games/saved/$gameId');
      ref.invalidate(savedGamesProvider);
      if (context.mounted) Navigator.pop(context); // close the sheet
    } catch (e) {
      debugPrint('deleteGame error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oyun silinemedi: $e'),
            backgroundColor: AppConstants.cardColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedGamesProvider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save Room',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your wishlist of hidden gems.',
                          style: TextStyle(
                            color: AppConstants.secondaryTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Game count badge
                  savedAsync.whenOrNull(
                        data: (games) => games.isEmpty
                            ? null
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppConstants.primaryColor
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '${games.length} saved',
                                  style: const TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ) ??
                      const SizedBox.shrink(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Content ───────────────────────────────────────────────────────
            Expanded(
              child: savedAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppConstants.primaryColor),
                ),
                error: (err, _) => Center(
                  child: Text(err.toString(),
                      style: const TextStyle(color: Colors.white)),
                ),
                data: (games) => games.isEmpty
                    ? _buildEmptyState()
                    : _buildGrid(context, ref, games),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Responsive 2-column grid ───────────────────────────────────────────────
  Widget _buildGrid(BuildContext context, WidgetRef ref, List<Game> games) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 3 columns on wide screens (tablet/web), 2 on phones
        final crossCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78, // wide enough to feel grid-like, not too tall
          ),
          itemCount: games.length,
          itemBuilder: (context, index) => _GameGridCard(
            game: games[index],
            onDelete: () => _deleteGame(context, ref, games[index].id),
          ),
        );
      },
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppConstants.cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppConstants.borderColor),
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                color: AppConstants.primaryColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Nothing saved yet.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "You haven't saved any games yet.\nSwipe right on games you love\nand they'll appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppConstants.secondaryTextColor,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _GameGridCard ─────────────────────────────────────────────────────────────
// Cover-dominant portrait card. Tapping opens GameDetailSheet which contains
// both the Steam link and the "Remove from Saved" button.
class _GameGridCard extends StatelessWidget {
  final Game game;
  final VoidCallback onDelete;
  const _GameGridCard({required this.game, required this.onDelete});

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => GameDetailSheet(game: game, onDelete: onDelete),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Solid background ─────────────────────────────────────────
            Container(color: AppConstants.cardColor),

            // ── Cover image ──────────────────────────────────────────────
            Image.network(
              game.gifUrl,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : Container(color: AppConstants.cardColor),
              errorBuilder: (_, __, ___) => Container(
                color: AppConstants.cardColor,
                child: const Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: Colors.white24, size: 36),
                ),
              ),
            ),

            // ── Gradient overlay ─────────────────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.35, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
            ),

            // ── Info overlay (bottom) ─────────────────────────────────────
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (game.price.isNotEmpty && game.price != 'N/A')
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        game.price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Text(
                    game.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),

            // ── Info icon (top right) ─────────────────────────────────────
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: Colors.white70, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
