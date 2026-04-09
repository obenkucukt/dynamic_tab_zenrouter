part of '../main_chrome_tabs.dart';

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
