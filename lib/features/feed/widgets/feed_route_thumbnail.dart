import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/colors.dart';
import '../../run/screens/widgets/run_summary_map_replay.dart';

class FeedRouteThumbnail extends StatelessWidget {
  const FeedRouteThumbnail({super.key, required this.route});

  final List<LatLng> route;

  static const _tiles =
      'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png';

  @override
  Widget build(BuildContext context) {
    if (route.length < 2) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.map_outlined,
          size: 40,
          color: AppColors.textSecondary.withValues(alpha: 0.5),
        ),
      );
    }
    final bounds = boundsForPoints(route);
    if (bounds == null) {
      return const SizedBox(height: 120);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 120,
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(10),
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: _tiles,
              userAgentPackageName: 'dev.fleaflet/flutter_map',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: route,
                  color: AppColors.primary,
                  strokeWidth: 4,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
