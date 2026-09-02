// 【解説】[11/21] パーサ本体。ここが全体を駆動する入口。
// 【解説】
// 【解説】 このファイルの仕事は「どこで切れるか」を決めることだけ。切れた塊を
// 【解説】 どう並べて木にするかは DocumentBuilder([12]) が持つ。以前は1つの
// 【解説】 関数に両方入っていて、可変ローカルが9個あった。
// 【解説】
// 【解説】 走査の見どころは3つ:
// 【解説】
// 【解説】 1. エスケープされた区切りは \ を残したまま素通しする。エスケープを
// 【解説】    実際に解決するのは decoration_parser 1箇所だけ、という約束を守る
// 【解説】    ため。ここでも落とすと \\ が2回書き換えられて壊れる。
// 【解説】
// 【解説】 2. verbatim 区間は「消費」ではなく「読み飛ばし」。中の | や = で
// 【解説】    塊を割らないが、文字そのものは後段に届く。
// 【解説】
// 【解説】 3. 寄せマーカー(< ^ >)は「記号として認識された | = の直後」でだけ
// 【解説】    読む。だから \= の後ろの > は素通しになる。特別扱いのコードは
// 【解説】    無く、ループがその地点に到達しないだけ、という作り。
// 【解説】    マーカーはクラスタとして読むので |~^ は「中央寄せの表」になる。
// 【解説】
// 【解説】 pendingAlign だけがループを跨ぐ状態。クラスタで書かれ、次の塊で
// 【解説】 使われる。走査側に残したのは「直前にどのマーカーを読んだか」が
// 【解説】 走査の事実だからで、builder には引数として渡している。
// 【解説】
// 【解説】 parse は static で、クラスは abstract final。状態を持たないのに
// 【解説】 インスタンスを作らせる形をやめた(NaturalBlockImages と同じ形)。
// 【解説】 入口で改行を \n に統一しているのも要点。しないと「開き記号を
// 【解説】 単独行に置ける」規則が Windows で書かれた文書に効かなくなる。
// 【解説】 CRLF と単独 CR の2回置換で、この行以降 \r は存在しない。
// 【解説】
// 【解説】 空白は一切削っていない。以前は文書の前後から ASCII の空白を
// 【解説】 削っていたが、やめた。理由は3つ:
// 【解説】   1. 最初と最後の行だけ字下げが剥がれ、他の行と扱いが割れていた
// 【解説】   2. 打った空白は見えて消せるので、内容として扱うのが筋
// 【解説】   3. その正規表現が parse 全体の2〜4割を占めていた($ 側が O(n))
// 【解説】 「記号を単独行に置ける」は _parseBlock の空行1つの規則が担うので、
// 【解説】 削っても壊れない。実際に消してテストを走らせて確かめてある。
// 【解説】 次: lib/src/parser/document_builder.dart

import '../block_align.dart';
import '../node.dart';
import 'block_marker.dart';
import 'decoration_parser.dart';
import 'document_builder.dart';
import 'layout_symbol.dart';
import 'literal_scanner.dart';
import 'verbatim_region.dart';

