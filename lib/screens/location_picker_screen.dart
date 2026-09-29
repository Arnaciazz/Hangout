import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/hangout_button.dart';

/// Full-screen map where the user taps to drop a pin.
/// Returns a [LatLng] when the user confirms, or null if cancelled.
class LocationPickerScreen extends StatefulWidget {
  /// Initial center; defaults to Hyderabad if not provided.
  final LatLng? initialPosition;

  const LocationPickerScreen({super.key, this.initialPosition});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _picked;
  bool _locating = false;

  static const _defaultCenter = LatLng(17.385044, 78.486671); // Hyderabad

  LatLng get _initialCenter => widget.initialPosition ?? _defaultCenter;

  @override
  void initState() {
    super.initState();
    _goToCurrentLocation();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final current = LatLng(pos.latitude, pos.longitude);
      setState(() => _picked = current);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(current, 15),
      );
    } catch (_) {
      // Silently fall back to default center
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onTap(LatLng latLng) {
    HapticFeedback.lightImpact();
    setState(() => _picked = latLng);
  }

  void _confirm() {
    if (_picked != null) Navigator.of(context).pop(_picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCenter,
              zoom: 13,
            ),
            onMapCreated: (c) => _mapController = c,
            onTap: _onTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _picked == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('picked'),
                      position: _picked!,
                      infoWindow: const InfoWindow(title: 'Search here'),
                    ),
                  },
          ),

          // ── Top bar ───────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x3, vertical: AppSpacing.x2),
              child: Row(
                children: [
                  HangoutIconButton(
                    icon: Icons.arrow_back_rounded,
                    variant: HangoutIconButtonVariant.surface,
                    tooltip: 'Back',
                    size: 44,
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: AnimatedContainer(
                      duration: AppMotion.base,
                      curve: AppMotion.easeOut,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.x4, vertical: AppSpacing.x3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.pillAll,
                        border: Border.all(
                          color: _picked == null
                              ? AppColors.border
                              : AppColors.paprika200,
                        ),
                        boxShadow: AppShadows.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _picked == null
                                ? Icons.touch_app_outlined
                                : Icons.place_rounded,
                            size: 16,
                            color: _picked == null
                                ? AppColors.textFaint
                                : AppColors.brand,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _picked == null
                                  ? 'Tap the map to drop a pin'
                                  : '${_picked!.latitude.toStringAsFixed(4)}, '
                                      '${_picked!.longitude.toStringAsFixed(4)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _picked == null
                                  ? AppTextStyles.caption
                                  : AppTextStyles.captionStrong,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── My location ───────────────────────────────────────────────────
          Positioned(
            right: AppSpacing.gutter,
            bottom: 130,
            child: _locating
                ? Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.md,
                    ),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : HangoutIconButton(
                    icon: Icons.my_location_rounded,
                    variant: HangoutIconButtonVariant.surface,
                    tooltip: 'Use my location',
                    onPressed: _goToCurrentLocation,
                  ),
          ),

          // ── Confirm ───────────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter,
                    AppSpacing.x3, AppSpacing.gutter, AppSpacing.x4),
                child: HangoutButton(
                  label: 'Search around here',
                  size: HangoutButtonSize.lg,
                  block: true,
                  iconLeft: Icons.search_rounded,
                  onPressed: _picked != null ? _confirm : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
