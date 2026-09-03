enum LayoutSymbol {
  column('|'),
  row('=');

  final String char;
  const LayoutSymbol(this.char);

  static final Map<String, LayoutSymbol> byChar = Map.unmodifiable({
    for (final symbol in LayoutSymbol.values) symbol.char: symbol,
  });
}
