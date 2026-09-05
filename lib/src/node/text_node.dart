part of '../node.dart';

final class TextNode extends ContentNode {
  final List<InlineNode> children;

  TextNode({this.children = const []});

  /// Reads one run of inline content, stopping in front of anything that is
  /// not its own: a separator that belongs to the block, or a verbatim
  /// region written on a line of its own.
  ///
  /// Neither is consumed. A node never eats what belongs to something else,
  /// so the caller can look at the cursor and decide what comes next.
  static TextNode _parse(SourceCursor cursor) {
    final children = <InlineNode>[];
    var style = const _Decoration();

    while (!cursor.isEnd &&
        !cursor.atBlockRegion &&
        cursor.layoutSymbol == null) {
      final before = cursor.position;
      final (node, next) = InlineNode._parse(cursor, style);
      style = next;
      if (node != null) children.add(node);
      // A child that reads nothing where the loop expects content would spin
      // here forever. The mistake is silent otherwise -- it hangs rather
      // than producing a wrong tree -- so it is worth saying out loud.
      assert(
        cursor.position > before,
        'inline parse made no progress at ${cursor.position}',
      );
    }

    return TextNode(children: children);
  }

  @override
  String toString() => 'TextNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}
