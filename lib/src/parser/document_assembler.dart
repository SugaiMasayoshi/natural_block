// 【解説】[14/23] 走査の結果を受け取って木を組み立てる側。
// 【解説】
// 【解説】 parser.dart が「どこで切れるか」を決め、ここが「切れた塊をどう
// 【解説】 並べるか」を決める。走査は一切しない。import が block_align と
// 【解説】 node だけなのが、その境界の証拠。
// 【解説】
// 【解説】 フィールドは3つしかない。以前は7つあった:
// 【解説】   _currentRow と _currentRowExplicit … 長さが連動する並列配列
// 【解説】   _inTable / _tableAlign / _tableRows / _columnAligns … 4つで1つの
// 【解説】     「開いている表」を表していた
// 【解説】
// 【解説】 前者は PendingCell が解いた。statedAlign が null 可能なので、
// 【解説】 「明示されたか」という真偽値そのものが不要になる。ついでに
// 【解説】 ColumnNode を作り直す無駄も消えた(以前は一度作ってから、継承した
// 【解説】 寄せでもう一度作っていた)。
// 【解説】
// 【解説】 後者は TableAssembler が解いた。null が「表は開いていない」を
// 【解説】 意味するので、中間状態が存在できない。inTable も保持をやめて
// 【解説】 _table != null の導出値になっている。
// 【解説】
// 【解説】 addBlock の上のコメントがこの言語の設計の要。「Columnブロックは
// 【解説】 内容、Rowセルは位置」という非対称が意図的で、それが 左==右 を
// 【解説】 「3セルで真ん中が空」と読ませている。
// 【解説】 次: natural_block_flutter 側へ。lib/natural_block_flutter.dart

import '../block_align.dart';
import '../node.dart';

/// A row cell that has been read but not yet placed.
///
/// [statedAlign] is null when no marker named an alignment, and that null is
/// the whole record of it. The parser used to carry a parallel `List<bool>`
/// beside the cells to remember the same fact, with nothing keeping the two
/// lists the same length; here the question "was an alignment stated?" and
/// the answer "which one" are one field.
///
/// The [ColumnNode] is built in [resolve], not before. Inside a table a cell
/// that stated nothing takes its column's alignment, and building the node
/// first meant building a second one to replace it.
class PendingCell {
  final List<TextNode> lines;
  final BlockAlign? statedAlign;

  const PendingCell({required this.lines, required this.statedAlign});

  /// The cell as a node, falling back to [inherited] when it stated nothing.
  ColumnNode resolve(BlockAlign inherited) =>
      ColumnNode(children: lines, align: statedAlign ?? inherited);
}

/// One open table, collecting the rows that belong to it.
///
/// Exists only while a table is open, which is the point: the assembler
/// holds it as a nullable field, so "no table is open" is the absence of an
/// object rather than a flag that four other fields have to agree with.
/// There is no way to be between states.
class TableAssembler {
  /// How the table sits, from the cluster that opened it (`|~^`).
  final BlockAlign align;

  final List<RowNode> _rows = [];

  /// Fixed by the first row: what each column is aligned as by default, and
  /// -- by its length -- how many cells every later row must have.
  List<BlockAlign>? _columnAligns;

  TableAssembler(this.align);

  /// Whether a row of [cellCount] cells can still belong to this table.
  ///
  /// A row of a different width has nothing to line its columns up against,
  /// and Flutter's `Table` requires every row to have the same number of
  /// cells, so a ragged run cannot be one table at all.
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

  /// The finished table, or null if it was never given a row -- which is
  /// what makes a redundant `|~` harmless.
  TableNode? close() =>
      _rows.isEmpty ? null : TableNode(children: _rows, align: align);
}

/// Assembles the block-level shape of a document from the pieces a scan
/// hands it, one block at a time.
///
/// Deliberately knows nothing about scanning: it never sees the source text,
/// only blocks already split into lines. Where a block ended and what
/// markers were written are questions the parser answers; what the resulting
/// tree looks like is answered here.
class DocumentAssembler {
  final List<BlockNode> _children = [];

  /// Cells of the row being read. Empty means no row is open.
  List<PendingCell> _row = [];

  /// The open table, or null when none is. Replaces four fields that could
  /// disagree with each other.
  TableAssembler? _table;

  /// Whether a table is open, which is what decides whether the next `~`
  /// opens one or closes this one.
  bool get inTable => _table != null;

  /// Declares that the rows which follow belong to a table sitting as
  /// [align] says.
  void openTable(BlockAlign align) => _table = TableAssembler(align);

  /// Ends the current table, emitting it if it was given any rows.
  void closeTable() {
    final node = _table?.close();
    if (node != null) _children.add(node);
    _table = null;
  }

  /// Adds one block, already split into its [lines].
  ///
  /// [align] is non-null only when a marker actually said so -- that
  /// distinction is what a table's inheritance rule reads. [endsRow] says
  /// the block was ended by a Row separator (`=`), meaning more cells of the
  /// same row follow.
  ///
  /// An empty block is treated differently depending on which kind it is,
  /// and the difference is deliberate:
  ///
  /// - A Column block is *content*. Nothing in it means nothing to show, so
  ///   it contributes no node at all (`左||右` yields two text nodes, not
  ///   three), and a marker does not change that: there is nothing inside to
  ///   be aligned.
  /// - A Row cell is a *position*. The surrounding cells are laid out
  ///   relative to it, so the cell survives even when blank -- that is what
  ///   lets `左==右` mean "three cells, middle one empty". Dropping empty
  ///   cells would make `左=右` and `左==右` indistinguishable and leave no
  ///   way to write a deliberately blank cell.
  ///
  /// The empty-block check comes before anything that closes the table,
  /// which is what keeps `||` from being an invisible separator that splits
  /// a table in two on something the AST does not record.
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

    // Anything that is not a row ends the table -- a TableNode holds rows,
    // so there is nowhere for a paragraph to go inside one.
    closeTable();
    if (align != null) {
      _children.add(ColumnNode(children: lines, align: align));
    } else {
      _children.addAll(lines);
    }
  }

  /// Finishes any row and table left open and returns the document.
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
    // A row that cannot join the open table ends it and stands on its own.
    closeTable();
    _children.add(
      RowNode(
        children: [for (final cell in cells) cell.resolve(BlockAlign.start)],
      ),
    );
  }
}
