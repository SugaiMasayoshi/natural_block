import 'package:natural_block/symbol/parser.dart';

enum SemanticRole {
  danger("!"),
  success("%"),
  info("?"),
  emphasis("*"),
  none("");

  final String char;
  const SemanticRole(this.char);

  static const Map<String, SemanticRole> _map = {
    "!": SemanticRole.danger,
    "%": SemanticRole.success,
    "?": SemanticRole.info,
    "*": SemanticRole.emphasis,
  };

  static MapSymbolParser<SemanticRole> parser() {
    return MapSymbolParser(_map, fallback: SemanticRole.none);
  }
}
