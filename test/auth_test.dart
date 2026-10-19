import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studesk/core/config/supabase_config.dart';
import 'package:studesk/core/theme/app_theme.dart';
import 'package:studesk/features/auth/data/auth_service.dart';
import 'package:studesk/features/auth/presentation/auth_screen.dart';

void main() {
  group('AuthService Tests', () {
    test('Defaults safely to Local Demo Mode when backend is unconfigured', () async {
      final auth = AuthService.instance;
      await auth.init();

      expect(auth.isBackendConfigured, SupabaseConfig.isConfigured);
      if (!auth.isBackendConfigured) {
        expect(auth.status, AuthStatus.offlineDemoMode);
        expect(auth.isDemoMode, isTrue);
      }
    });

    test('Entering demo mode updates status and clears error messages', () {
      final auth = AuthService.instance;
      auth.enterDemoMode();

      expect(auth.status, AuthStatus.offlineDemoMode);
      expect(auth.isDemoMode, isTrue);
      expect(auth.errorMessage, isNull);
    });
  });

  group('AuthScreen Widget Tests', () {
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
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Continue in Local Student Mode'), findsOneWidget);
    });
  });
}
