part of '../node.dart';


/// A run of lines sharing one alignment, produced by the `|` separator.
///
/// The single shape behind two readings that look different in the source
/// but are structurally identical: a cell of a row, and a standalone block
/// carrying an alignment marker. Both are "these lines, aligned this way",
/// so both are this one type.
///
/// Its children are lines, and only lines. A cell holding a nested row or
/// table is not expressible today, and stating that in the type keeps a
/// later decision to allow it a deliberate, visible change rather than
/// something that silently was always possible.
final class ColumnNode extends BlockNode {
  /// The lines of this block, top to bottom.
  final List<TextNode> children;

  /// How these lines are aligned horizontally, set by an alignment marker
  /// (`<`, `^`, `>`) written immediately after the layout separator that
  /// opened this block. Defaults to [BlockAlign.start] when no marker was
  /// given.
  final BlockAlign align;

  /// Creates a block of [children] lines, positioned by [align].
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
