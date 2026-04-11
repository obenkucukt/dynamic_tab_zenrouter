// ============================================================================
// Coordinator
// ============================================================================

import 'dart:async';

import 'package:dynamic_tab_zenrouter/main_chrome_tabs.dart';
import 'package:dynamic_tab_zenrouter/panel_path.dart';
import 'package:dynamic_tab_zenrouter/tabs_path.dart';
import 'package:dynamic_tab_zenrouter/views/about_views.dart';
import 'package:dynamic_tab_zenrouter/views/app_detail_views.dart';
import 'package:dynamic_tab_zenrouter/views/apps_view.dart';
import 'package:dynamic_tab_zenrouter/views/detail_views.dart';
import 'package:dynamic_tab_zenrouter/views/home_views.dart';
import 'package:dynamic_tab_zenrouter/views/logs_view.dart';
import 'package:dynamic_tab_zenrouter/views/node_create_view.dart';
import 'package:dynamic_tab_zenrouter/views/nodes_view.dart';
import 'package:dynamic_tab_zenrouter/views/settings_views.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

class AppCoordinator extends Coordinator<AppRoute> with CoordinatorDebug<AppRoute> {
  AppCoordinator() {
    addListener(_updateWebTitle);
  }

  @override
  bool get debugEnabled => true;

  @override
  Future<void> navigate(AppRoute route) async {
    await super.navigate(route);
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  // ---------------------------------------------------------------------------
  // Panel path (manages all panels like TabsPath manages tabs)
  // ---------------------------------------------------------------------------

  late final panelPath = PanelPath<AppRoute>.createWith(
    coordinator: this,
    label: 'panels',
    stack: [AppsLayout(), TabsPanelLayout(), LogsLayout()],
  )..bindLayout(ChromeTabLayout.new);

  // ---------------------------------------------------------------------------
  // Panel inner NavigationPaths
  // ---------------------------------------------------------------------------

  late final _appsPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'apps-panel',
    stack: [AppsRoute()],
  )..bindLayout(AppsLayout.new);

  NavigationPath<AppRoute> get appsPath => _appsPath;

  late final _nodesPath = NavigationPath<AppRoute>.createWith(coordinator: this, label: 'nodes-panel', stack: [])
    ..bindLayout(NodesLayout.new);

  NavigationPath<AppRoute> get nodesPath => _nodesPath;

