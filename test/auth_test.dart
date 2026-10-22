import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studesk/app.dart';
import 'package:studesk/core/config/supabase_config.dart';
import 'package:studesk/core/data/studesk_repository.dart';
import 'package:studesk/core/theme/app_theme.dart';
import 'package:studesk/features/auth/data/auth_service.dart';
import 'package:studesk/features/auth/presentation/auth_screen.dart';
import 'package:studesk/features/auth/presentation/username_onboarding_screen.dart';
import 'package:studesk/features/profile/data/profile_service.dart';
import 'package:studesk/features/profile/presentation/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StuDeskRepository.instance.init();
    ProfileService.instance.resetState();
  });

  const testUser = User(
    id: '00000000-0000-0000-0000-000000000001',
    appMetadata: {},
    userMetadata: {'full_name': 'Jordan Lee'},
    aud: 'authenticated',
    createdAt: '2026-10-21T00:00:00Z',
    email: 'jordan@example.com',
  );

  group('AuthService & SupabaseConfig Tests', () {
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

    test('SupabaseConfig validates redirect URLs and configuration', () {
      expect(SupabaseConfig.url, isNotEmpty);
      expect(SupabaseConfig.anonKey, isNotEmpty);
      expect(SupabaseConfig.webRedirectUrl, contains('http'));
      expect(
        SupabaseConfig.androidRedirectUrl,
        equals('studesk://login-callback'),
      );
      expect(SupabaseConfig.authRedirectUrl, isNotEmpty);
      expect(SupabaseConfig.isConfigured, isTrue);
      expect(SupabaseConfig.maskedAnonKey, contains('...'));
    });
  });

  group('Username Validation & Security Rules', () {
    final ps = ProfileService.instance;

    test('Rejects blank or whitespace usernames', () {
      expect(ps.validateUsername(null), isNotNull);
      expect(ps.validateUsername(''), isNotNull);
      expect(ps.validateUsername('   '), isNotNull);
    });

    test('Enforces length restrictions (3 to 20 characters)', () {
      expect(
        ps.validateUsername('al'),
        equals('Username must be at least 3 characters.'),
      );
      expect(
        ps.validateUsername('a' * 21),
        equals('Username cannot exceed 20 characters.'),
      );
      expect(ps.validateUsername('alex'), isNull);
      expect(ps.validateUsername('a' * 20), isNull);
    });

    test('Rejects invalid characters, uppercase, and spaces', () {
      expect(ps.validateUsername('alex chen'), isNotNull);
      expect(ps.validateUsername('alex@desk'), isNotNull);
      expect(ps.validateUsername('alex.chen'), isNotNull);
      expect(ps.validateUsername('alex-chen'), isNotNull);
      expect(ps.validateUsername('alex!'), isNotNull);
    });

    test('Rejects system-reserved usernames', () {
      expect(ps.validateUsername('admin'), contains('reserved'));
      expect(ps.validateUsername('studesk'), contains('reserved'));
      expect(ps.validateUsername('support'), contains('reserved'));
      expect(ps.validateUsername('root'), contains('reserved'));
    });

    test(
      'Accepts valid lowercase alphanumeric and underscore combinations',
      () {
        expect(ps.validateUsername('alex_chen'), isNull);
        expect(ps.validateUsername('student2026'), isNull);
        expect(ps.validateUsername('cs_101_dev'), isNull);
        expect(ps.validateUsername('jordan_lee'), isNull);
      },
    );
  });

  group('AuthGate & Screen Routing Tests', () {
    testWidgets(
      'AuthScreen renders strict monochrome layout and Google OAuth button',
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
        expect(find.text('Continue in Local Student Mode'), findsNothing);
      },
    );

    testWidgets(
      'AuthGate routes new user to UsernameOnboardingScreen when username is missing',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = StuDeskRepository.instance;
        await repo.updateProfile(
          repo.profile.copyWith(username: '', onboardingCompleted: false),
        );
        AuthService.instance.setAuthenticatedForTesting(testUser);

        await tester.pumpWidget(const StuDeskApp());
        await tester.pumpAndSettle();

        expect(find.byType(UsernameOnboardingScreen), findsOneWidget);
        expect(find.text('Choose your username'), findsOneWidget);
        expect(
          find.text(
            '3–20 characters. Lowercase letters, numbers, and underscores only.',
          ),
          findsOneWidget,
        );
        expect(find.text('Continue'), findsOneWidget);
      },
    );

    testWidgets(
      'UsernameOnboardingScreen handles input, validation feedback, and Continue action',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        bool completed = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.amoledDarkTheme,
            home: UsernameOnboardingScreen(onCompleted: () => completed = true),
          ),
        );
        await tester.pumpAndSettle();

        final inputField = find.byType(TextField);
        expect(inputField, findsOneWidget);

        // Enter too short username
        await tester.enterText(inputField, 'al');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(
          find.text('Username must be at least 3 characters.'),
          findsOneWidget,
        );

        // Enter valid username
        await tester.enterText(inputField, 'alex_chen');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(find.text('@alex_chen is available'), findsOneWidget);

        // Continue button should now trigger completion
        final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        expect(completed, isTrue);
        expect(
          StuDeskRepository.instance.profile.username,
          equals('alex_chen'),
        );
      },
    );

    testWidgets(
      'AuthGate routes returning user with completed username directly to MainNavigationShell',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final repo = StuDeskRepository.instance;
        await repo.updateProfile(
          repo.profile.copyWith(
            username: 'jordan_lee',
            name: 'Jordan',
            onboardingCompleted: true,
          ),
        );
        AuthService.instance.setAuthenticatedForTesting(testUser);

        await tester.pumpWidget(const StuDeskApp());
        await tester.pumpAndSettle();

        expect(find.byType(MainNavigationShell), findsOneWidget);
        expect(find.byType(UsernameOnboardingScreen), findsNothing);
      },
    );

    testWidgets('ProfileScreen displays username and student information', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = StuDeskRepository.instance;
      await repo.updateProfile(
        repo.profile.copyWith(
          username: 'jordan_lee',
          name: 'Jordan Lee',
          preferredName: 'Jordan',
          college: 'Apex Institute',
          course: 'Computer Science',
          onboardingCompleted: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const ProfileScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jordan'), findsOneWidget);
      expect(find.text('@jordan_lee'), findsOneWidget);
      expect(find.text('My College Life'), findsOneWidget);
      expect(find.text('Apex Institute'), findsOneWidget);
      expect(find.text('Computer Science'), findsOneWidget);
    });

    testWidgets(
      'UsernameOnboardingScreen rejects reserved usernames and disables Continue',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.amoledDarkTheme,
            home: UsernameOnboardingScreen(onCompleted: () {}),
          ),
        );
        await tester.pumpAndSettle();

        final inputField = find.byType(TextField);
        await tester.enterText(inputField, 'studesk');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(
          find.text('This username is reserved. Please pick another.'),
          findsOneWidget,
        );

        final continueBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Continue'),
        );
        expect(continueBtn.onPressed, isNull);
      },
    );

    testWidgets(
      'UsernameOnboardingScreen normalizes case and replaces spaces with underscores',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.amoledDarkTheme,
            home: UsernameOnboardingScreen(onCompleted: () {}),
          ),
        );
        await tester.pumpAndSettle();

        final inputField = find.byType(TextField);
        await tester.enterText(inputField, 'Alex Chen 2026');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        final textFieldWidget = tester.widget<TextField>(inputField);
        expect(textFieldWidget.controller?.text, equals('alex_chen_2026'));
      },
    );
  });
}
