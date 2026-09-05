part of '../node.dart';

final class RowNode extends BlockNode {
  final List<ColumnNode> children;

  RowNode({this.children = const []});

  /// Reads one row of a table.
  ///
  /// The same reading a block outside a table gets, differing in one thing:
  /// what a block that read no `^` becomes. Out there it stays a column;
  /// here every `|` opens a row, so a lone cell is a row of one.
  ///
  /// It goes through here rather than through [BlockNode._parse] because a
  /// `~` met while reading a table is the one that ends it, never one that
  /// opens another -- and a row really can start with `~`, as in
  /// `|~a^b|~e`.
  ///
  /// Null when the row had nothing in it.
  static RowNode? _parseInTable(SourceCursor cursor, BlockAlign? align) {
    final first = ColumnNode._parse(cursor, align);
    final row = _parse(cursor, first);
    if (row != null) return row;

    return first.children.isEmpty ? null : RowNode(children: [first]);
  }

  /// Continues a block that turned out to be a row, given the cell already
  /// read. Null when it was not one: a row is a block that read a `^`.
  ///
  /// Each `^` is consumed because it is the row's own; the `|` that ends the
  /// row is left for whoever arranges blocks.
  static RowNode? _parse(SourceCursor cursor, ColumnNode first) {
    if (cursor.peek != rowSymbol) return null;

    final cells = [first];
    while (cursor.peek == rowSymbol) {
      // The cell this `^` opens is read whatever follows, the end of the
      // source included. An empty cell is a position the layout keeps, and
      // the row must not mean one thing at the end of a document and
      // another with a character after it -- which is what a reader would
      // watch happen as they typed past it.
      final align = BlockNode._takeSeparator(cursor);
      cells.add(ColumnNode._parse(cursor, align));
    }
    return RowNode(children: cells);
  }

  @override
  String toString() => 'RowNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RowNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}
