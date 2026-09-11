import '../horizontal_align.dart';
import '../source_cursor.dart';

const Map<String, HorizontalAlign> _byChar = {
  '<': HorizontalAlign.start,
  '=': HorizontalAlign.center,
  '>': HorizontalAlign.end,
};

HorizontalAlign parseAlign(SourceCursor cursor) {
  final marker = _byChar[cursor.peek];
  if (marker == null) return HorizontalAlign.unstated;
  cursor.take();
  return marker;
}
