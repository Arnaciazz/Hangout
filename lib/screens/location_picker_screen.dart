import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) return;

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    elevation: 2,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: () => Navigator.of(context).pop(null),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      child: Text(
                        _picked == null
                            ? 'Tap the map to pick a spot'
                            : 'Lat ${_picked!.latitude.toStringAsFixed(4)}, '
                              'Lng ${_picked!.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _picked == null ? Colors.black45 : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── My location FAB ───────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 120,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 2,
              onPressed: _locating ? null : _goToCurrentLocation,
              child: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
            ),
          ),

          // ── Confirm button ────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: AnimatedOpacity(
                  opacity: _picked != null ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: ElevatedButton(
                    onPressed: _picked != null ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B6D01),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Search this area',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
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
