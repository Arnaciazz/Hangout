import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/restaurant.dart';

class RestaurantSwipeCard extends StatelessWidget {
  final Restaurant restaurant;
  final bool isTop;

  const RestaurantSwipeCard({
    super.key,
    required this.restaurant,
    this.isTop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.cardBorder, width: 2),
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.stickerShadow,
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Area
            _buildHeroImage(),
            // Content Area
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVibeSection(),
                    const SizedBox(height: 24),
                    _buildMenuSection(),
                    const SizedBox(height: 24),
                    _buildReviewsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    // Generate a colorful gradient as hero image placeholder
    final colors = _getRestaurantColors();
    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Content overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryGreenDark.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              restaurant.rating.toString(),
                              style: AppTextStyles.labelBold.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          restaurant.priceRange,
                          style: AppTextStyles.labelBold.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              restaurant.distance,
                              style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    restaurant.name,
                    style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Large emoji top-right
          Positioned(
            top: 20,
            right: 20,
            child: Text(
              _getRestaurantEmoji(),
              style: const TextStyle(fontSize: 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vibe Check', style: AppTextStyles.labelBold.copyWith(
          color: AppColors.onSurfaceVariant,
          letterSpacing: 1,
        )),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: restaurant.vibes.map((vibe) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              vibe,
              style: AppTextStyles.labelBold.copyWith(color: AppColors.onSurface),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Curated Menu', style: AppTextStyles.labelBold.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1,
            )),
            Text('See All', style: AppTextStyles.labelBold.copyWith(
              color: AppColors.primaryGreen,
            )),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: restaurant.menu.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = restaurant.menu[index];
              return Container(
                width: 120,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 24)),
                    Text(
                      item.name,
                      style: AppTextStyles.labelBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '\$${item.price.toInt()}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What people say', style: AppTextStyles.labelBold.copyWith(
          color: AppColors.onSurfaceVariant,
          letterSpacing: 1,
        )),
        const SizedBox(height: 12),
        ...restaurant.reviews.map((review) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.secondaryPurple.withOpacity(0.2),
                      child: Text(
                        review.name[0],
                        style: AppTextStyles.labelBold.copyWith(
                          color: AppColors.secondaryPurpleDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(review.name, style: AppTextStyles.labelBold),
                        Text(
                          review.badge,
                          style: AppTextStyles.labelTiny.copyWith(
                            color: AppColors.secondaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '"${review.text}"',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  List<Color> _getRestaurantColors() {
    switch (restaurant.imageUrl) {
      case 'neon_lotus':
        return [const Color(0xFFE040FB), const Color(0xFF7C4DFF)];
      case 'sakura':
        return [const Color(0xFFFF8A80), const Color(0xFFFF80AB)];
      case 'bistro':
        return [const Color(0xFF82B1FF), const Color(0xFF448AFF)];
      case 'brew':
        return [const Color(0xFFFFD180), const Color(0xFFFF9100)];
      default:
        return [AppColors.primaryGreen, AppColors.primaryGreenDim];
    }
  }

  String _getRestaurantEmoji() {
    switch (restaurant.imageUrl) {
      case 'neon_lotus':
        return '🏮';
      case 'sakura':
        return '🌸';
      case 'bistro':
        return '🍷';
      case 'brew':
        return '☕';
      default:
        return '🍽️';
    }
  }
}
