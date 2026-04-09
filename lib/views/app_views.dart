part of '../main_chrome_tabs.dart';

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
