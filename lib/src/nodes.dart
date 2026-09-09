/// The syntax tree: every node the parser can build, and nothing about how
/// it is built.
///
/// One file, because `sealed` requires every subtype of a sealed class to
/// live in the same library. That is the whole reason -- not privacy, and
/// not the reading order. `sealed` is what lets a consumer switch over the
/// node types and be told by the compiler when a new one appears.
///
/// The reading of source lives in `src/parse/`, one file per node. Those are
/// ordinary libraries, so their imports say which nodes and which symbols
/// each step of the reading depends on.
///
/// **What the tree records.** What the source said, never what a renderer
/// needs. `align` is `unstated` when nothing was written, which is not
/// [HorizontalAlign.start]; a table keeps its columns rather than stamping
/// them onto every cell; short rows are not padded. Resolving those for
/// drawing is the consumer's step.
library;

import 'package:collection/collection.dart';

import 'decoration_action.dart';
import 'horizontal_align.dart';
import 'semantic_color.dart';

export 'horizontal_align.dart';
export 'semantic_color.dart';

/// Everything in the tree. Sealed, so the set of node types is closed and
/// a consumer that handles all of them cannot be caught out by a new one.
sealed class NaturalBlockNode {}

/// How every node compares the children it holds.
///
/// Dart lists compare by identity, so a hand-written `==` that just wrote
/// `children == other.children` would call two trees different whenever
/// they were built separately -- which is every tree a test writes by hand
/// against one the parser produced.
const _childrenEquality = ListEquality<NaturalBlockNode>();

sealed class InlineNode extends NaturalBlockNode {}

/// The decoration state a run carries, and the parser's reading state.
///
/// Immutable: [apply] returns the next state rather than mutating, so the
/// style of a finished run cannot change under it.
class SpanDecoration {
  final int sizeOffset;
  final SemanticColor color;
  final bool emphasis;
  final bool isAction;

  const SpanDecoration({
    this.sizeOffset = 0,
    this.color = SemanticColor.none,
    this.emphasis = false,
    this.isAction = false,
  });

  SpanDecoration apply(DecorationAction action) => switch (action) {
    DecorationAction.larger => _copy(sizeOffset: sizeOffset + 1),
    DecorationAction.smaller => _copy(sizeOffset: sizeOffset - 1),
    DecorationAction.danger => _copy(color: _toggle(SemanticColor.danger)),
    DecorationAction.success => _copy(color: _toggle(SemanticColor.success)),
    DecorationAction.emphasis => _copy(emphasis: !emphasis),
    DecorationAction.action => _copy(isAction: !isAction),
    DecorationAction.reset => _copy(
      color: SemanticColor.none,
      emphasis: false,
      isAction: false,
    ),
  };

  @override
  String toString() =>
      'SpanDecoration(sizeOffset: $sizeOffset, color: $color, '
      'emphasis: $emphasis, isAction: $isAction)';

  @override
  bool operator ==(Object other) =>
      other is SpanDecoration &&
      sizeOffset == other.sizeOffset &&
      color == other.color &&
      emphasis == other.emphasis &&
      isAction == other.isAction;

  @override
  int get hashCode => Object.hash(sizeOffset, color, emphasis, isAction);

  SemanticColor _toggle(SemanticColor next) =>
      color == next ? SemanticColor.none : next;

  SpanDecoration _copy({
    int? sizeOffset,
    SemanticColor? color,
    bool? emphasis,
    bool? isAction,
  }) => SpanDecoration(
    sizeOffset: sizeOffset ?? this.sizeOffset,
    color: color ?? this.color,
    emphasis: emphasis ?? this.emphasis,
    isAction: isAction ?? this.isAction,
  );
}

final class TextSpanNode extends InlineNode {
  final String text;

  /// Everything the decoration syntax said about this run, as one value.
  ///
  /// One field rather than four, because it is one thing: the same object
  /// the parser carries while reading. A run's decoration and the reader's
  /// current decoration are not two ideas that happen to match.
  final SpanDecoration decoration;

  TextSpanNode({required this.text, this.decoration = const SpanDecoration()});

  @override
  String toString() => 'TextSpanNode(text: $text, decoration: $decoration)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextSpanNode &&
        text == other.text &&
        decoration == other.decoration;
  }

  @override
  int get hashCode => Object.hash(text, decoration);
}

final class VerbatimSpanNode extends InlineNode {
  final String text;

  VerbatimSpanNode({required this.text});

  @override
  String toString() => 'VerbatimSpanNode(text: $text)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerbatimSpanNode && text == other.text;
  }

  @override
  int get hashCode => Object.hash(runtimeType, text);
}

/// How the things inside are arranged, and nothing else.
///
/// A [ColumnNode] stacks its content; a [RowNode] lays its cells across.
/// Neither is content itself -- they say where content goes. A document is
/// a stack of these.
///
/// A table is *not* one, even though it arranges rows inside itself. From
/// the outside it is a thing you place, sized to its own content, so it
/// belongs with the content it sits among. It is the one node that is
/// content on the outside and layout on the inside.
sealed class LayoutNode extends NaturalBlockNode {}

