import 'package:flutter/widgets.dart';

/// Anchor rect for share_plus on iPad.
///
/// iPad presents the share sheet as a popover pointed at
/// [sharePositionOrigin]. When the rect passed in covers (nearly) the whole
/// window - which happens when it's computed from a screen- or sheet-level
/// context instead of the tapped button - UIKit has no room to place the
/// popover and silently never shows it. The same call works in compact width
/// because iOS uses a regular sheet there and ignores the anchor entirely.
///
/// Returns the context's own rect when it's a reasonable anchor, otherwise a
/// point in the middle of the window so the popover always has room.
Rect shareOriginFor(BuildContext context) {
  final windowSize = MediaQuery.sizeOf(context);
  final center = Rect.fromCenter(
    center: Offset(windowSize.width / 2, windowSize.height / 2),
    width: 1,
    height: 1,
  );
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return center;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  final tooBig = rect.width >= windowSize.width * 0.8 &&
      rect.height >= windowSize.height * 0.8;
  if (tooBig) return center;
  return rect;
}
