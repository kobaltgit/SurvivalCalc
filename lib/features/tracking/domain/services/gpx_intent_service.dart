import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/tracking/presentation/providers/planned_route_providers.dart';

class GpxIntentService {
  static const MethodChannel _channel =
      MethodChannel('com.survivalcalc.app/gpx_intent');

  static bool _initialized = false;

  /// Initializes listening for incoming GPX intents (Android only)
  static Future<void> init(WidgetRef ref, {void Function(String routeName)? onRouteImported}) async {
    if (kIsWeb) return;
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onGpxReceived') {
        final gpxString = call.arguments as String?;
        if (gpxString != null && gpxString.isNotEmpty) {
          await _handleGpx(ref, gpxString, onRouteImported);
        }
      }
    });

    try {
      final initialGpx = await _channel.invokeMethod<String>('getInitialGpx');
      if (initialGpx != null && initialGpx.isNotEmpty) {
        await _handleGpx(ref, initialGpx, onRouteImported);
      }
    } catch (_) {}
  }

  static Future<void> _handleGpx(
    WidgetRef ref,
    String gpxContent,
    void Function(String routeName)? onRouteImported,
  ) async {
    try {
      final route = await ref
          .read(plannedRouteProvider.notifier)
          .importFromGpx(gpxContent);

      final current = ref.read(activeTripProfileProvider);
      ref.read(activeTripProfileProvider.notifier).updateProfile(
            current.copyWith(
              title: route.name,
              totalDistanceKm: route.totalDistanceKm,
              totalAscentMeters: route.totalAscentMeters,
              plannedItinerary: const [],
            ),
          );

      onRouteImported?.call(route.name);
    } catch (e) {
      debugPrint('Error importing GPX from Intent: $e');
    }
  }
}
