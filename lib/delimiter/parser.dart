class MapDelimiterParser<T> {
  final Map<String, T> _map;
  final T fallback;

  const MapDelimiterParser(this._map, {required this.fallback});

  T parse(String char) => _map[char] ?? fallback;
}
