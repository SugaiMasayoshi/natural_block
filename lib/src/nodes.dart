library;

import 'package:collection/collection.dart';

import 'horizontal_align.dart';
import 'span_decoration.dart';

sealed class NaturalBlockNode {}

const _childrenEquality = ListEquality<NaturalBlockNode>();

final class DocumentNode extends NaturalBlockNode {
  final List<LayoutNode> children;

  DocumentNode({List<LayoutNode> children = const []})
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

sealed class LayoutNode extends NaturalBlockNode {}

final class ColumnNode extends LayoutNode {
  final List<ContentNode> children;

  final HorizontalAlign align;

  ColumnNode({
    List<ContentNode> children = const [],
    this.align = HorizontalAlign.unstated,
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

final class RowNode extends LayoutNode {
  final List<ColumnNode> children;

  RowNode({required List<ColumnNode> children})
    : children = List.unmodifiable(children),
      assert(children.length >= 2, 'a row has at least two cells');

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

sealed class ContentNode extends NaturalBlockNode {}

sealed class FlatContentNode extends ContentNode {}

final class TextNode extends FlatContentNode {
  final List<InlineNode> children;

  TextNode({required List<InlineNode> children})
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

final class RawNode extends FlatContentNode {
  final String text;

  RawNode({required this.text})
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

final class TableNode extends ContentNode {
  final List<TableRowNode> children;

  late final List<HorizontalAlign> columns = _columns(children);

  TableNode({required List<TableRowNode> children})
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

final class TableRowNode extends NaturalBlockNode {
  final List<TableCellNode> children;

  TableRowNode({required List<TableCellNode> children})
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

final class TableCellNode extends NaturalBlockNode {
  final List<FlatContentNode> children;

  final HorizontalAlign align;

  TableCellNode({
    List<FlatContentNode> children = const [],
    this.align = HorizontalAlign.unstated,
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

sealed class InlineNode extends NaturalBlockNode {}

final class TextSpanNode extends InlineNode {
  final String text;

  final SpanDecoration decoration;

  TextSpanNode({required this.text, this.decoration = const SpanDecoration()})
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

final class RawSpanNode extends InlineNode {
  final String text;

  RawSpanNode({required this.text})
    : assert(text.isNotEmpty, 'an empty raw region contributes no node');

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
