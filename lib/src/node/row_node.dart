part of '../node.dart';


/// A horizontal arrangement, produced by the `=` separator.
///
/// Holds every cell of one visual row -- each child is a [ColumnNode]
/// holding that cell's stacked lines (a cell with a single line is simply a
/// one-child [ColumnNode]). The row boundary is therefore explicit
/// structure: there is no convention of grouping sibling nodes back up to
/// find where one row ends and the next begins.
final class RowNode extends BlockNode {
  /// The cells of this row, left to right; each holds that cell's stacked
  /// lines.
  final List<ColumnNode> children;

  /// Creates a row of [children] cells.
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
  int get hashCode => Object.hash(runtimeType, _childrenEquality.hash(children));
}
