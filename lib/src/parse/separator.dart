import '../horizontal_align.dart';
import '../source_cursor.dart';

const Map<String, HorizontalAlign> _byChar = {
  '<': HorizontalAlign.start,
  '=': HorizontalAlign.center,
  '>': HorizontalAlign.end,
};

HorizontalAlign parseAlign(SourceCursor cursor) {
  var align = HorizontalAlign.unstated;
  while (!cursor.isEnd) {
    final marker = _byChar[cursor.peek];
    if (marker == null) break;
    align = marker;
    cursor.take();
  }
  return align;
}
