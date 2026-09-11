import '../horizontal_align.dart';
import '../layout_symbols.dart';
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'content_node.dart';
import 'separator.dart';

ColumnNode parseColumnNode(
  SourceCursor cursor, {
  String opener = columnSymbol,
}) {
  var align = HorizontalAlign.unstated;
  if (cursor.peek == opener) {
    cursor.take();
    align = parseAlign(cursor);
  }

  if (cursor.peek == '\n') cursor.take();

  final content = <ContentNode>[];

  while (true) {
    final before = cursor.position;
    final piece = parseContentNode(cursor);
    if (piece != null) content.add(piece);
    if (cursor.position == before) break;
  }

  assert(
    cursor.isEnd || unpairedMarkup.contains(cursor.peek),
    'a block ended at ${cursor.peek} rather than a separator',
  );

  return ColumnNode(children: content, align: align);
}
