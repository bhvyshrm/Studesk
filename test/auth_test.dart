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
import 'package:studesk/shared/widgets/studesk_wordmark.dart';
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
    userMetadata: {'full_name': 'Jordan Lee', 'username': 'jordan_lee'},
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

    test('Password reset returns safe non-enumerating confirmation', () async {
      final auth = AuthService.instance;
      final msg = await auth.sendPasswordResetEmail(identifier: 'student_alex');
      expect(msg, contains('password reset link has been sent'));
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

  group('AuthScreen UI & Interaction Tests', () {
    testWidgets(
      'AuthScreen renders AMOLED monochrome login view without Google login button',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const AuthScreen()),
        );
        await tester.pumpAndSettle();

        // Branding
        expect(find.byType(StuDeskWordmark), findsOneWidget);
        expect(
          find.text('Your Intelligent Student Workspace & Academic Desk'),
          findsOneWidget,
        );

        // Login Controls
        expect(find.text('Sign In'), findsNWidgets(2)); // Title and Button
        expect(find.text('STUDENT USERNAME'), findsOneWidget);
        expect(find.text('PASSWORD'), findsOneWidget);
        expect(find.text('Forgot password?'), findsOneWidget);
        expect(find.text('Create Account'), findsOneWidget);

        // CRITICAL: Ensure Google sign-in is NOT present
        expect(find.text('Continue with Google'), findsNothing);
        expect(find.text('Connecting to Google...'), findsNothing);
      },
    );

    testWidgets('AuthScreen validates blank inputs on sign in', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const AuthScreen()),
      );
      await tester.pumpAndSettle();

      // Tap Sign In button without typing
      final signInBtn = find.widgetWithText(ElevatedButton, 'Sign In');
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your username.'), findsOneWidget);

      // Enter username only
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'alex_chen');
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets(
      'AuthScreen navigates to Create Account, validates fields, and supports switching back',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const AuthScreen()),
        );
        await tester.pumpAndSettle();

        // Switch to Create Account
        final createAccountLink = find.text('Create Account');
        await tester.tap(createAccountLink);
        await tester.pumpAndSettle();

        expect(find.text('CHOOSE USERNAME'), findsOneWidget);
        expect(find.text('EMAIL ADDRESS'), findsOneWidget);
        expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Create Account'),
          findsOneWidget,
        );

        // Submit blank registration
        final createBtn = find.widgetWithText(ElevatedButton, 'Create Account');
        await tester.tap(createBtn);
        await tester.pumpAndSettle();

        expect(find.text('Username cannot be blank.'), findsOneWidget);

        // Switch back to Sign In
        final signInLink = find.text('Sign In');
        await tester.ensureVisible(signInLink);
        await tester.tap(signInLink);
        await tester.pumpAndSettle();

        expect(find.text('STUDENT USERNAME'), findsOneWidget);
      },
    );

    testWidgets('AuthScreen switches to Forgot Password and validates inputs', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const AuthScreen()),
      );
      await tester.pumpAndSettle();

      final forgotLink = find.text('Forgot password?');
      await tester.tap(forgotLink);
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('USERNAME OR EMAIL'), findsOneWidget);

      // Tap Send Reset Link with empty input
      final sendBtn = find.widgetWithText(ElevatedButton, 'Send Reset Link');
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Please enter your username or email address.'),
        findsOneWidget,
      );

      // Enter identifier and submit
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'alex_chen');
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('password reset link has been sent'),
        findsOneWidget,
      );

      // Back to Sign In
      final backBtn = find.text('Back to Sign In');
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.text('STUDENT USERNAME'), findsOneWidget);
    });
  });

  group('AuthGate & Screen Routing Tests', () {
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
