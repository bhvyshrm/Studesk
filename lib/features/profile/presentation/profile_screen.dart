import 'package:flutter/material.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/data/auth_service.dart';
import '../data/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _institutionController;
  late TextEditingController _courseController;
  late String _selectedYear;
  late String _selectedSemester;

  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _academicYears = [
    'Year 1',
    'Year 2',
    'Year 3',
    'Year 4',
    'Graduate / Master',
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
  ];

  @override
  void initState() {
    super.initState();
    final profile = StuDeskRepository.instance.profile;
    final currentUser = AuthService.instance.currentUser;

    _nameController = TextEditingController(text: profile.name);
    // Email comes directly from authenticated identity if available
    _emailController = TextEditingController(
      text: currentUser?.email ?? profile.email,
    );
    _institutionController = TextEditingController(text: profile.institution);
    _courseController = TextEditingController(text: profile.course);

    _selectedYear = _academicYears.contains(profile.academicYear)
        ? profile.academicYear
        : _academicYears[1];

    _selectedSemester = _semesters.contains(profile.semester)
        ? profile.semester
        : _semesters[3];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _institutionController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final current = StuDeskRepository.instance.profile;
    final updated = current.copyWith(
      name: _nameController.text.trim(),
      college: _institutionController.text.trim(),
      course: _courseController.text.trim(),
      academicYear: _selectedYear,
      semester: _selectedSemester,
    );

    try {
      await ProfileService.instance.saveProfile(updated);
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.stuTheme.surfaceTier3,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: context.stuTheme.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profile updated successfully',
                    style: TextStyle(color: context.stuTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save profile: $e';
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.stuTheme.surfaceTier1,
        title: Text(
          'Sign Out',
          style: TextStyle(color: context.stuTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to end your current session?',
          style: TextStyle(color: context.stuTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.stuTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.stuTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      await AuthService.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;
    final profile = StuDeskRepository.instance.profile;
    final currentUser = AuthService.instance.currentUser;
    final hasGoogleAvatar = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
    final isGoogleAuth = currentUser != null;

    return Scaffold(
      backgroundColor: stuTheme.canvas,
      appBar: AppBar(
        backgroundColor: stuTheme.canvas,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: stuTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Student Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: stuTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              size: 20,
              color: stuTheme.textSecondary,
            ),
            onPressed: () => ThemeController.instance.toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: stuTheme.surfaceTier1,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: stuTheme.border),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: stuTheme.surfaceTier2,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: stuTheme.accent.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: hasGoogleAvatar
                                    ? Image.network(
                                        profile.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            _buildAvatarFallback(stuTheme, profile.name),
                                      )
                                    : _buildAvatarFallback(stuTheme, profile.name),
                              ),
                              if (isGoogleAuth)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: stuTheme.surfaceTier1,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: stuTheme.border,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: stuTheme.accent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: stuTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentUser?.email ?? profile.email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: stuTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isGoogleAuth
                                            ? stuTheme.success
                                            : stuTheme.accent)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isGoogleAuth
                                        ? 'Supabase Cloud Account'
                                        : 'Local Student Mode',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isGoogleAuth
                                          ? stuTheme.success
                                          : stuTheme.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: stuTheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: stuTheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: stuTheme.error, fontSize: 13),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Academic Profile Fields Form Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: stuTheme.surfaceTier1,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: stuTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Academic Credentials',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: stuTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Read-Only Authenticated Email Field
                          _buildTextField(
                            label: 'Account Email',
                            controller: _emailController,
                            readOnly: true,
                            prefixIcon: Icons.lock_outline_rounded,
                            helperText:
                                'Email is provided by your authenticated account and cannot be modified.',
                            stuTheme: stuTheme,
                          ),

                          const SizedBox(height: 16),

                          // Full Name
                          _buildTextField(
                            label: 'Full Name',
                            controller: _nameController,
                            prefixIcon: Icons.badge_outlined,
                            stuTheme: stuTheme,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Institution / College
                          _buildTextField(
                            label: 'Institution / College',
                            controller: _institutionController,
                            prefixIcon: Icons.account_balance_outlined,
                            stuTheme: stuTheme,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your institution name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Course or Degree
                          _buildTextField(
                            label: 'Course / Degree',
                            controller: _courseController,
                            prefixIcon: Icons.school_outlined,
                            stuTheme: stuTheme,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your course or major';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Academic Year & Semester Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Academic Year',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: stuTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedYear,
                                      isExpanded: true,
                                      dropdownColor: stuTheme.surfaceTier2,
                                      style: TextStyle(
                                        color: stuTheme.textPrimary,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: stuTheme.surfaceTier2,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: stuTheme.border),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: stuTheme.border),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: stuTheme.accent),
                                        ),
                                      ),
                                      items: _academicYears
                                          .map(
                                            (yr) => DropdownMenuItem(
                                              value: yr,
                                              child: Text(yr),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedYear = val);
                                        }
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
                                    Text(
                                      'Current Semester',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: stuTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedSemester,
                                      isExpanded: true,
                                      dropdownColor: stuTheme.surfaceTier2,
                                      style: TextStyle(
                                        color: stuTheme.textPrimary,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: stuTheme.surfaceTier2,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 12),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: stuTheme.border),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: stuTheme.border),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                              color: stuTheme.accent),
                                        ),
                                      ),
                                      items: _semesters
                                          .map(
                                            (sem) => DropdownMenuItem(
                                              value: sem,
                                              child: Text(sem),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedSemester = val);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: stuTheme.accent,
                          foregroundColor: stuTheme.onAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isSaving ? null : _handleSave,
                        child: _isSaving
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: stuTheme.onAccent,
                                ),
                              )
                            : const Text(
                                'Save Profile Details',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Sign Out Button
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: stuTheme.error,
                          side: BorderSide(
                            color: stuTheme.error.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _handleSignOut,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout_rounded,
                                  size: 18, color: stuTheme.error),
                              const SizedBox(width: 8),
                              const Text(
                                'Sign Out of Session',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(StuDeskThemeExtension stuTheme, String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join()
        : 'S';
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: stuTheme.accent,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required StuDeskThemeExtension stuTheme,
    IconData? prefixIcon,
    bool readOnly = false,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: stuTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          validator: validator,
          style: TextStyle(
            color: readOnly ? stuTheme.textSecondary : stuTheme.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly
                ? stuTheme.surfaceTier3.withValues(alpha: 0.5)
                : stuTheme.surfaceTier2,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            helperText: helperText,
            helperMaxLines: 2,
            helperStyle: TextStyle(
              fontSize: 11,
              color: stuTheme.textMuted,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon,
                    size: 18,
                    color: readOnly ? stuTheme.textMuted : stuTheme.accent)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: stuTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: stuTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: stuTheme.accent),
            ),
          ),
        ),
      ],
    );
  }
}
