import 'package:flutter/material.dart';
import 'core/data/studesk_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/academics/presentation/academics_screen.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/auth/presentation/auth_splash_screen.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/presentation/unconfigured_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/library/presentation/library_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'shared/widgets/app_bottom_nav_bar.dart';

class StuDeskApp extends StatefulWidget {
  const StuDeskApp({super.key});

  @override
  State<StuDeskApp> createState() => _StuDeskAppState();
}

class _StuDeskAppState extends State<StuDeskApp> {
  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = ThemeController.instance;

    return MaterialApp(
      title: 'StuDesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: themeCtrl.isAmoled ? AppTheme.amoledDarkTheme : AppTheme.darkTheme,
      themeMode: themeCtrl.themeMode,
      builder: (context, child) {
        return child ??
            const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;

        // 1. Splash screen while checking session or initialization
        if (auth.status == AuthStatus.uninitialized) {
          return const AuthSplashScreen();
        }

        // 2. Unconfigured credentials state
        if (auth.status == AuthStatus.unconfigured) {
          return const UnconfiguredConfigScreen();
        }

        // 3. Authenticated session or Demo / Guest mode
        if (auth.isAuthenticated || auth.isDemoMode) {
          return ListenableBuilder(
            listenable: StuDeskRepository.instance,
            builder: (context, _) {
              final repo = StuDeskRepository.instance;
              if (!repo.isInitialized) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // First-time student onboarding check
              if (!repo.profile.onboardingCompleted) {
                return OnboardingScreen(
                  onCompleted: () {
                    // Navigate into MainNavigationShell
                  },
                );
              }

              return const MainNavigationShell();
            },
          );
        }

        // 4. Unauthenticated login view
        return const AuthScreen();
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openContextualActionSheet() {
    final stuTheme = context.stuTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: stuTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _getActionSheetTitle(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              ..._buildContextualActionTiles(ctx, stuTheme),
            ],
          ),
        ),
      ),
    );
  }

  String _getActionSheetTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Quick Actions (Home)';
      case 1:
        return 'Quick Actions (Academics)';
      case 2:
        return 'Quick Actions (Library)';
      default:
        return 'Quick Actions';
    }
  }

  List<Widget> _buildContextualActionTiles(BuildContext ctx, StuDeskThemeExtension stuTheme) {
    switch (_currentIndex) {
      case 0: // Home
        return [
          _buildActionTile(
            icon: Icons.check_circle_outline_rounded,
            iconColor: stuTheme.accent,
            title: 'New Task',
            subtitle: 'Academic task or homework with due date',
            onTap: () {
              Navigator.pop(ctx);
              _navigateToTab(0);
            },
          ),
          _buildActionTile(
            icon: Icons.calendar_month_rounded,
            iconColor: stuTheme.accent,
            title: 'New Event',
            subtitle: 'Campus meeting, workshop, or event',
            onTap: () {
              Navigator.pop(ctx);
              _navigateToTab(0);
            },
          ),
          _buildActionTile(
            icon: Icons.event_available_rounded,
            iconColor: stuTheme.error,
            title: 'Upcoming Exam',
            subtitle: 'Scheduled quiz, midterm, or final exam',
            onTap: () {
              Navigator.pop(ctx);
              _navigateToTab(0);
            },
          ),
          _buildActionTile(
            icon: Icons.alarm_rounded,
            iconColor: stuTheme.warning,
            title: 'Quick Reminder',
            subtitle: 'Timely alert for revision or submission',
            onTap: () {
              Navigator.pop(ctx);
              _navigateToTab(0);
            },
          ),
        ];

      case 1: // Academics
        return [
          _buildActionTile(
            icon: Icons.school_rounded,
            iconColor: stuTheme.accent,
            title: 'Add Syllabus / Subject',
            subtitle: 'Register course code, title, and topic list',
            onTap: () {
              Navigator.pop(ctx);
            },
          ),
          _buildActionTile(
            icon: Icons.description_outlined,
            iconColor: stuTheme.warning,
            title: 'Create Academic Note',
            subtitle: 'Coursework notes, formulas, and revision text',
            onTap: () {
              Navigator.pop(ctx);
            },
          ),
          _buildActionTile(
            icon: Icons.schedule_rounded,
            iconColor: stuTheme.success,
            title: 'Add Timetable Class',
            subtitle: 'Schedule weekly lecture, lab, or seminar slot',
            onTap: () {
              Navigator.pop(ctx);
            },
          ),
        ];

      case 2: // Library
        return [
          _buildActionTile(
            icon: Icons.create_new_folder_outlined,
            iconColor: stuTheme.accent,
            title: 'Create Collection',
            subtitle: 'Organize resources by topic (e.g. DSA Prep)',
            onTap: () {
              Navigator.pop(ctx);
            },
          ),
          _buildActionTile(
            icon: Icons.add_link_rounded,
            iconColor: Colors.red.shade400,
            title: 'Save YouTube / Web Resource',
            subtitle: 'Bookmark study playlists, articles, and documentation',
            onTap: () {
              Navigator.pop(ctx);
            },
          ),
        ];

      default:
        return [];
    }
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final stuTheme = context.stuTheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: stuTheme.textPrimary,
          fontSize: 14.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: stuTheme.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: stuTheme.textSecondary,
        size: 18,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;
    final showFAB = _currentIndex < 3; // Section 3: On profile, hide irrelevant create button

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onNavigateToAcademics: () => _navigateToTab(1),
            onNavigateToLibrary: () => _navigateToTab(2),
            onNavigateToProfile: () => _navigateToTab(3),
          ),
          const AcademicsScreen(),
          const LibraryScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: showFAB
          ? FloatingActionButton(
              onPressed: _openContextualActionSheet,
              backgroundColor: stuTheme.accent,
              foregroundColor: stuTheme.onAccent,
              elevation: 3,
              shape: const CircleBorder(),
              tooltip: 'Quick Add (+)',
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: _navigateToTab,
      ),
    );
  }
}
