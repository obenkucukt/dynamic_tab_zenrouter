import 'dart:async';
import 'dart:math';

import 'package:dynamic_tab_zenrouter/chrome_tabs.dart';
import 'package:dynamic_tab_zenrouter/panel_path.dart';
import 'package:dynamic_tab_zenrouter/route_seo.dart';
import 'package:dynamic_tab_zenrouter/tabs_path.dart';
import 'package:dynamic_tab_zenrouter/views/apps_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
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

const kApps = [
  (id: 'notes', name: 'Notes', subtitle: 'Quick notes & memos', icon: Icons.note, color: Color(0xFFFFA726)),
  (
    id: 'calendar',
    name: 'Calendar',
    subtitle: 'Events & schedules',
    icon: Icons.calendar_today,
    color: Color(0xFFEF5350),
  ),
  (id: 'music', name: 'Music', subtitle: 'Songs & playlists', icon: Icons.music_note, color: Color(0xFFAB47BC)),
  (id: 'photos', name: 'Photos', subtitle: 'Albums & memories', icon: Icons.photo, color: Color(0xFF66BB6A)),
  (id: 'maps', name: 'Maps', subtitle: 'Navigation & places', icon: Icons.map, color: Color(0xFF26A69A)),
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
      _ActivePanel.apps => AppsLayout(),
      _ActivePanel.nodes => NodesLayout(),
      _ActivePanel.tabs => TabsPanelLayout(),
      _ActivePanel.logs => LogsLayout(),
    };
    widget.coordinator.panelPath.focusPanel(layout);
  }

  Widget _buildPanelContent(RouteLayout<AppRoute> layout) {
    return layout.buildPath(widget.coordinator);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _activePanel;
    final borderColor = isDark ? const Color(0xFF3C3C3C) : const Color(0xFFE0E0E0);
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
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    side: BorderSide(color: borderFor(_ActivePanel.apps), width: widthFor(_ActivePanel.apps)),
                  ),
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                ),
                child: _buildPanelContent(AppsLayout()),
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(2),
                        margin: const EdgeInsets.all(2),
                        decoration: ShapeDecoration(
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            side: BorderSide(color: borderFor(_ActivePanel.nodes), width: widthFor(_ActivePanel.nodes)),
                          ),
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        ),
                        child: _buildPanelContent(NodesLayout()),
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
                        decoration: ShapeDecoration(
                          shape: RoundedSuperellipseBorder(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            side: BorderSide(color: borderFor(_ActivePanel.tabs), width: widthFor(_ActivePanel.tabs)),
                          ),
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        ),
                        child: _buildPanelContent(TabsPanelLayout()),
                      ),
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: logsOpen ? 200 : 0,
                  child: logsOpen
                      ? GestureDetector(
                          onTap: () => _onPanelTap(_ActivePanel.logs),
                          child: MouseRegion(
                            onEnter: (_) => _onPanelEnter(_ActivePanel.logs),
                            onExit: (_) => _onPanelExit(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.all(2),
                              margin: const EdgeInsets.all(2),
                              decoration: ShapeDecoration(
                                shape: RoundedSuperellipseBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(16)),
                                  side: BorderSide(
                                    color: borderFor(_ActivePanel.logs),
                                    width: widthFor(_ActivePanel.logs),
                                  ),
                                ),
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              ),
                              child: _buildPanelContent(LogsLayout()),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
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
        RowBox(
          style: FlexBoxStyler(),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SizedBox.square(
                dimension: 36,
                child: StyledIcon(icon: Icons.account_tree, style: IconStyler().size(20).color(Colors.grey[700]!)),
              ),
            ),
            Box(
              style: BoxStyler().wrap(WidgetModifierConfig.flexible(fit: FlexFit.tight)),
              child: Text(
                'Nodes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
            IconButton(
              onPressed: () {
                coordinator.panelPath.remove(NodesLayout());
              },
              icon: const Icon(Icons.close, size: 20),
            ),
          ],
        ),
        Box(style: BoxStyler().height(1).color(const Color(0xFFE0E0E0))),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: _kNodes.map((node) {
              return _NodeItem(nodeId: node.id, label: node.label, icon: node.icon, isDark: isDark);
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: double.infinity,
            height: 34,
            child: OutlinedButton.icon(
              onPressed: () => coordinator.navigate(NodeCreateRoute()),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create Node', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
            ),
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
                onTap: () => widget.coordinator.panelPath.remove(LogsLayout()),
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
// Panel Layouts
// ============================================================================

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

// ============================================================================
// Panel Routes
// ============================================================================

class AppsRoute extends AppRoute {
  AppsRoute({super.queries});

  @override
  String get title => 'Apps';

  @override
  IconData? get icon => Icons.apps;

  @override
  Type get layout => AppsLayout;

  @override
  Uri toUri() => Uri.parse('/apps');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return AppsSidebar(coordinator: coordinator);
  }
}

class NodesRoute extends AppRoute {
  NodesRoute({super.queries});

  @override
  String get title => 'Nodes';

  @override
  IconData? get icon => Icons.account_tree;

  @override
  Type get layout => NodesLayout;

  @override
  Uri toUri() => Uri.parse('/nodes');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => _NodesPanel(coordinator: coordinator);
}

class NodeCreateRoute extends AppRoute {
  NodeCreateRoute({super.queries});

  @override
  String get title => 'Create Node';

  @override
  IconData? get icon => Icons.add_circle_outline;

  @override
  Type get layout => NodesLayout;

  @override
  Uri toUri() => Uri.parse('/nodes/create');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              border: Border(bottom: BorderSide(color: const Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => coordinator.nodesPath.pop(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(child: Icon(Icons.arrow_back, size: 18)),
                    ),
                  ),
                ),
                Text(
                  'Create Node',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Node Name',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 36,
                    child: TextField(
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Enter node name...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Type',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['Input', 'Transform', 'Filter', 'Output'].map((type) {
                      return Chip(
                        label: Text(type, style: const TextStyle(fontSize: 12)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: ElevatedButton.icon(
                      onPressed: () => coordinator.nodesPath.pop(),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Create', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LogsRoute extends AppRoute {
  LogsRoute({super.queries});

  @override
  String get title => 'Logs';

  @override
  IconData? get icon => Icons.terminal;

  @override
  Type get layout => LogsLayout;

  @override
  Uri toUri() => Uri.parse('/logs');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return _LogsPanel(coordinator: coordinator);
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

// ============================================================================
// Main
// ============================================================================
