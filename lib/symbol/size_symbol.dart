import 'package:natural_block/symbol/parser.dart';

enum SizeSymbol {
  plus("+"),
  minus("-"),
  none("");

  final String char;
  const SizeSymbol(this.char);

  static const Map<String, SizeSymbol> _map = {
    "+": SizeSymbol.plus,
    "-": SizeSymbol.minus,
  };

  static MapSymbolParser<SizeSymbol> parser() {
    return MapSymbolParser(_map, fallback: SizeSymbol.none);
  }
}
