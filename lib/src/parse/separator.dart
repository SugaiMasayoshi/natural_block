import '../horizontal_align.dart';
import '../source_cursor.dart';

const Map<String, HorizontalAlign> _byChar = {
  '<': HorizontalAlign.start,
  '=': HorizontalAlign.center,
  '>': HorizontalAlign.end,
};

/// The alignment marker at the start of a block -- a column or a table cell,
/// where the block's text follows directly.
///
/// A backslash in front of a marker cancels it: the backslash is eaten and the
/// marker is left for the text. Only here, because only here would it have
/// meant anything; `a\<b` mid-sentence keeps its backslash.
HorizontalAlign parseAlign(SourceCursor cursor) {
  if (cursor.peek == r'\' && _byChar.containsKey(cursor.peekAt(1))) {
    cursor.take();
    return HorizontalAlign.unstated;
  }
  return _takeMarker(cursor);
}

/// A table's own alignment marker, after its opening `~`.
///
/// Does not settle an escape. The table's first cell starts at the same place
/// and reads its own marker next, and a backslash has to be settled by the one
/// whose text follows it -- otherwise `~\<a~` would eat the backslash here and
/// hand the cell a live `<`.
HorizontalAlign parseTableAlign(SourceCursor cursor) => _takeMarker(cursor);

HorizontalAlign _takeMarker(SourceCursor cursor) {
  final marker = _byChar[cursor.peek];
  if (marker == null) return HorizontalAlign.unstated;
  cursor.take();
  return marker;
}
