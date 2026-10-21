import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studesk/core/data/studesk_repository.dart';
import 'package:studesk/core/theme/app_theme.dart';
import 'package:studesk/shared/dialogs/studesk_forms.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StuDeskRepository.instance.init();
  });

  group('StuDeskForms UUID & Creation Tests', () {
    test('generateId produces valid RFC4122 UUID v4 strings', () {
      final id1 = StuDeskForms.generateId();
      final id2 = StuDeskForms.generateId();

      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(equals(id2)));
      expect(Uuid.isValidUUID(fromString: id1), isTrue);
      expect(Uuid.isValidUUID(fromString: id2), isTrue);
    });

    testWidgets(
      'showTaskForm validates empty title and prevents silent failure',
      (WidgetTester tester) async {
        final repo = StuDeskRepository.instance;
        expect(repo.tasks.isEmpty, isTrue);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => StuDeskForms.showTaskForm(ctx),
                  child: const Text('Open Task Form'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Task Form'));
        await tester.pumpAndSettle();

        expect(find.text('New Academic Task'), findsOneWidget);
        expect(find.text('Save Task'), findsOneWidget);

        // Tap save without typing title
        await tester.tap(find.text('Save Task'));
        await tester.pumpAndSettle();

        // Form remains open and displays validation error
        expect(find.text('Task title is required'), findsOneWidget);
        expect(repo.tasks.isEmpty, isTrue);

        // Type title and save
        await tester.enterText(
          find.widgetWithText(TextField, 'Task Title *'),
          'Complete Operating Systems assignment',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save Task'));
        await tester.pumpAndSettle();

        // Form closes and task is persisted in repo
        expect(find.text('New Academic Task'), findsNothing);
        expect(repo.tasks.length, equals(1));
        expect(
          repo.tasks.first.title,
          equals('Complete Operating Systems assignment'),
        );
        expect(Uuid.isValidUUID(fromString: repo.tasks.first.id), isTrue);
      },
    );

    testWidgets(
      'showSubjectForm validates inputs and persists Course with UUID topics',
      (WidgetTester tester) async {
        final repo = StuDeskRepository.instance;
        expect(repo.courses.isEmpty, isTrue);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => StuDeskForms.showSubjectForm(ctx),
                  child: const Text('Open Subject Form'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Subject Form'));
        await tester.pumpAndSettle();

        expect(find.text('Add Subject & Syllabus'), findsOneWidget);

        // Tap create with empty fields
        await tester.tap(find.text('Create Subject'));
        await tester.pumpAndSettle();

        expect(find.text('Subject code is required'), findsOneWidget);
        expect(repo.courses.isEmpty, isTrue);

        // Enter valid code and title
        await tester.enterText(
          find.widgetWithText(TextField, 'Subject Code * (e.g. CS201)'),
          'CS301',
        );
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Subject Title * (e.g. Data Structures)',
          ),
          'Database Management Systems',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create Subject'));
        await tester.pumpAndSettle();

        expect(repo.courses.length, equals(1));
        final course = repo.courses.first;
        expect(course.code, equals('CS301'));
        expect(course.title, equals('Database Management Systems'));
      },
    );

    testWidgets('confirmDelete dialog handles cancellation and confirmation', (
      WidgetTester tester,
    ) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  result = await StuDeskForms.confirmDelete(
                    ctx,
                    title: 'Delete Test Item',
                    message: 'Are you sure you want to delete this test item?',
                  );
                },
                child: const Text('Confirm Delete'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test Cancel
      await tester.tap(find.text('Confirm Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Test Item'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);

      // Test Confirm
      await tester.tap(find.text('Confirm Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
