import 'package:dynamic_tab_zenrouter/app_coordinator.dart';
import 'package:dynamic_tab_zenrouter/main_chrome_tabs.dart';
import 'package:dynamic_tab_zenrouter/views/node_create_view.dart';
import 'package:flutter/material.dart';
import 'package:mix/mix.dart';

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
  Widget build(AppCoordinator coordinator, BuildContext context) => NodesView(coordinator: coordinator);
}

class NodesView extends StatelessWidget {
  const NodesView({super.key, required this.coordinator});

  final AppCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    debugPrint('NodesPanel build');

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
            children: kNodes.map((node) {
              return _NodeItem(nodeId: node.id, label: node.label, icon: node.icon);
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

class _NodeItem extends StatelessWidget {
  const _NodeItem({required this.nodeId, required this.label, required this.icon});

  final String nodeId;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const hoverColor = Color(0xFFF0F0F0);
    final iconColor = Colors.grey[600]!;
    const textColor = Colors.black87;

    return PressableBox(
      style: BoxStyler()
          .color(Colors.transparent)
          .onHovered(BoxStyler().color(hoverColor))
          .margin(EdgeInsetsDirectionalMix.symmetric(horizontal: 8, vertical: 2))
          .paddingX(12)
          .paddingY(10)
          .borderRounded(8)
          .animate(.curve(duration: Duration(milliseconds: 150), curve: Curves.linear)),
      child: RowBox(
        style: FlexBoxStyler().spacing(12),
        children: [
          StyledIcon(icon: icon, style: IconStyler().size(20).color(iconColor)),
          Box(
            style: BoxStyler().wrap(WidgetModifierConfig.flexible(fit: FlexFit.tight)),
            child: Text(label, style: TextStyle(fontSize: 14, color: textColor)),
          ),
        ],
      ),
    );
  }
}

const kNodes = [
  (id: 'node-1', label: 'Input Node', icon: Icons.input),
  (id: 'node-2', label: 'Transform Node', icon: Icons.transform),
  (id: 'node-3', label: 'Filter Node', icon: Icons.filter_alt),
  (id: 'node-4', label: 'Output Node', icon: Icons.output),
  (id: 'node-5', label: 'Merge Node', icon: Icons.merge_type),
  (id: 'node-6', label: 'Split Node', icon: Icons.call_split),
];
