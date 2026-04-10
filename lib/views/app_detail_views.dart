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

    return Material(
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: ListenableBuilder(
              listenable: path,
              builder: (context, _) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: .min,
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
                      leading: const Icon(Icons.info),
                      title: const Text('App Info'),
                      selected: path.activeIndex == 0,
                      onTap: () {
                        coordinator.navigate(AppInfoRoute(appId: route.appId, queries: path.activeRoute.queries));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.screenshot),
                      title: const Text('Screenshots'),
                      selected: path.activeIndex == 1,
                      onTap: () {
                        coordinator.navigate(AppsScreenshotsRoute(appId: route.appId, queries: path.activeRoute.queries));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Versions'),
                      selected: path.activeIndex == 2,
                      onTap: () {
                        coordinator.navigate(AppVersionsRoute(appId: route.appId, queries: path.activeRoute.queries));
                      },
                    ),
                    ],
                  ),
                );
              },
            ),
          ),
          Flexible(child: route.buildPath(coordinator)),
        ],
      ),
    );
  }
}

// ============================================================================
// AppInfoRoute
// ============================================================================

class AppInfoRoute extends AppRoute {
  AppInfoRoute({required this.appId, super.queries});

  final String appId;

  @override
  String get title => 'App Info';

  @override
  IconData? get icon => Icons.info;

  @override
  List<Object?> get props => [appId, 'info'];

  @override
  Object? get parentLayoutKey => (AppDetailLayout, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId/info');

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
// AppsScreenshotsRoute — Layout with TabBar (subtypes from StoreOfApp)
// ============================================================================

class AppsScreenshotsRoute extends AppRoute with RouteLayout<AppRoute> {
  AppsScreenshotsRoute({required this.appId, super.queries});

  final String appId;

  @override
  String get title => 'Screenshots';

  @override
  IconData? get icon => Icons.screenshot;

  @override
  List<Object?> get props => [appId, 'screenshots'];

  @override
  Object? get parentLayoutKey => (AppDetailLayout, appId);

  @override
  Object get layoutKey => (AppsScreenshotsRoute, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId/screenshots');

  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.appScreenshotsPath(appId);

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return _AppScreenshotsBody(route: this, coordinator: coordinator);
  }
}

class _AppScreenshotsBody extends StatefulWidget {
  const _AppScreenshotsBody({required this.route, required this.coordinator});

  final AppsScreenshotsRoute route;
  final AppCoordinator coordinator;

  @override
  State<_AppScreenshotsBody> createState() => _AppScreenshotsBodyState();
}

class _AppScreenshotsBodyState extends State<_AppScreenshotsBody> with SingleTickerProviderStateMixin {
  late final IndexedStackPath<AppRoute> _path;
  late final List<String> _subTypes;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final store = kApps.where((a) => a.id == widget.route.appId).firstOrNull?.store ?? StoreOfApp.apple;
    _subTypes = store.screenshotSubTypes;
    _path = widget.coordinator.appScreenshotsPath(widget.route.appId);
    _tabController = TabController(length: _subTypes.length, initialIndex: _path.activeIndex, vsync: this);
    _path.addListener(_syncTab);
  }

  @override
  void dispose() {
    _path.removeListener(_syncTab);
    _tabController.dispose();
    super.dispose();
  }

  void _syncTab() {
    if (_tabController.index != _path.activeIndex) {
      _tabController.animateTo(_path.activeIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final sub in _subTypes) Tab(text: sub[0].toUpperCase() + sub.substring(1)),
            ],
            onTap: (i) {
              widget.coordinator.navigate(AppScreenshotSubTypeRoute(
                appId: widget.route.appId,
                subType: _subTypes[i],
                queries: _path.activeRoute.queries,
              ));
            },
          ),
        ),
        Expanded(child: widget.route.buildPath(widget.coordinator)),
      ],
    );
  }
}

// ============================================================================
// AppScreenshotSubTypeRoute — one tab per screenshot subtype
// ============================================================================

class AppScreenshotSubTypeRoute extends AppRoute {
  AppScreenshotSubTypeRoute({required this.appId, required this.subType, super.queries});

  final String appId;
  final String subType;

  @override
  String get title => subType[0].toUpperCase() + subType.substring(1);

