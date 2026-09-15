// 【解説】[読む順 19/23] 文章 = インライン(文字の run と文中のraw 区間)の並び。
// 【解説】
// 【解説】 装飾の状態を run から run へ引き継ぎ、進まなくなったら終わる。
// 【解説】 何行あっても1つの TextNode。改行は中の文字で、木に行の構造はない。
// 【解説】 次: src/parse/inline_node.dart
import '../nodes.dart';
import '../source_cursor.dart';
import '../span_decoration.dart';
import 'inline_node.dart';

TextNode parseTextNode(SourceCursor cursor) {
  final children = <InlineNode>[];
  var style = const SpanDecoration();

  while (true) {
    final before = cursor.position;
    final (node, next) = parseInlineNode(cursor, style);
    style = next;
    if (node != null) children.add(node);
    if (cursor.position == before) break;
  }

  return TextNode(children: children);
}
