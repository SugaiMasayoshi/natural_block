import 'package:natural_block/symbol/symbol_scanner.dart';

enum SemanticSymbol {
  danger('!'),
  success('%'),
  info('?'),
  emphasis('*'),
  none('');

  final String char;
  const SemanticSymbol(this.char);

  static const Map<String, SemanticSymbol> _map = {
    '!': SemanticSymbol.danger,
    '%': SemanticSymbol.success,
    '?': SemanticSymbol.info,
    '*': SemanticSymbol.emphasis,
  };

  static const scanner = SymbolScanner(_map, none: SemanticSymbol.none);
}
