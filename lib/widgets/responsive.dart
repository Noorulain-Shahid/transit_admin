// Shared layout rules for every admin screen, so the same app reads well as
// a phone app and as a Windows desktop window.
//
// Three window classes, by the *window's* width (not the device type — a
// narrow desktop window gets the phone layout, a wide tablet the desktop
// one):
//
//   compact   < 600         phone layout: bottom navigation, one column
//   medium    600 – 1023    navigation rail, multi-column card grids
//   expanded  ≥ 1024        labelled side navigation, two-column details
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Width below which the phone layout (bottom navigation) is used.
const double kCompactBreakpoint = 600;

/// Width from which the labelled side navigation and two-column detail
/// screens are used.
const double kExpandedBreakpoint = 1024;

/// Widest a content column grows to; beyond it the column is centred.
const double kMaxContentWidth = 1280;

enum WindowClass { compact, medium, expanded }

WindowClass windowClassFor(double width) {
  if (width < kCompactBreakpoint) return WindowClass.compact;
  if (width < kExpandedBreakpoint) return WindowClass.medium;
  return WindowClass.expanded;
}

/// The window class of the whole window (not of a sub-panel).
WindowClass windowClassOf(BuildContext context) =>
    windowClassFor(MediaQuery.sizeOf(context).width);

/// True on Windows/macOS/Linux desktop builds (not the web).
bool get isDesktopPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux);

/// Wraps [child] so it never stretches edge-to-edge past [maxWidth] on a
/// wide window — centres it instead, the way most admin/dashboard apps keep
/// a readable content column rather than letting text and cards sprawl
/// across an ultra-wide monitor. Narrower than [maxWidth], this is a no-op
/// (full width, exactly the phone behaviour).
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = kMaxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || constraints.maxWidth <= maxWidth) {
          return child;
        }
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: maxWidth, child: child),
        );
      },
    );
  }
}

/// How many grid columns a stat/card grid should use at [width] — 3 on a
/// phone, scaling up to 6 on a very wide desktop window, so a dashboard
/// grid doesn't stay stuck at 3 skinny columns stretched across a monitor.
int gridColumnsFor(double width) {
  if (width >= 1400) return 6;
  if (width >= 1100) return 5;
  if (width >= 700) return 4;
  return 3;
}

/// Columns that fit [width] when no item may be narrower than
/// [minItemWidth]; never fewer than 1 nor more than [maxColumns].
int columnsFor(
  double width, {
  required double minItemWidth,
  double spacing = 12,
  int maxColumns = 4,
}) {
  if (!width.isFinite || width <= 0) return 1;
  final fit = ((width + spacing) / (minItemWidth + spacing)).floor();
  return fit.clamp(1, maxColumns);
}

/// Lays [children] out in as many equal-width columns as fit (each at least
/// [minItemWidth] wide) — one column on a phone, two to four on a desktop.
/// Rows take the height of their tallest card; cards are top-aligned.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final double runSpacing;
  final int maxColumns;
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 340,
    this.spacing = 12,
    this.runSpacing = 10,
    this.maxColumns = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = columnsFor(
          width,
          minItemWidth: minItemWidth,
          spacing: spacing,
          maxColumns: maxColumns,
        );
        if (cols == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: runSpacing),
                children[i],
              ],
            ],
          );
        }
        final itemWidth = ((width - spacing * (cols - 1)) / cols)
            .floorToDouble();
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final c in children) SizedBox(width: itemWidth, child: c),
          ],
        );
      },
    );
  }
}

/// A detail screen's body: one column on a phone or narrow window, two
/// side-by-side columns ([primary] left, [secondary] right) once the
/// available width reaches [breakpoint].
class TwoPane extends StatelessWidget {
  final List<Widget> primary;
  final List<Widget> secondary;
  final double breakpoint;
  final double gap;
  final int primaryFlex;
  final int secondaryFlex;
  const TwoPane({
    super.key,
    required this.primary,
    required this.secondary,
    this.breakpoint = 900,
    this.gap = 12,
    this.primaryFlex = 1,
    this.secondaryFlex = 1,
  });

  List<Widget> _spaced(List<Widget> items) => [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) SizedBox(height: gap),
      items[i],
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _spaced([...primary, ...secondary]),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: primaryFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _spaced(primary),
              ),
            ),
            SizedBox(width: gap + 4),
            Expanded(
              flex: secondaryFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _spaced(secondary),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A [GestureDetector] that also shows the hand cursor on desktop when it
/// is tappable — every tappable card, pill and back button in the app goes
/// through this so a mouse user can see what's clickable.
class Clickable extends StatelessWidget {
  final VoidCallback? onTap;
  final HitTestBehavior? behavior;
  final Widget child;
  const Clickable({
    super.key,
    required this.onTap,
    required this.child,
    this.behavior,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, behavior: behavior, child: child),
    );
  }
}

/// Width cap for dialogs and sheets on a wide window, so a one-line prompt
/// doesn't become a 1,500-pixel-wide bar.
const BoxConstraints kDialogConstraints = BoxConstraints(maxWidth: 560);

/// Padding for a full-window scrolling list that keeps its rows in a
/// centred column at most [maxWidth] wide, while the scrollable itself
/// still spans the window (so the mouse wheel and scrollbar work anywhere,
/// not only over the column).
EdgeInsets centeredListPadding(
  BuildContext context, {
  double maxWidth = 900,
  double horizontal = 16,
  double top = 0,
  double bottom = 24,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final extra = (width - maxWidth) / 2;
  final side = extra > horizontal ? extra : horizontal;
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}

/// App-wide scrolling on desktop: vertical lists always show their
/// scrollbar thumb (a mouse user can see a list is longer than the window,
/// and grab the thumb instead of relying on a swipe), while phones keep
/// the platform's own overscroll and fading behaviour.
class AdminScrollBehavior extends MaterialScrollBehavior {
  const AdminScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final desktop = switch (getPlatform(context)) {
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => true,
      _ => false,
    };
    if (!desktop || axisDirectionToAxis(details.direction) != Axis.vertical) {
      return super.buildScrollbar(context, child, details);
    }
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      child: child,
    );
  }
}
