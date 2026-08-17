enum SemanticMarker {
  danger("!"),
  success("%"),
  info("?"),
  emphasis("*"),
  none("none");

  final String char;
  const SemanticMarker(this.char);

  static const Map<String, SemanticMarker> _map = {
    "!": SemanticMarker.danger,
    "%": SemanticMarker.success,
    "?": SemanticMarker.info,
    "*": SemanticMarker.emphasis,
  };

  static SemanticMarker fromChar(String char) {
    return _map[char] ?? SemanticMarker.none;
  }
}
