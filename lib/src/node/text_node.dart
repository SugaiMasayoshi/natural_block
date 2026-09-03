part of '../node.dart';

final class TextNode extends LineNode {
  final List<InlineNode> children;

  TextNode({this.children = const []});

  static List<InlineNode> _parseInline(String line) {
    final scanner = Scanner(
      line,
      symbols: const {':'},
      resolveEscapes: true,
      stopAtVerbatim: true,
    );
    final children = <InlineNode>[];
    final pending = StringBuffer();
    var style = const _Decoration();

    void flush() {
      if (pending.isEmpty) return;
      children.add(style.span(pending.toString()));
      pending.clear();
    }

    while (true) {
      final scanned = scanner.read();
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

      if (!DecorationAction.byChar.containsKey(scanner.peek)) {
        pending.write(':');
        continue;
      }

      flush();
      final (next, escaped) = _readCluster(scanner, style);
      style = next;
      pending.write(escaped);
    }

    flush();
    return children;
  }

  static (_Decoration, String) _readCluster(
    Scanner scanner,
    _Decoration style,
  ) {
    var result = style;
    while (!scanner.isEnd) {
      final char = scanner.peek;

      if (char == r'\') {
        final mark = scanner.position;
        scanner.take();
        final next = scanner.peek;
        if (!scanner.isEnd &&
            (Scanner.escapesAlwaysActive(next) ||
                DecorationAction.byChar.containsKey(next))) {
          scanner.take();
          return (result, next);
        }
        scanner.skipTo(mark);
        return (result, '');
      }

      final action = DecorationAction.byChar[char];
      if (action == null) return (result, '');
      scanner.take();
      result = result.apply(action);
    }
    return (result, '');
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

class _Decoration {
  final int sizeOffset;
  final SemanticColor color;
  final bool emphasis;
  final bool isAction;

  const _Decoration({
    this.sizeOffset = 0,
    this.color = SemanticColor.none,
    this.emphasis = false,
    this.isAction = false,
  });

  TextSpanNode span(String text) => TextSpanNode(
    text: text,
    sizeOffset: sizeOffset,
    color: color,
    emphasis: emphasis,
    isAction: isAction,
  );

  _Decoration apply(DecorationAction action) => switch (action) {
    DecorationAction.larger => _copy(sizeOffset: sizeOffset + 1),
    DecorationAction.smaller => _copy(sizeOffset: sizeOffset - 1),
    DecorationAction.danger => _copy(color: _toggle(SemanticColor.danger)),
    DecorationAction.success => _copy(color: _toggle(SemanticColor.success)),
    DecorationAction.info => _copy(color: _toggle(SemanticColor.info)),
    DecorationAction.emphasis => _copy(emphasis: !emphasis),
    DecorationAction.action => _copy(isAction: !isAction),
    DecorationAction.reset => _copy(
      color: SemanticColor.none,
      emphasis: false,
      isAction: false,
    ),
  };

  SemanticColor _toggle(SemanticColor next) =>
      color == next ? SemanticColor.none : next;

  _Decoration _copy({
    int? sizeOffset,
    SemanticColor? color,
    bool? emphasis,
    bool? isAction,
  }) => _Decoration(
    sizeOffset: sizeOffset ?? this.sizeOffset,
    color: color ?? this.color,
    emphasis: emphasis ?? this.emphasis,
    isAction: isAction ?? this.isAction,
  );
}
