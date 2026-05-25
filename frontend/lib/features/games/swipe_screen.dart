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
            const SnackBar(content: Text('Could not save game')),
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
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        title: const Text('IndieSwipe',
            style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: gamesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
        error: (err, _) => Center(child: Text(err.toString(), style: const TextStyle(color: Colors.white))),
        data: (games) {
          if (games.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.nightlight_round, color: AppConstants.primaryColor, size: 64),
                  SizedBox(height: 16),
                  Text("You've seen all games for today!",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Come back tomorrow for new ones.",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            );
          }

          bool isDone = false;

          return StatefulBuilder(
            builder: (context, setState) {
              if (isDone) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.nightlight_round, color: AppConstants.primaryColor, size: 64),
                      SizedBox(height: 16),
                      Text("You've seen all games for today!",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text("Come back tomorrow for new ones.",
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                );
              }

              return CardSwiper(
                cardsCount: games.length,
                onSwipe: (previousIndex, currentIndex, direction) {
                  if (direction == CardSwiperDirection.right) {
                    saveGame(games[previousIndex].id);
                  }
                  markAsSeen(games[previousIndex].id);
                  return true;
                },
                onEnd: () => setState(() => isDone = true),
                cardBuilder: (context, index, _, __) => _buildCard(games[index]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCard(Game game) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                game.gifUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppConstants.cardColor,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey, size: 48),
                        SizedBox(height: 8),
                        Text('Image could not be loaded',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.title,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(game.description,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: game.tags.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.3),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}