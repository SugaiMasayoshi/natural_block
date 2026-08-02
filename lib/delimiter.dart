enum Delimiter {
  column("|"),
  row("="),
  none("none");

  final String char;
  const Delimiter(this.char);

  static const Map<String, Delimiter> _map = {
    "|": Delimiter.column,
    "=": Delimiter.row,
  };

  static Delimiter fromChar(String char) {
    return _map[char] ?? Delimiter.none;
  }
}
