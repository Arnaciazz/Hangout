import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:confetti/confetti.dart';

class MatchScreen extends StatefulWidget {
  final VoidCallback? onDismiss;
  const MatchScreen({super.key, this.onDismiss});
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with TickerProviderStateMixin {
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    Future.delayed(const Duration(milliseconds: 300), () => _confetti.play());
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F8),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuDtRFYlMQIl4Osv5HkzSrbPv5-fjiHMaHo0xXo3B9g3cxnSvJzvpbTCUq15_7WWK2a2gVgQcdmce1sVdM3K3qoIjtzRw83bk1zt3zuilxPJP6a3THtnpzg9Bh5GGJMeTUx5r1K6g2kWWKsQCfceDjaR13PYYLd7oFeImg6-mFJLG2zbmyDRdkqUAyfkfiQcj0R5wk0Uy2KAOkz50JyI9H_q5USHBkSTO_dD-pCxBwIgLYjCCAmUmXxn2ynyXD8v4SGd6P9g5dwTOO8',
              fit: BoxFit.cover,
            ),
          ),
          // Gradient Scrim
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF1A0F0C), Colors.black54, Colors.transparent],
                  stops: [0.0, 0.4, 0.8],
                ),
              ),
            ),
          ),
          
          // Floating Top Actions
          Positioned(
            top: 56, left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(onTap: widget.onDismiss, child: _glassBtn(Icons.close)),
                _glassPill(),
                _glassBtn(Icons.share),
              ],
            ),
          ),

          // Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 32),
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 250), // push content down
                  const Text('CONSENSUS REACHED', style: TextStyle(color: Color(0xFFFFB59D), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5, shadows: [Shadow(blurRadius: 10, color: Colors.black54)])),
                  const SizedBox(height: 4),
                  const Text('Neon Lotus', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, fontFamily: 'Plus Jakarta Sans', height: 1.1, shadows: [Shadow(blurRadius: 10, color: Colors.black54)])),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _infoPill(Icons.star, '4.9', iconColor: const Color(0xFFA83300)),
                      const SizedBox(width: 8),
                      _infoPill(null, 'Thai Fusion'),
                      const SizedBox(width: 8),
                      _infoPill(null, '0.8 mi'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Bento Grid
                  Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: const DecorationImage(
                                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuByQkI7rvLd6WNySy2_v2p7IAZ1lrCw28cAU7o5WrGQnLYx5XA22nuR2zlaECgzIo4dTpsQTb_IFMY6eat-3LAFk4vTXeWO_4XpwbZ-6InlccnO8FdBUEQ0DmeccGz5I9L-GY2x30MOQKmSQxUBNdGFwWo4U5uQJQYmj66ZKlxMgXfQ04L6qGfeugu_Y5W8jhgfFSmZCf45rjqf_kIwBADURrqEw6H9sj9VFga1s6iM5ZsxRrrmykioQXc6E-Lz8Kp5aYfSHS75KNk'),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 8))],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent]),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('TOP VOTED DISH', style: TextStyle(color: Color(0xFFFFDBD0), fontSize: 11, fontWeight: FontWeight.w700)),
                                  Text('Spicy Pad Kra Pao', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _glassPanel(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: const BoxDecoration(color: Color(0xFFFBDCD3), shape: BoxShape.circle),
                                  child: const Icon(Icons.payments, color: Color(0xFFA83300), size: 20),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('ESTIMATED SHARE', style: TextStyle(color: Color(0xFF5C4037), fontSize: 11, fontWeight: FontWeight.w700)),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: const [
                                        Text('\$42', style: TextStyle(color: Color(0xFF281812), fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
                                        Text('/pp', style: TextStyle(color: Color(0xFF707389), fontSize: 14)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _glassPanel(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E2E1),
                            borderRadius: BorderRadius.circular(8),
                            image: const DecorationImage(
                              image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuB9KVO_G7LHfY-eTp4AfEx5Q0xzjtpaKzFkocntuTpYAEKagw8w6SuRjzK1v03YOiTh3GPXdRWTknF1C_IbER6jiZGiFNoKxeBy2CiQ-Gm8FZ1-jIOXE2jpTG5AKwDow4-2qBS8XXAZhTcO6pkPalyW5IG1C2qEhFJX0Z2Tm7klkzTPNyDEdtkOpB6rMMKdWCffHLVjqKFQMGZw2tdM5jntHZ3gP-UGSRLC-UNdgpcXe5w8bnu9Y-fFsg5IDcbMdRBca7drdSAAJuU'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: const Center(child: Icon(Icons.location_on, color: Color(0xFFA83300))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('1248 Neon Ave', style: TextStyle(color: Color(0xFF281812), fontSize: 18, fontWeight: FontWeight.w600)),
                              Text('Downtown District • Open till 11 PM', style: TextStyle(color: Color(0xFF5C4037), fontSize: 14)),
                            ],
                          ),
                        ),
                        Container(
                          width: 40, height: 40,
                          decoration: const BoxDecoration(color: Color(0xFFFFE9E3), shape: BoxShape.circle),
                          child: const Icon(Icons.directions, color: Color(0xFFA83300)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA83300),
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
                  const SizedBox(height: 16),
                  _glassPanel(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.receipt_long, color: Color(0xFFA83300)),
                        SizedBox(width: 8),
                        Text('Add to Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF281812))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Color(0xFFA83300), Color(0xFF1B6D01), Color(0xFFFF5200)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassBtn(IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F6).withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Icon(icon, color: const Color(0xFF281812), size: 20),
        ),
      ),
    );
  }

  Widget _glassPill() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F6).withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFA1F882), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('MATCH FOUND', style: TextStyle(color: Color(0xFF281812), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPill(IconData? icon, String text, {Color? iconColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F6).withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 4),
              ],
              Text(text, style: const TextStyle(color: Color(0xFF281812), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassPanel({required Widget child, required EdgeInsets padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F6).withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: child,
        ),
      ),
    );
  }
}
