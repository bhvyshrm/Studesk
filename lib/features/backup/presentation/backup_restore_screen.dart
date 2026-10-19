import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:studesk/core/theme/app_theme.dart';
import 'package:studesk/shared/models/models.dart';
import '../data/backup_service.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final BackupService _backupService = BackupService.instance;
  bool _isBackingUp = false;

  @override
  void initState() {
    super.initState();
    _backupService.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _backupService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  void _handleCreateBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final meta = await _backupService.createManualBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.stuTheme.surfaceTier3,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Backup created successfully: ${meta.coursesCount} courses, ${meta.tasksCount} tasks, ${meta.resourcesCount} resources.',
              style: TextStyle(color: context.stuTheme.textPrimary),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.stuTheme.errorContainer,
            content: Text('Backup failed: $e', style: TextStyle(color: context.stuTheme.error)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  void _showRestorePreviewDialog(BackupSnapshotInfo snapshot) {
    final stuTheme = context.stuTheme;
    StuDeskBackupPayload payload;
    try {
      payload = _backupService.validateAndPreview(snapshot.rawJson);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: stuTheme.errorContainer,
          content: Text('Cannot preview: $e', style: TextStyle(color: stuTheme.error)),
        ),
      );
      return;
    }

    RestoreConflictStrategy selectedStrategy = RestoreConflictStrategy.overwrite;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: stuTheme.surfaceTier1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.history_rounded, color: stuTheme.accent),
              const SizedBox(width: 8),
              Text(
                'Restore Snapshot',
                style: TextStyle(color: stuTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Created on: ${DateFormat.yMMMd().add_jm().format(payload.metadata.exportedAt)}',
                  style: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: stuTheme.surfaceTier2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: stuTheme.border),
                  ),
                  child: Column(
                    children: [
                      _buildPreviewRow('Profile', payload.profile.name, stuTheme),
                      _buildPreviewRow('Courses', '${payload.courses.length} registered', stuTheme),
                      _buildPreviewRow('Tasks', '${payload.tasks.length} items', stuTheme),
                      _buildPreviewRow('Resources', '${payload.resources.length} saved', stuTheme),
                      _buildPreviewRow('Journals', '${payload.journals.length} entries', stuTheme),
                      _buildPreviewRow(
                        'Attendance',
                        '${payload.subjectAttendance.length + payload.collegeAttendance.length} records',
                        stuTheme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Conflict Resolution Strategy:',
                  style: TextStyle(
                    color: stuTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setDialogState(() => selectedStrategy = RestoreConflictStrategy.overwrite),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          selectedStrategy == RestoreConflictStrategy.overwrite
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selectedStrategy == RestoreConflictStrategy.overwrite
                              ? stuTheme.accent
                              : stuTheme.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Replace Current Data (Clean restore)',
                            style: TextStyle(color: stuTheme.textPrimary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => setDialogState(() => selectedStrategy = RestoreConflictStrategy.mergeSkipExisting),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          selectedStrategy == RestoreConflictStrategy.mergeSkipExisting
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selectedStrategy == RestoreConflictStrategy.mergeSkipExisting
                              ? stuTheme.accent
                              : stuTheme.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Merge (Preserve existing items, import missing)',
                            style: TextStyle(color: stuTheme.textPrimary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: stuTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: stuTheme.accent,
                foregroundColor: stuTheme.onAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _backupService.restoreBackup(payload, strategy: selectedStrategy);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: stuTheme.surfaceTier3,
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'Data restored successfully!',
                      style: TextStyle(color: stuTheme.textPrimary),
                    ),
                  ),
                );
              },
              child: const Text('Confirm Restore'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, StuDeskThemeExtension stuTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: stuTheme.textSecondary, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: stuTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;
    final lastBackup = _backupService.lastBackupTime;
    final needsBackup = _backupService.shouldShowBackupReminder;

    return Scaffold(
      backgroundColor: stuTheme.canvas,
      appBar: AppBar(
        backgroundColor: stuTheme.canvas,
        title: Text(
          'Backup & Restore',
          style: TextStyle(color: stuTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: stuTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3-Day Reminder Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: needsBackup ? stuTheme.warningContainer : stuTheme.surfaceTier1,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: needsBackup ? stuTheme.warning.withValues(alpha: 0.3) : stuTheme.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (needsBackup ? stuTheme.warning : stuTheme.success)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      needsBackup ? Icons.notification_important_rounded : Icons.check_circle_rounded,
                      color: needsBackup ? stuTheme.warning : stuTheme.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          needsBackup ? 'Backup Recommended' : 'Backups Up-to-Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: stuTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lastBackup != null
                              ? 'Last snapshot: ${DateFormat.yMMMd().format(lastBackup)}'
                              : 'No backup created yet. Tap below to create your first backup.',
                          style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Manual Backup Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: stuTheme.accent,
                  foregroundColor: stuTheme.onAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isBackingUp ? null : _handleCreateBackup,
                icon: _isBackingUp
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup_rounded, size: 20),
                label: Text(
                  _isBackingUp ? 'Creating Snapshot...' : 'Create Backup Snapshot Now',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Retention Policy Note
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Backup Snapshots (${_backupService.snapshots.length}/20)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: stuTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto-prunes after 20',
                  style: TextStyle(fontSize: 11, color: stuTheme.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_backupService.snapshots.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: stuTheme.surfaceTier1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: stuTheme.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 40, color: stuTheme.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No Backups Stored Yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: stuTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Create Backup Snapshot Now" to save your subjects, syllabus, attendance, tasks, and journals.',
                      style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _backupService.snapshots.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final item = _backupService.snapshots[index];
                  final meta = item.metadata;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: stuTheme.surfaceTier1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: stuTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: stuTheme.surfaceTier2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.file_present_rounded, color: stuTheme.accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat.yMMMd().add_jm().format(meta.exportedAt),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: stuTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${meta.coursesCount} courses • ${meta.tasksCount} tasks • ${meta.journalsCount} journals',
                                style: TextStyle(fontSize: 11, color: stuTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.restore_rounded, color: stuTheme.accent, size: 20),
                          tooltip: 'Restore snapshot',
                          onPressed: () => _showRestorePreviewDialog(item),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              color: stuTheme.error, size: 20),
                          tooltip: 'Delete snapshot',
                          onPressed: () => _backupService.deleteSnapshot(item.key),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 28),

            // Google Drive Cloud Backup Architecture Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: stuTheme.surfaceTier1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: stuTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_to_drive_rounded, color: stuTheme.accent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Google Drive Integration',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: stuTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Drive backups require dedicated OAuth scopes (https://www.googleapis.com/auth/drive.appdata). See docs/GOOGLE_DRIVE_BACKUP.md for configuration instructions. Large binary images are excluded to keep sync fast and light.',
                    style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
