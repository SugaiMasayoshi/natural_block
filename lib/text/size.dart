enum TextSize {
  large("+"),
  small("-"),
  none("none");

  final String char;
  const TextSize(this.char);

  static const Map<String, TextSize> _map = {
    "+": TextSize.large,
    "-": TextSize.small,
  };

  static TextSize fromChar(String char) {
    return _map[char] ?? TextSize.none;
  }
}
