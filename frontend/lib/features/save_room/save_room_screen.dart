import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../games/game_model.dart';

final savedGamesProvider = FutureProvider<List<Game>>((ref) async {
  final api = ApiService();
  final response = await api.get('/games/saved');
  final List data = response.data['games'];
  return data.map((json) => Game.fromJson(json)).toList();
});

class SaveRoomScreen extends ConsumerWidget {
  const SaveRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedGamesAsync = ref.watch(savedGamesProvider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Save Room',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
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

            const SizedBox(height: 16),

            // Game list
            Expanded(
              child: savedGamesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppConstants.primaryColor),
                ),
                error: (err, _) => Center(
                  child: Text(err.toString(),
                      style: const TextStyle(color: Colors.white)),
                ),
                data: (games) => games.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppConstants.cardColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppConstants.borderColor),
                                ),
                                child: const Icon(Icons.bookmark_border_rounded,
                                    color: AppConstants.primaryColor, size: 32),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Nothing saved yet.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Swipe right on games you love\nand they\'ll appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppConstants.secondaryTextColor,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: games.length,
                        itemBuilder: (context, index) {
                          final game = games[index];
                          return _buildGameCard(game);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(Game game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.borderColor, width: 1),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Image.network(
              game.gifUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 90,
                height: 90,
                color: AppConstants.backgroundColor,
                child: const Icon(Icons.broken_image_rounded,
                    color: Colors.white24, size: 28),
              ),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.description,
                    style: TextStyle(
                      color: AppConstants.secondaryTextColor,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // First tag only
                  if (game.tags.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        game.tags.first,
                        style: const TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Steam button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse(game.steamLink);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppConstants.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.open_in_new_rounded,
                  color: AppConstants.primaryColor,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
