import 'dart:async';
import 'dart:math';

import 'package:dynamic_tab_zenrouter/chrome_tabs.dart';
import 'package:dynamic_tab_zenrouter/tabs_path.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

part 'views/home_views.dart';
part 'views/about_views.dart';
part 'views/settings_views.dart';
part 'views/detail_views.dart';
part 'views/app_views.dart';

// ============================================================================
// Base Route Types
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique, RouteQueryParameters {
  AppRoute({Map<String, String> queries = const {}})
    : queryNotifier = ValueNotifier(queries);

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
  Type get layout => ChromeTabLayout;
}

// ============================================================================
// App Data
// ============================================================================

const _kApps = [
  (id: 'notes', name: 'Notes', icon: Icons.note),
  (id: 'calendar', name: 'Calendar', icon: Icons.calendar_today),
  (id: 'music', name: 'Music', icon: Icons.music_note),
  (id: 'photos', name: 'Photos', icon: Icons.photo),
  (id: 'maps', name: 'Maps', icon: Icons.map),
];

// ============================================================================
// Chrome Tab Layout (top-level shell)
// ============================================================================

class ChromeTabLayout extends AppRoute with RouteLayout<AppRoute> {
  ChromeTabLayout({super.queries});

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

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chrome Tabs Demo'), centerTitle: false, elevation: 0),
      body: _ChromeTabLayoutBody(coordinator: coordinator, tabsContent: buildPath(coordinator)),
    );
  }
}

class _ChromeTabLayoutBody extends StatefulWidget {
  const _ChromeTabLayoutBody({required this.coordinator, required this.tabsContent});

  final AppCoordinator coordinator;
  final Widget tabsContent;

  @override
  State<_ChromeTabLayoutBody> createState() => _ChromeTabLayoutBodyState();
}

enum _ActivePanel { apps, nodes, tabs }

class _ChromeTabLayoutBodyState extends State<_ChromeTabLayoutBody> {
  _ActivePanel _hoveredPanel = _ActivePanel.tabs;

  @override
  void initState() {
    super.initState();
    widget.coordinator.tabsPath.addListener(_onTabsChanged);
    widget.coordinator.nodesOpen.addListener(_onNodesChanged);
  }

  @override
  void dispose() {
    widget.coordinator.tabsPath.removeListener(_onTabsChanged);
    widget.coordinator.nodesOpen.removeListener(_onNodesChanged);
    super.dispose();
  }

  void _onTabsChanged() => setState(() {});
  void _onNodesChanged() => setState(() {});

  _ActivePanel get _activePanel {
    if (_hoveredPanel != _ActivePanel.tabs) return _hoveredPanel;
    if (widget.coordinator.tabsPath.activeRoute is AppTabLayout) return _ActivePanel.apps;
    return _ActivePanel.tabs;
  }

  void _updateDisplayedUrl(Uri uri) {
    if (!mounted) return;
    Router.of(context).routeInformationProvider?.routerReportsNewRouteInformation(
      RouteInformation(uri: uri),
      type: RouteInformationReportingType.neglect,
    );
  }

  void _onPanelEnter(_ActivePanel panel) {
    _hoveredPanel = panel;
    setState(() {});
    switch (panel) {
      case _ActivePanel.apps:
        _updateDisplayedUrl(Uri.parse('/apps'));
      case _ActivePanel.nodes:
        _updateDisplayedUrl(Uri.parse('/nodes'));
      case _ActivePanel.tabs:
        _restoreTabUrl();
    }
  }

  void _onPanelExit() {
    _hoveredPanel = _ActivePanel.tabs;
    setState(() {});
  }

