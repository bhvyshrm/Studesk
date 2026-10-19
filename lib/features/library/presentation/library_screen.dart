import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/data/sample_data.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/widgets/pill_badge.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPlanner;

  const LibraryScreen({
    super.key,
    this.onNavigateToPlanner,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late List<LibraryResource> _resources;

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'count': 24, 'type': null},
    {'label': 'Notes', 'count': 12, 'type': ResourceType.note},
    {'label': 'Saved Videos', 'count': 6, 'type': ResourceType.video},
    {'label': 'Documents & PDFs', 'count': 4, 'type': ResourceType.pdf},
    {'label': 'Bookmarks', 'count': 2, 'type': 'bookmark'},
  ];

  @override
  void initState() {
    super.initState();
    _resources = List.from(SampleData.libraryResources);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddResourceSheet() {
    final stuTheme = context.stuTheme;
    final urlController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
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
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: stuTheme.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_link_rounded, color: stuTheme.accent),
                ),
                const SizedBox(width: 12),
                Text(
                  'Add Learning Resource',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: stuTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              autofocus: true,
              style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Paste YouTube URL or note topic...',
                hintStyle: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
                filled: true,
                fillColor: stuTheme.surfaceTier2,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: stuTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: stuTheme.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: stuTheme.accent,
                  foregroundColor: stuTheme.onAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  final text = urlController.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      _resources.insert(
                        0,
                        LibraryResource(
                          id: 'res-${DateTime.now().millisecondsSinceEpoch}',
                          title: text.startsWith('http')
                              ? 'Saved Video Reference'
                              : text,
                          type: text.startsWith('http')
                              ? ResourceType.video
                              : ResourceType.note,
                          subjectTag: 'CS201 DSA',
                          duration: 'New',
                          channel: 'Added Today',
                          isBookmarked: true,
                        ),
                      );
                    });
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: stuTheme.surfaceTier3,
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'Resource added to your library',
                        style: TextStyle(color: stuTheme.textPrimary),
                      ),
                    ),
                  );
                },
                child: const Text('Add to Library', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    // Filter resources
    final filter = _filters[_selectedFilterIndex];
    final filteredResources = _resources.where((r) {
      if (filter['type'] == null) return true;
      if (filter['type'] == 'bookmark') return r.isBookmarked;
      return r.type == filter['type'];
    }).toList();

    return Scaffold(
      backgroundColor: stuTheme.canvas,
      appBar: AppTopBar(
        title: 'Library',
        titleTrailing: PillBadge(
          label: '42 items',
          icon: Icon(Icons.bolt_rounded, size: 13, color: stuTheme.accent),
          backgroundColor: stuTheme.surfaceTier2,
          textColor: stuTheme.textPrimary,
        ),
        subtitle: 'Notes, Videos & Textbooks',
        onCalendarTap: widget.onNavigateToPlanner,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: stuTheme.surfaceTier2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: stuTheme.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: stuTheme.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: stuTheme.textPrimary, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Search notes, PDFs, YouTube videos...',
                        hintStyle: TextStyle(color: stuTheme.textSecondary, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: stuTheme.surfaceTier3,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: stuTheme.border),
                    ),
                    child: Text(
                      '⌘K',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: stuTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Horizontal Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final item = _filters[index];
                  final isSelected = _selectedFilterIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilterIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? stuTheme.accent : stuTheme.surfaceTier2,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            color: isSelected ? stuTheme.accent : stuTheme.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? stuTheme.onAccent : stuTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black.withValues(alpha: 0.15)
                                    : stuTheme.surfaceTier1,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                '${item['count']}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? stuTheme.onAccent : stuTheme.textSecondary,
                                ),
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

            const SizedBox(height: 18),

            // Quick Add Resource Banner
            GestureDetector(
              onTap: _showAddResourceSheet,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: stuTheme.surfaceTier1,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: stuTheme.accent.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: stuTheme.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_link_rounded,
                        color: stuTheme.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '+ New Note or Paste YouTube link',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: stuTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Auto-extracts chapters, timestamps & transcript',
                            style: TextStyle(
                              fontSize: 11,
                              color: stuTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: stuTheme.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Saved YouTube Videos Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_circle_filled_rounded,
                        color: Color(0xFFFF0000),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Saved Study Videos',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: stuTheme.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'View all (6)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: stuTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Video Cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredResources.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final resource = filteredResources[index];
                return _buildResourceCard(context, resource);
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(BuildContext context, LibraryResource res) {
    final stuTheme = context.stuTheme;

    if (res.type == ResourceType.video) {
      return CustomCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Thumbnail preview container
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: stuTheme.surfaceTier2,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.movie_creation_outlined,
                      size: 48,
                      color: stuTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                // Play overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                // Subject Tag
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: stuTheme.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          res.subjectTag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Duration Badge
                if (res.duration != null)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        res.duration!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          res.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: stuTheme.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${res.channel ?? "StuDesk Collection"} • ${res.metaInfo ?? ""}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: stuTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      res.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: res.isBookmarked ? stuTheme.accent : stuTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        // Toggle bookmark
                        final i = _resources.indexWhere((item) => item.id == res.id);
                        if (i != -1) {
                          final current = _resources[i];
                          _resources[i] = LibraryResource(
                            id: current.id,
                            title: current.title,
                            type: current.type,
                            subjectTag: current.subjectTag,
                            duration: current.duration,
                            metaInfo: current.metaInfo,
                            channel: current.channel,
                            isBookmarked: !current.isBookmarked,
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Document or Note Card
    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: res.type == ResourceType.pdf
                  ? stuTheme.errorContainer
                  : stuTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              res.type == ResourceType.pdf
                  ? Icons.picture_as_pdf_rounded
                  : Icons.description_rounded,
              color: res.type == ResourceType.pdf ? stuTheme.error : stuTheme.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  res.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: stuTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    PillBadge(
                      label: res.subjectTag,
                      backgroundColor: stuTheme.surfaceTier2,
                      textColor: stuTheme.textSecondary,
                      fontSize: 10,
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        res.metaInfo ?? '',
                        style: TextStyle(fontSize: 11, color: stuTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.download_rounded,
            color: stuTheme.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
