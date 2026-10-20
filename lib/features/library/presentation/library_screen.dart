import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
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
  final StuDeskRepository _repo = StuDeskRepository.instance;
  int _selectedFilterIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddResourceSheet() {
    final stuTheme = context.stuTheme;
    final titleController = TextEditingController();
    final urlOrContentController = TextEditingController();
    ResourceType selectedType = ResourceType.video;
    String selectedTag = _repo.courses.isNotEmpty ? _repo.courses.first.code : 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('YouTube Video')),
                        selected: selectedType == ResourceType.video,
                        selectedColor: stuTheme.accent.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selectedType == ResourceType.video ? stuTheme.accent : stuTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) => setSheetState(() => selectedType = ResourceType.video),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Text Note')),
                        selected: selectedType == ResourceType.note,
                        selectedColor: stuTheme.accent.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selectedType == ResourceType.note ? stuTheme.accent : stuTheme.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) => setSheetState(() => selectedType = ResourceType.note),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleController,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Resource Title',
                    labelStyle: TextStyle(color: stuTheme.textSecondary),
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlOrContentController,
                  maxLines: selectedType == ResourceType.note ? 3 : 1,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: selectedType == ResourceType.video
                        ? 'YouTube URL (https://youtube.com/...)'
                        : 'Note content or summary',
                    labelStyle: TextStyle(color: stuTheme.textSecondary),
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Subject: ', style: TextStyle(color: stuTheme.textSecondary, fontSize: 13)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedTag,
                      dropdownColor: stuTheme.surfaceTier2,
                      underline: const SizedBox(),
                      items: [
                        ..._repo.courses.map((c) => DropdownMenuItem(value: c.code, child: Text(c.code))),
                        if (_repo.courses.every((c) => c.code != 'General'))
                          const DropdownMenuItem(value: 'General', child: Text('General')),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => selectedTag = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: stuTheme.accent,
                      foregroundColor: stuTheme.onAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final content = urlOrContentController.text.trim();
                      if (title.isNotEmpty) {
                        final newResource = LibraryResource(
                          id: 'res_${DateTime.now().microsecondsSinceEpoch}',
                          title: title,
                          type: selectedType,
                          subjectTag: selectedTag,
                          channel: selectedType == ResourceType.video ? 'YouTube Academy' : 'Personal Notes',
                          duration: selectedType == ResourceType.video ? '15:00' : null,
                          url: selectedType == ResourceType.video ? content : null,
                          noteContent: selectedType == ResourceType.note ? content : null,
                          metaInfo: selectedType == ResourceType.video ? 'Curated Reference' : 'Written Note',
                          isBookmarked: true,
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        await _repo.addResource(newResource);
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: stuTheme.surfaceTier3,
                            behavior: SnackBarBehavior.floating,
                            content: Text('Added to your study library', style: TextStyle(color: stuTheme.textPrimary)),
                          ),
                        );
                      }
                    },
                    child: const Text('Add to Library', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openResourceViewer(LibraryResource res) {
    final stuTheme = context.stuTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: stuTheme.surfaceTier1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
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
            const SizedBox(height: 16),
            Row(
              children: [
                PillBadge(
                  label: res.subjectTag,
                  backgroundColor: stuTheme.accent.withValues(alpha: 0.15),
                  textColor: stuTheme.accent,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    res.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: res.isBookmarked ? stuTheme.accent : stuTheme.textSecondary,
                  ),
                  onPressed: () {
                    _repo.toggleResourceBookmark(res.id);
                    Navigator.pop(ctx);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: stuTheme.error),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _repo.deleteResource(res.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: stuTheme.surfaceTier3,
                          behavior: SnackBarBehavior.floating,
                          content: Text('Resource removed from library', style: TextStyle(color: stuTheme.textPrimary)),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              res.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: stuTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${res.channel ?? "StuDesk"} • ${res.metaInfo ?? ""}',
              style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            if (res.noteContent != null && res.noteContent!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: stuTheme.surfaceTier2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  res.noteContent!,
                  style: TextStyle(fontSize: 13, color: stuTheme.textPrimary, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (res.type == ResourceType.video) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text('Open in YouTube / Browser', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final targetUrl = res.url ?? 'https://www.youtube.com';
                    final uri = Uri.parse(targetUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          backgroundColor: stuTheme.surfaceTier3,
                          content: Text('Could not open link: $targetUrl', style: TextStyle(color: stuTheme.textPrimary)),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return ListenableBuilder(
      listenable: _repo,
      builder: (context, _) {
        final allResources = _repo.resources;

        final filters = [
          {'label': 'All', 'count': allResources.length, 'type': null},
          {
            'label': 'Notes',
            'count': allResources.where((r) => r.type == ResourceType.note).length,
            'type': ResourceType.note,
          },
          {
            'label': 'Saved Videos',
            'count': allResources.where((r) => r.type == ResourceType.video).length,
            'type': ResourceType.video,
          },
          {
            'label': 'Documents & PDFs',
            'count': allResources.where((r) => r.type == ResourceType.pdf).length,
            'type': ResourceType.pdf,
          },
          {
            'label': 'Bookmarks',
            'count': allResources.where((r) => r.isBookmarked).length,
            'type': 'bookmark',
          },
        ];

        final currentFilter = filters[_selectedFilterIndex.clamp(0, filters.length - 1)];
        final query = _searchController.text.trim().toLowerCase();

        final filteredResources = allResources.where((r) {
          // Filter by category
          if (currentFilter['type'] == 'bookmark' && !r.isBookmarked) return false;
          if (currentFilter['type'] is ResourceType && r.type != currentFilter['type']) return false;

          // Filter by query
          if (query.isNotEmpty) {
            final matchTitle = r.title.toLowerCase().contains(query);
            final matchTag = r.subjectTag.toLowerCase().contains(query);
            final matchChannel = r.channel?.toLowerCase().contains(query) ?? false;
            final matchDesc = r.noteContent?.toLowerCase().contains(query) ?? false;
            return matchTitle || matchTag || matchChannel || matchDesc;
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: stuTheme.canvas,
          appBar: AppTopBar(
            title: 'Library',
            titleTrailing: PillBadge(
              label: '${allResources.length} items',
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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
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
                          onChanged: (_) => setState(() {}),
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
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          child: Icon(Icons.clear_rounded, size: 18, color: stuTheme.textSecondary),
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
                    children: List.generate(filters.length, (index) {
                      final item = filters[index];
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
                                '+ New Note or Saved YouTube link',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: stuTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Store videos, study summaries & quick notes',
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

                // Resources List Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedFilterIndex == 2
                            ? 'Notes & Summaries'
                            : (_selectedFilterIndex == 3
                                ? 'PDFs & Lecture Slides'
                                : (_selectedFilterIndex == 4
                                    ? 'Bookmarked Resources'
                                    : 'Saved Study Videos')),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: stuTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${filteredResources.length} items',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: stuTheme.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (filteredResources.isEmpty)
                  CustomCard(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.folder_open_rounded, size: 40, color: stuTheme.textSecondary),
                          const SizedBox(height: 8),
                          Text(
                            'No resources found',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the banner above to add your first note or video link.',
                            style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
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
        ),
      ),
    );
  },
);
  }

  Widget _buildResourceCard(BuildContext context, LibraryResource res) {
    final stuTheme = context.stuTheme;

    if (res.type == ResourceType.video) {
      return GestureDetector(
        onTap: () => _openResourceViewer(res),
        child: CustomCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Thumbnail preview container
              Stack(
                children: [
                  Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: stuTheme.surfaceTier2,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.movie_creation_outlined,
                        size: 44,
                        color: stuTheme.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
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
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        res.subjectTag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
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
                            '${res.channel ?? "YouTube Reference"} • ${res.metaInfo ?? ""}',
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
                      onPressed: () => _repo.toggleResourceBookmark(res.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Document or Note Card
    return GestureDetector(
      onTap: () => _openResourceViewer(res),
      child: CustomCard(
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
                          res.metaInfo ?? (res.noteContent != null ? 'Note' : 'Document'),
                          style: TextStyle(fontSize: 11, color: stuTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
              onPressed: () => _repo.toggleResourceBookmark(res.id),
            ),
          ],
        ),
      ),
    );
  }
}
