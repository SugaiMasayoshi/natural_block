part of '../node.dart';

/// One row of a table.
///
/// Not a [RowNode]. Both hold cells written across, but a `RowNode` divides
/// the width it is given between them while these line up with the rows
/// above and below -- different enough that the renderer never treats one as
/// the other. Its own type also keeps a table from holding anything but
/// rows, and a row anything but cells.
///
/// In no sealed group, because nothing ever chooses: a table's children are
/// always rows, and a row's are always cells.
final class TableRowNode extends NaturalBlockNode {
  final List<TableCellNode> children;

  TableRowNode({this.children = const []});

  /// Reads one row, including the `|` that opened it.
  ///
  /// A table's `|` always opens a row, so a lone cell is a row of one --
  /// the only thing a table reads differently from a document, where the
  /// same text would stay a column.
  ///
  /// Null when the row had nothing in it, which is what lets every row be
  /// written with a leading `|`.
  static TableRowNode? _parse(SourceCursor cursor) {
    final align = cursor.peek == columnSymbol
        ? BlockAlign._takeSeparator(cursor)
        : null;

    final cells = [TableCellNode._parse(cursor, align)];
    while (cursor.peek == rowSymbol) {
      // The cell this `^` opens is read whatever follows, the end of the
      // table included. An empty cell is a position the grid keeps.
      cells.add(
        TableCellNode._parse(cursor, BlockAlign._takeSeparator(cursor)),
      );
    }

    if (cells.length == 1 && cells.single.children.isEmpty) return null;
    return TableRowNode(children: cells);
  }

  @override
  String toString() => 'TableRowNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableRowNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}
