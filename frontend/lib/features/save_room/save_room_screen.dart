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
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        title: const Text('Save Room',
            style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: savedGamesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
        error: (err, _) => Center(child: Text(err.toString(), style: const TextStyle(color: Colors.white))),
        data: (games) => games.isEmpty
            ? const Center(child: Text('No saved games yet.\nSwipe right to save!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppConstants.cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          game.gifUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 60,
                            height: 60,
                            color: AppConstants.cardColor,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                      title: Text(game.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(game.description, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new, color: AppConstants.primaryColor),
                        onPressed: () async {
                          final uri = Uri.parse(game.steamLink);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}