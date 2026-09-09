/// Where something sits across the width it is given.
///
/// Written as `<`, `=` or `>` directly after a separator, and nowhere else --
/// `List<String>` and `=>` are ordinary text. It lands on whatever that
/// separator opened: a `ColumnNode`, a `TableCellNode` or a `TableNode`.
///
/// A `RowNode` has none, and cannot: nothing opens a row, so there is no
/// marker to carry one. That fits what a row is -- it divides the width
/// between its cells rather than sitting in it, so there is no room left to
/// sit anywhere.
enum HorizontalAlign {
  /// No marker was written. **Not [start]**: a cell that stated nothing takes
  /// its column's alignment, and a renderer may draw an unstated block
  /// differently from one that asked for the start.
  ///
  /// A value rather than `null`, because the tree records what the source
  /// said and "the author wrote no marker here" is something it said. It also
  /// matches `SemanticColor.none`, which is the same idea for colour.
  unstated,

  start,
  center,
  end,
}
