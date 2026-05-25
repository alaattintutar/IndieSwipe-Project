import '../save_room/save_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import 'games_provider.dart';
import 'game_model.dart';

class SwipeScreen extends ConsumerWidget {
  const SwipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesProvider);

    void saveGame(String gameId) async {
      try {
        final api = ApiService();
        await api.post('/games/save/$gameId');
        ref.invalidate(savedGamesProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not save game'),
              backgroundColor: AppConstants.cardColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }

    void markAsSeen(String gameId) async {
      try {
        final api = ApiService();
        await api.post('/games/seen/$gameId');
      } catch (e) {}
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      // No AppBar — full immersive experience
      body: SafeArea(
        child: gamesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppConstants.primaryColor),
          ),
          error: (err, _) => Center(
            child: Text(err.toString(), style: const TextStyle(color: Colors.white)),
          ),
          data: (games) {
            // All games already seen before session started
            if (games.isEmpty) {
              return _buildEmptyState();
            }

            bool isDone = false;

            return StatefulBuilder(
              builder: (context, setState) {
                if (isDone) return _buildEmptyState();

                return Column(
                  children: [
                    // Top logo bar (replaces AppBar)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Indie',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Swipe',
                                  style: TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppConstants.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppConstants.borderColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_fire_department_rounded,
                                    color: AppConstants.primaryColor, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Daily ${games.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Card swiper — takes up most of the screen
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CardSwiper(
                          cardsCount: games.length,
                          onSwipe: (previousIndex, currentIndex, direction) {
                            if (direction == CardSwiperDirection.right) {
                              saveGame(games[previousIndex].id);
                            }
                            markAsSeen(games[previousIndex].id);
                            return true;
                          },
                          onEnd: () => setState(() => isDone = true),
                          cardBuilder: (context, index, _, __) =>
                              _buildCard(games[index]),
                        ),
                      ),
                    ),

                    // Swipe hint row
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_back_rounded,
                              color: Colors.white38, size: 16),
                          const SizedBox(width: 6),
                          Text('skip',
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400)),
                          const SizedBox(width: 24),
                          Text('save',
                              style: TextStyle(
                                  color: AppConstants.primaryColor.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400)),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                              color: AppConstants.primaryColor.withValues(alpha: 0.6),
                              size: 16),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(Game game) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Game image — fills entire card
          Image.network(
            game.gifUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppConstants.cardColor,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_rounded, color: Colors.white24, size: 52),
                    SizedBox(height: 8),
                    Text('Image could not be loaded',
                        style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

          // Dark gradient overlay from bottom
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.4, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),

          // Game info on top of gradient
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  game.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: game.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppConstants.primaryColor.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
              child: const Icon(Icons.nightlight_round,
                  color: AppConstants.primaryColor, size: 36),
            ),
            const SizedBox(height: 24),
            const Text(
              "You're all caught up.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You've seen all games for today.\nCome back tomorrow for new ones.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
