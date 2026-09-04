part of '../node.dart';

final class ColumnNode extends BlockNode {
  final List<LineNode> children;
  final BlockAlign align;

  ColumnNode({this.children = const [], this.align = BlockAlign.start});

  /// Reads one cell or block: everything up to the next `|` or `=`.
  ///
  /// Decides only what kind of child comes next, by looking at the cursor.
  /// Each child reads itself and stops before anything that is not its own,
  /// so nothing here needs to know how a line or a region is spelled.
  static _Parsed<ColumnNode> _parse(Scanner scanner, BlockAlign? align) {
    // The newline written against the separator that opened this block
    // belongs to that separator, which is what lets `|` sit on a line of
    // its own without opening a blank one.
    if (scanner.peek == '\n') scanner.take();

    final lines = <LineNode>[];
    String? terminator;

    while (true) {
      final line = LineNode._parse(scanner);
      if (line != null) lines.add(line);

      if (scanner.isEnd) break;
      final symbol = LayoutSymbol.byChar[scanner.peek];
      if (symbol != null) {
        terminator = scanner.take();
        break;
      }
      // Anything else means the line stopped in front of a block region.
    }

    return _Parsed(
      ColumnNode(children: lines, align: align ?? BlockAlign.start),
      terminator,
    );
  }

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

/// A node together with the symbol that ended it, or null at the source's end.
class _Parsed<T> {
  final T node;
  final String? terminator;

  const _Parsed(this.node, this.terminator);
}
