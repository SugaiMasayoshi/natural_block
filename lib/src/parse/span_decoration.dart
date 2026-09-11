import 'package:natural_block/natural_block.dart';
import 'package:natural_block/src/decoration_action.dart';

extension SpanDecorationActions on SpanDecoration {
  SpanDecoration apply(DecorationAction action) => switch (action) {
    DecorationAction.larger => copy(sizeOffset: sizeOffset + 1),
    DecorationAction.smaller => copy(sizeOffset: sizeOffset - 1),
    DecorationAction.danger => copy(color: toggle(SemanticColor.danger)),
    DecorationAction.success => copy(color: toggle(SemanticColor.success)),
    DecorationAction.emphasis => copy(emphasis: !emphasis),
    DecorationAction.action => copy(isAction: !isAction),
    DecorationAction.reset => copy(
      color: SemanticColor.none,
      emphasis: false,
      isAction: false,
    ),
  };
}
