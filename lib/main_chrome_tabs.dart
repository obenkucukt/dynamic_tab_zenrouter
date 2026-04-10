import 'dart:async';
import 'dart:math';

import 'package:dynamic_tab_zenrouter/chrome_tabs.dart';
import 'package:dynamic_tab_zenrouter/tabs_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';
import 'package:meta_seo/meta_seo.dart';

part 'views/home_views.dart';
part 'views/about_views.dart';
part 'views/settings_views.dart';
part 'views/detail_views.dart';
part 'views/app_views.dart';

// ============================================================================
// SEO Mixin
// ============================================================================

mixin RouteSeo on RouteUnique {
  String get title;
  IconData? get icon => null;
  // String get description;
  // String get keywords;
  // // Optional meta tags with defaults
  // String get author => 'Dai Duong';
  // String? get ogImage => null; // URL to social media preview image
  // String get ogType => 'website';
  // TwitterCard? get twitterCard => TwitterCard.summaryLargeImage;
  // String? get twitterSite => null; // e.g., '@yourusername'
  // String? get canonicalUrl => null; // Canonical URL for this page
  // String get language => 'en';
  // String? get robots => null; // e.g., 'index, follow'

  final meta = MetaSEO();

  @override
  void onUpdate(covariant RouteTarget newRoute) {
    super.onUpdate(newRoute);
    buildSeo();
  }

  @override
  Widget build(covariant Coordinator<RouteUnique> coordinator, BuildContext context) {
    buildSeo();
    return const SizedBox.shrink();
  }

  void buildSeo() {
    // Add MetaSEO just into Web platform condition
    if (kIsWeb) {
      // Basic meta tags
      // meta.author(author: author);
      // meta.description(description: description);
      // meta.keywords(keywords: keywords);
      // Open Graph meta tags (for Facebook, LinkedIn, etc.)
      _setWebTitle(title);
      // meta.ogTitle(ogTitle: title);
      // meta.ogDescription(ogDescription: description);
      // if (ogImage != null) {
      //   meta.ogImage(ogImage: ogImage!);
      // }
      // // Twitter Card meta tags
      // if (twitterCard != null) {
      //   meta.twitterCard(twitterCard: twitterCard!);
      // }
      // meta.twitterTitle(twitterTitle: title);
      // meta.twitterDescription(twitterDescription: description);
      // if (ogImage != null) {
      //   meta.twitterImage(twitterImage: ogImage!);
      // }
      // if (twitterSite != null) {
      //   // Note: You may need to add this manually if MetaSEO doesn't support it
      //   // or use meta.config() for custom tags
      // }
      // // Additional SEO tags
      // if (robots != null) {
      //   // Use meta.config() for custom tags
      //   meta.robots(robotsName: RobotsName.robots, content: robots!);
      // }
    }
  }

  void _setWebTitle(String title) {
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(label: '$title — Chrome Tabs Demo', primaryColor: 0xFF2196F3),
    );
  }
}

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
  String get title => 'Chrome Tabs Demo';

  @override
  IconData? get icon => Icons.tab;

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

enum _ActivePanel { apps, nodes, tabs, logs }

class _ChromeTabLayoutBodyState extends State<_ChromeTabLayoutBody> {
  _ActivePanel _hoveredPanel = _ActivePanel.tabs;
  late final _appsSidebar = _AppsSidebar(coordinator: widget.coordinator);
  late final _nodesPanel = _NodesPanel(coordinator: widget.coordinator);
  late final _logsPanel = _LogsPanel(coordinator: widget.coordinator);

  @override
  void initState() {
    super.initState();
    widget.coordinator.tabsPath.addListener(_onTabsChanged);
    widget.coordinator.nodesOpen.addListener(_onNodesChanged);
    widget.coordinator.logsOpen.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    widget.coordinator.tabsPath.removeListener(_onTabsChanged);
    widget.coordinator.nodesOpen.removeListener(_onNodesChanged);
    widget.coordinator.logsOpen.removeListener(_onLogsChanged);
    super.dispose();
  }

  void _onTabsChanged() => setState(() {});
  void _onNodesChanged() => setState(() {});
  void _onLogsChanged() => setState(() {});

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
      case _ActivePanel.logs:
        _updateDisplayedUrl(Uri.parse('/logs'));
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

