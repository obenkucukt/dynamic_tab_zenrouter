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
  // Dynamic per-app IndexedStackPaths (drawer: short-desc, long-desc, settings)
  // ---------------------------------------------------------------------------

  final Map<String, IndexedStackPath<AppRoute>> _appDrawerPaths = {};

  IndexedStackPath<AppRoute> appDrawerPath(String appId) {
    return _appDrawerPaths.putIfAbsent(appId, () {
      defineLayoutParent(() => AppDetailLayout(appId: appId));
      final p = IndexedStackPath<AppRoute>.createWith(
        [AppShortDescRoute(appId: appId), AppLongDescRoute(appId: appId), AppSettingsRoute(appId: appId)],
        coordinator: this,
        label: 'app-drawer-$appId',
      )..bindLayout(() => AppDetailLayout(appId: appId));
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
    ..._detailTabPaths.values,
    ..._appTabPaths.values,
    ..._appDrawerPaths.values,
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
      ['apps', final id] => AppShortDescRoute(appId: id, queries: q),
      ['apps', final id, 'short-desc'] => AppShortDescRoute(appId: id, queries: q),
      ['apps', final id, 'long-desc'] => AppLongDescRoute(appId: id, queries: q),
      ['apps', final id, 'settings'] => AppSettingsRoute(appId: id, queries: q),
      ['apps', final id, 'filter'] => AppFilterRoute(appId: id, queries: q),
      ['nodes'] => NodesRoute(queries: q),
      ['nodes', 'create'] => NodeCreateRoute(queries: q),
      ['logs'] => LogsRoute(queries: q),
      _ => HomeTab(queries: q),
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
    AppShortDescRoute(appId: 'notes'),
    AppShortDescRoute(appId: 'calendar'),
    AppShortDescRoute(appId: 'music'),
    AppShortDescRoute(appId: 'photos'),
    AppShortDescRoute(appId: 'maps'),
    AppLongDescRoute(appId: 'notes'),
    AppLongDescRoute(appId: 'calendar'),
    AppSettingsRoute(appId: 'notes'),
    AppSettingsRoute(appId: 'calendar'),
    AppFilterRoute(appId: 'notes'),
    AppFilterRoute(appId: 'calendar'),
    PostDetailRoute(postId: 1, postTitle: 'Post 1'),
    PostCommentRoute(postId: 1),
    TechDetailRoute(name: 'Flutter'),
    TechDetailRoute(name: 'ZenRouter'),
    SettingsSectionRoute(sectionId: 'theme', sectionTitle: 'Theme'),
    SettingsSectionRoute(sectionId: 'tabs', sectionTitle: 'Tab Behavior'),
  ];

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
        drawerPath.activeRoute.buildSeo();
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
