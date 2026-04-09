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
      body: buildPath(coordinator),
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
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;

  @override
  Future<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) async {
    await coordinator.navigate(DetailSectionRoute(tabId: tabId, section: 'notes'));
    await coordinator.push(this);
  }

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
// Coordinator
// ============================================================================

class AppCoordinator extends Coordinator<AppRoute> with CoordinatorDebug<AppRoute> {
  AppCoordinator();
  @override
  bool get debugEnabled => true;

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

  /// Lazily ensures the layout constructor exists before the coordinator
  /// tries to look it up during layout resolution.
  @override
  RouteLayoutParent? createLayoutParent(Object layoutKey) {
    if (layoutKey case (Type _, int id)) {
      detailTabPath(id);
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
  ];

  @override
  FutureOr<AppRoute> parseRouteFromUri(Uri uri) {
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
