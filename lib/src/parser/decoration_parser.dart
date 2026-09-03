import '../node.dart';
import '../semantic_color.dart';
import 'decoration_action.dart';
import 'literal_scanner.dart';
import 'source_scan.dart';
import 'verbatim_region.dart';

TextNode parseDecoratedLine(String lineText) {
  final scanner = LiteralScanner(lineText);
  final spans = <InlineNode>[];

  var sizeOffset = 0;
  var color = SemanticColor.none;
  var emphasis = false;
  var isAction = false;
  var inCluster = false;

  void flushSpan(String text) {
    if (text.isNotEmpty) {
      spans.add(
        TextSpanNode(
          text: text,
          sizeOffset: sizeOffset,
          color: color,
          emphasis: emphasis,
          isAction: isAction,
        ),
      );
    }
  }

  void apply(String char) {
    switch (DecorationAction.byChar[char]!) {
      case DecorationAction.larger:
        sizeOffset += 1;
      case DecorationAction.smaller:
        sizeOffset -= 1;
      case DecorationAction.danger:
        color = color == SemanticColor.danger
            ? SemanticColor.none
            : SemanticColor.danger;
      case DecorationAction.success:
        color = color == SemanticColor.success
            ? SemanticColor.none
            : SemanticColor.success;
      case DecorationAction.info:
        color = color == SemanticColor.info
            ? SemanticColor.none
            : SemanticColor.info;
      case DecorationAction.emphasis:
        emphasis = !emphasis;
      case DecorationAction.action:
        isAction = !isAction;
      case DecorationAction.reset:
        color = SemanticColor.none;
        emphasis = false;
        isAction = false;
    }
    scanner.markConsumed();
  }

  bool escapesNext() {
    final next = scanner.peekNext;
    if (escapesAlwaysActive(next)) return true;
    return inCluster ? DecorationAction.byChar.containsKey(next) : next == ':';
  }

  while (!scanner.isEnd) {
    final char = scanner.readChar();

    if (char == r'\' && escapesNext()) {
      scanner.dropCurrentChar();
      scanner.readChar();
      inCluster = false;
      continue;
    }

    if (char == verbatimFenceChar) {
      final region = verbatimRegionAt(lineText, scanner.position - 1);
      if (region != null) {
        flushSpan(scanner.consume());
        if (region.text.isNotEmpty) spans.add(VerbatimNode(text: region.text));
        scanner.skipTo(region.end);
        scanner.markConsumed();
        inCluster = false;
        continue;
      }
    }

    if (inCluster) {
      if (DecorationAction.byChar.containsKey(char)) {
        apply(char);
      } else {
        inCluster = false;
      }
      continue;
    }

    if (char == ':' && DecorationAction.byChar.containsKey(scanner.peekNext)) {
      flushSpan(scanner.consume());
      inCluster = true;
    }
  }
  flushSpan(scanner.flushRemaining());

  return TextNode(children: spans);
}
