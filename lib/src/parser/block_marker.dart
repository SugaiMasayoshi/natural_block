enum BlockMarker {
  table('~');

  final String char;
  const BlockMarker(this.char);

  static final Map<String, BlockMarker> byChar = Map.unmodifiable({
    for (final marker in BlockMarker.values) marker.char: marker,
  });
}
