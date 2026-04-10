import 'dart:math';

import 'package:dynamic_tab_zenrouter/app_coordinator.dart';
import 'package:dynamic_tab_zenrouter/main_chrome_tabs.dart';
import 'package:dynamic_tab_zenrouter/views/about_views.dart';
import 'package:dynamic_tab_zenrouter/views/detail_views.dart';
import 'package:dynamic_tab_zenrouter/views/nodes_view.dart';
import 'package:dynamic_tab_zenrouter/views/settings_views.dart';
import 'package:dynamic_tab_zenrouter/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

class HomeTab extends AppRoute {
  HomeTab({super.queries});

  @override
  String get title => 'Home';

  @override
  IconData? get icon => Icons.home;

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
            ElevatedButton.icon(
              onPressed: () => coordinator.navigate(NodesRoute()),
              icon: const Icon(Icons.account_tree),
              label: const Text('Open Nodes'),
            ),
          ],
        ),
      ],
    );
  }
}

class PostDetailRoute extends AppRoute {
  PostDetailRoute({required this.postId, required this.postTitle, super.queries});

  final int postId;
  final String postTitle;

  @override
  String get title => postTitle;

  @override
  IconData? get icon => Icons.article;

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
        InTabNavBar(title: postTitle, coordinator: coordinator),
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
  PostCommentRoute({required this.postId, super.queries});

  final int postId;

  @override
  String get title => 'Comments — Post $postId';

  @override
  IconData? get icon => Icons.comment;

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
        InTabNavBar(title: 'Comments - Post $postId', coordinator: coordinator),
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
