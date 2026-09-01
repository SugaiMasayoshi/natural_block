// 【解説】[9/16] パーサ本体。ここが全体を駆動する入口。
// 【解説】
// 【解説】 やっていることは単純で、| と = でソースを塊に割り、各塊を行に分け、
// 【解説】 各行を decoration_parser に渡すだけ。難しいのは「行」の組み立て方。
// 【解説】
// 【解説】 currentRow に = で繋がったセルを溜め、= の連なりが切れた瞬間に
// 【解説】 flushRow() で1つの RowNode として吐き出す。だから a=b|c=d は
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
// 【解説】
// 【解説】 マーカーはクラスタとして読む。~ が表の開始/終了をトグルし、< ^ > は
// 【解説】 開かれるブロックの寄せを決める。だから |~^ は「中央寄せの表」になる。
// 【解説】 表の間は RowNode を tableRows に溜め、列数が変わる / 行以外が来る /
// 【解説】 もう一度 |~ が来る / 入力が終わる のいずれかで TableNode にして吐く。
// 【解説】 currentRowExplicit があるのは、寄せを「明示されたか」で区別するため。
// 【解説】 明示されなかったセルだけが列の寄せを継承する(align だけでは
// 【解説】 明示の < と既定値がどちらも start で区別できない)。
// 【解説】
// 【解説】 parse は static で、クラスは abstract final。状態を持たないのに
// 【解説】 インスタンスを作らせる形をやめた(NaturalBlockImages と同じ形)。
// 【解説】 入口で CRLF を LF に正規化しているのも要点。しないと「開き記号を
// 【解説】 単独行に置ける」規則が Windows で書かれた文書に効かなくなる。
// 【解説】 前後の空白を削るのに trim() を使っていないのは、全角スペースを
// 【解説】 消さないため。日本語の字下げを壊さないという判断。
// 【解説】 次: natural_block_flutter 側へ。lib/natural_block_flutter.dart

import '../block_align.dart';
import '../node.dart';
import 'block_marker.dart';
import 'decoration_parser.dart';
import 'layout_symbol.dart';
import 'literal_scanner.dart';

/// Turns a NaturalBlock source string into a tree of [NaturalBlockNode]s.
///
/// This is the package's main entry point: it drives the top-level layout
/// scan (splitting on `|` and `=`) and delegates each resulting line to
/// [parseDecoratedLine] for inline decoration parsing.
abstract final class NaturalBlockParser {
  /// Characters stripped from either end of a source before parsing.
  ///
  /// Deliberately *not* `String.trim`, which strips every Unicode space --
  /// including U+3000, the ideographic space Japanese prose indents with,
  /// and which this language explicitly means to carry unharmed. Only the
  /// ASCII whitespace that surrounds a document by accident is removed.
  static final RegExp _surroundingWhitespace = RegExp(r'^[ \t\r\n]+|[ \t\r\n]+$');

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
  ///
  /// Markers are read as a cluster, so one separator can carry more than
  /// one: `~` ([BlockMarker.table]) declares that the block opening here is
  /// a table and the run of rows that follows belongs to it, while an
  /// alignment character says how that block sits -- `|~^` is a centered
  /// table. Writing `~` again closes the table; the alignment in *that*
  /// cluster belongs to the block being opened after it, not to the table
  /// that just ended.
  ///
  /// A table also ends on its own at the first thing that cannot belong to
  /// it: a row of a different cell count, anything that is not a row, or
  /// the end of the source. An *empty* block is not such a thing -- it
  /// contributes no node at all, so letting one close a table would make
  /// `||` an invisible separator.
  ///
  /// Because `~` toggles, a `|~` written *after* something already ended
  /// the table opens a new one rather than closing anything. That is the
  /// right reading for the document people write -- "table, note, table"
  /// wants the second `|~` to start a second table, and it does -- and it
  /// is the same property the decoration symbols have, where `:!` turns
  /// danger on when it is already off. A table that is never given a row
  /// contributes no node, so a redundant close is harmless on its own. Inside a table, a cell that carries no
  /// alignment marker of its own inherits its column's alignment from the
  /// first row, which is why the parser tracks whether each cell's
  /// alignment was stated rather than defaulted.
  static DocumentNode parse(String source) {
    // CRLF is normalized before anything looks at the text. `_parseBlock`
    // splits on `\n` and then compares lines against `''` to drop a single
    // blank one at each end -- the rule that lets a block's opening symbol
    // sit on its own line. Under CRLF that leading line is `'\r'`, not
    // `''`, so the rule silently stops applying and every line keeps a
    // trailing `\r`. Any document written by a Windows editor is affected.
    final normalized = source
        .replaceAll('\r\n', '\n')
        .replaceAll(_surroundingWhitespace, '');
    final scanner = LiteralScanner(normalized);
    final children = <BlockNode>[];
    var currentRow = <ColumnNode>[];
    // Whether each cell of `currentRow` got its alignment from a marker of
    // its own, as opposed to falling back to the default. Only a cell that
    // said nothing inherits its column's alignment inside a table, so the
    // two cases have to stay distinguishable -- `ColumnNode.align` alone
    // cannot, since an explicit `<` and an unstated default are both
    // `BlockAlign.start`.
    var currentRowExplicit = <bool>[];
    var hasPendingBlock = false;
    BlockAlign? pendingAlign;

    // Table state. `columnAligns` is set from the first row and then serves
    // as both the alignment each column inherits and the cell count every
    // later row must match to stay part of the table.
    var inTable = false;
    var tableAlign = BlockAlign.start;
    var tableRows = <RowNode>[];
    List<BlockAlign>? columnAligns;

    void flushTable() {
      if (tableRows.isNotEmpty) {
        children.add(TableNode(children: tableRows, align: tableAlign));
        tableRows = [];
      }
      columnAligns = null;
      tableAlign = BlockAlign.start;
      inTable = false;
    }

    void flushRow() {
      if (currentRow.isEmpty) return;
      final cells = currentRow;
      final explicit = currentRowExplicit;
      currentRow = [];
      currentRowExplicit = [];

      if (!inTable) {
        children.add(RowNode(children: cells));
        return;
      }

      final aligns = columnAligns;
      if (aligns == null) {
        // The first row fixes the shape: how many columns the table has, and
        // what each of them is aligned as by default.
        columnAligns = [for (final cell in cells) cell.align];
        tableRows.add(RowNode(children: cells));
        return;
      }

      if (cells.length != aligns.length) {
        // A row of a different width cannot be part of the same table --
        // columns would have nothing to line up against, and the renderer's
        // Table requires every row to have the same number of cells. So the
        // table ends here and this row stands on its own.
        flushTable();
        children.add(RowNode(children: cells));
        return;
      }

      tableRows.add(
        RowNode(
          children: [
            for (var i = 0; i < cells.length; i++)
              if (explicit[i])
                cells[i]
              else
                ColumnNode(children: cells[i].children, align: aligns[i]),
          ],
        ),
      );
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
        currentRowExplicit.add(align != null);
        if (endedBy != LayoutSymbol.row) flushRow();
      } else if (lines.isEmpty) {
        // An empty Column block contributes no node at all, and a marker
        // does not change that: there is nothing inside to be aligned.
        // Without this, `a||b` gave two nodes but `a|>|b` gave three, the
        // middle one an empty ColumnNode -- contradicting the rule stated
        // just above. Note this branch comes first so it also keeps an
        // empty block from ending a table (see the next branch).
      } else if (align != null) {
        flushTable();
        children.add(ColumnNode(children: lines, align: align));
      } else {
        // Anything that is not a row ends the table -- a TableNode holds
        // rows, so there is nowhere for a paragraph to go inside one.
        // Reaching here means the block has content: an empty one was
        // already handled above, which is what keeps it from ending a
        // table. Otherwise `||` would be an invisible separator, silently
        // splitting a table in two on something the AST does not record.
        flushTable();
        children.addAll(lines);
      }
    }

