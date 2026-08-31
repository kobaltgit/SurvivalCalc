import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/tracking/data/repositories/track_storage_repository.dart';
import 'package:survival_calc/features/tracking/domain/models/camp_debrief.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/models/gps_point.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/tracking/domain/services/camp_debrief_calculator.dart';
import 'package:survival_calc/features/tracking/domain/services/distance_calculator.dart';

// Repositories & Services Providers
final trackStorageRepositoryProvider = Provider<TrackStorageRepository>((ref) {
  return TrackStorageRepository();
});

final distanceCalculatorProvider = Provider<DistanceCalculator>((ref) {
  return const DistanceCalculator();
});

final campDebriefCalculatorProvider = Provider<CampDebriefCalculator>((ref) {
  return const CampDebriefCalculator();
});

final completedTracksProvider =
    FutureProvider.autoDispose<List<DailyTrack>>((ref) async {
  final repo = ref.watch(trackStorageRepositoryProvider);
  return repo.getCompletedTracks();
});

// State for Live Tracking
enum TrackingStatus {
  idle,
  tracking,
  paused,
  stopped,
}

class TrackingState {
  final TrackingStatus status;
  final DailyTrack? activeTrack;
  final GpsPoint? currentPoint;
  final double liveSpeedKmh;
  final double maxSpeedKmh;
  final int totalElapsedSeconds;
  final int movingSeconds;
  final int pauseSeconds;
  final String? errorMessage;
  final bool hasLocationPermission;

  const TrackingState({
    this.status = TrackingStatus.idle,
    this.activeTrack,
    this.currentPoint,
    this.liveSpeedKmh = 0.0,
    this.maxSpeedKmh = 0.0,
    this.totalElapsedSeconds = 0,
    this.movingSeconds = 0,
    this.pauseSeconds = 0,
    this.errorMessage,
    this.hasLocationPermission = false,
  });

  bool get isRecording => status == TrackingStatus.tracking;
  bool get isPaused => status == TrackingStatus.paused;
  bool get isActive => isRecording || isPaused;

  TrackingState copyWith({
    TrackingStatus? status,
    DailyTrack? activeTrack,
    GpsPoint? currentPoint,
    double? liveSpeedKmh,
    double? maxSpeedKmh,
    int? totalElapsedSeconds,
    int? movingSeconds,
    int? pauseSeconds,
    String? errorMessage,
    bool? hasLocationPermission,
  }) {
    return TrackingState(
      status: status ?? this.status,
      activeTrack: activeTrack ?? this.activeTrack,
      currentPoint: currentPoint ?? this.currentPoint,
      liveSpeedKmh: liveSpeedKmh ?? this.liveSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
      movingSeconds: movingSeconds ?? this.movingSeconds,
      pauseSeconds: pauseSeconds ?? this.pauseSeconds,
      errorMessage: errorMessage,
      hasLocationPermission:
          hasLocationPermission ?? this.hasLocationPermission,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  final Ref ref;
  final DistanceCalculator _distanceCalculator;
  final TrackStorageRepository _repository;
  final CampDebriefCalculator _debriefCalculator;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;

  TrackingNotifier(this.ref)
      : _distanceCalculator = ref.read(distanceCalculatorProvider),
        _repository = ref.read(trackStorageRepositoryProvider),
        _debriefCalculator = ref.read(campDebriefCalculatorProvider),
        super(const TrackingState()) {
    _initRestore();
  }

  Future<void> _initRestore() async {
    final active = await _repository.getActiveTrack();
    if (active != null && !active.isCompleted) {
      state = state.copyWith(
        status: TrackingStatus.paused,
        activeTrack: active,
        movingSeconds: active.movingDurationSeconds,
        pauseSeconds: active.pauseDurationSeconds,
        totalElapsedSeconds:
            active.movingDurationSeconds + active.pauseDurationSeconds,
        maxSpeedKmh: active.maxSpeedKmh,
        currentPoint: active.points.isNotEmpty ? active.points.last : null,
      );
    }
  }

  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        errorMessage: 'Служба геолокации отключена в системе.',
        hasLocationPermission: false,
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(
          errorMessage: 'Доступ к GPS отклонен пользователем.',
          hasLocationPermission: false,
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        errorMessage:
            'Доступ к GPS заблокирован навсегда в настройках устройства.',
        hasLocationPermission: false,
      );
      return false;
    }

    state = state.copyWith(
      hasLocationPermission: true,
      errorMessage: null,
    );
    return true;
  }

