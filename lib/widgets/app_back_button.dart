import 'package:dynamic_tab_zenrouter/app_coordinator.dart';
import 'package:dynamic_tab_zenrouter/main_chrome_tabs.dart';
import 'package:flutter/material.dart';
import 'package:mix/mix.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.coordinator});

  final AppCoordinator coordinator;

  List<AppRoute> _getBackStack() {
    final activeTab = coordinator.tabsPath.activeRoute;
    if (activeTab == null) return [];
    final innerPath = coordinator.tabsPath.tabPathFor(activeTab);
    if (innerPath.stack.length <= 1) return [];
    return innerPath.stack.sublist(0, innerPath.stack.length - 1).reversed.cast<AppRoute>().toList();
  }

  void _showBackStack(BuildContext context) {
    final stack = _getBackStack();
    if (stack.isEmpty) return;
    final box = context.findRenderObject() as RenderBox;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlay = Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<AppRoute>(
      context: context,
      color: isDark ? const Color(0xFF2D2D2D) : null,
      position: position,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
      items: stack.map((route) {
        return PopupMenuItem<AppRoute>(
          value: route,
          height: 40,
          child: Row(
            children: [
              Icon(route.icon, size: 16, color: isDark ? Colors.white70 : Colors.grey[700]),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  route.title,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(route.toUri().path, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        );
      }).toList(),
    ).then((route) {
      if (route != null) coordinator.navigate(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => coordinator.tryPop(),
      onLongPress: () => _showBackStack(context),
      customBorder: const CircleBorder(),
      child: const Tooltip(
        message: 'Back (long press for history)',
        child: SizedBox(width: 44, height: 44, child: Center(child: Icon(Icons.arrow_back, size: 20))),
      ),
    );
  }
}

class InTabNavBar extends StatelessWidget {
  const InTabNavBar({super.key, required this.title, required this.coordinator});

  final String title;
  final AppCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return Box(
      style: navBarStyle,
      child: Row(
        children: [
          AppBackButton(coordinator: coordinator),
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

final navBarStyle = BoxStyler()
    .height(44)
    .color(const Color(0xFFF5F5F5))
    .border(BorderMix(bottom: BorderSideMix(color: const Color(0xFFE0E0E0), width: 1)));
