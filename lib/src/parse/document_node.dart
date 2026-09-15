// 【解説】[読む順 8/23] 読み取りの入口。NaturalBlockParser.parse。
// 【解説】
// 【解説】 文書はブロック(LayoutNode)の並び。ブロックの間の | は文書が食べる
// 【解説】 (区切りは、それが分ける子たちの親が食べる)。
// 【解説】 全ての parse は「自分のものでない記号の手前で止まる」。子が止まった
// 【解説】 位置を親が見て、次に何をするかを決める。assert は進まないループの検出。
// 【解説】 次: src/parse/layout_node.dart
library;

import '../markup.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'layout_node.dart';

abstract final class NaturalBlockParser {
  static DocumentNode parse(String source) {
    final cursor = SourceCursor(source);
    final children = <LayoutNode>[];

    while (!cursor.isEnd) {
      final before = cursor.position;
      if (cursor.peek == columnChar) cursor.take();
      final layout = parseLayoutNode(cursor);
      if (layout != null) children.add(layout);
      assert(
        cursor.position > before,
        'layout parse made no progress at ${cursor.position}',
      );
    }

    return DocumentNode(children: children);
  }
}
