import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

/// Outdoorsy forest-green used as the Material 3 seed for both themes.
const Color _wildHorizonSeed = Color(0xFF386641);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  /// Allows descendants (Settings) to change theme mode at runtime.
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theme_mode_v1');
    final restored = ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
    if (!mounted || restored == _themeMode) {
      return;
    }
    setState(() => _themeMode = restored);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) {
      return;
    }
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode_v1', mode.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WildHorizon',
      theme: _buildAppTheme(Brightness.light),
      darkTheme: _buildAppTheme(Brightness.dark),
      themeMode: _themeMode,
      home: const HomeScreen(),
    );
  }
}

/// Material 3 theme tuned for a modern 2026 look: forest-green seed,
/// surface-tinted flat cards, generous rounding, and floating snackbars.
ThemeData _buildAppTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _wildHorizonSeed,
    brightness: brightness,
  );

  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 20,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: colorScheme.onInverseSurface,
        fontWeight: FontWeight.w500,
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: colorScheme.surfaceContainerHigh,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: colorScheme.onSurfaceVariant),
      ),
      height: 72,
      elevation: 0,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
    ),
  );
}

/// Meters from [p] to the closest point on segment [a]–[b] (planar equirectangular; fine for short OSM edges).
double _tapPointToSegmentMeters(LatLng p, LatLng a, LatLng b, Distance distance) {
  final segLen = distance.as(LengthUnit.Meter, a, b);
  if (segLen < 1.0) {
    return distance.as(LengthUnit.Meter, p, a);
  }
  final refLatRad = (a.latitude + b.latitude) * 0.5 * math.pi / 180;
  final cosR = math.cos(refLatRad);
  const scale = 6371000.0 * math.pi / 180.0;
  double x(LatLng ll) => cosR * ll.longitude * scale;
  double y(LatLng ll) => ll.latitude * scale;
  final ax = x(a), ay = y(a);
  final bx = x(b), by = y(b);
  final px = x(p), py = y(p);
  final abx = bx - ax, aby = by - ay;
  final apx = px - ax, apy = py - ay;
  final ab2 = abx * abx + aby * aby;
  if (ab2 < 1e-12) {
    return distance.as(LengthUnit.Meter, p, a);
  }
  final t = ((apx * abx + apy * aby) / ab2).clamp(0.0, 1.0);
  final cx = ax + t * abx;
  final cy = ay + t * aby;
  final cLat = cy / scale;
  final cLng = cx / (scale * cosR);
  return distance.as(LengthUnit.Meter, p, LatLng(cLat, cLng));
}

