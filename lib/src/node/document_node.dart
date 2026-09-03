part of '../node.dart';

final class DocumentNode extends NaturalBlockNode {
  final List<BlockNode> children;

  DocumentNode({this.children = const []});

  static DocumentNode parse(String source) {
    final text = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final scanner = Scanner(text, symbols: LayoutSymbol.byChar.keys.toSet());
    final document = _Document();
    BlockAlign? pendingAlign;

    while (true) {
      final scanned = scanner.read();
      document.addBlock(
        ColumnNode._parseLines(scanned.text),
        align: pendingAlign,
        endsRow: LayoutSymbol.byChar[scanned.symbol] == LayoutSymbol.row,
      );
      pendingAlign = null;
      if (scanned.symbol == null) break;

      final cluster = readMarkerCluster(
        text,
        scanner.position,
        allowTable:
            LayoutSymbol.byChar[scanned.symbol] == LayoutSymbol.column,
      );
      scanner.skipTo(cluster.end);

      if (cluster.togglesTable) {
        if (document.inTable) {
          document.closeTable();
          pendingAlign = cluster.align;
        } else {
          document.openTable(cluster.align ?? BlockAlign.start);
        }
      } else {
        pendingAlign = cluster.align;
      }

      if (scanner.isEnd) break;
    }

    return document.finish();
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
  int get hashCode => Object.hash(runtimeType, _childrenEquality.hash(children));
}

class _Document {
  final List<BlockNode> _children = [];
  List<_PendingCell> _row = [];
  _OpenTable? _table;

  bool get inTable => _table != null;

  void openTable(BlockAlign align) => _table = _OpenTable(align);

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
      _row.add(_PendingCell(lines: lines, statedAlign: align));
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
    _children.add(RowNode._fromCells(cells));
  }
}
