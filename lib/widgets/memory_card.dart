import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/memory.dart';

class MemoryCard extends StatelessWidget {
  final Memory memory;
  final int index;

  const MemoryCard({super.key, required this.memory, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = _gradColors(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.cardBorder, width: 2),
        boxShadow: [BoxShadow(color: AppColors.stickerShadow, offset: const Offset(0, 4), blurRadius: 12)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 160, width: double.infinity,
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors)),
            child: Stack(children: [
              Center(child: Text(memory.emoji, style: const TextStyle(fontSize: 56))),
              Positioned(top: 16, right: 16, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.photo_library_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('${memory.photoCount}', style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
                ]),
              )),
            ]),
          ),
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(memory.title, style: AppTextStyles.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: Text('\$${memory.spent.toStringAsFixed(0)}', style: AppTextStyles.labelBold.copyWith(color: AppColors.primaryGreenDark)),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.outline), const SizedBox(width: 6),
              Text(memory.date, style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline)),
              const SizedBox(width: 16),
              Icon(Icons.location_on_rounded, size: 14, color: AppColors.outline), const SizedBox(width: 4),
              Text(memory.location, style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline)),
            ]),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 6, children: memory.tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Text(tag, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGreenDark)),
            )).toList()),
          ])),
        ]),
      ),
    );
  }

  List<Color> _gradColors(int i) {
    final p = [[const Color(0xFFE040FB), const Color(0xFF7C4DFF)], [const Color(0xFFFF6E40), const Color(0xFFFF3D00)],
      [const Color(0xFF69F0AE), const Color(0xFF00E676)], [const Color(0xFFFFD740), const Color(0xFFFF9100)],
      [const Color(0xFF40C4FF), const Color(0xFF0091EA)]];
    return p[i % p.length];
  }
}