  @override
  IconData? get icon => Icons.phone_android;

  @override
  List<Object?> get props => [appId, 'screenshots', subType];

  @override
  Object? get parentLayoutKey => (AppsScreenshotsRoute, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId/screenshots/$subType');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final appName = kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;
    final subTitle = subType[0].toUpperCase() + subType.substring(1);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '$subTitle Screenshots',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('$appName — $subTitle', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),
        ...List.generate(
          4,
          (i) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.image, color: Colors.blue[300]),
              title: Text('Screenshot ${i + 1}'),
              subtitle: Text('$subTitle — $appName screenshot ${i + 1}'),
              trailing: Text('${(i + 1) * 320}x${(i + 1) * 568}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// AppVersionsRoute — Layout with TabBar (tracks from StoreOfApp)
// ============================================================================

class AppVersionsRoute extends AppRoute with RouteLayout<AppRoute> {
  AppVersionsRoute({required this.appId, super.queries});

  final String appId;

  @override
  String get title => 'Versions';

  @override
  IconData? get icon => Icons.history;

  @override
  List<Object?> get props => [appId, 'versions'];

  @override
  Object? get parentLayoutKey => (AppDetailLayout, appId);

  @override
  Object get layoutKey => (AppVersionsRoute, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId/versions');

  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.appVersionsPath(appId);

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return _AppVersionsBody(route: this, coordinator: coordinator);
  }
}

class _AppVersionsBody extends StatefulWidget {
  const _AppVersionsBody({required this.route, required this.coordinator});

  final AppVersionsRoute route;
  final AppCoordinator coordinator;

  @override
  State<_AppVersionsBody> createState() => _AppVersionsBodyState();
}

class _AppVersionsBodyState extends State<_AppVersionsBody> with SingleTickerProviderStateMixin {
  late final IndexedStackPath<AppRoute> _path;
  late final List<String> _tracks;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final store = kApps.where((a) => a.id == widget.route.appId).firstOrNull?.store ?? StoreOfApp.apple;
    _tracks = store.versionTracks;
    _path = widget.coordinator.appVersionsPath(widget.route.appId);
    _tabController = TabController(length: _tracks.length, initialIndex: _path.activeIndex, vsync: this);
    _path.addListener(_syncTab);
  }

  @override
  void dispose() {
    _path.removeListener(_syncTab);
    _tabController.dispose();
    super.dispose();
  }

  void _syncTab() {
    if (_tabController.index != _path.activeIndex) {
      _tabController.animateTo(_path.activeIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final track in _tracks) Tab(text: track[0].toUpperCase() + track.substring(1)),
            ],
            onTap: (i) {
              widget.coordinator.navigate(AppVersionTrackRoute(
                appId: widget.route.appId,
                track: _tracks[i],
                queries: _path.activeRoute.queries,
              ));
            },
          ),
        ),
        Expanded(child: widget.route.buildPath(widget.coordinator)),
      ],
    );
  }
}

// ============================================================================
// AppVersionTrackRoute — one tab per track
// ============================================================================

class AppVersionTrackRoute extends AppRoute {
  AppVersionTrackRoute({required this.appId, required this.track, super.queries});

  final String appId;
  final String track;

  @override
  String get title => track[0].toUpperCase() + track.substring(1);

  @override
  IconData? get icon => Icons.track_changes;

  @override
  List<Object?> get props => [appId, 'versions', track];

  @override
  Object? get parentLayoutKey => (AppVersionsRoute, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId/versions/$track');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final appName = kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;
    final trackTitle = track[0].toUpperCase() + track.substring(1);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '$trackTitle Track',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('$appName — $trackTitle', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),
        ...List.generate(
          3,
          (i) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.new_releases),
              title: Text('v${3 - i}.${i}.0'),
              subtitle: Text('$trackTitle release ${3 - i}'),
              trailing: Chip(
                label: Text(
                  i == 0 ? 'Latest' : 'Older',
                  style: TextStyle(fontSize: 11, color: i == 0 ? Colors.green[700] : Colors.grey[600]),
                ),
                backgroundColor: i == 0 ? Colors.green[50] : Colors.grey[100],
              ),
            ),
          ),
        ),
      ],
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
