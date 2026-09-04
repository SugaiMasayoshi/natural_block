part of '../node.dart';

sealed class LineNode extends BlockNode {
  /// Reads whichever kind of line starts here.
  ///
  /// The same shape [BlockNode] has one level up: the sealed supertype is
  /// what decides which of its subtypes a piece of source becomes, so the
  /// node holding the list does not have to know how either is spelled.
  ///
  /// Null when the line turned out to have no content -- a block with
  /// nothing in it contributes nothing.
  static LineNode? _parse(Scanner scanner) {
    if (scanner.atBlockRegion) return VerbatimNode._parse(scanner);
    final line = TextNode._parse(scanner);
    return line.children.isEmpty ? null : line;
  }
}
