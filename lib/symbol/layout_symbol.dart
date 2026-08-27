import 'package:natural_block/symbol/symbol_scanner.dart';

enum LayoutSymbol {
  column('|'),
  row('='),
  none('');

  final String char;
  const LayoutSymbol(this.char);

  static const Map<String, LayoutSymbol> _map = {
    '|': LayoutSymbol.column,
    '=': LayoutSymbol.row,
  };

  static const scanner = SymbolScanner(_map, none: LayoutSymbol.none);
}
