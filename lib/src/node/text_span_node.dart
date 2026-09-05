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

    // The scanner stops in front of everything that could end the run, so
    // this loop only has to say which of those actually do. A candidate that
    // does not -- a `:` that opens no cluster, a newline with nothing to
    // reset -- is taken as text and the read resumes.
    while (true) {
      pending.write(scanner.read(_clusterOpener));
      if (scanner.isEnd || scanner.atVerbatimFence) break;
      if (_endsRun(scanner, style)) break;
      pending.write(scanner.take());
    }

    // Only the newline-reset exit leaves the cursor on a `'\n'`; every other
    // one leaves it on a layout symbol, a fence, a `:` or the end. So which
    // exit was taken need not be tracked either.
    final outgoing = scanner.peek == '\n' ? const _Decoration() : style;

    // The newline written against a boundary belongs to that boundary.
    final atBoundary =
        scanner.isEnd || scanner.layoutSymbol != null || scanner.atBlockRegion;

    var run = pending.toString();
    if (atBoundary && run.endsWith('\n')) {
      run = run.substring(0, run.length - 1);
    }
    return (run.isEmpty ? null : TextSpanNode._of(run, style), outgoing);
  }

  /// Whether the character the cursor stopped in front of really ends the
  /// run. Peeks only -- it never moves the cursor.
  static bool _endsRun(Scanner scanner, _Decoration style) =>
      switch (scanner.peek) {
        // A newline resets decoration, so it ends a run that has some. With
        // nothing to reset it is an ordinary character in the middle of one.
        '\n' => style != const _Decoration(),
        // A `:` with no decoration character after it is ordinary text; one
        // with is the next run's cluster, and not this run's to consume.
        ':' => _opensCluster(scanner),
        // A layout symbol. Nothing else gets here.
        _ => true,
      };

  /// The one terminator the scanner cannot know about: a decoration cluster
  /// opens with `:`, which is this layer's syntax rather than the scanner's.
  static const _clusterOpener = {':'};

  static bool _opensCluster(Scanner scanner) =>
      scanner.peek == ':' &&
      DecorationAction.byChar.containsKey(scanner.peekAt(1));

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
