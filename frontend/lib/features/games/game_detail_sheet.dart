import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import 'game_model.dart';

// ── GameDetailSheet ───────────────────────────────────────────────────────────
// Public bottom sheet widget — shared between SwipeScreen and SaveRoomScreen.
// Shows full game info: title, price, review score, description, tags,
// and an "Open on Steam" button.
class GameDetailSheet extends StatelessWidget {
  final Game game;
  // Optional: when non-null a "Remove from Saved" button appears.
  // Null when opened from SwipeScreen (not applicable there).
  final VoidCallback? onDelete;
  const GameDetailSheet({super.key, required this.game, this.onDelete});

  // Maps Steam's review text to a matching colour for visual feedback
  Color _reviewColor(String review) {
    final lower = review.toLowerCase();
    if (lower.contains('overwhelmingly')) return const Color(0xFF66C0F4);
    if (lower.contains('very positive')) return const Color(0xFF57CBDE);
    if (lower.contains('positive')) return const Color(0xFF4CAF50);
    if (lower.contains('mixed')) return const Color(0xFFFF9800);
    if (lower.contains('negative')) return Colors.redAccent;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111113),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title + price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  game.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  game.price.isEmpty ? 'N/A' : game.price,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Review summary
          if (game.reviewSummary.isNotEmpty)
            Row(
              children: [
                Icon(Icons.thumb_up_alt_rounded,
                    color: _reviewColor(game.reviewSummary), size: 14),
                const SizedBox(width: 6),
                Text(
                  game.reviewSummary,
                  style: TextStyle(
                    color: _reviewColor(game.reviewSummary),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 16),

          Divider(color: AppConstants.borderColor, height: 1),
          const SizedBox(height: 16),

          // Description
          Text(
            game.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 20),

          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: game.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.cardColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Open on Steam
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(game.steamLink);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open on Steam'),
              style: AppConstants.primaryButtonStyle,
            ),
          ),

          // Remove from Saved — only shown when opened from SaveRoomScreen
          if (onDelete != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.redAccent),
                label: const Text('Remove from Saved',
                    style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
