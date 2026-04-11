import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';
import 'package:heroine/heroine.dart';

class StupidSimpleSheetPage<T> extends Page<T> {
  const StupidSimpleSheetPage({
    required this.child,
    super.key,
    this.motion = const CupertinoMotion.smooth(duration: Duration(milliseconds: 400)),
    this.draggable = true,
    this.snappingConfig = SheetSnappingConfig.full,
    super.name,
    super.arguments,
  });

  final Widget child;
  final Motion motion;
  final bool draggable;
  final SheetSnappingConfig snappingConfig;

  @override
  Route<T> createRoute(BuildContext context) {
    return StupidSimpleSheetRouteX<T>(
      settings: this,
      motion: motion,
      originateAboveBottomViewInset: true,
      child: child,
      draggable: draggable,
      snappingConfig: snappingConfig,
    );
  }
}

class StupidSimpleSheetRouteX<T> extends StupidSimpleSheetRoute<T> implements HeroinePageRouteMixin<T> {
  StupidSimpleSheetRouteX({
    required super.child,
    required super.settings,
    required super.motion,
    required super.originateAboveBottomViewInset,
    required super.draggable,
    required super.snappingConfig,
  });

  @override
  Widget buildContent(BuildContext context) => child;

  final _dismissProgress = ValueNotifier<double>(0);
  final _dismissOffset = ValueNotifier<Offset>(Offset.zero);

  @override
  bool get opaque => false;

  @override
  ValueListenable<double> get dismissProgress => _dismissProgress;

  @override
  ValueListenable<Offset> get dismissOffset => _dismissOffset;

  @override
  void updateDismiss(double progress, Offset offset) {
    _dismissProgress.value = progress.clamp(0, 1);
    _dismissOffset.value = offset;
  }

  @override
  void cancelDismiss() {
    _dismissProgress.value = 0;
    _dismissOffset.value = Offset.zero;
  }
}
