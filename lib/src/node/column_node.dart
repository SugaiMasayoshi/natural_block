part of '../node.dart';

final class ColumnNode extends BlockNode {
  final List<LineNode> children;
  final BlockAlign align;

  ColumnNode({this.children = const [], this.align = BlockAlign.start});

  /// Reads one cell or block: everything up to the next `|` or `=`.
  static _Parsed<ColumnNode> _parse(Scanner scanner, BlockAlign? align) {
    final origin = scanner.position;
    final lines = <LineNode>[];
    final pending = StringBuffer();
    String? terminator;
    var atStart = true;

    // The blank line a block's own symbol sits on is dropped at each end,
    // which is what lets `|` and `|~` be written on lines of their own. A
    // newline is a character now, so this trims the text rather than
    // removing a node.
    void flush({bool atEnd = false}) {
      var run = pending.toString();
      pending.clear();
      if (atStart) {
        if (run.startsWith('\n')) run = run.substring(1);
        atStart = false;
      }
      if (atEnd && run.endsWith('\n')) {
        run = run.substring(0, run.length - 1);
      }
      if (run.isEmpty) return;
      lines.add(TextNode(children: TextNode._parseInline(run)));
    }

    while (true) {
      final from = scanner.position;
      final scanned = scanner.read(
        LayoutSymbol.byChar.keys.toSet(),
        stopAtVerbatim: true,
      );
      final verbatim = scanned.verbatim;

      if (verbatim == null) {
        pending.write(scanned.text);
        terminator = scanned.symbol;
        break;
      }

      final start = from + scanned.text.length;
      final end = scanner.position;
      // Alone on its line, judged within this block: the cell's own start
      // counts as a boundary, and so does the separator that ends it.
      final next = scanner.at(end);
      final standalone =
          (start == origin || scanner.at(start - 1) == '\n') &&
          (next == '' || next == '\n' || LayoutSymbol.byChar.containsKey(next));

      if (!standalone) {
        pending.write(scanned.text);
        pending.write(scanner.source.substring(start, end));
        continue;
      }

      final before = scanned.text;
      pending.write(
        before.endsWith('\n') ? before.substring(0, before.length - 1) : before,
      );
      flush();
      lines.add(VerbatimNode(text: verbatim));
      if (!scanner.isEnd && scanner.at(end) == '\n') scanner.skipTo(end + 1);
    }

    flush(atEnd: true);
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
