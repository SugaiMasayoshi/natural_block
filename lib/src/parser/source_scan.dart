// 【解説】[8/23] ソースを切る2つの走査が共有する土台。今回の分解の要。
// 【解説】
// 【解説】 レイアウト走査(| = で止まる)とブロックの行分割(\n で止まる)は、
// 【解説】 止まる文字が違うだけで同じ歩き方をしていた。エスケープ対を跨ぐ、
// 【解説】 verbatim 区間を跨ぐ、区切りで止まる。以前は2箇所に同じコードが
// 【解説】 書いてあり、片方だけ直すと黙って食い違う状態だった。
// 【解説】
// 【解説】 位置を返すだけで、文字列を書き換えない。だから「テキストを一切
// 【解説】 変えてはいけない pass」から使える。エスケープを実際に解決するのは
// 【解説】 decoration_parser 1箇所だけ、という約束がこれで守られる。
// 【解説】
// 【解説】 escapesAlwaysActive も、以前は3箇所に書かれていた集合の定義。
// 【解説】 decoration_parser はこれを「拡張」する形になっていて、
// 【解説】 言い直してはいない。3つの pass が食い違えない構造。
// 【解説】 次: lib/src/parser/decoration_action.dart

import 'layout_symbol.dart';
import 'verbatim_region.dart';

/// Whether a backslash immediately before [next] cancels markup that is
/// active no matter where in a document it appears.
///
/// The single definition of that set. Three passes have to agree about
/// where an escape starts -- the layout scan, the line split, and
/// `parseDecoratedLine` -- and they used to say so in three places. Only the
/// last of them *resolves* the escape; the other two step over the pair and
/// leave the backslash for it, so that each character is rewritten at most
/// once.
///
/// A cluster in `parseDecoratedLine` escapes more than this (every
/// decoration character is live inside one), so that pass extends this set
/// rather than restating it.
bool escapesAlwaysActive(String next) =>
    next == r'\' ||
    next == verbatimFenceChar ||
    LayoutSymbol.byChar.containsKey(next);

/// The index of the next character at or after [from] that [isDelimiter]
/// accepts, or `source.length` if there is none.
///
/// Escaped pairs and verbatim regions are stepped over rather than looked
/// inside, so neither a `\|` nor a `|` written inside a region can end the
/// run. Nothing is rewritten -- the caller gets an index and slices the
/// text itself, which is what keeps this usable by passes that must leave
/// the text exactly as they found it.
///
/// Both passes that cut the source use this: the layout scan stops at `|`
/// and `=`, the line split stops at `\n`. They are the same walk over the
/// same hazards and differ only in what they stop for, which is why they
/// are one function rather than two that must be kept in step.
int nextDelimiter(
  String source,
  int from,
  bool Function(String char) isDelimiter,
) {
  var i = from;
  while (i < source.length) {
    final char = source[i];

    if (char == r'\' &&
        i + 1 < source.length &&
        escapesAlwaysActive(source[i + 1])) {
      i += 2;
      continue;
    }

    if (char == verbatimFenceChar) {
      final region = verbatimRegionAt(source, i);
      if (region != null) {
        // An unclosed fence returns null and is ordinary text from here on,
        // which is what stops a stray backtick swallowing the rest.
        i = region.end;
        continue;
      }
    }

    if (isDelimiter(char)) return i;
    i += 1;
  }
  return source.length;
}
