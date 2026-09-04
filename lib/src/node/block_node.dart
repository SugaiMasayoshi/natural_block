part of '../node.dart';

sealed class BlockNode extends NaturalBlockNode {
  /// Reads whichever block starts here, given the alignment the separator
  /// that opened it stated. Stops in front of the `|` or `~` that ends it,
  /// which belongs to whatever arranges the blocks.
  ///
  /// The first cell is read before anything is known about what the block
  /// is, because the same text serves either reading. What the separator
  /// after it turns out to be decides who finishes the job, and the cell
  /// already read is handed on rather than re-read or re-labelled.
  static List<BlockNode> _parse(Scanner scanner, BlockAlign? align) {
    final first = ColumnNode._parse(scanner, align);
    final row = RowNode._parse(scanner, first);
    if (row != null) return [row];

    // An empty Column block is content that is not there, so it contributes
    // no node -- `左||右` is two blocks, not three.
    return first.children.isEmpty ? const [] : [first];
  }
}
