// 【解説】[読む順 16/23] 表のセル = 寄せ + 中身。列(10番)とほぼ同じ。
// 【解説】
// 【解説】 違いは中身の振り分け。セルは表の分岐がない 17番を使い、型も
// 【解説】 FlatContentNode しか持てないので、表は入れ子にならない。~ でも止まる
// 【解説】 (_endsCell)のは、表の終わりがセルの終わりでもあるから。
// 【解説】 改行の扱いは列(10番)と同じ。
// 【解説】 次: src/parse/flat_content_node.dart
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
