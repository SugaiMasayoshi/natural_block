library;

import 'package:collection/collection.dart';

import 'horizontal_align.dart';
import 'normalize_source.dart';
import 'span_decoration.dart';

/// A node of the tree the parser returns. Nodes are immutable and compare by
/// value.
sealed class NaturalBlockNode {
  /// Where in the source the parser read this node from, [start] inclusive
  /// and [end] exclusive; null for a node built by hand. The offsets count
  /// in the source with its line breaks written as `\n` and its final line
  /// break dropped, as [normalizeSource] gives it, so each `\r\n` before a
  /// node shifts it back by one from the source as saved. Lines and columns
  /// are the same in both. Neither takes part in equality.
  final int? start;
  final int? end;

  NaturalBlockNode({this.start, this.end});

  /// Every node below this one, in the order they were written.
  Iterable<NaturalBlockNode> get descendants sync* {
    final children = switch (this) {
      DocumentNode(:final children) => children,
      ColumnNode(:final children) => children,
      RowNode(:final children) => children,
      CellNode(:final children) => children,
      TextNode(:final children) => children,
      TableNode(:final children) => children,
      TableRowNode(:final children) => children,
      TableCellNode(:final children) => children,
      RawNode() ||
      SpacerNode() ||
      TextSpanNode() ||
      RawSpanNode() => const <NaturalBlockNode>[],
    };
    for (final child in children) {
      yield child;
      yield* child.descendants;
    }
  }
}

const _childrenEquality = ListEquality<NaturalBlockNode>();

/// The whole document: its blocks, rows and spacers, top to bottom.
final class DocumentNode extends NaturalBlockNode {
  final List<LayoutNode> children;

  DocumentNode({List<LayoutNode> children = const [], super.start, super.end})
    : children = List.unmodifiable(children),
      assert(
        children.every((c) => c is! ColumnNode || c.children.isNotEmpty),
        'an empty block contributes no node',
      );

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

/// What a document stacks: a block, a row or a spacer.
sealed class LayoutNode extends NaturalBlockNode {
  LayoutNode({super.start, super.end});
}

/// Layout that holds no row: all a row's cell can stack.
sealed class FlatLayoutNode extends LayoutNode {
  FlatLayoutNode({super.start, super.end});
}

/// A block: its content, top to bottom.
final class ColumnNode extends FlatLayoutNode {
  final List<ContentNode> children;

  /// The marker at the start of the block. A block in a row's cell takes the
  /// cell's, and a cell that wrote none takes the one before its row's
  /// opening `^`.
  final HorizontalAlign align;

  ColumnNode({
    List<ContentNode> children = const [],
    this.align = HorizontalAlign.unstated,
    super.start,
    super.end,
  }) : children = List.unmodifiable(children);

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

/// A row written `^…^`: cells side by side, sharing the width equally.
final class RowNode extends LayoutNode {
  final List<CellNode> children;

  RowNode({required List<CellNode> children, super.start, super.end})
    : children = List.unmodifiable(children),
      assert(children.isNotEmpty, 'a row has at least one cell');

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

/// One cell of a [RowNode]: its blocks and spacers, top to bottom. An empty
/// cell holds none, and still takes its share of the row.
final class CellNode extends NaturalBlockNode {
  final List<FlatLayoutNode> children;

  CellNode({List<FlatLayoutNode> children = const [], super.start, super.end})
    : children = List.unmodifiable(children),
      assert(
        children.every((c) => c is! ColumnNode || c.children.isNotEmpty),
        'an empty block contributes no node',
      );

  @override
  String toString() => 'CellNode(children: $children)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CellNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}

/// What a block holds: text, a raw block or a table.
sealed class ContentNode extends NaturalBlockNode {
  ContentNode({super.start, super.end});
}

/// A line of `|` alone: space that takes a share of the height left over
/// where the height is set, and none where it is not. It stands between the
/// blocks of a document, or of a row's cell, whose height is the row's.
final class SpacerNode extends FlatLayoutNode {
  /// The share it takes: how many `|` it was written with.
  final int flex;

