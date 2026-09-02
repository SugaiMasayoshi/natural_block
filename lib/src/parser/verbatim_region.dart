// 【解説】[5.7/16] verbatim 区間の認識規則。このファイルが唯一の真実の源。
// 【解説】
// 【解説】 verbatim は「この範囲は markup ではない」という文字列についての宣言で、
// 【解説】 レイアウトの話でも装飾の話でもない。だから3人の利用者がいる。
// 【解説】   parse()           … 中の | や = で分割しない
// 【解説】   _parseBlock       … 中の改行で行を分けない(複数行コードのため)
// 【解説】   parseDecoratedLine… 区間を VerbatimNode として出す
// 【解説】
// 【解説】 3人いるが規則の定義は1つ。手書きの複製ができないので、利用者間で
// 【解説】 認識がずれることが構造的に起きない。ここが今回の設計の要。
// 【解説】
// 【解説】 状態を持たない純関数なのも意図的。スキャナのカーソルに触らないので、
// 【解説】 誰がどの順で呼んでも答えが変わらない。

/// The character that opens and closes a verbatim region.
///
/// The fifth character in this language that is always active, alongside
/// `|`, `=`, `:` and `\`. Spending one was the price of letting a verbatim
/// region sit anywhere -- a marker built on `|` can never be inline,
/// because `|` always breaks a block. A backtick is the only free character
/// that suggests code, and it is vanishingly rare in ordinary prose in
/// either Japanese or English.
const String verbatimFenceChar = '`';

/// Where a verbatim region opening at some index actually extends to.
class VerbatimRegion {
  /// The content, with the newline against each fence already removed.
  final String text;

  /// The index just past the closing fence, where scanning resumes.
  final int end;

  const VerbatimRegion({required this.text, required this.end});
}

/// The region opening at [openIndex] in [source], or `null` if there is
/// none -- either because no fence starts there, or because it is never
/// closed.
///
/// An unclosed fence is deliberately *not* a region: it stays ordinary
/// text, so a stray backtick cannot swallow anything. Every caller looks
/// ahead and only then commits, which is what makes three separate callers
/// agree by construction rather than by care.
///
/// The fence's run length sets the closing delimiter, so `` `` `` closes at
/// `` `` `` and may contain single backticks. Without that the language
/// could not quote its own syntax.
VerbatimRegion? verbatimRegionAt(String source, int openIndex) {
  if (openIndex >= source.length ||
      source[openIndex] != verbatimFenceChar) {
    return null;
  }

  var fence = 0;
  while (openIndex + fence < source.length &&
      source[openIndex + fence] == verbatimFenceChar) {
    fence += 1;
  }

  final contentStart = openIndex + fence;
  final closer = verbatimFenceChar * fence;
  final closerStart = source.indexOf(closer, contentStart);
  if (closerStart == -1) return null;

  return VerbatimRegion(
    text: _trimFenceNewlines(source.substring(contentStart, closerStart)),
    end: closerStart + fence,
  );
}

/// Drops the newline that sits directly against each fence.
///
/// Defined as "that newline belongs to the fence" rather than as "trim a
/// blank line", because only the first is unambiguous: content ending in
/// two newlines keeps one, and a region written inline keeps exactly what
/// was typed. What it buys is that a fence can sit on its own line, the way
/// anyone writing a code block expects.
String _trimFenceNewlines(String raw) {
  var text = raw;
  if (text.startsWith('\n')) text = text.substring(1);
  if (text.endsWith('\n')) text = text.substring(0, text.length - 1);
  return text;
}
