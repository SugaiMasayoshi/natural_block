part of '../node.dart';

final class DocumentNode extends NaturalBlockNode {
  final List<BlockNode> children;

  DocumentNode({this.children = const []});

  static DocumentNode _parse(String source) {
    final cursor = SourceCursor(source);
    final children = <BlockNode>[];

    // The first block is opened by the start of the source, not by a
    // separator, so it carries no markers.
    BlockAlign? align;

    // A separator at the very end of the source needs no special case: the
    // block it opens is empty, and an empty Column block contributes no
    // node.
    while (true) {
      final before = cursor.position;
      final block = BlockNode._parse(cursor, align);
      if (block != null) children.add(block);

      if (cursor.isEnd) break;

      // Only `|` separates blocks here. A `~` is the table's own and was
      // eaten by it, so after a table the cursor is on ordinary text and
      // there is nothing to consume -- and nothing to state markers about.
      align = cursor.peek == columnSymbol
          ? BlockNode._takeSeparator(cursor)
          : null;

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