  late final _logsPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'logs-panel',
    stack: [LogsRoute()],
  )..bindLayout(LogsLayout.new);

  NavigationPath<AppRoute> get logsPath => _logsPath;

  // ---------------------------------------------------------------------------
  // Static per-tab NavigationPaths
  // ---------------------------------------------------------------------------

  late final _homeTabPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'home-tab',
    stack: [HomeTab()],
  )..bindLayout(HomeTabLayout.new);

  NavigationPath<AppRoute> get homeTabPath {
    if (_homeTabPath.stack.isEmpty) _homeTabPath.push(HomeTab());
    return _homeTabPath;
  }

  late final _aboutTabPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'about-tab',
    stack: [AboutTab()],
  )..bindLayout(AboutTabLayout.new);

  NavigationPath<AppRoute> get aboutTabPath {
    if (_aboutTabPath.stack.isEmpty) _aboutTabPath.push(AboutTab());
    return _aboutTabPath;
  }

  late final _settingsTabPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'settings-tab',
    stack: [SettingsTab()],
  )..bindLayout(SettingsTabLayout.new);

  NavigationPath<AppRoute> get settingsTabPath {
    if (_settingsTabPath.stack.isEmpty) _settingsTabPath.push(SettingsTab());
    return _settingsTabPath;
  }

  // ---------------------------------------------------------------------------
  // Not Found tab
  // ---------------------------------------------------------------------------

  late final _notFoundTabPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'not-found-tab',
    stack: [],
  )..bindLayout(NotFoundTabLayout.new);

  NavigationPath<AppRoute> get notFoundTabPath => _notFoundTabPath;

  // ---------------------------------------------------------------------------
  // Dynamic per-tab NavigationPaths  (one per unique detail-tab id)
  // ---------------------------------------------------------------------------

  final Map<int, NavigationPath<AppRoute>> _detailTabPaths = {};

  NavigationPath<AppRoute> detailTabPath(int id) {
    final path = _detailTabPaths.putIfAbsent(id, () {
      defineLayoutParent(() => DetailTabLayout(id: id));
      final p = NavigationPath<AppRoute>.createWith(
        coordinator: this,
        label: 'detail-$id',
        stack: [DetailTab(id: id)],
      );
      p.addListener(notifyListeners);
      return p;
    });
    if (path.stack.isEmpty) {
      path.push(DetailTab(id: id));
    }
    return path;
  }

  // ---------------------------------------------------------------------------
  // Dynamic per-app NavigationPaths  (one per unique app id)
  // ---------------------------------------------------------------------------

  final Map<String, NavigationPath<AppRoute>> _appTabPaths = {};

  NavigationPath<AppRoute> appTabPath(String appId) {
    final path = _appTabPaths.putIfAbsent(appId, () {
      defineLayoutParent(() => AppTabLayout(appId: appId));
      final p = NavigationPath<AppRoute>.createWith(
        coordinator: this,
        label: 'app-$appId',
        stack: [AppDetailLayout(appId: appId)],
      );
      p.addListener(notifyListeners);
      return p;
    });
    if (path.stack.isEmpty) {
      path.push(AppDetailLayout(appId: appId));
    }
    return path;
  }

  // ---------------------------------------------------------------------------
  // Dynamic per-app IndexedStackPaths (drawer: info, screenshots, versions)
  // ---------------------------------------------------------------------------

  final Map<String, IndexedStackPath<AppRoute>> _appDrawerPaths = {};

  IndexedStackPath<AppRoute> appDrawerPath(String appId) {
    return _appDrawerPaths.putIfAbsent(appId, () {
      defineLayoutParent(() => AppDetailLayout(appId: appId));
      final q = _appQueries(appId);
      final p = IndexedStackPath<AppRoute>.createWith(
        [
          AppInfoRoute(appId: appId, queries: q),
          AppsScreenshotsRoute(appId: appId, queries: q),
          AppVersionsRoute(appId: appId, queries: q),
        ],
        coordinator: this,
        label: 'app-drawer-$appId',
      )..bindLayout(() => AppDetailLayout(appId: appId));
      p.addListener(notifyListeners);
      return p;
    });
  }

  // ---------------------------------------------------------------------------
  // Dynamic per-app IndexedStackPaths (screenshots: subtypes per store)
  // ---------------------------------------------------------------------------

  final Map<String, IndexedStackPath<AppRoute>> _appScreenshotsPaths = {};

  IndexedStackPath<AppRoute> appScreenshotsPath(String appId) {
    return _appScreenshotsPaths.putIfAbsent(appId, () {
      defineLayoutParent(() => AppsScreenshotsRoute(appId: appId));
      final store = kApps.where((a) => a.id == appId).firstOrNull?.store ?? StoreOfApp.apple;
      final q = _appQueries(appId);
      final subTypes = store.screenshotSubTypes;
      final p = IndexedStackPath<AppRoute>.createWith(
        [for (final sub in subTypes) AppScreenshotSubTypeRoute(appId: appId, subType: sub, queries: q)],
        coordinator: this,
        label: 'app-screenshots-$appId',
      )..bindLayout(() => AppsScreenshotsRoute(appId: appId));
      p.addListener(notifyListeners);
      return p;
    });
  }

  // ---------------------------------------------------------------------------
  // Dynamic per-app IndexedStackPaths (versions: tracks per store)
  // ---------------------------------------------------------------------------

  final Map<String, IndexedStackPath<AppRoute>> _appVersionsPaths = {};

  IndexedStackPath<AppRoute> appVersionsPath(String appId) {
    return _appVersionsPaths.putIfAbsent(appId, () {
      defineLayoutParent(() => AppVersionsRoute(appId: appId));
      final store = kApps.where((a) => a.id == appId).firstOrNull?.store ?? StoreOfApp.apple;
      final q = _appQueries(appId);
      final tracks = store.versionTracks;
      final p = IndexedStackPath<AppRoute>.createWith(
        [for (final track in tracks) AppVersionTrackRoute(appId: appId, track: track, queries: q)],
        coordinator: this,
        label: 'app-versions-$appId',
      )..bindLayout(() => AppVersionsRoute(appId: appId));
      p.addListener(notifyListeners);
      return p;
    });
  }

  @override
  RouteLayoutParent? createLayoutParent(Object layoutKey) {
    if (layoutKey case (Type _, int id)) {
      detailTabPath(id);
    }
    if (layoutKey case (Type _, String appId)) {
      appTabPath(appId);
      appDrawerPath(appId);
      appScreenshotsPath(appId);
      appVersionsPath(appId);
    }
    return super.createLayoutParent(layoutKey);
  }

  // ---------------------------------------------------------------------------
  // Tab strip
  // ---------------------------------------------------------------------------

  late final tabsPath = TabsPath<TabRoute>.createWith(coordinator: this, label: 'tabs', stack: [HomeTabLayout()])
    ..bindLayout(TabsPanelLayout.new);

  // ---------------------------------------------------------------------------
  // Coordinator overrides
  // ---------------------------------------------------------------------------

  @override
  List<StackPath<RouteTarget>> get paths => [
    ...super.paths,
    panelPath,
    tabsPath,
    _homeTabPath,
    _aboutTabPath,
    _settingsTabPath,
    _notFoundTabPath,
    ..._detailTabPaths.values,
    ..._appTabPaths.values,
    ..._appDrawerPaths.values,
    ..._appScreenshotsPaths.values,
    ..._appVersionsPaths.values,
    _appsPath,
    _nodesPath,
    _logsPath,
  ];

  @override
  FutureOr<AppRoute> parseRouteFromUri(Uri uri) {
    final q = uri.queryParameters;

    return switch (uri.pathSegments) {
      [] => IndexRoute(queries: q),
      ['home'] => HomeTab(queries: q),
      ['home', 'post', final id] => PostDetailRoute(postId: int.tryParse(id) ?? 0, postTitle: 'Post $id', queries: q),
      ['home', 'post', final id, 'comments'] => PostCommentRoute(postId: int.tryParse(id) ?? 0, queries: q),
      ['detail', final id] => DetailTab(id: int.tryParse(id) ?? 0, queries: q),
      ['detail', final id, 'notes', final noteId] => DetailNoteRoute(
        tabId: int.tryParse(id) ?? 0,
        noteId: int.tryParse(noteId) ?? 0,
        queries: q,
      ),
      ['detail', final id, final section] => DetailSectionRoute(
        tabId: int.tryParse(id) ?? 0,
        section: section,
        queries: q,
      ),
      ['about'] => AboutTab(queries: q),
      ['about', 'tech', final name] => TechDetailRoute(name: name, queries: q),
      ['settings'] => SettingsTab(queries: q),
      ['settings', final section] => SettingsSectionRoute(sectionId: section, sectionTitle: section, queries: q),
      ['apps'] => HomeTab(queries: q),
      ['apps', final id] => AppInfoRoute(appId: id, queries: q),
      ['apps', final id, 'info'] => AppInfoRoute(appId: id, queries: q),
      ['apps', final id, 'screenshots'] => AppScreenshotSubTypeRoute(
        appId: id,
        subType: _defaultScreenshotSubType(id),
        queries: q,
      ),
      ['apps', final id, 'screenshots', final sub] =>
        _isValidScreenshotSubType(id, sub)
            ? AppScreenshotSubTypeRoute(appId: id, subType: sub, queries: q)
            : NotFoundRoute(requestedPath: uri.toString(), queries: q),
      ['apps', final id, 'versions'] => AppVersionTrackRoute(appId: id, track: _defaultTrack(id), queries: q),
      ['apps', final id, 'versions', final track] =>
        _isValidTrack(id, track)
            ? AppVersionTrackRoute(appId: id, track: track, queries: q)
            : NotFoundRoute(requestedPath: uri.toString(), queries: q),
      ['apps', final id, 'languages'] => AppLanguageRoute(appId: id, queries: q),
      ['nodes'] => NodesRoute(queries: q),
      ['nodes', 'create'] => NodeCreateRoute(queries: q),
      ['logs'] => LogsRoute(queries: q),
      ['not-found'] => NotFoundRoute(requestedPath: q['path'] ?? uri.toString(), queries: q),
      _ => NotFoundRoute(requestedPath: uri.toString(), queries: q),
    };
  }

  @override
  List<AppRoute> get debugRoutes => [
    ...super.debugRoutes,
    HomeTab(),
    AboutTab(),
    SettingsTab(),
    AppsRoute(),
    NodesRoute(),
    NodeCreateRoute(),
    LogsRoute(),
    DetailTab(id: 1),
    DetailSectionRoute(tabId: 1, section: 'stats'),
    DetailSectionRoute(tabId: 1, section: 'history'),
    DetailSectionRoute(tabId: 1, section: 'notes'),
    DetailNoteRoute(tabId: 1, noteId: 1),
    AppInfoRoute(appId: 'notes'),
    AppInfoRoute(appId: 'calendar'),
    AppInfoRoute(appId: 'music'),
    AppInfoRoute(appId: 'photos'),
    AppInfoRoute(appId: 'maps'),
    AppScreenshotSubTypeRoute(appId: 'notes', subType: 'iphone'),
    AppScreenshotSubTypeRoute(appId: 'notes', subType: 'ipad'),
    AppScreenshotSubTypeRoute(appId: 'calendar', subType: 'phone'),
    AppScreenshotSubTypeRoute(appId: 'calendar', subType: 'tablet7'),
    AppScreenshotSubTypeRoute(appId: 'calendar', subType: 'tablet10'),
    AppVersionTrackRoute(appId: 'notes', track: 'production'),
    AppVersionTrackRoute(appId: 'notes', track: 'internal'),
    AppVersionTrackRoute(appId: 'notes', track: 'external'),
    AppVersionTrackRoute(appId: 'calendar', track: 'production'),
    AppVersionTrackRoute(appId: 'calendar', track: 'beta'),
    AppVersionTrackRoute(appId: 'calendar', track: 'alpha'),
    AppVersionTrackRoute(appId: 'calendar', track: 'internal'),
    AppLanguageRoute(appId: 'notes'),
    AppLanguageRoute(appId: 'calendar'),
    PostDetailRoute(postId: 1, postTitle: 'Post 1'),
    PostCommentRoute(postId: 1),
    TechDetailRoute(name: 'Flutter'),
    TechDetailRoute(name: 'ZenRouter'),
    SettingsSectionRoute(sectionId: 'theme', sectionTitle: 'Theme'),
    SettingsSectionRoute(sectionId: 'tabs', sectionTitle: 'Tab Behavior'),
    NotFoundRoute(requestedPath: '/invalid-page'),
  ];

  Map<String, String> _appQueries(String appId) {
    final app = kApps.where((a) => a.id == appId).firstOrNull;
    return <String, String>{
      if (app != null) ...{'store': app.store.name, 'storeLanguage': app.storeLanguage},
    };
  }

  void updateAppQueries(String appId, Map<String, String> queries) {
    void applyToPath(IndexedStackPath<AppRoute> path) {
      for (final r in path.stack) {
        r.queryNotifier.value = queries;
      }
    }

    if (_appDrawerPaths.containsKey(appId)) applyToPath(appDrawerPath(appId));
    if (_appScreenshotsPaths.containsKey(appId)) applyToPath(appScreenshotsPath(appId));
    if (_appVersionsPaths.containsKey(appId)) applyToPath(appVersionsPath(appId));
    markNeedRebuild();
  }

  String _defaultScreenshotSubType(String appId) {
    final store = kApps.where((a) => a.id == appId).firstOrNull?.store ?? StoreOfApp.apple;
    return store.screenshotSubTypes.first;
  }

  bool _isValidScreenshotSubType(String appId, String subType) {
    final store = kApps.where((a) => a.id == appId).firstOrNull?.store;
    if (store == null) return false;
    return store.screenshotSubTypes.contains(subType);
  }

  String _defaultTrack(String appId) {
    final store = kApps.where((a) => a.id == appId).firstOrNull?.store ?? StoreOfApp.apple;
    return store.versionTracks.first;
  }

  bool _isValidTrack(String appId, String track) {
    final store = kApps.where((a) => a.id == appId).firstOrNull?.store;
    if (store == null) return false;
    return store.versionTracks.contains(track);
  }

  void _updateWebTitle() {
    final activePanel = panelPath.activeRoute;

    if (activePanel is TabsPanelLayout || activePanel == null) {
      final activeTab = tabsPath.activeRoute;
      if (activeTab == null) return;
      final innerPath = tabsPath.tabPathFor(activeTab);
      if (innerPath.stack.isEmpty) return;

      final topRoute = innerPath.stack.last;
      if (topRoute is AppDetailLayout) {
        final drawerPath = appDrawerPath(topRoute.appId);
        final activeDrawerRoute = drawerPath.activeRoute;
        if (activeDrawerRoute is AppsScreenshotsRoute) {
          final screenshotsPath = appScreenshotsPath(activeDrawerRoute.appId);
          screenshotsPath.activeRoute.buildSeo();
          return;
        }
        if (activeDrawerRoute is AppVersionsRoute) {
          final versionsPath = appVersionsPath(activeDrawerRoute.appId);
          versionsPath.activeRoute.buildSeo();
          return;
        }
        activeDrawerRoute.buildSeo();
        return;
      }
      (topRoute as AppRoute).buildSeo();
      return;
    }

    if (activePanel is RouteLayoutParent) {
      final innerPath = (activePanel as RouteLayoutParent).resolvePath(this);
      if (innerPath.stack.isNotEmpty) {
        (innerPath.stack.last as AppRoute).buildSeo();
        return;
      }
    }

    activePanel.buildSeo();
  }
}
