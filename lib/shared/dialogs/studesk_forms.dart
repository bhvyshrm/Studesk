import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/data/studesk_repository.dart';
import '../../core/theme/app_theme.dart';
import '../models/models.dart';

abstract final class StuDeskForms {
  static const _uuid = Uuid();

  static String generateId() => _uuid.v4();

  // =========================================================================
  // 1. TASK CREATION & EDITING
  // =========================================================================
  static Future<bool?> showTaskForm(
    BuildContext context, {
    TaskItem? existingTask,
  }) {
    final isEditing = existingTask != null;
    final repo = StuDeskRepository.instance;
    final stuTheme = context.stuTheme;

    final titleCtrl = TextEditingController(text: existingTask?.title ?? '');
    final detailCtrl = TextEditingController(text: existingTask?.detail ?? '');
    DateTime selectedDate = existingTask?.dueDate ?? DateTime.now();
    TaskPriority priority = existingTask?.priority ?? TaskPriority.normal;
    String selectedTag =
        existingTask?.categoryTag ??
        (repo.courses.isNotEmpty ? repo.courses.first.code : 'General');
    bool isSaving = false;
    String? titleError;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Task' : 'New Academic Task',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: stuTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(sheetCtx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    autofocus: !isEditing,
                    enabled: !isSaving,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Task Title *',
                      hintText: 'e.g. Complete Dynamic Programming problem set',
                      errorText: titleError,
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      if (titleError != null) {
                        setModalState(() => titleError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: detailCtrl,
                    enabled: !isSaving,
                    maxLines: 2,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Details / Instructions (Optional)',
                      hintText:
                          'Notes, reference links, or submission details...',
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                          ),
                          label: Text(
                            DateFormat('EEE, MMM d').format(selectedDate),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedDate = picked);
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<TaskPriority>(
                          initialValue: priority,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            filled: true,
                            fillColor: stuTheme.surfaceTier2,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: TaskPriority.values
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p.name.toUpperCase(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setModalState(() => priority = val);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stuTheme.accent,
                        foregroundColor: stuTheme.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                setModalState(
                                  () => titleError = 'Task title is required',
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              try {
                                if (isEditing) {
                                  final updated = existingTask.copyWith(
                                    title: title,
                                    detail: detailCtrl.text.trim().isNotEmpty
                                        ? detailCtrl.text.trim()
                                        : null,
                                    dueDate: selectedDate,
                                    priority: priority,
                                    categoryTag: selectedTag,
                                  );
                                  await repo.updateTask(updated);
                                } else {
                                  final newTask = TaskItem(
                                    id: generateId(),
                                    title: title,
                                    detail: detailCtrl.text.trim().isNotEmpty
                                        ? detailCtrl.text.trim()
                                        : null,
                                    dueDate: selectedDate,
                                    dueTime: DateFormat('h:mm a')
                                        .format(DateTime.now()),
                                    priority: priority,
                                    categoryTag: selectedTag,
                                    isCompleted: false,
                                  );
                                  await repo.addTask(newTask);
                                }

                                if (context.mounted) {
                                  Navigator.pop(sheetCtx, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Task updated successfully'
                                            : 'Task created successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: stuTheme.error,
                                      content: Text('Failed to save task: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: stuTheme.onAccent,
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Task' : 'Save Task',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 2. EVENT CREATION & EDITING
  // =========================================================================
  static Future<bool?> showEventForm(
    BuildContext context, {
    EventItem? existingEvent,
  }) {
    final isEditing = existingEvent != null;
    final repo = StuDeskRepository.instance;
    final stuTheme = context.stuTheme;

    final titleCtrl = TextEditingController(text: existingEvent?.title ?? '');
    final locationCtrl = TextEditingController(
      text: existingEvent?.location ?? '',
    );
    final notesCtrl = TextEditingController(text: existingEvent?.notes ?? '');
    DateTime selectedDate = existingEvent?.eventDate ?? DateTime.now();
    bool isSaving = false;
    String? titleError;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing
                            ? 'Edit Event'
                            : 'New Academic / Campus Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: stuTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(sheetCtx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    autofocus: !isEditing,
                    enabled: !isSaving,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Event Title *',
                      hintText: 'e.g. AI Symposium or Hackathon Check-in',
                      errorText: titleError,
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      if (titleError != null) {
                        setModalState(() => titleError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationCtrl,
                    enabled: !isSaving,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Location (Optional)',
                      hintText: 'e.g. Auditorium Hall 4 or Zoom',
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    enabled: !isSaving,
                    maxLines: 2,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Notes / Agenda (Optional)',
                      hintText: 'Details, prep materials, or schedule...',
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stuTheme.accent,
                        foregroundColor: stuTheme.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                setModalState(
                                  () => titleError = 'Event title is required',
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              try {
                                if (isEditing) {
                                  final updated = existingEvent.copyWith(
                                    title: title,
                                    eventDate: selectedDate,
                                    location:
                                        locationCtrl.text.trim().isNotEmpty
                                        ? locationCtrl.text.trim()
                                        : null,
                                    notes: notesCtrl.text.trim().isNotEmpty
                                        ? notesCtrl.text.trim()
                                        : null,
                                  );
                                  await repo.updateEvent(updated);
                                } else {
                                  final newEvent = EventItem(
                                    id: generateId(),
                                    title: title,
                                    eventDate: selectedDate,
                                    location:
                                        locationCtrl.text.trim().isNotEmpty
                                        ? locationCtrl.text.trim()
                                        : null,
                                    notes: notesCtrl.text.trim().isNotEmpty
                                        ? notesCtrl.text.trim()
                                        : null,
                                  );
                                  await repo.addEvent(newEvent);
                                }

                                if (context.mounted) {
                                  Navigator.pop(sheetCtx, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Event updated successfully'
                                            : 'Event saved successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: stuTheme.error,
                                      content: Text('Failed to save event: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: stuTheme.onAccent,
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Event' : 'Save Event',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 3. EXAM CREATION & EDITING
  // =========================================================================
  static Future<bool?> showExamForm(
    BuildContext context, {
    ExamItem? existingExam,
  }) {
    final isEditing = existingExam != null;
    final repo = StuDeskRepository.instance;
    final stuTheme = context.stuTheme;

    final titleCtrl = TextEditingController(text: existingExam?.title ?? '');
    final courseCtrl = TextEditingController(
      text:
          existingExam?.courseCode ??
          (repo.courses.isNotEmpty ? repo.courses.first.code : ''),
    );
    final roomCtrl = TextEditingController(text: existingExam?.room ?? '');
    final cutoffCtrl = TextEditingController(
      text: existingExam?.syllabusCutoff ?? '',
    );
    DateTime selectedDate =
        existingExam?.examDate ?? DateTime.now().add(const Duration(days: 7));
    bool isSaving = false;
    String? titleError;
    String? courseError;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Exam' : 'Schedule Exam',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: stuTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(sheetCtx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    autofocus: !isEditing,
                    enabled: !isSaving,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Exam Title *',
                      hintText: 'e.g. Midterm Examination or Final Theory',
                      errorText: titleError,
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      if (titleError != null) {
                        setModalState(() => titleError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: courseCtrl,
                          enabled: !isSaving,
                          style: TextStyle(
                            color: stuTheme.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Course Code *',
                            hintText: 'e.g. CS201',
                            errorText: courseError,
                            filled: true,
                            fillColor: stuTheme.surfaceTier2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (_) {
                            if (courseError != null) {
                              setModalState(() => courseError = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: roomCtrl,
                          enabled: !isSaving,
                          style: TextStyle(
                            color: stuTheme.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Room / Hall',
                            hintText: 'e.g. Exam Hall 3',
                            filled: true,
                            fillColor: stuTheme.surfaceTier2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cutoffCtrl,
                    enabled: !isSaving,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Syllabus Cutoff / Units',
                      hintText: 'e.g. Units 1 to 4 or All Chapters',
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stuTheme.accent,
                        foregroundColor: stuTheme.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              final course = courseCtrl.text.trim();
                              bool hasError = false;

                              if (title.isEmpty) {
                                setModalState(
                                  () => titleError = 'Exam title is required',
                                );
                                hasError = true;
                              }
                              if (course.isEmpty) {
                                setModalState(
                                  () => courseError = 'Course code is required',
                                );
                                hasError = true;
                              }
                              if (hasError) return;

                              setModalState(() => isSaving = true);

                              try {
                                if (isEditing) {
                                  final updated = existingExam.copyWith(
                                    title: title,
                                    courseCode: course,
                                    examDate: selectedDate,
                                    room: roomCtrl.text.trim().isNotEmpty
                                        ? roomCtrl.text.trim()
                                        : 'TBA',
                                    syllabusCutoff:
                                        cutoffCtrl.text.trim().isNotEmpty
                                        ? cutoffCtrl.text.trim()
                                        : 'All units',
                                  );
                                  await repo.updateExam(updated);
                                } else {
                                  final newExam = ExamItem(
                                    id: generateId(),
                                    title: title,
                                    courseCode: course,
                                    examDate: selectedDate,
                                    room: roomCtrl.text.trim().isNotEmpty
                                        ? roomCtrl.text.trim()
                                        : 'TBA',
                                    syllabusCutoff:
                                        cutoffCtrl.text.trim().isNotEmpty
                                        ? cutoffCtrl.text.trim()
                                        : 'All units',
                                  );
                                  await repo.addExam(newExam);
                                }

                                if (context.mounted) {
                                  Navigator.pop(sheetCtx, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Exam updated successfully'
                                            : 'Exam scheduled successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: stuTheme.error,
                                      content: Text('Failed to save exam: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: stuTheme.onAccent,
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Exam' : 'Schedule Exam',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 4. REMINDER CREATION & EDITING
  // =========================================================================
  static Future<bool?> showReminderForm(
    BuildContext context, {
    ReminderItem? existingReminder,
  }) {
    final isEditing = existingReminder != null;
    final repo = StuDeskRepository.instance;
    final stuTheme = context.stuTheme;

    final textCtrl = TextEditingController(text: existingReminder?.text ?? '');
    DateTime selectedTime =
        existingReminder?.reminderTime ??
        DateTime.now().add(const Duration(hours: 2));
    bool isSaving = false;
    String? textError;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Reminder' : 'Set Quick Reminder',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: stuTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(sheetCtx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textCtrl,
                    autofocus: !isEditing,
                    enabled: !isSaving,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Reminder Notice *',
                      hintText: 'e.g. Upload lab report before 5 PM',
                      errorText: textError,
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      if (textError != null) {
                        setModalState(() => textError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                          ),
                          label: Text(
                            DateFormat('MMM d, yyyy').format(selectedTime),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedTime,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 1),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      selectedTime = DateTime(
                                        picked.year,
                                        picked.month,
                                        picked.day,
                                        selectedTime.hour,
                                        selectedTime.minute,
                                      );
                                    });
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time_rounded, size: 16),
                          label: Text(
                            DateFormat('h:mm a').format(selectedTime),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                      selectedTime,
                                    ),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      selectedTime = DateTime(
                                        selectedTime.year,
                                        selectedTime.month,
                                        selectedTime.day,
                                        picked.hour,
                                        picked.minute,
                                      );
                                    });
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stuTheme.accent,
                        foregroundColor: stuTheme.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final text = textCtrl.text.trim();
                              if (text.isEmpty) {
                                setModalState(
                                  () => textError = 'Reminder text is required',
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              try {
                                if (isEditing) {
                                  final updated = existingReminder.copyWith(
                                    text: text,
                                    reminderTime: selectedTime,
                                  );
                                  await repo.updateReminder(updated);
                                } else {
                                  final newReminder = ReminderItem(
                                    id: generateId(),
                                    text: text,
                                    reminderTime: selectedTime,
                                    isCompleted: false,
                                  );
                                  await repo.addReminder(newReminder);
                                }

                                if (context.mounted) {
                                  Navigator.pop(sheetCtx, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Reminder updated'
                                            : 'Reminder saved successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: stuTheme.error,
                                      content: Text(
                                        'Failed to save reminder: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: stuTheme.onAccent,
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Reminder' : 'Set Reminder',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 5. SUBJECT & SYLLABUS CREATION & EDITING
  // =========================================================================
  static Future<bool?> showSubjectForm(
    BuildContext context, {
    Course? existingCourse,
  }) {
    final isEditing = existingCourse != null;
    final repo = StuDeskRepository.instance;
    final stuTheme = context.stuTheme;

    final codeCtrl = TextEditingController(text: existingCourse?.code ?? '');
    final titleCtrl = TextEditingController(text: existingCourse?.title ?? '');
    final profCtrl = TextEditingController(
      text: existingCourse?.professor ?? '',
    );
    final roomCtrl = TextEditingController(
      text: existingCourse?.location ?? '',
    );
    int credits = existingCourse?.credits ?? 3;
    bool isSaving = false;
    String? codeError;
    String? titleError;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing
                            ? 'Edit Subject Details'
                            : 'Add Subject & Syllabus',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: stuTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(sheetCtx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    autofocus: !isEditing,
                    enabled:
                        !isSaving && !isEditing, // Code is unique identifier
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Subject Code * (e.g. CS201)',
                      errorText: codeError,
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      if (codeError != null) {
                        setModalState(() => codeError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    enabled: !isSaving,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Subject Title * (e.g. Data Structures)',
                      errorText: titleError,
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      if (titleError != null) {
                        setModalState(() => titleError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: profCtrl,
                          enabled: !isSaving,
                          style: TextStyle(
                            color: stuTheme.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Professor',
                            hintText: 'e.g. Dr. Vance',
                            filled: true,
                            fillColor: stuTheme.surfaceTier2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: roomCtrl,
                          enabled: !isSaving,
                          style: TextStyle(
                            color: stuTheme.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Room / Hall',
                            hintText: 'e.g. Hall 102',
                            filled: true,
                            fillColor: stuTheme.surfaceTier2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Credits: ',
                        style: TextStyle(
                          color: stuTheme.textSecondary,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ...[1, 2, 3, 4, 5].map((c) {
                        final isSelected = credits == c;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$c'),
                            selected: isSelected,
                            selectedColor: stuTheme.accent,
                            onSelected: isSaving
                                ? null
                                : (_) => setModalState(() => credits = c),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stuTheme.accent,
                        foregroundColor: stuTheme.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final code = codeCtrl.text.trim().toUpperCase();
                              final title = titleCtrl.text.trim();
                              bool hasError = false;

                              if (code.isEmpty) {
                                setModalState(
                                  () => codeError = 'Subject code is required',
                                );
                                hasError = true;
                              }
                              if (title.isEmpty) {
                                setModalState(
                                  () =>
                                      titleError = 'Subject title is required',
                                );
                                hasError = true;
                              }
                              if (hasError) return;

                              setModalState(() => isSaving = true);

                              try {
                                if (isEditing) {
                                  final updated = existingCourse.copyWith(
                                    title: title,
                                    professor: profCtrl.text.trim().isNotEmpty
                                        ? profCtrl.text.trim()
                                        : 'Instructor',
                                    location: roomCtrl.text.trim().isNotEmpty
                                        ? roomCtrl.text.trim()
                                        : 'Classroom',
                                    credits: credits,
                                  );
                                  await repo.updateCourse(updated);
                                } else {
                                  final newCourse = Course(
                                    code: code,
                                    title: title,
                                    professor: profCtrl.text.trim().isNotEmpty
                                        ? profCtrl.text.trim()
                                        : 'Instructor',
                                    department: 'Academic',
                                    schedule: 'Weekly Schedule',
                                    location: roomCtrl.text.trim().isNotEmpty
                                        ? roomCtrl.text.trim()
                                        : 'Classroom',
                                    credits: credits,
                                    attendedLectures: 0,
                                    totalLectures: 0,
                                  );
                                  await repo.addCourse(newCourse);
                                }

                                if (context.mounted) {
                                  Navigator.pop(sheetCtx, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Subject updated successfully'
                                            : 'Subject created successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: stuTheme.error,
                                      content: Text(
                                        'Failed to save subject: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: stuTheme.onAccent,
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Subject' : 'Create Subject',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 6. ACADEMIC NOTE CREATION & EDITING
  // =========================================================================
  static Future<bool?> showNoteForm(
    BuildContext context, {
    AcademicNote? existingNote,
  }) {
    final isEditing = existingNote != null;
    final repo = StuDeskRepository.instance;
    final stuTheme = context.stuTheme;

    final titleCtrl = TextEditingController(text: existingNote?.title ?? '');
    final contentCtrl = TextEditingController(
      text: existingNote?.content ?? '',
    );
    String selectedCode =
        existingNote?.subjectCode ??
        (repo.courses.isNotEmpty ? repo.courses.first.code : 'General');
    AcademicFileType selectedType =
        existingNote?.fileType ?? AcademicFileType.note;
    bool isSaving = false;
    String? titleError;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing
                            ? 'Edit Academic Note'
                            : 'Create Academic Note',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: stuTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(sheetCtx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    autofocus: !isEditing,
                    enabled: !isSaving,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Note Title *',
                      hintText:
                          'e.g. Lecture 4: Binary Trees & Balanced Search',
                      errorText: titleError,
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      if (titleError != null) {
                        setModalState(() => titleError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              repo.courses.any((c) => c.code == selectedCode)
                              ? selectedCode
                              : 'General',
                          decoration: InputDecoration(
                            labelText: 'Subject',
                            filled: true,
                            fillColor: stuTheme.surfaceTier2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'General',
                              child: Text('General'),
                            ),
                            ...repo.courses.map(
                              (c) => DropdownMenuItem(
                                value: c.code,
                                child: Text(c.code),
                              ),
                            ),
                          ],
                          onChanged: isSaving
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setModalState(() => selectedCode = val);
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<AcademicFileType>(
                          initialValue: selectedType,
                          decoration: InputDecoration(
                            labelText: 'Type',
                            filled: true,
                            fillColor: stuTheme.surfaceTier2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: AcademicFileType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.name.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setModalState(() => selectedType = val);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    enabled: !isSaving,
                    maxLines: 5,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Content & Formulas',
                      hintText: 'Write academic formulas, key definitions, or coursework notes...',
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stuTheme.accent,
                        foregroundColor: stuTheme.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                setModalState(
                                  () => titleError = 'Note title is required',
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              try {
                                if (isEditing) {
                                  final updated = existingNote.copyWith(
                                    title: title,
                                    subjectCode: selectedCode,
                                    fileType: selectedType,
                                    content: contentCtrl.text.trim(),
                                  );
                                  await repo.updateAcademicNote(updated);
                                } else {
                                  final newNote = AcademicNote(
                                    id: generateId(),
                                    title: title,
                                    subjectCode: selectedCode,
                                    fileType: selectedType,
                                    content: contentCtrl.text.trim(),
                                  );
                                  await repo.addAcademicNote(newNote);
                                }

                                if (context.mounted) {
                                  Navigator.pop(sheetCtx, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Note updated successfully'
                                            : 'Note saved successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: stuTheme.error,
                                      content: Text('Failed to save note: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: stuTheme.onAccent,
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Note' : 'Save Academic Note',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 7. TIMETABLE CLASS CREATION & EDITING
  // =========================================================================
  static Future<bool?> showTimetableForm(
    BuildContext context, {
    TimetableEntry? existingEntry,
    int? defaultDay,
  }) {
    final isEditing = existingEntry != null;
    final repo = StuDeskRepository.instance;
    final stuTheme = context.stuTheme;

    final titleCtrl = TextEditingController(text: existingEntry?.title ?? '');
    final codeCtrl = TextEditingController(
      text:
          existingEntry?.courseCode ??
          (repo.courses.isNotEmpty ? repo.courses.first.code : ''),
    );
    final roomCtrl = TextEditingController(text: existingEntry?.room ?? '');
    final profCtrl = TextEditingController(
      text: existingEntry?.professor ?? '',
    );
    int selectedDay =
        existingEntry?.dayOfWeek ?? defaultDay ?? DateTime.now().weekday;
    String startTime = existingEntry?.startTime ?? '09:00 AM';
    String endTime = existingEntry?.endTime ?? '10:30 AM';
    bool isSaving = false;
    String? titleError;
    String? codeError;

    final days = [
      {'day': 1, 'name': 'Monday'},
      {'day': 2, 'name': 'Tuesday'},
      {'day': 3, 'name': 'Wednesday'},
      {'day': 4, 'name': 'Thursday'},
      {'day': 5, 'name': 'Friday'},
      {'day': 6, 'name': 'Saturday'},
      {'day': 7, 'name': 'Sunday'},
    ];

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing
                            ? 'Edit Timetable Class'
                            : 'Add Timetable Class',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: stuTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(sheetCtx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    autofocus: !isEditing,
                    enabled: !isSaving,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Class / Subject Title *',
                      hintText: 'e.g. Operating Systems Lab',
                      errorText: titleError,
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      if (titleError != null) {
                        setModalState(() => titleError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codeCtrl,
                          enabled: !isSaving,
                          style: TextStyle(
                            color: stuTheme.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Course Code *',
                            hintText: 'e.g. CS201',
                            errorText: codeError,
                            filled: true,
                            fillColor: stuTheme.surfaceTier2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (_) {
                            if (codeError != null) {
                              setModalState(() => codeError = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedDay,
                          decoration: InputDecoration(
                            labelText: 'Day',
                            filled: true,
                            fillColor: stuTheme.surfaceTier2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: days
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d['day'] as int,
                                  child: Text(
                                    d['name'] as String,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setModalState(() => selectedDay = val);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: roomCtrl,
                          enabled: !isSaving,
                          style: TextStyle(
                            color: stuTheme.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Room / Hall',
                            hintText: 'e.g. Lab 4',
                            filled: true,
                            fillColor: stuTheme.surfaceTier2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: profCtrl,
                          enabled: !isSaving,
                          style: TextStyle(
                            color: stuTheme.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Professor',
                            hintText: 'e.g. Dr. Turing',
                            filled: true,
                            fillColor: stuTheme.surfaceTier2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time_rounded, size: 16),
                          label: Text('Start: $startTime'),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: const TimeOfDay(
                                      hour: 9,
                                      minute: 0,
                                    ),
                                  );
                                  if (picked != null) {
                                    setModalState(
                                      () => startTime = picked.format(context),
                                    );
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.access_time_filled_rounded,
                            size: 16,
                          ),
                          label: Text('End: $endTime'),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: const TimeOfDay(
                                      hour: 10,
                                      minute: 30,
                                    ),
                                  );
                                  if (picked != null) {
                                    setModalState(
                                      () => endTime = picked.format(context),
                                    );
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stuTheme.accent,
                        foregroundColor: stuTheme.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              final code = codeCtrl.text.trim();
                              bool hasError = false;

                              if (title.isEmpty) {
                                setModalState(
                                  () => titleError = 'Class title is required',
                                );
                                hasError = true;
                              }
                              if (code.isEmpty) {
                                setModalState(
                                  () => codeError = 'Course code is required',
                                );
                                hasError = true;
                              }
                              if (hasError) return;

                              setModalState(() => isSaving = true);

                              try {
                                if (isEditing) {
                                  final updated = existingEntry.copyWith(
                                    title: title,
                                    courseCode: code,
                                    dayOfWeek: selectedDay,
                                    startTime: startTime,
                                    endTime: endTime,
                                    room: roomCtrl.text.trim().isNotEmpty
                                        ? roomCtrl.text.trim()
                                        : 'Room TBA',
                                    professor: profCtrl.text.trim().isNotEmpty
                                        ? profCtrl.text.trim()
                                        : 'Professor',
                                  );
                                  await repo.updateTimetableEntry(updated);
                                } else {
                                  final newEntry = TimetableEntry(
                                    id: generateId(),
                                    dayOfWeek: selectedDay,
                                    startTime: startTime,
                                    endTime: endTime,
                                    courseCode: code,
                                    title: title,
                                    room: roomCtrl.text.trim().isNotEmpty
                                        ? roomCtrl.text.trim()
                                        : 'Room TBA',
                                    professor: profCtrl.text.trim().isNotEmpty
                                        ? profCtrl.text.trim()
                                        : 'Professor',
                                  );
                                  await repo.addTimetableEntry(newEntry);
                                }

                                if (context.mounted) {
                                  Navigator.pop(sheetCtx, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Class updated successfully'
                                            : 'Class added to timetable',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: stuTheme.error,
                                      content: Text('Failed to save class: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: stuTheme.onAccent,
                              ),
                            )
                          : Text(
                              isEditing
                                  ? 'Update Class'
                                  : 'Save Timetable Class',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 8. LIBRARY COLLECTION CREATION & EDITING
  // =========================================================================
  static Future<bool?> showCollectionForm(
    BuildContext context, {
    LibraryCollection? existingCollection,
  }) {
    final isEditing = existingCollection != null;
    final repo = StuDeskRepository.instance;
    final stuTheme = context.stuTheme;

    final nameCtrl = TextEditingController(
      text: existingCollection?.name ?? '',
    );
    final descCtrl = TextEditingController(
      text: existingCollection?.description ?? '',
    );
    bool isSaving = false;
    String? nameError;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing
                            ? 'Edit Learning Collection'
                            : 'New Learning Collection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: stuTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(sheetCtx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    autofocus: !isEditing,
                    enabled: !isSaving,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Collection Name *',
                      hintText:
                          'e.g. DSA Preparation or System Design Roadmaps',
                      errorText: nameError,
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      if (nameError != null) {
                        setModalState(() => nameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    enabled: !isSaving,
                    maxLines: 2,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'e.g. YouTube tutorials, articles, and interview notes...',
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stuTheme.accent,
                        foregroundColor: stuTheme.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                setModalState(
                                  () =>
                                      nameError = 'Collection name is required',
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              try {
                                if (isEditing) {
                                  final updated = existingCollection.copyWith(
                                    name: name,
                                    description: descCtrl.text.trim(),
                                  );
                                  await repo.updateCollection(updated);
                                } else {
                                  final newCollection = LibraryCollection(
                                    id: generateId(),
                                    name: name,
                                    description: descCtrl.text.trim(),
                                  );
                                  await repo.addCollection(newCollection);
                                }

                                if (context.mounted) {
                                  Navigator.pop(sheetCtx, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Collection updated successfully'
                                            : 'Collection created successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: stuTheme.error,
                                      content: Text(
                                        'Failed to save collection: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: stuTheme.onAccent,
                              ),
                            )
                          : Text(
                              isEditing
                                  ? 'Update Collection'
                                  : 'Create Collection',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 9. LIBRARY RESOURCE CREATION & EDITING
  // =========================================================================
  static Future<bool?> showResourceForm(
    BuildContext context, {
    LibraryResource? existingResource,
    String? defaultCollectionId,
  }) {
    final isEditing = existingResource != null;
    final repo = StuDeskRepository.instance;
    final stuTheme = context.stuTheme;

    final titleCtrl = TextEditingController(
      text: existingResource?.title ?? '',
    );
    final urlCtrl = TextEditingController(text: existingResource?.url ?? '');
    final notesCtrl = TextEditingController(
      text: existingResource?.noteContent ?? '',
    );
    final subjectCtrl = TextEditingController(
      text: existingResource?.subjectTag ?? 'General',
    );
    ResourceType selectedType = existingResource?.type ?? ResourceType.video;
    String? assignedCollectionId =
        existingResource?.collectionId ?? defaultCollectionId;
    bool isSaving = false;
    String? titleError;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing
                            ? 'Edit Study Resource'
                            : 'Save Study Resource',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: stuTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: stuTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(sheetCtx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    autofocus: !isEditing,
                    enabled: !isSaving,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Resource Title *',
                      hintText: 'e.g. Graph Algorithms & Dijkstra in Python',
                      errorText: titleError,
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) {
                      if (titleError != null) {
                        setModalState(() => titleError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlCtrl,
                    enabled: !isSaving,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Web / YouTube URL',
                      hintText:
                          'https://youtube.com/watch?... or documentation link',
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ResourceType>(
                          initialValue: selectedType,
                          decoration: InputDecoration(
                            labelText: 'Type',
                            filled: true,
                            fillColor: stuTheme.surfaceTier2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: ResourceType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.name.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setModalState(() => selectedType = val);
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: subjectCtrl,
                          enabled: !isSaving,
                          style: TextStyle(
                            color: stuTheme.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Subject Tag',
                            hintText: 'e.g. CS201 or Algorithms',
                            filled: true,
                            fillColor: stuTheme.surfaceTier2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (repo.collections.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: assignedCollectionId,
                      decoration: InputDecoration(
                        labelText: 'Collection (Optional)',
                        filled: true,
                        fillColor: stuTheme.surfaceTier2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No Collection (Root)'),
                        ),
                        ...repo.collections.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (val) {
                              setModalState(() => assignedCollectionId = val);
                            },
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    enabled: !isSaving,
                    maxLines: 2,
                    style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Personal Notes / Key Takeaways',
                      hintText: 'Timestamps, formulas, or summaries...',
                      filled: true,
                      fillColor: stuTheme.surfaceTier2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stuTheme.accent,
                        foregroundColor: stuTheme.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                setModalState(
                                  () =>
                                      titleError = 'Resource title is required',
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              try {
                                if (isEditing) {
                                  final updated = existingResource.copyWith(
                                    title: title,
                                    url: urlCtrl.text.trim().isNotEmpty
                                        ? urlCtrl.text.trim()
                                        : null,
                                    type: selectedType,
                                    subjectTag:
                                        subjectCtrl.text.trim().isNotEmpty
                                        ? subjectCtrl.text.trim()
                                        : 'General',
                                    collectionId: assignedCollectionId,
                                    noteContent:
                                        notesCtrl.text.trim().isNotEmpty
                                        ? notesCtrl.text.trim()
                                        : null,
                                  );
                                  await repo.updateResource(updated);
                                } else {
                                  final newResource = LibraryResource(
                                    id: generateId(),
                                    title: title,
                                    url: urlCtrl.text.trim().isNotEmpty
                                        ? urlCtrl.text.trim()
                                        : null,
                                    type: selectedType,
                                    subjectTag:
                                        subjectCtrl.text.trim().isNotEmpty
                                        ? subjectCtrl.text.trim()
                                        : 'General',
                                    collectionId: assignedCollectionId,
                                    noteContent:
                                        notesCtrl.text.trim().isNotEmpty
                                        ? notesCtrl.text.trim()
                                        : null,
                                  );
                                  await repo.addResource(newResource);
                                }

                                if (context.mounted) {
                                  Navigator.pop(sheetCtx, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'Resource updated successfully'
                                            : 'Resource saved to Library',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: stuTheme.error,
                                      content: Text(
                                        'Failed to save resource: $e',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: stuTheme.onAccent,
                              ),
                            )
                          : Text(
                              isEditing ? 'Update Resource' : 'Save Resource',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 10. SAFE DESTRUCTIVE CONFIRMATION DIALOG
  // =========================================================================
  static Future<bool> confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    Future<void> Function()? onConfirm,
  }) async {
    final stuTheme = context.stuTheme;
    bool isDeleting = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: stuTheme.surfaceTier1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: stuTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: stuTheme.textSecondary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: isDeleting
                  ? null
                  : () => Navigator.pop(dialogCtx, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: stuTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: stuTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isDeleting
                  ? null
                  : () async {
                      if (onConfirm != null) {
                        setDialogState(() => isDeleting = true);
                        try {
                          await onConfirm();
                          if (context.mounted) Navigator.pop(dialogCtx, true);
                        } catch (e) {
                          setDialogState(() => isDeleting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: stuTheme.error,
                                content: Text('Delete failed: $e'),
                              ),
                            );
                          }
                        }
                      } else {
                        Navigator.pop(dialogCtx, true);
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }
}
