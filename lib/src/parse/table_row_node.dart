// 【解説】[読む順 15/23] 表の1行。セルの間の ^ を食べる。
// 【解説】
// 【解説】 セルが1つだけで空なら行にしない。各行の先頭に | を書けるのはこのため
// 【解説】 (最初の | の前の空の行が消える)。
// 【解説】 次: src/parse/table_cell_node.dart
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'table_cell_node.dart';

TableRowNode? parseTableRowNode(SourceCursor cursor) {
  final cells = [parseTableCellNode(cursor)];
  while (cursor.peek == rowChar) {
    cursor.take();
    cells.add(parseTableCellNode(cursor));
  }

  if (cells.length == 1 && cells.single.children.isEmpty) return null;
  return TableRowNode(children: cells);
}
