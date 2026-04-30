import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Filters the user can set before swiping places.
class SwipeFilters {
  final List<String> placeTypes; // Google place type strings; empty = mode default
  final int? maxPrice;           // 1-4, null = any
  final bool openNowOnly;
  final int radiusKm;            // 1-10

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
  (label: 'Desserts', types: ['dessert_shop', 'dessert_restaurant', 'bakery']),
  (label: 'Desserts', types: ['dessert_shop', 'ice_cream_shop', 'bakery']),
];

const List<_Option> _travelOptions = [
  (label: 'Museums', types: ['museum']),
  (label: 'Parks', types: ['park', 'national_park']),
  (label: 'Amusement', types: ['amusement_park', 'amusement_center']),
  (label: 'Art Galleries', types: ['art_gallery']),
  (label: 'Historic Sites', types: ['historical_landmark', 'monument']),
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
  Color get _accent => _isHunger ? const Color(0xFF1B6D01) : const Color(0xFF1E6BE6);
  List<_Option> get _options => _isHunger ? _hungerOptions : _travelOptions;

  @override
  void initState() {
    super.initState();
    _filters = widget.initial;
  }

  void _toggleOption(_Option opt) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedLabels.contains(opt.label)) {
        _selectedLabels.remove(opt.label);
      } else {
        _selectedLabels.add(opt.label);
      }
      final types = <String>{};
      for (final o in _options) {
        if (_selectedLabels.contains(o.label)) types.addAll(o.types);
      }
      _filters = _filters.copyWith(placeTypes: types.toList());
    });
  }

  void _setPrice(int? p) {
    HapticFeedback.selectionClick();
    setState(() => _filters = _filters.copyWith(maxPrice: p));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: const Text(
          'Swipe Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_filters),
            child: Text(
              'Done',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _sectionHeader(
            _isHunger ? 'Cuisine Types' : 'Categories',
            'Tap to filter — empty = show everything',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _options.map((opt) {
              final selected = _selectedLabels.contains(opt.label);
              return GestureDetector(
                onTap: () => _toggleOption(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _accent : const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: selected ? _accent : Colors.white12),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          _sectionHeader('Max Price', 'Ignore pricier places'),
          const SizedBox(height: 12),
          Row(
            children: [
              _priceChip(null, 'Any'),
              const SizedBox(width: 10),
              _priceChip(1, 'RS'),
              const SizedBox(width: 10),
              _priceChip(2, 'RS RS'),
              const SizedBox(width: 10),
              _priceChip(3, 'RS RS RS'),
              const SizedBox(width: 10),
              _priceChip(4, 'RS RS RS RS'),
            ],
          ),
          const SizedBox(height: 32),
          _sectionHeader('Open Now', 'Only show places currently open'),
          const SizedBox(height: 4),
          SwitchListTile(
            value: _filters.openNowOnly,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _filters = _filters.copyWith(openNowOnly: v));
            },
            activeColor: _accent,
            contentPadding: EdgeInsets.zero,
            title: Text(
              _filters.openNowOnly ? 'Open places only' : 'All places',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          _sectionHeader('Search Radius', '${_filters.radiusKm} km from your spot'),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _accent,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              overlayColor: _accent.withOpacity(0.2),
              valueIndicatorColor: _accent,
              valueIndicatorTextStyle:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            child: Slider(
              value: _filters.radiusKm.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${_filters.radiusKm} km',
              onChanged: (v) =>
                  setState(() => _filters = _filters.copyWith(radiusKm: v.round())),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 km', style: TextStyle(color: Colors.white38, fontSize: 12)),
              Text('10 km', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop(_filters);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              _isHunger ? 'Find Restaurants' : 'Find Places',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _priceChip(int? value, String label) {
    final selected = _filters.maxPrice == value;
    return GestureDetector(
      onTap: () => _setPrice(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _accent : const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _accent : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}