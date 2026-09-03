import 'layout_symbol.dart';
import 'verbatim_region.dart';

bool escapesAlwaysActive(String next) =>
    next == r'\' ||
    next == verbatimFenceChar ||
    LayoutSymbol.byChar.containsKey(next);

int nextDelimiter(
  String source,
  int from,
  bool Function(String char) isDelimiter,
) {
  var i = from;
  while (i < source.length) {
    final char = source[i];

    if (char == r'\' &&
        i + 1 < source.length &&
        escapesAlwaysActive(source[i + 1])) {
      i += 2;
      continue;
    }

    if (char == verbatimFenceChar) {
      final region = verbatimRegionAt(source, i);
      if (region != null) {
        i = region.end;
        continue;
      }
    }

    if (isDelimiter(char)) return i;
    i += 1;
  }
  return source.length;
}
