import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studesk/app.dart';
import 'package:studesk/core/config/app_bootstrap.dart';
import 'package:studesk/core/data/studesk_repository.dart';
import 'package:studesk/core/theme/theme_controller.dart';
import 'package:studesk/features/auth/data/auth_service.dart';
import 'package:studesk/features/home/presentation/home_screen.dart';
import 'package:studesk/shared/widgets/app_bottom_nav_bar.dart';
import 'package:studesk/shared/widgets/studesk_wordmark.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    AppBootstrap.configureErrorHandling();
    SharedPreferences.setMockInitialValues({});
    await StuDeskRepository.instance.init();
    await StuDeskRepository.instance.updateProfile(
      StuDeskRepository.instance.profile.copyWith(
        name: 'Jordan Lee',
        preferredName: 'Jordan',
        college: 'Apex University',
        course: 'Computer Science',
        onboardingCompleted: true,
      ),
    );
    AuthService.instance.enterDemoMode();
  });

  void configurePhoneDimensions(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532); // iPhone standard resolution
    tester.view.devicePixelRatio = 3.0;
  }

  testWidgets('StuDesk App smoke and navigation test across 4 destinations',
      (WidgetTester tester) async {
    configurePhoneDimensions(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StuDeskApp());
    await tester.pumpAndSettle();

    // Verify Home screen loads with StuDesk editorial wordmark & plan sections
    expect(find.byType(StuDeskWordmark), findsWidgets);
    expect(find.text("Today's Plan"), findsOneWidget);
    expect(find.text('Coming Up'), findsOneWidget);

    // Verify bottom navigation destinations by accessible tooltips
    expect(find.byTooltip('Home Dashboard'), findsOneWidget);
    expect(find.byTooltip('Syllabus, Notes & Timetable'), findsOneWidget);
    expect(find.byTooltip('Personal Learning Collections & Resources'), findsOneWidget);
    expect(find.byTooltip('Profile, Attendance & Settings'), findsOneWidget);

    // Navigate to Academics tab
    await tester.tap(find.byTooltip('Syllabus, Notes & Timetable'));
    await tester.pumpAndSettle();
    expect(find.text('Syllabus'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Timetable'), findsOneWidget);

    // Navigate to Library tab
    await tester.tap(find.byTooltip('Personal Learning Collections & Resources'));
    await tester.pumpAndSettle();
    expect(find.text('Your library is empty'), findsOneWidget);
    expect(find.text('Create Collection'), findsWidgets);

    // Navigate to Profile tab
    await tester.tap(find.byTooltip('Profile, Attendance & Settings'));
    await tester.pumpAndSettle();
    expect(find.text('My College Life'), findsOneWidget);
    expect(find.text('My Schedule'), findsOneWidget);
    expect(find.text('My App'), findsOneWidget);

    // Return to Home tab
    await tester.tap(find.byTooltip('Home Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text("Today's Plan"), findsOneWidget);
  });

  testWidgets('Quick action sheet (+) opens from main shell', (WidgetTester tester) async {
    configurePhoneDimensions(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StuDeskApp());
    await tester.pumpAndSettle();

    // Contextual Floating Action Button
    final plusButton = find.byTooltip('Quick Add (+)');
    expect(plusButton, findsOneWidget);
    await tester.tap(plusButton);
    await tester.pumpAndSettle();

    // Verify action sheet options
    expect(find.textContaining('Quick Actions'), findsOneWidget);
    expect(find.text('New Task'), findsOneWidget);
    expect(find.text('New Event'), findsOneWidget);
    expect(find.text('Upcoming Exam'), findsOneWidget);
    expect(find.text('Quick Reminder'), findsOneWidget);
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

  testWidgets('Startup error fallback renders recovery UI instead of black screen',
      (WidgetTester tester) async {
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

  testWidgets('AppBottomNavBar maintains constrained height leaving space for body',
      (WidgetTester tester) async {
    configurePhoneDimensions(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StuDeskApp());
    await tester.pumpAndSettle();

    // Verify the bottom nav bar is bounded and does not consume the whole screen
    final navFinder = find.byType(AppBottomNavBar);
    expect(navFinder, findsOneWidget);
    final navSize = tester.getSize(navFinder);
    expect(navSize.height, lessThan(120.0));
    expect(navSize.height, greaterThan(50.0));

    // Verify Home dashboard body has substantial height (> 500)
    final homeFinder = find.byType(HomeScreen);
    expect(homeFinder, findsOneWidget);
    final homeSize = tester.getSize(homeFinder);
    expect(homeSize.height, greaterThan(600.0));
  });
}
