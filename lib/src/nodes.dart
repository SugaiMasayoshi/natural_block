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
      TextNode(:final children) => children,
      TableNode(:final children) => children,
      TableRowNode(:final children) => children,
      TableCellNode(:final children) => children,
      RawNode() ||
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

/// The whole document: its blocks and rows, top to bottom.
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

/// What a document stacks: a block or a row.
sealed class LayoutNode extends NaturalBlockNode {
  LayoutNode({super.start, super.end});
}

/// A block, or one cell of a [RowNode]: its content, top to bottom.
final class ColumnNode extends LayoutNode {
  final List<ContentNode> children;

  /// The marker at the start of the block, or of the cell. A cell that wrote
  /// none takes the one before its row's opening `^`.
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
  final List<ColumnNode> children;

  RowNode({required List<ColumnNode> children, super.start, super.end})
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

/// What a block holds: text, a raw block or a table.
sealed class ContentNode extends NaturalBlockNode {
  ContentNode({super.start, super.end});
}

/// Content that holds no table: all a table's cell can hold.
sealed class FlatContentNode extends ContentNode {
  FlatContentNode({super.start, super.end});
}

/// Text over any number of lines, as runs. Its newlines are in the runs.
final class TextNode extends FlatContentNode {
  final List<InlineNode> children;

  TextNode({required List<InlineNode> children, super.start, super.end})
    : children = List.unmodifiable(children),
      assert(children.isNotEmpty, 'a text node has at least one run');

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

/// A raw region with a line break inside: text taken exactly as written,
/// drawn as a block.
final class RawNode extends FlatContentNode {
  final String text;

  RawNode({required this.text, super.start, super.end})
    : assert(text.isNotEmpty, 'an empty raw region contributes no node');

  @override
  String toString() => 'RawNode(text: $text)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RawNode && text == other.text;
  }

  @override
  int get hashCode => Object.hash(runtimeType, text);
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

/// A run inside a [TextNode].
sealed class InlineNode extends NaturalBlockNode {
  InlineNode({super.start, super.end});
}

/// A run of text with one decoration.
final class TextSpanNode extends InlineNode {
  final String text;

  final SpanDecoration decoration;

  TextSpanNode({
    required this.text,
    this.decoration = const SpanDecoration(),
    super.start,
    super.end,
  }) : assert(text.isNotEmpty, 'an empty run contributes no node');

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
/// a line.
final class RawSpanNode extends InlineNode {
  final String text;

  RawSpanNode({required this.text, super.start, super.end})
    : assert(text.isNotEmpty, 'an empty raw region contributes no node'),
      assert(!text.contains('\n'), 'a raw region with a line break is a block');

  @override
  String toString() => 'RawSpanNode(text: $text)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RawSpanNode && text == other.text;
  }

  @override
  int get hashCode => Object.hash(runtimeType, text);
}
