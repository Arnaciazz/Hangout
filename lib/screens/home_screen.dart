import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'mode_lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onStartSwipe;
  const HomeScreen({super.key, this.onStartSwipe});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _groupService = GroupService();

  // ─── Profile sheet ─────────────────────────────────────────────────────────

  void _showProfileSheet() {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String? ??
        user?.email ??
        'You';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String? ??
        user?.userMetadata?['picture'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1B1B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // avatar + name
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF333333),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      if (user?.email != null)
                        Text(user!.email!,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            _profileTile(
              ctx,
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              },
            ),
            _profileTile(
              ctx,
              icon: Icons.help_outline_rounded,
              label: 'Help & Feedback',
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              },
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 8),
            _profileTile(
              ctx,
              icon: Icons.logout_rounded,
              label: 'Log out',
              color: const Color(0xFFFF5C5C),
              onTap: () async {
                Navigator.pop(ctx);
                await AuthService().signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileTile(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: TextStyle(
              color: color, fontSize: 15, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  void _showJoinSheet() {
    final codeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _JoinGroupSheet(codeCtrl: codeCtrl, service: _groupService),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.8),
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.black54),
                onPressed: () {},
              ),
              title: const Text(
                'Decisionly',
                style: TextStyle(
                  color: Color(0xFFFF5200),
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: _showProfileSheet,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFE0DCD8),
                      backgroundImage: (() {
                        final url = Supabase.instance.client.auth.currentUser
                            ?.userMetadata?['avatar_url'] as String?;
                        return url != null ? NetworkImage(url) : null;
                      })(),
                      child: Supabase.instance.client.auth.currentUser
                                  ?.userMetadata?['avatar_url'] ==
                              null
                          ? const Icon(Icons.person, size: 18,
                              color: Color(0xFF888888))
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 120),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildActiveSessions(),
          const SizedBox(height: 16),
          _buildGroupsSection(),
          const SizedBox(height: 16),
          _buildHeroTiles(),
          const SizedBox(height: 16),
          _buildUtilityTiles(),
          const SizedBox(height: 24),
          _buildBucketList(),
        ],
      ),
    );
  }

  // ─── Groups Section ───────────────────────────────────────────────────────

  Widget _buildGroupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Groups',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF281812))),
            Row(
              children: [
                _GroupActionButton(
                  label: 'Join',
                  icon: Icons.login_rounded,
                  onTap: _showJoinSheet,
                ),
                const SizedBox(width: 8),
                _GroupActionButton(
                  label: 'Create',
                  icon: Icons.add_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Group cards stream
        StreamBuilder<List<Group>>(
          stream: _groupService.watchMyGroups(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final groups = snapshot.data ?? [];
            if (groups.isEmpty) {
              return _buildEmptyGroups();
            }
            return SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _GroupCard(
                  group: groups[i],
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GroupDetailScreen(group: groups[i]),
                  )),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyGroups() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Column(
        children: [
          const Text('👥', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          const Text('No groups yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF281812))),
          const SizedBox(height: 4),
          Text('Create one or join with a code',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.outline)),
        ],
      ),
    );
  }

  Widget _buildActiveSessions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9E3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B6D01),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('ACTIVE SESSIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5C4037), letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Finding Dinner Spots', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF281812)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA83300),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTiles() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ModeLobbyScreen(mode: 'hunger'),
              ));
            },
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCJ6tIKYAPuu0dbIlzjYbK9z8Js8PA8WaoueM4RE9YzrmLRrolTEEeMpp8fUVPYRhcHS73iOYFCTPs5U4wKnNl4uMjUp3YfW66hnFS5XHDJZwASJEH7oHEoapWvgPyOY1cgCvGrl4agYH5vGOwmmoNnlXt6fMsdI8zHNiR_UKVmnSP4RviiG7S-Q-SBnbgsHj0Qk370Zn7ODzJNWvBs_R_MRxJFFSRqeuLAbKHlKhW4KAs8bPwko28EZLA_ef7JmRXy6kyC13v1Kx4'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCC1B6D01), Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    reverse: true,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFA1F882), borderRadius: BorderRadius.circular(12)),
                          child: const Text('Food', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF22740A))),
                        ),
                        const SizedBox(height: 8),
                        const Text('Hungry?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const Text("Let's find a bite.", style: TextStyle(fontSize: 14, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ModeLobbyScreen(mode: 'travel'),
              ));
            },
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAdS-otJCH7xzW0Eos_tBE2-2IKuwTLowFyS98T7b8Mq-Bv2mWBRdG6jmQORMbzltnFzMGwwUJ6tpkljfZlbclj8BWz9z_lT9Yu6eCAB82k3wE00gufB-VzhTt3bWw7xDZPCWvZArfPHkdemmiEdQkkI27Okibqt9pW0d1i1ztmJEl0rwsrnDRtNRqfaTzYWctIvFKwxsslzd4pR0OKc4cY9O82RwNVg0njXr7a86w5TwO1_CzLxWnM0YeumWdszQI2LkS6_vqWhFI'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCCA83300), Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    reverse: true,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFD24200), borderRadius: BorderRadius.circular(12)),
                          child: const Text('Explore', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                        const SizedBox(height: 8),
                        const Text('Adventure?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const Text("Plan a getaway.", style: TextStyle(fontSize: 14, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUtilityTiles() {
    return Column(
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 160),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuD6Pmr24ZeLeaRB30qH2LBQEmFxPo0QhwBbIV--BlUOUGzq1ZdC8F24NHn_Z5JXi_XbkrWlD-76EFLE__zsAb45ccath1kPMN7scfAIzScTD3KMI6C1ijVMeRYWLgoTZ5IBrClqn23t2JLWflnfUejZZ4Rb95Zwgcuzzixf7SaKkIIjCqejiYFligHF-uxOLwN5F3DgQ9EUGHrtnbhTBCOjxoNGi4AsYSUMuB1p-qtUYxDPRBg77RxIHmnEqfndBGiUIvmqtD2F5Oc'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withOpacity(0.4),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('DISCOVER YOUR MOOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  const Text('Late Night Snacks', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1ED),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.savings_outlined, color: Color(0xFFA83300), size: 18),
                        SizedBox(width: 8),
                        Expanded(child: Text('TOTAL SAVINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFA83300)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            text: '\$142',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF281812), fontFamily: 'Plus Jakarta Sans'),
                            children: [TextSpan(text: '.50', style: TextStyle(fontSize: 14, color: Color(0xFF5C4037)))],
                          ),
                        ),
                        Row(
                          children: const [
                            Icon(Icons.trending_up, color: Color(0xFF1B6D01), size: 14),
                            SizedBox(width: 4),
                            Expanded(child: Text('+12% this month', style: TextStyle(fontSize: 11, color: Color(0xFF1B6D01)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      bottom: -16, right: -16,
                      child: Icon(Icons.deck_outlined, size: 80, color: Color(0xFFF2D3CA)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.auto_awesome, color: Color(0xFF575B70), size: 18),
                            SizedBox(width: 8),
                            Expanded(child: Text('FAVORITE VIBE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF575B70)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Rooftop\nEnthusiast', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF281812), height: 1.1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildBucketList() {
    final items = [
      {'name': 'Sakura Sushi Bar', 'rating': '4.8', 'img': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBnazzwLxDYk5xy5dFcXjkub3P13sT1GuORr3UBeEMTg1tzo0MkT_j1awrEITKIDIfdN-LRxgSmXv9njy9yItgOs_G48yewuPvjCBj4oCcunB2nCUMSJgZafF_7RT3PYBu6tifmSvhIIRmPWIQdvlL2aoMPjVnpUYYXwH-HxqrwiLkwl1H_Ksyy_CtPJmyIv4FaucWzxcuI_dL88KR6TIwdCPxqADt80K7HcizcBgsnAUu2cbgpc60Wg7H8HM_a7eRH76KctHWUJK4'},
      {'name': 'Le Petit Bistro', 'rating': '4.5', 'img': 'https://lh3.googleusercontent.com/aida-public/AB6AXuDoXU81OhBhbYjrXh6vm_sh3gkyx9Slw-Qf0uMwS0Vr4V1P8l9pa_OSPgYPt3zyeVdlBe4g6qYnjkVsMxF73gaZ2FsDjpAiKMUOEYiqP7T2FC6Q0aj5I0dj3y6G-p8GTeqvyvhOqxeqpZ8OUZmK0bCsrcXbHpzqoIxmjDOHXjf7VV0vtd-B5efyriwpwmmiTXFPeAcl32nsm7b96lck8n6LAckYEXm6605AcJRM_DB7oUkaXBGqrFkEPLriYUE1KUWBmV4yx4h4AWU'},
      {'name': 'Morning Brew', 'rating': '4.9', 'img': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAUarNQLmU2gOr14gxVEOfUbECh8yItj8rvgtOKDielUryUuSFVmvjndP238v89XkU6CpyOAHiEcRUL_HIrNsQxnuBbVA9jHBsGfeG-2U1Kl3MfUJi424iX9HfxcPRLm50t2ICUTplXzx_xCM-fGTVpqcITdwT9az-9Cig1ccXnR-asduAdQjtX0PeKDVEO3xB3ZgakG8gluWHC6QT2J5A7_n17Ux0qr5xtno2RGU0eX9qGs_UdhRZE2kWAa7uQjwKbpJbC6RMesGM'},
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Bucket List Matches', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF281812))),
            Row(
              children: const [
                Text('See All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFA83300))),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFFA83300)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(item['img']!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Color(0xFFA1F882)),
                          const SizedBox(width: 4),
                          Text('${item['rating']} Match', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Group card (horizontal scroll) ──────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  const _GroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isHunger = group.mode == 'hunger';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isHunger ? const Color(0xFFE8FDD8) : const Color(0xFFFFEDE8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isHunger ? '🍽️' : '🌍', style: const TextStyle(fontSize: 24)),
            const Spacer(),
            Text(
              group.name,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF281812)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6F7B64)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Group action button (Create / Join) ──────────────────────────────────────

class _GroupActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GroupActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.onSurface),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF281812))),
          ],
        ),
      ),
    );
  }
}

// ─── Join group bottom sheet ──────────────────────────────────────────────────

class _JoinGroupSheet extends StatefulWidget {
  final TextEditingController codeCtrl;
  final GroupService service;
  const _JoinGroupSheet({required this.codeCtrl, required this.service});

  @override
  State<_JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends State<_JoinGroupSheet> {
  bool _loading = false;

  Future<void> _join() async {
    final code = widget.codeCtrl.text.trim();
    if (code.length != 6) return;
    setState(() => _loading = true);

    final result = await widget.service.joinByCode(code);
    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.errorMessage ?? 'Could not join.',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    Navigator.of(context).pop(); // close sheet

    // Navigate to the group detail
    final group = await widget.service.getGroupDetails(result.groupId!);
    if (!mounted || group == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Join a Group',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.onSurface)),
          const SizedBox(height: 4),
          Text('Enter the 6-character code shared by your friend.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline)),
          const SizedBox(height: 24),
          TextField(
            controller: widget.codeCtrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.onSurface,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '· · · · · ·',
              hintStyle: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.surfaceContainerHigh,
                letterSpacing: 8,
              ),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.cardBorder, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
              ),
            ),
            onChanged: (v) {
              if (v.length == 6) _join();
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _join,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryGreen.withOpacity(0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text('Join Group', style: AppTextStyles.button.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
