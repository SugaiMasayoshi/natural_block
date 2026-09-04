enum LayoutSymbol {
  column('|'),
  row('^'),
  table('~');

  final String char;
  const LayoutSymbol(this.char);

  static final Map<String, LayoutSymbol> byChar = Map.unmodifiable({
    for (final symbol in LayoutSymbol.values) symbol.char: symbol,
  });
}
