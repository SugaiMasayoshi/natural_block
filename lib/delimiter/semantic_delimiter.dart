import 'package:natural_block/delimiter/parser.dart';

enum SemanticDelimiter {
  danger("!"),
  success("%"),
  info("?"),
  emphasis("*"),
  none("none");

  final String char;
  const SemanticDelimiter(this.char);

  static const Map<String, SemanticDelimiter> _map = {
    "!": SemanticDelimiter.danger,
    "%": SemanticDelimiter.success,
    "?": SemanticDelimiter.info,
    "*": SemanticDelimiter.emphasis,
  };

  static MapDelimiterParser<SemanticDelimiter> parser() {
    return MapDelimiterParser(_map, fallback: SemanticDelimiter.none);
  }
}
