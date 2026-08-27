import 'package:natural_block/symbol/symbol_scanner.dart';

enum SizeSymbol {
  larger('+'),
  smaller('-'),
  none('');

  final String char;
  const SizeSymbol(this.char);

  static const Map<String, SizeSymbol> _map = {
    '+': SizeSymbol.larger,
    '-': SizeSymbol.smaller,
  };

  static const scanner = SymbolScanner(_map, none: SizeSymbol.none);
}
