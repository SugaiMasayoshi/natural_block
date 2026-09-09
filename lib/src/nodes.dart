/// The syntax tree: every node the parser can build, and nothing about how
/// it is built.
///
/// One file, because `sealed` requires every subtype to live in the same
/// library. That is the whole reason -- not privacy, and not the reading
/// order. The reading is in `src/parse/`, one library per node.
///
/// Written from the root down: a document, then what it arranges, then what
/// those hold, and the spans a run of text is made of last.
///
/// **What the tree records.** What the source said, never what a renderer
/// needs. `align` is `unstated` when nothing was written, which is not
/// [HorizontalAlign.start]; a table keeps its columns rather than stamping
/// them onto every cell; short rows are not padded. Resolving those for
/// drawing is the consumer's step.
library;

import 'package:collection/collection.dart';

import 'horizontal_align.dart';
import 'span_decoration.dart';

/// Everything in the tree. Sealed, so the set of node types is closed and
/// a consumer that handles all of them cannot be caught out by a new one.
sealed class NaturalBlockNode {}

/// Dart lists compare by identity, so `children == other.children` would call
/// a hand-built tree different from the one the parser produced.
const _childrenEquality = ListEquality<NaturalBlockNode>();

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

/// How the things inside are arranged, and nothing else.
///
/// A [ColumnNode] stacks its content; a [RowNode] lays its cells across.
/// Neither is content itself -- they say where content goes. A document is a
/// stack of these. A [TableNode] is not one; see there.
sealed class LayoutNode extends NaturalBlockNode {}

final class ColumnNode extends LayoutNode {
  final List<ContentNode> children;

  /// The alignment written for this block, or `unstated` when none was.
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

/// What a block holds, and what gets arranged.
///
/// **Nothing here is a line.** A newline is a character, so a [TextNode] runs
/// across as many as the author wrote: three lines are one `TextNode` holding
/// two `\n`s. The tree has no line-level structure at all, which is worth
/// stating plainly, because a per-line role is exactly what a heading or a
/// list item would need.
///
/// A table is one of these, the same as a verbatim region: something written
/// between delimiters that arrives already formatted. That is what lets a
/// block hold text, a table, and more text without breaking in two, so an
/// alignment written on the block reaches all of it.
sealed class ContentNode extends NaturalBlockNode {}

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
  /// The column's alignment lives here rather than being stamped onto every
  /// cell, so a cell's own `align` keeps meaning "what this cell stated". A
  /// consumer resolves the two:
  ///
  /// ```dart
  /// final effective = cell.align == HorizontalAlign.unstated
  ///     ? table.columns[i]
  ///     : cell.align;
  /// ```
  ///
  /// Read from the rows rather than passed in, so a hand-built table cannot
  /// disagree with itself.
  late final List<HorizontalAlign> columns = _columns(children);

  /// The alignment written for the table itself, or `unstated` when none was.
  ///
  /// Where the table sits inside its block, which is not the same question
  /// as [ColumnNode.align] -- that one says how a block arranges everything
  /// it holds. `|=` centres the text and the table together; `~=` centres
  /// only the table.
  final HorizontalAlign align;

  TableNode({this.children = const [], this.align = HorizontalAlign.unstated});

  /// Taken from the first row that reached each column, so a row wider than
  /// every row before it declares the columns it adds.
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
/// the width it is given between them while these line up with the rows above
/// and below.
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
/// Holds what a block holds, and yet never another table: a cell stops at
/// `~`, so the `~` inside a table is always the one that ends it. Nesting is
/// ruled out by where the cell stops.
///
/// That is also the one thing that separates it from a [ColumnNode], which
/// reads straight through a `~` because a table is content.
final class TableCellNode extends NaturalBlockNode {
  final List<ContentNode> children;

  /// What this cell stated, which is also what its column declares when it is
  /// the first row to reach that position.
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

sealed class InlineNode extends NaturalBlockNode {}

final class TextSpanNode extends InlineNode {
  final String text;

  /// Everything the decoration syntax said about this run.
  ///
  /// One field rather than four: a run's decoration and the reader's current
  /// decoration are not two ideas that happen to match.
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
