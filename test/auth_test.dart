import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studesk/app.dart';
import 'package:studesk/core/config/supabase_config.dart';
import 'package:studesk/core/data/studesk_repository.dart';
import 'package:studesk/core/theme/app_theme.dart';
import 'package:studesk/features/auth/data/auth_service.dart';
import 'package:studesk/features/auth/presentation/auth_screen.dart';
import 'package:studesk/features/auth/presentation/onboarding_screen.dart';
import 'package:studesk/features/profile/presentation/profile_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StuDeskRepository.instance.init();
  });

  group('AuthService Tests', () {
    test('Enters Local Demo Mode and resets state cleanly', () {
      final auth = AuthService.instance;
      auth.enterDemoMode();

      expect(auth.isDemoMode, isTrue);
      expect(auth.status, AuthStatus.offlineDemoMode);
      expect(auth.currentUser, isNull);
      expect(auth.errorMessage, isNull);
    });

    test('Sign out clears session and sets status to unauthenticated', () async {
      final auth = AuthService.instance;
      await auth.signOut();

      expect(auth.isAuthenticated, isFalse);
      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.currentUser, isNull);
    });

    test('SupabaseConfig validates environment configuration properties', () {
      expect(SupabaseConfig.url, isNotEmpty);
      expect(SupabaseConfig.anonKey, isNotEmpty);
      expect(SupabaseConfig.webRedirectUrl, equals('http://localhost:5001'));
      expect(SupabaseConfig.isConfigured, isTrue);
      expect(SupabaseConfig.maskedAnonKey, contains('...'));
    });
  });

  group('AuthGate & Screen Routing Tests', () {
    testWidgets('AuthScreen renders branded Google OAuth and Local mode buttons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AuthScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('StuDesk'), findsOneWidget);
      expect(find.text('Academic Companion & Intelligent Desk'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue in Local Student Mode'), findsOneWidget);
    });

    testWidgets('AuthGate routes to OnboardingScreen when onboarding is pending',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = StuDeskRepository.instance;
      await repo.updateProfile(repo.profile.copyWith(onboardingCompleted: false));
      AuthService.instance.enterDemoMode();

      await tester.pumpWidget(const StuDeskApp());
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Welcome to StuDesk'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('AuthGate routes to MainNavigationShell when onboarding is completed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = StuDeskRepository.instance;
      await repo.updateProfile(repo.profile.copyWith(
        name: 'Jordan',
        onboardingCompleted: true,
      ));
      AuthService.instance.enterDemoMode();

      await tester.pumpWidget(const StuDeskApp());
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationShell), findsOneWidget);
    });

    testWidgets('ProfileScreen renders student cards and edit profile action',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = StuDeskRepository.instance;
      await repo.updateProfile(repo.profile.copyWith(
        name: 'Jordan Lee',
        preferredName: 'Jordan',
        college: 'Apex Institute',
        course: 'Computer Science',
      ));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jordan'), findsOneWidget);
      expect(find.text('My College Life'), findsOneWidget);
      expect(find.text('Apex Institute'), findsOneWidget);
      expect(find.text('Computer Science'), findsOneWidget);
      expect(find.text('My Schedule'), findsOneWidget);
      expect(find.text('My Calendar'), findsOneWidget);
      expect(find.text('My App'), findsOneWidget);
      expect(find.text('Appearance & Theme'), findsOneWidget);
      expect(find.text('Help & How-To Guides'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // Open Edit Profile BottomSheet
      final editButton = find.byTooltip('Edit Profile');
      expect(editButton, findsOneWidget);
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.text('Edit Student Profile'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Preferred Display Name (Greeting)'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });
}
