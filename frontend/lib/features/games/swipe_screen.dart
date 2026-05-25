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
        data: (games) => CardSwiper(
          cardsCount: games.length,
          onSwipe: (previousIndex, currentIndex, direction) {
            if (direction == CardSwiperDirection.right) {
              _saveGame(games[previousIndex].id);
            }
            return true;
          },
          cardBuilder: (context, index, _, _) => _buildCard(games[index]),
        ),
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
              child: Image.network(game.gifUrl, fit: BoxFit.cover, width: double.infinity),
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

  void _saveGame(String gameId) async {
  try {
    final api = ApiService();
    await api.post('/games/save/$gameId');
  } catch (e) {
    // Already saved or other error - silently ignore
  }
}
}