  Future<GpsPoint?> fetchInitialLocation() async {
    final hasPerm = await checkAndRequestPermission();
    if (!hasPerm) return null;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final pt = GpsPoint(
        latitude: pos.latitude,
        longitude: pos.longitude,
        altitude: pos.altitude,
        timestamp: DateTime.now(),
        speedKmh: pos.speed > 0 ? pos.speed * 3.6 : 0.0,
        accuracy: pos.accuracy,
      );

      state = state.copyWith(currentPoint: pt, errorMessage: null);
      return pt;
    } catch (e) {
      try {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          final pt = GpsPoint(
            latitude: lastPos.latitude,
            longitude: lastPos.longitude,
            altitude: lastPos.altitude,
            timestamp: DateTime.now(),
            speedKmh: lastPos.speed > 0 ? lastPos.speed * 3.6 : 0.0,
            accuracy: lastPos.accuracy,
          );
          state = state.copyWith(currentPoint: pt, errorMessage: null);
          return pt;
        }
      } catch (_) {}
      state = state.copyWith(
        errorMessage: 'Поиск спутников GPS... (убедитесь, что GPS включен)',
      );
      return null;
    }
  }

  Future<void> startTracking({int dayIndex = 1, String? title}) async {
    final hasPerm = await checkAndRequestPermission();
    if (!hasPerm) return;

    final now = DateTime.now();
    final newTrack = DailyTrack(
      id: 'track_${now.millisecondsSinceEpoch}',
      dayIndex: dayIndex,
      title: title ?? 'Ходовой день $dayIndex',
      startTime: now,
    );

    state = state.copyWith(
      status: TrackingStatus.tracking,
      activeTrack: newTrack,
      totalElapsedSeconds: 0,
      movingSeconds: 0,
      pauseSeconds: 0,
      liveSpeedKmh: 0.0,
      maxSpeedKmh: 0.0,
      errorMessage: null,
    );

    _startTimer();
    _startPositionStream();
    await _repository.saveActiveTrack(newTrack);
  }

  void pauseTracking() {
    if (state.status != TrackingStatus.tracking) return;
    _positionSubscription?.pause();
    state = state.copyWith(
      status: TrackingStatus.paused,
      liveSpeedKmh: 0.0,
    );
    _syncActiveTrackToDisk();
  }

  void resumeTracking() {
    if (state.status != TrackingStatus.paused) return;
    _positionSubscription?.resume();
    state = state.copyWith(
      status: TrackingStatus.tracking,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == TrackingStatus.tracking) {
        final newMoving = state.movingSeconds + 1;
        final newTotal = state.totalElapsedSeconds + 1;
        state = state.copyWith(
          movingSeconds: newMoving,
          totalElapsedSeconds: newTotal,
        );
      } else if (state.status == TrackingStatus.paused) {
        final newPause = state.pauseSeconds + 1;
        final newTotal = state.totalElapsedSeconds + 1;
        state = state.copyWith(
          pauseSeconds: newPause,
          totalElapsedSeconds: newTotal,
        );
      }
    });
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // record every 5 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _onNewPosition(position);
      },
      onError: (error) {
        state = state.copyWith(errorMessage: 'Ошибка GPS: $error');
      },
    );
  }

  void _onNewPosition(Position pos) {
    if (state.status != TrackingStatus.tracking || state.activeTrack == null) {
      return;
    }

    final now = DateTime.now();
    final double speedKmh = (pos.speed > 0 ? pos.speed * 3.6 : 0.0);
    final double maxSpeed = mathMax(state.maxSpeedKmh, speedKmh);

    final newPoint = GpsPoint(
      latitude: pos.latitude,
      longitude: pos.longitude,
      altitude: pos.altitude,
      timestamp: now,
      speedKmh: speedKmh,
      accuracy: pos.accuracy,
    );

    final List<GpsPoint> updatedPoints = List.from(state.activeTrack!.points)
      ..add(newPoint);

    // Calculate updated distance and elevation
    final double distanceKm =
        _distanceCalculator.calculateTotalDistanceKm(updatedPoints);
    final elevation =
        _distanceCalculator.calculateElevationProfile(updatedPoints);

    final double avgMovingSpeedKmh = state.movingSeconds > 0
        ? (distanceKm / (state.movingSeconds / 3600.0))
        : 0.0;

    final updatedTrack = state.activeTrack!.copyWith(
      points: updatedPoints,
      totalDistanceKm: distanceKm,
      elevationGainMeters: elevation.gain,
      elevationLossMeters: elevation.loss,
      movingDurationSeconds: state.movingSeconds,
      pauseDurationSeconds: state.pauseSeconds,
      avgMovingSpeedKmh: avgMovingSpeedKmh,
      maxSpeedKmh: maxSpeed,
    );

    state = state.copyWith(
      activeTrack: updatedTrack,
      currentPoint: newPoint,
      liveSpeedKmh: speedKmh,
      maxSpeedKmh: maxSpeed,
    );

    // Debounce save to disk every 5 points
    if (updatedPoints.length % 5 == 0) {
      _syncActiveTrackToDisk();
    }
  }

  Future<void> addWaypoint({
    required String title,
    required WayPointType type,
    String? note,
  }) async {
    if (state.activeTrack == null) return;

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      // Use last point if available
    }

    final double lat = pos?.latitude ?? state.currentPoint?.latitude ?? 0.0;
    final double lng = pos?.longitude ?? state.currentPoint?.longitude ?? 0.0;
    final double alt = pos?.altitude ?? state.currentPoint?.altitude ?? 0.0;

    final wp = WayPoint(
      id: 'wp_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      note: note,
      type: type,
      latitude: lat,
      longitude: lng,
      altitude: alt,
      timestamp: DateTime.now(),
    );

    final updatedWaypoints = List<WayPoint>.from(state.activeTrack!.waypoints)
      ..add(wp);

    final updatedTrack =
        state.activeTrack!.copyWith(waypoints: updatedWaypoints);

    state = state.copyWith(activeTrack: updatedTrack);
    await _syncActiveTrackToDisk();
  }

  /// Stop tracking ("Встали на ночевку / Завершить день") and generate CampDebrief
  Future<CampDebrief?> stopAndFinishDay() async {
    _timer?.cancel();
    _positionSubscription?.cancel();

    if (state.activeTrack == null) {
      state = const TrackingState();
      return null;
    }

    final finalTrack = state.activeTrack!.copyWith(
      endTime: DateTime.now(),
      isCompleted: true,
      movingDurationSeconds: state.movingSeconds,
      pauseDurationSeconds: state.pauseSeconds,
    );

    // Save completed track to database / repository
    await _repository.saveCompletedTrack(finalTrack);
    await _repository.saveActiveTrack(null);
    ref.invalidate(completedTracksProvider);

    // Generate evening debrief
    final profile = ref.read(activeTripProfileProvider);
    final planResult = ref.read(calculationResultProvider);

    CampDebrief? debrief;
    if (planResult != null) {
      debrief = _debriefCalculator.generateDebrief(
        track: finalTrack,
        profile: profile,
        planResult: planResult,
      );
    }

    state = const TrackingState();
    return debrief;
  }

  Future<void> _syncActiveTrackToDisk() async {
    if (state.activeTrack != null) {
      final toSave = state.activeTrack!.copyWith(
        movingDurationSeconds: state.movingSeconds,
        pauseDurationSeconds: state.pauseSeconds,
      );
      await _repository.saveActiveTrack(toSave);
    }
  }

  double mathMax(double a, double b) => a > b ? a : b;

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final trackingProvider =
    StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier(ref);
});
