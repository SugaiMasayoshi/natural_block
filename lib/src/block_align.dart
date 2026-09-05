enum BlockAlign {
  start('<'),
  center('='),
  end('>');

  final String char;
  const BlockAlign(this.char);

  static final Map<String, BlockAlign> byChar = Map.unmodifiable({
    for (final align in BlockAlign.values) align.char: align,
  });
}
