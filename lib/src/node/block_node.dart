part of '../node.dart';

sealed class BlockNode extends NaturalBlockNode {
  static List<BlockNode> _parseAll(List<_Piece> pieces) {
    final children = <BlockNode>[];
    _OpenTable? table;

    void closeTable() {
      final node = table?.close();
      if (node != null) children.add(node);
      table = null;
    }

    for (var index = 0; index < pieces.length; index++) {
      final piece = pieces[index];
      var align = piece.align;

      if (piece.togglesTable) {
        if (table != null) {
          closeTable();
        } else {
          table = _OpenTable(align ?? BlockAlign.start);
          align = null;
        }
      }

      final cells = RowNode._splitCells(
        piece.text,
        align: align,
        isLast: index == pieces.length - 1,
      );
      if (cells != null) {
        final open = table;
        if (open != null && open.accepts(cells.length)) {
          open.add(cells);
        } else {
          closeTable();
          children.add(RowNode._fromCells(cells));
        }
        continue;
      }

      final lines = ColumnNode._parseLines(piece.text);
      if (lines.isEmpty) continue;

      closeTable();
      if (align != null) {
        children.add(ColumnNode(children: lines, align: align));
      } else {
        children.addAll(lines);
      }
    }

    closeTable();
    return children;
  }
}

class _Piece {
  final String text;
  final BlockAlign? align;
  final bool togglesTable;

  const _Piece({required this.text, this.align, this.togglesTable = false});
}

List<_Piece> _splitPieces(
  String source,
  LayoutSymbol symbol, {
  required bool allowTable,
}) {
  final scanner = Scanner(source, symbols: {symbol.char});
  final pieces = <_Piece>[];
  BlockAlign? align;
  var togglesTable = false;

  while (true) {
    final scanned = scanner.read();
    pieces.add(
      _Piece(text: scanned.text, align: align, togglesTable: togglesTable),
    );
    if (scanned.symbol == null) break;

    final cluster = readMarkerCluster(
      source,
      scanner.position,
      allowTable: allowTable,
    );
    scanner.skipTo(cluster.end);
    align = cluster.align;
    togglesTable = cluster.togglesTable;
  }

  return pieces;
}
