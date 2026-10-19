enum TaskPriority { high, academic, review, normal }

class TaskItem {
  final String id;
  final String title;
  final TaskPriority priority;
  final String? dueTime;
  final String categoryTag;
  final String? detail;
  bool isCompleted;

  TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    this.dueTime,
    required this.categoryTag,
    this.detail,
    this.isCompleted = false,
  });
}

class LectureItem {
  final String id;
  final String courseCode;
  final String title;
  final String timeRange;
  final String location;
  final String professor;
  final bool isLive;
  final String? topic;
  final bool isAttended;

  const LectureItem({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.timeRange,
    required this.location,
    required this.professor,
    this.isLive = false,
    this.topic,
    this.isAttended = false,
  });
}

class Course {
  final String code;
  final String title;
  final String professor;
  final String department;
  final String schedule;
  final String location;
  final int credits;
  final double attendancePercent;
  final int attendedLectures;
  final int totalLectures;
  final double syllabusPercent;
  final int completedTopics;
  final int totalTopics;
  final String grade;
  final String standing;
  final String lastTopic;
  final bool isWarning;

  const Course({
    required this.code,
    required this.title,
    required this.professor,
    required this.department,
    required this.schedule,
    required this.location,
    required this.credits,
    required this.attendancePercent,
    required this.attendedLectures,
    required this.totalLectures,
    required this.syllabusPercent,
    required this.completedTopics,
    required this.totalTopics,
    required this.grade,
    required this.standing,
    required this.lastTopic,
    this.isWarning = false,
  });
}

enum ResourceType { video, pdf, note, bookmark }

class LibraryResource {
  final String id;
  final String title;
  final ResourceType type;
  final String subjectTag;
  final String? duration;
  final String? metaInfo;
  final String? channel;
  final bool isBookmarked;

  const LibraryResource({
    required this.id,
    required this.title,
    required this.type,
    required this.subjectTag,
    this.duration,
    this.metaInfo,
    this.channel,
    this.isBookmarked = false,
  });
}

class UnitTopic {
  final String title;
  final String date;
  final String subtitle;
  final bool isCompleted;

  const UnitTopic({
    required this.title,
    required this.date,
    required this.subtitle,
    this.isCompleted = false,
  });
}

enum UnitStatus { completed, current, upcoming }

class CourseUnit {
  final int unitNumber;
  final String title;
  final UnitStatus status;
  final int completedTopics;
  final int totalTopics;
  final List<UnitTopic> topics;

  const CourseUnit({
    required this.unitNumber,
    required this.title,
    required this.status,
    required this.completedTopics,
    required this.totalTopics,
    required this.topics,
  });
}

class JournalEntry {
  final String id;
  final DateTime date;
  final String mood;
  final String streak;
  final int tasksCompleted;
  final int totalTasks;
  final List<String> linkedCourses;
  final String learnedText;
  final String? codeSnippet;
  final List<String> accomplishments;
  final String? blocker;
  final List<String> tags;
  final int wordCount;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.mood,
    required this.streak,
    required this.tasksCompleted,
    required this.totalTasks,
    required this.linkedCourses,
    required this.learnedText,
    this.codeSnippet,
    required this.accomplishments,
    this.blocker,
    required this.tags,
    required this.wordCount,
  });
}
