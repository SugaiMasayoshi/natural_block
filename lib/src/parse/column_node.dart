// 【解説】[読む順 10/23] 列(ブロック)= 始まりの寄せ + 中身。
// 【解説】
// 【解説】 中身は | か ^ か文書の終わりまで(layoutChars で止まる)。
// 【解説】 ~ ではここは止まらない。表はブロックの中身として 13番が読む。
// 【解説】 始まりと、中身1つのあとに改行を1つ食べる。境界に接した改行は文字では
// 【解説】 なく境界のもので、run(21番)はその手前で止まってここに任せる。
// 【解説】 セル(16番)も同じ形で、違うのは止まる文字と振り分けだけ。
// 【解説】 次: src/parse/align.dart
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'align.dart';
import 'content_node.dart';

ColumnNode parseColumnNode(SourceCursor cursor) {
  final align = parseAlign(cursor);
  final children = <ContentNode>[];
  if (cursor.peek == '\n') cursor.take();

  while (!cursor.isEnd && !layoutChars.contains(cursor.peek)) {
    final before = cursor.position;
    final content = parseContentNode(cursor);
    if (content != null) children.add(content);
    if (cursor.peek == '\n') cursor.take();
    assert(
      cursor.position > before,
      'column content parse made no progress at ${cursor.position}',
    );
  }

  return ColumnNode(children: children, align: align);
}
