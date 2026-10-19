import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/academics/presentation/academics_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/journal/presentation/journal_editor_screen.dart';
import 'features/library/presentation/library_screen.dart';
import 'features/planner/presentation/planner_screen.dart';
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
    return MaterialApp(
      title: 'StuDesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeController.instance.themeMode,
      home: const MainNavigationShell(),
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

  void _openQuickActionSheet() {
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
              const SizedBox(height: 18),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: stuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionTile(
                icon: Icons.edit_note_rounded,
                iconColor: stuTheme.accent,
                title: 'New Daily Journal Entry',
                subtitle: 'Record study momentum and flow state',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JournalEditorScreen(),
                    ),
                  );
                },
              ),
              _buildActionTile(
                icon: Icons.add_task_rounded,
                iconColor: stuTheme.accent,
                title: 'Create Academic Task',
                subtitle: 'Set assignment due date & priority',
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToTab(3); // Go to Planner
                },
              ),
              _buildActionTile(
                icon: Icons.how_to_reg_rounded,
                iconColor: stuTheme.success,
                title: 'Log Today\'s Attendance',
                subtitle: 'Check in to current scheduled lecture',
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToTab(1); // Go to Academics
                },
              ),
              _buildActionTile(
                icon: Icons.timer_rounded,
                iconColor: stuTheme.accent,
                title: 'Start 25m Focus Block',
                subtitle: 'Pomodoro timer for distraction-free study',
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: stuTheme.surfaceTier3,
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Pomodoro focus session active: 25 minutes',
                        style: TextStyle(color: stuTheme.textPrimary),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onNavigateToAcademics: () => _navigateToTab(1),
            onNavigateToPlanner: () => _navigateToTab(3),
          ),
          AcademicsScreen(
            onNavigateToPlanner: () => _navigateToTab(3),
          ),
          LibraryScreen(
            onNavigateToPlanner: () => _navigateToTab(3),
          ),
          const PlannerScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: _navigateToTab,
        onQuickCreate: _openQuickActionSheet,
      ),
    );
  }
}