    while (!scanner.isEnd) {
      hasPendingBlock = true;
      final char = scanner.readChar();

      // An escaped separator must not split a block -- but the backslash is
      // deliberately *kept* here rather than dropped, and both characters
      // are handed on as literal text.
      //
      // Escapes are resolved in exactly one place, [parseDecoratedLine],
      // which sees every character of every block. Dropping backslashes
      // here as well would mean two passes both rewriting the same text:
      // `\\` would be collapsed to `\` at this level, and the lone
      // backslash left behind would then be read as an escape again by the
      // next pass, silently eating whatever followed it. Deciding
      // boundaries here and resolving escapes there keeps each character
      // rewritten at most once.
      if (char == r'\' &&
          (LayoutSymbol.byChar.containsKey(scanner.peekNext) ||
              scanner.peekNext == r'\')) {
        scanner.readChar();
        continue;
      }

      final symbol = LayoutSymbol.byChar[char];
      if (symbol == null) continue;
      emitBlock(scanner.consume(), symbol);
      hasPendingBlock = false;

      // Markers are read as a cluster, the same way decoration characters
      // share one `:` -- `|~^` is a centered table. They describe different
      // things about the one block the separator opens: `~` says what kind
      // of block it is, an alignment character says how it sits.
      BlockAlign? clusterAlign;
      var tableToggles = 0;
      while (true) {
        final next = scanner.peekNext;
        final markerAlign = BlockAlign.byChar[next];
        if (markerAlign != null) {
          scanner.readChar();
          scanner.markConsumed();
          clusterAlign = markerAlign;
          continue;
        }
        // A table is a run of rows, so it can only be declared at a `|`.
        // After a `=`, which separates cells within one row, `~` is
        // ordinary text.
        if (symbol == LayoutSymbol.column &&
            BlockMarker.byChar[next] == BlockMarker.table) {
          scanner.readChar();
          scanner.markConsumed();
          tableToggles += 1;
          continue;
        }
        break;
      }

      if (tableToggles.isOdd) {
        if (inTable) {
          // Closing: the alignment belongs to the block being opened after
          // the table, not to the table that just ended.
          flushTable();
          pendingAlign = clusterAlign;
        } else {
          inTable = true;
          tableAlign = clusterAlign ?? BlockAlign.start;
        }
      } else {
        pendingAlign = clusterAlign;
      }
    }
    if (hasPendingBlock) emitBlock(scanner.flushRemaining(), null);
    flushRow();
    flushTable();

    return DocumentNode(children: children);
  }

  static List<TextNode> _parseBlock(String blockText) {
    final lines = blockText.split('\n');

    if (lines.firstOrNull == '') lines.removeAt(0);
    if (lines.lastOrNull == '') lines.removeLast();

    return lines.map(parseDecoratedLine).toList();
  }
}
