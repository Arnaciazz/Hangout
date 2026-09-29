import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_button.dart';
import '../widgets/hangout_motion.dart';

/// Filters the user can set before swiping places.
class SwipeFilters {
  final List<String> placeTypes; // Google place types; empty = mode default
  final int? maxPrice; // 1-4, null = any
  final bool openNowOnly;
  final int radiusKm; // 1-10

  const SwipeFilters({
    this.placeTypes = const [],
    this.maxPrice,
    this.openNowOnly = false,
    this.radiusKm = 3,
  });

  int get radiusMeters => radiusKm * 1000;

  SwipeFilters copyWith({
    List<String>? placeTypes,
    Object? maxPrice = _sentinel,
    bool? openNowOnly,
    int? radiusKm,
  }) {
    return SwipeFilters(
      placeTypes: placeTypes ?? this.placeTypes,
      maxPrice: maxPrice == _sentinel ? this.maxPrice : maxPrice as int?,
      openNowOnly: openNowOnly ?? this.openNowOnly,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }
}

const _sentinel = Object();

typedef _Option = ({String label, List<String> types});

const List<_Option> _hungerOptions = [
  (label: 'Pizza', types: ['pizza_restaurant']),
  (label: 'Burgers', types: ['hamburger_restaurant', 'fast_food_restaurant']),
  (label: 'Sushi', types: ['sushi_restaurant', 'japanese_restaurant']),
  (label: 'Noodles', types: ['ramen_restaurant', 'noodle_shop', 'chinese_restaurant']),
  (label: 'Biryani', types: ['indian_restaurant']),
  (label: 'Arabian', types: ['middle_eastern_restaurant']),
  (label: 'Cafe', types: ['cafe']),
  (label: 'Brewery', types: ['bar', 'brewery']),
  (label: 'North Indian', types: ['north_indian_restaurant', 'indian_restaurant']),
  (label: 'South Indian', types: ['indian_restaurant']),
  (label: 'Breakfast', types: ['breakfast_restaurant', 'brunch_restaurant']),
  (label: 'Desserts', types: [
    'dessert_shop',
    'dessert_restaurant',
    'ice_cream_shop',
    'bakery'
  ]),
];

const List<_Option> _travelOptions = [
  (label: 'Museums', types: ['museum']),
  (label: 'Parks', types: ['park', 'national_park']),
  (label: 'Amusement', types: ['amusement_park', 'amusement_center']),
  (label: 'Art galleries', types: ['art_gallery']),
  (label: 'Historic sites', types: ['historical_landmark', 'monument']),
  (label: 'Shopping', types: ['shopping_mall', 'market']),
  (label: 'Entertainment', types: ['tourist_attraction', 'performing_arts_theater']),
];

class SessionFiltersScreen extends StatefulWidget {
  final String mode;
  final SwipeFilters initial;

  const SessionFiltersScreen({
    super.key,
    required this.mode,
    required this.initial,
  });

  @override
  State<SessionFiltersScreen> createState() => _SessionFiltersScreenState();
}

class _SessionFiltersScreenState extends State<SessionFiltersScreen> {
  late SwipeFilters _filters;
  final Set<String> _selectedLabels = {};

  bool get _isHunger => widget.mode == 'hunger';
  static const _accent = AppColors.brand;
  static const _accentTint = AppColors.brandTint;
  List<_Option> get _options => _isHunger ? _hungerOptions : _travelOptions;

  @override
  void initState() {
    super.initState();
    _filters = widget.initial;
  }

  void _toggleOption(_Option opt) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedLabels.remove(opt.label)) _selectedLabels.add(opt.label);

      final types = <String>{};
      for (final o in _options) {
        if (_selectedLabels.contains(o.label)) types.addAll(o.types);
      }
      _filters = _filters.copyWith(placeTypes: types.toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: HangoutBackButton(
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter, AppSpacing.x2, AppSpacing.gutter, AppSpacing.x8),
        children: [
          Text('Narrow it down', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text('Everything here is optional.', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.x8),
          _sectionHeader(
            _isHunger ? 'Craving' : 'Categories',
            'Pick a few, or leave it open.',
          ),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              for (final opt in _options)
                _ChoiceChip(
                  label: opt.label,
                  selected: _selectedLabels.contains(opt.label),
                  accent: _accent,
                  tint: _accentTint,
                  onTap: () => _toggleOption(opt),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.x8),
          _sectionHeader('Budget', 'Skip anything pricier.'),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              _ChoiceChip(
                label: 'Any',
                selected: _filters.maxPrice == null,
                accent: _accent,
                tint: _accentTint,
                onTap: () => _setPrice(null),
              ),
              for (var i = 1; i <= 4; i++)
                _ChoiceChip(
                  label: '₹' * i,
                  selected: _filters.maxPrice == i,
                  accent: _accent,
                  tint: _accentTint,
                  onTap: () => _setPrice(i),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.x8),
          _sectionHeader('Open now', 'Only somewhere you can walk into.'),
          SwitchListTile(
            value: _filters.openNowOnly,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _filters = _filters.copyWith(openNowOnly: v));
            },
            activeThumbColor: Colors.white,
            activeTrackColor: _accent,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Only places open now',
              style: AppTextStyles.body,
            ),
          ),

          const SizedBox(height: AppSpacing.x6),
          _sectionHeader('How far', '${_filters.radiusKm} km from your spot.'),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accent,
              thumbColor: _accent,
              overlayColor: _accent.withValues(alpha: 0.12),
              valueIndicatorColor: _accent,
              valueIndicatorTextStyle:
                  AppTextStyles.captionStrong.copyWith(color: Colors.white),
            ),
            child: Slider(
              value: _filters.radiusKm.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${_filters.radiusKm} km',
              onChanged: (v) => setState(
                  () => _filters = _filters.copyWith(radiusKm: v.round())),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 km', style: AppTextStyles.caption),
              Text('10 km', style: AppTextStyles.caption),
            ],
          ),

        ],
      ),
      bottomNavigationBar: StickyActionBar(
        child: HangoutButton(
          label: _isHunger ? 'Find places to eat' : 'Find places to go',
          size: HangoutButtonSize.lg,
          block: true,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop(_filters);
          },
        ),
      ),
    );
  }

  void _setPrice(int? p) {
    HapticFeedback.selectionClick();
    setState(() => _filters = _filters.copyWith(maxPrice: p));
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h3),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTextStyles.small),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Color tint;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.94,
      haptics: false,
      // No `alignment:` here — Container wraps an aligned child in an Align,
      // which expands to the full available width inside a Wrap and turns
      // every pill into a full-width bar. Size to the label instead.
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent : AppColors.surface,
          borderRadius: AppRadius.pillAll,
          border: Border.all(color: selected ? accent : AppColors.border),
        ),
        child: AnimatedDefaultTextStyle(
          duration: AppMotion.base,
          style: AppTextStyles.smallStrong.copyWith(
            color: selected ? Colors.white : AppColors.textBody,
            height: 1,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
