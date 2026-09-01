// 【解説】[2/16] AST。このライブラリの出力そのもの。ここを先に読むと、
// 【解説】 パーサの各処理が「何を作ろうとしているか」が分かる。
// 【解説】
// 【解説】 階層:
// 【解説】   NaturalBlockNode（全ての親）
// 【解説】   ├ DocumentNode … parse() が返す最上位。文書1つにつき1個だけ
// 【解説】   ├ BlockNode    … 文書に直接並べられるもの(sealed)
// 【解説】   │   ├ TextNode  （1行）
// 【解説】   │   ├ RowNode   （横並び。= が作る）
// 【解説】   │   └ ColumnNode（行の塊＋寄せ。| が作る。セルでもある）
// 【解説】   └ TextSpanNode … 行の中の断片。ブロックにはなれない
// 【解説】
// 【解説】 読みどころは「children の型が全部違う」こと。どのノードも
// 【解説】 実際に入りうる子の型ちょうどを宣言していて、それ以外は
// 【解説】 コンパイルエラーになる。以前は全部 List<NaturalBlockNode> で、
// 【解説】 TextSpanNode を ColumnNode の子に置いても型が通り、描画時に
// 【解説】 例外も出ず黙って消える、という穴があった。
// 【解説】
// 【解説】 DocumentNode を ColumnNode と分けているのが今回の肝。以前は
// 【解説】 両方 ColumnNode で、「全体を囲うもの」と「中の塊」が同じ型だった。
// 【解説】 実際には子の集合が違い(ルートは3種類、塊は TextNode だけ)、
// 【解説】 さらにルートの align は構造上いつも既定値で死んでいた。
// 【解説】 次: lib/src/semantic_color.dart と lib/src/block_align.dart（語彙）

import 'package:collection/collection.dart';

import 'block_align.dart';
import 'semantic_color.dart';

/// Deep, order-sensitive equality (and matching hash) for a node's
/// `children` list, shared by every [NaturalBlockNode] subclass below.
const _childrenEquality = ListEquality<NaturalBlockNode>();

/// The base type of every node the parser can produce.
///
/// Each node below declares its `children` as exactly the type that can
/// actually appear there, rather than sharing one wide list type. That is
/// what makes a misplaced node -- a [TextSpanNode] used where a line
/// belongs, say -- a compile error instead of something that renders as
/// nothing at runtime.
sealed class NaturalBlockNode {}

/// The root of a parsed document: exactly one per `NaturalBlockParser.parse`
/// call, holding the blocks that make up the document.
///
/// Deliberately *not* a [ColumnNode], even though both stack their children
/// vertically. The two differ in what they can contain -- a document holds
/// any [BlockNode], while a [ColumnNode] holds only lines -- and a document
/// has no alignment of its own, having nothing to be aligned within. Sharing
/// one type for both meant a single `children` list that had to admit every
/// node kind, and an `align` field on the root that was never anything but
/// its default.
class DocumentNode extends NaturalBlockNode {
  final List<BlockNode> children;
  DocumentNode({this.children = const []});

  @override
  String toString() => 'DocumentNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}

/// A node that can be placed directly in a document, or in whatever else
/// arranges blocks.
///
/// This is the "can stand on its own in the flow" boundary: a [TextSpanNode]
/// is deliberately *not* one, because a styled run only ever exists inside a
/// [TextNode]'s line. New block-level constructs (a table, say) join here and
/// become placeable everywhere blocks are accepted, with nothing else to
/// wire up.
sealed class BlockNode extends NaturalBlockNode {}

/// A horizontal arrangement, produced by the `=` separator.
///
/// A [RowNode] holds every cell of one visual row -- each child is a
/// [ColumnNode] holding that cell's stacked lines (a cell with a single line
/// is simply a one-child [ColumnNode]). The row boundary is therefore
/// explicit structure: there is no convention of grouping sibling nodes back
/// up to find where one row ends and the next begins.
class RowNode extends BlockNode {
  final List<ColumnNode> children;
  RowNode({this.children = const []});

