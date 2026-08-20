import 'package:natural_block/symbol/parser.dart';

enum SemanticSymbol {
  danger("!"),
  success("%"),
  info("?"),
  emphasis("*"),
  none("");

  final String char;
  const SemanticSymbol(this.char);

  static const Map<String, SemanticSymbol> _map = {
    "!": SemanticSymbol.danger,
    "%": SemanticSymbol.success,
    "?": SemanticSymbol.info,
    "*": SemanticSymbol.emphasis,
  };

  static MapSymbolParser<SemanticSymbol> parser() {
    return MapSymbolParser(_map, fallback: SemanticSymbol.none);
  }
}
