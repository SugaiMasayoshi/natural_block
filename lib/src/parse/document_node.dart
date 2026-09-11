library;

import '../layout_symbols.dart';
import '../nodes.dart';
import '../source_cursor.dart';
import 'layout_node.dart';

abstract final class NaturalBlockParser {
  static DocumentNode parse(String source) {
    final cursor = SourceCursor(source);
    final children = <LayoutNode>[];

    while (!cursor.isEnd) {
      final before = cursor.position;
      // The `|` between blocks is the document's: it separates its children.
      if (cursor.peek == columnSymbol) cursor.take();
      final block = parseLayoutNode(cursor);
      if (block != null) children.add(block);
      assert(
        cursor.position > before,
        'block parse made no progress at ${cursor.position}',
      );
    }

    return DocumentNode(children: children);
  }
}
