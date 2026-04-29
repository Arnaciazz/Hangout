import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onStartSwipe;
  const HomeScreen({super.key, this.onStartSwipe});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: const NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuC9r8n7Mo7KePtFQwZ-h9pE_jW-0KZ73nHNTLygIcMOngaeiYdNzUif9iK1xM5uFg77yidhCGpicQyLIQ3WO1fJjpZHGaOJx--cdAHPGFJK4jl5OUpcXq8_ni91OZoV5l8KpNnwH868D63hpf5NdMh9lFA1kTpKwHS31Jm-yUFKGniYnl_9Y-vB3dnG9QvjsGRk25vKMFlCExNETiXddWNEfNY-HaWCUu5EwBtQmdjgMSC7qN5RkCcW9Vr-53eH5Thv31y33lk0V5c'),
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
          _buildHeroTiles(),
          const SizedBox(height: 16),
          _buildUtilityTiles(),
          const SizedBox(height: 24),
          _buildBucketList(),
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
            onTap: () { HapticFeedback.lightImpact(); widget.onStartSwipe?.call(); },
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
