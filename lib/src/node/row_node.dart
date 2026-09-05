part of '../node.dart';

final class RowNode extends BlockNode {
  final List<ColumnNode> children;

  RowNode({this.children = const []});

  /// Continues a block that turned out to be a row, given the cell already
  /// read. Null when it was not one: a row is a block that read a `=`.
  ///
  /// Each `=` is consumed because it is the row's own; the `|` that ends the
  /// row is left for whoever arranges blocks.
  static RowNode? _parse(Scanner scanner, ColumnNode first) {
    if (scanner.layoutSymbol != LayoutSymbol.row) return null;

    final cells = [first];
    while (scanner.layoutSymbol == LayoutSymbol.row) {
      // The cell this `=` opens is read whatever follows, the end of the
      // source included. An empty cell is a position the layout keeps, and
      // the row must not mean one thing at the end of a document and
      // another with a character after it -- which is what a reader would
      // watch happen as they typed past it.
      final align = scanner.takeSeparator();
      cells.add(ColumnNode._parse(scanner, align));
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
