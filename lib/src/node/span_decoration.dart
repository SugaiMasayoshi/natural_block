part of '../node.dart';

/// The decoration state a run carries, and the parser's reading state.
///
/// Immutable: [apply] returns the next state rather than mutating, so the
/// style of a finished run cannot change under it.
class SpanDecoration {
  final int sizeOffset;
  final SemanticColor color;
  final bool emphasis;
  final bool isAction;

  const SpanDecoration({
    this.sizeOffset = 0,
    this.color = SemanticColor.none,
    this.emphasis = false,
    this.isAction = false,
  });

  /// Reads the cluster the cursor has just entered and returns the state it
  /// leaves behind, together with any character a backslash rescued from it.
  ///
  /// That character is ordinary text belonging to the run that follows, and
  /// handing it back is what lets one backslash cover a whole run: past it
  /// every decoration character is literal again, so `:---\%%%` needs one
  /// backslash rather than one per character.
  (SpanDecoration, String) readCluster(SourceCursor cursor) {
    var result = this;
    while (!cursor.isEnd) {
      final char = cursor.peek;

      // A backslash that cancels nothing is an ordinary character, and the
      // cursor leaves the cursor on it -- the cluster ends either way, and
      // what the escape rescued (if anything) opens the run that follows.
      if (char == r'\') {
        return (result, cursor.takeEscape(clusterMarkup) ?? '');
      }

      final action = DecorationAction.byChar[char];
      if (action == null) return (result, '');
      cursor.take();
      result = result.apply(action);
    }
    return (result, '');
  }

  SpanDecoration apply(DecorationAction action) => switch (action) {
    DecorationAction.larger => _copy(sizeOffset: sizeOffset + 1),
    DecorationAction.smaller => _copy(sizeOffset: sizeOffset - 1),
    DecorationAction.danger => _copy(color: _toggle(SemanticColor.danger)),
    DecorationAction.success => _copy(color: _toggle(SemanticColor.success)),
    DecorationAction.emphasis => _copy(emphasis: !emphasis),
    DecorationAction.action => _copy(isAction: !isAction),
    DecorationAction.reset => _copy(
      color: SemanticColor.none,
      emphasis: false,
      isAction: false,
    ),
  };

  @override
  String toString() =>
      'SpanDecoration(sizeOffset: $sizeOffset, color: $color, '
      'emphasis: $emphasis, isAction: $isAction)';

  @override
  bool operator ==(Object other) =>
      other is SpanDecoration &&
      sizeOffset == other.sizeOffset &&
      color == other.color &&
      emphasis == other.emphasis &&
      isAction == other.isAction;

  @override
  int get hashCode => Object.hash(sizeOffset, color, emphasis, isAction);

  SemanticColor _toggle(SemanticColor next) =>
      color == next ? SemanticColor.none : next;

  SpanDecoration _copy({
    int? sizeOffset,
    SemanticColor? color,
    bool? emphasis,
    bool? isAction,
  }) => SpanDecoration(
    sizeOffset: sizeOffset ?? this.sizeOffset,
    color: color ?? this.color,
    emphasis: emphasis ?? this.emphasis,
    isAction: isAction ?? this.isAction,
  );
}
