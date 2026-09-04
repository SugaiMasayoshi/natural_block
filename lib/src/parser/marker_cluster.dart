import '../block_align.dart';

/// The markers written straight after a layout symbol, which describe the
/// block that symbol opens.
class MarkerCluster {
  final BlockAlign? align;

  final int end;

  const MarkerCluster({required this.align, required this.end});
}

MarkerCluster readMarkerCluster(String source, int from) {
  BlockAlign? align;
  var i = from;

  while (i < source.length) {
    final markerAlign = BlockAlign.byChar[source[i]];
    if (markerAlign == null) break;
    align = markerAlign;
    i += 1;
  }

  return MarkerCluster(align: align, end: i);
}
