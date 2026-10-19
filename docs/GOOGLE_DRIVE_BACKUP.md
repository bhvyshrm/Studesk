# StuDesk Google Drive Backup & Restore Architecture

This document specifies the format, retention rules, security policies, and setup instructions for StuDesk Google Drive and local JSON backups.

---

## 1. Structured Backup Format

StuDesk uses a documented, versioned JSON format (`schema_version: 1`).
Large binary attachments and images are excluded to keep snapshots fast, lightweight, and bandwidth-efficient.

### Schema Structure:
```json
{
  "metadata": {
    "app_version": "1.0.0",
    "schema_version": 1,
    "exported_at": "2026-10-19T17:00:00Z",
    "device_name": "StuDesk Companion",
    "courses_count": 4,
    "tasks_count": 6,
    "resources_count": 5,
    "journals_count": 14,
    "attendance_records_count": 32,
    "data_checksum": "a3b5c7...sha256"
  },
  "profile": { ... },
  "courses": [ ... ],
  "tasks": [ ... ],
  "resources": [ ... ],
  "journals": [ ... ],
  "subject_attendance": [ ... ],
  "college_attendance": [ ... ],
  "timetable": [ ... ],
  "exams": [ ... ]
}
```

---

## 2. Integrity Verification & Checksum

- Every backup includes a SHA-256 `data_checksum` computed over the canonical serialized JSON payload.
- Upon restore, `validateAndPreview()` validates JSON syntax, schema compatibility, and entity integrity before applying any changes.
- Corrupted or future-schema backups are rejected with clear user error messages.

---

## 3. Conflict Resolution Strategy

StuDesk supports two non-destructive conflict-resolution strategies:
1. **Replace / Overwrite**: Clears current local records and restores the exact state of the backup.
2. **Merge**: Preserves all current local entries, importing only missing courses, tasks, notes, and journals.

---

## 4. Retention & Reminder Policies

- **3-Day Backup Policy**: StuDesk checks `lastBackupTime`. If more than 3 days have elapsed without a backup, a reminder badge prompts the student to take a snapshot.
- **20-File Retention Limit**: To avoid cluttering storage, StuDesk maintains an index of at most 20 snapshots. Creating snapshot #21 automatically prunes the oldest snapshot.

---

## 5. Google Drive API Integration Setup

To connect remote Google Drive backups:

1. **Enable Google Drive API**:
   - In Google Cloud Console, enable **Google Drive API** for your project.

2. **Add OAuth Scope**:
   - Add the AppData scope: `https://www.googleapis.com/auth/drive.appdata`.
   - This scope restricts StuDesk to its own private hidden application data folder (`appDataFolder`) and prevents access to arbitrary personal user files.

3. **Google Sign-In Scope Request**:
   - During Google Sign-In, request the additional Drive AppData scope.
   - Files are named `studesk_backup_<timestamp>.json` and tagged with MIME type `application/json`.
