import 'package:natural_block/delimiter/parser.dart';

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

  static MapDelimiterParser<SemanticRole> parser() {
    return MapDelimiterParser(_map, fallback: SemanticRole.none);
  }
}
