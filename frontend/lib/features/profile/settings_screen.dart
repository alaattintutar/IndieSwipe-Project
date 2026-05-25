import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../games/games_provider.dart';
import '../save_room/save_room_screen.dart';

// ── Provider ──────────────────────────────────────────────────────────────────
// Fetches the current user's profile from GET /api/auth/me.
// The response excludes the password field (backend uses .select('-password')).
final currentUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ApiService();
  final response = await api.get('/auth/me');
  return Map<String, dynamic>.from(response.data['user'] as Map);
});

// ── SettingsScreen ─────────────────────────────────────────────────────────────
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // ── Logout flow ───────────────────────────────────────────────────────────
  // 1. Show confirmation dialog
  // 2. Remove JWT token from SharedPreferences
  // 3. Invalidate all user-specific providers so stale data is wiped
  // 4. Navigate to /login and clear the entire back stack
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Clear the stored token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // Wipe providers so the next login session starts fresh
    ref.invalidate(gamesProvider);
    ref.invalidate(savedGamesProvider);
    ref.invalidate(currentUserProvider);

    if (context.mounted) {
      // pushNamedAndRemoveUntil clears the entire navigation stack —
      // the user cannot go back to the home screen with the back button.
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Nav bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: userAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppConstants.primaryColor),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: Colors.white38, size: 48),
                        const SizedBox(height: 16),
                        Text(err.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                data: (user) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    // ── Profile card ──────────────────────────────────────
                    _ProfileCard(user: user),
                    const SizedBox(height: 28),

                    // ── Account section ───────────────────────────────────
                    _SectionLabel('ACCOUNT'),
                    const SizedBox(height: 8),
                    _SettingsGroup(items: [
                      _SettingsTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Account Settings',
                      ),
                      _SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notifications',
                      ),
                      _SettingsTile(
                        icon: Icons.lock_outline_rounded,
                        label: 'Privacy',
                        isLast: true,
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── About section ─────────────────────────────────────
                    _SectionLabel('ABOUT'),
                    const SizedBox(height: 8),
                    _SettingsGroup(items: [
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        label: 'About IndieSwipe',
                      ),
                      _SettingsTile(
                        icon: Icons.article_outlined,
                        label: 'Privacy Policy',
                      ),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        label: 'Terms of Service',
                        isLast: true,
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // ── Logout ────────────────────────────────────────────
                    _LogoutButton(onTap: () => _logout(context, ref)),
                    const SizedBox(height: 20),

                    // Version string
                    const Center(
                      child: Text(
                        'IndieSwipe v1.0.0',
                        style:
                            TextStyle(color: Colors.white24, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _ProfileCard ──────────────────────────────────────────────────────────────
// Shows avatar (first-letter initials), username, email and role badge.
class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final username = (user['username'] as String?) ?? '';
    final email = (user['email'] as String?) ?? '';
    final role = (user['role'] as String?) ?? 'gamer';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        children: [
          // Avatar circle with initial
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppConstants.primaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    color: AppConstants.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        AppConstants.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          AppConstants.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppConstants.secondaryTextColor,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    );
  }
}

// ── Settings group (card with tiles) ─────────────────────────────────────────
// Groups multiple tiles into a single rounded card with dividers.
class _SettingsGroup extends StatelessWidget {
  final List<_SettingsTile> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        children: items
            .asMap()
            .entries
            .map((e) => Column(
                  children: [
                    e.value,
                    if (!e.value.isLast)
                      Divider(
                          height: 1,
                          color: AppConstants.borderColor,
                          indent: 50),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white60, size: 20),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Colors.white24, size: 20),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// ── Logout button ─────────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
