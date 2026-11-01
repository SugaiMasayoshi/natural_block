library;

import '../nodes.dart';
import '../source_cursor.dart';
import 'layout_node.dart';

abstract final class NaturalBlockParser {
  static DocumentNode parse(String source) {
    final cursor = SourceCursor(source);
    final children = <LayoutNode>[];

    while (!cursor.isEnd) {
      final before = cursor.position;
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
