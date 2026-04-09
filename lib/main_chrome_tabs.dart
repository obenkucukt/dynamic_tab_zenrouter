import 'dart:async';
import 'dart:math';

import 'package:dynamic_tab_zenrouter/chrome_tabs.dart';
import 'package:dynamic_tab_zenrouter/tabs_path.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Route Definitions
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

abstract class TabRoute extends AppRoute with RouteTab {}

/// Main layout with Chrome-style tabs
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
        coordinator.navigate(DetailTab(id: random, title: 'Tab $random'));
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
// Tab Routes (appear as tab roots)
// ============================================================================

/// Home tab – lists posts that can be opened as sub-routes inside the tab.
class HomeTab extends TabRoute {
  @override
  Type? get layout => ChromeTabLayout;

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
              onTap: () =>
                  coordinator.tabsPath.activeTabPath?.push(PostDetailRoute(postId: post.id, postTitle: post.title)),
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
                coordinator.navigate(DetailTab(id: random, title: 'Random Tab $random'));
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

  @override
  Uri toUri() => Uri.parse('/home');
}

/// Detail tab with customizable content
class DetailTab extends TabRoute {
  DetailTab({required this.id, required this.title});

  final int id;
  final String title;

  @override
  List<Object?> get props => [id];

  @override
  Type? get layout => ChromeTabLayout;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text('Tab ID: $id', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 32),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Text(
                      'Tab Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(context, 'Created', DateTime.now().toString()),
                _buildInfoRow(context, 'Type', 'Detail Tab'),
                _buildInfoRow(context, 'Closeable', 'Yes'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => coordinator.tabsPath.activeTabPath?.push(DetailSubPage(tabId: id, section: 'stats')),
          icon: const Icon(Icons.bar_chart),
          label: const Text('View Statistics'),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => coordinator.tabsPath.activeTabPath?.push(DetailSubPage(tabId: id, section: 'history')),
          icon: const Icon(Icons.history),
          label: const Text('View History'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  @override
  Widget tabLabel(AppCoordinator coordinator, TabsPath path, BuildContext context, bool active) {
    return Text(
      title,
      style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.normal),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Uri toUri() => Uri.parse('/detail/$id');
}

/// About tab
class AboutTab extends TabRoute {
  @override
  Type? get layout => ChromeTabLayout;

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
          'This is a demonstration of Chrome-style tabs using ZenRouter.\nTap a technology to learn more.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        Text(
          'Technologies Used:',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...techs.map(
          (tech) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(tech.icon, color: Colors.blue[700]),
              title: Text(tech.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(tech.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => coordinator.tabsPath.activeTabPath?.push(
                TechDetailRoute(name: tech.name, description: tech.description),
              ),
            ),
          ),
        ),
      ],
    );
  }

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

  @override
  Uri toUri() => Uri.parse('/about');
}

/// Settings tab
class SettingsTab extends TabRoute {
  @override
  Type? get layout => ChromeTabLayout;

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
              onTap: () => coordinator.tabsPath.activeTabPath?.push(
                SettingsSectionRoute(sectionId: section.id, sectionTitle: section.title),
              ),
            ),
          ),
        ),
      ],
    );
  }

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

  @override
  Uri toUri() => Uri.parse('/settings');
}

/// Index route that redirects to home
class IndexRoute extends AppRoute with RouteRedirect {
  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => const SizedBox.shrink();

  @override
  Uri toUri() => Uri.parse('/');

  @override
  FutureOr<RouteTarget> redirect() => HomeTab();
}

// ============================================================================
// In-Tab Sub-Routes
// ============================================================================

/// Sub-route shown when tapping a post inside the Home tab.
class PostDetailRoute extends AppRoute {
  PostDetailRoute({required this.postId, required this.postTitle});

  final int postId;
  final String postTitle;

  @override
  List<Object?> get props => [postId];

