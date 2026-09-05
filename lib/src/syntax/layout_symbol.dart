import '../source_cursor.dart';

enum LayoutSymbol {
  column('|'),
  row('^'),
  table('~');

  final String char;
  const LayoutSymbol(this.char);

  static final Map<String, LayoutSymbol> byChar = Map.unmodifiable({
    for (final symbol in LayoutSymbol.values) symbol.char: symbol,
  });

  static final Set<String> chars = byChar.keys.toSet();
}

extension LayoutSymbolAt on SourceCursor {
  /// The layout symbol at the cursor, or null when the cursor is not on one.
  ///
  /// Every level asks this: a cell stops at any of them, a row asks whether
  /// the next one is another cell, a table whether it is the `~` that ends
  /// it. Asked through the symbol rather than its character so those
  /// questions read as what they are.
  ///
  /// An extension rather than a member, for the same reason the alphabet is
  /// an argument: the cursor moves over characters, and which of them mean
  /// something is the grammar's business.
  LayoutSymbol? get layoutSymbol => LayoutSymbol.byChar[peek];
}
