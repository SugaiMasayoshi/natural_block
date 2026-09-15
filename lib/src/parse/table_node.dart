// 【解説】[読む順 14/23] 表。
// 【解説】
// 【解説】 開きと閉じの ~ を両方自分で食べる(囲みは包むもの自身が持つ)。
// 【解説】 行の間の | も表が食べる。閉じの ~ がなければ文書の終わりまで表。
// 【解説】 開きの ~ の直後は最初のセルの始まりなので、寄せはセルが読む。
// 【解説】 次: src/parse/table_row_node.dart
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'table_row_node.dart';

TableNode? parseTableNode(SourceCursor cursor) {
  cursor.take();

  final rows = <TableRowNode>[];

  while (!cursor.isEnd && cursor.peek != tableChar) {
    final before = cursor.position;
    if (cursor.peek == columnChar) cursor.take();
    final row = parseTableRowNode(cursor);
    if (row != null) rows.add(row);
    assert(
      cursor.position > before,
      'table row parse made no progress at ${cursor.position}',
    );
  }
  if (cursor.peek == tableChar) cursor.take();

  if (rows.isEmpty) return null;
  return TableNode(children: rows);
}
