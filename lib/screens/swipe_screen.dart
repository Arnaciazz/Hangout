import 'package:flutter/material.dart';
import 'dart:ui';

class SwipeScreen extends StatefulWidget {
  final VoidCallback? onMatch;
  const SwipeScreen({super.key, this.onMatch});
  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F8),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(),
            _buildDetails(),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () { widget.onMatch?.call(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B6C00).withOpacity(0.9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Book a Table', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuBlrqxk44NAOHMzzaZxrPxfB_44eNKoAGg-Ksh9UwaOCrUQSLQz__mnRQqIXpIkGeP3DH0WjW-0kLTQ2npltc0aVCVsxyfEHylZ3N9wjI1zVWbQDCfvYXxtCVbLxzU7fVqxUA_jVfbanHh6OTDgzCctkyQKT4r0p7tozIsNG4TDZ55bpIjlC5pIyD2ictGaTV4GFHzs7nRjGBuJjr8tkBYLwpWTtBNGWnfsFjiEvjww2xWjyw1cyhWSmhPgPy20NsycYcAQRvyyrLQ',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.black45, Colors.transparent],
                  stops: [0.0, 0.4, 0.8],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20, right: 20, bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF58CC02), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: const [
                          Icon(Icons.star, color: Color(0xFF1E5000), size: 14),
                          SizedBox(width: 4),
                          Text('4.9', style: TextStyle(color: Color(0xFF1E5000), fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('NEW ARRIVAL', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Neon Lotus', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, fontFamily: 'Plus Jakarta Sans', height: 1.1)),
                const Text('Modern Asian Fusion & Craft Cocktails', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _glassPill(Icons.payments, '\$120 for two', isHighlight: false),
                      const SizedBox(width: 12),
                      _glassPill(Icons.location_on, '0.8 mi away', isHighlight: false),
                      const SizedBox(width: 12),
                      _glassPill(Icons.local_offer, '15% off Drinks', isHighlight: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _actionBtn(Icons.close, Colors.white, Colors.black26),
                    const SizedBox(width: 24),
                    _actionBtn(Icons.bookmark, Colors.white70, Colors.white10, size: 56),
                    const SizedBox(width: 24),
                    _actionBtn(Icons.favorite, const Color(0xFFFFFFFF), const Color(0xFF2B6C00), size: 64, onTap: () => widget.onMatch?.call()),
                  ],
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassPill(IconData icon, String text, {bool isHighlight = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isHighlight ? const Color(0xFFFD5835).withOpacity(0.9) : Colors.white.withOpacity(0.15),
            border: Border.all(color: isHighlight ? const Color(0xFFFD5835) : Colors.white24),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: isHighlight ? const Color(0xFF570C00) : Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(text, style: TextStyle(color: isHighlight ? const Color(0xFF570C00) : Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, Color bg, {double size = 64, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30),
            ),
            child: Icon(icon, color: color, size: size * 0.45),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      color: const Color(0xFFFCF9F8),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 48, height: 6, decoration: BoxDecoration(color: const Color(0xFFE5E2E1), borderRadius: BorderRadius.circular(3))),
          ),
          const SizedBox(height: 24),
          const Text('Vibe Check', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1C1B1B))),
          const SizedBox(height: 16),
          Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDHVFO3xKzGaql8Y0vfa0DmxzPDtxKUoTtHtFkkcdgAD4Z2evmYIXzu2WL6oPKIYsCAXMSE7022OlvkMR7xPPsAmMiZEhSagK7ploBExjjK9sxdhL2qxnz-Ckjq3g1XnCvVrSBAN10zC7MSS0w3X7wBzH4brUVAbKMcoTLF8ZPXA27h8dpF73aPCC7TEErBXPlAKqN69_US2VN0x3j8YS9T6NeZ6wNStH-yx-cwni9DjxM7IBla7KZp_W_1CgiP7LBsPjFYpRpoDNs'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: Colors.white30, shape: BoxShape.circle, border: Border.all(color: Colors.white54)),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildMenu(),
          const SizedBox(height: 32),
          _buildReviews(),
          const SizedBox(height: 80), // padding for FAB
        ],
      ),
    );
  }

  // Curated Menu
  Widget _buildMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Curated Menu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1C1B1B))),
            Row(
              children: const [
                Text('See All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFA83300))),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFFA83300)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _menuItem('Dragon Roll', '\$24', 'https://lh3.googleusercontent.com/aida-public/AB6AXuBnazzwLxDYk5xy5dFcXjkub3P13sT1GuORr3UBeEMTg1tzo0MkT_j1awrEITKIDIfdN-LRxgSmXv9njy9yItgOs_G48yewuPvjCBj4oCcunB2nCUMSJgZafF_7RT3PYBu6tifmSvhIIRmPWIQdvlL2aoMPjVnpUYYXwH-HxqrwiLkwl1H_Ksyy_CtPJmyIv4FaucWzxcuI_dL88KR6TIwdCPxqADt80K7HcizcBgsnAUu2cbgpc60Wg7H8HM_a7eRH76KctHWUJK4'),
              const SizedBox(width: 16),
              _menuItem('Smoked Negroni', '\$18', 'https://lh3.googleusercontent.com/aida-public/AB6AXuDoXU81OhBhbYjrXh6vm_sh3gkyx9Slw-Qf0uMwS0Vr4V1P8l9pa_OSPgYPt3zyeVdlBe4g6qYnjkVsMxF73gaZ2FsDjpAiKMUOEYiqP7T2FC6Q0aj5I0dj3y6G-p8GTeqvyvhOqxeqpZ8OUZmK0bCsrcXbHpzqoIxmjDOHXjf7VV0vtd-B5efyriwpwmmiTXFPeAcl32nsm7b96lck8n6LAckYEXm6605AcJRM_DB7oUkaXBGqrFkEPLriYUE1KUWBmV4yx4h4AWU'),
              const SizedBox(width: 16),
              _menuItem('Crispy Rice', '\$16', 'https://lh3.googleusercontent.com/aida-public/AB6AXuAUarNQLmU2gOr14gxVEOfUbECh8yItj8rvgtOKDielUryUuSFVmvjndP238v89XkU6CpyOAHiEcRUL_HIrNsQxnuBbVA9jHBsGfeG-2U1Kl3MfUJi424iX9HfxcPRLm50t2ICUTplXzx_xCM-fGTVpqcITdwT9az-9Cig1ccXnR-asduAdQjtX0PeKDVEO3xB3ZgakG8gluWHC6QT2J5A7_n17Ux0qr5xtno2RGU0eX9qGs_UdhRZE2kWAa7uQjwKbpJbC6RMesGM'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuItem(String title, String price, String img) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1C1B1B))),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFA83300))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reviews
  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What people say', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1C1B1B))),
        const SizedBox(height: 16),
        _reviewItem('Sarah J.', 'Local Guide', '"Absolutely electric atmosphere. The smoked negroni is a must-try, and the DJ perfectly matched the energy of the room. Perfect spot for a Friday night out."'),
        const SizedBox(height: 16),
        _reviewItem('Michael T.', '', '"The sushi rolls are incredibly fresh. A bit loud, but that\'s the vibe. Service was remarkably fast."'),
      ],
    );
  }

  Widget _reviewItem(String name, String subtitle, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE5E2E1),
                child: Text(name[0], style: const TextStyle(color: Color(0xFF1C1B1B), fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1C1B1B))),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF8B8A8A))),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF555454), height: 1.4)),
        ],
      ),
    );
  }
}