  @override
  Uri toUri() => Uri.parse('/home/post/$postId');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Column(
      children: [
        _InTabNavBar(title: postTitle, onBack: () => coordinator.tabsPath.activeTabPath?.pop()),
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
                    'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                    'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris '
                    'nisi ut aliquip ex ea commodo consequat.\n\n'
                    'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum '
                    'dolore eu fugiat nulla pariatur.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => coordinator.tabsPath.activeTabPath?.push(PostCommentRoute(postId: postId)),
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

/// Second-level sub-route: comments of a post (demonstrates multi-level nesting).
class PostCommentRoute extends AppRoute {
  PostCommentRoute({required this.postId});

  final int postId;

  @override
  List<Object?> get props => [postId, 'comments'];

  @override
  Uri toUri() => Uri.parse('/home/post/$postId/comments');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final comments = List.generate(
      5,
      (i) => (user: 'User ${i + 1}', text: 'This is comment #${i + 1} on post $postId.'),
    );

    return Column(
      children: [
        _InTabNavBar(title: 'Comments — Post $postId', onBack: () => coordinator.tabsPath.activeTabPath?.pop()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Comments',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...comments.map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(c.user.split(' ').last)),
                    title: Text(c.user, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(c.text),
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

/// Sub-route shown when tapping a settings section inside the Settings tab.
class SettingsSectionRoute extends AppRoute {
  SettingsSectionRoute({required this.sectionId, required this.sectionTitle});

  final String sectionId;
  final String sectionTitle;

  @override
  List<Object?> get props => [sectionId];

  @override
  Uri toUri() => Uri.parse('/settings/$sectionId');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Column(
      children: [
        _InTabNavBar(title: sectionTitle, onBack: () => coordinator.tabsPath.activeTabPath?.pop()),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                sectionTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ...List.generate(
                4,
                (i) => SwitchListTile(
                  title: Text('$sectionTitle Option ${i + 1}'),
                  subtitle: Text('Description for option ${i + 1}'),
                  value: i.isEven,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sub-route shown when tapping a technology inside the About tab.
class TechDetailRoute extends AppRoute {
  TechDetailRoute({required this.name, this.description = ''});

  final String name;
  final String description;

  @override
  List<Object?> get props => [name];

  @override
  Uri toUri() => Uri.parse('/about/tech/${name.toLowerCase()}');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Column(
      children: [
        _InTabNavBar(title: name, onBack: () => coordinator.tabsPath.activeTabPath?.pop()),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.code, size: 64, color: Colors.blue[700]),
                  const SizedBox(height: 24),
                  Text(name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 32),
                  Text(
                    'This page lives inside the About tab NavigationPath.\n'
                    'Press the back arrow or use the browser back button to return.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sub-route for detail tab sub-pages (stats, history, etc.)
class DetailSubPage extends AppRoute {
  DetailSubPage({required this.tabId, required this.section});

  final int tabId;
  final String section;

  @override
  List<Object?> get props => [tabId, section];

  @override
  Uri toUri() => Uri.parse('/detail/$tabId/$section');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Column(
      children: [
        _InTabNavBar(
          title: '${section[0].toUpperCase()}${section.substring(1)} — Tab $tabId',
          onBack: () => coordinator.tabsPath.activeTabPath?.pop(),
        ),
        Expanded(
          child: Center(
            child: Text(
              '${section.toUpperCase()} content for tab $tabId',
              style: Theme.of(context).textTheme.titleLarge,
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

/// A compact navigation bar placed at the top of in-tab sub-routes so the user
/// can navigate back without leaving the tab.
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

class AppCoordinator extends Coordinator<AppRoute> {
  late final tabsPath = TabsPath<TabRoute>.createWith(coordinator: this, label: 'tabs', stack: [HomeTab()])
    ..bindLayout(ChromeTabLayout.new);

  @override
  List<StackPath<RouteTarget>> get paths => [...super.paths, tabsPath];

  @override
  FutureOr<AppRoute> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => IndexRoute(),
      ['home'] => HomeTab(),
      ['home', 'post', final id] => PostDetailRoute(postId: int.tryParse(id) ?? 0, postTitle: 'Post $id'),
      ['home', 'post', final id, 'comments'] => PostCommentRoute(postId: int.tryParse(id) ?? 0),
      ['detail', final id] => DetailTab(id: int.tryParse(id) ?? 0, title: 'Detail $id'),
      ['detail', final id, final section] => DetailSubPage(tabId: int.tryParse(id) ?? 0, section: section),
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
