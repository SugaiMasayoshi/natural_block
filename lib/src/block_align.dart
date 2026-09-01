// 【解説】[4/16] ブロックの寄せ。この後に出てくる「値から byChar を導出する」
// 【解説】 書き方の見本でもある(記号表3つが全て同じ形)。
// 【解説】 left/right ではなく start/end という命名の理由がdocに書いてある。

/// How a block is aligned within the space it's given, and the character
/// that triggers it when written immediately after an unescaped layout
/// separator (`|` or `=`). Deriving [byChar] from the enum's own values
/// (rather than hand-writing a separate map) means a value can never
/// silently fall out of sync with its lookup entry: add a case here and
/// it's automatically included in [byChar] too.
///
/// The names are [start]/[center]/[end] rather than left/right: the syntax
/// characters (`<`, `^`, `>`) point left and right, but the alignment they
/// express is direction-relative, so `start`/`end` stay the correct
/// semantic under right-to-left text as well.
enum BlockAlign {
  start('<'),
  center('^'),
  end('>');

  final String char;
  const BlockAlign(this.char);

  static final Map<String, BlockAlign> byChar = {
    for (final align in BlockAlign.values) align.char: align,
  };
}
