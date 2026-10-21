import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studesk/core/data/studesk_repository.dart';
import 'package:studesk/core/theme/app_theme.dart';
import 'package:studesk/features/backup/data/backup_service.dart';
import 'package:studesk/features/backup/presentation/backup_restore_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StuDeskRepository.instance.init();
    BackupService.instance.resetForTesting();
    await BackupService.instance.init();
  });

  group('BackupService Tests', () {
    test(
      'Manual backup creation creates valid snapshot and metadata',
      () async {
        final service = BackupService.instance;
        final meta = await service.createManualBackup();

        expect(meta.schemaVersion, 1);
        expect(meta.dataChecksum.isNotEmpty, isTrue);
        expect(service.snapshots.isNotEmpty, isTrue);
        expect(service.lastBackupTime, isNotNull);
        expect(service.shouldShowBackupReminder, isFalse);
      },
    );

    test('3-day backup reminder logic triggers when backup is old', () {
      final service = BackupService.instance;
      // When no backup has ever been performed
      expect(service.shouldShowBackupReminder, isTrue);
    });

    test('Validation catches invalid JSON backup syntax', () {
      final service = BackupService.instance;
      expect(
        () => service.validateAndPreview('not-json'),
        throwsFormatException,
      );
    });
  });

  group('BackupRestoreScreen Widget Tests', () {
    testWidgets('Screen renders manual backup button and retention info', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const BackupRestoreScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Backup & Restore'), findsOneWidget);
      expect(find.text('Create Backup Snapshot Now'), findsOneWidget);
      expect(find.text('Google Drive Integration'), findsOneWidget);
      expect(find.text('Auto-prunes after 20'), findsOneWidget);
    });
  });
}