  @override
  String toString() => 'RowNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RowNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}

/// A run of rows that share their column widths, opened by the `~` marker
/// (`|~`) and closed by that same marker, by a row of a different cell
/// count, by anything that is not a row, or by the end of the document.
///
/// Being declared rather than inferred is the whole point. A run of rows is
/// not automatically a table: `LEFT==RIGHT` is three cells with an empty
/// middle, written that way to push RIGHT to the far edge, and it only does
/// that because plain rows split the available width evenly. A table wants
/// the opposite -- columns as wide as their content -- so the two readings
/// cannot share a width policy, and only an explicit marker can say which
/// one a given run of rows means.
///
/// The declaration is also the place to hang what a table needs and a bare
/// row cannot express: rules, striping, and cell padding are properties of
/// a table, not of the text inside it, and the decoration syntax has no way
/// to say them.
class TableNode extends BlockNode {
  final List<RowNode> children;

  /// How the table as a whole is positioned, from an alignment character in
  /// the same marker cluster that opened it -- `|~^` centers it. Meaningful
  /// because a table is sized to its content rather than filling the width,
  /// so there is room around it to be positioned within.
  final BlockAlign align;

  TableNode({this.children = const [], this.align = BlockAlign.start});

  @override
  String toString() => 'TableNode(children: $children, align: $align)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableNode &&
        align == other.align &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, align, _childrenEquality.hash(children));
}

/// A run of lines sharing one alignment, produced by the `|` separator.
///
/// This is the single shape behind two readings that look different in the
/// source but are structurally identical: a cell of a [RowNode], and a
/// standalone block carrying an alignment marker. Both are "these lines,
/// aligned this way", so both are this one type.
///
/// Its children are lines, and only lines. A cell holding a nested row or
/// table is not expressible today, and stating that in the type keeps a
/// later decision to allow it a deliberate, visible change rather than
/// something that silently was always possible.
class ColumnNode extends BlockNode {
  final List<TextNode> children;

  /// How these lines are aligned horizontally, set by an alignment marker
  /// (`<`, `^`, `>`) written immediately after the layout separator that
  /// opened this block. Defaults to [BlockAlign.start] when no marker was
  /// given.
  final BlockAlign align;

  ColumnNode({this.children = const [], this.align = BlockAlign.start});

  @override
  String toString() => 'ColumnNode(children: $children, align: $align)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColumnNode &&
        align == other.align &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, align, _childrenEquality.hash(children));
}

/// A single line of text, broken into one or more [TextSpanNode] children
/// wherever its decoration state changes partway through.
class TextNode extends BlockNode {
  final List<TextSpanNode> children;
  TextNode({this.children = const []});

  @override
  String toString() => 'TextNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}

/// A single run of text sharing one decoration state (size, color, emphasis,
/// and actionability) -- a [TextNode] is split into one [TextSpanNode] per
/// run whenever a decoration cluster changes that state partway through a
/// line.
///
/// Not a [BlockNode]: a styled run is part of a line, never a thing the
/// document arranges on its own.
class TextSpanNode extends NaturalBlockNode {
  /// The literal text of this run, with escaping already resolved.
  final String text;

  /// How many size steps this run is offset from the surrounding default,
  /// e.g. `+2` from two stacked `:+` decorations -- a relative step count,
  /// not an absolute font size, since the parser has no notion of what the
  /// base size actually is.
  final int sizeOffset;

  /// The semantic color applied to this run, or [SemanticColor.none] if no
  /// color decoration is active.
  final SemanticColor color;

  /// Whether emphasis (`:*`) is active for this run.
  final bool emphasis;

  /// Whether this run is actionable (`:@`) -- something the reader can tap.
  ///
  /// The parser records only *that* the run is actionable, never what
  /// tapping it should do: that decision belongs entirely to the consuming
  /// app (open a URL, jump to a section, open a mention, run a command...).
  /// The tapped payload is simply this run's own [text] -- there is no
  /// separate target field, deliberately, the same way [color] records a
  /// semantic meaning like [SemanticColor.danger] and leaves it to the
  /// theme to decide what red means.
  final bool isAction;

  TextSpanNode({
    required this.text,
    this.sizeOffset = 0,
    this.color = SemanticColor.none,
    this.emphasis = false,
    this.isAction = false,
  });

  @override
  String toString() {
    return 'TextSpanNode(text: $text, sizeOffset: $sizeOffset, color: $color, emphasis: $emphasis, isAction: $isAction)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextSpanNode &&
        text == other.text &&
        sizeOffset == other.sizeOffset &&
        color == other.color &&
        emphasis == other.emphasis &&
        isAction == other.isAction;
  }

  @override
  int get hashCode => Object.hash(text, sizeOffset, color, emphasis, isAction);
}
