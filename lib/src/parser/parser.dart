// 【解説】[13/23] パーサ本体。ここが全体を駆動する入口。
// 【解説】
// 【解説】 このファイルの仕事は「どこで切れるか」を決めることだけ。切れた塊を
// 【解説】 どう並べて木にするかは DocumentAssembler([14]) が持つ。以前は1つの
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
// 【解説】 次: lib/src/parser/source_scan.dart
import '../block_align.dart';
import '../node.dart';
import 'decoration_parser.dart';
import 'document_assembler.dart';
import 'layout_symbol.dart';
import 'marker_cluster.dart';
import 'source_scan.dart';

bool _isLayoutSymbol(String char) => LayoutSymbol.byChar.containsKey(char);

bool _isNewline(String char) => char == '\n';

/// Turns a NaturalBlock source string into a tree of [NaturalBlockNode]s.
///
/// The package's entry point, and its only public one. Everything below --
/// where the source is cut, what a marker cluster says, how blocks become a
/// tree -- is private, which is what has let the inside be reshaped without
/// the outside noticing.
abstract final class NaturalBlockParser {
  /// Parses [source] into a [DocumentNode] tree.
  ///
  /// `|` separates vertical blocks and `=` separates the cells of a
  /// horizontal row. A run of `=`-joined cells becomes one [RowNode], so
  /// `a=b|c=d` produces two rows rather than one four-cell row. Each block
  /// is split into lines and each line becomes a [TextNode]; a single blank
  /// line at each end of a block is dropped, which is what lets a block's
  /// symbol sit on a line of its own.
  ///
  /// An alignment marker -- `<`, `^`, `>` -- written immediately after an
  /// unescaped separator sets how the block starting there sits. That
  /// position is the entire trigger: anywhere else those are ordinary text,
  /// which is what lets `a > b`, `->`, `=>` and `List<String>` through
  /// untouched. `~` in the same cluster declares a table, so `|~^` is a
  /// centered one.
  ///
  /// This function does one thing: decide where the source is cut. What the
  /// markers at a cut say is [readMarkerCluster]'s question, and what the
  /// resulting blocks add up to is [DocumentAssembler]'s. The rules for rows
  /// and tables are stated there rather than repeated here.
  static DocumentNode parse(String source) {
    // Every CR-based line ending becomes `\n`, and after this line a `\r`
    // does not exist anywhere in the text. That single invariant is what
    // every later rule relies on: lines are split on `\n` and compared
    // against `''` to drop a blank one at each end of a block, and under
    // CRLF that line would be `'\r'`, so the rule would silently stop
    // applying and every line would keep a trailing `\r`.
    //
    // The order matters, and getting it wrong is silent: replacing the lone
    // `\r` first would turn every `\r\n` into `\n\n` and double every line.
    // `input_normalization_test` pins both the order and the lone CR.
    //
    // Two literal replacements rather than one `RegExp(r'\r\n?')`: measured
    // on a 3.5k-character document the regex costs about 4.4x the pair, and
    // the ordering hazard it would remove is already covered by a test.
    //
    // Nothing else is stripped. Whitespace is content -- a space the author
    // typed is one they can see and delete, so removing it at the document's
    // edges would treat the first and last line unlike every other line.
    final text = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    final document = DocumentAssembler();
    var start = 0;

    // Written by a separator's marker cluster and read by the block that
    // separator opens, so it necessarily outlives the turn that set it. It
    // lives here rather than in the assembler because it is a fact about the
    // scan: which markers were just read.
    BlockAlign? pendingAlign;

    while (true) {
      final at = nextDelimiter(text, start, _isLayoutSymbol);
      document.addBlock(
        _parseLines(text.substring(start, at)),
        align: pendingAlign,
        endsRow: at < text.length && LayoutSymbol.byChar[text[at]] == LayoutSymbol.row,
      );
      pendingAlign = null;
      if (at >= text.length) break;

      final cluster = readMarkerCluster(
        text,
        at + 1,
        // A table is a run of rows, so it can only be declared at a `|`.
        // After a `=`, which divides cells within one row, `~` is text.
        allowTable: LayoutSymbol.byChar[text[at]] == LayoutSymbol.column,
      );
      start = cluster.end;

      if (cluster.togglesTable) {
        if (document.inTable) {
          // Closing: the alignment belongs to the block opened after the
          // table, not to the table that just ended.
          document.closeTable();
          pendingAlign = cluster.align;
        } else {
          document.openTable(cluster.align ?? BlockAlign.start);
        }
      } else {
        pendingAlign = cluster.align;
      }

      // A separator at the very end of the source opens nothing. Without
      // this, `a=b=` would gain a third, empty cell that the author never
      // wrote -- and an empty cell is a position the layout keeps.
      if (start >= text.length) break;
    }

    return document.finish();
  }

  /// Splits a block into lines and parses each one.
  ///
  /// Uses the same walk as the layout scan, stopping at `\n` instead of at a
  /// separator. That shared walk is what keeps a multi-line verbatim region
  /// in one line: cutting it into a line each would leave no later pass able
  /// to put it back, and a code block would be impossible.
  ///
  /// A single blank line at each end is dropped so a block's opening or
  /// closing symbol can sit on a line of its own, while a genuine blank line
  /// in the middle survives.
  static List<TextNode> _parseLines(String block) {
    final lines = <String>[];
    var start = 0;
    while (true) {
      final at = nextDelimiter(block, start, _isNewline);
      lines.add(block.substring(start, at));
      if (at >= block.length) break;
      start = at + 1;
    }

    if (lines.firstOrNull == '') lines.removeAt(0);
    if (lines.lastOrNull == '') lines.removeLast();

    return lines.map(parseDecoratedLine).toList();
  }
}
