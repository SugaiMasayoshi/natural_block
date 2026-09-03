part of '../node.dart';

final class RowNode extends BlockNode {
  final List<ColumnNode> children;

  RowNode({this.children = const []});

  static List<_Piece>? _splitCells(
    String text, {
    required BlockAlign? align,
    required bool isLast,
  }) {
    final cells = _splitPieces(text, LayoutSymbol.row, allowTable: false);
    if (cells.length == 1) return null;

    if (isLast && cells.last.text.isEmpty && cells.last.align == null) {
      cells.removeLast();
    }

    if (align != null) {
      cells[0] = _Piece(text: cells[0].text, align: align);
    }
    return cells;
  }

  static ColumnNode _cell(_Piece piece, BlockAlign inherited) => ColumnNode(
    children: ColumnNode._parseLines(piece.text),
    align: piece.align ?? inherited,
  );

  static RowNode _fromCells(List<_Piece> cells) => RowNode(
    children: [for (final cell in cells) _cell(cell, BlockAlign.start)],
  );

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
