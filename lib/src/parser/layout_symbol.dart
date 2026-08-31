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

  static final Map<String, LayoutSymbol> byChar = {
    for (final symbol in LayoutSymbol.values) symbol.char: symbol,
  };
}