  void _restoreTabUrl() {
    final tabPath = widget.coordinator.tabsPath;
    final activeTab = tabPath.activeRoute;
    if (activeTab == null) return;
    final innerPath = tabPath.tabPathFor(activeTab);
    if (innerPath.stack.isEmpty) return;
    _updateDisplayedUrl(innerPath.stack.last.identifier);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _activePanel;
    final borderColor = isDark ? const Color(0xFF3C3C3C) : const Color(0xFFE0E0E0);
    final nodesOpen = widget.coordinator.nodesOpen.value;

    Color borderFor(_ActivePanel panel) => active == panel ? Colors.blue : borderColor;
    double widthFor(_ActivePanel panel) => active == panel ? 2.5 : 1;

    return Row(
      spacing: 2,
      children: [
        const SizedBox(width: 2),
        MouseRegion(
          onEnter: (_) => _onPanelEnter(_ActivePanel.apps),
          onExit: (_) => _onPanelExit(),
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(2),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border.all(color: borderFor(_ActivePanel.apps), width: widthFor(_ActivePanel.apps)),
            ),
            child: _AppsSidebar(coordinator: widget.coordinator),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: nodesOpen ? 220 : 0,
          child: nodesOpen
              ? MouseRegion(
                  onEnter: (_) => _onPanelEnter(_ActivePanel.nodes),
                  onExit: (_) => _onPanelExit(),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      border: Border.all(color: borderFor(_ActivePanel.nodes), width: widthFor(_ActivePanel.nodes)),
                    ),
                    child: _NodesPanel(coordinator: widget.coordinator),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: MouseRegion(
            onEnter: (_) => _onPanelEnter(_ActivePanel.tabs),
            child: Container(
              padding: const EdgeInsets.all(2),
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: borderFor(_ActivePanel.tabs), width: widthFor(_ActivePanel.tabs)),
              ),
              child: widget.tabsContent,
            ),
          ),
        ),
        const SizedBox(width: 2),
      ],
    );
  }
}

// ============================================================================
// Static Per-Tab Layouts
// ============================================================================

class HomeTabLayout extends TabLayoutRoute {
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
  DetailTabLayout({required this.id, this.title, super.queries});

  final int id;
  final String? title;

  @override
  List<Object?> get props => [id];

  @override
  Object get layoutKey => (DetailTabLayout, id);

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.detailTabPath(id);

  @override
  Widget tabLabel(AppCoordinator coordinator, TabsPath path, BuildContext context, bool active) {
    return Text(
      title ?? 'Tab $id',
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
  List<Object?> get props => [appId];

  @override
  Object get layoutKey => (AppTabLayout, appId);

  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) => coordinator.appTabPath(appId);

  @override
  Widget tabLabel(AppCoordinator coordinator, TabsPath path, BuildContext context, bool active) {
    final name = appName ?? _kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;
    final icon = _kApps.where((a) => a.id == appId).firstOrNull?.icon ?? Icons.apps;
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

class IndexRoute extends AppRoute with RouteRedirect {
  IndexRoute({super.queries});

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => const SizedBox.shrink();

  @override
  Uri toUri() => Uri.parse('/');

  @override
  FutureOr<RouteTarget> redirect() => HomeTab();
}

// ============================================================================
// Shared Widgets
// ============================================================================

class _InTabNavBar extends StatelessWidget {
  const _InTabNavBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFE0E0E0))),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, size: 20), onPressed: onBack, tooltip: 'Back'),
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ============================================================================
// Apps Sidebar
// ============================================================================

class _AppsSidebar extends StatefulWidget {
  const _AppsSidebar({required this.coordinator});

  final AppCoordinator coordinator;

  @override
  State<_AppsSidebar> createState() => _AppsSidebarState();
}

class _AppsSidebarState extends State<_AppsSidebar> {
  @override
  void initState() {
    super.initState();
    widget.coordinator.tabsPath.addListener(_onTabsChanged);
  }

  @override
  void dispose() {
    widget.coordinator.tabsPath.removeListener(_onTabsChanged);
    super.dispose();
  }

