import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'align.dart';
import 'column_node.dart';
import 'row_node.dart';
import 'spacer_node.dart';

/// Whether a layout opens at [position], the start of a line in [place]: in
/// a block, a spacer, a marker or a row; in a row's cell, a spacer.
bool layoutOpensAt(String source, int position, TextPlace place) {
  if (spacerAt(source, position, place) != null) return true;
  if (place != TextPlace.block || position >= source.length) return false;
  final first = source[position];
  return alignMarkers.containsKey(first) || first == rowChar;
}

LayoutNode? parseLayoutNode(SourceCursor cursor) {
  final start = cursor.position;
  if (parseSpacerNode(cursor, TextPlace.block) case final spacer?) {
    if (cursor.peek == '\n') cursor.take();
    return spacer;
  }
  final align = parseAlign(cursor);
  if (cursor.peek == rowChar) return parseRowNode(cursor, align, start);
  return parseColumnNode(cursor, align, start, TextPlace.block);
}
