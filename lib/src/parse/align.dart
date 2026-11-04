import '../horizontal_align.dart';
import '../markup.dart';
import '../source_cursor.dart';

HorizontalAlign parseAlign(SourceCursor cursor) {
  final escapedMarker =
      cursor.peek == escapeChar && alignMarkers.containsKey(cursor.peekAt(1));
  if (escapedMarker) {
    cursor.take();
    return HorizontalAlign.unstated;
  }
  final marker = alignMarkers[cursor.peek];
  if (marker == null) return HorizontalAlign.unstated;
  cursor.take();
  return marker;
}
