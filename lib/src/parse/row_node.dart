// 【解説】[読む順 12/23] 行 = ^ で区切られた列(セル)の並び。
// 【解説】
// 【解説】 セルの間の ^ は行が食べる。最初のセルは 9番で読まれて渡される。
// 【解説】 空のセルも位置として残る。左^^右 で右が端に寄るのはこのため。
// 【解説】 次: src/parse/content_node.dart
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'column_node.dart';

RowNode parseRowNode(SourceCursor cursor, ColumnNode first) {
  final cells = [first];
  while (cursor.peek == rowChar) {
    cursor.take();
    cells.add(parseColumnNode(cursor));
  }
  return RowNode(children: cells);
}
