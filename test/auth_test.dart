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
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StuDeskRepository.instance.init();
  });

  const testUser = User(
    id: '00000000-0000-0000-0000-000000000001',
    appMetadata: {},
    userMetadata: {'full_name': 'Jordan Lee'},
    aud: 'authenticated',
    createdAt: '2026-10-21T00:00:00Z',
    email: 'jordan@example.com',
  );

  group('AuthService Tests', () {
    test('Set authenticated for testing and sign out cleans session', () async {
      final auth = AuthService.instance;
      auth.setAuthenticatedForTesting(testUser);

      expect(auth.isAuthenticated, isTrue);
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.currentUser?.email, equals('jordan@example.com'));
      expect(auth.errorMessage, isNull);

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
    testWidgets(
      'AuthScreen renders branded Google OAuth button and no local demo mode',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const AuthScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('StuDesk'), findsOneWidget);
        expect(
          find.text('Your Intelligent Student Workspace & Academic Desk'),
          findsOneWidget,
        );
        expect(find.text('Continue with Google'), findsOneWidget);
        // Confirmed: No local demo bypass button in Google-only auth mode
        expect(find.text('Continue in Local Student Mode'), findsNothing);
      },
    );

    testWidgets(
      'AuthGate routes to OnboardingScreen when onboarding is pending',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = StuDeskRepository.instance;
        await repo.updateProfile(
          repo.profile.copyWith(onboardingCompleted: false),
        );
        AuthService.instance.setAuthenticatedForTesting(testUser);

        await tester.pumpWidget(const StuDeskApp());
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(find.text('Welcome to StuDesk'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      },
    );

    testWidgets(
      'AuthGate routes to MainNavigationShell when onboarding is completed',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = StuDeskRepository.instance;
        await repo.updateProfile(
          repo.profile.copyWith(name: 'Jordan', onboardingCompleted: true),
        );
        AuthService.instance.setAuthenticatedForTesting(testUser);

        await tester.pumpWidget(const StuDeskApp());
        await tester.pumpAndSettle();

        expect(find.byType(MainNavigationShell), findsOneWidget);
      },
    );

    testWidgets('ProfileScreen renders student cards and edit profile action', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = StuDeskRepository.instance;
      await repo.updateProfile(
        repo.profile.copyWith(
          name: 'Jordan Lee',
          preferredName: 'Jordan',
          college: 'Apex Institute',
          course: 'Computer Science',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const ProfileScreen()),
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
