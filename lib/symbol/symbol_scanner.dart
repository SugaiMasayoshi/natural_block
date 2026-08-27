class SymbolScanner<T> {
  final Map<String, T> _map;
  final T none;

  const SymbolScanner(this._map, {required this.none});

  T scan(String char) => _map[char] ?? none;
}
