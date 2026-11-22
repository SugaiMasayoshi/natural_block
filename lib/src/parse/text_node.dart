import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'line_node.dart';
import 'line_start.dart';

TextNode? parseTextNode(SourceCursor cursor, TextPlace place) {
  final start = cursor.position;
  final lines = <LineNode>[];
  bool opensMarkupAt(int index) =>
      cursor.source.length > index && cursor.source[index] == tableChar ||
      opensLine(cursor.source, index, place);

  while (true) {
    final line = parseLineNode(cursor, place);
    // A line with nothing on it before a cell's end or a raw block is theirs.
    final endsLine = cursor.isEnd || cursor.peek == '\n';
    if (line.children.isNotEmpty || endsLine) lines.add(line);

    if (cursor.peek != '\n' || opensMarkupAt(cursor.position + 1)) break;
    cursor.take();
    final escapedMarker =
        cursor.peek == escapeChar && opensMarkupAt(cursor.position + 1);
    if (escapedMarker) cursor.take();
  }

  if (lines.isEmpty) return null;
  return TextNode(children: lines, start: start, end: lines.last.end);
}
