import '../block_align.dart';
import '../node.dart';

class PendingCell {
  final List<TextNode> lines;
  final BlockAlign? statedAlign;

  const PendingCell({required this.lines, required this.statedAlign});

  ColumnNode resolve(BlockAlign inherited) =>
      ColumnNode(children: lines, align: statedAlign ?? inherited);
}

class TableAssembler {
  final BlockAlign align;

  final List<RowNode> _rows = [];

  List<BlockAlign>? _columnAligns;

  TableAssembler(this.align);

  bool accepts(int cellCount) =>
      _columnAligns == null || cellCount == _columnAligns!.length;

  void add(List<PendingCell> cells) {
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

class DocumentAssembler {
  final List<BlockNode> _children = [];

  List<PendingCell> _row = [];

  TableAssembler? _table;

  bool get inTable => _table != null;

  void openTable(BlockAlign align) => _table = TableAssembler(align);

  void closeTable() {
    final node = _table?.close();
    if (node != null) _children.add(node);
    _table = null;
  }

  void addBlock(
    List<TextNode> lines, {
    BlockAlign? align,
    required bool endsRow,
  }) {
    if (_row.isNotEmpty || endsRow) {
      _row.add(PendingCell(lines: lines, statedAlign: align));
      if (!endsRow) _flushRow();
      return;
    }

    if (lines.isEmpty) return;

    closeTable();
    if (align != null) {
      _children.add(ColumnNode(children: lines, align: align));
    } else {
      _children.addAll(lines);
    }
  }

  DocumentNode finish() {
    _flushRow();
    closeTable();
    return DocumentNode(children: _children);
  }

  void _flushRow() {
    if (_row.isEmpty) return;
    final cells = _row;
    _row = [];

    final table = _table;
    if (table != null && table.accepts(cells.length)) {
      table.add(cells);
      return;
    }
    closeTable();
    _children.add(
      RowNode(
        children: [for (final cell in cells) cell.resolve(BlockAlign.start)],
      ),
    );
  }
}
