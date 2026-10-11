library;

import 'horizontal_align.dart';

const String columnChar = '|';
const String rowChar = '^';
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

const Set<String> layoutChars = {columnChar, rowChar};

const Set<String> contentChars = {tableChar, rawChar};

const Set<String> boundaryChars = {...layoutChars, ...contentChars};

const Set<String> textMarkup = {...boundaryChars, clusterChar};
