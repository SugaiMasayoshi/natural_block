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