    final topRoute = innerPath.stack.last;
    if (topRoute is AppDetailLayout) {
      final drawerPath = widget.coordinator.appDrawerPath(topRoute.appId);
      _updateDisplayedUrl(drawerPath.activeRoute.identifier);
      return;
    }
    _updateDisplayedUrl(topRoute.identifier);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _activePanel;
    final borderColor = isDark ? const Color(0xFF3C3C3C) : const Color(0xFFE0E0E0);
    final nodesOpen = widget.coordinator.nodesOpen.value;
    final logsOpen = widget.coordinator.logsOpen.value;

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
            child: _appsSidebar,
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
                    child: _nodesPanel,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Column(
            children: [
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: logsOpen ? 200 : 0,
                child: logsOpen
                    ? MouseRegion(
                        onEnter: (_) => _onPanelEnter(_ActivePanel.logs),
                        onExit: (_) => _onPanelExit(),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            border: Border.all(color: borderFor(_ActivePanel.logs), width: widthFor(_ActivePanel.logs)),
                          ),
                          child: _logsPanel,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
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
  String get title => appName ?? _kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;

  @override
  IconData? get icon => _kApps.where((a) => a.id == appId).firstOrNull?.icon ?? Icons.apps;

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
  String get title => 'Chrome Tabs Demo';

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

class _AppBackButton extends StatelessWidget {
  const _AppBackButton({required this.coordinator});

  final AppCoordinator coordinator;

  List<AppRoute> _getBackStack() {
    final activeTab = coordinator.tabsPath.activeRoute;
    if (activeTab == null) return [];
    final innerPath = coordinator.tabsPath.tabPathFor(activeTab);
    if (innerPath.stack.length <= 1) return [];
    return innerPath.stack.sublist(0, innerPath.stack.length - 1).reversed.cast<AppRoute>().toList();
  }

  void _showBackStack(BuildContext context) {
    final stack = _getBackStack();
    if (stack.isEmpty) return;
    final box = context.findRenderObject() as RenderBox;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlay = Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<AppRoute>(
      context: context,
      color: isDark ? const Color(0xFF2D2D2D) : null,
      position: position,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
      items: stack.map((route) {
        return PopupMenuItem<AppRoute>(
          value: route,
          height: 40,
          child: Row(
            children: [
              Icon(route.icon, size: 16, color: isDark ? Colors.white70 : Colors.grey[700]),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  route.title,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(route.toUri().path, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        );
      }).toList(),
    ).then((route) {
      if (route != null) coordinator.navigate(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => coordinator.tryPop(),
      onLongPress: () => _showBackStack(context),
      customBorder: const CircleBorder(),
      child: const Tooltip(
        message: 'Back (long press for history)',
        child: SizedBox(width: 44, height: 44, child: Center(child: Icon(Icons.arrow_back, size: 20))),
      ),
    );
  }
}

class _InTabNavBar extends StatelessWidget {
  const _InTabNavBar({required this.title, required this.coordinator});

  final String title;
  final AppCoordinator coordinator;

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
          _AppBackButton(coordinator: coordinator),
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
    debugPrint('AppsSidebar build');
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
                onTap: () => widget.coordinator.navigate(AppShortDescRoute(appId: app.id)),
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
// Logs Panel
// ============================================================================

class _LogsPanel extends StatefulWidget {
  const _LogsPanel({required this.coordinator});

  final AppCoordinator coordinator;

  @override
  State<_LogsPanel> createState() => _LogsPanelState();
}

class _LogsPanelState extends State<_LogsPanel> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_onCoordinatorChanged);
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_onCoordinatorChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onCoordinatorChanged() {
    final activeTab = widget.coordinator.tabsPath.activeRoute;
    if (activeTab == null) return;
    final innerPath = widget.coordinator.tabsPath.tabPathFor(activeTab);
    if (innerPath.stack.isEmpty) return;
    final route = innerPath.stack.last;
    final entry = '[${DateTime.now().toIso8601String().substring(11, 19)}] ${route.toUri()}';
    setState(() {
      _logs.add(entry);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('LogsPanel build');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.terminal, size: 20, color: isDark ? Colors.white70 : Colors.grey[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Logs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _logs.clear()),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Tooltip(
                    message: 'Clear logs',
                    child: Icon(Icons.delete_sweep, size: 18, color: isDark ? Colors.white54 : Colors.grey[500]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => widget.coordinator.logsOpen.value = false,
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
          child: _logs.isEmpty
              ? Center(
                  child: Text(
                    'No logs yet',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey[400]),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(
                        _logs[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: isDark ? Colors.greenAccent[400] : Colors.green[800],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ============================================================================
// Coordinator
// ============================================================================

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

  final nodesOpen = ValueNotifier<bool>(false);
  final logsOpen = ValueNotifier<bool>(true);

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
        [
          AppShortDescRoute(appId: appId),
          AppLongDescRoute(appId: appId),
          AppSettingsRoute(appId: appId),
        ],
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
    ..bindLayout(ChromeTabLayout.new);

  // ---------------------------------------------------------------------------
  // Coordinator overrides
  // ---------------------------------------------------------------------------

  @override
  List<StackPath<RouteTarget>> get paths => [
    ...super.paths,
    tabsPath,
    _homeTabPath,
    _aboutTabPath,
    _settingsTabPath,
    ..._detailTabPaths.values,
    ..._appTabPaths.values,
    ..._appDrawerPaths.values,
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
      ['nodes'] => HomeTab(queries: q),
      _ => HomeTab(queries: q),
    };
  }

  @override
  List<AppRoute> get debugRoutes => [
    ...super.debugRoutes,
    HomeTab(),
    AboutTab(),
    SettingsTab(),
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
  }
}

// ============================================================================
// Main
// ============================================================================
