# Graph Report - SurvivalCalc  (2026-09-02)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 1260 nodes · 1900 edges · 62 communities (61 shown, 1 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `4d413ea6`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Community 0
- Community 1
- Community 2
- Community 3
- Community 4
- Community 5
- Community 6
- Community 7
- Community 8
- Community 9
- Community 10
- Community 11
- Community 12
- Community 13
- Community 14
- Community 15
- Community 16
- Community 17
- Community 18
- Community 19
- Community 20
- Community 21
- Community 22
- Community 23
- Community 24
- Community 25
- Community 26
- Community 27
- Community 28
- Community 29
- Community 30
- Community 31
- Community 32
- Community 33
- Community 34
- Community 35
- Community 36
- Community 37
- Community 38
- Community 39
- Community 40
- Community 41
- Community 42
- Community 43
- Community 44
- Community 45
- Community 46
- Community 47
- Community 48
- Community 49
- Community 50
- Community 51
- Community 52
- Community 53
- Community 54
- Community 55
- Community 56
- Community 57
- Community 58
- Community 59
- Community 60
- Community 61

## God Nodes (most connected - your core abstractions)
1. `activeTripProfileProvider` - 24 edges
2. `groupParticipantsProvider` - 21 edges
3. `trackingProvider` - 18 edges
4. `calculationResultProvider` - 17 edges
5. `plannedRouteProvider` - 10 edges
6. `_SaveTripDialogState` - 9 edges
7. `_MkkExportSheetState` - 9 edges
8. `_TrackHistorySheetState` - 8 edges
9. `_TripSetupScreenState` - 8 edges
10. `TripProfile` - 8 edges

## Surprising Connections (you probably didn't know these)
- `_confirmClearSandbox` --references--> `trackingProvider`  [EXTRACTED]
  lib/features/tracking/presentation/widgets/track_history_sheet.dart → lib/features/tracking/presentation/providers/tracking_providers.dart
- `_confirmDeleteTrack` --references--> `trackingProvider`  [EXTRACTED]
  lib/features/tracking/presentation/widgets/track_history_sheet.dart → lib/features/tracking/presentation/providers/tracking_providers.dart
- `build` --references--> `plannedRouteProvider`  [EXTRACTED]
  lib/features/tracking/presentation/widgets/offline_maps_sheet.dart → lib/features/tracking/presentation/providers/planned_route_providers.dart
- `_OfflineMapsSheetState` --references--> `plannedRouteProvider`  [EXTRACTED]
  lib/features/tracking/presentation/widgets/offline_maps_sheet.dart → lib/features/tracking/presentation/providers/planned_route_providers.dart
- `QrSyncService` --references--> `trackingProvider`  [EXTRACTED]
  lib/core/services/qr_sync_service.dart → lib/features/tracking/presentation/providers/tracking_providers.dart

## Import Cycles
- None detected.

## Communities (62 total, 1 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.03
Nodes (66): addFoodItem, addGearItem, addParticipant, allGearProvider, availableFoodsProvider, calculate, checkedMap, clear (+58 more)

### Community 1 - "Community 1"
Cohesion: 0.04
Nodes (50): activeTrack, activeTrip, addCampNoteToActiveTrack, addWaypoint, checkAndRequestPermission, clearSandboxTracks, completedTracksProvider, copyWith (+42 more)

### Community 2 - "Community 2"
Cohesion: 0.05
Nodes (47): dart:async, LatLng, _buildTileUrl, cancel, _concurrency, downloaded, DownloadProgress, downloadTiles (+39 more)

### Community 3 - "Community 3"
Cohesion: 0.04
Nodes (44): int get, calories, carbsG, copyWith, DailyMealSlot, DailyRation, dayNumber, dutyParticipantIds (+36 more)

### Community 4 - "Community 4"
Cohesion: 0.05
Nodes (42): BoxFit, double?, alertRed, borderActive, borderSubtle, darkBackground, electricCyan, OutdoorTheme (+34 more)

### Community 5 - "Community 5"
Cohesion: 0.05
Nodes (38): FoodCategory, caloricDensity, calories100g, carbs100g, category, copyWith, fat100g, FoodItem (+30 more)

### Community 6 - "Community 6"
Cohesion: 0.05
Nodes (37): dart:typed_data, Font?, downloadFileToDevice, file, filePath, layoutPdf, openPdfInViewer, tempDir (+29 more)

### Community 7 - "Community 7"
Cohesion: 0.05
Nodes (36): double get, bmr, carbsCalPercent, coldBonusKcal, dailyCalories, dailyCarbsG, dailyEquivalentKm, dailyFatG (+28 more)

### Community 8 - "Community 8"
Cohesion: 0.07
Nodes (37): showQrShareModal, plannedRouteProvider, trackingProvider, build, _buildBottomControls, _buildHudHeader, _buildHudStat, _buildStartFinishMarkers (+29 more)

