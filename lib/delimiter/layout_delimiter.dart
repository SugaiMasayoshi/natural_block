import 'package:natural_block/delimiter/parser.dart';

enum LayoutDelimiter {
  column("|"),
  row("="),
  none("");

  final String char;
  const LayoutDelimiter(this.char);

  static const Map<String, LayoutDelimiter> _map = {
    "|": LayoutDelimiter.column,
    "=": LayoutDelimiter.row,
  };

  static MapDelimiterParser<LayoutDelimiter> parser() {
    return MapDelimiterParser(_map, fallback: LayoutDelimiter.none);
  }
}
