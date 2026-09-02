import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:survival_calc/core/enums/trip_enums.dart';
import 'package:survival_calc/core/theme/outdoor_theme.dart';
import 'package:survival_calc/core/widgets/qr_scanner_dialog.dart';
import 'package:survival_calc/features/calculator/presentation/providers/calculator_providers.dart';
import 'package:survival_calc/features/group_distribution/domain/models/participant.dart';
import 'package:survival_calc/features/tracking/domain/models/daily_camp_note.dart';
import 'package:survival_calc/features/tracking/domain/models/way_point.dart';
import 'package:survival_calc/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:survival_calc/features/trip_setup/domain/models/trip_profile.dart';

class TripQrSnapshot {
  final TripProfile profile;
  final List<WayPoint> waypoints;
  final List<DailyCampNote> campNotes;
  final bool isLeader;
  final String? senderName;

  const TripQrSnapshot({
    required this.profile,
    this.waypoints = const [],
    this.campNotes = const [],
    this.isLeader = true,
    this.senderName,
  });

  Map<String, dynamic> toJson() {
    return {
      'v': 2,
      'profile': jsonDecode(profile.toJson()),
      'waypoints': waypoints.map((w) => w.toJson()).toList(),
      'campNotes': campNotes.map((n) => n.toJson()).toList(),
      'isLeader': isLeader,
      if (senderName != null) 'senderName': senderName,
    };
  }

  factory TripQrSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['v'] == 2) {
      final profMap = json['profile'] as Map<String, dynamic>;
      final profile = TripProfile.fromJson(jsonEncode(profMap));
      final wpList = (json['waypoints'] as List<dynamic>?)
              ?.map((e) => WayPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final notesList = (json['campNotes'] as List<dynamic>?)
              ?.map((e) => DailyCampNote.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      return TripQrSnapshot(
        profile: profile,
        waypoints: wpList,
        campNotes: notesList,
        isLeader: json['isLeader'] as bool? ?? true,
        senderName: json['senderName'] as String?,
      );
    } else {
      final profile = TripProfile.fromJson(jsonEncode(json));
      return TripQrSnapshot(profile: profile);
    }
  }
}

class QrSyncService {
  const QrSyncService();

  static const String _qrPrefix = 'SURVIVALCALC:';

  /// Encodes a TripProfile + current Waypoints & Notes into a compressed base64 QR payload
  String encodeTripSnapshot(TripQrSnapshot snapshot) {
    final jsonStr = jsonEncode(snapshot.toJson());
    final bytes = utf8.encode(jsonStr);
    final base64Str = base64Url.encode(bytes);
    return '$_qrPrefix$base64Str';
  }

  /// Encodes a pure TripProfile (v1 backward compatibility)
  String encodeTripProfile(TripProfile profile) {
    return encodeTripSnapshot(TripQrSnapshot(profile: profile));
  }

