// 【解説】[8/16] 1行の中の装飾を解析して TextNode を作る。
// 【解説】
// 【解説】 状態機械としては2状態しかない:
// 【解説】   クラスタ外 … : を見つけ、その次が装飾文字ならクラスタに入る
// 【解説】   クラスタ内 … 装飾文字が続く限り適用し続け、違う文字が来たら抜ける
// 【解説】 これが :+++ で3段階、:!* で色と太字の同時適用、を同じ規則で説明する。
// 【解説】
// 【解説】 サイズだけが加算(+1/-1)で、色・強調・アクションはトグルなのに注意。
// 【解説】 :: (reset) は色・強調・アクションを消すがサイズは消さない。軸が独立。
// 【解説】
// 【解説】 一番ややこしいのは while ループ内のエスケープ処理。
// 【解説】 実装より先に、なぜ3つの条件が要るのかを下の inline【解説】で追うとよい。
// 【解説】 次: lib/src/parser/parser.dart

import '../node.dart';
import '../semantic_color.dart';
import 'decoration_action.dart';
import 'literal_scanner.dart';

/// Parses a single line for `:`-led decoration clusters (e.g. `:!`, `:+++`,
/// or the combined `:!*`), applying each character in a cluster in order.
/// A cluster keeps extending for as long as the next character is a
/// recognized decoration character (including a further `:`, which resets
/// color/emphasis/action -- `::` is just a cluster whose only character is
/// that reset). Size, color, emphasis, and action are otherwise independent
/// axes -- no symbol resets another -- and color/emphasis/action can each
/// also be closed by repeating the symbol that opened it.
///
/// A bare `+`, `-`, `!`, `%`, `?`, `*`, or `@` with no `:` right before it is
/// always just a literal character -- these are extremely common in
/// ordinary prose (hyphenated words, numeric ranges, exclamations,
/// percentages, email addresses/mentions...) in both Japanese and English,
/// and the `:` prefix is what makes markup unambiguous without needing to
/// guess from context.
TextNode parseDecoratedLine(String lineText) {
  final scanner = LiteralScanner(lineText);
  final spans = <TextSpanNode>[];

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
      case DecorationAction.action:
        isAction = !isAction;
      case DecorationAction.reset:
        color = SemanticColor.none;
        emphasis = false;
        isAction = false;
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
      // 【解説】 3つの条件が全部必要な理由。1つでも欠けると壊れる:
      // 【解説】  char == '\'      … これがエスケープの合図
      // 【解説】  peekNext != ':'  … 無いと \: が二重処理される。クラスタはここで
      // 【解説】                      終わり、下の通常経路でも \: が処理されるため
      // 【解説】  次が装飾文字     … 無いと C:\Users\sugai の \ まで食べてしまい
      // 【解説】                      C:Userssugai になる(実際に一度そうなった)
      // 【解説】 解決したい例は :+++100:---\%off。\ でクラスタを抜けるので、以降の
      // 【解説】 装飾文字は全部ただの文字に戻る。だから %off の % 1つに \ を1つで済む。
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
