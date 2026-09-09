import 'decoration_action.dart';
import 'semantic_color.dart';

/// The decoration state a run carries, and the parser's reading state -- one
/// type, because they are one thing.
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
