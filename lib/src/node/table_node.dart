part of '../node.dart';

final class TableNode extends BlockNode {
  final List<RowNode> children;
  final BlockAlign align;

  TableNode({this.children = const [], this.align = BlockAlign.start});

  @override
  String toString() => 'TableNode(children: $children, align: $align)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableNode &&
        align == other.align &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, align, _childrenEquality.hash(children));
}

class _OpenTable {
  final BlockAlign align;
  final List<RowNode> _rows = [];
  List<BlockAlign>? _columnAligns;

  _OpenTable(this.align);

  bool accepts(int cellCount) =>
      _columnAligns == null || cellCount == _columnAligns!.length;

  void add(List<_PendingCell> cells) {
    final aligns = _columnAligns ??= [
      for (final cell in cells) cell.statedAlign ?? BlockAlign.start,
    ];
    _rows.add(
      RowNode(
        children: [
          for (var i = 0; i < cells.length; i++) cells[i].resolve(aligns[i]),
        ],
      ),
    );
  }

  TableNode? close() =>
      _rows.isEmpty ? null : TableNode(children: _rows, align: align);
}
