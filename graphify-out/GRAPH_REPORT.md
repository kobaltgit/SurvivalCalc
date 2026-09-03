# Graph Report - SurvivalCalc  (2026-09-03)

## Corpus Check
- 115 files · ~96,711 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1459 nodes · 2255 edges · 77 communities (75 shown, 2 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Lib Features Calculator Presentation Providers Calculator Providers Module (68 nodes)
- Lib Features Tracking Presentation Providers Tracking Providers Module (51 nodes)
- Dart Typed Data Module (49 nodes)
- Color Module (46 nodes)
- Latlng Module (46 nodes)
- Lib Core Enums Trip Enums Foodcategory Module (44 nodes)
- Double Get Module (40 nodes)
- Lib Core Services Export Service Module (39 nodes)
- Lib Features Wiki Data Wiki Repository Module (38 nodes)
- Dart Async Module (37 nodes)
- Lib Features Calculator Domain Services Metabolic Calculator Module (35 nodes)
- Lib Features Trip Setup Domain Models Trip Profile Module (35 nodes)
- Lib Features Calculator Domain Models Trip Calculation Result Tripcalculationresult Module (33 nodes)
- Lib Features Ration Domain Models Daily Ration Module (31 nodes)
- Lib Features Tracking Data Repositories Offline Tile Repository Module (31 nodes)
- Bool Get Module (30 nodes)
- Lib Features Tracking Presentation Screens Tracking Screen Module (30 nodes)
- All Summer Spring Autumn Module (29 nodes)
- Lib Features Tracking Domain Models Camp Debrief Campdebrief Module (26 nodes)
- Lib Features Tracking Domain Models Camp Debrief Module (25 nodes)
- Lib Features Tracking Domain Services Camp Debrief Calculator Module (23 nodes)
- Animation Module (19 nodes)
- Lib Core Enums Trip Enums Gearcategory Module (19 nodes)
- Lib Features Trip Storage Domain Models Saved Trip Entry Module (19 nodes)
- Lib Features Trip Storage Presentation Widgets Trip Library Sheet Module (19 nodes)
- Dart Io Module (18 nodes)
- Lib Features Calculator Presentation Providers Calculator Providers Participantsprovider Module (18 nodes)
- Lib Features Tracking Data Repositories Track Storage Repository Module (18 nodes)
- Lib Features Tracking Domain Models Planned Route Module (18 nodes)
- Lib Features Tracking Presentation Widgets Add Waypoint Dialog Module (18 nodes)
- Lib Core Services Qr Sync Service Module (17 nodes)
- Lib Core Theme Outdoor Theme Module (17 nodes)
- Lib Features Calculator Presentation Providers Calculator Providers Calculationresultprovider Module (17 nodes)
- Lib Features Tracking Domain Models Way Point Module (17 nodes)
- Asyncvalue Module (16 nodes)
- Lib Core Enums Trip Enums Triprole Module (16 nodes)
- Lib Features Tracking Presentation Widgets Gpx Import Dialog Module (16 nodes)
- Consumerstate Module (15 nodes)
- Int Get Module (15 nodes)
- Lib Features Home Presentation Screens Main Navigation Screen Module (15 nodes)
- Class Module (14 nodes)
- Lib Core Services Qr Sync Service Qrsyncservice Module (14 nodes)
- Lib Core Widgets App Logo Applogo Module (14 nodes)
- Lib Features Tracking Domain Services Gpx Intent Service Module (14 nodes)
- Lib Features Trip Setup Presentation Screens Trip Setup Screen Module (14 nodes)
- Lib Features Trip Storage Presentation Providers Saved Trips Providers Module (14 nodes)
-  Module (13 nodes)
- Dart Ui Module (12 nodes)
- Lib Features Trip Setup Domain Models Planned Day Schedule Module (12 nodes)
- Lib Features Trip Storage Presentation Widgets Save Trip Dialog Module (12 nodes)
- Lib Features Wiki Domain Models Wiki Article Wikiarticle Module (12 nodes)
- Datetime Module (11 nodes)
- Imagepicker Module (11 nodes)
- Lib Features Tracking Domain Models Planned Route Plannedroute Module (11 nodes)
- Lib Features Tracking Domain Models Way Point Waypoint Module (10 nodes)
- Lib Features Tracking Domain Services Gpx Route Parser Module (10 nodes)
- Lib Features Tracking Presentation Widgets Cached Tile Provider Module (10 nodes)
- Lib Features Trip Storage Data Repositories Saved Trips Repository Module (10 nodes)
- Dart Math Module (9 nodes)
- Lib Core Utils Polyline Utils Module (9 nodes)
- Lib Features Mkk Reports Domain Services Mkk Markdown Generator Module (9 nodes)
- Lib Features Tracking Domain Models Map Layer Type Module (9 nodes)
- Lib Features Trip Setup Presentation Dialogs Planned Itinerary Dialog Module (9 nodes)
- Lib Features Wiki Presentation Widgets Wiki Callout Box Module (9 nodes)
- Dart Convert Module (8 nodes)
- Lib Core Widgets Fullscreen Qr Dialog Module (8 nodes)
- Lib Features Calculator Presentation Providers Calculator Providers Customfoodnotifier Module (8 nodes)
- Lib Features Gear Data Repositories Gear Repository Module (8 nodes)
- Lib Features Tracking Presentation Widgets Map Layer Selector Sheet Module (8 nodes)
- Dart Html Module (6 nodes)
- File Saver Stub Dart Module (5 nodes)
- Lib Core Widgets Qr Scanner Dialog Qrscannerdialog Module (5 nodes)
- Lib Features Trip Storage Presentation Providers Saved Trips Providers Savedrealtripsprovider Module (5 nodes)
- Lib Features Tracking Presentation Providers Tracking Providers Campdebriefcalculatorprovider Module (4 nodes)
- Package Flutter Riverpod Flutter Riverpod Dart Module (4 nodes)
- Lib Core Services File Saver Stub Module (3 nodes)
- Custompainter Module (2 nodes)

## God Nodes (most connected - your core abstractions)
1. `activeTripProfileProvider` - 33 edges
2. `plannedRouteProvider` - 26 edges
3. `groupParticipantsProvider` - 24 edges
4. `trackingProvider` - 18 edges
5. `calculationResultProvider` - 17 edges
6. `_MkkExportSheetState` - 10 edges
7. `_SaveTripDialogState` - 10 edges
8. `TripProfile` - 9 edges
9. `build` - 8 edges
10. `TrackingNotifier` - 8 edges

## Surprising Connections (you probably didn't know these)
- `GpxIntentService` --references--> `activeTripProfileProvider`  [EXTRACTED]
  lib/features/tracking/domain/services/gpx_intent_service.dart → lib/features/calculator/presentation/providers/calculator_providers.dart
- `_handleGpx` --references--> `activeTripProfileProvider`  [EXTRACTED]
  lib/features/tracking/domain/services/gpx_intent_service.dart → lib/features/calculator/presentation/providers/calculator_providers.dart
- `_pickPhoto` --references--> `activeTripProfileProvider`  [EXTRACTED]
  lib/features/tracking/presentation/widgets/add_waypoint_dialog.dart → lib/features/calculator/presentation/providers/calculator_providers.dart
- `_pickPhoto` --references--> `activeTripProfileProvider`  [EXTRACTED]
  lib/features/tracking/presentation/widgets/camp_debrief_sheet.dart → lib/features/calculator/presentation/providers/calculator_providers.dart
- `_applyAndFinish` --references--> `activeTripProfileProvider`  [EXTRACTED]
  lib/features/tracking/presentation/widgets/gpx_import_dialog.dart → lib/features/calculator/presentation/providers/calculator_providers.dart

## Import Cycles
- None detected.

## Communities (77 total, 2 thin omitted)

### Community 0 - "Lib Features Calculator Presentation Providers Calculator Providers Module (68 nodes)"
Cohesion: 0.03
Nodes (67): addFoodItem, addGearItem, addParticipant, allGearProvider, availableFoodsProvider, calculate, checkedMap, clear (+59 more)

### Community 1 - "Lib Features Tracking Presentation Providers Tracking Providers Module (51 nodes)"
Cohesion: 0.04
Nodes (50): activeTrack, activeTrip, addCampNoteToActiveTrack, addWaypoint, checkAndRequestPermission, clearSandboxTracks, completedTracksProvider, copyWith (+42 more)

### Community 2 - "Dart Typed Data Module (49 nodes)"
Cohesion: 0.04
Nodes (47): dart:typed_data, Font?, downloadFileToDevice, file, filePath, layoutPdf, openPdfInViewer, tempDir (+39 more)

### Community 3 - "Color Module (46 nodes)"
Cohesion: 0.04
Nodes (43): Color, IconData, _buildDailyEssentialsCard, _buildEssentialItem, _buildGearCategoriesPieChart, _buildHeroWeightCard, _buildMacroBar, _buildMacroNutrientPieChart (+35 more)

### Community 4 - "Latlng Module (46 nodes)"
Cohesion: 0.05
Nodes (44): LatLng, _buildTileUrl, cancel, _concurrency, downloaded, DownloadProgress, downloadTiles, errorMessage (+36 more)

### Community 5 - "Lib Core Enums Trip Enums Foodcategory Module (44 nodes)"
Cohesion: 0.05
Nodes (42): FoodCategory, Participant, caloricDensity, calories100g, carbs100g, category, copyWith, fat100g (+34 more)

### Community 6 - "Double Get Module (40 nodes)"
Cohesion: 0.05
Nodes (38): double get, bmr, carbsCalPercent, coldBonusKcal, dailyCalories, dailyCarbsG, dailyEquivalentKm, dailyFatG (+30 more)

### Community 7 - "Lib Core Services Export Service Module (39 nodes)"
Cohesion: 0.05
Nodes (37): copyToClipboard, ExportService, generateMarkdownReport, shareReport, build, _buildBackpackMeltCard, _buildCampJournalSection, _buildElevationChart (+29 more)

### Community 8 - "Lib Features Wiki Data Wiki Repository Module (38 nodes)"
Cohesion: 0.07
Nodes (34): _articles, getAllArticles, getArticleById, getArticlesByCategory, searchArticles, WikiRepository, Обезболивание, category (+26 more)

### Community 9 - "Dart Async Module (37 nodes)"
Cohesion: 0.06
Nodes (35): dart:async, customFoodProvider, _buildFilterChip, _categoryScrollController, createState, dispose, _hintTimer, initState (+27 more)

### Community 10 - "Lib Features Calculator Domain Services Metabolic Calculator Module (35 nodes)"
Cohesion: 0.08
Nodes (28): calculate, MetabolicCalculator, calculate, gearCalculatorService, metabolicCalculator, rationGeneratorService, TripCalculatorEngine, calculateGearWeights (+20 more)

### Community 11 - "Lib Features Trip Setup Domain Models Trip Profile Module (35 nodes)"
Cohesion: 0.06
Nodes (34): activeDays, activityType, avgParticipantWeightKg, clubOrCity, communicationSchedule, coordinatorEmail, coordinatorName, coordinatorPhone (+26 more)

### Community 12 - "Lib Features Calculator Domain Models Trip Calculation Result Tripcalculationresult Module (33 nodes)"
Cohesion: 0.08
Nodes (28): TripCalculationResult, createExpeditionZip, ExpeditionArchiveService, _buildDocCard, createState, _isExportingZip, _isGeneratingPassport, _isGeneratingReport (+20 more)

### Community 13 - "Lib Features Ration Domain Models Daily Ration Module (31 nodes)"
Cohesion: 0.06
Nodes (30): calories, carbsG, copyWith, DailyMealSlot, DailyRation, dayNumber, dutyParticipantIds, fatG (+22 more)

### Community 14 - "Lib Features Tracking Data Repositories Offline Tile Repository Module (31 nodes)"
Cohesion: 0.06
Nodes (30): centerLat, centerLon, clearAllTiles, createdAt, deleteRegion, fromJson, fromMap, getSavedRegions (+22 more)

### Community 15 - "Bool Get Module (30 nodes)"
Cohesion: 0.07
Nodes (29): bool get, int?, Gender, assignedFood, assignedGear, birthYear, cityRegion, contactPhone (+21 more)

### Community 16 - "Lib Features Tracking Presentation Screens Tracking Screen Module (30 nodes)"
Cohesion: 0.07
Nodes (29): _buildHudHeader, _buildHudStat, _buildStartFinishMarkers, createState, _fitRoute, _followUser, _formatDuration, _getWaypointColor (+21 more)

### Community 17 - "All Summer Spring Autumn Module (29 nodes)"
Cohesion: 0.07
Nodes (28): all,
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
  water,, ActivityType, badgeTitle (+20 more)

### Community 18 - "Lib Features Tracking Domain Models Camp Debrief Campdebrief Module (26 nodes)"
Cohesion: 0.08
Nodes (25): CampDebrief, avgMovingSpeedKmh, copyWith, DailyTrack, dayIndex, debrief, elevationGainMeters, elevationLossMeters (+17 more)

### Community 19 - "Lib Features Tracking Domain Models Camp Debrief Module (25 nodes)"
Cohesion: 0.08
Nodes (24): actualAscentMeters, actualCaloriesBurned, actualDescentMeters, actualDistanceKm, avgMovingSpeedKmh, calorieDelta, copyWith, dailyFoodWeightConsumedG (+16 more)

### Community 20 - "Lib Features Tracking Domain Services Camp Debrief Calculator Module (23 nodes)"
Cohesion: 0.13
Nodes (17): CampDebriefCalculator, generateDebrief, metabolicCalculator, package:survival_calc/core/enums/trip_enums.dart, package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart, package:survival_calc/features/calculator/domain/services/metabolic_calculator.dart, package:survival_calc/features/gear/data/repositories/gear_repository.dart, package:survival_calc/features/gear/domain/services/gear_calculator_service.dart (+9 more)

### Community 21 - "Animation Module (19 nodes)"
Cohesion: 0.11
Nodes (18): Animation, AnimationController, _animController, build, _controller, createState, dispose, initState (+10 more)

### Community 22 - "Lib Core Enums Trip Enums Gearcategory Module (19 nodes)"
Cohesion: 0.11
Nodes (18): GearCategory, GearSeason, GearType, category, copyWith, fromMap, GearItem, id (+10 more)

### Community 23 - "Lib Features Trip Storage Domain Models Saved Trip Entry Module (19 nodes)"
Cohesion: 0.11
Nodes (18): checkedGearIds, copyWith, createdAt, customFoods, customGear, fromJson, fromMap, id (+10 more)

### Community 24 - "Lib Features Trip Storage Presentation Widgets Trip Library Sheet Module (19 nodes)"
Cohesion: 0.11
Nodes (18): _buildBadge, _buildRealTripsTab, _buildSystemPresetCard, _buildTemplatesTab, _buildTripCard, createState, description, dispose (+10 more)

### Community 25 - "Dart Io Module (18 nodes)"
Cohesion: 0.12
Nodes (15): dart:io, package:flutter_test/flutter_test.dart, package:survival_calc/features/tracking/data/repositories/track_storage_repository.dart, package:survival_calc/features/tracking/domain/models/way_point.dart, package:survival_calc/features/tracking/domain/services/gpx_exporter.dart, package:survival_calc/features/tracking/domain/services/gpx_route_parser.dart, package:survival_calc/features/tracking/domain/services/tile_math_utils.dart, package:survival_calc/features/tracking/presentation/providers/tracking_providers.dart (+7 more)

### Community 26 - "Lib Features Calculator Presentation Providers Calculator Providers Participantsprovider Module (18 nodes)"
Cohesion: 0.16
Nodes (17): participantsProvider, tripCalculationResultProvider, tripProfileProvider, build, MkkExportSheet, _MkkExportSheetState, currentTripTracksProvider, sandboxTracksProvider (+9 more)

### Community 27 - "Lib Features Tracking Data Repositories Track Storage Repository Module (18 nodes)"
Cohesion: 0.12
Nodes (16): clearSandboxTracks, deleteTrack, getActiveTrack, getCompletedTracks, _getPrefs, getSandboxTracks, getTracksForTrip, _keyActiveTrack (+8 more)

### Community 28 - "Lib Features Tracking Domain Models Planned Route Module (18 nodes)"
Cohesion: 0.11
Nodes (17): description, fromJson, fromMap, id, importedAt, maxLat, maxLon, minLat (+9 more)

### Community 29 - "Lib Features Tracking Presentation Widgets Add Waypoint Dialog Module (18 nodes)"
Cohesion: 0.11
Nodes (17): build, createState, _deletePhoto, didChangeDependencies, dispose, initState, _isProcessingImage, _mediaService (+9 more)

### Community 30 - "Lib Core Services Qr Sync Service Module (17 nodes)"
Cohesion: 0.12
Nodes (16): campNotes, decodeTripProfile, decodeTripSnapshot, encodeTripProfile, encodeTripSnapshot, fromJson, isLeader, participants (+8 more)

### Community 31 - "Lib Core Theme Outdoor Theme Module (17 nodes)"
Cohesion: 0.12
Nodes (16): alertRed, borderActive, borderSubtle, darkBackground, electricCyan, OutdoorTheme, signalAmber, signalOrange (+8 more)

### Community 32 - "Lib Features Calculator Presentation Providers Calculator Providers Calculationresultprovider Module (17 nodes)"
Cohesion: 0.16
Nodes (17): calculationResultProvider, exportServiceProvider, qrSyncServiceProvider, build, DashboardScreen, _DashboardScreenState, build, GearChecklistScreen (+9 more)

### Community 33 - "Lib Features Tracking Domain Models Way Point Module (17 nodes)"
Cohesion: 0.12
Nodes (16): altitude, authorName, authorRole, copyWith, fromJson, id, latitude, longitude (+8 more)

### Community 34 - "Asyncvalue Module (16 nodes)"
Cohesion: 0.24
Nodes (16): AsyncValue, activeTripProfileProvider, customGearProvider, gearCheckedStateProvider, groupParticipantsProvider, build, _buildMkkSection, initState (+8 more)

### Community 35 - "Lib Core Enums Trip Enums Triprole Module (16 nodes)"
Cohesion: 0.12
Nodes (15): TripRole, authorName, authorRole, copyWith, createdAt, DailyCampNote, dayNumber, fromJson (+7 more)

### Community 36 - "Lib Features Tracking Presentation Widgets Gpx Import Dialog Module (16 nodes)"
Cohesion: 0.13
Nodes (15): _applyAndFinish, _autoApplyToProfile, build, _buildRoutePreviewCard, _buildStatItem, createState, _errorMessage, GpxImportDialog (+7 more)

### Community 37 - "Consumerstate Module (15 nodes)"
Cohesion: 0.17
Nodes (15): ConsumerState, ConsumerStatefulWidget, MainNavigationScreen, _MainNavigationScreenState, TrackingScreen, _TrackingScreenState, AddWaypointDialog, _AddWaypointDialogState (+7 more)

### Community 38 - "Int Get Module (15 nodes)"
Cohesion: 0.13
Nodes (14): int get, _approxDistanceKm, estimateSizeMb, getTilesForPolyline, getTilesForRadius, hashCode, latLonToTile, operator (+6 more)

### Community 39 - "Lib Features Home Presentation Screens Main Navigation Screen Module (15 nodes)"
Cohesion: 0.13
Nodes (14): createState, _currentIndex, _hideWebBanner, initState, _switchTab, package:survival_calc/features/dashboard/presentation/screens/dashboard_screen.dart, package:survival_calc/features/gear/presentation/screens/gear_checklist_screen.dart, package:survival_calc/features/ration/presentation/screens/food_breakdown_screen.dart (+6 more)

### Community 40 - "Class Module (14 nodes)"
Cohesion: 0.16
Nodes (13): class, loadDistributionServiceProvider, tripRepositoryProvider, build, _buildHeaderStat, createState, initState, LoadDistributionScreen (+5 more)

### Community 41 - "Lib Core Services Qr Sync Service Qrsyncservice Module (14 nodes)"
Cohesion: 0.20
Nodes (14): QrSyncService, showQrImportModal, showQrShareModal, plannedRouteProvider, trackingProvider, trackStorageRepositoryProvider, build, _buildBottomControls (+6 more)

### Community 42 - "Lib Core Widgets App Logo Applogo Module (14 nodes)"
Cohesion: 0.14
Nodes (13): AppLogo, FullscreenQrDialog, PositionBar, MapLayerSelectorSheet, WikiArticleDetailScreen, build, _buildRichText, _buildTable (+5 more)

### Community 43 - "Lib Features Tracking Domain Services Gpx Intent Service Module (14 nodes)"
Cohesion: 0.15
Nodes (12): _channel, GpxIntentService, _handleGpx, init, _initialized, showNewTripConfirmation, package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart, package:survival_calc/features/tracking/presentation/providers/planned_route_providers.dart (+4 more)

### Community 44 - "Lib Features Trip Setup Presentation Screens Trip Setup Screen Module (14 nodes)"
Cohesion: 0.15
Nodes (13): _buildQuickStat, createState, dispose, onCalculatePressed, _titleController, TripSetupScreen, _TripSetupScreenState, package:latlong2/latlong.dart (+5 more)

### Community 45 - "Lib Features Trip Storage Presentation Providers Saved Trips Providers Module (14 nodes)"
Cohesion: 0.15
Nodes (12): allAsync, deleteEntry, duplicateEntry, loadAll, maybeWhen, _repo, saveCurrent, savedTripsRepositoryProvider (+4 more)

### Community 46 - " Module (13 nodes)"
Cohesion: 0.15
Nodes (12): , BoxFit, double?, build, fill, fit, height, _kLogoSvg (+4 more)

### Community 47 - "Dart Ui Module (12 nodes)"
Cohesion: 0.17
Nodes (11): dart:ui, build, dragDevices, init, initialUrlData, isExplicitShareImport, OutdoorScrollBehavior, MaterialScrollBehavior (+3 more)

### Community 48 - "Lib Features Trip Setup Domain Models Planned Day Schedule Module (12 nodes)"
Cohesion: 0.17
Nodes (11): copyWith, date, dayNumber, distanceKm, fromMap, generateDefaultSchedule, movementType, obstacles (+3 more)

### Community 49 - "Lib Features Trip Storage Presentation Widgets Save Trip Dialog Module (12 nodes)"
Cohesion: 0.17
Nodes (11): createState, dispose, disposeWidget, initialIsTemplate, initState, _isSaving, _isTemplate, _noteController (+3 more)

### Community 50 - "Lib Features Wiki Domain Models Wiki Article Wikiarticle Module (12 nodes)"
Cohesion: 0.20
Nodes (10): WikiArticle, article, build, article, build, onTap, WikiArticleCard, package:flutter/material.dart (+2 more)

### Community 51 - "Datetime Module (11 nodes)"
Cohesion: 0.18
Nodes (10): DateTime, accuracy, altitude, fromJson, GpsPoint, latitude, longitude, speedKmh (+2 more)

### Community 52 - "Imagepicker Module (11 nodes)"
Cohesion: 0.18
Nodes (10): ImagePicker, deleteImage, getImageBytes, MediaStorageService, pickAndSaveImage, _picker, _webImageCache, package:image_picker/image_picker.dart (+2 more)

### Community 53 - "Lib Features Tracking Domain Models Planned Route Plannedroute Module (11 nodes)"
Cohesion: 0.18
Nodes (10): PlannedRoute, clearAll, clearPlannedRoute, deleteRegion, importFromGpx, _loadSaved, PlannedRouteNotifier, _plannedRoutePrefKey (+2 more)

### Community 54 - "Lib Features Tracking Domain Models Way Point Waypoint Module (10 nodes)"
Cohesion: 0.20
Nodes (9): WayPoint, build, _buildStat, onDelete, show, _showFullscreenPhoto, waypoint, WaypointDetailsSheet (+1 more)

### Community 55 - "Lib Features Tracking Domain Services Gpx Route Parser Module (10 nodes)"
Cohesion: 0.20
Nodes (9): _calculateHaversineDistance, _degreesToRadians, filterOutliers, GpxRouteParser, parseGpx, sanitizeElevation, toGpx, package:survival_calc/features/tracking/domain/models/planned_route.dart (+1 more)

### Community 56 - "Lib Features Tracking Presentation Widgets Cached Tile Provider Module (10 nodes)"
Cohesion: 0.20
Nodes (9): CachedTileProvider, fallbackUrlTemplate, getImage, getTileUrl, package:flutter/foundation.dart, package:flutter_map/flutter_map.dart, package:flutter/widgets.dart, package:survival_calc/features/tracking/data/repositories/offline_tile_repository.dart (+1 more)

### Community 57 - "Lib Features Trip Storage Data Repositories Saved Trips Repository Module (10 nodes)"
Cohesion: 0.20
Nodes (9): deleteEntry, duplicateEntry, _getPrefs, loadAll, _prefs, SavedTripsRepository, saveEntry, _storageKey (+1 more)

### Community 58 - "Dart Math Module (9 nodes)"
Cohesion: 0.22
Nodes (8): dart:math, calculateElevationProfile, calculateTotalDistanceKm, _degreesToRadians, distanceBetweenMeters, DistanceCalculator, earthRadiusMeters, static const double

### Community 59 - "Lib Core Utils Polyline Utils Module (9 nodes)"
Cohesion: 0.25
Nodes (8): _, decode, encode, _encodeValue, PolylineUtils, package:survival_calc/features/tracking/domain/models/gps_point.dart, package:survival_calc/features/tracking/domain/services/distance_calculator.dart, main

### Community 60 - "Lib Features Mkk Reports Domain Services Mkk Markdown Generator Module (9 nodes)"
Cohesion: 0.22
Nodes (8): charset, _formatInline, generatePostTripReportMarkdown, generatePreTripPassportMarkdown, lang, markdownToHtml, MkkMarkdownGenerator, package:intl/intl.dart

### Community 61 - "Lib Features Tracking Domain Models Map Layer Type Module (9 nodes)"
Cohesion: 0.22
Nodes (8): id, MapLayerType, maxNativeZoom, maxZoom, minZoom, name, subtitle, urlTemplate

### Community 62 - "Lib Features Trip Setup Presentation Dialogs Planned Itinerary Dialog Module (9 nodes)"
Cohesion: 0.22
Nodes (8): build, createState, initState, _items, PlannedItineraryDialog, profile, _save, show

### Community 63 - "Lib Features Wiki Presentation Widgets Wiki Callout Box Module (9 nodes)"
Cohesion: 0.22
Nodes (8): build, CalloutType, content, _getColor, _getIcon, title, type, WikiCalloutBox

### Community 64 - "Dart Convert Module (8 nodes)"
Cohesion: 0.29
Nodes (7): dart:convert, AssetFoodRepository, _assetPath, _cachedFoods, FoodRepository, loadFoods, saveCustomFood

### Community 65 - "Lib Core Widgets Fullscreen Qr Dialog Module (8 nodes)"
Cohesion: 0.25
Nodes (7): build, payload, show, subtitle, title, package:qr_flutter/qr_flutter.dart, package:survival_calc/core/theme/outdoor_theme.dart

### Community 66 - "Lib Features Calculator Presentation Providers Calculator Providers Customfoodnotifier Module (8 nodes)"
Cohesion: 0.36
Nodes (8): CustomFoodNotifier, CustomGearNotifier, GroupParticipantsNotifier, TripProfileNotifier, OfflineRegionsNotifier, TripProfile, List, StateNotifier

### Community 67 - "Lib Features Gear Data Repositories Gear Repository Module (8 nodes)"
Cohesion: 0.29
Nodes (7): AssetGearRepository, _assetPath, _cachedGear, GearRepository, loadGear, saveCustomGear, static const String

### Community 68 - "Lib Features Tracking Presentation Widgets Map Layer Selector Sheet Module (8 nodes)"
Cohesion: 0.25
Nodes (7): build, currentLayer, _getLayerIcon, onSelected, show, package:survival_calc/features/tracking/domain/models/map_layer_type.dart, ValueChanged

### Community 69 - "Dart Html Module (6 nodes)"
Cohesion: 0.33
Nodes (5): dart:html, blob, downloadFileToDevice, openPdfInViewer, url

### Community 70 - "File Saver Stub Dart Module (5 nodes)"
Cohesion: 0.40
Nodes (4): file_saver_stub.dart, FileSaverService, openPdfInViewer, saveAndShareFile

### Community 71 - "Lib Core Widgets Qr Scanner Dialog Qrscannerdialog Module (5 nodes)"
Cohesion: 0.40
Nodes (5): QrScannerDialog, _QrScannerDialogState, SingleTickerProviderStateMixin, State, StatefulWidget

### Community 72 - "Lib Features Trip Storage Presentation Providers Saved Trips Providers Savedrealtripsprovider Module (5 nodes)"
Cohesion: 0.50
Nodes (5): savedRealTripsProvider, savedTemplatesProvider, build, TripLibrarySheet, _TripLibrarySheetState

### Community 73 - "Lib Features Tracking Presentation Providers Tracking Providers Campdebriefcalculatorprovider Module (4 nodes)"
Cohesion: 0.50
Nodes (4): campDebriefCalculatorProvider, distanceCalculatorProvider, TrackingNotifier, TrackingState

### Community 74 - "Package Flutter Riverpod Flutter Riverpod Dart Module (4 nodes)"
Cohesion: 0.50
Nodes (3): package:flutter_riverpod/flutter_riverpod.dart, package:survival_calc/main.dart, main

## Knowledge Gaps
- **983 isolated node(s):** `DietaryRestriction`, `MedicalCondition`, `extreme_cold`, `survival`, `basics` (+978 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1063 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `TripRole` connect `Lib Core Enums Trip Enums Triprole Module (16 nodes)` to `Lib Features Tracking Domain Models Way Point Module (17 nodes)`, `Lib Core Services Export Service Module (39 nodes)`, `Bool Get Module (30 nodes)`, `All Summer Spring Autumn Module (29 nodes)`, `Lib Features Tracking Presentation Widgets Add Waypoint Dialog Module (18 nodes)`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `TripProfile` connect `Lib Features Calculator Presentation Providers Calculator Providers Customfoodnotifier Module (8 nodes)` to `Lib Core Enums Trip Enums Foodcategory Module (44 nodes)`, `Double Get Module (40 nodes)`, `Lib Features Trip Setup Domain Models Trip Profile Module (35 nodes)`, `Lib Features Calculator Domain Models Trip Calculation Result Tripcalculationresult Module (33 nodes)`, `Lib Features Trip Storage Domain Models Saved Trip Entry Module (19 nodes)`, `Lib Core Services Qr Sync Service Module (17 nodes)`, `Lib Features Trip Storage Presentation Widgets Trip Library Sheet Module (19 nodes)`, `Lib Features Trip Setup Presentation Dialogs Planned Itinerary Dialog Module (9 nodes)`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `DietaryRestriction`, `MedicalCondition`, `extreme_cold` to the rest of the system?**
  _983 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Lib Features Calculator Presentation Providers Calculator Providers Module (68 nodes)` be split into smaller, more focused modules?**
  _Cohesion score 0.029411764705882353 - nodes in this community are weakly interconnected._
- **Should `Lib Features Tracking Presentation Providers Tracking Providers Module (51 nodes)` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._
- **Should `Dart Typed Data Module (49 nodes)` be split into smaller, more focused modules?**
  _Cohesion score 0.041666666666666664 - nodes in this community are weakly interconnected._
- **Should `Color Module (46 nodes)` be split into smaller, more focused modules?**
  _Cohesion score 0.044444444444444446 - nodes in this community are weakly interconnected._