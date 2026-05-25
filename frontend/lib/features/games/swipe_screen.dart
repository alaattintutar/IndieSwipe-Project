import '../save_room/save_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import 'games_provider.dart';
import 'game_model.dart';

// ── SwipeScreen ───────────────────────────────────────────────────────────────
// ConsumerStatefulWidget keeps _currentIndex and _isDone in Flutter's own state
// so they survive provider rebuilds (e.g. when a new page is appended).
// A plain ConsumerWidget would reset _currentIndex to 0 on every re-render.
class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  int _currentIndex = 0;
  bool _isDone = false;

  // ── Save game (right swipe) ────────────────────────────────────────────────
  void _saveGame(String gameId) async {
    try {
      final api = ApiService();
      await api.post('/games/save/$gameId');
      ref.invalidate(savedGamesProvider);
    } catch (e) {
      if (mounted) {
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

  // ── Mark as seen (every swipe) ────────────────────────────────────────────
  void _markAsSeen(String gameId) async {
    try {
      final api = ApiService();
      await api.post('/games/seen/$gameId');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(gamesProvider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: gamesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppConstants.primaryColor),
          ),
          error: (err, _) => Center(
            child: Text(err.toString(), style: const TextStyle(color: Colors.white)),
          ),
          data: (gamesState) {
            // gamesState is GamesState — use .games for the list
            final games = gamesState.games;

            if (games.isEmpty || _isDone) return _buildEmptyState();

            return Column(
              children: [
                // Top logo bar
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
                            // Shows total loaded games; grows as pages are fetched
                            Text(
                              '${games.length} games',
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

                // Card swiper
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CardSwiper(
                      cardsCount: games.length,
                      onSwipe: (previousIndex, newIndex, direction) {
                        if (direction == CardSwiperDirection.right) {
                          _saveGame(games[previousIndex].id);
                        }
                        _markAsSeen(games[previousIndex].id);

                        final next = newIndex ?? previousIndex + 1;
                        setState(() => _currentIndex = next);

                        // ── Prefetch trigger ──────────────────────────────
                        // When the user is 3 cards from the end, silently
                        // fetch the next page and append it to the list.
                        final remaining = games.length - next;
                        if (remaining <= 3 &&
                            gamesState.hasMore &&
                            !gamesState.isLoadingMore) {
                          ref.read(gamesProvider.notifier).fetchNextPage();
                        }

                        return true;
                      },
                      onEnd: () => setState(() => _isDone = true),
                      cardBuilder: (context, index, _, __) => _VideoCard(
                        key: ValueKey(games[index].id),
                        game: games[index],
                        isFront: index == _currentIndex,
                      ),
                    ),
                  ),
                ),

                // Swipe hint
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_back_rounded, color: Colors.white38, size: 16),
                      const SizedBox(width: 6),
                      const Text('skip',
                          style: TextStyle(color: Colors.white38, fontSize: 12)),
                      const SizedBox(width: 24),
                      Text('save',
                          style: TextStyle(
                              color: AppConstants.primaryColor.withValues(alpha: 0.6),
                              fontSize: 12)),
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
        ),
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
            const Text("You're all caught up.",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              "You've seen all games for today.\nCome back tomorrow for new ones.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Video Card Widget ────────────────────────────────────────────────────────
// Separate StatefulWidget because VideoPlayerController needs lifecycle management
// (init, dispose). ConsumerWidget rebuilds on every state change — having a
// StatefulWidget here prevents the controller from being recreated unnecessarily.

class _VideoCard extends StatefulWidget {
  final Game game;
  final bool isFront;
  const _VideoCard({super.key, required this.game, required this.isFront});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  VideoPlayerController? _controller;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    // Always pre-load the video — even if this card is behind.
    // initialize() downloads and buffers the stream in the background.
    // play() is intentionally NOT called here; we wait for isFront == true.
    _initVideo();
  }

  @override
  void didUpdateWidget(_VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Card came to the front — video is already buffered, play instantly.
    if (!oldWidget.isFront && widget.isFront) {
      _controller?.play();
    }
    // Card went to the back — pause to save resources.
    if (oldWidget.isFront && !widget.isFront) {
      _controller?.pause();
    }
  }

  Future<void> _initVideo() async {
    if (widget.game.videoUrl.isEmpty) return;
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.game.videoUrl),
      );
      await controller.initialize();
      controller.setVolume(0);
      controller.setLooping(true);
      // Start playing only if this card is already in front when init finishes.
      // Otherwise stay paused — didUpdateWidget will trigger play() later.
      if (widget.isFront) controller.play();
      if (mounted) {
        setState(() {
          _controller = controller;
          _videoReady = true;
        });
      }
    } catch (e) {
      // Video failed to load — header image fallback will be shown
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GameDetailSheet(game: widget.game),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Solid background — prevents transparency bleed from card behind ──
          Container(color: AppConstants.cardColor),

          // ── Media layer: video or fallback image ──
          if (_videoReady && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            Image.network(
              widget.game.gifUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppConstants.cardColor,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: AppConstants.cardColor,
                child: const Center(
                  child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 52),
                ),
              ),
            ),

          // ── Gradient overlay ──
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

          // ── Info button (top right) ──
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => _showDetails(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: Colors.white70, size: 18),
              ),
            ),
          ),

          // ── Video indicator (top left) ──
          if (_videoReady)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.play_circle_outline_rounded,
                        color: Colors.white70, size: 12),
                    SizedBox(width: 4),
                    Text('LIVE',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ),

          // ── Game info at bottom ──
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price badge
                if (widget.game.price.isNotEmpty && widget.game.price != 'N/A')
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.game.price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                Text(
                  widget.game.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.game.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.game.tags.take(3).map((tag) {
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
}

// ─── Game Detail Bottom Sheet ─────────────────────────────────────────────────
// Shows full game info with price, review score and Steam link.
// Slides up from bottom when the info button is tapped.

class _GameDetailSheet extends StatelessWidget {
  final Game game;
  const _GameDetailSheet({required this.game});

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

          // Review summary badge
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

          // Divider
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
                child: Text(tag,
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Open on Steam button
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
        ],
      ),
    );
  }
}
