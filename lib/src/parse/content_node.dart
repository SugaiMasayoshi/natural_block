// 【解説】[読む順 13/23] 列の中身の振り分け。
// 【解説】
// 【解説】 ~ なら表、それ以外は FlatContentNode の振り分け(17番)に任せる。
// 【解説】 セルは表の分岐がない 17番を直接使う。
// 【解説】 次: src/parse/table_node.dart
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'flat_content_node.dart';
import 'table_node.dart';

ContentNode? parseContentNode(SourceCursor cursor) {
  if (cursor.peek == tableChar) return parseTableNode(cursor);
  return parseFlatContentNode(cursor);
}
