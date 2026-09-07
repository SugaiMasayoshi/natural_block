part of '../node.dart';

final class DocumentNode extends NaturalBlockNode {
  final List<LayoutNode> children;

  DocumentNode({this.children = const []});

  static DocumentNode _parse(String source) {
    final cursor = SourceCursor(source);
    final children = <LayoutNode>[];

    // Nothing to arrange but the blocks themselves: each reads the `|` that
    // opened it, and a separator at the very end needs no special case
    // because the block it opens is empty and contributes no node.
    while (!cursor.isEnd) {
      final before = cursor.position;
      final block = LayoutNode._parse(cursor);
      if (block != null) children.add(block);
      assert(
        cursor.position > before,
        'block parse made no progress at ${cursor.position}',
      );
    }

    return DocumentNode(children: children);
  }

  @override
  String toString() => 'DocumentNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}
