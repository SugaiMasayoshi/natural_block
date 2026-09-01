// 【解説】[9/16] パーサ本体。ここが全体を駆動する入口。
// 【解説】
// 【解説】 やっていることは単純で、| と = でソースを塊に割り、各塊を行に分け、
// 【解説】 各行を decoration_parser に渡すだけ。難しいのは「行」の組み立て方。
// 【解説】
// 【解説】 currentRow に = で繋がったセルを溜め、= の連なりが切れた瞬間に
// 【解説】 flushRow() で1つの RowNode として吐き出す。だから a=b|c=d は|c=d は
// 【解説】 2つの RowNode になる(1つの4セル行にならない)。
// 【解説】
// 【解説】 emitBlock の上にある長いコメントが、この言語の設計の要。
// 【解説】 「Columnブロックは内容、Rowセルは位置」という非対称が意図的で、
// 【解説】 それが 左==右 を「3セルで真ん中が空」と読ませている。空セルを捨てると
// 【解説】 左=右 と 左==右 が区別できなくなる。
// 【解説】
// 【解説】 寄せマーカー(< ^ >)は「記号として認識された | = の直後」でだけ読む。
// 【解説】 だから \= のようにエスケープされた区切りの後ろの > は素通しになる。
// 【解説】 特別扱いのコードは無く、ループがその地点に到達しないだけ、という作り。
// 【解説】 → ここは今後 |~（表の宣言）を足すなら手を入れる場所でもある。
// 【解説】 次: natural_block_flutter 側へ。lib/natural_block_flutter.dart

import '../block_align.dart';
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

  /// Parses [source] into a [DocumentNode] tree.
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
  ///
  /// An alignment marker -- `<` (start), `^` (center), or `>` (end) -- may
  /// appear immediately after an unescaped `|` or `=`, configuring the
  /// [BlockAlign] of the block that starts there. That position is the
  /// entire trigger: anywhere else, `<`, `^`, and `>` are ordinary literal
  /// text (essential, since `a > b`, `->`, `=>`, and `List<String>` are
  /// everywhere in normal prose). The marker is only recognized right after
  /// a separator that was itself recognized as markup, so an escaped
  /// separator (`\=`) leaves a following `>` untouched as well, with no
  /// special-case needed -- the scan loop simply never reaches the
  /// marker-check when the separator itself was escaped. A row cell always
  /// carries a [BlockAlign] (defaulting to [BlockAlign.start] when no
  /// marker was given); a plain, non-row block is left as a bare list of
  /// lines unless a marker was given, in which case it is wrapped in a
  /// [ColumnNode] carrying that alignment.
  DocumentNode parse(String source) {
    final scanner = LiteralScanner(source.trim());
    final children = <BlockNode>[];
    var currentRow = <ColumnNode>[];
    var hasPendingBlock = false;
    BlockAlign? pendingAlign;

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
      final align = pendingAlign;
      pendingAlign = null;
      if (currentRow.isNotEmpty || endedBy == LayoutSymbol.row) {
        currentRow.add(
          ColumnNode(children: lines, align: align ?? BlockAlign.start),
        );
        if (endedBy != LayoutSymbol.row) flushRow();
      } else if (align != null) {
        children.add(ColumnNode(children: lines, align: align));
      } else {
        children.addAll(lines);
      }
    }

    while (!scanner.isEnd) {
      hasPendingBlock = true;
      final char = scanner.readChar();

      // The same escape rule the decoration parser uses, with this level's
      // own notion of what counts as markup: `|` and `=`. Drop the
      // backslash, then read the separator it escapes so it joins the
      // literal run instead of splitting a block.
      if (char == r'\' && LayoutSymbol.byChar.containsKey(scanner.peekNext)) {
        scanner.dropCurrentChar();
        scanner.readChar();
        continue;
      }

      final symbol = LayoutSymbol.byChar[char];
      if (symbol == null) continue;
      emitBlock(scanner.consume(), symbol);
      hasPendingBlock = false;

      final align = BlockAlign.byChar[scanner.peekNext];
      if (align != null) {
        scanner.readChar();
        scanner.markConsumed();
        pendingAlign = align;
      }
    }
    if (hasPendingBlock) emitBlock(scanner.flushRemaining(), null);
    flushRow();

    return DocumentNode(children: children);
  }

  List<TextNode> _parseBlock(String blockText) {
    final lines = blockText.split('\n');

    if (lines.firstOrNull == '') lines.removeAt(0);
    if (lines.lastOrNull == '') lines.removeLast();

    return lines.map(parseDecoratedLine).toList();
  }
}
