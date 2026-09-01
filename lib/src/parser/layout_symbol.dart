// 【解説】[5/16] レイアウト記号の表。| と = の2つだけ。
// 【解説】 この2文字と : と \ だけが「常に効く記号」で、他は全て普通の文字。
// 【解説】 これがこの言語の衝突安全性の核心。

/// What a single layout character means, and the character that triggers
/// it. Deriving [byChar] from the enum's own values (rather than
/// hand-writing a separate map) means a value can never silently fall out
/// of sync with its lookup entry: add a case here and it's automatically
/// included in [byChar] too.
enum LayoutSymbol {
  column('|'),
  row('=');

  final String char;
  const LayoutSymbol(this.char);

  static final Map<String, LayoutSymbol> byChar = Map.unmodifiable({
    for (final symbol in LayoutSymbol.values) symbol.char: symbol,
  });
}
