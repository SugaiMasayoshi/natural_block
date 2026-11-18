library;

import 'horizontal_align.dart';

const String rowChar = '^';
const String spacerChar = '|';
const String tableChar = '~';
const String rawChar = '`';
const String clusterChar = ':';
const String escapeChar = r'\';

const Map<String, HorizontalAlign> alignMarkers = {
  '<': HorizontalAlign.start,
  '=': HorizontalAlign.center,
  '>': HorizontalAlign.end,
};

enum DecorationAction {
  larger('+'),
  smaller('-'),
  negative('!'),
  positive('%'),
  emphasis('*'),
  custom('@'),
  reset(clusterChar);

  final String char;
  const DecorationAction(this.char);

  static final Set<String> chars = byChar.keys.toSet();

  static final Map<String, DecorationAction> byChar = Map.unmodifiable({
    for (final action in DecorationAction.values) action.char: action,
  });
}

/// Where a run of text is read, which decides what ends it. `^` separates
/// cells only inside a row or a table; in a block it opens a row at the start
/// of a line and is text everywhere else. A row's cell and a table's cell end
/// runs alike; only a row's cell holds a spacer.
enum TextPlace {
  block({rawChar}),
  rowCell({rowChar, rawChar}),
  tableCell({rowChar, rawChar});

  /// The characters that end a run wherever they are, so the node they
  /// belong to can read them. A `~` ends one only at the start of a line.
  final Set<String> boundaries;

  const TextPlace(this.boundaries);
}
