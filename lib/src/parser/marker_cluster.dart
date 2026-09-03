import '../block_align.dart';
import 'block_marker.dart';

class MarkerCluster {
  final BlockAlign? align;

  final bool togglesTable;

  final int end;

  const MarkerCluster({
    required this.align,
    required this.togglesTable,
    required this.end,
  });
}

MarkerCluster readMarkerCluster(
  String source,
  int from, {
  required bool allowTable,
}) {
  BlockAlign? align;
  var togglesTable = false;
  var i = from;

  while (i < source.length) {
    final char = source[i];

    final markerAlign = BlockAlign.byChar[char];
    if (markerAlign != null) {
      align = markerAlign;
      i += 1;
      continue;
    }

    if (allowTable && BlockMarker.byChar[char] == BlockMarker.table) {
      togglesTable = !togglesTable;
      i += 1;
      continue;
    }

    break;
  }

  return MarkerCluster(align: align, togglesTable: togglesTable, end: i);
}
