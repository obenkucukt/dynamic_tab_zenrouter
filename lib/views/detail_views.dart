part of '../main_chrome_tabs.dart';

/// Root content for a dynamic detail tab.
class DetailTab extends AppRoute {
  DetailTab({required this.id});

  final int id;

  @override
  List<Object?> get props => [id];

  @override
  Object? get parentLayoutKey => (DetailTabLayout, id);

  @override
  Uri toUri() => Uri.parse('/detail/$id');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Tab $id', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text('Tab ID: $id', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Statistics', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View stats for this tab'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => coordinator.push(DetailSectionRoute(tabId: id, section: 'stats')),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View history for this tab'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => coordinator.push(DetailSectionRoute(tabId: id, section: 'history')),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.note_add),
            title: const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View and create notes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => coordinator.push(DetailSectionRoute(tabId: id, section: 'notes')),
          ),
        ),
      ],
    );
  }
}

/// A sub-page inside a dynamically-created detail tab.
/// Uses [parentLayoutKey] with the tab id so the coordinator resolves the
/// correct [DetailTabLayout] instance and its [NavigationPath].
class DetailSectionRoute extends AppRoute {
  DetailSectionRoute({required this.tabId, required this.section});

  final int tabId;
  final String section;

  @override
  List<Object?> get props => [tabId, section];

  @override
  Object? get parentLayoutKey => (DetailTabLayout, tabId);

  @override
  Uri toUri() => Uri(path: '/detail/$tabId/$section');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final sectionTitle = '${section[0].toUpperCase()}${section.substring(1)}';

    return Column(
      children: [
        _InTabNavBar(title: '$sectionTitle - Tab $tabId', onBack: () => coordinator.tryPop()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                sectionTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SelectableText(
                'This page lives inside dynamic Tab $tabId.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              if (section == 'notes') ...[
                ...List.generate(
                  3,
                  (i) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.note),
                      title: Text('Note ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Note content for tab $tabId'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => coordinator.push(DetailNoteRoute(tabId: tabId, noteId: i + 1)),
                    ),
                  ),
                ),
              ] else
                ...List.generate(
                  4,
                  (i) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(section == 'stats' ? Icons.bar_chart : Icons.access_time),
                      title: Text('$sectionTitle item ${i + 1}'),
                      subtitle: Text('Details for $section item ${i + 1} in tab $tabId'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Third-level nesting inside a dynamic tab: Notes -> single Note detail.
class DetailNoteRoute extends AppRoute with RouteDeepLink {
  DetailNoteRoute({required this.tabId, required this.noteId});

  final int tabId;
  final int noteId;

  @override
  List<Object?> get props => [tabId, 'note', noteId];

  @override
  Object? get parentLayoutKey => (DetailTabLayout, tabId);

  @override
  Uri toUri() => Uri.parse('/detail/$tabId/notes/$noteId');

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.push;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Column(
      children: [
        _InTabNavBar(title: 'Note $noteId - Tab $tabId', onBack: () => coordinator.tryPop()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Note $noteId',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      'This is the full content of note $noteId inside dynamic tab $tabId.\n\n'
                      'Three levels deep:  Tab $tabId  >  Notes  >  Note $noteId\n\n'
                      'The browser URL reflects the full path.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
