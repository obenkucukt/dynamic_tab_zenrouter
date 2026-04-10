// ============================================================================
// Apps Sidebar
// ============================================================================

import 'package:dynamic_tab_zenrouter/app_coordinator.dart';
import 'package:dynamic_tab_zenrouter/main_chrome_tabs.dart';
import 'package:dynamic_tab_zenrouter/views/app_detail_views.dart';
import 'package:flutter/material.dart';
import 'package:mix/mix.dart';
import 'package:motor/motor.dart';
import 'package:oref/oref.dart';

const kApps = [
  (id: 'notes', name: 'Notes', subtitle: 'Quick notes & memos', icon: Icons.note, color: Color(0xFFFFA726)),
  (
    id: 'calendar',
    name: 'Calendar',
    subtitle: 'Events & schedules',
    icon: Icons.calendar_today,
    color: Color(0xFFEF5350),
  ),
  (id: 'music', name: 'Music', subtitle: 'Songs & playlists', icon: Icons.music_note, color: Color(0xFFAB47BC)),
  (id: 'photos', name: 'Photos', subtitle: 'Albums & memories', icon: Icons.photo, color: Color(0xFF66BB6A)),
  (id: 'maps', name: 'Maps', subtitle: 'Navigation & places', icon: Icons.map, color: Color(0xFF26A69A)),
];

// ============================================================================
// AppsSidebar
// ============================================================================

class AppsRoute extends AppRoute {
  AppsRoute({super.queries});

  @override
  String get title => 'Apps';

  @override
  IconData? get icon => Icons.apps;

  @override
  Type get layout => AppsLayout;

  @override
  Uri toUri() => Uri.parse('/apps');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return AppsView(coordinator: coordinator);
  }
}

class AppsView extends StatefulWidget {
  const AppsView({required this.coordinator, super.key});

  final AppCoordinator coordinator;

  @override
  State<AppsView> createState() => _AppsViewState();
}

class _AppsViewState extends State<AppsView> {
  static const _expandedWidth = 220.0;
  static const _collapsedWidth = 56.0;

  @override
  void initState() {
    super.initState();
    widget.coordinator.tabsPath.addListener(_onTabsChanged);
  }

  @override
  void dispose() {
    widget.coordinator.tabsPath.removeListener(_onTabsChanged);
    super.dispose();
  }

  void _onTabsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    debugPrint('AppsSidebar build');
    final activeTab = widget.coordinator.tabsPath.activeRoute;
    String? activeAppId;
    if (activeTab is AppTabLayout) {
      activeAppId = activeTab.appId;
    }
    final isMinimized = signal<bool>(context, false);