### Community 9 - "Community 9"
Cohesion: 0.06
Nodes (32): trackStorageRepositoryProvider, _addNote, build, _buildBackpackMeltCard, _buildElevationChart, _buildHydrationCard, _buildMetabolicBalanceCard, _buildMetricTile (+24 more)

### Community 10 - "Community 10"
Cohesion: 0.07
Nodes (28): copyToClipboard, ExportService, generateMarkdownReport, shareReport, campNotes, decodeTripProfile, decodeTripSnapshot, encodeTripProfile (+20 more)

### Community 11 - "Community 11"
Cohesion: 0.06
Nodes (30): centerLat, centerLon, clearAllTiles, createdAt, deleteRegion, fromJson, fromMap, getSavedRegions (+22 more)

### Community 12 - "Community 12"
Cohesion: 0.10
Nodes (23): calculate, gearCalculatorService, metabolicCalculator, rationGeneratorService, TripCalculatorEngine, calculateGearWeights, filterAndScaleGear, GearCalculatorService (+15 more)

### Community 13 - "Community 13"
Cohesion: 0.08
Nodes (25): Animation, AnimationController, CustomPainter, _animController, build, _controller, createState, dispose (+17 more)

### Community 14 - "Community 14"
Cohesion: 0.08
Nodes (25): _buildDailyEssentialsCard, _buildEssentialItem, _buildGearCategoriesPieChart, _buildHeroWeightCard, _buildMacroBar, _buildMacroNutrientPieChart, _buildMiniStatCard, _buildNutrientCard (+17 more)

### Community 15 - "Community 15"
Cohesion: 0.08
Nodes (25): CampDebrief, avgMovingSpeedKmh, copyWith, DailyTrack, dayIndex, debrief, elevationGainMeters, elevationLossMeters (+17 more)

### Community 16 - "Community 16"
Cohesion: 0.08
Nodes (24): all,
  summer,
  spring_autumn,, asthma,
  joint_pain,
  insect_allergy,
  hypertension,, breakfast,
  lunch_snack,
  dinner,, electronics,
  med_hygiene,
  clothing,
  packs,, grains,
  proteins,
  fats,
  snacks,, hiking,
  mountain,
  water,, badgeTitle, basics (+16 more)

### Community 17 - "Community 17"
Cohesion: 0.08
Nodes (24): bool get, assignedFood, assignedGear, contactPhone, copyWith, dietaryRestrictions, displayName, fromMap (+16 more)

### Community 18 - "Community 18"
Cohesion: 0.08
Nodes (24): ActivityType, Season, activeDays, activityType, avgParticipantWeightKg, clubOrCity, copyWith, createdAt (+16 more)

### Community 19 - "Community 19"
Cohesion: 0.08
Nodes (24): actualAscentMeters, actualCaloriesBurned, actualDescentMeters, actualDistanceKm, avgMovingSpeedKmh, calorieDelta, copyWith, dailyFoodWeightConsumedG (+16 more)

### Community 20 - "Community 20"
Cohesion: 0.10
Nodes (21): TripCalculationResult, createExpeditionZip, ExpeditionArchiveService, _buildDocCard, createState, _isExportingZip, _isGeneratingPassport, _isGeneratingReport (+13 more)

### Community 21 - "Community 21"
Cohesion: 0.12
Nodes (23): AsyncValue, QrSyncService, showQrImportModal, activeTripProfileProvider, customGearProvider, gearCheckedStateProvider, groupParticipantsProvider, build (+15 more)

### Community 22 - "Community 22"
Cohesion: 0.10
Nodes (21): customFoodProvider, _buildDailyMenuTab, _buildFilterChip, _buildHeaderStat, _buildMealSlotCard, _buildShoppingListTab, _categoryScrollController, createState (+13 more)

### Community 23 - "Community 23"
Cohesion: 0.11
Nodes (17): _escapeXml, exportTrackToGpx, GpxExporter, package:flutter_test/flutter_test.dart, package:survival_calc/core/services/qr_sync_service.dart, package:survival_calc/features/tracking/domain/models/camp_debrief.dart, package:survival_calc/features/tracking/domain/models/daily_camp_note.dart, package:survival_calc/features/tracking/domain/models/daily_track.dart (+9 more)

### Community 24 - "Community 24"
Cohesion: 0.10
Nodes (19): description, fromJson, fromMap, id, importedAt, maxLat, maxLon, minLat (+11 more)

### Community 25 - "Community 25"
Cohesion: 0.12
Nodes (15): dart:convert, AssetFoodRepository, _assetPath, _cachedFoods, FoodRepository, loadFoods, saveCustomFood, package:survival_calc/features/gear/data/repositories/gear_repository.dart (+7 more)

