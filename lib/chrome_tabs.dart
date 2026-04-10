import 'package:flutter/material.dart';
import 'package:oref/oref.dart';
import 'package:zenrouter/zenrouter.dart';
import 'tabs_path.dart';

/// A polished Chrome-like tab widget that displays tabs with modern styling.
class ChromeTabs<T extends RouteTab> extends StatefulWidget {
  const ChromeTabs({super.key, required this.coordinator, required this.path, this.onNewTab});

  final Coordinator coordinator;
  final TabsPath<T> path;
  final VoidCallback? onNewTab;

  @override
  State<ChromeTabs<T>> createState() => _ChromeTabsState<T>();
}

class _ChromeTabsState<T extends RouteTab> extends State<ChromeTabs<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    widget.path.addListener(_onPathChanged);
  }

  @override
  void dispose() {
    widget.path.removeListener(_onPathChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onPathChanged() => setState(() {});

  void _toggleView() => setState(() => _isGridView = !_isGridView);

  void _activateTabFromGrid(int index) {
    widget.path.goToIndexed(index);
    setState(() {
      _isGridView = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 44,
          decoration: ShapeDecoration(
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              side: BorderSide(color: const Color(0xFFDADCE0), width: 1),
            ),
            color: const Color(0xFFE8EAED),
          ),
          child: Row(
            children: [
              // Grid view toggle button
              _GridViewToggleButton(isGridView: _isGridView, onPressed: _toggleView),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: .horizontal,
                  itemCount: widget.path.stack.length,
                  itemBuilder: (context, index) {
                    final route = widget.path.stack[index];
                    final isActive = index == widget.path.activeIndex;
                    return _ChromeTab(
                      route: route,
                      coordinator: widget.coordinator,
                      path: widget.path,
                      isActive: isActive,
                      onTap: () => widget.path.goToIndexed(index),
                      onClose: widget.path.stack.length > 1 ? () => widget.path.remove(route) : null,
                    );
                  },
                ),
              ),
              if (widget.onNewTab != null) _NewTabButton(onPressed: widget.onNewTab!),
            ],
          ),
        ),
        Expanded(
          child: _isGridView
              ? _GridView(
                  coordinator: widget.coordinator,
                  path: widget.path,
                  onTabTap: _activateTabFromGrid,
                  onTabClose: (route) => widget.path.remove(route),
                )
              : Container(
                  color: Colors.white,
                  child: switch (widget.path.activeRoute) {
                    null => const Center(child: Text('No tab selected')),
                    final tab => _TabContentStack(
                      key: ValueKey(tab),
                      coordinator: widget.coordinator,
                      path: widget.path.tabPathFor(tab),
                    ),
                  },
                ),
        ),
      ],
    );
  }
}

class _ChromeTab<T extends RouteTab> extends StatefulWidget {
  const _ChromeTab({
    required this.route,
    required this.coordinator,
    required this.path,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  final T route;
  final Coordinator coordinator;
  final TabsPath<T> path;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  State<_ChromeTab<T>> createState() => _ChromeTabState<T>();
}

class _ChromeTabState<T extends RouteTab> extends State<_ChromeTab<T>> {
  @override
  Widget build(BuildContext context) {
    final isHovered = signal<bool>(context, false);
    final activeColor = Colors.white;
    final inactiveColor = const Color(0xFFE8EAED);
    final hoverColor = const Color(0xFFDADCE0);

    return SignalBuilder(
      builder: (context) {
        return MouseRegion(
          onEnter: (_) => isHovered.set(true),
          onExit: (_) => isHovered.set(false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              constraints: const BoxConstraints(minWidth: 120, maxWidth: 240),
              decoration: ShapeDecoration(
                color: widget.isActive
                    ? activeColor
                    : isHovered()
                    ? hoverColor
                    : inactiveColor,
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                  side: BorderSide.none,
                ),
              ),
              child: Row(
                mainAxisSize: .min,
                spacing: 12,
                children: [
                  Flexible(child: widget.route.tabLabel(widget.coordinator, widget.path, context, widget.isActive)),
                  if (widget.onClose != null) ...[
                    const SizedBox(width: 8),
                    _CloseButton(onPressed: widget.onClose!, isVisible: isHovered() || widget.isActive),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onPressed, required this.isVisible});

  final VoidCallback onPressed;
  final bool isVisible;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          opacity: widget.isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _isHovered ? (const Color(0xFFDADCE0)) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close, size: 16, color: const Color(0xFF5F6368)),
          ),
        ),
      ),
    );
  }
}

class _NewTabButton extends StatefulWidget {
  const _NewTabButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_NewTabButton> createState() => _NewTabButtonState();
}

class _NewTabButtonState extends State<_NewTabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: _isHovered ? (const Color(0xFFDADCE0)) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.add, size: 18, color: const Color(0xFF5F6368)),
        ),
      ),
    );
  }
}

