import '../horizontal_align.dart';
import '../markup.dart';
import '../source_cursor.dart';

HorizontalAlign parseAlign(SourceCursor cursor) {
  if (cursor.peek == escapeChar && alignMarkers.containsKey(cursor.peekAt(1))) {
    cursor.take();
    return HorizontalAlign.unstated;
  }
  final marker = alignMarkers[cursor.peek];
  if (marker == null) return HorizontalAlign.unstated;
  cursor.take();
  return marker;
}
