import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/data/auth_service.dart';
import '../data/profile_service.dart';
import 'attendance_screen.dart';
import 'calendar_screen.dart';
import 'help_guides_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StuDeskRepository _repo = StuDeskRepository.instance;
  final ThemeController _themeCtrl = ThemeController.instance;

  void _showEditProfileDialog() {
    final stuTheme = context.stuTheme;
    final profile = _repo.profile;
    final nameCtrl = TextEditingController(text: profile.name);
    final prefNameCtrl = TextEditingController(text: profile.preferredName);
    final bioCtrl = TextEditingController(text: profile.bio);
    final instCtrl = TextEditingController(text: profile.institution);
    final courseCtrl = TextEditingController(text: profile.course);
    String selectedYear = profile.academicYear.isNotEmpty ? profile.academicYear : 'Year 1';
    String selectedSem = profile.semester.isNotEmpty ? profile.semester : 'Semester 1';
    bool isSaving = false;

    final years = ['Year 1', 'Year 2', 'Year 3', 'Year 4', 'Graduate / Master', 'Other'];
    final sems = ['Semester 1', 'Semester 2', 'Semester 3', 'Semester 4', 'Semester 5', 'Semester 6', 'Semester 7', 'Semester 8', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Student Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prefNameCtrl,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Preferred Display Name (Greeting)',
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioCtrl,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Bio / Focus Area',
                    hintText: 'e.g. CS major interested in distributed systems',
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instCtrl,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'College / Institution',
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: courseCtrl,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Course / Degree Program',
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: years.contains(selectedYear) ? selectedYear : years.first,
                        decoration: InputDecoration(
                          labelText: 'Year',
                          filled: true,
                          fillColor: stuTheme.surfaceTier2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: years.map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedYear = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: sems.contains(selectedSem) ? selectedSem : sems.first,
                        decoration: InputDecoration(
                          labelText: 'Semester',
                          filled: true,
                          fillColor: stuTheme.surfaceTier2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: sems.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedSem = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: stuTheme.accent,
                      foregroundColor: stuTheme.onAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            setModalState(() => isSaving = true);
                            final updated = profile.copyWith(
                              name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : profile.name,
                              preferredName: prefNameCtrl.text.trim(),
                              bio: bioCtrl.text.trim(),
                              college: instCtrl.text.trim(),
                              course: courseCtrl.text.trim(),
                              academicYear: selectedYear,
                              semester: selectedSem,
                            );
                            try {
                              await ProfileService.instance.saveProfile(updated);
                            } catch (_) {
                              await _repo.updateProfile(updated);
                            }
                            if (context.mounted) Navigator.pop(ctx);
                          },
                    child: isSaving
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: stuTheme.onAccent, strokeWidth: 2))
                        : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAppearanceCustomizationDialog() {
    final stuTheme = context.stuTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: stuTheme.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Appearance & Theme Modes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Display Mode',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: stuTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildThemeChip(
                      label: 'Light',
                      mode: AppAppearanceMode.light,
                      current: _themeCtrl.appearanceMode,
                      stuTheme: stuTheme,
                      onTap: () {
                        _themeCtrl.setAppearanceMode(AppAppearanceMode.light);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildThemeChip(
                      label: 'Dark',
                      mode: AppAppearanceMode.dark,
                      current: _themeCtrl.appearanceMode,
                      stuTheme: stuTheme,
                      onTap: () {
                        _themeCtrl.setAppearanceMode(AppAppearanceMode.dark);
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildThemeChip(
                      label: 'AMOLED',
                      mode: AppAppearanceMode.amoled,
                      current: _themeCtrl.appearanceMode,
                      stuTheme: stuTheme,
                      onTap: () {
                        _themeCtrl.setAppearanceMode(AppAppearanceMode.amoled);
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Accent Palette',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: stuTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(ThemeController.availableAccents.length, (idx) {
                    final color = ThemeController.availableAccents[idx];
                    final isSelected = _themeCtrl.accentIndex == idx;
                    return GestureDetector(
                      onTap: () {
                        _themeCtrl.setAccentIndex(idx);
                        setModalState(() {});
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 20, color: Colors.black) : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Compact Spacing',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                  ),
                  subtitle: Text(
                    'Denser card and list margins for smaller screens',
                    style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                  ),
                  value: _themeCtrl.isCompactSpacing,
                  activeThumbColor: stuTheme.accent,
                  onChanged: (val) {
                    _themeCtrl.setCompactSpacing(val);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Reduced Motion',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                  ),
                  subtitle: Text(
                    'Minimize page transition and animation duration',
                    style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                  ),
                  value: _themeCtrl.reducedMotion,
                  activeThumbColor: stuTheme.accent,
                  onChanged: (val) {
                    _themeCtrl.setReducedMotion(val);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeChip({
    required String label,
    required AppAppearanceMode mode,
    required AppAppearanceMode current,
    required StuDeskThemeExtension stuTheme,
    required VoidCallback onTap,
  }) {
    final isSelected = current == mode;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? stuTheme.accent : stuTheme.surfaceTier2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.transparent : stuTheme.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? stuTheme.onAccent : stuTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _exportDeskData() async {
    final payload = await _repo.createBackupPayload();
    final jsonStr = jsonEncode(payload.toJson());

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.stuTheme.surfaceTier1,
          title: Text('Export Desk Backup', style: TextStyle(color: context.stuTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your desk data has been packaged into an encrypted JSON export containing ${_repo.courses.length} subjects, ${_repo.tasks.length} tasks, and ${_repo.notes.length} notes.',
                style: TextStyle(fontSize: 13, color: context.stuTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.stuTheme.surfaceTier2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Payload size: ${jsonStr.length} bytes',
                  style: TextStyle(fontSize: 11.5, color: context.stuTheme.textMuted),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.stuTheme.surfaceTier1,
        title: Text('Sign Out', style: TextStyle(color: context.stuTheme.textPrimary)),
        content: Text(
          'Are you sure you want to end your session on this device?',
          style: TextStyle(color: context.stuTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.stuTheme.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _repo.clearUserSessionData();
      await AuthService.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return ListenableBuilder(
      listenable: _repo,
      builder: (context, _) {
        final profile = _repo.profile;
        final currentUser = AuthService.instance.currentUser;
        final email = currentUser?.email ?? profile.email;

        final initials = profile.effectiveDisplayName.isNotEmpty
            ? profile.effectiveDisplayName.substring(0, 1).toUpperCase()
            : 'S';

        return Scaffold(
          backgroundColor: stuTheme.canvas,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 10.1: Personal Identity Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: stuTheme.surfaceTier1,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: stuTheme.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: stuTheme.accent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: stuTheme.accent, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: stuTheme.accent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.effectiveDisplayName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: stuTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.lock_outline_rounded, size: 12, color: stuTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          email.isNotEmpty ? email : 'student@university.edu',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (profile.bio.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      profile.bio,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: stuTheme.textMuted),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              color: stuTheme.accent,
                              tooltip: 'Edit Profile',
                              onPressed: _showEditProfileDialog,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section 10.2: My College Life
                      Text(
                        'My College Life',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: stuTheme.surfaceTier1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: stuTheme.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildInfoRow('Institution', profile.institution.isNotEmpty ? profile.institution : 'Not configured', stuTheme),
                              const Divider(height: 16),
                              _buildInfoRow('Course / Program', profile.course.isNotEmpty ? profile.course : 'Not configured', stuTheme),
                              const Divider(height: 16),
                              _buildInfoRow('Academic Year', profile.academicYear.isNotEmpty ? profile.academicYear : 'Year 1', stuTheme),
                              const Divider(height: 16),
                              _buildInfoRow('Semester', profile.semester.isNotEmpty ? profile.semester : 'Semester 1', stuTheme),
                              const Divider(height: 16),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: stuTheme.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.how_to_reg_rounded, color: stuTheme.accent, size: 20),
                                ),
                                title: Text(
                                  'My Attendance',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                                ),
                                subtitle: Text(
                                  _repo.attendanceSummaryDetail,
                                  style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                                ),
                                trailing: Icon(Icons.chevron_right_rounded, color: stuTheme.textSecondary),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceScreen()));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section 10.3: My Calendar
                      Text(
                        'My Schedule',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: stuTheme.surfaceTier1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: stuTheme.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: stuTheme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.calendar_month_rounded, color: stuTheme.accent, size: 20),
                          ),
                          title: Text(
                            'My Calendar',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                          ),
                          subtitle: Text(
                            'Unified monthly and daily view of tasks, exams, and events',
                            style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                          ),
                          trailing: Icon(Icons.chevron_right_rounded, color: stuTheme.textSecondary),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section 10.4: My App Settings & Guides
                      Text(
                        'My App',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: stuTheme.surfaceTier1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: stuTheme.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.palette_outlined, color: stuTheme.accent, size: 22),
                              title: Text('Appearance & Theme', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: stuTheme.textPrimary)),
                              subtitle: Text(
                                'Light, Dark, and AMOLED modes with gold accent choice',
                                style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                              ),
                              trailing: Icon(Icons.chevron_right_rounded, color: stuTheme.textSecondary),
                              onTap: _showAppearanceCustomizationDialog,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: Icon(Icons.help_outline_rounded, color: stuTheme.accent, size: 22),
                              title: Text('Help & How-To Guides', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: stuTheme.textPrimary)),
                              subtitle: Text(
                                '12 step-by-step guides for organizing your college life',
                                style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                              ),
                              trailing: Icon(Icons.chevron_right_rounded, color: stuTheme.textSecondary),
                              onTap: () => HelpGuidesSheet.show(context),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: Icon(Icons.file_download_outlined, color: stuTheme.accent, size: 22),
                              title: Text('Export Desk Backup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: stuTheme.textPrimary)),
                              subtitle: Text(
                                'Export complete JSON backup of courses, tasks, and notes',
                                style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                              ),
                              trailing: Icon(Icons.chevron_right_rounded, color: stuTheme.textSecondary),
                              onTap: _exportDeskData,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: Icon(Icons.restart_alt_rounded, color: stuTheme.warning, size: 22),
                              title: Text('Restore App Defaults', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: stuTheme.textPrimary)),
                              subtitle: Text(
                                'Reset appearance and preferences without altering academic data',
                                style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                              ),
                              onTap: () async {
                                await _themeCtrl.restoreDefaults();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('App display preferences restored to defaults')),
                                  );
                                }
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: Icon(Icons.logout_rounded, color: stuTheme.error, size: 22),
                              title: Text('Sign Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: stuTheme.error)),
                              onTap: _handleSignOut,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, StuDeskThemeExtension stuTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: stuTheme.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}
