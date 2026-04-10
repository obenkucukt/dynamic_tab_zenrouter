import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

/// Manages shell panels (apps, tabs, nodes, logs) as a single [StackPath].
///
/// Similar to [TabsPath] but designed for parallel panels:
/// - Multiple panels are visible simultaneously (not one at a time)
/// - [activeRoute] determines which panel's route appears in the URL
/// - [isPanelOpen] checks if a specific panel is in the stack
/// - [remove] also cleans up the panel's inner [NavigationPath]
class PanelPath<T extends RouteUnique> extends StackPath<T> with ChangeNotifier, StackMutatable<T> {
  PanelPath._(super.stack, {super.debugLabel, super.coordinator});

  factory PanelPath.createWith({
    required Coordinator coordinator,
    required String label,
    List<T>? stack,
  }) =>
      PanelPath._(stack ?? [], debugLabel: label, coordinator: coordinator);

  static const key = PathKey('PanelPath');

  int? _activeIndex;
  int? get activeIndex => _activeIndex;

  @override
  PathKey get pathKey => key;

  @override
  T? get activeRoute =>
      _activeIndex != null && _activeIndex! >= 0 && _activeIndex! < stack.length ? stack[_activeIndex!] : null;

  bool isPanelOpen(T panel) => stack.contains(panel);

  void focusPanel(T panel) {
    final index = stack.indexOf(panel);
    if (index != -1 && _activeIndex != index) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  @override
  Future<void> activateRoute(T route) async {
    final index = stack.indexOf(route);
    if (index != -1) {
      _activeIndex = index;
    } else {
      push(route);
    }
  }

  @override
  Future<void> pushOrMoveToTop(T element) async {
    await super.pushOrMoveToTop(element);
    final index = stack.indexOf(element);
    if (index != -1) _activeIndex = index;
  }

  @override
  Future<R?> push<R extends Object>(T element) async {
    final future = super.push<R>(element);
    _activeIndex = stack.length;
    return future;
  }

  @override
  Future<bool?> pop([Object? result]) async {
    final length = stack.length;
    final value = await super.pop(result);
    if (value == true && _activeIndex == length - 1) {
      _activeIndex = stack.length - 1;
    }
    return value;
  }

  @override
  void remove(T element, {bool discard = true}) {
    if (element is RouteLayoutParent) {
      final innerPath = (element as RouteLayoutParent).resolvePath(coordinator!);
      if (innerPath is NavigationPath) innerPath.reset();
    }

    final index = stack.indexOf(element);
    super.remove(element, discard: discard);
    if (index == _activeIndex && index < stack.length) return;
    _activeIndex ??= stack.length - 1;
    if (_activeIndex! >= stack.length) _activeIndex = stack.length - 1;
    if (_activeIndex! < 0) _activeIndex = null;
    notifyListeners();
  }

  @override
  void reset() {
    clear();
    _activeIndex = null;
  }

  @override
  Future<void> navigate(T route) async {
    final index = stack.indexOf(route);
    if (index != -1) {
      _activeIndex = index;
      notifyListeners();
      return;
    }
    push(route);
  }
}
