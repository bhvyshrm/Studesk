import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studesk/app.dart';
import 'package:studesk/core/config/supabase_config.dart';
import 'package:studesk/core/theme/app_theme.dart';
import 'package:studesk/features/auth/data/auth_service.dart';
import 'package:studesk/features/auth/presentation/auth_screen.dart';
import 'package:studesk/features/profile/presentation/profile_screen.dart';

void main() {
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

  group('AuthScreen & Routing Widget Tests', () {
    testWidgets('AuthScreen renders branded Google OAuth and Demo mode buttons',
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

    testWidgets('AuthGate routes to MainNavigationShell in Demo Mode',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      AuthService.instance.enterDemoMode();

      await tester.pumpWidget(const StuDeskApp());
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationShell), findsOneWidget);
    });

    testWidgets('ProfileScreen renders read-only email and editable fields',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Student Profile'), findsOneWidget);
      expect(find.text('Academic Credentials'), findsOneWidget);
      expect(find.text('Account Email'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Institution / College'), findsOneWidget);
      expect(find.text('Course / Degree'), findsOneWidget);
      expect(find.text('Save Profile Details'), findsOneWidget);
      expect(find.text('Sign Out of Session'), findsOneWidget);
    });
  });
}
