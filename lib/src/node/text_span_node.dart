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
    final pending = StringBuffer();
    var style = incoming;

    while (_opensCluster(scanner)) {
      scanner.take();
      final (next, escaped) = style.readCluster(scanner);
      style = next;
      pending.write(escaped);
    }

    var outgoing = style;

    while (true) {
      final scanned = scanner.read(_runEndsAt);
      pending.write(scanned.text);

      if (scanned.symbol == null) break;

      if (LayoutSymbol.byChar.containsKey(scanned.symbol)) {
        scanner.skipTo(scanner.position - 1);
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

    // The newline written against a boundary belongs to that boundary. Which
    // of the five ways out of the loop was taken is not tracked: whether the
    // run stopped at a boundary is a question the cursor can answer, and
    // asking it here leaves no branch that can forget to say so.
    final atBoundary =
        scanner.isEnd ||
        LayoutSymbol.byChar.containsKey(scanner.peek) ||
        scanner.atBlockRegion;

    var run = pending.toString();
    if (atBoundary && run.endsWith('\n')) {
      run = run.substring(0, run.length - 1);
    }
    return (run.isEmpty ? null : TextSpanNode._of(run, style), outgoing);
  }

  /// The characters that can end a run. Constant, so it is built once
  /// rather than per run.
  static final Set<String> _runEndsAt = {
    ':',
    '\n',
    ...LayoutSymbol.byChar.keys,
  };

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
