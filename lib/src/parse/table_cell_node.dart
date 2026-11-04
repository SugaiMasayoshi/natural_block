import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'align.dart';
import 'flat_content_node.dart';

TableCellNode parseTableCellNode(SourceCursor cursor) {
  final align = parseAlign(cursor);
  final children = <FlatContentNode>[];

  var atLineStart = false;
  bool closesTable() => atLineStart && cursor.peek == tableChar;

  while (!cursor.isEnd && cursor.peek != rowChar && !closesTable()) {
    final before = cursor.position;
    final content = parseFlatContentNode(cursor, TextPlace.cell);
    if (content != null) children.add(content);
    atLineStart = cursor.peek == '\n';
    if (atLineStart) cursor.take();
    assert(
      cursor.position > before,
      'cell content parse made no progress at ${cursor.position}',
    );
  }

  return TableCellNode(children: children, align: align);
}
