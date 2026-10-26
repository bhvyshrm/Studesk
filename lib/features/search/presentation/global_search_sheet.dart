import 'package:flutter/material.dart';

import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';

class GlobalSearchSheet extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const GlobalSearchSheet({super.key, this.onNavigateToTab});

  static Future<void> show(
    BuildContext context, {
    void Function(int tabIndex)? onNavigateToTab,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => GlobalSearchSheet(onNavigateToTab: onNavigateToTab),
    );
  }

  @override
  State<GlobalSearchSheet> createState() => _GlobalSearchSheetState();
}

class _GlobalSearchSheetState extends State<GlobalSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final StuDeskRepository _repo = StuDeskRepository.instance;
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _results = [];

  final List<String> _filters = [
    'All',
    'Task',
    'Exam',
    'Subject',
    'Note',
    'Library',
    'Class',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _results = []);
    } else {
      final all = _repo.searchAll(query);
      setState(() {
        if (_selectedFilter == 'All') {
          _results = all;
        } else {
          _results = all.where((r) => r['type'] == _selectedFilter).toList();
        }
      });
    }
  }

  void _onFilterSelected(String filter) {
    setState(() => _selectedFilter = filter);
    _onSearchChanged();
  }

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
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
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

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search tasks, exams, subjects, notes, links...',
                    hintStyle: TextStyle(
                      color: stuTheme.textMuted,
                      fontSize: 13.5,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: stuTheme.accent,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: stuTheme.textSecondary,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: stuTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: stuTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: stuTheme.accent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        selectedColor: stuTheme.accent,
                        backgroundColor: stuTheme.surfaceTier2,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? stuTheme.onAccent
                              : stuTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : stuTheme.border,
                          ),
                        ),
                        onSelected: (val) {
                          if (val) _onFilterSelected(filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 1),

              // Search Results
              Expanded(
                child: _searchController.text.trim().isEmpty
                    ? _buildInitialGuide(stuTheme)
                    : (_results.isEmpty
                          ? _buildNoResultsState(stuTheme)
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: _results.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final res = _results[index];
                                return _buildResultTile(res, stuTheme);
                              },
                            )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialGuide(StuDeskThemeExtension stuTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 36, color: stuTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              'Search your desk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: stuTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Find tasks, classes, upcoming exams, lecture notes, and learning resources across your entire account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: stuTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(StuDeskThemeExtension stuTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 36, color: stuTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              'No matches found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: stuTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching with a different keyword or removing filters.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: stuTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(
    Map<String, dynamic> res,
    StuDeskThemeExtension stuTheme,
  ) {
    final type = res['type'] as String;
    final title = res['title'] as String;
    final subtitle = res['subtitle'] as String;

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'Task':
        icon = Icons.check_circle_outline_rounded;
        iconColor = stuTheme.accent;
        break;
      case 'Exam':
        icon = Icons.event_available_rounded;
        iconColor = stuTheme.error;
        break;
      case 'Subject':
        icon = Icons.school_rounded;
        iconColor = stuTheme.accent;
        break;
      case 'Note':
        icon = Icons.description_outlined;
        iconColor = stuTheme.warning;
        break;
      case 'Library':
        icon = Icons.video_library_rounded;
        iconColor = stuTheme.textPrimary;
        break;
      case 'Class':
        icon = Icons.schedule_rounded;
        iconColor = stuTheme.success;
        break;
      default:
        icon = Icons.bookmark_border_rounded;
        iconColor = stuTheme.textSecondary;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: stuTheme.border),
      ),
      tileColor: stuTheme.surfaceTier1,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: stuTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: stuTheme.textSecondary, fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: stuTheme.surfaceTier2,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: stuTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (type == 'Task' || type == 'Exam' || type == 'Event') {
          widget.onNavigateToTab?.call(0); // Home
        } else if (type == 'Subject' || type == 'Note' || type == 'Class') {
          widget.onNavigateToTab?.call(1); // Academics
        } else if (type == 'Library') {
          widget.onNavigateToTab?.call(2); // Library
        }
      },
    );
  }
}
