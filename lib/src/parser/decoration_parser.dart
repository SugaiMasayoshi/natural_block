// 【解説】[11/23] 1行の中の装飾を解析して TextNode を作る。
// 【解説】
// 【解説】 状態機械としては2状態しかない:
// 【解説】   クラスタ外 … : を見つけ、その次が装飾文字ならクラスタに入る
// 【解説】   クラスタ内 … 装飾文字が続く限り適用し続け、違う文字が来たら抜ける
// 【解説】 これが :+++ で3段階、:!* で色と太字の同時適用、を同じ規則で説明する。
// 【解説】
// 【解説】 サイズだけが加算(+1/-1)で、色・強調・アクションはトグルなのに注意。
// 【解説】 :: (reset) は色・強調・アクションを消すがサイズは消さない。軸が独立。
// 【解説】
// 【解説】 while ループは特例なしの3規則だけで、上から順に読める:
// 【解説】   1. \ が記号を打ち消すなら、\ を捨てて次の文字を文字として読む
// 【解説】   2. クラスタ内なら、装飾文字は適用、それ以外で抜ける
// 【解説】   3. クラスタ外なら、: の次が装飾文字のときだけクラスタに入る
// 【解説】
// 【解説】 以前はエスケープの判定が2方式に分かれていた。\ の時点で先読みする
// 【解説】 前向きと、: の時点で1つ戻って見る後ろ向きが混在し、同じ \ に両方が
// 【解説】 発火するのを止めるためだけの peekNext != ':' という特例が要った。
// 【解説】 今は「\ の時点で、次が記号かどうかだけ見る」の一方式に統一してある。
// 【解説】
// 【解説】 何が記号かは、常に効く分を source_scan.dart が持ち、この pass だけの
// 【解説】 分(クラスタ内の装飾文字、外の :)を escapesNext が足す。3つの pass が
// 【解説】 同じ集合に合意する必要があるので、定義は1つで拡張する形にしてある。
// 【解説】 次: lib/src/parser/parser.dart（同じ書き方が | と = に対して出てくる）

import '../node.dart';
import '../semantic_color.dart';
import 'decoration_action.dart';
import 'literal_scanner.dart';
import 'source_scan.dart';
import 'verbatim_region.dart';

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

  /// Whether a backslash immediately before [next] is an escape rather than
  /// an ordinary backslash -- that is, whether [next] would be markup here
  /// if left alone.
  ///
  /// Which characters those are is exactly what differs between the two
  /// states, and it is the only thing that differs: inside a cluster every
  /// decoration character is live, while outside one only `:` is (a bare
  /// `+`, `!`, `%`... is ordinary text there, which is the whole point of
  /// the `:` prefix). A backslash before anything else is just a backslash,
  /// so a Windows path like `C:\Users` survives untouched.
  bool escapesNext() {
    final next = scanner.peekNext;
    // The always-active set -- `\`, the separators, the fence -- is
    // [escapesAlwaysActive]'s to define, and the other two passes ask the
    // same function. They step over such a pair and leave the backslash;
    // this is the one pass that removes it, so all three have to agree
    // about where a pair starts or a backslash would survive into the text.
    if (escapesAlwaysActive(next)) return true;
    // What this pass adds. Inside a cluster every decoration character is
    // live; outside one only `:` is, because a bare `+`, `!`, `%`... is
    // ordinary text there -- the whole point of the `:` prefix. A backslash
    // before anything else is just a backslash, so `C:\Users` is untouched.
    return inCluster
        ? DecorationAction.byChar.containsKey(next)
        : next == ':';
  }

  while (!scanner.isEnd) {
    final char = scanner.readChar();

    // One escape rule, checked at the backslash itself, for both states.
    // Drop the backslash, then read the character it escapes so it joins
    // the literal run as ordinary text -- reading it here is what stops it
    // being re-examined as markup on the next turn of the loop.
    //
    // Leaving the cluster is what lets one backslash cover a whole run:
    // past it every decoration character is ordinary text again, so
    // `:---\%%%` needs one backslash rather than one per character.
    if (char == r'\' && escapesNext()) {
      scanner.dropCurrentChar();
      scanner.readChar();
      inCluster = false;
      continue;
    }

    // Checked before the cluster branch, and deliberately so: inside a
    // cluster a `:` is the reset action and would be applied on sight, so
    // a region opening right after one would be swallowed. A fence means a
    // region in both states, which is also the only way three separate
    // callers can agree about where regions are.
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
      // An unclosed fence is ordinary text: fall through and let it join
      // the literal run.
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
