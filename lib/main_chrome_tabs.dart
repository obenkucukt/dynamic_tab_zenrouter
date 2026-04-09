import 'dart:async';
import 'dart:math';

import 'package:dynamic_tab_zenrouter/chrome_tabs.dart';
import 'package:dynamic_tab_zenrouter/tabs_path.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// ============================================================================
// Base Route Types
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

abstract class TabRoute extends AppRoute with RouteTab {}

/// A tab that also acts as a [RouteLayout], managing its own inner
/// [NavigationPath].  Sub-routes whose [parentLayoutKey] matches this layout's
/// [layoutKey] are automatically pushed onto the correct per-tab path, keeping
/// the browser URL and deep-linking in sync.
abstract class TabLayoutRoute extends TabRoute with RouteLayout<AppRoute> {
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
    _updateDisplayedUrl(innerPath.stack.last.toUri());
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
  DetailTabLayout({required this.id, this.title});

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
  AppTabLayout({required this.appId, this.appName});

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

// ============================================================================
// Tab Content Routes  (root page inside each tab's NavigationPath)
// ============================================================================

class HomeTab extends AppRoute {
  @override
  Type get layout => HomeTabLayout;

  @override
  Uri toUri() => Uri.parse('/home');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final posts = List.generate(6, (i) => (id: i + 1, title: 'Post ${i + 1}'));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Welcome to Chrome Tabs!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Click a post below to navigate inside this tab.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        ...posts.map(
          (post) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(child: Text('${post.id}')),
              title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Tap to open detail view for post ${post.id}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => coordinator.push(PostDetailRoute(postId: post.id, postTitle: post.title)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                final random = Random().nextInt(100);
                coordinator.navigate(DetailTab(id: random));
              },
              icon: const Icon(Icons.tab),
              label: const Text('Open Random Tab'),
            ),
            ElevatedButton.icon(
              onPressed: () => coordinator.navigate(AboutTab()),
              icon: const Icon(Icons.info_outline),
              label: const Text('Open About'),
            ),
            ElevatedButton.icon(
              onPressed: () => coordinator.navigate(SettingsTab()),
              icon: const Icon(Icons.settings),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class AboutTab extends AppRoute {
  @override
  Type get layout => AboutTabLayout;

  @override
  Uri toUri() => Uri.parse('/about');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final techs = [
      (name: 'Flutter', description: 'UI Framework', icon: Icons.flutter_dash),
      (name: 'ZenRouter', description: 'Navigation & Routing', icon: Icons.route),
      (name: 'TabsPath', description: 'Tab State Management', icon: Icons.tab),
      (name: 'NavigationStack', description: 'Per-tab Navigation', icon: Icons.layers),
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('About', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(
          'Tap a technology to learn more.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        ...techs.map(
          (tech) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(tech.icon, color: Colors.blue[700]),
              title: Text(tech.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(tech.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => coordinator.push(TechDetailRoute(name: tech.name, description: tech.description)),
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsTab extends AppRoute {
  @override
  Type get layout => SettingsTabLayout;

  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final sections = [
      (id: 'theme', title: 'Theme', description: 'Appearance and color preferences', icon: Icons.brightness_6),
      (id: 'tabs', title: 'Tab Behavior', description: 'How tabs open, close and restore', icon: Icons.tab),
      (id: 'animations', title: 'Animations', description: 'Transition speeds and effects', icon: Icons.animation),
      (id: 'shortcuts', title: 'Keyboard Shortcuts', description: 'Customize key bindings', icon: Icons.keyboard),
    ];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Tap a section to view its options.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        ...sections.map(
          (section) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                child: Icon(section.icon, color: Colors.blue[700]),
              ),
              title: Text(section.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(section.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => coordinator.push(SettingsSectionRoute(sectionId: section.id, sectionTitle: section.title)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Root content for a dynamic detail tab.
class DetailTab extends AppRoute {
  DetailTab({required this.id});

  final int id;

  @override
  List<Object?> get props => [id];

  @override
  Object? get parentLayoutKey => (DetailTabLayout, id);

  @override
  Uri toUri() => Uri.parse('/detail/$id');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Tab $id', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text('Tab ID: $id', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Statistics', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View stats for this tab'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => coordinator.push(DetailSectionRoute(tabId: id, section: 'stats')),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.history),
            title: const Text('History', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View history for this tab'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => coordinator.push(DetailSectionRoute(tabId: id, section: 'history')),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.note_add),
            title: const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View and create notes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => coordinator.push(DetailSectionRoute(tabId: id, section: 'notes')),
          ),
        ),
      ],
    );
  }
}

/// Root content for a dynamic app tab.
class AppDetailTab extends AppRoute {
  AppDetailTab({required this.appId});

  final String appId;

  @override
  List<Object?> get props => [appId];

  @override
  Object? get parentLayoutKey => (AppTabLayout, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final app = _kApps.where((a) => a.id == appId).firstOrNull;
    final appName = app?.name ?? appId;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(appName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text('App ID: $appId', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Short Description', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View the short description of this app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => coordinator.push(AppDescriptionRoute(appId: appId, type: 'short')),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Full Description', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('View the full description of this app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => coordinator.push(AppDescriptionRoute(appId: appId, type: 'full')),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Configure this app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => coordinator.push(AppSettingsRoute(appId: appId)),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        ValueListenableBuilder<bool>(
          valueListenable: coordinator.nodesOpen,
          builder: (context, isOpen, _) {
            return ElevatedButton.icon(
              onPressed: () => coordinator.nodesOpen.value = !isOpen,
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

class IndexRoute extends AppRoute with RouteRedirect {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => const SizedBox.shrink();

  @override
  Uri toUri() => Uri.parse('/');

  @override
  FutureOr<RouteTarget> redirect() => HomeTab();
}

// ============================================================================
// In-Tab Sub-Routes  (layout / parentLayoutKey → correct tab path → URL synced)
// ============================================================================

// --- Home tab sub-routes ---------------------------------------------------

class PostDetailRoute extends AppRoute {
  PostDetailRoute({required this.postId, required this.postTitle});

  final int postId;
  final String postTitle;

  @override
  List<Object?> get props => [postId];

  @override
  Type get layout => HomeTabLayout;

  @override
  Uri toUri() => Uri.parse('/home/post/$postId');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Column(
      children: [
        _InTabNavBar(title: postTitle, onBack: () => coordinator.tryPop()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(postTitle, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Post ID: $postId', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                    'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n\n'
                    'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum '
                    'dolore eu fugiat nulla pariatur.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => coordinator.push(PostCommentRoute(postId: postId)),
                icon: const Icon(Icons.comment),
                label: const Text('View Comments'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PostCommentRoute extends AppRoute with RouteDeepLink {
  PostCommentRoute({required this.postId});

  final int postId;

  @override
  List<Object?> get props => [postId, 'comments'];

  @override
  Type get layout => HomeTabLayout;

  @override
  Uri toUri() => Uri.parse('/home/post/$postId/comments');

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;

  @override
  Future<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) async {
    await coordinator.navigate(PostDetailRoute(postId: postId, postTitle: 'Post $postId'));
    await coordinator.push(this);
  }

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final comments = List.generate(5, (i) => (user: 'User ${i + 1}', text: 'Comment #${i + 1} on post $postId.'));

    return Column(
      children: [
        _InTabNavBar(title: 'Comments - Post $postId', onBack: () => coordinator.tryPop()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: comments
                .map(
                  (c) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(c.user.split(' ').last)),
                      title: Text(c.user, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(c.text),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// --- Settings tab sub-routes ------------------------------------------------

class SettingsSectionRoute extends AppRoute {
  SettingsSectionRoute({required this.sectionId, required this.sectionTitle});

  final String sectionId;
  final String sectionTitle;

  @override
  List<Object?> get props => [sectionId];

  @override
  Type get layout => SettingsTabLayout;

  @override
  Uri toUri() => Uri.parse('/settings/$sectionId');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Column(
      children: [
        _InTabNavBar(title: sectionTitle, onBack: () => coordinator.tryPop()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: List.generate(
              4,
              (i) => SwitchListTile(
                title: Text('$sectionTitle Option ${i + 1}'),
                subtitle: Text('Description for option ${i + 1}'),
                value: i.isEven,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- About tab sub-routes ---------------------------------------------------

class TechDetailRoute extends AppRoute {
  TechDetailRoute({required this.name, this.description = ''});

  final String name;
  final String description;

  @override
  List<Object?> get props => [name];

  @override
  Type get layout => AboutTabLayout;

  @override
  Uri toUri() => Uri.parse('/about/tech/${name.toLowerCase()}');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Column(
      children: [
        _InTabNavBar(title: name, onBack: () => coordinator.tryPop()),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.code, size: 64, color: Colors.blue[700]),
                const SizedBox(height: 24),
                Text(name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(description, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- App tab sub-routes -----------------------------------------------------

class AppDescriptionRoute extends AppRoute {
  AppDescriptionRoute({required this.appId, required this.type});

  final String appId;
  final String type;

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
        _InTabNavBar(title: '$typeTitle - $appName', onBack: () => coordinator.tryPop()),
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
  AppSettingsRoute({required this.appId});

  final String appId;

  @override
  List<Object?> get props => [appId, 'settings'];

  @override
  Object? get parentLayoutKey => (AppTabLayout, appId);

  @override
  Uri toUri() => Uri.parse('/apps/$appId/settings');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final appName = _kApps.where((a) => a.id == appId).firstOrNull?.name ?? appId;

    return Column(
      children: [
        _InTabNavBar(title: 'Settings - $appName', onBack: () => coordinator.tryPop()),
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
    );
  }
}

// --- Dynamic detail tab sub-routes ------------------------------------------

/// A sub-page inside a dynamically-created detail tab.
/// Uses [parentLayoutKey] with the tab id so the coordinator resolves the
/// correct [DetailTabLayout] instance and its [NavigationPath].
class DetailSectionRoute extends AppRoute {
  DetailSectionRoute({required this.tabId, required this.section});

  final int tabId;
  final String section;

  @override
  List<Object?> get props => [tabId, section];

  @override
  Object? get parentLayoutKey => (DetailTabLayout, tabId);

  @override
  Uri toUri() => Uri(path: '/detail/$tabId/$section');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final sectionTitle = '${section[0].toUpperCase()}${section.substring(1)}';

    return Column(
      children: [
        _InTabNavBar(title: '$sectionTitle - Tab $tabId', onBack: () => coordinator.tryPop()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                sectionTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SelectableText(
                'This page lives inside dynamic Tab $tabId.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              if (section == 'notes') ...[
                ...List.generate(
                  3,
                  (i) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.note),
                      title: Text('Note ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('Note content for tab $tabId'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => coordinator.push(DetailNoteRoute(tabId: tabId, noteId: i + 1)),
                    ),
                  ),
                ),
              ] else
                ...List.generate(
                  4,
                  (i) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(section == 'stats' ? Icons.bar_chart : Icons.access_time),
                      title: Text('$sectionTitle item ${i + 1}'),
                      subtitle: Text('Details for $section item ${i + 1} in tab $tabId'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Third-level nesting inside a dynamic tab: Notes → single Note detail.
class DetailNoteRoute extends AppRoute with RouteDeepLink {
  DetailNoteRoute({required this.tabId, required this.noteId});

  final int tabId;
  final int noteId;

  @override
  List<Object?> get props => [tabId, 'note', noteId];

  @override
  Object? get parentLayoutKey => (DetailTabLayout, tabId);

  @override
  Uri toUri() => Uri.parse('/detail/$tabId/notes/$noteId');

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.push;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Column(
      children: [
        _InTabNavBar(title: 'Note $noteId - Tab $tabId', onBack: () => coordinator.tryPop()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Note $noteId',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      'This is the full content of note $noteId inside dynamic tab $tabId.\n\n'
                      'Three levels deep:  Tab $tabId  >  Notes  >  Note $noteId\n\n'
                      'The browser URL reflects the full path.',
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

    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['home'] => HomeTab(),
      ['home', 'post', final id] => PostDetailRoute(postId: int.tryParse(id) ?? 0, postTitle: 'Post $id'),
      ['home', 'post', final id, 'comments'] => PostCommentRoute(postId: int.tryParse(id) ?? 0),
      ['detail', final id] => DetailTab(id: int.tryParse(id) ?? 0),
      ['detail', final id, 'notes', final noteId] => DetailNoteRoute(
        tabId: int.tryParse(id) ?? 0,
        noteId: int.tryParse(noteId) ?? 0,
      ),
      ['detail', final id, final section] => DetailSectionRoute(tabId: int.tryParse(id) ?? 0, section: section),
      ['about'] => AboutTab(),
      ['about', 'tech', final name] => TechDetailRoute(name: name),
      ['settings'] => SettingsTab(),
      ['settings', final section] => SettingsSectionRoute(sectionId: section, sectionTitle: section),
      ['apps'] => HomeTab(),
      ['apps', final id] => AppDetailTab(appId: id),
      ['apps', final id, 'description', final type] => AppDescriptionRoute(appId: id, type: type),
      ['apps', final id, 'settings'] => AppSettingsRoute(appId: id),
      ['nodes'] => HomeTab(),
      _ => HomeTab(),
    };
  }
}

// ============================================================================
// Main
// ============================================================================

void main() {
  final coordinator = AppCoordinator();
  usePathUrlStrategy();

  runApp(
    MaterialApp.router(
      title: 'Chrome Tabs Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      routerConfig: coordinator,
    ),
  );
}
