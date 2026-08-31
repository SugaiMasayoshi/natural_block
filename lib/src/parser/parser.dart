import '../node.dart';
import 'decoration_parser.dart';
import 'layout_symbol.dart';
import 'literal_scanner.dart';

/// Turns a NaturalBlock source string into a tree of [NaturalBlockNode]s.
///
/// This is the package's main entry point: it drives the top-level layout
/// scan (splitting on `|` and `=`) and delegates each resulting line to
/// [parseDecoratedLine] for inline decoration parsing.
class NaturalBlockParser {
  NaturalBlockParser();

  /// Parses [source] into a [ColumnNode] tree.
  ///
  /// `|` marks a Column separator and `=` marks a Row separator. The scan
  /// walks [source] left to right, splitting it into blocks at each `|` or
  /// `=`; a block bordered by two Row separators (or by one Row separator
  /// and the start/end of a Column) becomes one cell of a row, while every
  /// other block becomes a direct child of the enclosing column.
  ///
  /// Each block is then split into lines, and a single leading or trailing
  /// empty line is dropped -- this lets a block's opening/closing symbol sit
  /// on its own line in the source without producing a spurious blank
  /// [TextNode], while still preserving genuine blank lines in the middle of
  /// a block.
  ///
  /// The output shape for rows: a run of cells separated by `=` is collected
  /// into a single [RowNode], with each cell wrapped in a [ColumnNode]
  /// holding that cell's lines. The row is emitted as one node as soon as
  /// the run of `=`-joined cells ends, so `a=b|c=d` produces two RowNodes,
  /// not one four-cell row.
  ColumnNode parse(String source) {
    final scanner = LiteralScanner(source.trim());
    final children = <NaturalBlockNode>[];
    var currentRow = <ColumnNode>[];
    var hasPendingBlock = false;

    void flushRow() {
      if (currentRow.isNotEmpty) {
        children.add(RowNode(children: currentRow));
        currentRow = [];
      }
    }

    // An empty block is treated differently depending on which kind it is,
    // and the difference is deliberate rather than an artifact of `add` vs
    // `addAll`:
    //
    // - A Column block is *content*. Nothing in it means nothing to show, so
    //   it contributes no node at all (`左||右` yields two text nodes, not
    //   three).
    // - A Row cell is a *position*. The surrounding cells are laid out
    //   relative to it, so the cell survives even when blank -- that is what
    //   lets `左==右` mean "three cells, middle one empty". Dropping empty
    //   cells would make `左=右` and `左==右` indistinguishable and leave no
    //   way to write a deliberately blank cell.
    //
    // Note the cell is emitted as an empty ColumnNode (`children: []`)
    // rather than holding a placeholder empty TextNode: "a cell exists with
    // no content" is what the source actually says, whereas an empty
    // TextNode would additionally claim the cell contains one blank line.
    void emitBlock(String text, LayoutSymbol? endedBy) {
      final lines = _parseBlock(text);
      if (currentRow.isNotEmpty || endedBy == LayoutSymbol.row) {
        currentRow.add(ColumnNode(children: lines));
        if (endedBy != LayoutSymbol.row) flushRow();
      } else {
        children.addAll(lines);
      }
    }

    while (!scanner.isEnd) {
      hasPendingBlock = true;
      final symbol = LayoutSymbol.byChar[scanner.readChar()];
      if (symbol == null) continue;
      if (scanner.lastWasEscaped) {
        scanner.dropPrecedingChar();
        continue;
      }
      emitBlock(scanner.consume(), symbol);
      hasPendingBlock = false;
    }
    if (hasPendingBlock) emitBlock(scanner.flushRemaining(), null);
    flushRow();

    return ColumnNode(children: children);
  }

  List<ContentNode> _parseBlock(String blockText) {
    final lines = blockText.split('\n');

    if (lines.firstOrNull == '') lines.removeAt(0);
    if (lines.lastOrNull == '') lines.removeLast();

    return lines.map(parseDecoratedLine).toList();
  }
}
