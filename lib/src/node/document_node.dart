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

    // `~` separates table regions from ordinary ones, so eating one flips
    // which of the two the next run is. This is the only place that `~` is
    // consumed: a table stops in front of the one that ends it, exactly as
    // a row stops in front of the `|` that ends it.
    var inTable = false;

    // A separator at the very end of the source needs no special case: the
    // block it opens is empty, and an empty Column block contributes no
    // node.
    while (true) {
      // A table is a block, so the two readings differ only in which one is
      // asked -- not in what is done with the answer.
      final block = inTable
          ? TableNode._parse(cursor, align)
          : BlockNode._parse(cursor, align);
      if (block != null) children.add(block);

      if (cursor.isEnd) break;
      if (cursor.peek == tableSymbol) {
        inTable = !inTable;
      }
      align = BlockNode._takeSeparator(cursor);
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
