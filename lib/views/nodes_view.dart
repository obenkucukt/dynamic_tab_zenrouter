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
            children: kNodes.map((node) {
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

const kNodes = [
  (id: 'node-1', label: 'Input Node', icon: Icons.input),
  (id: 'node-2', label: 'Transform Node', icon: Icons.transform),
  (id: 'node-3', label: 'Filter Node', icon: Icons.filter_alt),
  (id: 'node-4', label: 'Output Node', icon: Icons.output),
  (id: 'node-5', label: 'Merge Node', icon: Icons.merge_type),
  (id: 'node-6', label: 'Split Node', icon: Icons.call_split),
];
