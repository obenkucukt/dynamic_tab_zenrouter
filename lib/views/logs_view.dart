// ============================================================================
// Logs Panel
// ============================================================================

import 'package:dynamic_tab_zenrouter/app_coordinator.dart';
import 'package:dynamic_tab_zenrouter/main_chrome_tabs.dart';
import 'package:flutter/material.dart';
import 'package:motor/motor.dart';
import 'package:oref/oref.dart';

class LogsRoute extends AppRoute {
  LogsRoute({super.queries});

  @override
  String get title => 'Logs';

  @override
  IconData? get icon => Icons.terminal;

  @override
  Type get layout => LogsLayout;

  @override
  Uri toUri() => Uri.parse('/logs');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => LogsView(coordinator: coordinator);
}

class LogsView extends StatefulWidget {
  const LogsView({super.key, required this.coordinator});

  final AppCoordinator coordinator;

  @override
  State<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends State<LogsView> {
  static const _expandedHeight = 200.0;
  static const _collapsedHeight = 37.0;

  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_onCoordinatorChanged);
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_onCoordinatorChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onCoordinatorChanged() {
    final activeTab = widget.coordinator.tabsPath.activeRoute;
    if (activeTab == null) return;
    final innerPath = widget.coordinator.tabsPath.tabPathFor(activeTab);
    if (innerPath.stack.isEmpty) return;
    final route = innerPath.stack.last;
    final entry = '[${DateTime.now().toIso8601String().substring(11, 19)}] ${route.toUri()}';
    setState(() {
      _logs.add(entry);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('LogsPanel build');
    final isMinimized = signal<bool>(context, false);

    return SingleMotionBuilder(
      motion: CupertinoMotion.snappy(),
      value: isMinimized() ? 0.0 : 1.0,
      builder: (context, rawT, child) {
        final t = rawT.clamp(0.0, 1.0);
        final height = _collapsedHeight + (_expandedHeight - _collapsedHeight) * t;

        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: height / _expandedHeight,
            child: SizedBox(
              height: _expandedHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SignalBuilder(
                    builder: (context) {
                      return GestureDetector(
                        onTap: () {
                          if (isMinimized()) isMinimized.set(false);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.terminal, size: 20, color: Colors.grey[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Logs',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => isMinimized.set(!isMinimized()),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Tooltip(
                                    message: isMinimized() ? 'Expand' : 'Minimize',
                                    child: Icon(
                                      isMinimized() ? Icons.expand_less : Icons.expand_more,
                                      size: 18,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() => _logs.clear()),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Tooltip(
                                    message: 'Clear logs',
                                    child: Icon(Icons.delete_sweep, size: 18, color: Colors.grey[500]),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => widget.coordinator.panelPath.remove(LogsLayout()),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: const Color(0xFFE0E0E0)),
                  Expanded(
                    child: Opacity(
                      opacity: t,
                      child: _logs.isEmpty
                          ? Center(
                              child: Text('No logs yet', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 1),
                                  child: Text(
                                    _logs[index],
                                    style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.green[800]),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
