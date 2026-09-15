// 【解説】[読む順 9/23] ブロックが列か行かを決める。
// 【解説】
// 【解説】 まず列として読み、止まった先が ^ なら、読んだ列を行の最初のセルにして
// 【解説】 行として続ける。後から来た記号が、前に読んだものの形を変えるのは
// 【解説】 ここだけ(README の「| は手前のブロックを終わらせる」はここから来る)。
// 【解説】 中身のない列は null。空のブロックは何も残さない。
// 【解説】 次: src/parse/column_node.dart
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'column_node.dart';
import 'row_node.dart';

LayoutNode? parseLayoutNode(SourceCursor cursor) {
  final first = parseColumnNode(cursor);
  if (cursor.peek == rowChar) return parseRowNode(cursor, first);

  return first.children.isEmpty ? null : first;
}
