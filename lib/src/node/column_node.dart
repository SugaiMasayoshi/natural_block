part of '../node.dart';

final class ColumnNode extends LayoutNode {
  final List<ContentNode> children;

  /// The alignment written for this block, or `unstated` when none was.
  ///
  /// Unstated is not [HorizontalAlign.start]. Inside a table only a cell that stated
  /// nothing inherits its column's alignment, and a renderer is free to draw
  /// an unstated block differently from one that asked for the start.
  final HorizontalAlign align;

  ColumnNode({this.children = const [], this.align = HorizontalAlign.unstated});

  /// Reads one cell or block: everything up to the next `|` or `^`, which it
  /// leaves for whoever those belong to -- `^` divides cells and is the
  /// row's, `|` divides blocks and is the document's or the table's.
  ///
  /// Decides only what kind of child comes next, by looking at the cursor.
  /// Each child reads itself and stops before anything that is not its own.
  static ColumnNode _parse(SourceCursor cursor, HorizontalAlign align) {
    // The newline against a boundary belongs to the boundary; see the rule
    // in `node.dart`. This is the block's own start, not the separator's --
    // a document beginning with a newline drops it too, and there is no
    // separator there at all.
    if (cursor.peek == '\n') cursor.take();

    final content = <ContentNode>[];

    // Reads straight through a `~`: a table is content, so it belongs to
    // this block rather than ending it.
    while (!cursor.isEnd && !separators.contains(cursor.peek)) {
      final before = cursor.position;
      final piece = ContentNode._parse(cursor);
      if (piece != null) content.add(piece);
      assert(
        cursor.position > before,
        'content parse made no progress at ${cursor.position}',
      );
    }

    return ColumnNode(children: content, align: align);
  }

  @override
  String toString() => 'ColumnNode(children: $children, align: $align)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColumnNode &&
        align == other.align &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, align, _childrenEquality.hash(children));
}
