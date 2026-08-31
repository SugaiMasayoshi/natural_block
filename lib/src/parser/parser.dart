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
  /// The output convention for rows is important: the parser never emits a
  /// single node that holds every cell of a row. Instead, it emits one
  /// [RowNode] per cell, and it is *consecutive* [RowNode] siblings in the
  /// resulting children list that together represent one visual row --
  /// consumers are expected to group them back up when rendering.
  ColumnNode parse(String source) {
    final scanner = LiteralScanner(source.trim());
    final children = <NaturalBlockNode>[];
    LayoutSymbol? previousSymbol;
    var hasPendingBlock = false;

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
    // Note the RowNode is emitted empty (`children: []`) rather than holding
    // a placeholder empty TextNode: "a cell exists with no content" is what
    // the source actually says, whereas an empty TextNode would additionally
    // claim the cell contains one blank line.
    void emitBlock(String text, LayoutSymbol? endedBy) {
      final contentNodes = _parseBlock(text);
      final belongsToRow =
          previousSymbol == LayoutSymbol.row || endedBy == LayoutSymbol.row;
      if (belongsToRow) {
        children.add(RowNode(children: contentNodes));
      } else {
        children.addAll(contentNodes);
      }
      previousSymbol = endedBy;
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

    return ColumnNode(children: children);
  }

  List<ContentNode> _parseBlock(String blockText) {
    final lines = blockText.split('\n');

    if (lines.firstOrNull == '') lines.removeAt(0);
    if (lines.lastOrNull == '') lines.removeLast();

    return lines.map(parseDecoratedLine).toList();
  }
}
