import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class HelpGuidesSheet extends StatelessWidget {
  const HelpGuidesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const HelpGuidesSheet(),
    );
  }

  static const List<Map<String, String>> _guides = [
    {
      'title': '1. Setting up your student profile',
      'content': 'Open the Profile tab. Your StuDesk account provides your student username and email. You can customize your preferred display name, bio, college/institution, degree program, academic year, and current semester at any time.',
    },
    {
      'title': '2. Creating tasks, events, exams, and reminders',
      'content': 'On Home, tap the "+" button or "+ Add" in Today\'s Plan. Choose whether to add a Task (with due date & priority), an Event (with location & date), an Exam (with syllabus cutoff & room), or a Quick Reminder.',
    },
    {
      'title': '3. Managing a subject syllabus',
      'content': 'Go to Academics → Syllabus. Tap "Add Subject" to register a course (e.g. CS201). Tap on the subject card to expand it and tap "Add Topic" to list concepts. Mark topics as completed as you study.',
    },
    {
      'title': '4. Uploading and finding academic notes',
      'content': 'Go to Academics → Notes. Tap the "+" button to create a text note or store coursework summaries. Use the instant search bar or filter chips (PDF, Note, Image) to retrieve revision materials quickly.',
    },
    {
      'title': '5. Creating your weekly timetable',
      'content': 'Go to Academics → Timetable. Select a day (Monday to Sunday) and tap "Add Class". Configure the start time, end time, subject code, classroom, and professor name.',
    },
    {
      'title': '6. Saving learning resources to Library',
      'content': 'Open the Library tab. Tap the link icon to save a YouTube video or playlist URL, documentation link, or study website. Tapping the saved link opens it directly in your browser or YouTube app.',
    },
    {
      'title': '7. Creating and organizing collections',
      'content': 'Inside the Library tab, tap the folder icon to create a topic collection (e.g. "DSA Prep" or "Operating Systems"). When saving a link, assign it to your collection to keep your study desk organized.',
    },
    {
      'title': '8. Recording and correcting attendance',
      'content': 'Open Profile → My Attendance. Select your subject and tap "Mark Present" or "Mark Absent". StuDesk displays plain counts ("18 classes attended", "6 absences recorded") without fake percentage gauges. You can review and correct historical records anytime.',
    },
    {
      'title': '9. Using global search',
      'content': 'Tap the magnifying glass icon in the top header from any screen. StuDesk searches your tasks, exams, classes, notes, and library links in real time with categorized results.',
    },
    {
      'title': '10. Configuring in-app notifications',
      'content': 'Tap the notification bell in the top-right header to open your in-app notification center. Upcoming exams and due tasks are automatically aggregated and can be marked as read or dismissed.',
    },
    {
      'title': '11. Changing themes (Light, Dark, AMOLED)',
      'content': 'Go to Profile → Appearance. Choose between Light mode (warm cream), Dark mode (refined charcoal), or AMOLED dark mode (pure #000000 black for maximum battery efficiency). You can also choose your favorite gold accent color.',
    },
    {
      'title': '12. Understanding cloud storage and account data',
      'content': 'Your profile, courses, and tasks synchronize securely with encrypted cloud storage. You can also export a complete JSON backup of your desk from Profile → Privacy & Data Controls.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 12),
                  decoration: BoxDecoration(
                    color: stuTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: stuTheme.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.help_outline_rounded,
                        color: stuTheme.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Help & How-To Guides',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: stuTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  itemCount: _guides.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final guide = _guides[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: stuTheme.surfaceTier1,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: stuTheme.border),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        title: Text(
                          guide['title']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: stuTheme.textPrimary,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 14,
                            ),
                            child: Text(
                              guide['content']!,
                              style: TextStyle(
                                fontSize: 13,
                                color: stuTheme.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
