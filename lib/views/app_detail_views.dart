// ============================================================================
// AppDetailLayout — Drawer layout with IndexedStackPath
// ============================================================================

import 'package:dynamic_tab_zenrouter/app_coordinator.dart';
import 'package:dynamic_tab_zenrouter/main_chrome_tabs.dart';
import 'package:dynamic_tab_zenrouter/stupid_sheet_page.dart';
import 'package:dynamic_tab_zenrouter/views/apps_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
                          coordinator.navigate(
                            AppsScreenshotsRoute(appId: route.appId, queries: path.activeRoute.queries),
                          );
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
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: const Text('Language'),
                        subtitle: path.activeRoute.selectorBuilder<String?>(
                          selector: (q) => q['storeLanguage'],
                          builder: (context, lang) =>
                              Text(lang ?? '—', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ),
                        onTap: () {
                          coordinator.push(AppLanguageRoute(appId: route.appId, queries: path.activeRoute.queries));
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
            tabs: [for (final sub in _subTypes) Tab(text: sub[0].toUpperCase() + sub.substring(1))],
            onTap: (i) {
              widget.coordinator.navigate(
                AppScreenshotSubTypeRoute(
                  appId: widget.route.appId,
                  subType: _subTypes[i],
                  queries: _path.activeRoute.queries,
                ),
              );
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
    final images = _screenshotImages[subType] ?? _screenshotImages['iphone']!;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$subTitle Screenshots',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('$appName — $subTitle', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childCount: images.length,
            itemBuilder: (context, i) {
              final img = images[i];
              return Column(
                crossAxisAlignment: .stretch,
                spacing: 4,
                children: [
                  Text('Screenshot ${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ClipRSuperellipse(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    child: Image.network(
                      img.url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return AspectRatio(
                          aspectRatio: img.aspectRatio,
                          child: Container(
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stack) => AspectRatio(
                        aspectRatio: img.aspectRatio,
                        child: Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}

class _ScreenshotImage {
  const _ScreenshotImage(this.url, this.aspectRatio);
  final String url;
  final double aspectRatio;
}

const _screenshotImages = <String, List<_ScreenshotImage>>{
  'iphone': [
    _ScreenshotImage('https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=400', 9 / 19.5),
    _ScreenshotImage('https://images.unsplash.com/photo-1611532736597-de2d4265fba3?w=400', 9 / 19.5),
    _ScreenshotImage('https://images.unsplash.com/photo-1556656793-08538906a9f8?w=400', 9 / 19.5),
    _ScreenshotImage('https://images.unsplash.com/photo-1592899677977-9c10ca588bbd?w=400', 9 / 19.5),
    _ScreenshotImage('https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=400', 9 / 19.5),
  ],
  'ipad': [
    _ScreenshotImage('https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=600', 4 / 3),
    _ScreenshotImage('https://images.unsplash.com/photo-1585790050230-5dd28404ccb9?w=600', 4 / 3),
    _ScreenshotImage('https://images.unsplash.com/photo-1542751110-97427bbecf20?w=600', 4 / 3),
    _ScreenshotImage('https://images.unsplash.com/photo-1527698266440-12104e498b76?w=600', 4 / 3),
  ],
  'phone': [
    _ScreenshotImage('https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=400', 9 / 20),
    _ScreenshotImage('https://images.unsplash.com/photo-1605170439002-90845e8c0137?w=400', 9 / 20),
    _ScreenshotImage('https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=400', 9 / 20),
    _ScreenshotImage('https://images.unsplash.com/photo-1617625802912-cde586faf331?w=400', 9 / 20),
    _ScreenshotImage('https://images.unsplash.com/photo-1585060544812-6b45742d762f?w=400', 9 / 20),
  ],
  'tablet7': [
    _ScreenshotImage('https://images.unsplash.com/photo-1561154464-82e9aab73a55?w=500', 16 / 10),
    _ScreenshotImage('https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=500', 16 / 10),
    _ScreenshotImage('https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=500', 16 / 10),
    _ScreenshotImage('https://images.unsplash.com/photo-1488590528505-98d2b5aba04b?w=500', 16 / 10),
  ],
  'tablet10': [
    _ScreenshotImage('https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=600', 4 / 3),
    _ScreenshotImage('https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=600', 4 / 3),
    _ScreenshotImage('https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=600', 4 / 3),
    _ScreenshotImage('https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=600', 4 / 3),
    _ScreenshotImage('https://images.unsplash.com/photo-1504868584819-f8e8b4b6d7e3?w=600', 4 / 3),
  ],
};

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
            tabs: [for (final track in _tracks) Tab(text: track[0].toUpperCase() + track.substring(1))],
            onTap: (i) {
              widget.coordinator.navigate(
                AppVersionTrackRoute(appId: widget.route.appId, track: _tracks[i], queries: _path.activeRoute.queries),
              );
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
// AppLanguageRoute — drawer item for changing storeLanguage query param
// ============================================================================

const _kAvailableLanguages = ['en', 'tr', 'de', 'fr', 'es', 'it', 'ja', 'ko', 'zh', 'pt'];

const _kLanguageLabels = <String, String>{
  'en': 'English',
  'tr': 'Türkçe',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
  'it': 'Italiano',
  'ja': '日本語',
  'ko': '한국어',
  'zh': '中文',
  'pt': 'Português',
};

class AppLanguageRoute extends AppRoute with RouteTransition {
  AppLanguageRoute({required this.appId, super.queries});

  final String appId;

  @override
  String get title => 'Language';

  @override
  IconData? get icon => Icons.language;

  @override
  List<Object?> get props => [appId, 'languages'];

  @override
  Object? get parentLayoutKey => (AppTabLayout, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId/languages');

  @override
  StackTransition<T> transition<T extends RouteUnique>(covariant AppCoordinator coordinator) {
    return StackTransition.custom(
      builder: (context) => build(coordinator, context),
      pageBuilder: (context, key, child) => StupidSimpleSheetPage(key: key, child: child),
    );
  }

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return _AppLanguageBody(route: this, coordinator: coordinator);
  }
}

class _AppLanguageBody extends StatelessWidget {
  const _AppLanguageBody({required this.route, required this.coordinator});

  final AppLanguageRoute route;
  final AppCoordinator coordinator;

  void _selectLanguage(String lang) {
    final updated = Map<String, String>.from(route.queries);
    updated['storeLanguage'] = lang;
    route.updateQueries(coordinator, queries: updated);
  }

  void _onSave() {
    coordinator.tryPop();
    coordinator.updateAppQueries(route.appId, route.queries);
  }

  @override
  Widget build(BuildContext context) {
    final appName = kApps.where((a) => a.id == route.appId).firstOrNull?.name ?? route.appId;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Material(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Store Language',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('$appName — Select the store language', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            route.selectorBuilder<String?>(
              selector: (q) => q['storeLanguage'],
              builder: (context, currentLang) {
                return Chip(
                  avatar: const Icon(Icons.check_circle, size: 18),
                  label: Text(_kLanguageLabels[currentLang] ?? currentLang ?? '—'),
                );
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: route.selectorBuilder<String?>(
                selector: (q) => q['storeLanguage'],
                builder: (context, currentLang) {
                  return ListView.separated(
                    itemCount: _kAvailableLanguages.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final lang = _kAvailableLanguages[i];
                      final selected = currentLang == lang;
                      return ListTile(
                        leading: Text(
                          lang.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                          ),
                        ),
                        title: Text(_kLanguageLabels[lang] ?? lang),
                        trailing: selected
                            ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                            : null,
                        selected: selected,
                        onTap: () => _selectLanguage(lang),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _onSave,
                icon: const Icon(Icons.check),
                label: const Text('Save'),
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => coordinator.tryPop(),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
