import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';

/// How many `|` the spacer at [position] is written with, or null when there
/// is none: `|` alone on its line. In a row's cell it may also end at the `^`
/// that closes the cell.
int? spacerAt(String source, int position, TextPlace place) {
  if (place == TextPlace.tableCell) return null;
  var index = position;
  while (index < source.length && source[index] == spacerChar) {
    index++;
  }
  final flex = index - position;
  if (flex == 0) return null;
  final ends =
      index == source.length ||
      source[index] == '\n' ||
      place == TextPlace.rowCell && source[index] == rowChar;
  return ends ? flex : null;
}

/// The spacer at the cursor, or null when there is none. The line break is
/// left to the parent.
SpacerNode? parseSpacerNode(SourceCursor cursor, TextPlace place) {
  final flex = spacerAt(cursor.source, cursor.position, place);
  if (flex == null) return null;
  final start = cursor.position;
  cursor.jumpTo(start + flex);
  return SpacerNode(flex: flex, start: start, end: cursor.position);
}
