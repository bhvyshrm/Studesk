import 'package:flutter/material.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/studesk_wordmark.dart';
import '../../profile/data/profile_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  late TextEditingController _nameController;
  late TextEditingController _institutionController;
  late TextEditingController _courseController;
  String _selectedYear = 'Year 1';
  String _selectedSemester = 'Semester 1';
  bool _isSaving = false;

  final List<String> _academicYears = [
    'Year 1',
    'Year 2',
    'Year 3',
    'Year 4',
    'Graduate / Master',
    'Other',
  ];

  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
    'Semester 7',
    'Semester 8',
    'Trimester / Other',
  ];

  @override
  void initState() {
    super.initState();
    final profile = StuDeskRepository.instance.profile;
    _nameController = TextEditingController(text: profile.effectiveDisplayName);
    _institutionController = TextEditingController(text: profile.institution);
    _courseController = TextEditingController(text: profile.course);
    if (profile.academicYear.isNotEmpty && _academicYears.contains(profile.academicYear)) {
      _selectedYear = profile.academicYear;
    }
    if (profile.semester.isNotEmpty && _semesters.contains(profile.semester)) {
      _selectedSemester = profile.semester;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _institutionController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding({bool skipped = false}) async {
    setState(() => _isSaving = true);
    final repo = StuDeskRepository.instance;
    final current = repo.profile;

    final updated = current.copyWith(
      preferredName: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : (current.name.isNotEmpty ? current.name.split(' ').first : 'Student'),
      name: current.name.isNotEmpty ? current.name : _nameController.text.trim(),
      college: skipped ? current.college : _institutionController.text.trim(),
      course: skipped ? current.course : _courseController.text.trim(),
      academicYear: skipped ? current.academicYear : _selectedYear,
      semester: skipped ? current.semester : _selectedSemester,
      onboardingCompleted: true,
    );

    try {
      await ProfileService.instance.saveProfile(updated);
    } catch (_) {
      // Offline fallback
      await repo.updateProfile(updated);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      widget.onCompleted();
    }
  }

  void _nextPage() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding(skipped: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Scaffold(
      backgroundColor: stuTheme.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              children: [
                // Header with wordmark & Skip action
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: StuDeskWordmark(fontSize: 20, showDot: true),
                      ),
                      TextButton(
                        onPressed: _isSaving ? null : () => _completeOnboarding(skipped: true),
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            color: stuTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Step Progress Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: List.generate(3, (index) {
                      final isActive = index <= _currentStep;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: isActive ? stuTheme.accent : stuTheme.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (idx) => setState(() => _currentStep = idx),
                    children: [
                      _buildWelcomeStep(stuTheme),
                      _buildAcademicProfileStep(stuTheme),
                      _buildOverviewStep(stuTheme),
                    ],
                  ),
                ),

                // Bottom Action Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stuTheme.accent,
                        foregroundColor: stuTheme.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isSaving ? null : _nextPage,
                      child: _isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: stuTheme.onAccent,
                              ),
                            )
                          : Text(
                              _currentStep == 2 ? 'Enter StuDesk' : 'Continue',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: stuTheme.onAccent,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep(StuDeskThemeExtension stuTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: stuTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.waving_hand_rounded, color: stuTheme.accent, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome to StuDesk',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: stuTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personal student companion for organizing classes, syllabi, study resources, deadlines, and attendance in one distraction-free desk.',
            style: TextStyle(
              fontSize: 14,
              color: stuTheme.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'What should we call you?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: stuTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: TextStyle(color: stuTheme.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Your preferred display name',
              hintStyle: TextStyle(color: stuTheme.textMuted, fontSize: 14),
              filled: true,
              fillColor: stuTheme.surfaceTier1,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: stuTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: stuTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: stuTheme.accent, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicProfileStep(StuDeskThemeExtension stuTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: stuTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.school_rounded, color: stuTheme.accent, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            'Your Academic Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: stuTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure your college and degree to organize your timetable, syllabi, and attendance records.',
            style: TextStyle(
              fontSize: 14,
              color: stuTheme.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),

          // Institution
          Text(
            'College / Institution (Optional)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: stuTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _institutionController,
            style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. Stanford University, IIT Delhi',
              hintStyle: TextStyle(color: stuTheme.textMuted, fontSize: 13),
              filled: true,
              fillColor: stuTheme.surfaceTier1,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.accent)),
            ),
          ),
          const SizedBox(height: 16),

          // Course
          Text(
            'Course / Degree Program (Optional)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: stuTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _courseController,
            style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. B.Tech Computer Science, B.Sc Economics',
              hintStyle: TextStyle(color: stuTheme.textMuted, fontSize: 13),
              filled: true,
              fillColor: stuTheme.surfaceTier1,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.accent)),
            ),
          ),
          const SizedBox(height: 16),

          // Year and Semester Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Academic Year', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: stuTheme.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedYear,
                      isExpanded: true,
                      dropdownColor: stuTheme.surfaceTier1,
                      style: TextStyle(color: stuTheme.textPrimary, fontSize: 13.5),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: stuTheme.surfaceTier1,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.border)),
                      ),
                      items: _academicYears.map((yr) => DropdownMenuItem(value: yr, child: Text(yr))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Semester', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: stuTheme.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSemester,
                      isExpanded: true,
                      dropdownColor: stuTheme.surfaceTier1,
                      style: TextStyle(color: stuTheme.textPrimary, fontSize: 13.5),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: stuTheme.surfaceTier1,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.border)),
                      ),
                      items: _semesters.map((sem) => DropdownMenuItem(value: sem, child: Text(sem))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSemester = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStep(StuDeskThemeExtension stuTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: stuTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.check_circle_outline_rounded, color: stuTheme.accent, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            'Ready to start',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: stuTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here is what StuDesk helps you organize:',
            style: TextStyle(
              fontSize: 14,
              color: stuTheme.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),

          _buildPillarTile(
            icon: Icons.calendar_today_rounded,
            title: 'Daily Plan & Coming Up',
            subtitle: 'Classes, deadlines, tasks, and exam countdowns in one clear view.',
            stuTheme: stuTheme,
          ),
          _buildPillarTile(
            icon: Icons.school_rounded,
            title: 'Academics & Timetable',
            subtitle: 'Your weekly class schedule, subject syllabi, and coursework files.',
            stuTheme: stuTheme,
          ),
          _buildPillarTile(
            icon: Icons.menu_book_rounded,
            title: 'Learning Library',
            subtitle: 'Personal collections for YouTube tutorials, documentation, and links.',
            stuTheme: stuTheme,
          ),
          _buildPillarTile(
            icon: Icons.how_to_reg_rounded,
            title: 'Attendance Records',
            subtitle: 'Track presence and absences with plain counts — no fake percentages.',
            stuTheme: stuTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildPillarTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required StuDeskThemeExtension stuTheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: stuTheme.surfaceTier1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: stuTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: stuTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: stuTheme.accent, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: stuTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: stuTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
