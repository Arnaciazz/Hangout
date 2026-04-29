import 'package:flutter/material.dart';

class MemoryScreen extends StatelessWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFFCF9F8).withOpacity(0.8),
            surfaceTintColor: Colors.transparent,
            pinned: true,
            title: const Text('Memory Lane', style: TextStyle(color: Color(0xFF1C1B1B), fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Plus Jakarta Sans')),
            centerTitle: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: const Text('A visual receipt of good times.', style: TextStyle(color: Color(0xFF3F4A36), fontSize: 16)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTimelineNode(
                  context,
                  date: 'Oct 12 • Shinjuku',
                  title: 'Omakase Nights',
                  imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBTiypGRdCBGaBT7VQdiO_FQyTPPSkv51tdfjDOFQuSq4p1ypDC4HdOYylTfL4a415ukSneRNyNMwN7PDYcCVbqrXQTSPbPnBdaxfOUoTTf3FUF35br1r1EQFFWj9mrSXJJafeq8XaxZWyD5vwILCMMTnqQb0690kcOjNgI_kSNcFHkj4Isa3B8V6Y8YjfroeTUSZk63WqFlIJcPvHiXKu-rdD9urbW-3y4q1vHysM8yrYxaX1pEQwPtEvEPMTD41S8czxBBNAufzU',
                  isFirst: true,
                  isLast: false,
                  detailsWidget: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _bentoBox('Total Bill', '\$245.50', valueColor: const Color(0xFF1C1B1B))),
                          const SizedBox(width: 8),
                          Expanded(child: _bentoBox('Your Share', '\$122.75', valueColor: const Color(0xFF2B6C00))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFFD5835), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('TOP VOTED DISH', style: TextStyle(color: Color(0xCC570C00), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                                SizedBox(height: 4),
                                Text('Otoro Nigiri', style: TextStyle(color: Color(0xFF570C00), fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Container(
                              width: 40, height: 40,
                              decoration: const BoxDecoration(color: Color(0x1A570C00), shape: BoxShape.circle),
                              child: const Icon(Icons.restaurant, color: Color(0xFF570C00), size: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTimelineNode(
                  context,
                  date: 'Oct 10 • Roppongi',
                  title: 'Neon Sips',
                  imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBt2-zMQk7KUNVaTFM6uvW4ko1waRuoC4ddAF2k0fPj7FUBfv5RUf4Zxah9FVN17CrwMF6Y_l4ZazPekjOdwM7pdobfmg9W_A4SrOoCPDLVUuEXHAZWZuhR4Pon5LGd44jILpO9fi-eWsBZqGikBOYFbHuMT3YPTK-6-FTthFy6NoKCPJ5Yh1J20Aq0EppuWY7WQ56WLV26jxO5F1CCZ1nVkEf6UYGDMW6-uWv7GPXc2hqNyisfM-maDx-cFMH69txnteoygpW_CRo',
                  isFirst: false,
                  isLast: false,
                  detailsWidget: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFF58CC02), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('YOUR SHARE PAID', style: TextStyle(color: Color(0xCC1E5000), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                                SizedBox(height: 4),
                                Text('\$48.00', style: TextStyle(color: Color(0xFF1E5000), fontSize: 22, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const Icon(Icons.check_circle, color: Color(0xFF1E5000), size: 32),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _bentoBox('Group Total', '\$144.00', valueColor: const Color(0xFF1C1B1B), isSmall: true)),
                          const SizedBox(width: 8),
                          Expanded(child: _bentoBox('Favorite Drink', 'Yuzu Spritz', valueColor: const Color(0xFF1C1B1B), isSmall: true)),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildTimelineNode(
                  context,
                  date: 'Oct 09 • Shibuya',
                  title: 'Morning Brew',
                  imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDwvIozD73T7VawzMDBhq0GlSkJTmK3De9KjafnN1H2CahfqVWcTISMeTlEFsi_c_krrIWVVH3EEgdN6Qemml8jYu2lY0sAVh7rpcfbGSfDy7MxcjwAVpdE-GY0gz1WCqMv8u3WhjYs4_h-rzY4K_Uoa8vQw0QOwS6duMQeqVP8uA9_zgor_j-AZDknkw_xYqlshG1_8VmAvdYMqVPON_JHt3aIwjGaBMFuV7qDu3QRCydQUnKG9kSAlZaiZDHByGNy9MX8ilVnmEg',
                  isFirst: false,
                  isLast: true,
                  aspectRatio: 16 / 9,
                  detailsWidget: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF6F3F2), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Covered by Alex', style: TextStyle(color: Color(0xFF1C1B1B), fontSize: 16)),
                        Text('SETTLED', style: TextStyle(color: Color(0xFF2B6C00), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(
    BuildContext context, {
    required String date,
    required String title,
    required String imageUrl,
    required Widget detailsWidget,
    required bool isFirst,
    required bool isLast,
    double aspectRatio = 4 / 5,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line & Dot
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 24, bottom: -40,
                    child: Container(
                      width: 2,
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: Color(0x99BECBB1), width: 2, style: BorderStyle.solid)), // Use dashed using custom painter if needed, but solid is fine for simple impl
                      ),
                    ),
                  ),
                Positioned(
                  top: 24,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: isFirst ? const Color(0xFF2B6C00) : const Color(0xFFE5E2E1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFCF9F8), width: 4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.black26, Colors.transparent],
                            stops: [0.0, 0.4, 1.0],
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(date, style: const TextStyle(color: Color(0xFFE5E2E1), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'Plus Jakarta Sans')),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  detailsWidget,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bentoBox(String title, String value, {required Color valueColor, bool isSmall = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF0EDEC), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: Color(0xFF3F4A36), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: valueColor, fontSize: isSmall ? 16 : 22, fontWeight: isSmall ? FontWeight.w500 : FontWeight.w700)),
        ],
      ),
    );
  }
}
