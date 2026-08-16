enum LayoutDelimiter {
  column("|"),
  row("="),
  none("none");

  final String char;
  const LayoutDelimiter(this.char);

  static const Map<String, LayoutDelimiter> _map = {
    "|": LayoutDelimiter.column,
    "=": LayoutDelimiter.row,
  };

  static LayoutDelimiter fromChar(String char) {
    return _map[char] ?? LayoutDelimiter.none;
  }
}