  void _onTabsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeTab = widget.coordinator.tabsPath.activeRoute;
    String? activeAppId;
    if (activeTab is AppTabLayout) {
      activeAppId = activeTab.appId;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.apps, size: 20, color: isDark ? Colors.white70 : Colors.grey[700]),
              const SizedBox(width: 8),
              Text('Apps', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Divider(height: 1, color: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFE0E0E0)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: _kApps.map((app) {
              return _AppSidebarItem(
                appId: app.id,
                appName: app.name,
                icon: app.icon,
                isActive: app.id == activeAppId,
                isDark: isDark,
                onTap: () => widget.coordinator.navigate(AppDetailTab(appId: app.id)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _AppSidebarItem extends StatefulWidget {
  const _AppSidebarItem({
    required this.appId,
    required this.appName,
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  final String appId;
  final String appName;
  final IconData icon;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_AppSidebarItem> createState() => _AppSidebarItemState();
}

class _AppSidebarItemState extends State<_AppSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isDark ? Colors.blue[700]! : Colors.blue[50]!;
    final hoverColor = widget.isDark ? const Color(0xFF3C3C3C) : const Color(0xFFF0F0F0);
    final bgColor = widget.isActive
        ? activeColor
        : _isHovered
        ? hoverColor
        : Colors.transparent;
    final textColor = widget.isActive
        ? (widget.isDark ? Colors.blue[200]! : Colors.blue[800]!)
        : (widget.isDark ? Colors.white : Colors.black87);
    final iconColor = widget.isActive
        ? (widget.isDark ? Colors.blue[200]! : Colors.blue[700]!)
        : (widget.isDark ? Colors.white70 : Colors.grey[600]!);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: widget.isActive ? Border.all(color: Colors.blue, width: 1.5) : null,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.appName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.normal,
                    color: textColor,
                  ),
                ),
              ),
              if (widget.isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Nodes Panel
// ============================================================================

const _kNodes = [
  (id: 'node-1', label: 'Input Node', icon: Icons.input),
  (id: 'node-2', label: 'Transform Node', icon: Icons.transform),
  (id: 'node-3', label: 'Filter Node', icon: Icons.filter_alt),
  (id: 'node-4', label: 'Output Node', icon: Icons.output),
  (id: 'node-5', label: 'Merge Node', icon: Icons.merge_type),
  (id: 'node-6', label: 'Split Node', icon: Icons.call_split),
];

class _NodesPanel extends StatelessWidget {
  const _NodesPanel({required this.coordinator});

  final AppCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    debugPrint('NodesPanel build');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.account_tree, size: 20, color: isDark ? Colors.white70 : Colors.grey[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nodes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: () => coordinator.nodesOpen.value = false,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(Icons.close, size: 18, color: isDark ? Colors.white54 : Colors.grey[500]),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFE0E0E0)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: _kNodes.map((node) {
              return _NodeItem(nodeId: node.id, label: node.label, icon: node.icon, isDark: isDark);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _NodeItem extends StatefulWidget {
  const _NodeItem({required this.nodeId, required this.label, required this.icon, required this.isDark});

  final String nodeId;
  final String label;
  final IconData icon;
  final bool isDark;

  @override
  State<_NodeItem> createState() => _NodeItemState();
}

class _NodeItemState extends State<_NodeItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = widget.isDark ? const Color(0xFF3C3C3C) : const Color(0xFFF0F0F0);
    final bgColor = _isHovered ? hoverColor : Colors.transparent;
    final iconColor = widget.isDark ? Colors.white70 : Colors.grey[600]!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(widget.icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(fontSize: 14, color: widget.isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Coordinator
// ============================================================================

class AppCoordinator extends Coordinator<AppRoute> with CoordinatorDebug<AppRoute> {
  AppCoordinator();

  @override
  bool get debugEnabled => true;

  final nodesOpen = ValueNotifier<bool>(false);

  // ---------------------------------------------------------------------------
  // Static per-tab NavigationPaths
  // ---------------------------------------------------------------------------

  late final homeTabPath = NavigationPath<AppRoute>.createWith(coordinator: this, label: 'home-tab', stack: [HomeTab()])
    ..bindLayout(HomeTabLayout.new);

  late final aboutTabPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'about-tab',
    stack: [AboutTab()],
  )..bindLayout(AboutTabLayout.new);

  late final settingsTabPath = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'settings-tab',
    stack: [SettingsTab()],
  )..bindLayout(SettingsTabLayout.new);

  // ---------------------------------------------------------------------------
  // Dynamic per-tab NavigationPaths  (one per unique detail-tab id)
  // ---------------------------------------------------------------------------

  final Map<int, NavigationPath<AppRoute>> _detailTabPaths = {};

  NavigationPath<AppRoute> detailTabPath(int id) {
    return _detailTabPaths.putIfAbsent(id, () {
      defineLayoutParent(() => DetailTabLayout(id: id));
      final path = NavigationPath<AppRoute>.createWith(
        coordinator: this,
        label: 'detail-$id',
        stack: [DetailTab(id: id)],
      );
      path.addListener(notifyListeners);
      return path;
    });
  }

  // ---------------------------------------------------------------------------
  // Dynamic per-app NavigationPaths  (one per unique app id)
  // ---------------------------------------------------------------------------

  final Map<String, NavigationPath<AppRoute>> _appTabPaths = {};

  NavigationPath<AppRoute> appTabPath(String appId) {
    return _appTabPaths.putIfAbsent(appId, () {
      defineLayoutParent(() => AppTabLayout(appId: appId));
      final path = NavigationPath<AppRoute>.createWith(
        coordinator: this,
        label: 'app-$appId',
        stack: [AppDetailTab(appId: appId)],
      );
      path.addListener(notifyListeners);
      return path;
    });
  }

  @override
  RouteLayoutParent? createLayoutParent(Object layoutKey) {
    if (layoutKey case (Type _, int id)) {
      detailTabPath(id);
    }
    if (layoutKey case (Type _, String appId)) {
      appTabPath(appId);
    }
    return super.createLayoutParent(layoutKey);
  }

  // ---------------------------------------------------------------------------
  // Tab strip
  // ---------------------------------------------------------------------------

  late final tabsPath = TabsPath<TabRoute>.createWith(coordinator: this, label: 'tabs', stack: [HomeTabLayout()])
    ..bindLayout(ChromeTabLayout.new);

  // ---------------------------------------------------------------------------
  // Coordinator overrides
  // ---------------------------------------------------------------------------

  @override
  List<StackPath<RouteTarget>> get paths => [
    ...super.paths,
    tabsPath,
    homeTabPath,
    aboutTabPath,
    settingsTabPath,
    ..._detailTabPaths.values,
    ..._appTabPaths.values,
  ];

  @override
  FutureOr<AppRoute> parseRouteFromUri(Uri uri) {
    if (uri.pathSegments case ['nodes']) {
      nodesOpen.value = true;
    }

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
      ['detail', final id, final section] => DetailSectionRoute(tabId: int.tryParse(id) ?? 0, section: section, queries: q),
      ['about'] => AboutTab(queries: q),
      ['about', 'tech', final name] => TechDetailRoute(name: name, queries: q),
      ['settings'] => SettingsTab(queries: q),
      ['settings', final section] => SettingsSectionRoute(sectionId: section, sectionTitle: section, queries: q),
      ['apps'] => HomeTab(queries: q),
      ['apps', final id] => AppDetailTab(appId: id, queries: q),
      ['apps', final id, 'filter'] => AppFilterRoute(appId: id, queries: q),
      ['apps', final id, 'description', final type] => AppDescriptionRoute(appId: id, type: type, queries: q),
      ['apps', final id, 'settings'] => AppSettingsRoute(appId: id, queries: q),
      ['nodes'] => HomeTab(queries: q),
      _ => HomeTab(queries: q),
    };
  }
}

// ============================================================================
// Main
// ============================================================================
