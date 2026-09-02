import '../block_align.dart';
import 'block_node.dart';
import 'children_equality.dart';
import 'row_node.dart';

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
/// row cannot express: rules, striping, and cell padding are properties of a
/// table, not of the text inside it, and the decoration syntax has no way to
/// say them.
final class TableNode extends BlockNode {
  /// The rows of the table, top to bottom. Every one holds the same number
  /// of cells -- a row of a different width ends the table rather than
  /// joining it.
  final List<RowNode> children;

  /// How the table as a whole is positioned, from an alignment character in
  /// the same marker cluster that opened it -- `|~^` centers it. Meaningful
  /// because a table is sized to its content rather than filling the width,
  /// so there is room around it to be positioned within.
  final BlockAlign align;

  /// Creates a table of [children] rows, positioned by [align].
  TableNode({this.children = const [], this.align = BlockAlign.start});

  @override
  String toString() => 'TableNode(children: $children, align: $align)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableNode &&
        align == other.align &&
        childrenEquality.equals(children, other.children);
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, align, childrenEquality.hash(children));
}
