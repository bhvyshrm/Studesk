import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studesk/core/data/studesk_repository.dart';
import 'package:studesk/shared/models/models.dart';

class BackupSnapshotInfo {
  final String key;
  final BackupMetadata metadata;
  final String rawJson;

  const BackupSnapshotInfo({
    required this.key,
    required this.metadata,
    required this.rawJson,
  });
}

class BackupService extends ChangeNotifier {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const String _prefBackupIndex = 'studesk_backup_index';
  static const String _prefLastBackupTime = 'studesk_last_backup_time';
  static const int maxRetainedBackups = 20;
  static const int reminderIntervalDays = 3;

  List<BackupSnapshotInfo> _snapshots = [];
  List<BackupSnapshotInfo> get snapshots => List.unmodifiable(_snapshots);

  DateTime? _lastBackupTime;
  DateTime? get lastBackupTime => _lastBackupTime;

  bool get shouldShowBackupReminder {
    if (_lastBackupTime == null) return true;
    final daysSince = DateTime.now().difference(_lastBackupTime!).inDays;
    return daysSince >= reminderIntervalDays;
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTimeStr = prefs.getString(_prefLastBackupTime);
      if (lastTimeStr != null) {
        _lastBackupTime = DateTime.tryParse(lastTimeStr);
      }
      await refreshSnapshots();
    } catch (e) {
      debugPrint('BackupService init error: $e');
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _snapshots = [];
    _lastBackupTime = null;
    notifyListeners();
  }

  Future<void> refreshSnapshots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getStringList(_prefBackupIndex) ?? [];
      final list = <BackupSnapshotInfo>[];

      for (final key in keys) {
        final content = prefs.getString(key);
        if (content != null) {
          try {
            final json = jsonDecode(content) as Map<String, dynamic>;
            final meta = BackupMetadata.fromJson(json['metadata'] as Map<String, dynamic>);
            list.add(BackupSnapshotInfo(key: key, metadata: meta, rawJson: content));
          } catch (_) {}
        }
      }

      // Sort newest first
      list.sort((a, b) => b.metadata.exportedAt.compareTo(a.metadata.exportedAt));
      _snapshots = list;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing snapshots: $e');
    }
  }

  Future<BackupMetadata> createManualBackup() async {
    final repo = StuDeskRepository.instance;
    final payload = await repo.createBackupPayload();
    final jsonString = jsonEncode(payload.toJson());

    final prefs = await SharedPreferences.getInstance();
    final timestamp = payload.metadata.exportedAt.millisecondsSinceEpoch;
    final key = 'studesk_backup_$timestamp';

    // Save snapshot content
    await prefs.setString(key, jsonString);

    // Update index list
    final existingKeys = prefs.getStringList(_prefBackupIndex) ?? [];
    existingKeys.insert(0, key);

    // Enforce 20-file retention policy
    if (existingKeys.length > maxRetainedBackups) {
      final excessKeys = existingKeys.sublist(maxRetainedBackups);
      for (final oldKey in excessKeys) {
        await prefs.remove(oldKey);
      }
      existingKeys.removeRange(maxRetainedBackups, existingKeys.length);
    }

    await prefs.setStringList(_prefBackupIndex, existingKeys);

    _lastBackupTime = payload.metadata.exportedAt;
    await prefs.setString(_prefLastBackupTime, _lastBackupTime!.toIso8601String());

    await refreshSnapshots();
    return payload.metadata;
  }

  StuDeskBackupPayload validateAndPreview(String jsonString) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw const FormatException('Invalid JSON syntax in backup file.');
    }

    return StuDeskBackupPayload.fromJson(json);
  }

  Future<void> restoreBackup(
    StuDeskBackupPayload payload, {
    RestoreConflictStrategy strategy = RestoreConflictStrategy.overwrite,
  }) async {
    final repo = StuDeskRepository.instance;
    await repo.restoreFromBackupPayload(payload, strategy: strategy);
  }

  Future<void> deleteSnapshot(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    final existingKeys = prefs.getStringList(_prefBackupIndex) ?? [];
    existingKeys.remove(key);
    await prefs.setStringList(_prefBackupIndex, existingKeys);
    await refreshSnapshots();
  }
}
