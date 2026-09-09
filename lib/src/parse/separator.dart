import '../horizontal_align.dart';
import '../source_cursor.dart';

/// The three alignments that can be written. [HorizontalAlign.unstated] is
/// absent because there is no character for it -- that is what it means.
const Map<String, HorizontalAlign> _byChar = {
  '<': HorizontalAlign.start,
  '=': HorizontalAlign.center,
  '>': HorizontalAlign.end,
};

/// The markers written directly after a separator, which is the only place
/// they mean anything.
///
/// Called with the separator already eaten, by the node that ate it -- so the
/// symbol never leaves its owner's file, and a node never reads markers
/// without having just consumed the thing that makes them markers. `=>` at
/// the start of a document is text, and nothing here has to know that.
///
/// A later marker overrides an earlier one, so `|<>` ends up end-aligned --
/// the rule a decoration cluster already has, where `:!%` is success.
///
/// A `^` is not a marker, so it ends the run of them and opens a cell of its
/// own: `|<^>a` is a row, not an end-aligned block.
///
/// Not on [HorizontalAlign] itself, because the nodes these land on -- a
/// column, a table, a table's cell -- share no ancestor closer than the root.
HorizontalAlign takeMarkers(SourceCursor cursor) {
  var align = HorizontalAlign.unstated;
  while (!cursor.isEnd) {
    final marker = _byChar[cursor.peek];
    if (marker == null) break;
    align = marker;
    cursor.take();
  }
  return align;
}
