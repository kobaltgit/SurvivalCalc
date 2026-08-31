import 'package:survival_calc/features/tracking/domain/models/daily_track.dart';

class GpxExporter {
  const GpxExporter();

  /// Converts a DailyTrack to GPX 1.1 XML string
  String exportTrackToGpx(DailyTrack track) {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<gpx version="1.1" creator="SurvivalCalc" xmlns="http://www.topografix.com/GPX/1/1">',
    );

    // Metadata
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>${_escapeXml(track.title)}</name>');
    buffer.writeln('    <time>${track.startTime.toUtc().toIso8601String()}</time>');
    buffer.writeln('  </metadata>');

    // Waypoints
    for (final wp in track.waypoints) {
      buffer.writeln(
        '  <wpt lat="${wp.latitude.toStringAsFixed(7)}" lon="${wp.longitude.toStringAsFixed(7)}">',
      );
      buffer.writeln('    <ele>${wp.altitude.toStringAsFixed(1)}</ele>');
      buffer.writeln('    <time>${wp.timestamp.toUtc().toIso8601String()}</time>');
      buffer.writeln('    <name>${_escapeXml(wp.title)}</name>');
      if (wp.note != null && wp.note!.isNotEmpty) {
        buffer.writeln('    <desc>${_escapeXml(wp.note!)}</desc>');
      }
      buffer.writeln('    <sym>${wp.type.name}</sym>');
      buffer.writeln('  </wpt>');
    }

    // Track
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>${_escapeXml(track.title)}</name>');
    buffer.writeln('    <trkseg>');

    for (final pt in track.points) {
      buffer.writeln(
        '      <trkpt lat="${pt.latitude.toStringAsFixed(7)}" lon="${pt.longitude.toStringAsFixed(7)}">',
      );
      buffer.writeln('        <ele>${pt.altitude.toStringAsFixed(1)}</ele>');
      buffer.writeln('        <time>${pt.timestamp.toUtc().toIso8601String()}</time>');
      buffer.writeln('      </trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
