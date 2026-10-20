// This app previously assumed a fixed phone-width column everywhere — no
// `MediaQuery`/`LayoutBuilder`/breakpoint logic existed anywhere in the
// admin screens, even though an admin panel is disproportionately likely to
// be opened on a tablet or desktop browser. These two small helpers are the
// shared starting point for fixing that, applied first to the
// highest-traffic surfaces (the bottom-nav shell and the Dashboard's stat
// grid) rather than attempting every screen in one pass.
import 'package:flutter/material.dart';

/// Wraps [child] so it never stretches edge-to-edge past [maxWidth] on a
/// wide viewport (desktop/tablet browser) — centers it instead, the same
/// way most admin/dashboard web apps keep a readable content column rather
/// than letting text and cards sprawl across an ultra-wide window. Narrower
/// than [maxWidth], this is a no-op (full width, exactly today's behavior).
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 900});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Below `maxWidth` this is a complete no-op — returns `child`
        // directly with no extra Center/SizedBox wrapper at all — so every
        // phone-width layout this app already had (the one actually used
        // and tested) is byte-for-byte unchanged. Only a viewport wider
        // than a phone/small-tablet gets the centered, width-capped column.
        if (constraints.maxWidth <= maxWidth) return child;
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
