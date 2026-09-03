part of '../node.dart';

final class TextNode extends LineNode {
  final List<InlineNode> children;

  TextNode({this.children = const []});

  static List<InlineNode> _parseInline(String line) {
    final scanner = Scanner(line);
    const symbols = {':', '\n'};
    final children = <InlineNode>[];
    final pending = StringBuffer();
    var style = const _Decoration();

    void flush() {
      if (pending.isEmpty) return;
      children.add(style.span(pending.toString()));
      pending.clear();
    }

    while (true) {
      final scanned = scanner.read(
        symbols,
        resolveEscapes: true,
        stopAtVerbatim: true,
      );
      pending.write(scanned.text);

      final verbatim = scanned.verbatim;
      if (verbatim != null) {
        flush();
        if (verbatim.isNotEmpty) {
          children.add(VerbatimSpanNode(text: verbatim));
        }
        continue;
      }

      if (scanned.symbol == null) break;

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

    flush();
    return children;
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
