part of '../main_chrome_tabs.dart';

// ============================================================================
// Simple "Bloc" simulator — receives filter state ONE-WAY from route queries
// ============================================================================

class _AppDataBloc extends ChangeNotifier {
  Map<String, String> _activeFilters = {};
  List<String> _filteredItems = [];

  Map<String, String> get activeFilters => _activeFilters;
  List<String> get filteredItems => _filteredItems;

  /// Called ONE-WAY from route queryNotifier listener.
  /// NEVER call updateQueries from this class (avoids circular flow).
  void onFiltersChanged(Map<String, String> allQueries) {
    final filters = Map.fromEntries(allQueries.entries.where((e) => e.key.startsWith('f')));
    if (_mapEquals(filters, _activeFilters)) return;
    _activeFilters = filters;
    _filteredItems = _fetchData(filters);
    notifyListeners();
  }

  List<String> _fetchData(Map<String, String> filters) {
    if (filters.isEmpty) {
      return List.generate(8, (i) => 'Item ${i + 1} (no filter)');
    }
    final tag = filters.entries.map((e) => '${e.key}=${e.value}').join(', ');
    return List.generate(5, (i) => 'Result ${i + 1}  [$tag]');
  }

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

// ============================================================================
// AppDetailTab — filter chips + one-way bloc demo
// ============================================================================

/// Root content for a dynamic app tab.
class AppDetailTab extends AppRoute {
  AppDetailTab({required this.appId, super.queries});

  final String appId;

  @override
  String get title => _kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;

  @override
  IconData? get icon => _kApps.where((a) => a.id == appId).firstOrNull?.icon ?? Icons.apps;

  @override
  List<Object?> get props => [appId];

  @override
  Object? get parentLayoutKey => (AppTabLayout, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return _AppDetailTabBody(route: this, coordinator: coordinator);
  }
}

class _AppDetailTabBody extends StatefulWidget {
  const _AppDetailTabBody({required this.route, required this.coordinator});

  final AppDetailTab route;
  final AppCoordinator coordinator;

  @override
  State<_AppDetailTabBody> createState() => _AppDetailTabBodyState();
}

class _AppDetailTabBodyState extends State<_AppDetailTabBody> {
  final _bloc = _AppDataBloc();

  @override
  void initState() {
    super.initState();
    // ONE-WAY: route queries -> bloc (NEVER the reverse)
    widget.route.queryNotifier.addListener(_syncToBloc);
    _syncToBloc();
  }

  @override
  void dispose() {
    widget.route.queryNotifier.removeListener(_syncToBloc);
    _bloc.dispose();
    super.dispose();
  }

  void _syncToBloc() => _bloc.onFiltersChanged(widget.route.queries);