/// Turns a NaturalBlock source string into a tree of [NaturalBlockNode]s.
///
/// This is the package's main entry point: it drives the top-level layout
/// scan (splitting on `|` and `=`) and delegates each resulting line to
/// [parseDecoratedLine] for inline decoration parsing.
abstract final class NaturalBlockParser {
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
  /// contributes no node, so a redundant close is harmless on its own.
  ///
  /// Inside a table, a cell that carries no alignment marker of its own
  /// inherits its column's alignment from the first row, which is why an
  /// alignment is passed on only when a marker actually stated it.
  ///
  /// This documents the whole contract because it is the public entry
  /// point, but the scan here only decides *where* the source is cut;
  /// [DocumentBuilder] is what turns the resulting blocks into a tree, and
  /// holds the row and table rules above.
  static DocumentNode parse(String source) {
    // Every CR-based line ending becomes `\n`, and after this line a `\r`
    // does not exist anywhere in the text. That single invariant is what
    // every later rule relies on: `_parseBlock` splits on `\n` and compares
    // lines against `''` to drop a single blank one at each end -- the rule
    // that lets a block's opening symbol sit on its own line. Under CRLF
    // that leading line would be `'\r'`, not `''`, so the rule would
    // silently stop applying and every line would keep a trailing `\r`.
    // A document written by a Windows editor is affected.
    //
    // The order matters, and getting it wrong is silent: replacing the lone
    // `\r` first would turn every `\r\n` into `\n\n` and double every line.
    // `input_normalization_test`'s "a CRLF document parses exactly like the
    // LF one" catches that -- it goes from two nodes to four.
    //
    // This is deliberately two literal replacements rather than one
    // `RegExp(r'\r\n?')`: measured on a 3.5k-character document the regex
    // costs about 4.4x what the pair does, and the ordering hazard the
    // regex would remove is already covered by that test.
    //
    // Nothing else is stripped. Whitespace is content -- a space the author
    // typed is a space they can see and delete, so removing it at the
    // document's edges would treat the first and last line differently from
    // every other line. The one thing that does disappear is a single blank
    // line at each end of a *block*, which `_parseBlock` handles.
    final normalized = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final scanner = LiteralScanner(normalized);
    final builder = DocumentBuilder();
    var hasPendingBlock = false;

    // Set when a separator's marker cluster names an alignment, and read by
    // the block that separator opens -- so it necessarily outlives the
    // iteration that wrote it. It stays here rather than inside the builder
    // because it is a fact about the scan: which markers were just read.
    BlockAlign? pendingAlign;

    /// Hands the block that just ended to the builder, along with the
    /// alignment the separator before it asked for.
    void emitBlock(String text, LayoutSymbol? endedBy) {
      final align = pendingAlign;
      pendingAlign = null;
      builder.addBlock(
        _parseBlock(text),
        align: align,
        endsRow: endedBy == LayoutSymbol.row,
      );
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
              scanner.peekNext == r'\' ||
              // The fence too, or this scan and the decoration scan would
              // disagree: an escaped `` \` `` would open a region here
              // while the other pass, which resolves the escape, sees no
              // region at all. Three passes recognize regions, so they have
              // to agree about where one starts.
              scanner.peekNext == verbatimFenceChar)) {
        scanner.readChar();
        continue;
      }

      // A verbatim region is skipped over, not consumed: everything inside
      // stays in the literal run, so a `|` or `=` in it never splits a
      // block while the text still reaches the pass that resolves escapes.
      // An unclosed fence returns null and is left as ordinary text, which
      // is why a stray backtick cannot swallow anything.
      if (char == verbatimFenceChar) {
        final region = verbatimRegionAt(normalized, scanner.position - 1);
        if (region != null) {
          scanner.skipTo(region.end);
        }
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
      // Whether this cluster asks to cross the table boundary at all. Each
      // `~` flips it, so a second one in the same cluster cancels the first
      // -- `|~~` opens nothing. Nothing in the language gives a repeated
      // `~` a meaning; flipping is just what falls out of `~` being a
      // toggle, and `table_test` pins the result so it stays defined.
      var togglesTable = false;
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
          togglesTable = !togglesTable;
          continue;
        }
        break;
      }

      if (togglesTable) {
        if (builder.inTable) {
          // Closing: the alignment belongs to the block being opened after
          // the table, not to the table that just ended.
          builder.closeTable();
          pendingAlign = clusterAlign;
        } else {
          builder.openTable(clusterAlign ?? BlockAlign.start);
        }
      } else {
        pendingAlign = clusterAlign;
      }
    }
    if (hasPendingBlock) emitBlock(scanner.flushRemaining(), null);

    return builder.finish();
  }

  /// Splits a block into lines, leaving verbatim regions whole.
  ///
  /// The third place that recognizes a region, and the one that makes a
  /// multi-line code block possible at all: a plain `split('\n')` would cut
  /// such a region into a line each, and no later pass could put it back.
  /// All three callers ask the same function where a region ends, so they
  /// cannot disagree about it.
  static List<TextNode> _parseBlock(String blockText) {
    final lines = <String>[];
    final line = StringBuffer();

    for (var i = 0; i < blockText.length;) {
      final char = blockText[i];

      // An escaped fence is not a fence -- the same agreement the layout
      // scan keeps, and for the same reason.
      if (char == r'\' &&
          i + 1 < blockText.length &&
          blockText[i + 1] == verbatimFenceChar) {
        line.write(blockText.substring(i, i + 2));
        i += 2;
        continue;
      }

      if (char == verbatimFenceChar) {
        final region = verbatimRegionAt(blockText, i);
        if (region != null) {
          line.write(blockText.substring(i, region.end));
          i = region.end;
          continue;
        }
      }

      if (char == '\n') {
        lines.add(line.toString());
        line.clear();
        i += 1;
        continue;
      }

      line.write(char);
      i += 1;
    }
    lines.add(line.toString());

    if (lines.firstOrNull == '') lines.removeAt(0);
    if (lines.lastOrNull == '') lines.removeLast();

    return lines.map(parseDecoratedLine).toList();
  }
}