/// Shortest distance from [tapped] to the polyline. Vertex-only distance misses taps between nodes.
double _tapDistanceToPolylineMeters(
  LatLng tapped,
  List<LatLng> points,
  Distance distance,
) {
  if (points.isEmpty) {
    return double.infinity;
  }
  if (points.length == 1) {
    return distance.as(LengthUnit.Meter, tapped, points[0]);
  }
  var best = double.infinity;
  for (var i = 0; i < points.length - 1; i++) {
    final d = _tapPointToSegmentMeters(tapped, points[i], points[i + 1], distance);
    if (d < best) {
      best = d;
    }
  }
  return best;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final _riderNameController = TextEditingController();
  final _riderBikeController = TextEditingController();

  int _navIndex = 0;
  List<RideEntry> _rides = [];

  String _areaName = 'Fremont Older Preserve, Bay Area';
  double _radiusMiles = 50;
  LatLng _mapCenter = const LatLng(37.2606, -122.0890);
  double _mapZoom = 10.5;
  bool _isLoadingTrails = false;
  String? _trailError;
  List<TrailData> _trails = [];
  int? _selectedTrailId;

  StreamSubscription<Position>? _trailCompletionSubscription;
  TrailData? _trailCompletionTarget;
  bool _trailCompletionReachedStart = false;
  DateTime? _trailCompletionStartAt;
  bool _trailCompletionSaved = false;
  double get _radiusMeters => _radiusMiles * 1609.34;
  final Distance _distance = const Distance();
  Timer? _mapViewSaveTimer;

  /// Owns all live-recording state and the GPS subscription. The recording
  /// UI lives in [_RecordingScreen]; this state is shared so the home screen
  /// can also react if needed.
  final _RecordingSession _recordingSession = _RecordingSession();

  /// Saved ride whose recorded track is currently highlighted on the map.
  RideEntry? _focusedRecordedRide;

  /// User's preferred display units. Metric by default; toggled from
  /// Settings → Units. Persisted under `units_v1`.
  UnitSystem _units = UnitSystem.metric;

  /// Cached current conditions for the most recently visited area.
  WeatherSnapshot? _weather;

  /// Cached 3-day daily forecast aligned with [_weather].
  List<WeatherDayForecast> _forecast = [];
  bool _isLoadingWeather = false;

  /// User-pinned weather location. When `null`, weather follows the map
  /// center. Set via the weather sheet's "Change location" picker.
  WeatherLocation? _pinnedWeatherLocation;

  /// Map of achievement-id → first-unlock timestamp. Restored on launch
  /// from `achievements_v1`. Used to drive the badge grid and to compute
  /// newly-unlocked diffs after saving a ride.
  Map<String, DateTime> _achievementUnlocks = {};

  @override
  void initState() {
    super.initState();
    _recordingSession.addListener(_onRecordingChange);
    _loadLocalData();
  }

  @override
  void dispose() {
    _mapViewSaveTimer?.cancel();
    unawaited(_persistMapView());
    _trailCompletionSubscription?.cancel();
    _recordingSession.removeListener(_onRecordingChange);
    _recordingSession.dispose();
    _riderNameController.dispose();
    _riderBikeController.dispose();
    super.dispose();
  }

  void _onRecordingChange() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    _riderNameController.text = prefs.getString('rider_name') ?? '';
    _riderBikeController.text = prefs.getString('rider_bike') ?? '';
    _units = UnitSystem.fromName(prefs.getString('units_v1'));

    final raw = prefs.getString('rides_v1');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _rides = decoded
            .map((e) => RideEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _rides = [];
      }
    }

    var restoredMap = false;
    final mapLat = double.tryParse(prefs.getString('map_center_lat') ?? '');
    final mapLng = double.tryParse(prefs.getString('map_center_lng') ?? '');
    final mapZoom = double.tryParse(prefs.getString('map_zoom') ?? '');
    if (mapLat != null && mapLng != null && mapZoom != null) {
      _mapCenter = LatLng(mapLat, mapLng);
      _mapZoom = mapZoom.clamp(3.0, 18.0);
      restoredMap = true;
    }

    _restoreCachedWeather(prefs);
    _restoreCachedAchievements(prefs);

    setState(() {});

    if (restoredMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _mapController.move(_mapCenter, _mapZoom);
      });
    }

    unawaited(_loadWeather());
  }

  Future<void> _persistMapView() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('map_center_lat', _mapCenter.latitude.toString());
    await prefs.setString('map_center_lng', _mapCenter.longitude.toString());
    await prefs.setString('map_zoom', _mapZoom.toString());
  }

  void _schedulePersistMapView() {
    _mapViewSaveTimer?.cancel();
    _mapViewSaveTimer = Timer(const Duration(milliseconds: 900), () {
      unawaited(_persistMapView());
    });
  }

  void _focusRecordedRideOnMap(RideEntry ride) {
    if (ride.track.length < 2) {
      return;
    }
    setState(() {
      _navIndex = 2;
      _focusedRecordedRide = ride;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      try {
        final bounds = LatLngBounds.fromPoints(ride.track);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(40),
            maxZoom: 17,
          ),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          final cam = _mapController.camera;
          setState(() {
            _mapCenter = cam.center;
            _mapZoom = cam.zoom;
          });
          _schedulePersistMapView();
        });
      } catch (_) {
        final mid = ride.track[ride.track.length ~/ 2];
        _mapController.move(mid, 14);
        setState(() {
          _mapCenter = mid;
          _mapZoom = 14;
        });
        _schedulePersistMapView();
      }
    });
  }

  void _focusTrailOnMap(TrailData trail) {
    if (trail.points.isEmpty) {
      return;
    }
    setState(() {
      _selectedTrailId = trail.osmId;
    });
    if (trail.points.length == 1) {
      final p = trail.points.first;
      _mapController.move(p, 15);
      setState(() {
        _mapCenter = p;
        _mapZoom = 15;
      });
      _schedulePersistMapView();
      return;
    }
    try {
      final bounds = LatLngBounds.fromPoints(trail.points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(40),
          maxZoom: 17,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final cam = _mapController.camera;
        setState(() {
          _mapCenter = cam.center;
          _mapZoom = cam.zoom;
        });
        _schedulePersistMapView();
      });
    } catch (_) {
      final mid = trail.points[trail.points.length ~/ 2];
      _mapController.move(mid, 14);
      setState(() {
        _mapCenter = mid;
        _mapZoom = 14;
      });
      _schedulePersistMapView();
    }
  }

  Future<void> _showBrowseTrailsSheet() async {
    if (_trails.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No trails loaded yet — pan to your area and tap refresh.',
          ),
        ),
      );
      return;
    }

    final searchController = TextEditingController();

    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.52,
          minChildSize: 0.28,
          maxChildSize: 0.92,
          builder: (dragContext, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final q = searchController.text.trim().toLowerCase();
                final sorted = [..._trails]..sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );
                final filtered = q.isEmpty
                    ? sorted
                    : sorted
                          .where((t) => t.name.toLowerCase().contains(q))
                          .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        'Browse trails',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search by name',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setModalState(() {}),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No trails match “${searchController.text.trim()}”.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final trail = filtered[index];
                                final tier = _trailDifficultyTier(trail);
                                return ListTile(
                                  title: Text(trail.name),
                                  subtitle: Text(
                                    '${trail.lengthKm.toStringAsFixed(1)} km · '
                                    '${_trailDifficultyLabel(tier)}',
                                  ),
                                  onTap: () {
                                    Navigator.of(sheetContext).pop();
                                    _focusTrailOnMap(trail);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
    searchController.dispose();
  }

  void _tryFocusTrailFromSearchQuery(String raw) {
    final q = raw.trim().toLowerCase();
    if (q.isEmpty) {
      return;
    }
    if (_trails.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Load trails first — tap refresh on the map.'),
        ),
      );
      return;
    }

    TrailData? exact;
    for (final t in _trails) {
      if (t.name.toLowerCase() == q) {
        exact = t;
        break;
      }
    }
    if (exact != null) {
      _focusTrailOnMap(exact);
      return;
    }

    final partial = _trails
        .where((t) => t.name.toLowerCase().contains(q))
        .toList();
    if (partial.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No trail matches “$raw”.')),
      );
      return;
    }
    partial.sort((a, b) {
      final byLen = a.name.length.compareTo(b.name.length);
      if (byLen != 0) {
        return byLen;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    _focusTrailOnMap(partial.first);
    if (partial.length > 1 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${partial.length} trails match — opened the shortest name. '
            'Use suggestions or Browse trails to pick another.',
          ),
        ),
      );
    }
  }

  Future<void> _persistRides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'rides_v1',
      jsonEncode(_rides.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> _saveRiderProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rider_name', _riderNameController.text.trim());
    await prefs.setString('rider_bike', _riderBikeController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Rider profile saved')));
  }

  Future<void> _setUnits(UnitSystem units) async {
    if (units == _units) {
      return;
    }
    setState(() {
      _units = units;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('units_v1', units.persistName);
  }

  void _addRide(RideEntry ride) {
    setState(() {
      _rides.insert(0, ride);
    });
    _persistRides();
    _checkForNewAchievements();
  }

  void _removeRideAt(int index) {
    setState(() {
      _rides.removeAt(index);
    });
    _persistRides();
  }

  static const double _trailNearStartEndMeters = 95;
  static const int _trailVertexSample = 28;

  double _minDistanceMetersToAny(LatLng p, Iterable<LatLng> points) {
    var best = double.infinity;
    for (final q in points) {
      final d = _distance.as(LengthUnit.Meter, p, q);
      if (d < best) {
        best = d;
      }
    }
    return best;
  }

  bool _trailFormsShortLoop(TrailData trail) {
    if (trail.points.length < 8) {
      return false;
    }
    return _distance.as(
          LengthUnit.Meter,
          trail.points.first,
          trail.points.last,
        ) <=
        85;
  }

  Iterable<LatLng> _firstTrailSample(TrailData trail) {
    final n = math.min(_trailVertexSample, trail.points.length);
    return trail.points.take(n);
  }

  Iterable<LatLng> _lastTrailSample(TrailData trail) {
    final n = math.min(_trailVertexSample, trail.points.length);
    return trail.points.sublist(trail.points.length - n);
  }

  Future<void> _beginTrailCompletionTracking(TrailData trail) async {
    final old = _trailCompletionSubscription;
    _trailCompletionSubscription = null;
    await old?.cancel();

    if (!mounted) {
      return;
    }
    final servicesOn = await Geolocator.isLocationServiceEnabled();
    if (!servicesOn) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Turn on location services to auto-save when you finish the trail.',
          ),
        ),
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission is needed to detect trail start and finish.',
          ),
        ),
      );
      return;
    }

    _trailCompletionSaved = false;
    _trailCompletionReachedStart = false;
    _trailCompletionStartAt = null;
    setState(() {
      _trailCompletionTarget = trail;
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );
    _trailCompletionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(_handleTrailCompletionPosition, onError: (_) {});
  }

  void _handleTrailCompletionPosition(Position position) {
    if (!mounted || _trailCompletionSaved) {
      return;
    }
    final target = _trailCompletionTarget;
    if (target == null) {
      return;
    }

    final here = LatLng(position.latitude, position.longitude);
    final loop = _trailFormsShortLoop(target);

    if (!_trailCompletionReachedStart) {
      if (_minDistanceMetersToAny(here, _firstTrailSample(target)) <=
          _trailNearStartEndMeters) {
        _trailCompletionReachedStart = true;
        _trailCompletionStartAt = DateTime.now();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Start reached — head to the end of "${target.name}" to save your ride.',
            ),
          ),
        );
      }
      return;
    }

    final startedAt = _trailCompletionStartAt;
    if (startedAt == null) {
      return;
    }
    final minSeconds = loop ? 95 : 28;
    if (DateTime.now().difference(startedAt).inSeconds < minSeconds) {
      return;
    }

    if (_minDistanceMetersToAny(here, _lastTrailSample(target)) <=
        _trailNearStartEndMeters) {
      _trailCompletionSaved = true;
      _trailCompletionSubscription?.cancel();
      _trailCompletionSubscription = null;
      final completed = target;
      setState(() {
        _trailCompletionTarget = null;
        _trailCompletionReachedStart = false;
        _trailCompletionStartAt = null;
      });
      _addRide(
        RideEntry(
          name: completed.name,
          notes:
              'Finished trail (auto-saved). ${_trailDifficultyDisplayLabel(completed)} · '
              '${completed.lengthKm.toStringAsFixed(2)} km · ${completed.highwayType}',
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _navIndex = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "${completed.name}" to Rides')),
      );
    }
  }

  void _cancelTrailCompletionTracking() {
    _trailCompletionSubscription?.cancel();
    _trailCompletionSubscription = null;
    setState(() {
      _trailCompletionTarget = null;
      _trailCompletionReachedStart = false;
      _trailCompletionStartAt = null;
      _trailCompletionSaved = false;
    });
  }

  /// Opens the dedicated recording screen. The screen owns the session
  /// lifecycle (start on init, stop on the Stop button). When the user
  /// stops with a non-trivial ride, the returned [RecordingResult] is
  /// handed off to the save-sheet flow.
  Future<void> _openRecordingScreen() async {
    final stats = await Navigator.of(context).push<RecordingResult?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _RecordingScreen(
          session: _recordingSession,
          initialCenter: _mapCenter,
          initialZoom: _mapZoom < 14 ? 14 : _mapZoom,
          units: _units,
        ),
      ),
    );
    if (stats == null || !mounted) {
      return;
    }
    await _saveRecordedRide(stats);
  }

  Future<void> _saveRecordedRide(RecordingResult stats) async {
    if (stats.track.length < 2 || stats.distanceMeters < 5) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ride was too short to save. Try again with location moving.',
          ),
        ),
      );
      return;
    }

    final defaultName = _defaultRideName(stats.startedAt);
    final saved = await _showSaveRideSheet(
      defaultName: defaultName,
      distanceMeters: stats.distanceMeters,
      durationSeconds: stats.durationSeconds,
      elevationGainMeters: stats.elevationGainMeters,
      avgSpeedMps: stats.avgSpeedMps,
      maxSpeedMps: stats.maxSpeedMps,
    );
    if (saved == null || !mounted) {
      return;
    }

    final entry = RideEntry(
      name: saved.name,
      notes: saved.notes,
      createdAt: stats.startedAt,
      track: stats.track,
      distanceMeters: stats.distanceMeters,
      durationSeconds: stats.durationSeconds,
      elevationGainMeters: stats.elevationGainMeters > 0
          ? stats.elevationGainMeters
          : null,
      avgSpeedMps: stats.avgSpeedMps > 0 ? stats.avgSpeedMps : null,
      maxSpeedMps: stats.maxSpeedMps > 0 ? stats.maxSpeedMps : null,
    );
    _addRide(entry);

    setState(() {
      _navIndex = 1;
    });
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "${saved.name}" to Rides'),
        action: entry.hasRecordedTrack
            ? SnackBarAction(
                label: 'Share',
                onPressed: () => _openRideShareCard(entry),
              )
            : null,
      ),
    );
  }

  String _defaultRideName(DateTime t) {
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return 'Ride $m/$d $hh:$mm';
  }

  Future<({String name, String notes})?> _showSaveRideSheet({
    required String defaultName,
    required double distanceMeters,
    required int durationSeconds,
    required double elevationGainMeters,
    required double avgSpeedMps,
    required double maxSpeedMps,
  }) async {
    final nameController = TextEditingController(text: defaultName);
    final notesController = TextEditingController();
    final distLabel = _formatDistance(distanceMeters, _units);
    final durLabel = _formatDurationSeconds(durationSeconds);
    final showElevation = elevationGainMeters >= 1;
    final elevLabel = _formatElevationGain(elevationGainMeters, _units);
    final showAvgSpeed = avgSpeedMps > 0.1;
    final showMaxSpeed = maxSpeedMps > 0.1;
    final avgLabel = 'Avg ${_formatSpeed(avgSpeedMps, _units)}';
    final maxLabel = 'Max ${_formatSpeed(maxSpeedMps, _units)}';

    final result = await showModalBottomSheet<({String name, String notes})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final insets = MediaQuery.of(sheetContext).viewInsets;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + insets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Save your ride',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.straighten, size: 16),
                    label: Text(distLabel),
                  ),
                  Chip(
                    avatar: const Icon(Icons.timer_outlined, size: 16),
                    label: Text(durLabel),
                  ),
                  if (showElevation)
                    Chip(
                      avatar: const Icon(Icons.terrain, size: 16),
                      label: Text(elevLabel),
                    ),
                  if (showAvgSpeed)
                    Chip(
                      avatar: const Icon(Icons.speed, size: 16),
                      label: Text(avgLabel),
                    ),
                  if (showMaxSpeed)
                    Chip(
                      avatar: const Icon(Icons.bolt, size: 16),
                      label: Text(maxLabel),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Ride name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Discard'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final name = nameController.text.trim().isEmpty
                            ? defaultName
                            : nameController.text.trim();
                        Navigator.of(sheetContext).pop(
                          (name: name, notes: notesController.text.trim()),
                        );
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save ride'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    nameController.dispose();
    notesController.dispose();
    return result;
  }

  void _zoomIn() {
    final nextZoom = (_mapZoom + 1).clamp(3.0, 18.0);
    _mapController.move(_mapCenter, nextZoom);
    setState(() {
      _mapZoom = nextZoom;
    });
  }

  void _zoomOut() {
    final nextZoom = (_mapZoom - 1).clamp(3.0, 18.0);
    _mapController.move(_mapCenter, nextZoom);
    setState(() {
      _mapZoom = nextZoom;
    });
  }

  void _onMapTap(TapPosition _, LatLng tappedPoint) {
    if (_trails.isEmpty) {
      return;
    }

    // Zoom-scaled hit width, with a floor so mid-segment taps still register at high zoom.
    final thresholdMeters = math.max(150000 / math.pow(2, _mapZoom), 14.0);
    TrailData? closestTrail;
    var closestDistance = double.infinity;

    for (final trail in _trails) {
      final meters = _tapDistanceToPolylineMeters(tappedPoint, trail.points, _distance);
      if (meters < closestDistance) {
        closestDistance = meters;
        closestTrail = trail;
      }
    }

    if (closestTrail != null && closestDistance <= thresholdMeters) {
      setState(() {
        _selectedTrailId = closestTrail!.osmId;
      });
      _showTrailDetails(closestTrail);
    }
  }

  void _showTrailDetails(TrailData trail) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                trail.name,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Track & auto-save: go near the trail start, then the finish. '
                'Your ride is saved automatically when you reach the end. '
                'Loops need a bit more time between start and finish.',
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('${trail.lengthKm.toStringAsFixed(2)} km')),
                  Chip(label: Text('Type: ${trail.highwayType}')),
                  if (trail.surface != null)
                    Chip(label: Text('Surface: ${trail.surface}')),
                  Chip(
                    avatar: const Icon(Icons.terrain, size: 18),
                    label: Text(
                      _trailDifficultyDisplayLabel(trail),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _beginTrailCompletionTracking(trail);
                },
                icon: const Icon(Icons.route_outlined),
                label: const Text('Track & auto-save at finish'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.of(sheetContext).pop();
                  _addRide(
                    RideEntry(
                      name: trail.name,
                      notes:
                          '${_trailDifficultyDisplayLabel(trail)} · '
                          '${trail.lengthKm.toStringAsFixed(2)} km · ${trail.highwayType}',
                    ),
                  );
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Added to Rides')),
                  );
                },
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Add to my rides now'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddRideDialog() async {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    final result = await showDialog<RideEntry>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add ride'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Ride name',
                    hintText: 'Example: Sunset Loop',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Conditions, who you rode with, bike setup…',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  RideEntry(name: name, notes: notesController.text.trim()),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    nameController.dispose();
    notesController.dispose();

    if (result != null) {
      _addRide(result);
    }
  }


  void _restoreCachedAchievements(SharedPreferences prefs) {
    final raw = prefs.getString('achievements_v1');
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _achievementUnlocks = decoded.map(
        (id, value) => MapEntry(id, DateTime.parse(value as String)),
      );
    } catch (_) {
      _achievementUnlocks = {};
    }
  }

  Future<void> _persistAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _achievementUnlocks.map(
      (id, when) => MapEntry(id, when.toIso8601String()),
    );
    await prefs.setString('achievements_v1', jsonEncode(encoded));
  }

  /// Re-evaluate every badge against the current ride list. Anything new
  /// is recorded with the current timestamp and surfaced via a celebration
  /// snackbar.
  void _checkForNewAchievements() {
    final newlyUnlocked = <Achievement>[];
    final now = DateTime.now();
    for (final a in kAchievements) {
      if (a.isUnlocked(_rides) && !_achievementUnlocks.containsKey(a.id)) {
        _achievementUnlocks[a.id] = now;
        newlyUnlocked.add(a);
      }
    }
    if (newlyUnlocked.isNotEmpty) {
      unawaited(_persistAchievements());
      _celebrateUnlocks(newlyUnlocked);
    }
  }

  void _celebrateUnlocks(List<Achievement> unlocked) {
    if (!mounted || unlocked.isEmpty) return;
    final first = unlocked.first;
    final extra = unlocked.length - 1;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: first.color.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: first.color.withValues(alpha: 0.6),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(first.icon, color: first.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    extra == 0
                        ? 'Achievement unlocked'
                        : '$extra more unlocked',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    first.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: _openAchievementsScreen,
        ),
      ),
    );
  }

  /// Returns up to [n] achievements ordered by most-recent unlock first.
  /// Used by the Rides-tab header card to show the latest 3 badges.
  List<Achievement> _recentlyUnlockedBadges(int n) {
    final entries = _achievementUnlocks.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final result = <Achievement>[];
    for (final e in entries) {
      final match = kAchievements.firstWhere(
        (a) => a.id == e.key,
        orElse: () => kAchievements.first,
      );
      if (match.id != e.key) continue;
      result.add(match);
      if (result.length >= n) break;
    }
    return result;
  }

  void _openAchievementsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AchievementsScreen(
          rides: _rides,
          unlocks: Map.of(_achievementUnlocks),
        ),
      ),
    );
  }

  /// Open the shareable summary card for a recorded ride. Auto-fills the
  /// achievements row with whatever the ride has unlocked overall (best
  /// effort: we don't yet diff per-ride, so we show every current unlock
  /// the ride contributes to).
  void _openRideShareCard(RideEntry ride) {
    final relevantAchievements = kAchievements
        .where((a) => _achievementUnlocks.containsKey(a.id))
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _RideShareScreen(
          ride: ride,
          units: _units,
          unlockedAchievements: relevantAchievements,
        ),
      ),
    );
  }

  /// The effective lat/lon used for weather lookups: the user's pinned
  /// location if set, otherwise the current map center.
  LatLng get _effectiveWeatherLatLng {
    final pin = _pinnedWeatherLocation;
    return pin != null ? LatLng(pin.latitude, pin.longitude) : _mapCenter;
  }

  /// Open-Meteo gives current conditions + a 3-day daily forecast for the
  /// active weather location (pinned city OR map center). Stored in
  /// metric and converted at render time. We cache the latest response so
  /// the chip shows instantly on next launch.
  Future<void> _loadWeather({bool force = false}) async {
    if (_isLoadingWeather) {
      return;
    }
    final center = _effectiveWeatherLatLng;
    final pinName = _pinnedWeatherLocation?.shortName;
    final existing = _weather;
    if (!force && existing != null) {
      final age = DateTime.now().difference(existing.fetchedAt);
      final dKm = _distance.as(
        LengthUnit.Kilometer,
        LatLng(existing.latitude, existing.longitude),
        center,
      );
      final sameLabel = existing.placeName == pinName;
      if (age < const Duration(minutes: 30) && dKm < 5 && sameLabel) {
        return;
      }
    }

    setState(() {
      _isLoadingWeather = true;
    });

    final lat = center.latitude.toStringAsFixed(4);
    final lon = center.longitude.toStringAsFixed(4);
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,'
      'is_day,precipitation,weather_code,wind_speed_10m,wind_direction_10m'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,'
      'precipitation_sum,wind_speed_10m_max'
      '&timezone=auto&forecast_days=3',
    );

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final current = body['current'] as Map<String, dynamic>;
      final daily = body['daily'] as Map<String, dynamic>;

      final snapshot = WeatherSnapshot(
        tempC: (current['temperature_2m'] as num).toDouble(),
        feelsLikeC: (current['apparent_temperature'] as num).toDouble(),
        weatherCode: (current['weather_code'] as num).toInt(),
        isDay: ((current['is_day'] as num).toInt()) == 1,
        windSpeedKmh: (current['wind_speed_10m'] as num).toDouble(),
        windDirectionDeg: (current['wind_direction_10m'] as num).toDouble(),
        humidityPct: (current['relative_humidity_2m'] as num).toInt(),
        precipitationMm: (current['precipitation'] as num).toDouble(),
        latitude: center.latitude,
        longitude: center.longitude,
        fetchedAt: DateTime.now(),
        placeName: pinName,
      );

      final times = (daily['time'] as List).cast<String>();
      final codes = (daily['weather_code'] as List).cast<num>();
      final tmax = (daily['temperature_2m_max'] as List).cast<num>();
      final tmin = (daily['temperature_2m_min'] as List).cast<num>();
      final precip = (daily['precipitation_sum'] as List).cast<num>();
      final wind = (daily['wind_speed_10m_max'] as List).cast<num>();

      final forecast = <WeatherDayForecast>[];
      for (var i = 0; i < times.length; i++) {
        forecast.add(
          WeatherDayForecast(
            date: DateTime.parse(times[i]),
            weatherCode: codes[i].toInt(),
            tempMaxC: tmax[i].toDouble(),
            tempMinC: tmin[i].toDouble(),
            precipitationMm: precip[i].toDouble(),
            windMaxKmh: wind[i].toDouble(),
          ),
        );
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _weather = snapshot;
        _forecast = forecast;
        _isLoadingWeather = false;
      });
      unawaited(_persistWeather());
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _persistWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final w = _weather;
    if (w == null) {
      await prefs.remove('weather_v1');
      await prefs.remove('forecast_v1');
      return;
    }
    await prefs.setString('weather_v1', jsonEncode(w.toJson()));
    await prefs.setString(
      'forecast_v1',
      jsonEncode(_forecast.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> _persistPinnedWeatherLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = _pinnedWeatherLocation;
    if (pin == null) {
      await prefs.remove('weather_location_v1');
    } else {
      await prefs.setString(
        'weather_location_v1',
        jsonEncode(pin.toJson()),
      );
    }
  }

  void _restoreCachedWeather(SharedPreferences prefs) {
    final pinRaw = prefs.getString('weather_location_v1');
    if (pinRaw != null && pinRaw.isNotEmpty) {
      try {
        _pinnedWeatherLocation = WeatherLocation.fromJson(
          jsonDecode(pinRaw) as Map<String, dynamic>,
        );
      } catch (_) {
        _pinnedWeatherLocation = null;
      }
    }

    final wRaw = prefs.getString('weather_v1');
    if (wRaw == null || wRaw.isEmpty) {
      return;
    }
    try {
      _weather = WeatherSnapshot.fromJson(
        jsonDecode(wRaw) as Map<String, dynamic>,
      );
      final fRaw = prefs.getString('forecast_v1');
      if (fRaw != null && fRaw.isNotEmpty) {
        final list = jsonDecode(fRaw) as List<dynamic>;
        _forecast = list
            .map(
              (e) => WeatherDayForecast.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (_) {
      _weather = null;
      _forecast = [];
    }
  }

  /// Switch to a different weather location (or pass `null` to go back to
  /// "follow map"). Persists the choice and immediately refetches.
  Future<void> _setWeatherLocation(WeatherLocation? location) async {
    setState(() {
      _pinnedWeatherLocation = location;
    });
    await _persistPinnedWeatherLocation();
    await _loadWeather(force: true);
  }

  /// Snap the weather location to the device's current GPS coordinates.
  /// Requests permission with graceful failure (snackbar on error).
  Future<void> _useGpsForWeatherLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied'),
          ),
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 8),
      );
      await _setWeatherLocation(
        WeatherLocation(
          name: 'My location',
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get GPS: $e')),
      );
    }
  }

  /// Calls Open-Meteo's geocoding API for autocomplete results. Returns
  /// up to 8 matches; empty list on any failure so the UI can render an
  /// empty state without surfacing errors.
  Future<List<WeatherLocation>> _searchWeatherPlaces(String query) async {
    if (query.trim().isEmpty) return const [];
    final uri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?name=${Uri.encodeQueryComponent(query.trim())}'
      '&count=8&language=en&format=json',
    );
    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 6),
      );
      if (response.statusCode != 200) return const [];
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results = body['results'] as List<dynamic>?;
      if (results == null) return const [];
      return results.map((r) {
        final m = r as Map<String, dynamic>;
        return WeatherLocation(
          name: (m['name'] as String?) ?? 'Unknown',
          latitude: (m['latitude'] as num).toDouble(),
          longitude: (m['longitude'] as num).toDouble(),
          country: m['country'] as String?,
          admin: m['admin1'] as String?,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Opens the location picker (search / GPS / follow-map). Reopens the
  /// weather sheet afterward so the user sees the updated conditions.
  void _showWeatherLocationPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _WeatherLocationPickerSheet(
          currentPin: _pinnedWeatherLocation,
          onSearch: _searchWeatherPlaces,
          onPick: (loc) async {
            await _setWeatherLocation(loc);
            if (!mounted) return;
            _showWeatherSheet();
          },
          onUseGps: () async {
            await _useGpsForWeatherLocation();
            if (!mounted) return;
            _showWeatherSheet();
          },
          onFollowMap: () async {
            await _setWeatherLocation(null);
            if (!mounted) return;
            _showWeatherSheet();
          },
        );
      },
    );
  }

  /// Detailed weather panel: hero card with current conditions + a row of
  /// upcoming days. Includes a pull-to-refresh equivalent (manual button).
  void _showWeatherSheet() {
    final snapshot = _weather;
    if (snapshot == null) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final gradient = weatherGradientFor(
          snapshot.weatherCode,
          isDay: snapshot.isDay,
        );
        final icon = weatherIconFor(
          snapshot.weatherCode,
          isDay: snapshot.isDay,
        );
        final label = weatherLabelFor(snapshot.weatherCode);
        final mediaPadding = MediaQuery.of(sheetContext).padding.bottom;

        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              _showWeatherLocationPicker();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.place,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      snapshot.placeName ?? 'Map view',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(icon, color: Colors.white, size: 56),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatTemperature(
                                      snapshot.tempC,
                                      _units,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 44,
                                      fontWeight: FontWeight.w800,
                                      height: 1.0,
                                      letterSpacing: -1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  Text(
                                    'Feels like '
                                    '${_formatTemperature(snapshot.feelsLikeC, _units)}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Refresh',
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                              onPressed: _isLoadingWeather
                                  ? null
                                  : () async {
                                      await _loadWeather(force: true);
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _WeatherStat(
                              icon: Icons.air,
                              label: 'Wind',
                              value: _formatWind(
                                snapshot.windSpeedKmh,
                                _units,
                              ),
                            ),
                            _WeatherStat(
                              icon: Icons.water_drop_outlined,
                              label: 'Humidity',
                              value: '${snapshot.humidityPct}%',
                            ),
                            _WeatherStat(
                              icon: Icons.umbrella_outlined,
                              label: 'Precip',
                              value:
                                  '${snapshot.precipitationMm.toStringAsFixed(1)} mm',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_forecast.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        16 + mediaPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEXT ${_forecast.length} DAYS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              for (final day in _forecast)
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: day == _forecast.last ? 0 : 8,
                                    ),
                                    child: _ForecastDayCard(
                                      day: day,
                                      units: _units,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Updated '
                            '${_formatRelativeTime(snapshot.fetchedAt)} · '
                            'Open-Meteo',
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadTrails() async {
    setState(() {
      _isLoadingTrails = true;
      _trailError = null;
    });

    final bounds = _mapController.camera.visibleBounds;
    final hasBounds =
        bounds.northWest.latitude != bounds.southEast.latitude &&
        bounds.northWest.longitude != bounds.southEast.longitude;
    // When bbox is unavailable, Overpass `around:` — cap to stay within API limits.
    final cappedRadiusMeters = _radiusMeters
        .clamp(1000, 100000)
        .toStringAsFixed(0);

    final spatial = hasBounds
        ? '(${bounds.south.toStringAsFixed(6)},${bounds.west.toStringAsFixed(6)},${bounds.north.toStringAsFixed(6)},${bounds.east.toStringAsFixed(6)})'
        : '(around:$cappedRadiusMeters,${_mapCenter.latitude.toStringAsFixed(6)},${_mapCenter.longitude.toStringAsFixed(6)})';

    // Only ways that are explicitly for bikes / MTB in OSM (not generic paths).
    final query =
        '''
[out:json][timeout:25];
(
  way["highway"="cycleway"]$spatial;
  way["highway"~"path|track"]["bicycle"~"yes|designated|permissive"]$spatial;
  way["highway"~"path|track"]["mtb"~"yes|designated|allowed|official"]$spatial;
  way["highway"~"path|track"]["mtb:scale"]["bicycle"!~"no"]$spatial;
);
out geom;
''';

    try {
      final trails = await _loadFromOverpass(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _trails = trails;
        _trailError = null;
        if (_selectedTrailId != null &&
            !_trails.any((trail) => trail.osmId == _selectedTrailId)) {
          _selectedTrailId = null;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _trailError =
            'Could not load trails. Check your network and tap refresh.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTrails = false;
        });
      }
    }

    unawaited(_loadWeather());
  }

  Future<List<TrailData>> _loadFromOverpass(String query) async {
    final response = await http.post(
      Uri.parse('https://overpass-api.de/api/interpreter'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        // overpass-api.de returns 406 if User-Agent looks like a generic script
        // (e.g. Dart's default); use an identifiable app UA.
        'User-Agent':
            'WildHorizon/1.0 (OSM trail viewer; +https://openstreetmap.org/copyright)',
        'Accept': '*/*',
      },
      body: {'data': query},
    );

    if (response.statusCode != 200) {
      throw Exception('Overpass API returned ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (decoded['elements'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final seenIds = <int>{};
    final trails = <TrailData>[];
    for (final element in elements) {
      final rawId = element['id'];
      if (rawId is! num) {
        continue;
      }
      final id = rawId.toInt();
      if (seenIds.contains(id)) {
        continue;
      }
      seenIds.add(id);

      final geometry = (element['geometry'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      final points = <LatLng>[];
      for (final point in geometry) {
        final lat = point['lat'];
        final lon = point['lon'];
        if (lat is num && lon is num) {
          points.add(LatLng(lat.toDouble(), lon.toDouble()));
        }
      }
      if (points.length > 1) {
        final hasPointInRadius = points.any(
          (point) =>
              _distance.as(LengthUnit.Meter, _mapCenter, point) <=
              _radiusMeters,
        );
        if (!hasPointInRadius) {
          continue;
        }

        final tags = (element['tags'] as Map<String, dynamic>? ?? {});
        if (!_isOsmBikeTrail(tags)) {
          continue;
        }
        final highway = (tags['highway'] as String?) ?? 'path';
        double lengthMeters = 0;
        for (var i = 1; i < points.length; i++) {
          lengthMeters += _distance.as(
            LengthUnit.Meter,
            points[i - 1],
            points[i],
          );
        }
        trails.add(
          TrailData(
            osmId: id,
            points: points,
            name: _trailNameFromOsmTags(tags, highway),
            highwayType: highway,
            surface: tags['surface'] as String?,
            mtbScale: tags['mtb:scale'] as String?,
            mtbScaleImba: tags['mtb:scale:imba'] as String?,
            osmSacScale: tags['sac_scale'] as String?,
            tracktype: tags['tracktype'] as String?,
            lengthKm: lengthMeters / 1000,
          ),
        );
      }
    }
    return trails;
  }

  Widget _buildHomeTab(BuildContext context, String radiusLabel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.place_outlined),
              title: const Text('Trail search area'),
              subtitle: Text('$_areaName ($radiusLabel-mile radius)'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bike trails from OpenStreetMap via Overpass (no API key). Pan/zoom, then refresh.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              IconButton.filledTonal(
                onPressed: _isLoadingTrails ? null : _loadTrails,
                tooltip: 'Refresh bike trails now',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Center: ${_mapCenter.latitude.toStringAsFixed(4)}, ${_mapCenter.longitude.toStringAsFixed(4)}  |  Zoom: ${_mapZoom.toStringAsFixed(1)}x',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _showAddRideDialog,
            icon: const Icon(Icons.add_road),
            label: const Text('Add ride'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab(BuildContext context, String radiusLabel) {
    final statusBarH = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _mapCenter,
            initialZoom: _mapZoom,
            onMapReady: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _loadTrails();
                }
              });
            },
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onPositionChanged: (position, _) {
              final center = position.center;
              final zoom = position.zoom;
              setState(() {
                _mapCenter = center;
                _mapZoom = zoom;
              });
              _schedulePersistMapView();
            },
            onTap: _onMapTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.wildhorizon',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _mapCenter,
                  radius: _radiusMeters,
                  useRadiusInMeter: true,
                  color: Colors.green.withAlpha(35),
                  borderColor: Colors.green.shade700,
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            PolylineLayer(
              polylines: _trails.map((trail) {
                final selected = trail.osmId == _selectedTrailId;
                final tier = _trailDifficultyTier(trail);
                final lineColor = _trailDifficultyColor(tier);
                final baseWidth = _mapZoom >= 13
                    ? 5.0
                    : _mapZoom >= 11
                    ? 4.0
                    : 3.0;
                final expertDouble = !selected && tier == 3;
                return Polyline(
                  points: trail.points,
                  color: lineColor,
                  strokeWidth: selected
                      ? baseWidth + 2
                      : baseWidth + (expertDouble ? 0.5 : 0),
                  borderStrokeWidth: selected
                      ? 3.5
                      : (expertDouble ? 2.25 : 0),
                  borderColor: selected
                      ? Colors.yellowAccent.shade400
                      : (expertDouble
                            ? const Color(0xFFE0E0E0)
                            : Colors.transparent),
                );
              }).toList(),
            ),
            if (_focusedRecordedRide != null &&
                _focusedRecordedRide!.track.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _focusedRecordedRide!.track,
                    color: const Color(0xFFAA00FF),
                    strokeWidth: 4.5,
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _mapCenter,
                  width: 28,
                  height: 28,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                  ),
                ),
                if (_focusedRecordedRide != null &&
                    _focusedRecordedRide!.track.length >= 2) ...[
                  Marker(
                    point: _focusedRecordedRide!.track.first,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.flag,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Marker(
                    point: _focusedRecordedRide!.track.last,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFAA00FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.sports_score,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        if (_isLoadingTrails)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x44000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        Positioned(
          top: statusBarH + 128,
          left: 12,
          child: Card(
            color: Colors.white.withAlpha(230),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _zoomIn,
                  tooltip: 'Zoom in',
                  icon: const Icon(Icons.add, size: 18),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
                const Divider(height: 1),
                IconButton(
                  onPressed: _zoomOut,
                  tooltip: 'Zoom out',
                  icon: const Icon(Icons.remove, size: 18),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
        if (_trailCompletionTarget != null)
          Positioned(
            left: 56,
            right: 8,
            top: statusBarH + 128,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.navigation_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _trailCompletionReachedStart
                            ? 'Reach the end of "${_trailCompletionTarget!.name}" to save'
                            : 'Go to the start of "${_trailCompletionTarget!.name}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: _cancelTrailCompletionTracking,
                      child: const Text('Stop'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          top: statusBarH + 128,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_weather != null) ...[
                _WeatherChip(
                  snapshot: _weather!,
                  units: _units,
                  isLoading: _isLoadingWeather,
                  onTap: _showWeatherSheet,
                ),
                const SizedBox(height: 8),
              ],
              Card(
                color: Colors.white.withAlpha(230),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    '${_trails.length} bike trails in $radiusLabel-mile radius',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (_focusedRecordedRide != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Card(
                    color: const Color(0xFFAA00FF).withValues(alpha: 0.92),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.route,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              _focusedRecordedRide!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(
                              () => _focusedRecordedRide = null,
                            ),
                            tooltip: 'Clear ride view',
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Card(
              color: Colors.white.withAlpha(235),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.labelSmall!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Line color = difficulty',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      for (final tier in const <int>[0, 1, 2, 3])
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _trailDifficultyLegendSwatch(tier),
                              const SizedBox(width: 6),
                              Text(_trailDifficultyLabel(tier)),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _trailDifficultyLegendSwatch(-1),
                            const SizedBox(width: 6),
                            const Expanded(child: Text('Unrated')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_trailError != null)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _trailError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
        Positioned(
          top: statusBarH + 8,
          left: 8,
          right: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(28),
                      color: Theme.of(context).colorScheme.surface,
                      child: Autocomplete<TrailData>(
                        displayStringForOption: (trail) => trail.name,
                        optionsBuilder: (TextEditingValue value) {
                          final q = value.text.trim().toLowerCase();
                          if (q.isEmpty || _trails.isEmpty) {
                            return const Iterable<TrailData>.empty();
                          }
                          final list = _trails
                              .where((t) => t.name.toLowerCase().contains(q))
                              .toList();
                          list.sort(
                            (a, b) => a.name
                                .toLowerCase()
                                .compareTo(b.name.toLowerCase()),
                          );
                          return list.take(20);
                        },
                        onSelected: (trail) {
                          _focusTrailOnMap(trail);
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                        fieldViewBuilder: (
                          context,
                          textController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          return TextField(
                            controller: textController,
                            focusNode: focusNode,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search trails...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              prefixIcon: const Icon(Icons.search, size: 18),
                              suffixIcon: textController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear',
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        textController.clear();
                                        setState(() {});
                                      },
                                    ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (value) {
                              _tryFocusTrailFromSearchQuery(value);
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _showBrowseTrailsSheet,
                    icon: const Icon(Icons.list_alt_outlined, size: 16),
                    label: const Text('Search'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(fontSize: 13),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Material(
                    elevation: 4,
                    shape: const CircleBorder(),
                    color: Theme.of(context).colorScheme.surface,
                    child: IconButton(
                      onPressed: _isLoadingTrails ? null : _loadTrails,
                      icon: const Icon(Icons.refresh, size: 18),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      tooltip: 'Refresh trails',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.surface,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _radiusMiles > 5
                              ? () {
                                  setState(
                                    () => _radiusMiles =
                                        (_radiusMiles - 5).clamp(5, 500),
                                  );
                                  _loadTrails();
                                }
                              : null,
                          icon: const Icon(Icons.remove, size: 16),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          tooltip: 'Decrease radius',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '${_radiusMiles.toStringAsFixed(0)} mi',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _radiusMiles < 500
                              ? () {
                                  setState(
                                    () => _radiusMiles =
                                        (_radiusMiles + 5).clamp(5, 500),
                                  );
                                  _loadTrails();
                                }
                              : null,
                          icon: const Icon(Icons.add, size: 16),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          tooltip: 'Increase radius',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: _PressEffect(
            onTap: _openRecordingScreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF1744).withValues(alpha: 0.55),
                blurRadius: 22,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            pressedShadow: [
              BoxShadow(
                color: const Color(0xFFFF1744).withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF5252), Color(0xFFB71C1C)],
                ),
              ),
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Tooltip(
                    message: 'Record a ride',
                    child: Icon(
                      Icons.fiber_manual_record,
                      color: Color(0xFFD50000),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRidesTab(BuildContext context) {
    final rider = _riderNameController.text.trim();
    final bike = _riderBikeController.text.trim();
    String? riderLine;
    if (rider.isNotEmpty && bike.isNotEmpty) {
      riderLine = 'Rider: $rider · $bike';
    } else if (rider.isNotEmpty) {
      riderLine = 'Rider: $rider';
    } else if (bike.isNotEmpty) {
      riderLine = 'Bike: $bike';
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (riderLine != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                riderLine,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          FilledButton.icon(
            onPressed: _showAddRideDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add ride'),
          ),
          const SizedBox(height: 12),
          _AchievementsHeaderCard(
            unlockedCount: _achievementUnlocks.length,
            totalCount: kAchievements.length,
            recentUnlocks: _recentlyUnlockedBadges(3),
            onTap: _openAchievementsScreen,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _rides.isEmpty
                ? Center(
                    child: Text(
                      'No rides saved yet.\nAdd one here, from a trail on the map, or use Add ride on Home.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _rides.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ride = _rides[index];
                      return _RideCard(
                        ride: ride,
                        units: _units,
                        onTap: ride.hasRecordedTrack
                            ? () => _focusRecordedRideOnMap(ride)
                            : null,
                        onShare: ride.hasRecordedTrack
                            ? () => _openRideShareCard(ride)
                            : null,
                        onDelete: () => _removeRideAt(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Rider', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Saved on this device only.', style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        TextField(
          controller: _riderNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Display name',
            hintText: 'What we call you on Rides',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _riderBikeController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Bike (optional)',
            hintText: 'e.g. Trek Fuel EX 8',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saveRiderProfile,
          child: const Text('Save rider profile'),
        ),
        const SizedBox(height: 32),
        Text('Units', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Distances, elevation and speeds use these units everywhere.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        SegmentedButton<UnitSystem>(
          segments: const [
            ButtonSegment<UnitSystem>(
              value: UnitSystem.metric,
              label: Text('kph'),
            ),
            ButtonSegment<UnitSystem>(
              value: UnitSystem.imperial,
              label: Text('mph'),
            ),
          ],
          selected: {_units},
          onSelectionChanged: (selection) {
            if (selection.isNotEmpty) {
              _setUnits(selection.first);
            }
          },
        ),
        const SizedBox(height: 32),
        Text('Appearance', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Auto follows your system light/dark setting.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final mode = MyApp.of(context)?.themeMode ?? ThemeMode.system;
            return SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('Auto'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  MyApp.of(context)?.setThemeMode(selection.first);
                }
              },
            );
          },
        ),
        const SizedBox(height: 32),
        Text('About', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'WildHorizon loads bike trails from OpenStreetMap (Overpass). '
          'Ride list and rider profile are stored locally with SharedPreferences.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final radiusLabel = _radiusMiles.toStringAsFixed(0);
    const navTitles = ['WildHorizon', 'Rides', 'Map', 'Settings'];

    return Scaffold(
      appBar: _navIndex == 2 ? null : AppBar(title: Text(navTitles[_navIndex])),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildHomeTab(context, radiusLabel),
          _buildRidesTab(context),
          _buildMapTab(context, radiusLabel),
          _buildSettingsTab(context),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (index) {
          setState(() {
            _navIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bike_outlined),
            selectedIcon: Icon(Icons.directions_bike),
            label: 'Rides',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

String? _trimmedOsmTag(Map<String, dynamic> tags, String key) {
  final value = tags[key];
  if (value is! String) {
    return null;
  }
  final t = value.trim();
  return t.isEmpty ? null : t;
}

/// OSM tagging must clearly allow cycling / MTB (excludes generic foot paths).
bool _isOsmBikeTrail(Map<String, dynamic> tags) {
  final bicycle = _trimmedOsmTag(tags, 'bicycle')?.toLowerCase();
  if (bicycle == 'no' || bicycle == 'use_sidepath') {
    return false;
  }

  final hw = _trimmedOsmTag(tags, 'highway')?.toLowerCase() ?? '';
  if (hw == 'cycleway') {
    return true;
  }
  if (hw != 'path' && hw != 'track') {
    return false;
  }

  if (RegExp(r'^(yes|designated|permissive)$').hasMatch(bicycle ?? '')) {
    return true;
  }

  final mtb = _trimmedOsmTag(tags, 'mtb')?.toLowerCase() ?? '';
  if (RegExp(r'^(yes|designated|allowed|official)$').hasMatch(mtb)) {
    return true;
  }

  if (_trimmedOsmTag(tags, 'mtb:scale') != null) {
    return true;
  }

  return false;
}

/// Best-effort label from OSM tags. Many paths have no `name` but do have
/// `ref`, `mtb:name`, route refs, endpoints, or other descriptive tags.
String _trailNameFromOsmTags(Map<String, dynamic> tags, String highwayType) {
  const nameKeys = [
    'name',
    'mtb:name',
    'official_name',
    'alt_name',
    'loc_name',
    'reg_name',
    'short_name',
    'designation',
  ];
  for (final key in nameKeys) {
    final s = _trimmedOsmTag(tags, key);
    if (s != null) {
      return s;
    }
  }

  const refKeys = [
    'ref',
    'mtb:ref',
    'nhn:ref',
    'usfs:trailid',
    'ncn_ref',
    'rcn_ref',
    'lcn_ref',
    'lwn_ref',
    'rwn_ref',
    'nwn_ref',
  ];
  for (final key in refKeys) {
    final r = _trimmedOsmTag(tags, key);
    if (r != null) {
      final network =
          _trimmedOsmTag(tags, 'network') ?? _trimmedOsmTag(tags, 'route');
      if (network != null && network.length <= 14) {
        return '$network $r';
      }
      return 'Trail $r';
    }
  }

  final destination = _trimmedOsmTag(tags, 'destination');
  if (destination != null) {
    return 'Toward $destination';
  }

  final from = _trimmedOsmTag(tags, 'from');
  final to = _trimmedOsmTag(tags, 'to');
  if (from != null && to != null) {
    return '$from – $to';
  }
  if (to != null) {
    return 'Toward $to';
  }
  if (from != null) {
    return 'From $from';
  }

  final desc = _trimmedOsmTag(tags, 'description');
  if (desc != null && desc.length <= 72) {
    return desc;
  }

  final parts = <String>[];
  final hw = highwayType.trim();
  if (hw.isNotEmpty) {
    parts.add(hw[0].toUpperCase() + hw.substring(1));
  }
  final surface = _trimmedOsmTag(tags, 'surface');
  if (surface != null) {
    parts.add(surface);
  }
  final scale = _trimmedOsmTag(tags, 'mtb:scale');
  if (scale != null) {
    parts.add('MTB $scale');
  }
  if (parts.isNotEmpty) {
    return parts.join(' · ');
  }
  return 'Unnamed trail';
}

int? _parseSacScaleDigit(String? raw) {
  if (raw == null) {
    return null;
  }
  final s = raw.trim();
  if (s.isEmpty) {
    return null;
  }
  final lower = s.toLowerCase();
  final m = RegExp(r'^[sS]?(\d)').firstMatch(lower);
  if (m != null) {
    return int.tryParse(m.group(1)!);
  }
  return null;
}

int? _parseImbaDigit(String? raw) {
  if (raw == null) {
    return null;
  }
  final s = raw.trim();
  if (s.isEmpty) {
    return null;
  }
  return int.tryParse(s[0]);
}

/// Rough MTB bucket 0–6 from OSM `sac_scale` (hiking scale) when `mtb:scale` is missing.
int? _bucketFromOsmSacScaleTag(String? raw) {
  if (raw == null) {
    return null;
  }
  final s = raw.trim();
  if (s.isEmpty) {
    return null;
  }
  final lower = s.toLowerCase();
  final t = RegExp(r'^[tT]\s*(\d)').firstMatch(lower);
  if (t != null) {
    final d = int.tryParse(t.group(1)!);
    if (d != null) {
      return (d - 1).clamp(0, 6);
    }
  }
  switch (lower.replaceAll('-', '_')) {
    case 'hiking':
      return 0;
    case 'mountain_hiking':
      return 2;
    case 'demanding_mountain_hiking':
      return 3;
    case 'alpine_hiking':
      return 4;
    case 'demanding_alpine_hiking':
      return 5;
    case 'difficult_alpine_hiking':
      return 6;
    default:
      return null;
  }
}

/// Rough MTB bucket from OSM `tracktype` (surface firmness of tracks).
int? _bucketFromTracktype(String? raw) {
  if (raw == null) {
    return null;
  }
  final m = RegExp(
    r'grade\s*(\d)',
    caseSensitive: false,
  ).firstMatch(raw.trim());
  if (m == null) {
    return null;
  }
  final d = int.tryParse(m.group(1)!);
  if (d == null || d < 1 || d > 5) {
    return null;
  }
  const gradeToBucket = <int, int>{1: 0, 2: 1, 3: 2, 4: 4, 5: 5};
  return gradeToBucket[d];
}

/// Last-resort hint from `surface` when no better tags exist.
int? _bucketFromSurfaceHint(String? raw) {
  if (raw == null) {
    return null;
  }
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) {
    return null;
  }
  if (s.contains('paving') ||
      s.contains('paved') ||
      s.contains('asphalt') ||
      s.contains('concrete') ||
      s == 'paving_stones') {
    return 0;
  }
  if (s.contains('gravel') ||
      s.contains('compacted') ||
      s.contains('fine_gravel')) {
    return 1;
  }
  if (s == 'dirt' ||
      s == 'earth' ||
      s == 'ground' ||
      s == 'grass' ||
      s.contains('wood')) {
    return 2;
  }
  if (s.contains('rock') || s.contains('mud') || s.contains('sand')) {
    return 3;
  }
  return null;
}

/// Raw `mtb:scale` / IMBA-derived bucket 0–6, or -1 unrated, except [cycleway] → 0.
/// Falls back to hiking [sac_scale], [tracktype], then [surface] when MTB tags are absent.
int _trailSacMtbBucket(TrailData trail) {
  final sac = _parseSacScaleDigit(trail.mtbScale);
  if (sac != null) {
    return sac.clamp(0, 6);
  }
  final imba = _parseImbaDigit(trail.mtbScaleImba);
  if (imba != null) {
    const imbaToSac = [0, 2, 3, 5, 6];
    return imbaToSac[imba.clamp(0, 4)];
  }
  if (trail.highwayType.toLowerCase() == 'cycleway') {
    return 0;
  }
  final fromSac = _bucketFromOsmSacScaleTag(trail.osmSacScale);
  if (fromSac != null) {
    return fromSac.clamp(0, 6);
  }
  final fromTrack = _bucketFromTracktype(trail.tracktype);
  if (fromTrack != null) {
    return fromTrack.clamp(0, 6);
  }
  final fromSurface = _bucketFromSurfaceHint(trail.surface);
  if (fromSurface != null) {
    return fromSurface.clamp(0, 6);
  }
  return -1;
}

/// Ski-style display tier: -1 unrated, 0 beginner, 1 intermediate, 2 advanced, 3 expert.
int _trailDifficultyTier(TrailData trail) {
  final b = _trailSacMtbBucket(trail);
  if (b < 0) {
    return -1;
  }
  if (b <= 1) {
    return 0;
  }
  if (b <= 3) {
    return 1;
  }
  if (b <= 5) {
    return 2;
  }
  return 3;
}

Color _trailDifficultyColor(int tier) {
  switch (tier) {
    case -1:
      return const Color(0xFFC62828);
    case 0:
      return const Color(0xFF2E7D32);
    case 1:
      return const Color(0xFF1565C0);
    case 2:
    case 3:
      return const Color(0xFF000000);
    default:
      return const Color(0xFFC62828);
  }
}

/// Labels for [tier] values from [_trailDifficultyTier] only.
String _trailDifficultyLabel(int tier) {
  switch (tier) {
    case -1:
      return 'Unrated';
    case 0:
      return 'Beginner';
    case 1:
      return 'Intermediate';
    case 2:
      return 'Advanced';
    case 3:
      return 'Expert';
    default:
      return 'Unrated';
  }
}

/// True when difficulty comes from `mtb:scale` / `mtb:scale:imba` or a cycleway default.
bool _trailDifficultyFromVerifiedOsmTags(TrailData trail) {
  if (trail.highwayType.toLowerCase() == 'cycleway') {
    return true;
  }
  if (_parseSacScaleDigit(trail.mtbScale) != null) {
    return true;
  }
  if (_parseImbaDigit(trail.mtbScaleImba) != null) {
    return true;
  }
  return false;
}

String _trailDifficultyDisplayLabel(TrailData trail) {
  final tier = _trailDifficultyTier(trail);
  final base = _trailDifficultyLabel(tier);
  if (tier < 0 || _trailDifficultyFromVerifiedOsmTags(trail)) {
    return base;
  }
  return '$base (est.)';
}

Widget _trailDifficultyLegendSwatch(int tier) {
  if (tier == 3) {
    return SizedBox(
      width: 14,
      height: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.black26, width: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.black26, width: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
  return SizedBox(
    width: 14,
    height: 10,
    child: Center(
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: _trailDifficultyColor(tier),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.black26, width: 0.5),
        ),
      ),
    ),
  );
}

enum UnitSystem {
  metric,
  imperial;

  static UnitSystem fromName(String? name) {
    if (name == 'imperial') return UnitSystem.imperial;
    return UnitSystem.metric;
  }

  String get persistName => this == UnitSystem.imperial ? 'imperial' : 'metric';
}

String _formatDurationSeconds(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  if (h > 0) {
    return '$h:${two(m)}:${two(s)}';
  }
  return '${two(m)}:${two(s)}';
}

/// "1.23 km" / "455 m" for metric; "0.76 mi" / "1494 ft" for imperial.
String _formatDistance(double meters, UnitSystem u) {
  if (u == UnitSystem.imperial) {
    final feet = meters * 3.28084;
    if (feet < 1000) {
      return '${feet.toStringAsFixed(0)} ft';
    }
    final miles = meters / 1609.344;
    return '${miles.toStringAsFixed(2)} mi';
  }
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
  return '${meters.toStringAsFixed(0)} m';
}

/// Just the elevation magnitude with unit, no arrow: "45 m" / "148 ft".
String _formatElevationValue(double meters, UnitSystem u) {
  if (u == UnitSystem.imperial) {
    final feet = meters * 3.28084;
    return '${feet.toStringAsFixed(0)} ft';
  }
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
  return '${meters.toStringAsFixed(0)} m';
}

/// Elevation gain prefixed with an up-arrow: "↑45 m" / "↑148 ft".
String _formatElevationGain(double meters, UnitSystem u) =>
    '↑${_formatElevationValue(meters, u)}';

String _speedUnitLabel(UnitSystem u) =>
    u == UnitSystem.imperial ? 'mph' : 'km/h';

/// Just the number, no unit: "12.3". Returns "0" when speed is essentially zero.
String _formatSpeedValue(double mps, UnitSystem u) {
  final v = u == UnitSystem.imperial ? mps * 2.23694 : mps * 3.6;
  if (v < 0.1) {
    return '0';
  }
  return v.toStringAsFixed(1);
}

/// "12.3 km/h" / "12.3 mph".
String _formatSpeed(double mps, UnitSystem u) =>
    '${_formatSpeedValue(mps, u)} ${_speedUnitLabel(u)}';

/// Open-Meteo data is always Celsius; convert + format for the active unit.
String _formatTemperature(double celsius, UnitSystem u) {
  final v = u == UnitSystem.imperial
      ? (celsius * 9 / 5) + 32
      : celsius;
  return '${v.round()}°${u == UnitSystem.imperial ? 'F' : 'C'}';
}

/// Wind in km/h → "12 mph" or "12 km/h".
String _formatWind(double kmh, UnitSystem u) {
  final v = u == UnitSystem.imperial ? kmh * 0.621371 : kmh;
  return '${v.round()} ${u == UnitSystem.imperial ? 'mph' : 'km/h'}';
}

class RideEntry {
  RideEntry({
    required this.name,
    this.notes = '',
    DateTime? createdAt,
    this.track = const [],
    this.distanceMeters,
    this.durationSeconds,
    this.elevationGainMeters,
    this.avgSpeedMps,
    this.maxSpeedMps,
  }) : createdAt = createdAt ?? DateTime.now();

  final String name;
  final String notes;
  final DateTime createdAt;
  final List<LatLng> track;
  final double? distanceMeters;
  final int? durationSeconds;
  final double? elevationGainMeters;
  final double? avgSpeedMps;
  final double? maxSpeedMps;

  bool get hasRecordedTrack => track.length >= 2;

  String createdLabel() {
    final d = createdAt;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String? distanceLabel(UnitSystem units) {
    final m = distanceMeters;
    if (m == null) {
      return null;
    }
    return _formatDistance(m, units);
  }

  String? durationLabel() {
    final s = durationSeconds;
    if (s == null) {
      return null;
    }
    return _formatDurationSeconds(s);
  }

  String? elevationGainLabel(UnitSystem units) {
    final g = elevationGainMeters;
    if (g == null || g < 1) {
      return null;
    }
    return _formatElevationGain(g, units);
  }

  String? avgSpeedLabel(UnitSystem units) {
    final s = avgSpeedMps;
    if (s == null || s <= 0.1) {
      return null;
    }
    return 'avg ${_formatSpeed(s, units)}';
  }

  String? maxSpeedLabel(UnitSystem units) {
    final s = maxSpeedMps;
    if (s == null || s <= 0.1) {
      return null;
    }
    return 'max ${_formatSpeed(s, units)}';
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    if (track.isNotEmpty)
      'track': track
          .map((p) => [p.latitude, p.longitude])
          .toList(growable: false),
    if (distanceMeters != null) 'distanceMeters': distanceMeters,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (elevationGainMeters != null) 'elevationGainMeters': elevationGainMeters,
    if (avgSpeedMps != null) 'avgSpeedMps': avgSpeedMps,
    if (maxSpeedMps != null) 'maxSpeedMps': maxSpeedMps,
  };

  factory RideEntry.fromJson(Map<String, dynamic> json) {
    final nameRaw = json['name'] as String? ?? '';
    final name = nameRaw.trim().isEmpty ? 'Ride' : nameRaw.trim();
    final trackRaw = json['track'];
    final track = <LatLng>[];
    if (trackRaw is List) {
      for (final p in trackRaw) {
        if (p is List && p.length == 2 && p[0] is num && p[1] is num) {
          track.add(
            LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
          );
        }
      }
    }
    final distRaw = json['distanceMeters'];
    final durRaw = json['durationSeconds'];
    final elevRaw = json['elevationGainMeters'];
    final avgRaw = json['avgSpeedMps'];
    final maxRaw = json['maxSpeedMps'];
    return RideEntry(
      name: name,
      notes: (json['notes'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      track: track,
      distanceMeters: distRaw is num ? distRaw.toDouble() : null,
      durationSeconds: durRaw is num ? durRaw.toInt() : null,
      elevationGainMeters: elevRaw is num ? elevRaw.toDouble() : null,
      avgSpeedMps: avgRaw is num ? avgRaw.toDouble() : null,
      maxSpeedMps: maxRaw is num ? maxRaw.toDouble() : null,
    );
  }
}

class TrailData {
  const TrailData({
    required this.osmId,
    required this.points,
    required this.name,
    required this.highwayType,
    required this.lengthKm,
    this.surface,
    this.mtbScale,
    this.mtbScaleImba,
    this.osmSacScale,
    this.tracktype,
  });

  final int osmId;
  final List<LatLng> points;
  final String name;
  final String highwayType;
  final String? surface;
  final String? mtbScale;
  final String? mtbScaleImba;
  /// Hiking `sac_scale` when `mtb:scale` is absent (OpenStreetMap).
  final String? osmSacScale;
  final String? tracktype;
  final double lengthKm;
}

/// A user-pickable location for weather lookups. Can come from the
/// Open-Meteo geocoding API (search), the device's GPS (auto), or be
/// `null` (let the weather follow the map center). Persisted as
/// `weather_location_v1`.
class WeatherLocation {
  const WeatherLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.country,
    this.admin,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  final String? admin;

  /// Pretty "Mountain View, California, United States" string for headers.
  /// Falls back gracefully if admin/country are missing.
  String get displayName {
    final parts = <String>[
      name,
      if (admin != null && admin!.isNotEmpty) admin!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.join(', ');
  }

  /// Shorter "Mountain View, CA" / "Mountain View, US" for the chip / sheet
  /// header where space is tight.
  String get shortName {
    final region = admin ?? country;
    if (region == null || region.isEmpty) return name;
    return '$name, $region';
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'country': country,
    'admin': admin,
  };

  static WeatherLocation fromJson(Map<String, dynamic> json) =>
      WeatherLocation(
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        country: json['country'] as String?,
        admin: json['admin'] as String?,
      );
}

/// Live conditions reported by Open-Meteo. All values stored in metric
/// (Celsius / km·h). The UI converts to imperial at render time based on
/// the user's `UnitSystem` preference.
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.tempC,
    required this.feelsLikeC,
    required this.weatherCode,
    required this.isDay,
    required this.windSpeedKmh,
    required this.windDirectionDeg,
    required this.humidityPct,
    required this.precipitationMm,
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
    this.placeName,
  });

  final double tempC;
  final double feelsLikeC;
  final int weatherCode;
  final bool isDay;
  final double windSpeedKmh;
  final double windDirectionDeg;
  final int humidityPct;
  final double precipitationMm;
  final double latitude;
  final double longitude;
  final DateTime fetchedAt;

  /// Friendly label for the location these readings represent. `null`
  /// means "following the map" and the UI shows "Map view" instead.
  final String? placeName;

  Map<String, dynamic> toJson() => {
    'tempC': tempC,
    'feelsLikeC': feelsLikeC,
    'weatherCode': weatherCode,
    'isDay': isDay,
    'windSpeedKmh': windSpeedKmh,
    'windDirectionDeg': windDirectionDeg,
    'humidityPct': humidityPct,
    'precipitationMm': precipitationMm,
    'latitude': latitude,
    'longitude': longitude,
    'fetchedAt': fetchedAt.toIso8601String(),
    'placeName': placeName,
  };

  static WeatherSnapshot fromJson(Map<String, dynamic> json) {
    return WeatherSnapshot(
      tempC: (json['tempC'] as num).toDouble(),
      feelsLikeC: (json['feelsLikeC'] as num).toDouble(),
      weatherCode: (json['weatherCode'] as num).toInt(),
      isDay: json['isDay'] as bool,
      windSpeedKmh: (json['windSpeedKmh'] as num).toDouble(),
      windDirectionDeg: (json['windDirectionDeg'] as num).toDouble(),
      humidityPct: (json['humidityPct'] as num).toInt(),
      precipitationMm: (json['precipitationMm'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      placeName: json['placeName'] as String?,
    );
  }
}

class WeatherDayForecast {
  const WeatherDayForecast({
    required this.date,
    required this.weatherCode,
    required this.tempMaxC,
    required this.tempMinC,
    required this.precipitationMm,
    required this.windMaxKmh,
  });

  final DateTime date;
  final int weatherCode;
  final double tempMaxC;
  final double tempMinC;
  final double precipitationMm;
  final double windMaxKmh;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weatherCode': weatherCode,
    'tempMaxC': tempMaxC,
    'tempMinC': tempMinC,
    'precipitationMm': precipitationMm,
    'windMaxKmh': windMaxKmh,
  };

  static WeatherDayForecast fromJson(Map<String, dynamic> json) {
    return WeatherDayForecast(
      date: DateTime.parse(json['date'] as String),
      weatherCode: (json['weatherCode'] as num).toInt(),
      tempMaxC: (json['tempMaxC'] as num).toDouble(),
      tempMinC: (json['tempMinC'] as num).toDouble(),
      precipitationMm: (json['precipitationMm'] as num).toDouble(),
      windMaxKmh: (json['windMaxKmh'] as num).toDouble(),
    );
  }
}

// ---------------------------------------------------------------------------
// Achievements
// ---------------------------------------------------------------------------

enum AchievementCategory {
  rides('Milestones'),
  distance('Distance'),
  elevation('Elevation'),
  speed('Speed'),
  time('Endurance'),
  habits('Habits');

  const AchievementCategory(this.label);
  final String label;
}

/// Current progress toward an [Achievement]. `current >= target` ⇒ unlocked.
class AchievementProgress {
  const AchievementProgress(this.current, this.target);
  final double current;
  final double target;
  bool get isUnlocked => current >= target;
  double get percent =>
      target > 0 ? (current / target).clamp(0.0, 1.0) : 0;
}

/// One unlockable badge. Stored declaratively; the unlock check is a pure
/// function of the ride history so we can re-evaluate at any time.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    required this.target,
    required this.unit,
    required this.progress,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementCategory category;
  final double target;
  final String unit;
  final AchievementProgress Function(List<RideEntry> rides) progress;

  bool isUnlocked(List<RideEntry> rides) => progress(rides).isUnlocked;
}

// ---- Aggregate helpers used by the catalog -------------------------------

double _totalRideDistanceKm(List<RideEntry> rides) {
  var total = 0.0;
  for (final r in rides) {
    final m = r.distanceMeters;
    if (m != null) total += m / 1000;
  }
  return total;
}

double _totalRideElevationM(List<RideEntry> rides) {
  var total = 0.0;
  for (final r in rides) {
    final m = r.elevationGainMeters;
    if (m != null) total += m;
  }
  return total;
}

double _maxSingleRideKm(List<RideEntry> rides) {
  var best = 0.0;
  for (final r in rides) {
    final m = r.distanceMeters;
    if (m == null) continue;
    final km = m / 1000;
    if (km > best) best = km;
  }
  return best;
}

double _maxSingleRideElevationM(List<RideEntry> rides) {
  var best = 0.0;
  for (final r in rides) {
    final m = r.elevationGainMeters;
    if (m != null && m > best) best = m;
  }
  return best;
}

double _maxSingleRideSeconds(List<RideEntry> rides) {
  var best = 0.0;
  for (final r in rides) {
    final s = r.durationSeconds;
    if (s == null) continue;
    final sd = s.toDouble();
    if (sd > best) best = sd;
  }
  return best;
}

double _maxTopSpeedKmh(List<RideEntry> rides) {
  var best = 0.0;
  for (final r in rides) {
    final mps = r.maxSpeedMps;
    if (mps == null) continue;
    final kmh = mps * 3.6;
    if (kmh > best) best = kmh;
  }
  return best;
}

double _habitProgress(
  List<RideEntry> rides,
  bool Function(RideEntry ride) test,
) {
  return rides.any(test) ? 1 : 0;
}

/// The full catalog of badges. Add new ones here — they'll automatically
/// surface in the Achievements screen and the celebration snackbar.
final List<Achievement> kAchievements = [
  // Ride count milestones
  Achievement(
    id: 'first_pedal',
    title: 'First Pedal',
    description: 'Save your first ride',
    icon: Icons.directions_bike,
    color: const Color(0xFF66BB6A),
    category: AchievementCategory.rides,
    target: 1,
    unit: 'ride',
    progress: (r) => AchievementProgress(r.length.toDouble(), 1),
  ),
  Achievement(
    id: 'trail_blazer',
    title: 'Trail Blazer',
    description: 'Save 5 rides',
    icon: Icons.terrain,
    color: const Color(0xFF26A69A),
    category: AchievementCategory.rides,
    target: 5,
    unit: 'rides',
    progress: (r) => AchievementProgress(r.length.toDouble(), 5),
  ),
  Achievement(
    id: 'veteran',
    title: 'Veteran',
    description: 'Save 25 rides',
    icon: Icons.local_fire_department,
    color: const Color(0xFFEF5350),
    category: AchievementCategory.rides,
    target: 25,
    unit: 'rides',
    progress: (r) => AchievementProgress(r.length.toDouble(), 25),
  ),
  Achievement(
    id: 'centurion',
    title: 'Centurion',
    description: 'Save 100 rides',
    icon: Icons.emoji_events,
    color: const Color(0xFFFFA726),
    category: AchievementCategory.rides,
    target: 100,
    unit: 'rides',
    progress: (r) => AchievementProgress(r.length.toDouble(), 100),
  ),

  // Cumulative distance
  Achievement(
    id: 'ten_km_club',
    title: '10 km Club',
    description: 'Ride 10 km in total',
    icon: Icons.straighten,
    color: const Color(0xFF42A5F5),
    category: AchievementCategory.distance,
    target: 10,
    unit: 'km',
    progress: (r) => AchievementProgress(_totalRideDistanceKm(r), 10),
  ),
  Achievement(
    id: 'fifty_km_club',
    title: '50 km Club',
    description: 'Ride 50 km in total',
    icon: Icons.straighten,
    color: const Color(0xFF5C6BC0),
    category: AchievementCategory.distance,
    target: 50,
    unit: 'km',
    progress: (r) => AchievementProgress(_totalRideDistanceKm(r), 50),
  ),
  Achievement(
    id: 'hundred_km_club',
    title: '100 km Club',
    description: 'Ride 100 km in total',
    icon: Icons.bolt,
    color: const Color(0xFF7E57C2),
    category: AchievementCategory.distance,
    target: 100,
    unit: 'km',
    progress: (r) => AchievementProgress(_totalRideDistanceKm(r), 100),
  ),
  Achievement(
    id: 'five_hundred_club',
    title: '500 km Club',
    description: 'Ride 500 km in total',
    icon: Icons.flag,
    color: const Color(0xFFEC407A),
    category: AchievementCategory.distance,
    target: 500,
    unit: 'km',
    progress: (r) => AchievementProgress(_totalRideDistanceKm(r), 500),
  ),

  // Cumulative elevation
  Achievement(
    id: 'hill_climber',
    title: 'Hill Climber',
    description: 'Climb 1,000 m in total',
    icon: Icons.terrain,
    color: const Color(0xFF8D6E63),
    category: AchievementCategory.elevation,
    target: 1000,
    unit: 'm',
    progress: (r) => AchievementProgress(_totalRideElevationM(r), 1000),
  ),
  Achievement(
    id: 'mountain_goat',
    title: 'Mountain Goat',
    description: 'Climb 5,000 m in total',
    icon: Icons.landscape,
    color: const Color(0xFF78909C),
    category: AchievementCategory.elevation,
    target: 5000,
    unit: 'm',
    progress: (r) => AchievementProgress(_totalRideElevationM(r), 5000),
  ),
  Achievement(
    id: 'sky_climber',
    title: 'Sky Climber',
    description: "Climb 10,000 m total — that's an Everest!",
    icon: Icons.flight_takeoff,
    color: const Color(0xFF26C6DA),
    category: AchievementCategory.elevation,
    target: 10000,
    unit: 'm',
    progress: (r) => AchievementProgress(_totalRideElevationM(r), 10000),
  ),

  // Single ride distance
  Achievement(
    id: 'long_hauler',
    title: 'Long Hauler',
    description: 'Ride 25 km in a single trip',
    icon: Icons.timeline,
    color: const Color(0xFF29B6F6),
    category: AchievementCategory.distance,
    target: 25,
    unit: 'km',
    progress: (r) => AchievementProgress(_maxSingleRideKm(r), 25),
  ),
  Achievement(
    id: 'marathon',
    title: 'Marathon',
    description: 'Ride 50 km in a single trip',
    icon: Icons.celebration,
    color: const Color(0xFFD81B60),
    category: AchievementCategory.distance,
    target: 50,
    unit: 'km',
    progress: (r) => AchievementProgress(_maxSingleRideKm(r), 50),
  ),

  // Speed
  Achievement(
    id: 'speedster',
    title: 'Speedster',
    description: 'Hit 30 km/h on a ride',
    icon: Icons.speed,
    color: const Color(0xFFFFCA28),
    category: AchievementCategory.speed,
    target: 30,
    unit: 'km/h',
    progress: (r) => AchievementProgress(_maxTopSpeedKmh(r), 30),
  ),
  Achievement(
    id: 'lightning',
    title: 'Lightning',
    description: 'Hit 50 km/h on a ride',
    icon: Icons.bolt,
    color: const Color(0xFFFFEE58),
    category: AchievementCategory.speed,
    target: 50,
    unit: 'km/h',
    progress: (r) => AchievementProgress(_maxTopSpeedKmh(r), 50),
  ),

  // Single ride elevation
  Achievement(
    id: 'summit',
    title: 'Summit',
    description: 'Climb 500 m in one ride',
    icon: Icons.filter_hdr,
    color: const Color(0xFF66BB6A),
    category: AchievementCategory.elevation,
    target: 500,
    unit: 'm',
    progress: (r) => AchievementProgress(_maxSingleRideElevationM(r), 500),
  ),
  Achievement(
    id: 'everest_step',
    title: 'Everest Step',
    description: 'Climb 1,000 m in one ride',
    icon: Icons.height,
    color: const Color(0xFF26A69A),
    category: AchievementCategory.elevation,
    target: 1000,
    unit: 'm',
    progress: (r) => AchievementProgress(_maxSingleRideElevationM(r), 1000),
  ),

  // Time
  Achievement(
    id: 'endurance',
    title: 'Endurance',
    description: 'Ride for 2+ hours straight',
    icon: Icons.timer,
    color: const Color(0xFFFF7043),
    category: AchievementCategory.time,
    target: 7200,
    unit: 'sec',
    progress: (r) => AchievementProgress(_maxSingleRideSeconds(r), 7200),
  ),
  Achievement(
    id: 'all_day_epic',
    title: 'All-Day Epic',
    description: 'Ride for 5+ hours straight',
    icon: Icons.alarm,
    color: const Color(0xFFE53935),
    category: AchievementCategory.time,
    target: 18000,
    unit: 'sec',
    progress: (r) => AchievementProgress(_maxSingleRideSeconds(r), 18000),
  ),

  // Habits
  Achievement(
    id: 'early_bird',
    title: 'Early Bird',
    description: 'Start a ride before 7 AM',
    icon: Icons.wb_sunny,
    color: const Color(0xFFFFB300),
    category: AchievementCategory.habits,
    target: 1,
    unit: 'ride',
    progress: (r) => AchievementProgress(
      _habitProgress(r, (ride) => ride.createdAt.hour < 7),
      1,
    ),
  ),
  Achievement(
    id: 'night_owl',
    title: 'Night Owl',
    description: 'Start a ride after 8 PM',
    icon: Icons.nightlight_round,
    color: const Color(0xFF5E35B1),
    category: AchievementCategory.habits,
    target: 1,
    unit: 'ride',
    progress: (r) => AchievementProgress(
      _habitProgress(r, (ride) => ride.createdAt.hour >= 20),
      1,
    ),
  ),
  Achievement(
    id: 'weekend_warrior',
    title: 'Weekend Warrior',
    description: 'Ride on a Saturday or Sunday',
    icon: Icons.weekend,
    color: const Color(0xFF1E88E5),
    category: AchievementCategory.habits,
    target: 1,
    unit: 'ride',
    progress: (r) => AchievementProgress(
      _habitProgress(
        r,
        (ride) => ride.createdAt.weekday >= DateTime.saturday,
      ),
      1,
    ),
  ),
];

/// Format the "current / target" line that shows under each badge.
String formatAchievementProgress(Achievement a, AchievementProgress p) {
  if (p.isUnlocked) return 'Unlocked';
  switch (a.unit) {
    case 'sec':
      return '${_formatDurationSeconds(p.current.round())} / '
          '${_formatDurationSeconds(p.target.round())}';
    case 'km':
    case 'km/h':
    case 'm':
      return '${p.current.toStringAsFixed(p.current < 10 ? 1 : 0)} / '
          '${p.target.toStringAsFixed(0)} ${a.unit}';
    default:
      return '${p.current.round()} / ${p.target.round()} ${a.unit}';
  }
}

/// Maps a WMO weather code (Open-Meteo's `weathercode`) to a Material icon.
/// `isDay` swaps sun for moon on clear/partly-cloudy.
IconData weatherIconFor(int code, {bool isDay = true}) {
  switch (code) {
    case 0:
      return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    case 1:
    case 2:
      return isDay ? Icons.wb_cloudy_outlined : Icons.nights_stay_outlined;
    case 3:
      return Icons.cloud_rounded;
    case 45:
    case 48:
      return Icons.foggy;
    case 51:
    case 53:
    case 55:
    case 56:
    case 57:
      return Icons.grain;
    case 61:
    case 63:
    case 65:
    case 66:
    case 67:
      return Icons.water_drop_rounded;
    case 71:
    case 73:
    case 75:
    case 77:
    case 85:
    case 86:
      return Icons.ac_unit_rounded;
    case 80:
    case 81:
    case 82:
      return Icons.umbrella_rounded;
    case 95:
    case 96:
    case 99:
      return Icons.thunderstorm_rounded;
    default:
      return Icons.cloud_outlined;
  }
}

String weatherLabelFor(int code) {
  switch (code) {
    case 0:
      return 'Clear';
    case 1:
      return 'Mostly clear';
    case 2:
      return 'Partly cloudy';
    case 3:
      return 'Overcast';
    case 45:
    case 48:
      return 'Foggy';
    case 51:
    case 53:
    case 55:
      return 'Drizzle';
    case 56:
    case 57:
      return 'Freezing drizzle';
    case 61:
      return 'Light rain';
    case 63:
      return 'Rain';
    case 65:
      return 'Heavy rain';
    case 66:
    case 67:
      return 'Freezing rain';
    case 71:
      return 'Light snow';
    case 73:
      return 'Snow';
    case 75:
      return 'Heavy snow';
    case 77:
      return 'Snow grains';
    case 80:
      return 'Light showers';
    case 81:
      return 'Showers';
    case 82:
      return 'Heavy showers';
    case 85:
    case 86:
      return 'Snow showers';
    case 95:
      return 'Thunderstorm';
    case 96:
    case 99:
      return 'Storm + hail';
    default:
      return 'Cloudy';
  }
}

/// Two-stop gradient that tints the weather chip background to match the
/// conditions: sunny = warm, cloudy = cool gray, rain = deep blue, etc.
List<Color> weatherGradientFor(int code, {required bool isDay}) {
  if (!isDay && (code == 0 || code == 1 || code == 2)) {
    return const [Color(0xFF1A237E), Color(0xFF000051)];
  }
  switch (code) {
    case 0:
    case 1:
      return const [Color(0xFFFFB74D), Color(0xFFEF6C00)];
    case 2:
    case 3:
      return const [Color(0xFF64B5F6), Color(0xFF1976D2)];
    case 45:
    case 48:
      return const [Color(0xFF90A4AE), Color(0xFF455A64)];
    case 51:
    case 53:
    case 55:
    case 56:
    case 57:
    case 61:
    case 63:
    case 65:
    case 66:
    case 67:
    case 80:
    case 81:
    case 82:
      return const [Color(0xFF4FC3F7), Color(0xFF01579B)];
    case 71:
    case 73:
    case 75:
    case 77:
    case 85:
    case 86:
      return const [Color(0xFFE1F5FE), Color(0xFF81D4FA)];
    case 95:
    case 96:
    case 99:
      return const [Color(0xFF4527A0), Color(0xFF1A237E)];
    default:
      return const [Color(0xFF78909C), Color(0xFF37474F)];
  }
}

/// Pulsing red dot used to mark the live recording location and the
/// recording-status chip.
class _RecordingPulseDot extends StatefulWidget {
  const _RecordingPulseDot();

  @override
  State<_RecordingPulseDot> createState() => _RecordingPulseDotState();
}

class _RecordingPulseDotState extends State<_RecordingPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return SizedBox(
          width: 16,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.25 * (1 - t)),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Result handed back from [_RecordingScreen] to the home screen when the
/// user stops a ride.
typedef RecordingResult = ({
  DateTime startedAt,
  DateTime endedAt,
  List<LatLng> track,
  double distanceMeters,
  int durationSeconds,
  double elevationGainMeters,
  double avgSpeedMps,
  double maxSpeedMps,
});

class _RecordingStartResult {
  const _RecordingStartResult.ok() : ok = true, errorMessage = null;
  const _RecordingStartResult.error(this.errorMessage) : ok = false;
  final bool ok;
  final String? errorMessage;
}

/// Owns live GPS recording: position stream, distance accumulation,
/// elevation smoothing, and speed tracking. Notifies listeners on every
/// accepted sample and on every 1-second tick.
class _RecordingSession extends ChangeNotifier {
  static const Distance _distance = Distance();

  bool _isRecording = false;
  final List<LatLng> _track = [];
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  double _distanceMeters = 0;
  double _currentSpeedMps = 0;
  double _maxSpeedMps = 0;
  double _elevationGain = 0;
  double? _smoothedAltitude;
  DateTime? _lastSampleAt;
  StreamSubscription<Position>? _subscription;
  Timer? _tickTimer;

  bool get isRecording => _isRecording;
  List<LatLng> get track => List.unmodifiable(_track);
  DateTime? get startedAt => _startedAt;
  Duration get elapsed => _elapsed;
  double get distanceMeters => _distanceMeters;
  double get currentSpeedMps => _currentSpeedMps;
  double get maxSpeedMps => _maxSpeedMps;
  double get elevationGain => _elevationGain;

  double get avgSpeedMps {
    final secs = _elapsed.inSeconds;
    if (secs < 1) {
      return 0;
    }
    return _distanceMeters / secs;
  }

  Future<_RecordingStartResult> start() async {
    if (_isRecording) {
      return const _RecordingStartResult.ok();
    }
    try {
      final servicesOn = await Geolocator.isLocationServiceEnabled();
      if (!servicesOn) {
        return const _RecordingStartResult.error(
          'Location services are off. Enable them in System Settings → '
          'Privacy & Security → Location Services.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const _RecordingStartResult.error(
          'Location permission denied. Allow it in System Settings to '
          'record rides.',
        );
      }
    } catch (e) {
      return _RecordingStartResult.error('Could not access location: $e');
    }

    _isRecording = true;
    _track.clear();
    _distanceMeters = 0;
    _startedAt = DateTime.now();
    _elapsed = Duration.zero;
    _smoothedAltitude = null;
    _elevationGain = 0;
    _currentSpeedMps = 0;
    _maxSpeedMps = 0;
    _lastSampleAt = null;
    notifyListeners();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );
    _subscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_handlePosition, onError: (_) {});
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = _startedAt;
      if (start == null) {
        return;
      }
      _elapsed = DateTime.now().difference(start);
      notifyListeners();
    });
    return const _RecordingStartResult.ok();
  }

  void _handlePosition(Position position) {
    if (!_isRecording) {
      return;
    }
    final p = LatLng(position.latitude, position.longitude);
    double stepMeters = 0;
    if (_track.isNotEmpty) {
      stepMeters = _distance.as(LengthUnit.Meter, _track.last, p);
      // Filter obvious GPS jitter (sub-3m steps) and teleports (>150m jumps).
      if (stepMeters < 3 || stepMeters > 150) {
        return;
      }
      _distanceMeters += stepMeters;
    }
    _updateElevation(position);
    _updateSpeed(position, stepMeters);
    _track.add(p);
    notifyListeners();
  }

  void _updateElevation(Position position) {
    final alt = position.altitude;
    if (!alt.isFinite) {
      return;
    }
    final accuracy = position.altitudeAccuracy;
    if (accuracy.isFinite && accuracy > 25) {
      return;
    }
    const alpha = 0.4;
    final prev = _smoothedAltitude;
    final smoothed = prev == null ? alt : prev + alpha * (alt - prev);
    if (prev != null) {
      final delta = smoothed - prev;
      if (delta >= 1.0) {
        _elevationGain += delta;
      }
    }
    _smoothedAltitude = smoothed;
  }

  void _updateSpeed(Position position, double stepMeters) {
    double speedMps = 0;
    if (position.speed.isFinite && position.speed >= 0) {
      speedMps = position.speed;
    } else {
      final last = _lastSampleAt;
      final now = position.timestamp;
      if (last != null) {
        final dt = now.difference(last).inMilliseconds / 1000.0;
        if (dt > 0 && stepMeters > 0) {
          speedMps = stepMeters / dt;
        }
      }
    }
    if (speedMps > 42) {
      speedMps = _currentSpeedMps;
    }
    _currentSpeedMps = speedMps;
    if (speedMps > _maxSpeedMps) {
      _maxSpeedMps = speedMps;
    }
    _lastSampleAt = position.timestamp;
  }

  /// Stops recording and returns the captured stats. Returns `null` if
  /// recording wasn't running.
  RecordingResult? stop() {
    if (!_isRecording) {
      return null;
    }
    _subscription?.cancel();
    _subscription = null;
    _tickTimer?.cancel();
    _tickTimer = null;

    final startedAt = _startedAt ?? DateTime.now();
    final endedAt = DateTime.now();
    final track = List<LatLng>.from(_track);
    final distanceMeters = _distanceMeters;
    final elevationGainMeters = _elevationGain;
    final maxSpeedMps = _maxSpeedMps;
    final durationSeconds = endedAt.difference(startedAt).inSeconds;
    final avgSpeedMps = durationSeconds > 0
        ? distanceMeters / durationSeconds
        : 0.0;

    _isRecording = false;
    _track.clear();
    _distanceMeters = 0;
    _startedAt = null;
    _elapsed = Duration.zero;
    _smoothedAltitude = null;
    _elevationGain = 0;
    _currentSpeedMps = 0;
    _maxSpeedMps = 0;
    _lastSampleAt = null;
    notifyListeners();

    return (
      startedAt: startedAt,
      endedAt: endedAt,
      track: track,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      elevationGainMeters: elevationGainMeters,
      avgSpeedMps: avgSpeedMps,
      maxSpeedMps: maxSpeedMps,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }
}

/// Full-screen route shown while a ride is being recorded. Owns the
/// session lifecycle (starts on init, stops via the Stop button or via
/// a confirm-discard flow from the close button).
class _RecordingScreen extends StatefulWidget {
  const _RecordingScreen({
    required this.session,
    required this.initialCenter,
    required this.initialZoom,
    required this.units,
  });

  final _RecordingSession session;
  final LatLng initialCenter;
  final double initialZoom;
  final UnitSystem units;

  @override
  State<_RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<_RecordingScreen> {
  final MapController _miniMapController = MapController();
  bool _autoFollow = true;
  String? _startError;
  bool _startAttempted = false;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onChange);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _startAttempted = true;
      final result = await widget.session.start();
      if (!mounted) {
        return;
      }
      setState(() {
        _startError = result.ok ? null : result.errorMessage;
      });
    });
  }

  void _onChange() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (_autoFollow && widget.session.track.isNotEmpty) {
      _miniMapController.move(
        widget.session.track.last,
        _miniMapController.camera.zoom,
      );
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onChange);
    super.dispose();
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this ride?'),
        content: const Text(
          "You'll lose the recorded track and stats. There's no undo.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep recording'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _onClosePressed() async {
    if (!widget.session.isRecording) {
      Navigator.of(context).pop();
      return;
    }
    final ok = await _confirmDiscard();
    if (!ok || !mounted) {
      return;
    }
    widget.session.stop();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _onStopPressed() {
    final stats = widget.session.stop();
    Navigator.of(context).pop(stats);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final theme = Theme.of(context);

    return PopScope(
      canPop: !session.isRecording,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _onClosePressed();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Discard and close',
            onPressed: _onClosePressed,
          ),
          title: const Text('Recording ride'),
        ),
        body: _startError != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_off, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        _startError!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              )
            : !_startAttempted || (!session.isRecording && _startAttempted)
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        const _RecordingPulseDot(),
                        const SizedBox(width: 10),
                        Text(
                          'RECORDING',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Text(
                      _formatDurationSeconds(session.elapsed.inSeconds),
                      style: TextStyle(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w800,
                        fontSize: 64,
                        color: theme.colorScheme.onSurface,
                        height: 1.0,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _GlowStatCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _BigStat(
                                value: _formatDistance(
                                  session.distanceMeters,
                                  widget.units,
                                ),
                                label: 'DISTANCE',
                              ),
                            ),
                            const _VerticalStatDivider(),
                            Expanded(
                              child: _BigStat(
                                value: session.elevationGain >= 1
                                    ? _formatElevationValue(
                                        session.elevationGain,
                                        widget.units,
                                      )
                                    : (widget.units == UnitSystem.imperial
                                          ? '0 ft'
                                          : '0 m'),
                                label: 'ELEV ↑',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _GlowStatCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _BigStat(
                                value: _formatSpeedValue(
                                  session.currentSpeedMps,
                                  widget.units,
                                ),
                                label: 'NOW ${_speedUnitLabel(widget.units)}',
                              ),
                            ),
                            const _VerticalStatDivider(),
                            Expanded(
                              child: _BigStat(
                                value: _formatSpeedValue(
                                  session.avgSpeedMps,
                                  widget.units,
                                ),
                                label: 'AVG ${_speedUnitLabel(widget.units)}',
                              ),
                            ),
                            const _VerticalStatDivider(),
                            Expanded(
                              child: _BigStat(
                                value: _formatSpeedValue(
                                  session.maxSpeedMps,
                                  widget.units,
                                ),
                                label: 'MAX ${_speedUnitLabel(widget.units)}',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _miniMapController,
                              options: MapOptions(
                                initialCenter: widget.initialCenter,
                                initialZoom: widget.initialZoom,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.all,
                                ),
                                onPositionChanged: (_, hasGesture) {
                                  if (hasGesture && _autoFollow) {
                                    setState(() => _autoFollow = false);
                                  }
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.wildhorizon',
                                ),
                                if (session.track.length >= 2)
                                  PolylineLayer(
                                    polylines: [
                                      Polyline(
                                        points: session.track,
                                        color: Colors.redAccent,
                                        strokeWidth: 5,
                                        borderStrokeWidth: 2,
                                        borderColor: Colors.white,
                                      ),
                                    ],
                                  ),
                                if (session.track.isNotEmpty)
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: session.track.last,
                                        width: 20,
                                        height: 20,
                                        child: const _RecordingPulseDot(),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            if (!_autoFollow)
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: FloatingActionButton.small(
                                  heroTag: 'follow-me-fab',
                                  onPressed: () {
                                    setState(() => _autoFollow = true);
                                    if (session.track.isNotEmpty) {
                                      _miniMapController.move(
                                        session.track.last,
                                        _miniMapController.camera.zoom,
                                      );
                                    }
                                  },
                                  tooltip: 'Follow me',
                                  child: const Icon(Icons.my_location),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: (_startError != null || !session.isRecording)
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: _PressEffect(
                    onTap: _onStopPressed,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF1744).withValues(alpha: 0.45),
                        blurRadius: 22,
                        spreadRadius: 1,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    pressedShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF1744).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    child: Container(
                      height: 60,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF5252), Color(0xFFB71C1C)],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.stop_rounded, color: Colors.white, size: 26),
                          SizedBox(width: 10),
                          Text(
                            'STOP RIDE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Wraps a child with a tactile 3D press effect: scale-down on tap and a
/// drop shadow that compresses as you push. Used for all big action buttons.
class _PressEffect extends StatefulWidget {
  const _PressEffect({
    required this.child,
    required this.onTap,
    this.boxShadow,
    this.pressedShadow,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  final Widget child;
  final VoidCallback onTap;
  final List<BoxShadow>? boxShadow;
  final List<BoxShadow>? pressedShadow;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  @override
  State<_PressEffect> createState() => _PressEffectState();
}

class _PressEffectState extends State<_PressEffect> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) {
        _setPressed(false);
        widget.onTap();
      },
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: widget.shape == BoxShape.rectangle
                ? widget.borderRadius
                : null,
            shape: widget.shape,
            boxShadow: _pressed ? widget.pressedShadow : widget.boxShadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Gradient stat card with a soft drop shadow — used on the recording
/// screen so the metrics feel like floating glass tiles.
class _GlowStatCard extends StatelessWidget {
  const _GlowStatCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerHigh,
            scheme.surfaceContainerLow,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalStatDivider extends StatelessWidget {
  const _VerticalStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(
        alpha: 0.5,
      ),
    );
  }
}

/// Modern card row for a saved ride. Shows a colored avatar, the title,
/// inline stat badges, and a delete button. Tap-to-focus is enabled when
/// the ride has a recorded GPS track.
class _RideCard extends StatelessWidget {
  const _RideCard({
    required this.ride,
    required this.units,
    required this.onDelete,
    this.onTap,
    this.onShare,
  });

  final RideEntry ride;
  final UnitSystem units;
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isRecorded = ride.hasRecordedTrack;

    final badges = <Widget>[];
    final distLabel = ride.distanceLabel(units);
    final durLabel = ride.durationLabel();
    final elevLabel = ride.elevationGainLabel(units);
    final avgLabel = ride.avgSpeedLabel(units);
    if (distLabel != null) {
      badges.add(_RideStatBadge(icon: Icons.straighten, label: distLabel));
    }
    if (durLabel != null) {
      badges.add(_RideStatBadge(icon: Icons.timer_outlined, label: durLabel));
    }
    if (elevLabel != null) {
      badges.add(_RideStatBadge(icon: Icons.terrain, label: elevLabel));
    }
    if (avgLabel != null) {
      badges.add(_RideStatBadge(icon: Icons.speed, label: avgLabel));
    }

    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerHigh,
            scheme.surfaceContainerLow,
          ],
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isRecorded
                          ? const [Color(0xFFFF5252), Color(0xFFB71C1C)]
                          : [
                              scheme.primary,
                              scheme.primary.withValues(alpha: 0.75),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (isRecorded
                                ? const Color(0xFFFF1744)
                                : scheme.primary)
                            .withValues(alpha: isDark ? 0.45 : 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isRecorded ? Icons.route : Icons.directions_bike,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            ride.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          ride.createdLabel(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (badges.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: badges,
                      ),
                    ],
                    if (ride.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        ride.notes,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
                const SizedBox(width: 4),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onShare != null)
                      IconButton(
                        tooltip: 'Share ride card',
                        icon: const Icon(Icons.ios_share),
                        onPressed: onShare,
                        visualDensity: VisualDensity.compact,
                      ),
                    IconButton(
                      tooltip: 'Remove ride',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "now" / "5m ago" / "2h ago" / "Jan 5".
String _formatRelativeTime(DateTime t) {
  final delta = DateTime.now().difference(t);
  if (delta.inSeconds < 60) return 'just now';
  if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
  if (delta.inHours < 24) return '${delta.inHours}h ago';
  return '${t.month}/${t.day}';
}

class _WeatherStat extends StatelessWidget {
  const _WeatherStat({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastDayCard extends StatelessWidget {
  const _ForecastDayCard({required this.day, required this.units});
  final WeatherDayForecast day;
  final UnitSystem units;

  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final isToday =
        day.date.year == today.year &&
        day.date.month == today.month &&
        day.date.day == today.day;
    final label = isToday ? 'Today' : _weekdayLabels[day.date.weekday - 1];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHigh,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            weatherIconFor(day.weatherCode),
            color: scheme.primary,
            size: 26,
          ),
          const SizedBox(height: 8),
          Text(
            _formatTemperature(day.tempMaxC, units),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          Text(
            _formatTemperature(day.tempMinC, units),
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (day.precipitationMm > 0.05) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.water_drop,
                  size: 10,
                  color: scheme.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 2),
                Text(
                  day.precipitationMm.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Tappable hero card on the Rides tab. Shows total progress
/// ("12 of 22 unlocked") with a gradient progress bar and a row of the
/// most-recently-unlocked badges. Tap to open the full grid.
class _AchievementsHeaderCard extends StatelessWidget {
  const _AchievementsHeaderCard({
    required this.unlockedCount,
    required this.totalCount,
    required this.recentUnlocks,
    required this.onTap,
  });

  final int unlockedCount;
  final int totalCount;
  final List<Achievement> recentUnlocks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pct = totalCount == 0 ? 0.0 : unlockedCount / totalCount;
    return _PressEffect(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6A1B9A).withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      pressedShadow: [
        BoxShadow(
          color: const Color(0xFF6A1B9A).withValues(alpha: 0.25),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E24AA), Color(0xFF311B92)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.emoji_events,
                    color: Color(0xFFFFD54F),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Achievements',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        '$unlockedCount of $totalCount unlocked',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white70,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation(
                  Color(0xFFFFD54F),
                ),
              ),
            ),
            if (recentUnlocks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final a in recentUnlocks)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: a.color.withValues(alpha: 0.7),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(a.icon, color: a.color, size: 18),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-screen view of every badge, grouped by category. Locked badges
/// are desaturated and show a tiny progress bar; tap any badge for a
/// details dialog.
class _AchievementsScreen extends StatelessWidget {
  const _AchievementsScreen({
    required this.rides,
    required this.unlocks,
  });

  final List<RideEntry> rides;
  final Map<String, DateTime> unlocks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlockedCount = kAchievements
        .where((a) => unlocks.containsKey(a.id))
        .length;
    final pct = unlockedCount / kAchievements.length;

    final categories = AchievementCategory.values;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8E24AA), Color(0xFF311B92)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Color(0xFFFFD54F),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$unlockedCount of ${kAchievements.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
                Text(
                  unlockedCount == 0
                      ? 'Save a ride to unlock your first badge.'
                      : 'Keep riding to unlock the rest!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(
                      Color(0xFFFFD54F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          for (final cat in categories) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
              child: Text(
                cat.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
              children: [
                for (final a in kAchievements.where((x) => x.category == cat))
                  _AchievementTile(
                    achievement: a,
                    progress: a.progress(rides),
                    unlockedAt: unlocks[a.id],
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.progress,
    required this.unlockedAt,
  });

  final Achievement achievement;
  final AchievementProgress progress;
  final DateTime? unlockedAt;

  void _showDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final unlocked = progress.isUnlocked;
        return AlertDialog(
          icon: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: achievement.color.withValues(
                alpha: unlocked ? 0.2 : 0.08,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: achievement.color.withValues(
                  alpha: unlocked ? 0.7 : 0.25,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              achievement.icon,
              color: unlocked
                  ? achievement.color
                  : Theme.of(dialogContext).colorScheme.onSurfaceVariant,
              size: 32,
            ),
          ),
          title: Text(
            achievement.title,
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                achievement.description,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.percent,
                  minHeight: 6,
                  backgroundColor: Theme.of(
                    dialogContext,
                  ).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(achievement.color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatAchievementProgress(achievement, progress),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
              if (unlocked && unlockedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Unlocked ${_formatRelativeTime(unlockedAt!)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      dialogContext,
                    ).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unlocked = progress.isUnlocked;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: unlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      achievement.color.withValues(
                        alpha: isDark ? 0.32 : 0.18,
                      ),
                      scheme.surfaceContainerHigh,
                    ],
                  )
                : null,
            border: Border.all(
              color: unlocked
                  ? achievement.color.withValues(alpha: 0.5)
                  : scheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: unlocked
                      ? achievement.color.withValues(alpha: 0.22)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: unlocked
                      ? [
                          BoxShadow(
                            color: achievement.color.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Icon(
                  achievement.icon,
                  color: unlocked
                      ? achievement.color
                      : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: unlocked
                      ? scheme.onSurface
                      : scheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              if (unlocked)
                Text(
                  'UNLOCKED',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: achievement.color,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress.percent,
                      minHeight: 3,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        achievement.color.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal sheet for choosing what location the weather should follow.
/// Three sources: city search (Open-Meteo geocoding), device GPS, or the
/// current map view. Calls back when the user picks something.
class _WeatherLocationPickerSheet extends StatefulWidget {
  const _WeatherLocationPickerSheet({
    required this.currentPin,
    required this.onSearch,
    required this.onPick,
    required this.onUseGps,
    required this.onFollowMap,
  });

  final WeatherLocation? currentPin;
  final Future<List<WeatherLocation>> Function(String query) onSearch;
  final ValueChanged<WeatherLocation> onPick;
  final VoidCallback onUseGps;
  final VoidCallback onFollowMap;

  @override
  State<_WeatherLocationPickerSheet> createState() =>
      _WeatherLocationPickerSheetState();
}

class _WeatherLocationPickerSheetState
    extends State<_WeatherLocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  String _lastQuery = '';
  List<WeatherLocation> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      _runSearch(value);
    });
  }

  Future<void> _runSearch(String value) async {
    final query = value.trim();
    if (query == _lastQuery && _results.isNotEmpty) return;
    _lastQuery = query;
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    final results = await widget.onSearch(query);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Weather location',
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: _onQueryChanged,
                      onSubmitted: _runSearch,
                      decoration: InputDecoration(
                        hintText: 'Search city, town, place\u2026',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onQueryChanged('');
                                },
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                      children: [
                        _PickerTile(
                          icon: Icons.my_location,
                          color: Colors.redAccent,
                          title: 'Use my GPS location',
                          subtitle: 'Detect where you are right now',
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onUseGps();
                          },
                        ),
                        _PickerTile(
                          icon: Icons.map_outlined,
                          color: scheme.primary,
                          title: widget.currentPin == null
                              ? 'Following map (current)'
                              : 'Follow the map view',
                          subtitle:
                              'Weather updates as you pan and zoom',
                          trailingCheck: widget.currentPin == null,
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onFollowMap();
                          },
                        ),
                        if (_results.isNotEmpty ||
                            _searching ||
                            _lastQuery.isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Text(
                              'SEARCH RESULTS',
                              style: TextStyle(
                                fontSize: 11,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        if (_searching)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        else if (_results.isEmpty &&
                            _lastQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            child: Text(
                              'No matches found',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          for (final r in _results)
                            _PickerTile(
                              icon: Icons.location_on_outlined,
                              color: scheme.tertiary,
                              title: r.name,
                              subtitle: [
                                if (r.admin != null) r.admin!,
                                if (r.country != null) r.country!,
                              ].join(' · '),
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onPick(r);
                              },
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingCheck = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool trailingCheck;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailingCheck)
                  Icon(Icons.check, color: scheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glassy gradient weather chip shown on the Map tab. Color is driven by
/// the current WMO weather code so the chip "looks like" the conditions —
/// warm for sun, deep blue for night, gray for fog, etc. Tap to open the
/// full 3-day forecast sheet.
class _WeatherChip extends StatelessWidget {
  const _WeatherChip({
    required this.snapshot,
    required this.units,
    required this.onTap,
    required this.isLoading,
  });

  final WeatherSnapshot snapshot;
  final UnitSystem units;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final gradient = weatherGradientFor(
      snapshot.weatherCode,
      isDay: snapshot.isDay,
    );
    final icon = weatherIconFor(snapshot.weatherCode, isDay: snapshot.isDay);
    final label = weatherLabelFor(snapshot.weatherCode);
    final tempStr = _formatTemperature(snapshot.tempC, units);

    return _PressEffect(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: gradient.last.withValues(alpha: 0.45),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      pressedShadow: [
        BoxShadow(
          color: gradient.last.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tempStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            if (isLoading) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RideStatBadge extends StatelessWidget {
  const _RideStatBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shareable ride card
// ---------------------------------------------------------------------------

/// Renders a recorded GPS track as standalone "trail art": a glowing
/// polyline centered in its bounding box, with start/end dots. Uses a
/// rough Mercator x-scale so the shape doesn't look squashed at higher
/// latitudes.
class _RouteShapePainter extends CustomPainter {
  _RouteShapePainter({
    required this.points,
    required this.color,
  });

  final List<LatLng> points;
  final Color color;
  static const double _padding = 28;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    var minLat = points.first.latitude;
    var maxLat = minLat;
    var minLng = points.first.longitude;
    var maxLng = minLng;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final cosLat = math.cos(
      ((minLat + maxLat) / 2) * math.pi / 180,
    );
    final spanLat = (maxLat - minLat).abs();
    final spanLng = (maxLng - minLng).abs() * cosLat;
    if (spanLat == 0 || spanLng == 0) return;

    final w = size.width - 2 * _padding;
    final h = size.height - 2 * _padding;
    final scale = math.min(w / spanLng, h / spanLat);

    // Center the bounding box inside the canvas.
    final renderedW = spanLng * scale;
    final renderedH = spanLat * scale;
    final ox = _padding + (w - renderedW) / 2;
    final oy = _padding + (h - renderedH) / 2;

    Offset project(LatLng p) {
      final x = (p.longitude - minLng) * cosLat * scale;
      final y = (maxLat - p.latitude) * scale;
      return Offset(ox + x, oy + y);
    }

    final routePath = ui.Path();
    routePath.moveTo(project(points.first).dx, project(points.first).dy);
    for (var i = 1; i < points.length; i++) {
      final o = project(points[i]);
      routePath.lineTo(o.dx, o.dy);
    }

    final glow = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 5;

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.4;

    canvas.drawPath(routePath, glow);
    canvas.drawPath(routePath, stroke);
    canvas.drawPath(routePath, highlight);

    final start = project(points.first);
    final end = project(points.last);

    // Start dot — bright green with white halo.
    canvas.drawCircle(
      start,
      9,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      start,
      6,
      Paint()..color = const Color(0xFF66BB6A),
    );

    // End dot — checkered flag color with white halo.
    canvas.drawCircle(
      end,
      9,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      end,
      6,
      Paint()..color = const Color(0xFFFF5252),
    );
  }

  @override
  bool shouldRepaint(covariant _RouteShapePainter old) =>
      old.points != points || old.color != color;
}

/// The visual share card. Designed to be rendered offscreen-able inside a
/// `RepaintBoundary` and exported to PNG. Always uses dark colors so the
/// captured image looks the same regardless of the app's current theme.
class _RideSummaryCard extends StatelessWidget {
  const _RideSummaryCard({
    required this.ride,
    required this.units,
    required this.unlockedAchievements,
  });

  final RideEntry ride;
  final UnitSystem units;
  final List<Achievement> unlockedAchievements;

  static const _bgDark = Color(0xFF0E1A12);
  static const _bgMid = Color(0xFF132A1B);
  static const _accent = Color(0xFF86E96B);
  static const _accentSoft = Color(0xFFB6F2A1);

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatRideDate(ride.createdAt);
    final stats = <_SummaryStat>[
      _SummaryStat(
        label: 'Distance',
        value: ride.distanceLabel(units) ?? '—',
        icon: Icons.straighten,
      ),
      _SummaryStat(
        label: 'Time',
        value: ride.durationLabel() ?? '—',
        icon: Icons.timer_outlined,
      ),
      _SummaryStat(
        label: 'Elev gain',
        value: ride.elevationGainLabel(units) ?? '—',
        icon: Icons.terrain,
      ),
      _SummaryStat(
        label: 'Avg speed',
        value: ride.avgSpeedLabel(units) ?? '—',
        icon: Icons.speed,
      ),
    ];

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgMid, _bgDark],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accent.withValues(alpha: 0.18),
                      _accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.terrain,
                        color: _accent,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'WILDHORIZON',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    ride.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.06),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                        ),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: ride.hasRecordedTrack
                          ? CustomPaint(
                              painter: _RouteShapePainter(
                                points: ride.track,
                                color: _accentSoft,
                              ),
                              child: const SizedBox.expand(),
                            )
                          : const Center(
                              child: Icon(
                                Icons.directions_bike,
                                color: _accent,
                                size: 64,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _summaryStatTile(stats[0])),
                      const SizedBox(width: 10),
                      Expanded(child: _summaryStatTile(stats[1])),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _summaryStatTile(stats[2])),
                      const SizedBox(width: 10),
                      Expanded(child: _summaryStatTile(stats[3])),
                    ],
                  ),
                  if (unlockedAchievements.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Color(0xFFFFD54F),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          for (final a in unlockedAchievements.take(4))
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      a.color.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: a.color.withValues(alpha: 0.7),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  a.icon,
                                  color: a.color,
                                  size: 18,
                                ),
                              ),
                            ),
                          if (unlockedAchievements.length > 4)
                            Text(
                              '+${unlockedAchievements.length - 4}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStatTile(_SummaryStat s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(s.icon, color: _accent, size: 14),
              const SizedBox(width: 6),
              Text(
                s.label.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
}

/// "Sun, Jun 28 · 3:14 PM"
String _formatRideDate(DateTime t) {
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final day = dayNames[t.weekday - 1];
  final mon = monthNames[t.month - 1];
  var hour = t.hour % 12;
  if (hour == 0) hour = 12;
  final am = t.hour < 12 ? 'AM' : 'PM';
  final mins = t.minute.toString().padLeft(2, '0');
  return '$day, $mon ${t.day} · $hour:$mins $am';
}

/// Hosts the shareable [_RideSummaryCard] inside a `RepaintBoundary` so
/// the user can capture it as a PNG (saved to ~/Pictures/WildHorizon on
/// macOS). The screen itself is dark to match the card's design.
class _RideShareScreen extends StatefulWidget {
  const _RideShareScreen({
    required this.ride,
    required this.units,
    required this.unlockedAchievements,
  });

  final RideEntry ride;
  final UnitSystem units;
  final List<Achievement> unlockedAchievements;

  @override
  State<_RideShareScreen> createState() => _RideShareScreenState();
}

class _RideShareScreenState extends State<_RideShareScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _saving = false;

  Future<void> _onSave() async {
    if (_saving) return;
    setState(() => _saving = true);

    File? savedFile;
    String? error;
    try {
      final bytes = await _captureCardAsPng();
      if (bytes == null) {
        error = 'Could not capture image';
      } else {
        savedFile = await _saveCardToDisk(bytes);
      }
    } catch (e) {
      error = 'Save failed: $e';
    }

    if (!mounted) return;
    setState(() => _saving = false);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (error != null || savedFile == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error ?? 'Could not save image')),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text('Saved to ${savedFile.path}'),
        action: Platform.isMacOS
            ? SnackBarAction(
                label: 'Show in Finder',
                onPressed: () {
                  Process.run('open', ['-R', savedFile!.path]);
                },
              )
            : null,
      ),
    );
  }

  Future<Uint8List?> _captureCardAsPng() async {
    // Let any pending layout/paint finish before reading the pixels.
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _cardKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    return byteData?.buffer.asUint8List();
  }

  Future<File?> _saveCardToDisk(Uint8List bytes) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = widget.ride.name
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .toLowerCase();
    final filename = 'wildhorizon_${safeName}_$stamp.png';

    Directory dir;
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        dir = Directory('$home/Pictures/WildHorizon');
      } else {
        dir = Directory.systemTemp;
      }
    } else {
      dir = Directory.systemTemp;
    }
    await dir.create(recursive: true);
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A07),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050A07),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Share ride'),
        actions: [
          IconButton(
            tooltip: 'Save image',
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.ios_share),
            onPressed: _saving ? null : _onSave,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _RideSummaryCard(
                    ride: widget.ride,
                    units: widget.units,
                    unlockedAchievements: widget.unlockedAchievements,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _PressEffect(
            onTap: _onSave,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF86E96B).withValues(alpha: 0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            pressedShadow: [
              BoxShadow(
                color: const Color(0xFF86E96B).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF86E96B), Color(0xFF2E7D32)],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ios_share, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    Platform.isMacOS ? 'Save to Pictures' : 'Save image',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
