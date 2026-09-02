// 【解説】[9.5/16] 走査の結果を受け取って木を組み立てる側。
// 【解説】
// 【解説】 parser.dart が「どこで切れるか」を決め、このファイルが「切れた塊を
// 【解説】 どう並べるか」を決める。走査は一切しない — LiteralScanner も
// 【解説】 verbatim_region も import していないのが、その境界の証拠。
// 【解説】
// 【解説】 持っている状態は2組ある:
// 【解説】   行   … _currentRow / _currentRowExplicit
// 【解説】   表   … _inTable / _tableAlign / _tableRows / _columnAligns
// 【解説】 = で繋がったセルを _currentRow に溜め、= の連なりが切れた瞬間に
// 【解説】 _flushRow() で1つの RowNode として吐く。だから a=b|c=d は
// 【解説】 2つの RowNode になる(1つの4セル行にならない)。
// 【解説】
// 【解説】 addBlock の上にある長いコメントが、この言語の設計の要。
// 【解説】 「Columnブロックは内容、Rowセルは位置」という非対称が意図的で、
// 【解説】 それが 左==右 を「3セルで真ん中が空」と読ませている。空セルを捨てると
// 【解説】 左=右 と 左==右 が区別できなくなる。
// 【解説】
// 【解説】 寄せが引数なのは意図的。以前は parse のローカル変数を emitBlock が
// 【解説】 覗いていて、呼び出し地点を見ても何の寄せが効くのか分からなかった。
// 【解説】 明示されたときだけ非 null、という約束がそのまま _currentRowExplicit に
// 【解説】 なる(align だけでは明示の < と既定値がどちらも start で区別できない)。
// 【解説】 次: lib/src/parser/parser.dart の続き、あるいは natural_block_flutter へ

import '../block_align.dart';
import '../node.dart';

/// Assembles the block-level shape of a document from the pieces a scan
/// hands it, one block at a time.
///
/// Deliberately knows nothing about scanning: it never sees the source
/// text, only blocks that have already been split into lines. Where a block
/// ended and what markers were written are questions the parser answers;
/// what the resulting tree looks like is answered here.
class DocumentBuilder {
  final List<BlockNode> _children = [];

  List<ColumnNode> _currentRow = [];

  /// Whether each cell of [_currentRow] got its alignment from a marker of
  /// its own, as opposed to falling back to the default. Only a cell that
  /// said nothing inherits its column's alignment inside a table, so the
  /// two cases have to stay distinguishable -- [ColumnNode.align] alone
  /// cannot, since an explicit `<` and an unstated default are both
  /// [BlockAlign.start].
  List<bool> _currentRowExplicit = [];

  // Table state. `_columnAligns` is set from the first row and then serves
  // as both the alignment each column inherits and the cell count every
  // later row must match to stay part of the table.
  bool _inTable = false;
  BlockAlign _tableAlign = BlockAlign.start;
  List<RowNode> _tableRows = [];
  List<BlockAlign>? _columnAligns;

  /// Whether a table is currently open, which is what decides whether the
  /// next `~` opens one or closes this one.
  bool get inTable => _inTable;

  /// Declares that the rows which follow belong to a table, sitting as
  /// [align] says.
  void openTable(BlockAlign align) {
    _inTable = true;
    _tableAlign = align;
  }

  /// Ends the current table, emitting it if it was given any rows.
  ///
  /// A table that never got a row contributes no node, so closing one that
  /// was never really started is harmless.
  void closeTable() {
    if (_tableRows.isNotEmpty) {
      _children.add(TableNode(children: _tableRows, align: _tableAlign));
      _tableRows = [];
    }
    _columnAligns = null;
    _tableAlign = BlockAlign.start;
    _inTable = false;
  }

  /// Adds one block, already split into its [lines].
  ///
  /// [align] is non-null only when a marker actually said so -- that
  /// distinction is what a table's inheritance rule reads. [endsRow] says
  /// the block was ended by a Row separator (`=`), meaning more cells of
  /// the same row follow.
  ///
  /// An empty block is treated differently depending on which kind it is,
  /// and the difference is deliberate rather than an artifact of `add` vs
  /// `addAll`:
  ///
  /// - A Column block is *content*. Nothing in it means nothing to show, so
  ///   it contributes no node at all (`左||右` yields two text nodes, not
  ///   three).
  /// - A Row cell is a *position*. The surrounding cells are laid out
  ///   relative to it, so the cell survives even when blank -- that is what
  ///   lets `左==右` mean "three cells, middle one empty". Dropping empty
  ///   cells would make `左=右` and `左==右` indistinguishable and leave no
  ///   way to write a deliberately blank cell.
  ///
  /// Note the cell is emitted as an empty ColumnNode (`children: []`)
  /// rather than holding a placeholder empty TextNode: "a cell exists with
  /// no content" is what the source actually says, whereas an empty
  /// TextNode would additionally claim the cell contains one blank line.
  void addBlock(List<TextNode> lines, {BlockAlign? align, required bool endsRow}) {
    if (_currentRow.isNotEmpty || endsRow) {
      _currentRow.add(
        ColumnNode(children: lines, align: align ?? BlockAlign.start),
      );
      _currentRowExplicit.add(align != null);
      if (!endsRow) _flushRow();
    } else if (lines.isEmpty) {
      // An empty Column block contributes no node at all, and a marker
      // does not change that: there is nothing inside to be aligned.
      // Without this, `a||b` gave two nodes but `a|>|b` gave three, the
      // middle one an empty ColumnNode -- contradicting the rule stated
      // just above. Note this branch comes first so it also keeps an
      // empty block from ending a table (see the next branch).
    } else if (align != null) {
      closeTable();
      _children.add(ColumnNode(children: lines, align: align));
    } else {
      // Anything that is not a row ends the table -- a TableNode holds
      // rows, so there is nowhere for a paragraph to go inside one.
      // Reaching here means the block has content: an empty one was
      // already handled above, which is what keeps it from ending a
      // table. Otherwise `||` would be an invisible separator, silently
      // splitting a table in two on something the AST does not record.
      closeTable();
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
    if (_currentRow.isEmpty) return;
    final cells = _currentRow;
    final explicit = _currentRowExplicit;
    _currentRow = [];
    _currentRowExplicit = [];

    if (!_inTable) {
      _children.add(RowNode(children: cells));
      return;
    }

    final aligns = _columnAligns;
    if (aligns == null) {
      // The first row fixes the shape: how many columns the table has, and
      // what each of them is aligned as by default.
      _columnAligns = [for (final cell in cells) cell.align];
      _tableRows.add(RowNode(children: cells));
      return;
    }

    if (cells.length != aligns.length) {
      // A row of a different width cannot be part of the same table --
      // columns would have nothing to line up against, and the renderer's
      // Table requires every row to have the same number of cells. So the
      // table ends here and this row stands on its own.
      closeTable();
      _children.add(RowNode(children: cells));
      return;
    }

    _tableRows.add(
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
}