### Community 26 - "Community 26"
Cohesion: 0.11
Nodes (18): GearCategory, GearSeason, GearType, category, copyWith, fromMap, GearItem, id (+10 more)

### Community 27 - "Community 27"
Cohesion: 0.11
Nodes (17): checkedGearIds, copyWith, createdAt, customFoods, customGear, fromJson, fromMap, id (+9 more)

### Community 28 - "Community 28"
Cohesion: 0.11
Nodes (17): _buildBadge, _buildRealTripsTab, _buildSystemPresetCard, _buildTemplatesTab, _buildTripCard, createState, description, dispose (+9 more)

### Community 29 - "Community 29"
Cohesion: 0.12
Nodes (16): altitude, authorName, authorRole, copyWith, fromJson, id, latitude, longitude (+8 more)

### Community 30 - "Community 30"
Cohesion: 0.13
Nodes (15): Color, _buildFilterChip, _categoryScrollController, createState, dispose, GearChecklistScreen, _GearChecklistScreenState, _hintTimer (+7 more)

### Community 31 - "Community 31"
Cohesion: 0.18
Nodes (12): calculate, MetabolicCalculator, CampDebriefCalculator, generateDebrief, metabolicCalculator, package:survival_calc/core/enums/trip_enums.dart, package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart, package:survival_calc/features/calculator/domain/services/metabolic_calculator.dart (+4 more)

### Community 32 - "Community 32"
Cohesion: 0.13
Nodes (15): build, createState, _currentIndex, _hideWebBanner, MainNavigationScreen, _MainNavigationScreenState, _switchTab, package:survival_calc/features/dashboard/presentation/screens/dashboard_screen.dart (+7 more)

### Community 33 - "Community 33"
Cohesion: 0.12
Nodes (15): createState, _deletePhoto, dispose, initState, _isProcessingImage, _mediaService, _noteController, _photoBytes (+7 more)

### Community 34 - "Community 34"
Cohesion: 0.13
Nodes (15): _autoApplyToProfile, build, _buildRoutePreviewCard, _buildStatItem, createState, _errorMessage, GpxImportDialog, _GpxImportDialogState (+7 more)

### Community 35 - "Community 35"
Cohesion: 0.15
Nodes (15): allAsync, deleteEntry, duplicateEntry, loadAll, maybeWhen, _repo, saveCurrent, savedRealTripsProvider (+7 more)

### Community 36 - "Community 36"
Cohesion: 0.22
Nodes (15): ConsumerState, ConsumerStatefulWidget, participantsProvider, tripCalculationResultProvider, tripProfileProvider, build, MkkExportSheet, _MkkExportSheetState (+7 more)

### Community 37 - "Community 37"
Cohesion: 0.13
Nodes (14): TripRole, authorName, authorRole, copyWith, createdAt, DailyCampNote, dayNumber, fromJson (+6 more)

### Community 38 - "Community 38"
Cohesion: 0.14
Nodes (13): dart:ui, tripRepositoryProvider, build, dragDevices, init, initialProfile, main, OutdoorScrollBehavior (+5 more)

### Community 39 - "Community 39"
Cohesion: 0.20
Nodes (14): calculationResultProvider, exportServiceProvider, qrSyncServiceProvider, build, DashboardScreen, _DashboardScreenState, build, _showEditParticipantDialog (+6 more)

### Community 40 - "Community 40"
Cohesion: 0.15
Nodes (13): _buildQuickStat, createState, dispose, onCalculatePressed, _titleController, TripSetupScreen, _TripSetupScreenState, package:latlong2/latlong.dart (+5 more)

### Community 41 - "Community 41"
Cohesion: 0.15
Nodes (12): clearSandboxTracks, deleteTrack, getActiveTrack, getCompletedTracks, _getPrefs, getSandboxTracks, getTracksForTrip, _keyActiveTrack (+4 more)

### Community 42 - "Community 42"
Cohesion: 0.17
Nodes (11): createState, dispose, disposeWidget, initialIsTemplate, _isSaving, _isTemplate, _noteController, show (+3 more)

### Community 43 - "Community 43"
Cohesion: 0.22
Nodes (10): class, loadDistributionServiceProvider, build, _buildHeaderStat, createState, initState, LoadDistributionScreen, _LoadDistributionScreenState (+2 more)

### Community 44 - "Community 44"
Cohesion: 0.18
Nodes (10): DateTime, accuracy, altitude, fromJson, GpsPoint, latitude, longitude, speedKmh (+2 more)

### Community 45 - "Community 45"
Cohesion: 0.18
Nodes (10): ImagePicker, deleteImage, getImageBytes, MediaStorageService, pickAndSaveImage, _picker, _webImageCache, package:image_picker/image_picker.dart (+2 more)

