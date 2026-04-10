part of '../main_chrome_tabs.dart';

class AboutTab extends AppRoute {
  AboutTab({super.queries});

  @override
  String get title => 'About';

  @override
  IconData? get icon => Icons.info;

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

class TechDetailRoute extends AppRoute {
  TechDetailRoute({required this.name, this.description = '', super.queries});

  final String name;
  final String description;

  @override
  String get title => name;

  @override
  IconData? get icon => Icons.code;

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
        _InTabNavBar(title: name, coordinator: coordinator),
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
