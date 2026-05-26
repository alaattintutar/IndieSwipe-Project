import '../save_room/save_room_screen.dart';
import '../profile/settings_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import 'games_provider.dart';
import 'game_model.dart';
import 'game_detail_sheet.dart';

// ── SwipeScreen ───────────────────────────────────────────────────────────────
// ConsumerStatefulWidget keeps _currentIndex and _isDone in Flutter's own state
// so they survive provider rebuilds (e.g. when a new page is appended).
class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  int _currentIndex = 0;
  bool _isDone = false;
  bool _waitingForMore = false;
  int _swiperBaseIndex = 0;
  int _swiperEpoch = 0;
  String? _selectedTag; // null = "All"

  // CardSwiperController lets the X / Heart buttons trigger programmatic swipes.
  late CardSwiperController _swiperController;

  static const _tagOptions = <(String?, String)>[
    (null, 'All'),
    ('action', 'Action'),
    ('adventure', 'Adventure'),
    ('rpg', 'RPG'),
    ('strategy', 'Strategy'),
    ('simulation', 'Simulation'),
    ('casual', 'Casual'),
  ];

  @override
  void initState() {
    super.initState();
    _swiperController = CardSwiperController();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  // ── Switch genre filter ────────────────────────────────────────────────────
  void _setTag(String? tag) {
    if (_selectedTag == tag) return;
    setState(() {
      _selectedTag = tag;
      _currentIndex = 0;
      _isDone = false;
      _waitingForMore = false;
      _swiperBaseIndex = 0;
      _swiperEpoch++;
    });
    ref.read(gamesProvider.notifier).setTag(tag);
  }

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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    // When waiting for next batch, detect the moment new games arrive
    // and reset the CardSwiper with a new epoch key.
    ref.listen<AsyncValue<GamesState>>(gamesProvider, (_, next) {
      if (!_waitingForMore) return;
      final games = next.value?.games;
      if (games != null && games.length > _swiperBaseIndex) {
        setState(() {
          _swiperEpoch++;
          _currentIndex = 0;
          _waitingForMore = false;
        });
      }
    });

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
            _buildTopBar(context, gamesAsync),
            const SizedBox(height: 10),

            // ── Genre chips ───────────────────────────────────────────────
            _buildTagChips(),
            const SizedBox(height: 10),

            // ── Card area ─────────────────────────────────────────────────
            Expanded(
              child: gamesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _ShimmerCard(),
                ),
                error: (err, _) => Center(
                  child: Text(err.toString(),
                      style: const TextStyle(color: Colors.white)),
                ),
                data: (gamesState) {
                  final games = gamesState.games;

                  if (_isDone) return _buildEmptyState();
                  if (_waitingForMore) return _buildLoadingMore();
                  if (games.isEmpty) return _buildLoadingMore();

                  final visibleGames = games.sublist(_swiperBaseIndex);
                  if (visibleGames.isEmpty) return _buildLoadingMore();

                  // Center + ConstrainedBox: on desktop/tablet the card stays
                  // portrait-phone-sized (max 450 px wide). On phones it fills.
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CardSwiper(
                          key: ValueKey(_swiperEpoch),
                          controller: _swiperController,
                          cardsCount: visibleGames.length,
                          onSwipe: (previousIndex, newIndex, direction) {
                            if (direction == CardSwiperDirection.right) {
                              HapticFeedback.mediumImpact();
                              _saveGame(visibleGames[previousIndex].id);
                            } else {
                              HapticFeedback.lightImpact();
                            }
                            _markAsSeen(visibleGames[previousIndex].id);

                            final next = newIndex ?? previousIndex + 1;
                            setState(() => _currentIndex = next);

                            // Prefetch next batch when 3 cards remain
                            final remaining = visibleGames.length - next;
                            if (remaining <= 3 &&
                                gamesState.hasMore &&
                                !gamesState.isLoadingMore) {
                              ref
                                  .read(gamesProvider.notifier)
                                  .fetchNextPage();
                            }

                            return true;
                          },
                          onEnd: () {
                            if (gamesState.hasMore ||
                                gamesState.isLoadingMore) {
                              setState(() {
                                _swiperBaseIndex = games.length;
                                _waitingForMore = true;
                              });
                              if (!gamesState.isLoadingMore) {
                                ref
                                    .read(gamesProvider.notifier)
                                    .fetchNextPage();
                              }
                            } else {
                              setState(() => _isDone = true);
                            }
                          },
                          cardBuilder: (context, index, _, __) {
                            return _VideoCard(
                              key: ValueKey(visibleGames[index].id),
                              game: visibleGames[index],
                              // isFront drives: neon glow, video play/pause
                              isFront: index == _currentIndex,
                              onDoubleTap: index == _currentIndex
                                  ? () => _swiperController.swipe(CardSwiperDirection.right)
                                  : null,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── X / Heart action buttons ──────────────────────────────────
            _buildActionButtons(gamesAsync),
          ],
        ),
      ),
    );
  }

  // ── Always-visible top bar ─────────────────────────────────────────────────
  Widget _buildTopBar(
      BuildContext context, AsyncValue<GamesState> gamesAsync) {
    final gamesState = gamesAsync.valueOrNull;
    final remaining = () {
      if (gamesState == null ||
          gamesState.games.length <= _swiperBaseIndex) return 0;
      return gamesState.games.sublist(_swiperBaseIndex).length - _currentIndex;
    }();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // IndieSwipe logo — Space Grotesk gives that modern SaaS look
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Indie',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'Swipe',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppConstants.primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Remaining counter (hidden during loading)
              if (remaining > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        '$remaining left',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Settings shortcut
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const SettingsScreen(),
                    transitionsBuilder: (_, animation, __, child) =>
                        SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(1, 0), end: Offset.zero)
                          .animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppConstants.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: const Icon(Icons.settings_outlined,
                      color: Colors.white60, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              // Save Room shortcut
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const SaveRoomScreen(),
                    transitionsBuilder: (_, animation, __, child) =>
                        SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(1, 0), end: Offset.zero)
                          .animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic)),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppConstants.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: const Icon(Icons.bookmark_rounded,
                      color: AppConstants.primaryColor, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Horizontal genre chip row ──────────────────────────────────────────────
  Widget _buildTagChips() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tagOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (tagValue, tagLabel) = _tagOptions[i];
          final isSelected = _selectedTag == tagValue;
          return GestureDetector(
            onTap: () => _setTag(tagValue),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppConstants.primaryColor
                      : AppConstants.borderColor,
                ),
              ),
              child: Center(
                child: Text(
                  tagLabel,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : AppConstants.secondaryTextColor,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── X / Heart action buttons ───────────────────────────────────────────────
  // Left button: programmatic left-swipe (skip).
  // Right button: programmatic right-swipe (save) with neon glow.
  // Both are hidden (opacity 0) when no cards are showing.
  Widget _buildActionButtons(AsyncValue<GamesState> gamesAsync) {
    final showing = gamesAsync.hasValue && !_isDone && !_waitingForMore;
    return AnimatedOpacity(
      opacity: showing ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✕ Skip
            _ActionButton(
              icon: Icons.close_rounded,
              color: Colors.white54,
              borderColor: Colors.white24,
              onTap: showing
                  ? () => _swiperController.swipe(CardSwiperDirection.left)
                  : null,
            ),
            const SizedBox(width: 40),
            // ♥ Save
            _ActionButton(
              icon: Icons.favorite_rounded,
              color: AppConstants.primaryColor,
              borderColor: AppConstants.primaryColor.withValues(alpha: 0.5),
              isGlow: true,
              onTap: showing
                  ? () => _swiperController.swipe(CardSwiperDirection.right)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingMore() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppConstants.primaryColor),
          SizedBox(height: 16),
          Text('Loading more games…',
              style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasTag = _selectedTag != null;
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
            Text(
              hasTag ? 'No more $_selectedTag games.' : "You're all caught up.",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              hasTag
                  ? 'Try a different genre or switch to All.'
                  : "You've seen all games.\nCome back tomorrow for new ones.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 14, height: 1.5),
            ),
            if (hasTag) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _setTag(null),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Show All',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Circular button used for the X (skip) and Heart (save) controls.
// isGlow=true adds a neon pink BoxShadow around the heart button.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color borderColor;
  final bool isGlow;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.borderColor,
    this.isGlow = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: AppConstants.cardColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isGlow
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}

// ─── Skeleton / Shimmer Card ──────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final p = -1.5 + 3 * _ctrl.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(p - 1, 0),
                    end: Alignment(p, 0),
                    colors: const [
                      Color(0xFF18181B),
                      Color(0xFF28282C),
                      Color(0xFF18181B),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _block(52, 20, radius: 5),
                    const SizedBox(height: 10),
                    _block(200, 26, radius: 6),
                    const SizedBox(height: 8),
                    _block(double.infinity, 13, radius: 4),
                    const SizedBox(height: 6),
                    _block(180, 13, radius: 4),
                    const SizedBox(height: 12),
                    Row(children: [
                      _block(56, 20, radius: 5),
                      const SizedBox(width: 8),
                      _block(64, 20, radius: 5),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _block(double width, double height, {double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Video Card Widget ────────────────────────────────────────────────────────
// Separate StatefulWidget for VideoPlayerController lifecycle management.
class _VideoCard extends StatefulWidget {
  final Game game;
  final bool isFront;
  final VoidCallback? onDoubleTap;
  const _VideoCard({super.key, required this.game, required this.isFront, this.onDoubleTap});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _isMuted = kIsWeb;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(_VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isFront && widget.isFront) _controller?.play();
    if (oldWidget.isFront && !widget.isFront) _controller?.pause();
  }

  Future<void> _initVideo() async {
    if (widget.game.videoUrl.isEmpty) return;
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.game.videoUrl),
      );
      await controller.initialize();
      controller.setVolume(_isMuted ? 0 : 1);
      controller.setLooping(true);
      if (widget.isFront) controller.play();
      if (mounted) {
        setState(() {
          _controller = controller;
          _videoReady = true;
        });
      }
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  void _toggleMute() {
    final next = !_isMuted;
    setState(() => _isMuted = next);
    _controller?.setVolume(next ? 0 : 1);
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
      builder: (_) => GameDetailSheet(game: widget.game),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Outer Container carries the neon border + glow (only on the front card).
    // The BoxShadow renders *outside* the widget, so it's not clipped.
    // The inner ClipRRect keeps video/image content neatly rounded.
    return GestureDetector(
      onTap: () => _showDetails(context),
      onDoubleTap: widget.onDoubleTap,
      child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: widget.isFront
            ? Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.55),
                width: 1.5,
              )
            : null,
        boxShadow: widget.isFront
            ? [
                BoxShadow(
                  color: AppConstants.primaryColor.withValues(alpha: 0.28),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Solid background ──────────────────────────────────────────
            Container(color: AppConstants.cardColor),

            // ── Media layer: video or fallback image ──────────────────────
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
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppConstants.cardColor,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppConstants.primaryColor, strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: AppConstants.cardColor,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: Colors.white24, size: 52),
                  ),
                ),
              ),

            // ── Gradient overlay ──────────────────────────────────────────
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

            // ── Info button (top right) ───────────────────────────────────
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

            // ── Mute / unmute button (below info button, top right) ────────
            if (_videoReady)
              Positioned(
                top: 60,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleMute,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white70,
                      size: 15,
                    ),
                  ),
                ),
              ),

            // ── GAMEPLAY badge (top left) ─────────────────────────────────
            if (_videoReady)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppConstants.primaryColor.withValues(alpha: 0.7),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withValues(alpha: 0.22),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Neon dot
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'GAMEPLAY',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Game info at bottom ───────────────────────────────────────
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price badge
                  if (widget.game.price.isNotEmpty &&
                      widget.game.price != 'N/A')
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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

                  // Title — Space Grotesk (heavy, modern tech feel)
                  Text(
                    widget.game.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Description — Outfit (clean, readable body font)
                  Text(
                    widget.game.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.game.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              AppConstants.primaryColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppConstants.primaryColor
                                .withValues(alpha: 0.35),
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
      ),
    ),
    );
  }
}
