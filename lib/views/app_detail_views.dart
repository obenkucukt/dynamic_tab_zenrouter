// ============================================================================
// AppDetailLayout — Drawer layout with IndexedStackPath
// ============================================================================

import 'package:dynamic_tab_zenrouter/app_coordinator.dart';
import 'package:dynamic_tab_zenrouter/main_chrome_tabs.dart';
import 'package:dynamic_tab_zenrouter/views/apps_view.dart';
import 'package:dynamic_tab_zenrouter/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

class AppDetailLayout extends AppRoute with RouteLayout<AppRoute> {
  AppDetailLayout({required this.appId, super.queries});

  final String appId;

  @override
  String get title => kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;

  @override
  IconData? get icon => kApps.where((a) => a.id == appId).firstOrNull?.icon ?? Icons.apps;

  @override
  List<Object?> get props => [appId];

  @override
  Object? get parentLayoutKey => (AppTabLayout, appId);

  @override
  Object get layoutKey => (AppDetailLayout, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId');

  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.appDrawerPath(appId);

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return _AppDetailLayoutBody(route: this, coordinator: coordinator);
  }
}

class _AppDetailLayoutBody extends StatelessWidget {
  const _AppDetailLayoutBody({required this.route, required this.coordinator});

  final AppDetailLayout route;
  final AppCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final appName = kApps.where((a) => a.id == route.appId).firstOrNull?.name ?? route.appId;
    final appIcon = kApps.where((a) => a.id == route.appId).firstOrNull?.icon ?? Icons.apps;
    final path = coordinator.appDrawerPath(route.appId);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(ctx).openDrawer()),
        ),
        title: Text(appName),
        centerTitle: false,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListenableBuilder(
          listenable: path,
          builder: (context, _) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(appIcon, size: 40, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        appName,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text('App ID: ${route.appId}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Short Description'),
                  selected: path.activeIndex == 0,
                  onTap: () {
                    coordinator.navigate(AppShortDescRoute(appId: route.appId));
                    // Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.article),
                  title: const Text('Long Description'),
                  selected: path.activeIndex == 1,
                  onTap: () {
                    coordinator.navigate(AppLongDescRoute(appId: route.appId));
                    // Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('App Settings'),
                  selected: path.activeIndex == 2,
                  onTap: () {
                    coordinator.navigate(AppSettingsRoute(appId: route.appId));
                    // Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: route.buildPath(coordinator),
    );
  }
}

// ============================================================================
// AppShortDescRoute
// ============================================================================

class AppShortDescRoute extends AppRoute {
  AppShortDescRoute({required this.appId, super.queries});

  final String appId;

  @override
  String get title => 'Short Description';

  @override
  IconData? get icon => Icons.description;

  @override
  List<Object?> get props => [appId, 'short-desc'];

  @override
  Object? get parentLayoutKey => (AppDetailLayout, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId/short-desc');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final appName = kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Short Description',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '$appName is a powerful application for productivity and daily use.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AppLongDescRoute
// ============================================================================

class AppLongDescRoute extends AppRoute {
  AppLongDescRoute({required this.appId, super.queries});

  final String appId;

  @override
  String get title => 'Long Description';

  @override
  IconData? get icon => Icons.article;

  @override
  List<Object?> get props => [appId, 'long-desc'];

  @override
  Object? get parentLayoutKey => (AppDetailLayout, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId/long-desc');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final appName = kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Long Description',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '$appName is a comprehensive application designed to enhance your '
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
    );
  }
}

// ============================================================================
// AppSettingsRoute
// ============================================================================

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
  Object? get parentLayoutKey => (AppDetailLayout, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId/settings');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final appName = kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;

    return ListView(
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
    widget.coordinator.tryPop();
  }

  @override
  Widget build(BuildContext context) {
    final appName = kApps.where((a) => a.id == widget.route.appId).firstOrNull?.name ?? widget.route.appId;

    return Column(
      children: [
        InTabNavBar(title: 'Edit Filters - $appName', coordinator: widget.coordinator),
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