### Community 46 - "Community 46"
Cohesion: 0.27
Nodes (10): CustomFoodNotifier, CustomGearNotifier, GearCheckedNotifier, GroupParticipantsNotifier, TripProfileNotifier, OfflineRegionsNotifier, TripProfile, List (+2 more)

### Community 47 - "Community 47"
Cohesion: 0.20
Nodes (8): TrackStorageRepository, package:shared_preferences/shared_preferences.dart, package:survival_calc/features/tracking/data/repositories/track_storage_repository.dart, package:survival_calc/features/trip_storage/data/repositories/saved_trips_repository.dart, package:survival_calc/features/trip_storage/domain/models/saved_trip_entry.dart, main, repository, main

### Community 48 - "Community 48"
Cohesion: 0.20
Nodes (9): clearAll, clearPlannedRoute, deleteRegion, importFromGpx, _loadSaved, _plannedRoutePrefKey, refresh, setPlannedRoute (+1 more)

### Community 49 - "Community 49"
Cohesion: 0.20
Nodes (9): CachedTileProvider, fallbackUrlTemplate, getImage, getTileUrl, package:flutter/foundation.dart, package:flutter_map/flutter_map.dart, package:flutter/widgets.dart, package:survival_calc/features/tracking/data/repositories/offline_tile_repository.dart (+1 more)

### Community 50 - "Community 50"
Cohesion: 0.20
Nodes (9): deleteEntry, duplicateEntry, _getPrefs, loadAll, _prefs, SavedTripsRepository, saveEntry, _storageKey (+1 more)

### Community 51 - "Community 51"
Cohesion: 0.22
Nodes (8): charset, generatePostTripReportMarkdown, generatePreTripPassportMarkdown, lang, markdownToHtml, MkkMarkdownGenerator, name, package:intl/intl.dart

### Community 52 - "Community 52"
Cohesion: 0.22
Nodes (8): _buildTrackList, _confirmClearSandbox, _confirmDeleteTrack, createState, _formatDuration, _selectedTab, package:survival_calc/core/theme/outdoor_theme.dart, package:survival_calc/features/tracking/presentation/widgets/camp_debrief_sheet.dart

### Community 53 - "Community 53"
Cohesion: 0.25
Nodes (7): dart:math, _calculateHaversineDistance, _degreesToRadians, GpxRouteParser, parseGpx, package:survival_calc/features/tracking/domain/models/planned_route.dart, package:xml/xml.dart

### Community 54 - "Community 54"
Cohesion: 0.25
Nodes (7): calculateElevationProfile, calculateTotalDistanceKm, _degreesToRadians, distanceBetweenMeters, DistanceCalculator, earthRadiusMeters, static const double

### Community 55 - "Community 55"
Cohesion: 0.29
Nodes (6): dart:html, anchor, blob, downloadFileToDevice, openPdfInViewer, url

### Community 56 - "Community 56"
Cohesion: 0.29
Nodes (6): dart:io, package:survival_calc/features/tracking/domain/services/gpx_route_parser.dart, package:survival_calc/features/tracking/domain/services/tile_math_utils.dart, lat, main, version

### Community 57 - "Community 57"
Cohesion: 0.40
Nodes (4): file_saver_stub.dart, FileSaverService, openPdfInViewer, saveAndShareFile

### Community 58 - "Community 58"
Cohesion: 0.50
Nodes (4): campDebriefCalculatorProvider, distanceCalculatorProvider, TrackingNotifier, TrackingState

### Community 59 - "Community 59"
Cohesion: 0.50
Nodes (3): package:flutter_riverpod/flutter_riverpod.dart, package:survival_calc/main.dart, main

### Community 60 - "Community 60"
Cohesion: 0.50
Nodes (3): package:survival_calc/features/tracking/domain/models/gps_point.dart, package:survival_calc/features/tracking/domain/services/distance_calculator.dart, main

## Knowledge Gaps
- **857 isolated node(s):** `addFoodItem`, `addGearItem`, `addParticipant`, `allGearProvider`, `availableFoodsProvider` (+852 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 930 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `TripRole` connect `Community 37` to `Community 33`, `Community 9`, `Community 16`, `Community 17`, `Community 29`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **Why does `TripProfile` connect `Community 46` to `Community 5`, `Community 7`, `Community 10`, `Community 18`, `Community 20`, `Community 27`, `Community 28`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **Why does `GpsPoint` connect `Community 44` to `Community 1`?**
  _High betweenness centrality (0.009) - this node is a cross-community bridge._
- **What connects `addFoodItem`, `addGearItem`, `addParticipant` to the rest of the system?**
  _857 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.029850746268656716 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.04591836734693878 - nodes in this community are weakly interconnected._