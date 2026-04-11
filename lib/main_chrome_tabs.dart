import 'dart:async';
import 'dart:math';

import 'package:dynamic_tab_zenrouter/app_coordinator.dart';
import 'package:dynamic_tab_zenrouter/chrome_tabs.dart';
import 'package:dynamic_tab_zenrouter/panel_path.dart';
import 'package:dynamic_tab_zenrouter/route_seo.dart';
import 'package:dynamic_tab_zenrouter/tabs_path.dart';
import 'package:dynamic_tab_zenrouter/views/apps_view.dart';
import 'package:dynamic_tab_zenrouter/views/detail_views.dart';
import 'package:dynamic_tab_zenrouter/views/home_views.dart';
import 'package:flutter/material.dart';

import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Base Route Types
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique, RouteQueryParameters, RouteSeo {
  AppRoute({Map<String, String> queries = const {}}) : queryNotifier = ValueNotifier(queries);

  @override
  final ValueNotifier<Map<String, String>> queryNotifier;

  @override
  Uri get identifier {
    final uri = toUri();
    if (queries.isEmpty) return uri;
    return uri.replace(queryParameters: queries);
  }
}

abstract class TabRoute extends AppRoute with RouteTab {
  TabRoute({super.queries});
}

/// A tab that also acts as a [RouteLayout], managing its own inner
/// [NavigationPath].  Sub-routes whose [parentLayoutKey] matches this layout's
/// [layoutKey] are automatically pushed onto the correct per-tab path, keeping
/// the browser URL and deep-linking in sync.
abstract class TabLayoutRoute extends TabRoute with RouteLayout<AppRoute> {
  TabLayoutRoute({super.queries});

  @override
  Type get layout => TabsPanelLayout;
}

class TabsPanelLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  String get title => 'Tabs';

  @override
  Type get layout => ChromeTabLayout;

  @override
  TabsPath<TabRoute> resolvePath(AppCoordinator coordinator) => coordinator.tabsPath;

  @override
  Widget buildPath(covariant AppCoordinator coordinator) {
    return ChromeTabs<TabRoute>(
      coordinator: coordinator,
      path: coordinator.tabsPath,
      onNewTab: () {
        final random = Random().nextInt(100);
        coordinator.navigate(DetailTab(id: random));
      },
    );
  }
}

// ============================================================================
// App Data
// ============================================================================

// ============================================================================
// Chrome Tab Layout (top-level shell)
// ============================================================================

class ChromeTabLayout extends AppRoute with RouteLayout<AppRoute> {
  ChromeTabLayout({super.queries});

  @override
  String get title => 'Chrome Tabs Demo';

  @override
  IconData? get icon => Icons.tab;

  @override
  PanelPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.panelPath;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return _ChromeTabLayoutBody(coordinator: coordinator);
  }
}

class _ChromeTabLayoutBody extends StatefulWidget {
  const _ChromeTabLayoutBody({required this.coordinator});

  final AppCoordinator coordinator;

  @override
  State<_ChromeTabLayoutBody> createState() => _ChromeTabLayoutBodyState();
}

enum _ActivePanel { apps, nodes, tabs, logs }

class _ChromeTabLayoutBodyState extends State<_ChromeTabLayoutBody> {
  _ActivePanel _hoveredPanel = _ActivePanel.tabs;

  @override
  void initState() {
    super.initState();
    widget.coordinator.panelPath.addListener(_onPathChanged);
    widget.coordinator.tabsPath.addListener(_onPathChanged);
    widget.coordinator.nodesPath.addListener(_onPathChanged);
    widget.coordinator.logsPath.addListener(_onPathChanged);
    widget.coordinator.appsPath.addListener(_onPathChanged);
  }

  @override
  void dispose() {
    widget.coordinator.panelPath.removeListener(_onPathChanged);
    widget.coordinator.tabsPath.removeListener(_onPathChanged);
    widget.coordinator.nodesPath.removeListener(_onPathChanged);
    widget.coordinator.logsPath.removeListener(_onPathChanged);
    widget.coordinator.appsPath.removeListener(_onPathChanged);
    super.dispose();
  }

  void _onPathChanged() => setState(() {});

  _ActivePanel get _activePanel {
    if (_hoveredPanel != _ActivePanel.tabs) return _hoveredPanel;
    if (widget.coordinator.tabsPath.activeRoute is AppTabLayout) return _ActivePanel.apps;
    return _ActivePanel.tabs;
  }