  /// Decodes a QR code string or raw JSON back into a TripQrSnapshot
  TripQrSnapshot? decodeTripSnapshot(String payload) {
    final cleanPayload = payload.trim();
    if (cleanPayload.isEmpty) return null;

    try {
      if (cleanPayload.startsWith(_qrPrefix)) {
        final base64Str = cleanPayload.substring(_qrPrefix.length);
        final bytes = base64Url.decode(base64Str);
        final jsonStr = utf8.decode(bytes);
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          return TripQrSnapshot.fromJson(decoded);
        }
      } else if (cleanPayload.startsWith('{') && cleanPayload.endsWith('}')) {
        final decoded = jsonDecode(cleanPayload);
        if (decoded is Map<String, dynamic>) {
          return TripQrSnapshot.fromJson(decoded);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Decodes a QR code string into a pure TripProfile
  TripProfile? decodeTripProfile(String payload) {
    return decodeTripSnapshot(payload)?.profile;
  }

  /// Shows the QR code modal dialog for sharing the active trip + notes
  void showQrShareModal(BuildContext context, WidgetRef ref) {
    final profile = ref.read(activeTripProfileProvider);
    final activeTrack = ref.read(trackingProvider).activeTrack;
    final waypoints = activeTrack?.waypoints ?? [];
    final campNotes = activeTrack?.debrief?.notes ?? [];

    final participants = ref.read(groupParticipantsProvider);
    final isLeader = participants.any((p) => p.role == TripRole.leader);
    final leaderMember = participants.firstWhere(
      (p) => p.role == TripRole.leader,
      orElse: () => participants.isNotEmpty
          ? participants.first
          : const Participant(id: 'p_leader', name: 'Руководитель', weightKg: 75),
    );

    final snapshot = TripQrSnapshot(
      profile: profile,
      waypoints: waypoints,
      campNotes: campNotes,
      isLeader: isLeader,
      senderName: leaderMember.name,
    );

    final payload = encodeTripSnapshot(snapshot);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: OutdoorTheme.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: OutdoorTheme.signalOrange, width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '📱 Офлайн QR-Код',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: OutdoorTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: OutdoorTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Сканируйте этот QR-код для моментальной синхронизации плана, путевых меток и дневника (100% без интернета).',
                  style: TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
                ),
                const SizedBox(height: 16),

                // QR Code Container with High-Contrast White Background
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: OutdoorTheme.signalOrange.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 200.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0F1216),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F1216),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Trip Brief Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: OutdoorTheme.surfaceCardElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        profile.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: OutdoorTheme.signalOrange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.groupSize} чел. • ${profile.durationDays} дн. • ${profile.totalDistanceKm.toStringAsFixed(0)} км • ${waypoints.length} меток • ${campNotes.length} заметок',
                        style: const TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Copy Raw Sync Key Button
                ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: payload));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Текстовый ключ синхронизации скопирован'),
                          backgroundColor: OutdoorTheme.tacticalGreen,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Скопировать ключ похода'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the Import modal dialog for receiving a trip via QR / Text Key
  void showQrImportModal(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    TripQrSnapshot? previewSnapshot;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          backgroundColor: OutdoorTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: OutdoorTheme.signalOrange, width: 1.5),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.qr_code_scanner, color: OutdoorTheme.signalOrange, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Импорт и синхронизация',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: OutdoorTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: OutdoorTheme.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Отсканируйте QR-код камерой или вставьте ключ синхронизации:',
                    style: TextStyle(fontSize: 12, color: OutdoorTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // 1. Primary Live Camera Scanner Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B00), Color(0xFFE65100)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: OutdoorTheme.signalOrange.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final scanned = await QrScannerDialog.show(context);
                        if (scanned != null && scanned.isNotEmpty) {
                          textController.text = scanned;
                          final parsed = decodeTripSnapshot(scanned);
                          setModalState(() => previewSnapshot = parsed);
                          if (parsed == null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⚠️ Не удалось распознать поход из QR-кода'),
                                backgroundColor: OutdoorTheme.alertRed,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 22),
                      label: const Text(
                        '📷 Сканировать QR камерой',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Divider with Text
                  const Row(
                    children: [
                      Expanded(child: Divider(color: OutdoorTheme.borderSubtle)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'ИЛИ ВВЕДИТЕ КЛЮЧ ВРУЧНУЮ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: OutdoorTheme.textMuted,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: OutdoorTheme.borderSubtle)),
                    ],
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: textController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: 'Вставьте ключ SURVIVALCALC:...',
                      hintStyle: const TextStyle(fontSize: 12, color: OutdoorTheme.textMuted),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste, color: OutdoorTheme.signalOrange),
                        tooltip: 'Вставить из буфера',
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) {
                            textController.text = data!.text!;
                            final parsed = decodeTripSnapshot(data.text!);
                            setModalState(() => previewSnapshot = parsed);
                          }
                        },
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = decodeTripSnapshot(val);
                      setModalState(() => previewSnapshot = parsed);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Preview Card if successfully decoded
                  if (previewSnapshot != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OutdoorTheme.tacticalGreen.withValues(alpha: 0.15),
                        border: Border.all(color: OutdoorTheme.tacticalGreen),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: OutdoorTheme.tacticalGreen, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Поход: ${previewSnapshot!.profile.title}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: OutdoorTheme.tacticalGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Дней: ${previewSnapshot!.profile.durationDays} • Участников: ${previewSnapshot!.profile.groupSize} • Дистанция: ${previewSnapshot!.profile.totalDistanceKm.toStringAsFixed(0)} км',
                            style: const TextStyle(
                                fontSize: 11, color: OutdoorTheme.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '📍 Новых меток: ${previewSnapshot!.waypoints.length} • 📝 Заметок лагеря: ${previewSnapshot!.campNotes.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  ElevatedButton.icon(
                    onPressed: previewSnapshot == null
                        ? null
                        : () async {
                            final snapshot = previewSnapshot!;
                            final currentParticipants = ref.read(groupParticipantsProvider);
                            final currentIsLeader = currentParticipants
                                .any((p) => p.role == TripRole.leader);

                            // 1. Update Profile (if receiver is not leader or code is from leader)
                            if (!currentIsLeader || snapshot.isLeader) {
                              ref
                                  .read(activeTripProfileProvider.notifier)
                                  .updateProfile(snapshot.profile);
                            }

                            // 2. Merge Waypoints (non-destructive)
                            final trackingNotifier = ref.read(trackingProvider.notifier);
                            final activeTrack = ref.read(trackingProvider).activeTrack;
                            if (activeTrack != null && snapshot.waypoints.isNotEmpty) {
                              for (final wp in snapshot.waypoints) {
                                final alreadyExists = activeTrack.waypoints.any(
                                  (existing) =>
                                      existing.id == wp.id ||
                                      (existing.title == wp.title &&
                                          (existing.latitude - wp.latitude).abs() < 0.0001 &&
                                          (existing.longitude - wp.longitude).abs() < 0.0001),
                                );
                                if (!alreadyExists) {
                                  await trackingNotifier.addWaypoint(
                                    title: wp.title,
                                    type: wp.type,
                                    note: wp.note,
                                    photoPath: wp.photoPath,
                                    authorName: wp.authorName,
                                    authorRole: wp.authorRole,
                                  );
                                }
                              }
                            }

                            // 3. Merge Camp Notes (non-destructive)
                            if (snapshot.campNotes.isNotEmpty) {
                              for (final note in snapshot.campNotes) {
                                await trackingNotifier.addCampNoteToActiveTrack(note);
                              }
                            }

                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '✅ Данные похода "${snapshot.profile.title}" успешно объединены! (+${snapshot.waypoints.length} меток, +${snapshot.campNotes.length} заметок)'),
                                  backgroundColor: OutdoorTheme.tacticalGreen,
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.download_done),
                    label: const Text('Принять и объединить данные'),
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
