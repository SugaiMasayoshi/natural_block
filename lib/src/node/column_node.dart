part of '../node.dart';

final class ColumnNode extends BlockNode {
  final List<ContentNode> children;

  /// The alignment written for this block, or null when none was.
  ///
  /// Null is not [BlockAlign.start]. Inside a table only a cell that stated
  /// nothing inherits its column's alignment, and a renderer is free to draw
  /// an unstated block differently from one that asked for the start.
  final BlockAlign? align;

  ColumnNode({this.children = const [], this.align});

  /// Reads one cell or block: everything up to the next `|` or `=`, which it
  /// leaves for whoever those belong to -- `=` divides cells and is the
  /// row's, `|` divides blocks and is the document's or the table's.
  ///
  /// Decides only what kind of child comes next, by looking at the cursor.
  /// Each child reads itself and stops before anything that is not its own.
  static ColumnNode _parse(SourceCursor cursor, BlockAlign? align) {
    // A block drops one blank line at its start, which is what lets the
    // separator that opened it sit on a line of its own. The block's rule,
    // not the separator's: a document beginning with a newline drops it too,
    // and there is no separator there at all. (The matching newline at the
    // end is dropped by the run that holds it, where the text is.)
    if (cursor.peek == '\n') cursor.take();

    final content = <ContentNode>[];

    while (!cursor.isEnd && cursor.layoutSymbol == null) {
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
