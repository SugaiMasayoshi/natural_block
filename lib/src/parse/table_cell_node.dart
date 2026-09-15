import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'align.dart';
import 'flat_content_node.dart';

const _endsCell = {columnChar, rowChar, tableChar};

TableCellNode parseTableCellNode(SourceCursor cursor) {
  final align = parseAlign(cursor);
  final children = <FlatContentNode>[];
  if (cursor.peek == '\n') cursor.take();

  while (!cursor.isEnd && !_endsCell.contains(cursor.peek)) {
    final before = cursor.position;
    final content = parseFlatContentNode(cursor);
    if (content != null) children.add(content);
    if (cursor.peek == '\n') cursor.take();
    assert(
      cursor.position > before,
      'cell content parse made no progress at ${cursor.position}',
    );
  }

  return TableCellNode(children: children, align: align);
}