/// What a block holds, and what gets arranged.
///
/// **Not a line.** This was called `LineNode` and it misled: a [TextNode]
/// runs across as many newlines as the author wrote, because a newline is a
/// character rather than a boundary. A block of three lines is one
/// `TextNode` holding two `\n`s, not three nodes.
///
/// Three kinds, and a table is one of them -- the same as a verbatim region:
/// something written between delimiters that arrives already formatted. That
/// is what lets a block hold text, a table, and more text without breaking
/// in two, so an alignment written on the block reaches all of it.
///
/// The tree has no line-level structure at all. That is worth stating
/// plainly, because a per-line role is exactly what a heading or a list item
/// would need, and the old name suggested somewhere to put one.
sealed class ContentNode extends NaturalBlockNode {}

final class VerbatimNode extends ContentNode {
  final String text;

  VerbatimNode({required this.text});

  @override
  String toString() => 'VerbatimNode(text: $text)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VerbatimNode && text == other.text;
  }

  @override
  int get hashCode => Object.hash(runtimeType, text);
}

final class TextNode extends ContentNode {
  final List<InlineNode> children;

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

final class ColumnNode extends LayoutNode {
  final List<ContentNode> children;

  /// The alignment written for this block, or `unstated` when none was.
  ///
  /// Unstated is not [HorizontalAlign.start]. Inside a table only a cell that stated
  /// nothing inherits its column's alignment, and a renderer is free to draw
  /// an unstated block differently from one that asked for the start.
  final HorizontalAlign align;

  ColumnNode({this.children = const [], this.align = HorizontalAlign.unstated});

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

final class RowNode extends LayoutNode {
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

/// A grid, written between a pair of `~`.
///
/// Content, not layout: from the outside it is a thing you place, sized to
/// its own rows rather than to the width it is given. Inside it arranges,
/// which makes it the one node with a foot on each side.
final class TableNode extends ContentNode {
  /// The rows as the source wrote them. A row may be shorter than the table
  /// is wide; it is not padded here, because the author wrote no cell there.
  final List<TableRowNode> children;

  /// What each column declared, and by its length how wide the table is.
  ///
  /// Two facts in one list because they come from one place: a column exists
  /// because some row had a cell at that position, and its alignment is what
  /// that row's cell stated -- which may be nothing.
  ///
  /// This is where a table's column alignment lives, rather than being
  /// stamped onto every cell. A cell's own `align` therefore keeps meaning
  /// "what this cell stated", and a consumer resolves the two:
  ///
  /// ```dart
  /// final effective = cell.align == HorizontalAlign.unstated
  ///     ? table.columns[i]
  ///     : cell.align;
  /// ```
  ///
  /// Read from the rows rather than passed in, so a hand-built table cannot
  /// disagree with itself. Computed once, on first use.
  late final List<HorizontalAlign> columns = _columns(children);

  /// The alignment written for the table itself, or `unstated` when none was.
  ///
  /// Where the table sits inside its block, which is not the same question
  /// as [ColumnNode.align] -- that one says how a block arranges everything
  /// it holds. `|=` centres the text and the table together; `~=` centres
  /// only the table.
  final HorizontalAlign align;

  TableNode({this.children = const [], this.align = HorizontalAlign.unstated});

  /// What each column declared, taken from the first row that reached it.
  ///
  /// For the ordinary table -- whose first row is its widest -- that is just
  /// "the first row". A later row that is wider than every row before it
  /// declares the columns it adds.
  static List<HorizontalAlign> _columns(List<TableRowNode> rows) {
    final columns = <HorizontalAlign>[];
    for (final row in rows) {
      for (var i = columns.length; i < row.children.length; i++) {
        columns.add(row.children[i].align);
      }
    }
    return columns;
  }

  @override
  String toString() =>
      'TableNode(children: $children, columns: $columns, align: $align)';

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

/// One row of a table.
///
/// Not a [RowNode]. Both hold cells written across, but a `RowNode` divides
/// the width it is given between them while these line up with the rows
/// above and below -- different enough that the renderer never treats one as
/// the other. Its own type also keeps a table from holding anything but
/// rows, and a row anything but cells.
///
/// In no sealed group, because nothing ever chooses: a table's children are
/// always rows, and a row's are always cells.
final class TableRowNode extends NaturalBlockNode {
  final List<TableCellNode> children;

  TableRowNode({this.children = const []});

  @override
  String toString() => 'TableRowNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableRowNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}

/// One cell of a table.
///
/// Holds what a block holds, and yet never another table -- not because the
/// reading below skips that branch, but because it never gets that far. A
/// cell stops at `~`, so the `~` inside a table is always the one that ends
/// it and never one that opens another. Nesting is ruled out by where the
/// cell stops, which is the one line of it that differs from a column.
///
/// Not a [ColumnNode], though it stacks its content the same way. A column
/// reads through a `~` -- a table is content, so a block keeps going after
/// one -- while a cell has to stop at it.
final class TableCellNode extends NaturalBlockNode {
  final List<ContentNode> children;

  /// What this cell stated, which is also what its column declares when it
  /// is the first row to reach that position. `unstated` when it stated nothing.
  final HorizontalAlign align;

  TableCellNode({
    this.children = const [],
    this.align = HorizontalAlign.unstated,
  });

  @override
  String toString() => 'TableCellNode(children: $children, align: $align)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableCellNode &&
        align == other.align &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, align, _childrenEquality.hash(children));
}

final class DocumentNode extends NaturalBlockNode {
  final List<LayoutNode> children;

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
