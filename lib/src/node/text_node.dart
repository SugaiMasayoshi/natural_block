part of '../node.dart';

final class TextNode extends LineNode {
  final List<InlineNode> children;

  TextNode({this.children = const []});

  /// Reads one run of inline content, stopping in front of anything that is
  /// not its own: a separator that belongs to the block, or a verbatim
  /// region written on a line of its own.
  ///
  /// Neither is consumed. A node never eats what belongs to something else,
  /// so the caller can look at the cursor and decide what comes next.
  static TextNode _parse(Scanner scanner) {
    final symbols = {':', '\n', ...LayoutSymbol.byChar.keys};
    final children = <InlineNode>[];
    final pending = StringBuffer();
    var style = const _Decoration();

    void flush({bool atBoundary = false}) {
      var run = pending.toString();
      pending.clear();
      // The newline written against a boundary belongs to that boundary.
      if (atBoundary && run.endsWith('\n')) {
        run = run.substring(0, run.length - 1);
      }
      if (run.isEmpty) return;
      children.add(style.span(run));
    }

    while (true) {
      final scanned = scanner.read(
        symbols,
        resolveEscapes: true,
        stopBeforeVerbatim: true,
      );
      pending.write(scanned.text);

      if (scanned.atVerbatim) {
        // A region on a line of its own is a block, and so not this line's
        // to hold. Left untouched for the caller.
        if (scanner.atBlockRegion) break;
        flush();
        final text = scanner.takeVerbatim();
        if (text.isNotEmpty) children.add(VerbatimSpanNode(text: text));
        continue;
      }

      if (scanned.symbol == null) break;

      if (LayoutSymbol.byChar.containsKey(scanned.symbol)) {
        // The block's own terminator. Hand it back unconsumed.
        scanner.skipTo(scanner.position - 1);
        break;
      }

      if (scanned.symbol == '\n') {
        const fresh = _Decoration();
        if (style != fresh) {
          flush();
          style = fresh;
        }
        pending.write('\n');
        continue;
      }

      if (!DecorationAction.byChar.containsKey(scanner.peek)) {
        pending.write(':');
        continue;
      }

      flush();
      final (next, escaped) = style.readCluster(scanner);
      style = next;
      pending.write(escaped);
    }

    flush(atBoundary: true);
    return TextNode(children: children);
  }

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
