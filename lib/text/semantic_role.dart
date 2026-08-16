enum SemanticRole {
  danger("!"),
  success("%"),
  info("?"),
  emphasis("*"),
  none("none");

  final String char;
  const SemanticRole(this.char);

  static const Map<String, SemanticRole> _map = {
    "!": SemanticRole.danger,
    "%": SemanticRole.success,
    "?": SemanticRole.info,
    "*": SemanticRole.emphasis,
  };

  static SemanticRole fromChar(String char) {
    return _map[char] ?? SemanticRole.none;
  }
}
