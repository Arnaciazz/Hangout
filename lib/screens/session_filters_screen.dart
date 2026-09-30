import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
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

  /// Stored on the session, so the host's choices survive reopening the lobby.
  Map<String, dynamic> toJson() => {
        'place_types': placeTypes,
        'max_price': maxPrice,
        'open_now_only': openNowOnly,
        'radius_km': radiusKm,
      };

  factory SwipeFilters.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SwipeFilters();
    return SwipeFilters(
      placeTypes: [
        for (final t in (json['place_types'] as List? ?? const [])) t as String,
      ],
      maxPrice: (json['max_price'] as num?)?.toInt(),
      openNowOnly: json['open_now_only'] as bool? ?? false,
      radiusKm: ((json['radius_km'] as num?)?.toInt() ?? 3).clamp(1, 10),
    );
  }
}

const _sentinel = Object();

typedef _Option = ({String id, List<String> types});

const List<_Option> _hungerOptions = [
  (id: 'pizza', types: ['pizza_restaurant']),
  (id: 'burgers', types: ['hamburger_restaurant', 'fast_food_restaurant']),
  (id: 'sushi', types: ['sushi_restaurant', 'japanese_restaurant']),
  (id: 'noodles', types: ['ramen_restaurant', 'noodle_shop', 'chinese_restaurant']),
  (id: 'biryani', types: ['indian_restaurant']),
  (id: 'arabian', types: ['middle_eastern_restaurant']),
  (id: 'cafe', types: ['cafe']),
  (id: 'brewery', types: ['bar', 'brewery']),
  (id: 'north_indian', types: ['north_indian_restaurant', 'indian_restaurant']),
  (id: 'south_indian', types: ['indian_restaurant']),
  (id: 'breakfast', types: ['breakfast_restaurant', 'brunch_restaurant']),
  (id: 'desserts', types: [
    'dessert_shop',
    'dessert_restaurant',
    'ice_cream_shop',
    'bakery'
  ]),
];

const List<_Option> _travelOptions = [
  (id: 'museums', types: ['museum']),
  (id: 'parks', types: ['park', 'national_park']),
  (id: 'amusement', types: ['amusement_park', 'amusement_center']),
  (id: 'galleries', types: ['art_gallery']),
  (id: 'historic', types: ['historical_landmark', 'monument']),
  (id: 'shopping', types: ['shopping_mall', 'market']),
  (id: 'entertainment', types: ['tourist_attraction', 'performing_arts_theater']),
];

String _optionLabel(AppLocalizations l10n, String id) => switch (id) {
      'pizza' => l10n.catPizza,
      'burgers' => l10n.catBurgers,
      'sushi' => l10n.catSushi,
      'noodles' => l10n.catNoodles,
      'biryani' => l10n.catBiryani,
      'arabian' => l10n.catArabian,
      'cafe' => l10n.catCafe,
      'brewery' => l10n.catBrewery,
      'north_indian' => l10n.catNorthIndian,
      'south_indian' => l10n.catSouthIndian,
      'breakfast' => l10n.catBreakfast,
      'desserts' => l10n.catDesserts,
      'museums' => l10n.catMuseums,
      'parks' => l10n.catParks,
      'amusement' => l10n.catAmusement,
      'galleries' => l10n.catGalleries,
      'historic' => l10n.catHistoric,
      'shopping' => l10n.catShopping,
      _ => l10n.catEntertainment,
    };

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
  final Set<String> _selected = {};

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
      if (!_selected.remove(opt.id)) _selected.add(opt.id);

      final types = <String>{};
      for (final o in _options) {
        if (_selected.contains(o.id)) types.addAll(o.types);
      }
      _filters = _filters.copyWith(placeTypes: types.toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          Text(l10n.filtersTitle, style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text(l10n.filtersBody, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.x8),
          _sectionHeader(
            _isHunger ? l10n.filtersCraving : l10n.filtersCategories,
            l10n.filtersPickFew,
          ),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              for (final opt in _options)
                _ChoiceChip(
                  label: _optionLabel(l10n, opt.id),
                  selected: _selected.contains(opt.id),
                  accent: _accent,
                  tint: _accentTint,
                  onTap: () => _toggleOption(opt),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.x8),
          _sectionHeader(l10n.filtersBudget, l10n.filtersBudgetHint),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              _ChoiceChip(
                label: l10n.filtersAny,
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
          _sectionHeader(l10n.filtersOpenNow, l10n.filtersOpenNowHint),
          SwitchListTile(
            value: _filters.openNowOnly,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _filters = _filters.copyWith(openNowOnly: v));
            },
            activeThumbColor: Colors.white,
            activeTrackColor: _accent,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.filtersOpenNowSwitch, style: AppTextStyles.body),
          ),

          const SizedBox(height: AppSpacing.x6),
          _sectionHeader(
              l10n.filtersHowFar, l10n.filtersHowFarHint(_filters.radiusKm)),
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
              label: l10n.filtersKm(_filters.radiusKm),
              onChanged: (v) => setState(
                  () => _filters = _filters.copyWith(radiusKm: v.round())),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.filtersKm(1), style: AppTextStyles.caption),
              Text(l10n.filtersKm(10), style: AppTextStyles.caption),
            ],
          ),

        ],
      ),
      bottomNavigationBar: StickyActionBar(
        child: HangoutButton(
          label: _isHunger ? l10n.setupFindFood : l10n.setupFindPlaces,
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
