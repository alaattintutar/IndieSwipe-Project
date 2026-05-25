import '../save_room/save_room_screen.dart';
import '../profile/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import 'games_provider.dart';
import 'game_model.dart';
import 'game_detail_sheet.dart';

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
  bool _waitingForMore = false;
  int _swiperBaseIndex = 0;
  int _swiperEpoch = 0;
  String? _selectedTag; // null = "All"

  // Tag options shown in the horizontal chip row.
  // Values match the lowercase Steam genre strings stored in MongoDB.
  static const _tagOptions = <(String?, String)>[
    (null, 'All'),
    ('action', 'Action'),
    ('adventure', 'Adventure'),
    ('rpg', 'RPG'),
    ('strategy', 'Strategy'),
    ('simulation', 'Simulation'),
    ('casual', 'Casual'),
  ];

  // ── Switch genre filter ────────────────────────────────────────────────────
  // Resets all swipe state so the new deck starts clean, then asks the
  // notifier to refetch with the new tag (triggers AsyncLoading → skeleton).
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
            // ── Top bar — always visible ─────────────────────────────────
            _buildTopBar(context, gamesAsync),
            const SizedBox(height: 10),

            // ── Genre chips — always visible ─────────────────────────────
            _buildTagChips(),
            const SizedBox(height: 10),

            // ── Card area: skeleton / error / cards ──────────────────────
            Expanded(
              child: gamesAsync.when(
                // Skeleton replaces the spinner for a polished loading feel
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

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CardSwiper(
                      key: ValueKey(_swiperEpoch),
                      cardsCount: visibleGames.length,
                      onSwipe: (previousIndex, newIndex, direction) {
                        if (direction == CardSwiperDirection.right) {
                          HapticFeedback.mediumImpact(); // save — stronger pulse
                          _saveGame(visibleGames[previousIndex].id);
                        } else {
                          HapticFeedback.lightImpact(); // skip — gentle tap
                        }
                        _markAsSeen(visibleGames[previousIndex].id);

                        final next = newIndex ?? previousIndex + 1;
                        setState(() => _currentIndex = next);

                        // Prefetch next batch when 3 cards remain
                        final remaining = visibleGames.length - next;
                        if (remaining <= 3 &&
                            gamesState.hasMore &&
                            !gamesState.isLoadingMore) {
                          ref.read(gamesProvider.notifier).fetchNextPage();
                        }

                        return true;
                      },
                      onEnd: () {
                        if (gamesState.hasMore || gamesState.isLoadingMore) {
                          setState(() {
                            _swiperBaseIndex = games.length;
                            _waitingForMore = true;
                          });
                          if (!gamesState.isLoadingMore) {
                            ref.read(gamesProvider.notifier).fetchNextPage();
                          }
                        } else {
                          setState(() => _isDone = true);
                        }
                      },
                      cardBuilder: (context, index, _, __) => _VideoCard(
                        key: ValueKey(visibleGames[index].id),
                        game: visibleGames[index],
                        isFront: index == _currentIndex,
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Swipe hint — fades out when no cards visible ─────────────
            _buildSwipeHint(gamesAsync),
          ],
        ),
      ),
    );
  }

  // ── Always-visible top bar ─────────────────────────────────────────────────
  Widget _buildTopBar(
      BuildContext context, AsyncValue<GamesState> gamesAsync) {
    final gamesState = gamesAsync.value;
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
          // IndieSwipe logo
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Indie',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                ),
                TextSpan(
                  text: 'Swipe',
                  style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
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

  // ── Swipe hint — fades when cards aren't visible ───────────────────────────
  Widget _buildSwipeHint(AsyncValue<GamesState> gamesAsync) {
    final showing = gamesAsync.hasValue && !_isDone && !_waitingForMore;
    return AnimatedOpacity(
      opacity: showing ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_back_rounded,
                color: Colors.white38, size: 16),
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

// ─── Skeleton / Shimmer Card ──────────────────────────────────────────────────
// Shown while the first batch loads or when a tag filter changes.
// Uses an AnimationController to sweep a lighter band across the dark card,
// mimicking the shimmer effect without any extra package.
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
        final p = -1.5 + 3 * _ctrl.value; // sweeps from -1.5 to +1.5
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Animated shimmer background
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
              // Placeholder blocks mimicking the real card layout
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
      builder: (_) => GameDetailSheet(game: widget.game),
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

// _GameDetailSheet has been extracted to game_detail_sheet.dart as the
// public GameDetailSheet widget — shared with SaveRoomScreen.
