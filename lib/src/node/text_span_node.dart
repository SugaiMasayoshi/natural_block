part of '../node.dart';

final class TextSpanNode extends InlineNode {
  final String text;

  /// Everything the decoration syntax said about this run, as one value.
  ///
  /// The same object the parser carries while reading: a run's style and
  /// the reader's current style are the same thing, so they are one type.
  final _Decoration _style;

  TextSpanNode({
    required this.text,
    int sizeOffset = 0,
    SemanticColor color = SemanticColor.none,
    bool emphasis = false,
    bool isAction = false,
  }) : _style = _Decoration(
         sizeOffset: sizeOffset,
         color: color,
         emphasis: emphasis,
         isAction: isAction,
       );

  TextSpanNode._of(this.text, this._style);

  /// Reads one run of styled text, and the decoration state it leaves.
  ///
  /// Any cluster written at the cursor is applied first, so the run's style
  /// is settled before a character of it is read. The run then ends at the
  /// next thing that is not part of it -- a following cluster, a verbatim
  /// region, a newline that resets an open decoration, or the block's own
  /// separator -- none of which it consumes.
  static (TextSpanNode?, _Decoration) _parse(
    Scanner scanner,
    _Decoration incoming,
  ) {
    final symbols = {':', '\n', ...LayoutSymbol.byChar.keys};
    final pending = StringBuffer();
    var style = incoming;

    while (_opensCluster(scanner)) {
      scanner.take();
      final (next, escaped) = style.readCluster(scanner);
      style = next;
      pending.write(escaped);
    }

    var outgoing = style;
    var atBoundary = false;

    while (true) {
      final scanned = scanner.read(
        symbols,
        resolveEscapes: true,
        stopBeforeVerbatim: true,
      );
      pending.write(scanned.text);

      if (scanned.atVerbatim) {
        atBoundary = scanner.atBlockRegion;
        break;
      }

      if (scanned.symbol == null) {
        atBoundary = true;
        break;
      }

      if (LayoutSymbol.byChar.containsKey(scanned.symbol)) {
        scanner.skipTo(scanner.position - 1);
        atBoundary = true;
        break;
      }

      if (scanned.symbol == '\n') {
        // A newline resets decoration. When there is something to reset the
        // run ends here and the newline belongs to the fresh one after it.
        const fresh = _Decoration();
        if (style != fresh) {
          scanner.skipTo(scanner.position - 1);
          outgoing = fresh;
          break;
        }
        pending.write('\n');
        continue;
      }

      // A `:` with no decoration character after it is ordinary text; one
      // with is the next run's cluster, and not this run's to consume.
      if (DecorationAction.byChar.containsKey(scanner.peek)) {
        scanner.skipTo(scanner.position - 1);
        break;
      }
      pending.write(':');
    }

    var run = pending.toString();
    // The newline written against a boundary belongs to that boundary.
    if (atBoundary && run.endsWith('\n')) {
      run = run.substring(0, run.length - 1);
    }
    return (run.isEmpty ? null : style.span(run), outgoing);
  }

  static bool _opensCluster(Scanner scanner) =>
      scanner.peek == ':' &&
      DecorationAction.byChar.containsKey(scanner.at(scanner.position + 1));

  int get sizeOffset => _style.sizeOffset;

  SemanticColor get color => _style.color;

  bool get emphasis => _style.emphasis;

  bool get isAction => _style.isAction;

  @override
  String toString() =>
      'TextSpanNode(text: $text, sizeOffset: $sizeOffset, color: $color, '
      'emphasis: $emphasis, isAction: $isAction)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextSpanNode &&
        text == other.text &&
        _style == other._style;
  }

  @override
  int get hashCode => Object.hash(text, _style);
}

/// The decoration state a run carries, and the parser's reading state.
///
/// Immutable: [apply] returns the next state rather than mutating, so the
/// style of a finished run cannot change under it.
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

  TextSpanNode span(String text) => TextSpanNode._of(text, this);

  /// Reads the cluster the cursor has just entered and returns the state it
  /// leaves behind, together with any character a backslash rescued from it.
  ///
  /// That character is ordinary text belonging to the run that follows, and
  /// handing it back is what lets one backslash cover a whole run: past it
  /// every decoration character is literal again, so `:---\%%%` needs one
  /// backslash rather than one per character.
  (_Decoration, String) readCluster(Scanner scanner) {
    var result = this;
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

  @override
  bool operator ==(Object other) =>
      other is _Decoration &&
      sizeOffset == other.sizeOffset &&
      color == other.color &&
      emphasis == other.emphasis &&
      isAction == other.isAction;

  @override
  int get hashCode => Object.hash(sizeOffset, color, emphasis, isAction);

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