    return SignalBuilder(
      builder: (context) {
        return SingleMotionBuilder(
          motion: CupertinoMotion.snappy(),
          value: isMinimized() ? 0.0 : 1.0,
          builder: (context, rawT, child) {
            final t = rawT.clamp(0.0, 1.0);
            final width = _collapsedWidth + (_expandedWidth - _collapsedWidth) * t;

            return ClipRect(
              child: SizedBox(
                width: width,
                child: OverflowBox(
                  maxWidth: _expandedWidth,
                  minWidth: _expandedWidth,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: _expandedWidth,
                    child: ColumnBox(
                      style: FlexBoxStyler().crossAxisAlignment(CrossAxisAlignment.start),
                      children: [
                        RowBox(
                          style: FlexBoxStyler().spacing(10),
                          children: [
                            SignalBuilder(
                              builder: (context) {
                                return PressableBox(
                                  style: _menuToggleStyle,
                                  onPress: () => isMinimized.set(!isMinimized()),
                                  child: StyledIcon(
                                    icon: isMinimized() ? Icons.menu : Icons.menu_open,
                                    style: _menuIconStyle,
                                  ),
                                );
                              },
                            ),
                            Box(
                              style: BoxStyler()
                                  .wrap(WidgetModifierConfig.flexible(fit: FlexFit.tight))
                                  .wrap(WidgetModifierConfig.opacity(t)),
                              child: Text(
                                'Apps',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                            ),
                          ],
                        ),
                        Box(style: BoxStyler().height(1).color(const Color(0xFFE0E0E0))),
                        Box(
                          style: BoxStyler().wrap(WidgetModifierConfig.flexible(fit: FlexFit.tight)),
                          child: ListView.builder(
                            itemCount: kApps.length,
                            itemBuilder: (context, index) {
                              return SignalBuilder(
                                builder: (context) {
                                  return _AppSidebarItem(
                                    appId: kApps[index].id,
                                    appName: kApps[index].name,
                                    subtitle: kApps[index].subtitle,
                                    icon: kApps[index].icon,
                                    isActive: kApps[index].id == activeAppId,
                                    color: kApps[index].color,
                                    textOpacity: t,
                                    isMinimized: isMinimized(),
                                    onTap: () => widget.coordinator.navigate(AppShortDescRoute(appId: kApps[index].id)),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// Sidebar Item
// ============================================================================

class _AppSidebarItem extends StatelessWidget {
  const _AppSidebarItem({
    required this.appId,
    required this.appName,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.color,
    required this.textOpacity,
    required this.isMinimized,
  });

  final String appId;
  final String appName;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color color;
  final double textOpacity;
  final bool isMinimized;

  @override
  Widget build(BuildContext context) {
    return PressableBox(
      style: _itemBoxStyle(isActive: isActive),
      onPress: onTap,
      child: RowBox(
        children: [
          Box(
            style: _iconBoxStyle(color: color).marginAll(8),
            child: StyledIcon(icon: icon, style: _iconContentStyle),
          ),
          ColumnBox(
            style: FlexBoxStyler()
                .crossAxisAlignment(CrossAxisAlignment.start)
                .mainAxisSize(MainAxisSize.min)
                .spacing(2)
                .wrap(WidgetModifierConfig.flexible(fit: FlexFit.tight))
                .wrap(WidgetModifierConfig.opacity(textOpacity)),
            children: [
              StyledText(appName, style: _titleTextStyle(isActive: isActive)),
              StyledText(subtitle, style: _subtitleTextStyle),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Shared Sidebar Styles
// ============================================================================

BoxStyler _itemBoxStyle({required bool isActive}) {
  final base = BoxStyler();
  if (isActive) return base.color(Colors.blue[50]!);
  return base.color(Colors.transparent).onHovered(BoxStyler().color(const Color(0xFFF0F0F0)));
}

BoxStyler _iconBoxStyle({required Color color}) {
  return BoxStyler()
      .size(36, 36)
      .alignment(Alignment.center)
      .animate(AnimationConfig.curve(duration: Duration(milliseconds: 150), curve: Curves.linear))
      .decoration(
        ShapeDecorationMix(
          color: color,
          shape: RoundedSuperellipseBorderMix(borderRadius: BorderRadiusMix.circular(8)),
        ),
      );
}

TextStyler _titleTextStyle({required bool isActive}) => TextStyler()
    .fontSize(13)
    .fontWeight(isActive ? FontWeight.w600 : FontWeight.w500)
    .color(isActive ? Colors.blue[800]! : Colors.black87)
    .maxLines(1)
    .overflow(TextOverflow.ellipsis);

final _subtitleTextStyle = TextStyler()
    .fontSize(11)
    .color(Colors.grey[600]!)
    .maxLines(1)
    .overflow(TextOverflow.ellipsis);

final _iconContentStyle = IconStyler().size(18).color(Colors.white);

final _menuToggleStyle = BoxStyler()
    .size(36, 36)
    .alignment(Alignment.center)
    .margin(EdgeInsetsDirectionalMix.symmetric(horizontal: 8, vertical: 4));

final _menuIconStyle = IconStyler().size(20).color(Colors.grey[700]!);
