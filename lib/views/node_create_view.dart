import 'package:dynamic_tab_zenrouter/app_coordinator.dart';
import 'package:dynamic_tab_zenrouter/main_chrome_tabs.dart';
import 'package:flutter/material.dart';

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