  @override
  Widget build(BuildContext context) {
    final app = _kApps.where((a) => a.id == widget.route.appId).firstOrNull;
    final appName = app?.name ?? widget.route.appId;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(appName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(
          'App ID: ${widget.route.appId}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // ----- Filter Chips (rebuild only when filter queries change) -----
        widget.route.selectorBuilder<Map<String, String>>(
          selector: (q) => Map.fromEntries(q.entries.where((e) => e.key.startsWith('f'))),
          builder: (context, filters) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_list, size: 20, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text('Active Filters', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const Spacer(),
                        ActionChip(
                          avatar: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit Filters'),
                          onPressed: () => widget.coordinator.push(
                            AppFilterRoute(appId: widget.route.appId, queries: widget.route.queries),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (filters.isEmpty)
                      Text(
                        'No filters applied',
                        style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: filters.entries.map((e) {
                          return Chip(
                            label: Text('${e.key}: ${e.value}'),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              final updated = Map<String, String>.from(widget.route.queries)..remove(e.key);
                              widget.route.updateQueries(widget.coordinator, queries: updated);
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // ----- Data list driven by bloc (one-way from queries) -----
        ListenableBuilder(
          listenable: _bloc,
          builder: (context, _) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.list_alt, size: 20, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Filtered Data (from Bloc)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bloc receives filters ONE-WAY from queryNotifier',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const Divider(),
                    ..._bloc.filteredItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6),
                            const SizedBox(width: 12),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // ----- Existing navigation cards -----
        Card(
          child: ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Short Description', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View the short description of this app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => widget.coordinator.push(AppDescriptionRoute(appId: widget.route.appId, type: 'short')),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Full Description', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View the full description of this app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => widget.coordinator.push(AppDescriptionRoute(appId: widget.route.appId, type: 'full')),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Configure this app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => widget.coordinator.push(AppSettingsRoute(appId: widget.route.appId)),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        ValueListenableBuilder<bool>(
          valueListenable: widget.coordinator.nodesOpen,
          builder: (context, isOpen, _) {
            return ElevatedButton.icon(
              onPressed: () => widget.coordinator.nodesOpen.value = !isOpen,
              icon: Icon(isOpen ? Icons.close : Icons.account_tree),
              label: Text(isOpen ? 'Close Nodes' : 'Open Nodes'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            );
          },
        ),
      ],
    );
  }
}

class AppDescriptionRoute extends AppRoute {
  AppDescriptionRoute({required this.appId, required this.type, super.queries});

  final String appId;
  final String type;

  @override
  String get title => type == 'short' ? 'Short Description' : 'Full Description';

  @override
  IconData? get icon => Icons.description;

  @override
  List<Object?> get props => [appId, 'description', type];

  @override
  Object? get parentLayoutKey => (AppTabLayout, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId/description/$type');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final appName = _kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;
    final typeTitle = type == 'short' ? 'Short Description' : 'Full Description';

    return Column(
      children: [
        _InTabNavBar(title: '$typeTitle - $appName', coordinator: coordinator),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      type == 'short'
                          ? '$appName is a powerful application for productivity and daily use.'
                          : '$appName is a comprehensive application designed to enhance your '
                                'productivity and streamline your daily workflow. It offers a wide '
                                'range of features including real-time collaboration, cloud sync, '
                                'and cross-platform support.\n\n'
                                'Key features:\n'
                                '- Intuitive user interface\n'
                                '- Cross-platform compatibility\n'
                                '- Real-time sync\n'
                                '- Offline support',
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

class AppSettingsRoute extends AppRoute {
  AppSettingsRoute({required this.appId, super.queries});

  final String appId;

  @override
  String get title => 'Settings';

  @override
  IconData? get icon => Icons.settings;

  @override
  List<Object?> get props => [appId, 'settings'];

  @override
  Object? get parentLayoutKey => (AppTabLayout, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId/settings');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final appName = _kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;

    return Material(
      color: Colors.amber,
      child: Column(
        children: [
          _InTabNavBar(title: 'Settings - $appName', coordinator: coordinator),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: List.generate(
                3,
                (i) => SwitchListTile(
                  title: Text('$appName Setting ${i + 1}'),
                  subtitle: Text('Configure option ${i + 1}'),
                  value: i.isEven,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AppFilterRoute — sub-route for editing filters
// ============================================================================

const _kAvailableFilters = {
  'f1': ['all', 'active', 'archived', 'draft'],
  'f2': ['newest', 'oldest', 'popular', 'trending'],
  'f3': ['free', 'paid', 'subscription'],
  'f4': ['mobile', 'desktop', 'web', 'all-platforms'],
};

class AppFilterRoute extends AppRoute {
  AppFilterRoute({required this.appId, super.queries});

  final String appId;

  @override
  String get title => 'Filters';

  @override
  IconData? get icon => Icons.filter_list;

  @override
  List<Object?> get props => [appId, 'filter'];

  @override
  Object? get parentLayoutKey => (AppTabLayout, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId/filter');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return _AppFilterBody(route: this, coordinator: coordinator);
  }
}

class _AppFilterBody extends StatefulWidget {
  const _AppFilterBody({required this.route, required this.coordinator});

  final AppFilterRoute route;
  final AppCoordinator coordinator;

  @override
  State<_AppFilterBody> createState() => _AppFilterBodyState();
}

class _AppFilterBodyState extends State<_AppFilterBody> {
  void _updateFilter(String key, String? value) {
    final updated = Map<String, String>.from(widget.route.queries);
    if (value != null) {
      updated[key] = value;
    } else {
      updated.remove(key);
    }
    widget.route.updateQueries(widget.coordinator, queries: updated);
  }

  void _onSave() {
    // Navigate back to AppDetailTab with the current queries.
    // ZenRouter finds the existing AppDetailTab (same props/appId),
    // calls onUpdate -> queryNotifier.value = newRoute.queries.
    widget.coordinator.navigate(AppDetailTab(appId: widget.route.appId, queries: widget.route.queries));
  }

  @override
  Widget build(BuildContext context) {
    final appName = _kApps.where((a) => a.id == widget.route.appId).firstOrNull?.name ?? widget.route.appId;

    return Column(
      children: [
        _InTabNavBar(title: 'Edit Filters - $appName', coordinator: widget.coordinator),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Filters', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Select values for each filter. Press Save to apply.', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              ..._kAvailableFilters.entries.map((entry) {
                final filterKey = entry.key;
                final options = entry.value;

                return widget.route.selectorBuilder<String?>(
                  selector: (q) => q[filterKey],
                  builder: (context, current) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  filterKey.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 1),
                                ),
                                const Spacer(),
                                if (current != null)
                                  GestureDetector(
                                    onTap: () => _updateFilter(filterKey, null),
                                    child: Text('Clear', style: TextStyle(color: Colors.red[400], fontSize: 13)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: options.map((option) {
                                final selected = current == option;
                                return ChoiceChip(
                                  label: Text(option),
                                  selected: selected,
                                  onSelected: (val) => _updateFilter(filterKey, val ? option : null),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _onSave,
                icon: const Icon(Icons.check),
                label: const Text('Save Filters'),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => widget.coordinator.tryPop(),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