  SpacerNode({this.flex = 1, super.start, super.end})
    : assert(flex > 0, 'a spacer is at least one `|`');

  @override
  String toString() => 'SpacerNode(flex: $flex)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpacerNode && flex == other.flex;
  }

  @override
  int get hashCode => Object.hash(runtimeType, flex);
}

/// Content that holds no table: all a table's cell can hold.
sealed class FlatContentNode extends ContentNode {
  FlatContentNode({super.start, super.end});
}

/// One line of text, as runs. A blank line has none.
final class TextNode extends FlatContentNode {
  final List<InlineNode> children;

  TextNode({required List<InlineNode> children, super.start, super.end})
    : children = List.unmodifiable(children);

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

/// A raw block: text taken exactly as written, drawn as a block. Its
/// [decoration] is the one written before its fence.
final class RawNode extends FlatContentNode {
  final String text;

  final SpanDecoration decoration;

  RawNode({
    required this.text,
    this.decoration = const SpanDecoration(),
    super.start,
    super.end,
  }) : assert(text.isNotEmpty, 'an empty raw region contributes no node');

  @override
  String toString() => 'RawNode(text: $text, decoration: $decoration)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RawNode &&
        text == other.text &&
        decoration == other.decoration;
  }

  @override
  int get hashCode => Object.hash(runtimeType, text, decoration);
}

/// A table written between `~`: rows whose columns line up.
///
/// Rows keep the cells they were written with, so they may differ in length.
final class TableNode extends ContentNode {
  final List<TableRowNode> children;

  /// Each column's alignment, taken from the first row that has the column.
  /// Its length is the table's width. A cell that states its own overrides
  /// it.
  late final List<HorizontalAlign> columns = _columns(children);

  TableNode({required List<TableRowNode> children, super.start, super.end})
    : children = List.unmodifiable(children),
      assert(children.isNotEmpty, 'a table has at least one row');

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
  String toString() => 'TableNode(children: $children, columns: $columns)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableNode &&
        _childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, _childrenEquality.hash(children));
}

/// One row of a [TableNode].
final class TableRowNode extends NaturalBlockNode {
  final List<TableCellNode> children;

  TableRowNode({required List<TableCellNode> children, super.start, super.end})
    : children = List.unmodifiable(children),
      assert(children.isNotEmpty, 'a table row has at least one cell');

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

/// One cell of a [TableRowNode].
final class TableCellNode extends NaturalBlockNode {
  final List<FlatContentNode> children;

  /// The marker at the start of this cell. [HorizontalAlign.unstated] means
  /// the column's, from [TableNode.columns].
  final HorizontalAlign align;

  TableCellNode({
    List<FlatContentNode> children = const [],
    this.align = HorizontalAlign.unstated,
    super.start,
    super.end,
  }) : children = List.unmodifiable(children);

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

/// A run inside a [TextNode]: its text, and the decoration in effect on it.
sealed class InlineNode extends NaturalBlockNode {
  final String text;

  final SpanDecoration decoration;

  InlineNode({
    required this.text,
    this.decoration = const SpanDecoration(),
    super.start,
    super.end,
  });
}

/// A run of text with one decoration.
final class TextSpanNode extends InlineNode {
  TextSpanNode({required super.text, super.decoration, super.start, super.end})
    : assert(text.isNotEmpty, 'an empty run contributes no node');

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

/// A raw region without a line break: text taken exactly as written, inside
/// a line. Its [decoration] is the one in effect around it, which its text
/// does not change.
final class RawSpanNode extends InlineNode {
  RawSpanNode({required super.text, super.decoration, super.start, super.end})
    : assert(text.isNotEmpty, 'an empty raw region contributes no node'),
      assert(!text.contains('\n'), 'a raw region with a line break is a block');

  @override
  String toString() => 'RawSpanNode(text: $text, decoration: $decoration)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RawSpanNode &&
        text == other.text &&
        decoration == other.decoration;
  }

  @override
  int get hashCode => Object.hash(runtimeType, text, decoration);
}
