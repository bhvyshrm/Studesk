import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studesk/app.dart';
import 'package:studesk/core/config/app_bootstrap.dart';
import 'package:studesk/core/theme/theme_controller.dart';
import 'package:studesk/features/journal/presentation/journal_editor_screen.dart';
import 'package:studesk/features/subjects/presentation/subject_details_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    AppBootstrap.configureErrorHandling();
  });

  void configurePhoneDimensions(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532); // iPhone 14/15 Pro standard resolution
    tester.view.devicePixelRatio = 3.0;
  }

  testWidgets('StuDesk App smoke and navigation test', (WidgetTester tester) async {
    configurePhoneDimensions(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StuDeskApp());
    await tester.pumpAndSettle();

    // Verify Home screen loads
    expect(find.textContaining('Alex'), findsWidgets);
    expect(find.text('STREAK'), findsOneWidget);
    expect(find.text("Today's Schedule"), findsOneWidget);

    // Verify bottom navigation items exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Academics'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Planner'), findsOneWidget);

    // Tap Academics tab
    await tester.tap(find.text('Academics'));
    await tester.pumpAndSettle();
    expect(find.text('Overview & Subjects'), findsOneWidget);
    expect(find.text('Registered Courses'), findsOneWidget);
    expect(find.text('CS201'), findsWidgets);

    // Tap Library tab
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Saved Study Videos'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);

    // Tap Planner tab
    await tester.tap(find.text('Planner'));
    await tester.pumpAndSettle();
    expect(find.text('Calendar & Tasks'), findsOneWidget);
    expect(find.text('Week 43'), findsOneWidget);

    // Return to Home tab
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Alex'), findsWidgets);
  });

  testWidgets('Directly open and test Subject Details CS201', (WidgetTester tester) async {
    configurePhoneDimensions(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SubjectDetailsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Data Structures & Algorithms'), findsOneWidget);
    expect(find.text('Dr. Vance'), findsOneWidget);
    expect(find.text('CS201 • 4 Credits • Core'), findsOneWidget);
    expect(find.text('Syllabus & Units'), findsOneWidget);
    expect(find.text('Trees & Hierarchical Structures'), findsOneWidget);
    expect(find.text('Current Focus'), findsOneWidget);
  });

  testWidgets('Directly open and test Daily Journal Editor', (WidgetTester tester) async {
    configurePhoneDimensions(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: JournalEditorScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learning Flow State'), findsOneWidget);
    expect(find.text('What I Learned Today'), findsOneWidget);
    expect(find.text('Accomplishments & Blockers'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    // Select different mood
    await tester.tap(find.text('High Energy'));
    await tester.pumpAndSettle();

    // Verify selected
    expect(find.text('High Energy'), findsOneWidget);
  });

  testWidgets('Quick action sheet (+) opens from main shell', (WidgetTester tester) async {
    configurePhoneDimensions(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StuDeskApp());
    await tester.pumpAndSettle();

    // Center (+) button has size 24
    final plusButton = find.byWidgetPredicate(
      (widget) => widget is Icon && widget.icon == Icons.add_rounded && widget.size == 24,
    );
    expect(plusButton, findsOneWidget);
    await tester.tap(plusButton);
    await tester.pumpAndSettle();

    // Verify modal options
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('New Daily Journal Entry'), findsOneWidget);
    expect(find.text('Create Academic Task'), findsOneWidget);
    expect(find.text("Log Today's Attendance"), findsOneWidget);
  });

  testWidgets('Theme toggle switches mode cleanly', (WidgetTester tester) async {
    configurePhoneDimensions(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StuDeskApp());
    await tester.pumpAndSettle();

    final initialBrightness = ThemeController.instance.isDarkMode;

    // Toggle theme
    ThemeController.instance.toggleTheme();
    await tester.pumpAndSettle();

    expect(ThemeController.instance.isDarkMode, !initialBrightness);

    // Toggle back
    ThemeController.instance.toggleTheme();
    await tester.pumpAndSettle();

    expect(ThemeController.instance.isDarkMode, initialBrightness);
  });

  testWidgets('Startup error fallback renders recovery UI instead of black screen', (WidgetTester tester) async {
    final details = FlutterErrorDetails(
      exception: Exception('Simulated widget failure'),
      stack: StackTrace.current,
    );

    final errorWidget = ErrorWidget.builder(details);

    await tester.pumpWidget(errorWidget);
    await tester.pumpAndSettle();

    expect(find.text('StuDesk Interface Error'), findsOneWidget);
    expect(find.text('Reload StuDesk'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });
}