  void _onPanelEnter(_ActivePanel panel) {
    if (_hoveredPanel == panel) return;
    _hoveredPanel = panel;
    setState(() {});
  }

  void _onPanelExit() {
    if (_hoveredPanel == _ActivePanel.tabs) return;
    _hoveredPanel = _ActivePanel.tabs;
    setState(() {});
  }

  void _onPanelTap(_ActivePanel panel) {
    final layout = switch (panel) {
      .apps => AppsLayout(),
      .nodes => NodesLayout(),
      .tabs => TabsPanelLayout(),
      .logs => LogsLayout(),
    };
    widget.coordinator.panelPath.focusPanel(layout);
  }

  Widget _buildPanelContent(RouteLayout<AppRoute> layout) => layout.buildPath(widget.coordinator);

  @override
  Widget build(BuildContext context) {
    final active = _activePanel;
    final borderColor = const Color(0xFFE0E0E0);
    final nodesOpen = widget.coordinator.panelPath.isPanelOpen(NodesLayout());
    final logsOpen = widget.coordinator.panelPath.isPanelOpen(LogsLayout());

    Color? appBarColor;
    Color? appBarForeground;
    final activeTab = widget.coordinator.tabsPath.activeRoute;
    if (activeTab is AppTabLayout) {
      final appData = kApps.where((a) => a.id == activeTab.appId).firstOrNull;
      if (appData != null) {
        appBarColor = appData.color;
        appBarForeground = appData.color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
      }
    }

    Color borderFor(_ActivePanel panel) => active == panel ? Colors.blue : borderColor;
    double widthFor(_ActivePanel panel) => 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chrome Tabs Demo'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: appBarColor,
        foregroundColor: appBarForeground,
      ),
      body: Row(
        spacing: 2,
        children: [
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () => _onPanelTap(_ActivePanel.apps),
            child: MouseRegion(
              onEnter: (_) => _onPanelEnter(_ActivePanel.apps),
              onExit: (_) => _onPanelExit(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(2),
                margin: const EdgeInsets.all(2),

                child: Material(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    side: BorderSide(color: borderFor(_ActivePanel.apps), width: widthFor(_ActivePanel.apps)),
                  ),
                  color: Colors.white,
                  animateColor: true,
                  clipBehavior: Clip.hardEdge,
                  child: _buildPanelContent(AppsLayout()),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: nodesOpen ? 220 : 0,
            child: nodesOpen
                ? GestureDetector(
                    onTap: () => _onPanelTap(_ActivePanel.nodes),
                    child: MouseRegion(
                      onEnter: (_) => _onPanelEnter(_ActivePanel.nodes),
                      onExit: (_) => _onPanelExit(),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        margin: const EdgeInsets.all(2),
                        child: Material(
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            side: BorderSide(color: borderFor(_ActivePanel.nodes), width: widthFor(_ActivePanel.nodes)),
                          ),
                          color: Colors.white,
                          animateColor: true,
                          child: _buildPanelContent(NodesLayout()),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onPanelTap(_ActivePanel.tabs),
                    child: MouseRegion(
                      onEnter: (_) => _onPanelEnter(_ActivePanel.tabs),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(2),
                        margin: const EdgeInsets.all(2),
                        child: Material(
                          clipBehavior: Clip.hardEdge,
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            side: BorderSide(color: borderFor(_ActivePanel.tabs), width: widthFor(_ActivePanel.tabs)),
                          ),
                          color: Colors.white,
                          animateColor: true,
                          child: _buildPanelContent(TabsPanelLayout()),
                        ),
                      ),
                    ),
                  ),
                ),
                if (logsOpen)
                  GestureDetector(
                    onTap: () => _onPanelTap(_ActivePanel.logs),
                    child: MouseRegion(
                      onEnter: (_) => _onPanelEnter(_ActivePanel.logs),
                      onExit: (_) => _onPanelExit(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(2),
                        margin: const EdgeInsets.all(2),

                        child: Material(
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            side: BorderSide(color: borderFor(_ActivePanel.logs), width: widthFor(_ActivePanel.logs)),
                          ),
                          color: Colors.white,
                          animateColor: true,
                          clipBehavior: Clip.hardEdge,
                          child: _buildPanelContent(LogsLayout()),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

// ============================================================================
// Static Per-Tab Layouts
// ============================================================================

class HomeTabLayout extends TabLayoutRoute {
  @override
  String get title => 'Home';

  @override
  IconData? get icon => Icons.home;

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.homeTabPath;

  @override
  Widget tabLabel(AppCoordinator coordinator, TabsPath path, BuildContext context, bool active) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.home, size: 16),
        const SizedBox(width: 8),
        Text('Home', style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}

class AboutTabLayout extends TabLayoutRoute {
  @override
  String get title => 'About';

  @override
  IconData? get icon => Icons.info;

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.aboutTabPath;

  @override
  Widget tabLabel(AppCoordinator coordinator, TabsPath path, BuildContext context, bool active) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info, size: 16),
        const SizedBox(width: 8),
        Text('About', style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}

class SettingsTabLayout extends TabLayoutRoute {
  @override
  String get title => 'Settings';

  @override
  IconData? get icon => Icons.settings;

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.settingsTabPath;

  @override
  Widget tabLabel(AppCoordinator coordinator, TabsPath path, BuildContext context, bool active) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.settings, size: 16),
        const SizedBox(width: 8),
        Text('Settings', style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}

// ============================================================================
// Dynamic Per-Tab Layout  (one instance per unique detail-tab id)
// ============================================================================

class DetailTabLayout extends TabLayoutRoute {
  DetailTabLayout({required this.id, this.tabTitle, super.queries});

  final int id;
  final String? tabTitle;

  @override
  String get title => tabTitle ?? 'Tab $id';

  @override
  IconData? get icon => Icons.tab;

  @override
  List<Object?> get props => [id];

  @override
  Object get layoutKey => (DetailTabLayout, id);

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.detailTabPath(id);

  @override
  Widget tabLabel(AppCoordinator coordinator, TabsPath path, BuildContext context, bool active) {
    return Text(
      tabTitle ?? 'Tab $id',
      style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ============================================================================
// Dynamic Per-App Tab Layout  (one instance per unique app id)
// ============================================================================

class AppTabLayout extends TabLayoutRoute {
  AppTabLayout({required this.appId, this.appName, super.queries});

  final String appId;
  final String? appName;

  @override
  String get title => appName ?? kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;

  @override
  IconData? get icon => kApps.where((a) => a.id == appId).firstOrNull?.icon ?? Icons.apps;

  @override
  List<Object?> get props => [appId];

  @override
  Object get layoutKey => (AppTabLayout, appId);

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.appTabPath(appId);

  @override
  Widget tabLabel(AppCoordinator coordinator, TabsPath path, BuildContext context, bool active) {
    final name = appName ?? kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;
    final icon = kApps.where((a) => a.id == appId).firstOrNull?.icon ?? Icons.apps;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),
        Text(
          name,
          style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ============================================================================
// Not Found Tab
// ============================================================================

class NotFoundTabLayout extends TabLayoutRoute {
  @override
  String get title => 'Not Found';

  @override
  IconData? get icon => Icons.error_outline;

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.notFoundTabPath;

  @override
  Widget tabLabel(AppCoordinator coordinator, TabsPath path, BuildContext context, bool active) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 16, color: active ? Colors.red : null),
        const SizedBox(width: 8),
        Text('Not Found', style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}

class NotFoundRoute extends AppRoute {
  NotFoundRoute({required this.requestedPath, super.queries});

  final String requestedPath;

  @override
  String get title => 'Not Found';

  @override
  IconData? get icon => Icons.error_outline;

  @override
  List<Object?> get props => [requestedPath];

  @override
  Object? get parentLayoutKey => NotFoundTabLayout;

  @override
  Uri toUri() => Uri.parse('/not-found');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 24),
            Text(
              '404',
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.red[400]),
            ),
            const SizedBox(height: 12),
            Text('Page Not Found', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SelectableText(
                  requestedPath,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.grey[700]),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => coordinator.navigate(HomeTab()),
              icon: const Icon(Icons.home),
              label: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class IndexRoute extends AppRoute with RouteRedirect {
  IndexRoute({super.queries});

  @override
  String get title => 'Chrome Tabs Demo';

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => const SizedBox.shrink();

  @override
  Uri toUri() => Uri.parse('/');

  @override
  FutureOr<RouteTarget> redirect() => HomeTab();
}

class AppsLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  String get title => 'Apps';

  @override
  Type get layout => ChromeTabLayout;

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.appsPath;
}

class NodesLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  String get title => 'Nodes';

  @override
  Type get layout => ChromeTabLayout;

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.nodesPath;
}

class LogsLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  String get title => 'Logs';

  @override
  Type get layout => ChromeTabLayout;

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.logsPath;
}
