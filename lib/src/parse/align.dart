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
  final marker = _byChar[cursor.peek];
  if (marker == null) return HorizontalAlign.unstated;
  cursor.take();
  return marker;
}
