import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/pill_badge.dart';

class JournalEditorScreen extends StatefulWidget {
  const JournalEditorScreen({super.key});

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  final StuDeskRepository _repo = StuDeskRepository.instance;
  int _selectedMoodIndex = 0; // 0: Deep Focus
  final List<Map<String, String>> _moods = [
    {'emoji': '🎯', 'label': 'Deep Focus'},
    {'emoji': '⚡', 'label': 'High Energy'},
    {'emoji': '😌', 'label': 'Calm & Steady'},
    {'emoji': '🧠', 'label': 'Reflective'},
  ];

  late TextEditingController _reflectionController;
  late List<Map<String, dynamic>> _accomplishments;

  @override
  void initState() {
    super.initState();
    // Check if there's an existing journal entry for today
    final now = DateTime.now();
    final todayEntry = _repo.journals.cast<JournalEntry?>().firstWhere(
      (j) => j != null && j.date.year == now.year && j.date.month == now.month && j.date.day == now.day,
      orElse: () => null,
    );

    _reflectionController = TextEditingController(
      text: todayEntry?.learnedText ??
          'Solid grasp on binary search tree rebalancing and Red-Black tree rotations in CS201. Spent 45 minutes walking through edge cases on node color flipping. Need to review double-black deletion cases tomorrow before office hours.',
    );

    if (todayEntry != null) {
      final moodIndex = _moods.indexWhere((m) => m['label'] == todayEntry.mood);
      if (moodIndex != -1) _selectedMoodIndex = moodIndex;
    }

    _accomplishments = [
      {
        'text': 'Finished OS Lab 4 kernel sync schema draft and submitted PR to group repo.',
        'done': true,
      },
      {
        'text': '30-min Python LeetCode daily practice completed (Two Pointers & Sliding Window).',
        'done': true,
      },
    ];
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    final text = _reflectionController.text.trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    final now = DateTime.now();

    final entry = JournalEntry(
      id: 'jrn_${now.microsecondsSinceEpoch}',
      date: now,
      mood: _moods[_selectedMoodIndex]['label']!,
      streak: '${_repo.calculateStreak() + 1} Days',
      tasksCompleted: _accomplishments.where((a) => a['done'] == true).length,
      totalTasks: _accomplishments.length,
      linkedCourses: _repo.courses.take(2).map((c) => c.code).toList(),
      learnedText: text,
      accomplishments: _accomplishments
          .where((a) => a['done'] == true)
          .map((a) => a['text'] as String)
          .toList(),
      tags: const ['Daily', 'Reflection', 'Academics'],
      wordCount: words,
    );

    await _repo.saveJournalEntry(entry);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.stuTheme.surfaceTier3,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Daily journal entry saved! Active streak: ${_repo.calculateStreak()} Days 🔥',
            style: TextStyle(color: context.stuTheme.textPrimary),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Scaffold(
      backgroundColor: stuTheme.canvas,
      appBar: AppBar(
        backgroundColor: stuTheme.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 48,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: stuTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: stuTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: stuTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: stuTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Auto-saved',
                  style: TextStyle(
                    fontSize: 10,
                    color: stuTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: stuTheme.accent,
                foregroundColor: stuTheme.onAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
                elevation: 0,
              ),
              onPressed: _saveAndClose,
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Learning Flow State Header Card
            _buildFlowStateCard(context),

            const SizedBox(height: 14),

            // 2. Linked Progress Strip
            _buildLinkedProgressStrip(context),

            const SizedBox(height: 14),

            // 3. What I Learned Today Card
            _buildLearnedCard(context),

            const SizedBox(height: 14),

            // 4. Accomplishments & Blockers Card
            _buildAccomplishmentsCard(context),

            const SizedBox(height: 16),

            // 5. Quick Tag Pills Bar
            _buildQuickTagBar(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowStateCard(BuildContext context) {
    final stuTheme = context.stuTheme;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: stuTheme.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.lightbulb_rounded,
                        color: stuTheme.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Learning Flow State',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PillBadge(
                label: '+1 Streak',
                icon: Icon(
                  Icons.local_fire_department_rounded,
                  size: 13,
                  color: stuTheme.success,
                ),
                backgroundColor: stuTheme.successContainer,
                textColor: stuTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'How was your cognitive clarity and study momentum today?',
            style: TextStyle(
              fontSize: 13,
              color: stuTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),

          // Mood Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_moods.length, (index) {
                final mood = _moods[index];
                final isSelected = _selectedMoodIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMoodIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? stuTheme.accent.withValues(alpha: 0.18)
                            : stuTheme.surfaceTier2,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: isSelected ? stuTheme.accent : stuTheme.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(mood['emoji']!, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            mood['label']!,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? stuTheme.textPrimary : stuTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 14),
          Divider(color: stuTheme.border, height: 1),
          const SizedBox(height: 10),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '342 words',
                    style: TextStyle(fontSize: 11, color: stuTheme.textSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '•',
                    style: TextStyle(fontSize: 11, color: stuTheme.textMuted),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.schedule_rounded, size: 12, color: stuTheme.textSecondary),
                  const SizedBox(width: 3),
                  Text(
                    '1 min read',
                    style: TextStyle(fontSize: 11, color: stuTheme.textSecondary),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 12, color: stuTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Private entry',
                    style: TextStyle(fontSize: 11, color: stuTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedProgressStrip(BuildContext context) {
    final stuTheme = context.stuTheme;

    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: stuTheme.surfaceTier2,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.checklist_rounded,
              color: stuTheme.textPrimary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: "Today's Tasks: ",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: stuTheme.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: '3 of 5 completed',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Linked to Semester 5 Track',
                  style: TextStyle(
                    fontSize: 11,
                    color: stuTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stuTheme.surfaceTier2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: stuTheme.border),
                ),
                child: Text(
                  '#CS201',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: stuTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stuTheme.surfaceTier2,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: stuTheme.border),
                ),
                child: Text(
                  '#CS204',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: stuTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLearnedCard(BuildContext context) {
    final stuTheme = context.stuTheme;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      leadingIndicator: Container(
        width: 4,
        decoration: BoxDecoration(
          color: stuTheme.accent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'What I Learned Today',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: stuTheme.textSecondary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _reflectionController,
            maxLines: null,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: stuTheme.textPrimary,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 12),

          // Code Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: stuTheme.surfaceTier2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: stuTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.code_rounded,
                  size: 14,
                  color: stuTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'O(log n) worst-case lookup',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: stuTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccomplishmentsCard(BuildContext context) {
    final stuTheme = context.stuTheme;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Accomplishments & Blockers',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PillBadge(
                label: '2 done • 1 blocker',
                backgroundColor: stuTheme.surfaceTier2,
                textColor: stuTheme.textSecondary,
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Accomplishment Checklist
          ..._accomplishments.map((item) {
            final isDone = item['done'] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() => item['done'] = !isDone);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: isDone ? stuTheme.success : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isDone ? stuTheme.success : stuTheme.border,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['text'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: stuTheme.textPrimary,
                          height: 1.3,
                          decoration: isDone ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 6),

          // Blocker Callout Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: stuTheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: stuTheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: stuTheme.error,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blocker',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.error,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Hit a snag with Banker's algorithm deadlock state simulation in OS lab; need to review Deadlock detection algorithms.",
                        style: TextStyle(
                          fontSize: 12,
                          color: stuTheme.error,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTagBar(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildTagButton('#Course Tag', Icons.tag_rounded, stuTheme),
                const SizedBox(width: 8),
                _buildTagButton('Voice Memo', Icons.mic_rounded, stuTheme),
                const SizedBox(width: 8),
                _buildTagButton('Diagram', Icons.image_outlined, stuTheme),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: stuTheme.surfaceTier2,
            shape: BoxShape.circle,
            border: Border.all(color: stuTheme.border),
          ),
          child: Icon(
            Icons.keyboard_hide_rounded,
            size: 16,
            color: stuTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTagButton(String label, IconData icon, StuDeskThemeExtension stuTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: stuTheme.surfaceTier2,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: stuTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: stuTheme.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: stuTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
