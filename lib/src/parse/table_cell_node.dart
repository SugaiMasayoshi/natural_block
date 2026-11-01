import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'align.dart';
import 'flat_content_node.dart';

const _endsCell = {rowChar, tableChar, '\n'};

TableCellNode parseTableCellNode(SourceCursor cursor) {
  final align = parseAlign(cursor);
  final children = <FlatContentNode>[];

  while (!cursor.isEnd && !_endsCell.contains(cursor.peek)) {
    final before = cursor.position;
    final content = parseFlatContentNode(cursor, TextPlace.tableCell);
    if (content != null) children.add(content);
    assert(
      cursor.position > before,
      'cell content parse made no progress at ${cursor.position}',
    );
  }

  return TableCellNode(children: children, align: align);
}