// Grid view toggle button
class _GridViewToggleButton extends StatefulWidget {
  const _GridViewToggleButton({required this.isGridView, required this.onPressed});

  final bool isGridView;
  final VoidCallback onPressed;

  @override
  State<_GridViewToggleButton> createState() => _GridViewToggleButtonState();
}

class _GridViewToggleButtonState extends State<_GridViewToggleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: widget.isGridView
                ? (const Color(0xFFDADCE0))
                : _isHovered
                ? (const Color(0xFFDADCE0))
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.isGridView ? Icons.close_fullscreen : Icons.grid_view,
            size: 18,
            color: const Color(0xFF5F6368),
          ),
        ),
      ),
    );
  }
}

// Grid view widget
class _GridView<T extends RouteTab> extends StatelessWidget {
  const _GridView({required this.coordinator, required this.path, required this.onTabTap, required this.onTabClose});

  final Coordinator coordinator;
  final TabsPath<T> path;
  final Function(int) onTabTap;
  final Function(T) onTabClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          childAspectRatio: 16 / 10,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: path.stack.length,
        itemBuilder: (context, index) {
          final route = path.stack[index];
          final isActive = index == path.activeIndex;
          return _GridTabCard(
            route: route,
            coordinator: coordinator,
            path: path,
            isActive: isActive,
            onTap: () => onTabTap(index),
            onClose: path.stack.length > 1 ? () => onTabClose(route) : null,
          );
        },
      ),
    );
  }
}

// Grid tab card
class _GridTabCard<T extends RouteTab> extends StatefulWidget {
  const _GridTabCard({
    required this.route,
    required this.coordinator,
    required this.path,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  final T route;
  final Coordinator coordinator;
  final TabsPath<T> path;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  State<_GridTabCard<T>> createState() => _GridTabCardState<T>();
}

class _GridTabCardState<T extends RouteTab> extends State<_GridTabCard<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cardColor = Colors.white;
    final borderColor = widget.isActive ? (const Color(0xFF1976D2)) : (const Color(0xFFDADCE0));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: widget.isActive ? 2 : 1),
            boxShadow: _isHovered
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))]
                : [],
          ),
          child: Stack(
            children: [
              // Tab content preview
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    color: const Color(0xFFF8F9FA),
                    child: Center(child: Icon(Icons.tab, size: 48, color: const Color(0xFFDADCE0))),
                  ),
                ),
              ),
              // Tab label bar at the bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: widget.route.tabLabel(widget.coordinator, widget.path, context, widget.isActive)),
                      if (widget.onClose != null && _isHovered) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: const Color(0xFFE8EAED), shape: BoxShape.circle),
                            child: Icon(Icons.close, size: 14, color: const Color(0xFF5F6368)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Active indicator
              if (widget.isActive)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(12)),
                    child: const Text(
                      'Active',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the inner [NavigationStack] for a single tab.
///
/// Each tab gets its own [NavigationPath] so that sub-route pushes/pops are
/// scoped to the tab and preserved across tab switches.
class _TabContentStack extends StatelessWidget {
  const _TabContentStack({super.key, required this.coordinator, required this.path});

  final Coordinator coordinator;
  final NavigationPath<RouteUnique> path;

  @override
  Widget build(BuildContext context) {
    return NavigationStack<RouteUnique>(
      path: path,
      coordinator: coordinator,
      resolver: (route) => StackTransition.material(Builder(builder: (ctx) => route.build(coordinator, ctx))),
    );
  }
}
