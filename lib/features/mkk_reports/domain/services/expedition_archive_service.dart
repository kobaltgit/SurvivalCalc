import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:survival_calc/features/calculator/domain/models/trip_calculation_result.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/mkk_reports/domain/services/mkk_markdown_generator.dart';
import 'package:survival_calc/features/mkk_reports/domain/services/mkk_pdf_generator.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_camp_note.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/tracking/domain/services/gpx_exporter.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class ExpeditionArchiveService {
  /// Assembles and encodes the complete Expedition ZIP package in memory.
  static Future<Uint8List> createExpeditionZip({
    required TripProfile profile,
    required List<Participant> participants,
    required TripCalculationResult? calcResult,
    required List<DailyTrack> tracks,
    required List<WayPoint> waypoints,
    required List<DailyCampNote> campNotes,
  }) async {
    final archive = Archive();

    // 1. Generate PDFs
    try {
      final passportPdfBytes = await MkkPdfGenerator.generatePreTripPassportPdf(
        profile: profile,
        participants: participants,
        calcResult: calcResult,
      );
      archive.addFile(ArchiveFile('Passport_MKK.pdf', passportPdfBytes.length, passportPdfBytes));
    } catch (e) {
      debugPrint('Error creating passport PDF for ZIP: $e');
    }

    try {
      final reportPdfBytes = await MkkPdfGenerator.generatePostTripReportPdf(
        profile: profile,
        participants: participants,
        tracks: tracks,
        waypoints: waypoints,
        campNotes: campNotes,
      );
      archive.addFile(ArchiveFile('Technical_Report.pdf', reportPdfBytes.length, reportPdfBytes));
    } catch (e) {
      debugPrint('Error creating report PDF for ZIP: $e');
    }

    // 2. Generate Markdown & HTML summaries
    final passportMd = MkkMarkdownGenerator.generatePreTripPassportMarkdown(
      profile: profile,
      participants: participants,
      calcResult: calcResult,
    );
    final reportMd = MkkMarkdownGenerator.generatePostTripReportMarkdown(
      profile: profile,
      participants: participants,
      tracks: tracks,
      waypoints: waypoints,
      campNotes: campNotes,
    );
    final fullSummaryMd = '$passportMd\n\n========================================\n\n$reportMd';
    final fullSummaryHtml = MkkMarkdownGenerator.markdownToHtml(fullSummaryMd);

    final mdBytes = Uint8List.fromList(fullSummaryMd.codeUnits);
    archive.addFile(ArchiveFile('Trip_Summary.md', mdBytes.length, mdBytes));

    final htmlBytes = Uint8List.fromList(fullSummaryHtml.codeUnits);
    archive.addFile(ArchiveFile('Trip_Summary.html', htmlBytes.length, htmlBytes));

    // 3. Export Tracks GPX
    if (tracks.isNotEmpty) {
      const gpxExporter = GpxExporter();
      for (int i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        final gpxStr = gpxExporter.exportTrackToGpx(track);
        final gpxBytes = Uint8List.fromList(gpxStr.codeUnits);
        final safeName = track.title.replaceAll(RegExp(r'[^\w\dа-яА-Я_\-]'), '_');
        archive.addFile(ArchiveFile('Tracks/Day_${i + 1}_$safeName.gpx', gpxBytes.length, gpxBytes));
      }
    }

    // 4. Attach Photos from Waypoints if available on local filesystem
    if (!kIsWeb) {
      for (int i = 0; i < waypoints.length; i++) {
        final w = waypoints[i];
        if (w.photoPath != null && w.photoPath!.isNotEmpty) {
          final file = File(w.photoPath!);
          if (file.existsSync()) {
            try {
              final bytes = file.readAsBytesSync();
              final ext = file.path.split('.').last;
              final safeName = w.title.replaceAll(RegExp(r'[^\w\dа-яА-Я_\-]'), '_');
              archive.addFile(ArchiveFile('Photos/wpt_${i + 1}_$safeName.$ext', bytes.length, bytes));
            } catch (e) {
              debugPrint('Error reading waypoint photo for ZIP: $e');
            }
          }
        }
      }
    }

    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);
    return Uint8List.fromList(zipData);
  }
}
