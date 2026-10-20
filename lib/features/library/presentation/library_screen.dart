import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_top_bar.dart';

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
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedCollectionId;
  ResourceType? _selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateCollectionDialog() {
    final stuTheme = context.stuTheme;
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

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
            Text(
              'New Learning Collection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Collection Name *',
                hintText: 'e.g. DSA Preparation or System Design',
                filled: true,
                fillColor: stuTheme.surfaceTier2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g. Tutorials, YouTube roadmaps, and interview practice',
                filled: true,
                fillColor: stuTheme.surfaceTier2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  final collection = LibraryCollection(
                    id: 'col_${DateTime.now().microsecondsSinceEpoch}',
                    name: name,
                    description: descCtrl.text.trim(),
                  );
                  await _repo.addCollection(collection);
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: const Text('Create Collection', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddResourceDialog() {
    final stuTheme = context.stuTheme;
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    ResourceType selectedType = ResourceType.video;
    String? assignedCollectionId = _selectedCollectionId;

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
                  'Save Learning Resource',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Resource Title *',
                    hintText: 'e.g. Graph Algorithms Explained',
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'URL (YouTube, Documentation, Article)',
                    hintText: 'https://...',
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ResourceType>(
                        initialValue: selectedType,
                        decoration: InputDecoration(
                          labelText: 'Resource Type',
                          filled: true,
                          fillColor: stuTheme.surfaceTier2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ResourceType.values
                            .map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase())))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: assignedCollectionId,
                        decoration: InputDecoration(
                          labelText: 'Collection',
                          filled: true,
                          fillColor: stuTheme.surfaceTier2,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None (General)')),
                          ..._repo.collections.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (val) {
                          setModalState(() => assignedCollectionId = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  style: TextStyle(color: stuTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Personal Notes / Takeaways',
                    hintText: 'Key insights or timestamps...',
                    filled: true,
                    fillColor: stuTheme.surfaceTier2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      final res = LibraryResource(
                        id: 'res_${DateTime.now().microsecondsSinceEpoch}',
                        title: title,
                        type: selectedType,
                        subjectTag: 'Learning',
                        url: urlCtrl.text.trim().isNotEmpty ? urlCtrl.text.trim() : null,
                        description: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                        collectionId: assignedCollectionId,
                      );
                      await _repo.addResource(res);
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save Resource', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchExternalUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open external link')),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return ListenableBuilder(
      listenable: _repo,
      builder: (context, _) {
        final collections = _repo.collections;
        final resources = _repo.resources.where((r) {
          final q = _searchCtrl.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            if (!r.title.toLowerCase().contains(q) &&
                !(r.description?.toLowerCase().contains(q) ?? false) &&
                !r.subjectTag.toLowerCase().contains(q)) {
              return false;
            }
          }
          if (_selectedCollectionId != null) {
            if (r.collectionId != _selectedCollectionId) return false;
          }
          if (_selectedTypeFilter != null) {
            if (r.type != _selectedTypeFilter) return false;
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: stuTheme.canvas,
          appBar: AppTopBar(
            showBrandWordmark: true,
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with Add Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: TextStyle(color: stuTheme.textPrimary, fontSize: 13.5),
                          decoration: InputDecoration(
                            hintText: 'Search saved links, videos, tutorials...',
                            hintStyle: TextStyle(color: stuTheme.textMuted, fontSize: 12.5),
                            prefixIcon: Icon(Icons.search_rounded, size: 20, color: stuTheme.textSecondary),
                            filled: true,
                            fillColor: stuTheme.surfaceTier1,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: stuTheme.border)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: stuTheme.surfaceTier1, foregroundColor: stuTheme.textPrimary),
                        icon: const Icon(Icons.create_new_folder_outlined),
                        tooltip: 'New Collection',
                        onPressed: _showCreateCollectionDialog,
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: stuTheme.accent, foregroundColor: stuTheme.onAccent),
                        icon: const Icon(Icons.add_link_rounded),
                        tooltip: 'Save Link / Resource',
                        onPressed: _showAddResourceDialog,
                      ),
                    ],
                  ),
                ),

                // Collections horizontal scroll
                if (collections.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('All Resources'),
                            selected: _selectedCollectionId == null,
                            onSelected: (_) => setState(() => _selectedCollectionId = null),
                          ),
                        ),
                        ...collections.map((col) {
                          final isSelected = _selectedCollectionId == col.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(col.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCollectionId = selected ? col.id : null;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                // Resource List or Empty State
                Expanded(
                  child: resources.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(color: stuTheme.surfaceTier2, shape: BoxShape.circle),
                                  child: Icon(Icons.video_library_outlined, size: 28, color: stuTheme.textMuted),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Your library is empty',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: stuTheme.textPrimary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Save YouTube study playlists, online tutorials, and documentation links. Organize them into custom collections.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: stuTheme.textSecondary, height: 1.4),
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                                      label: const Text('Create Collection'),
                                      onPressed: _showCreateCollectionDialog,
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: stuTheme.accent,
                                        foregroundColor: stuTheme.onAccent,
                                      ),
                                      icon: const Icon(Icons.add_link_rounded, size: 18),
                                      label: const Text('Save Resource'),
                                      onPressed: _showAddResourceDialog,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: resources.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final res = resources[index];
                            final hasUrl = res.url != null && res.url!.isNotEmpty;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: stuTheme.surfaceTier1,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: stuTheme.border),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: res.isYouTube
                                          ? Colors.red.withValues(alpha: 0.12)
                                          : stuTheme.accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      res.isYouTube ? Icons.play_circle_fill_rounded : Icons.link_rounded,
                                      color: res.isYouTube ? Colors.red.shade400 : stuTheme.accent,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
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
                                          ),
                                        ),
                                        if (res.description != null && res.description!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            res.description!,
                                            style: TextStyle(fontSize: 12, color: stuTheme.textSecondary),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        if (hasUrl)
                                          InkWell(
                                            onTap: () => _launchExternalUrl(res.url),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.open_in_new_rounded, size: 14, color: stuTheme.accent),
                                                const SizedBox(width: 4),
                                                Text(
                                                  res.isYouTube ? 'Watch on YouTube' : 'Open Link',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: stuTheme.accent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, size: 18, color: stuTheme.textMuted),
                                    onPressed: () => _repo.deleteResource(res.id),
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
        );
      },
    );
  }
}
