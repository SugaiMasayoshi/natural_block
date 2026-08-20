import 'package:natural_block/symbol/parser.dart';

enum LayoutSymbol {
  column("|"),
  row("="),
  none("");

  final String char;
  const LayoutSymbol(this.char);

  static const Map<String, LayoutSymbol> _map = {
    "|": LayoutSymbol.column,
    "=": LayoutSymbol.row,
  };

  static MapSymbolParser<LayoutSymbol> parser() {
    return MapSymbolParser(_map, fallback: LayoutSymbol.none);
  }
}
