import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';

/// Displays a Google map centered on the facility with an optional marker.
class ActivityMap extends StatefulWidget {
  final double? lat;
  final double? lng;
  final String title;
  const ActivityMap({super.key, required this.lat, required this.lng, required this.title});

  @override
  State<ActivityMap> createState() => _ActivityMapState();
}

class _ActivityMapState extends State<ActivityMap> {
  GoogleMapController? _controller;
  Position? _myPos;

  bool get _hasCoords => widget.lat != null && widget.lng != null;

  @override
  void initState() {
    super.initState();
    _loadMyPos();
  }

  Future<void> _loadMyPos() async {
    try {
      _myPos = await locationService.current();
      if (mounted) setState(() {});
    } catch (_) {
      // ignore errors – handled by UI when requesting permission elsewhere
    }
  }

  void _moveTo(LatLng target) {
    _controller?.animateCamera(CameraUpdate.newLatLng(target));
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCoords) {
      return const Center(child: Text('Location unavailable'));
    }

    final marker = Marker(
      markerId: const MarkerId('facility'),
      position: LatLng(widget.lat!, widget.lng!),
      infoWindow: InfoWindow(title: widget.title),
    );

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.lat!, widget.lng!),
            zoom: 15,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: {marker},
          onMapCreated: (c) => _controller = c,
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            children: [
              if (_myPos != null)
                FloatingActionButton(
                  heroTag: 'me',
                  mini: true,
                  onPressed: () => _moveTo(LatLng(_myPos!.latitude, _myPos!.longitude)),
                  child: const Icon(Icons.my_location),
                ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'facility',
                mini: true,
                onPressed: () => _moveTo(LatLng(widget.lat!, widget.lng!)),
                child: const Icon(Icons.place),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

