import 'package:flutter/widgets.dart';
import '../providers/library_provider.dart';
import '../services/player_settings.dart';

/// Where a list of books stands: the index of the first one not finished,
/// the way a series counts it. Null when the first is still to be read, so
/// a list opens at its top, and the last index when every one is finished.
int? upNextIndex(LibraryProvider lib, List<String> progressKeys) {
  for (var i = 0; i < progressKeys.length; i++) {
    if (lib.getProgressData(progressKeys[i])?['isFinished'] != true) {
      return i == 0 ? null : i;
    }
  }
  return progressKeys.isEmpty ? null : progressKeys.length - 1;
}

/// Brings row [index] of a sheet's book list to the top once it has laid
/// out. A list row is the 112 tall card and its 8 of padding, after the 4
/// the list keeps above; a grid is counted in rows of [columns] cells that
/// share [width], each 0.62 as wide as it is tall and 10 apart.
void scrollSheetToIndex(ScrollController? controller, int index,
    {int columns = 1, double width = 0}) {
  if (controller == null || index <= 0) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!controller.hasClients) return;
    final double offset;
    if (columns > 1) {
      final cell = (width - 32 - (columns - 1) * 10) / columns;
      offset = 4 + (index ~/ columns) * (cell / 0.62 + 10);
    } else {
      offset = 4 + index * 120.0;
    }
    final to = offset.clamp(0.0, controller.position.maxScrollExtent);
    if (PlayerSettings.einkMode) {
      controller.jumpTo(to);
    } else {
      controller.animateTo(to,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    }
  });
}
