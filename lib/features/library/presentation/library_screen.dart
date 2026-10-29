import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/studesk_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/dialogs/studesk_forms.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_top_bar.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPlanner;

  const LibraryScreen({super.key, this.onNavigateToPlanner});

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
    StuDeskForms.showCollectionForm(context);
  }

  void _showAddResourceDialog() {
    StuDeskForms.showResourceForm(
      context,
      defaultCollectionId: _selectedCollectionId,
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
          appBar: AppTopBar(showBrandWordmark: true),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with Add Actions
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: TextStyle(
                            color: stuTheme.textPrimary,
                            fontSize: 13.5,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Search saved links, videos, tutorials...',
                            hintStyle: TextStyle(
                              color: stuTheme.textMuted,
                              fontSize: 12.5,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: stuTheme.textSecondary,
                            ),
                            filled: true,
                            fillColor: stuTheme.surfaceTier1,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: stuTheme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: stuTheme.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: stuTheme.surfaceTier1,
                          foregroundColor: stuTheme.textPrimary,
                        ),
                        icon: const Icon(Icons.create_new_folder_outlined),
                        tooltip: 'New Collection',
                        onPressed: _showCreateCollectionDialog,
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: stuTheme.accent,
                          foregroundColor: stuTheme.onAccent,
                        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('All Resources'),
                            selected: _selectedCollectionId == null,
                            onSelected: (_) =>
                                setState(() => _selectedCollectionId = null),
                          ),
                        ),
                        ...collections.map((col) {
                          final isSelected = _selectedCollectionId == col.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onLongPress: () async {
                                final action =
                                    await showModalBottomSheet<String>(
                                      context: context,
                                      backgroundColor: stuTheme.surfaceTier1,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (ctx) => SafeArea(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ListTile(
                                              leading: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                              title: Text('Edit "${col.name}"'),
                                              onTap: () =>
                                                  Navigator.pop(ctx, 'edit'),
                                            ),
                                            ListTile(
                                              leading: Icon(
                                                Icons.delete_outline,
                                                color: stuTheme.textPrimary,
                                              ),
                                              title: Text(
                                                'Delete "${col.name}"',
                                                style: TextStyle(
                                                  color: stuTheme.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              onTap: () =>
                                                  Navigator.pop(ctx, 'delete'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                if (!context.mounted) return;
                                if (action == 'edit') {
                                  StuDeskForms.showCollectionForm(
                                    context,
                                    existingCollection: col,
                                  );
                                } else if (action == 'delete') {
                                  final confirmed =
                                      await StuDeskForms.confirmDelete(
                                        context,
                                        title: 'Delete Collection',
                                        message:
                                            'Are you sure you want to delete collection "${col.name}"? Saved resources will be preserved.',
                                      );
                                  if (confirmed) {
                                    if (_selectedCollectionId == col.id) {
                                      setState(
                                        () => _selectedCollectionId = null,
                                      );
                                    }
                                    await _repo.deleteCollection(col.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Collection "${col.name}" deleted',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              child: FilterChip(
                                label: Text(col.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCollectionId = selected
                                        ? col.id
                                        : null;
                                  });
                                },
                              ),
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
                                  decoration: BoxDecoration(
                                    color: stuTheme.surfaceTier2,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.video_library_outlined,
                                    size: 28,
                                    color: stuTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Your library is empty',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: stuTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Save YouTube study playlists, online tutorials, and documentation links. Organize them into custom collections.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: stuTheme.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(
                                        Icons.create_new_folder_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Create Collection'),
                                      onPressed: _showCreateCollectionDialog,
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: stuTheme.accent,
                                        foregroundColor: stuTheme.onAccent,
                                      ),
                                      icon: const Icon(
                                        Icons.add_link_rounded,
                                        size: 18,
                                      ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          itemCount: resources.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final res = resources[index];
                            final hasUrl =
                                res.url != null && res.url!.isNotEmpty;

                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => StuDeskForms.showResourceForm(
                                context,
                                existingResource: res,
                                defaultCollectionId: _selectedCollectionId,
                              ),
                              child: Container(
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
                                        color: stuTheme.surfaceTier2,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: stuTheme.border,
                                        ),
                                      ),
                                      child: Icon(
                                        res.isYouTube
                                            ? Icons.play_circle_fill_rounded
                                            : Icons.link_rounded,
                                        color: stuTheme.textPrimary,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            res.title,
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                              color: stuTheme.textPrimary,
                                            ),
                                          ),
                                          if (res.description != null &&
                                              res.description!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              res.description!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: stuTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),
                                          if (hasUrl)
                                            InkWell(
                                              onTap: () =>
                                                  _launchExternalUrl(res.url),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.open_in_new_rounded,
                                                    size: 14,
                                                    color: stuTheme.accent,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    res.isYouTube
                                                        ? 'Watch on YouTube'
                                                        : 'Open Link',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: stuTheme.textMuted,
                                      ),
                                      onPressed: () async {
                                        final confirmed =
                                            await StuDeskForms.confirmDelete(
                                              context,
                                              title: 'Delete Resource',
                                              message:
                                                  'Are you sure you want to delete "${res.title}" from your library?',
                                            );
                                        if (confirmed) {
                                          await _repo.deleteResource(res.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Resource deleted',
                                                    ),
                                                  ),
                                                );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
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
