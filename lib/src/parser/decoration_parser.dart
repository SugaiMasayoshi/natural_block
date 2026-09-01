import '../node.dart';
import '../semantic_color.dart';
import 'decoration_action.dart';
import 'literal_scanner.dart';

/// Parses a single line for `:`-led decoration clusters (e.g. `:!`, `:+++`,
/// or the combined `:!*`), applying each character in a cluster in order.
/// A cluster keeps extending for as long as the next character is a
/// recognized decoration character (including a further `:`, which resets
/// color/emphasis -- `::` is just a cluster whose only character is that
/// reset). Size, color, and emphasis are otherwise independent axes -- no
/// symbol resets another -- and color/emphasis can each also be closed by
/// repeating the symbol that opened it.
///
/// A bare `+`, `-`, `!`, `%`, `?`, or `*` with no `:` right before it is
/// always just a literal character -- these are extremely common in
/// ordinary prose (hyphenated words, numeric ranges, exclamations,
/// percentages...) in both Japanese and English, and the `:` prefix is what
/// makes markup unambiguous without needing to guess from context.
TextNode parseDecoratedLine(String lineText) {
  final scanner = LiteralScanner(lineText);
  final spans = <TextSpanNode>[];

  var sizeOffset = 0;
  var color = SemanticColor.none;
  var emphasis = false;
  var inCluster = false;

  void flushSpan(String text) {
    if (text.isNotEmpty) {
      spans.add(
        TextSpanNode(
          text: text,
          sizeOffset: sizeOffset,
          color: color,
          emphasis: emphasis,
        ),
      );
    }
  }

  /// Applies a decoration character's effect to the current style and
  /// marks it consumed on [scanner].
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
      case DecorationAction.reset:
        color = SemanticColor.none;
        emphasis = false;
    }
    scanner.markConsumed();
  }

  while (!scanner.isEnd) {
    final char = scanner.readChar();

    if (inCluster) {
      // Inside a cluster the decoration characters are live, so a backslash
      // in front of one escapes it -- the mirror of `\:` outside a cluster,
      // where `:` is the character that would otherwise be markup. Ending
      // the cluster is what makes the escape work: past it every decoration
      // character is ordinary text again, so `:---\%%%` needs the one
      // backslash rather than one per character.
      //
      // The `peekNext` check keeps this from eating backslashes it has no
      // business eating: a `\` before something that was never markup (as
      // in a Windows path) stays put, exactly as it does outside a cluster.
      //
      // `\:` is deliberately excluded. A `:` is markup on both sides of a
      // cluster boundary, and the escape below already handles it -- the
      // cluster ends at the backslash either way, so by the time the `:`
      // is read the ordinary path takes over. Intercepting it here would
      // mean the same backslash gets dropped twice.
      if (char == r'\' &&
          scanner.peekNext != ':' &&
          DecorationAction.byChar.containsKey(scanner.peekNext)) {
        inCluster = false;
        scanner.markConsumed();
        continue;
      }
      if (DecorationAction.byChar.containsKey(char)) {
        apply(char);
      } else {
        inCluster = false;
      }
      continue;
    }

    if (char != ':') continue;

    if (scanner.lastWasEscaped) {
      scanner.dropPrecedingChar();
      continue;
    }

    if (!DecorationAction.byChar.containsKey(scanner.peekNext)) continue;

    flushSpan(scanner.consume());
    inCluster = true;
  }
  flushSpan(scanner.flushRemaining());

  return TextNode(children: spans);
}
