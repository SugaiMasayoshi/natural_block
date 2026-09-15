// 【解説】[読む順 17/23] 表以外の中身(FlatContentNode)の振り分け。
// 【解説】
// 【解説】 行頭のフェンスならraw ブロック、それ以外は文章。表の分岐がないので、
// 【解説】 これで読むセルの中に表は作られない。型も FlatContentNode なので、
// 【解説】 手で組んでも入れ子にはできない。列の中身(13番)は、表の分岐を足して
// 【解説】 からこれを呼ぶ。
// 【解説】 次: src/parse/raw.dart
import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'raw.dart';
import 'text_node.dart';

FlatContentNode? parseFlatContentNode(SourceCursor cursor) {
  if (cursor.peek == rawChar && cursor.atLineStart) return parseRawNode(cursor);

  final text = parseTextNode(cursor);
  return text.children.isEmpty ? null : text;
}
