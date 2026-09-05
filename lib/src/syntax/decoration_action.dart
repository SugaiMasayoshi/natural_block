enum DecorationAction {
  larger('+'),
  smaller('-'),
  danger('!'),
  success('%'),
  emphasis('*'),
  action('@'),
  reset(':');

  final String char;
  const DecorationAction(this.char);

  /// Every character that opens or closes a decoration, for asking whether
  /// a backslash in a cluster has anything to cancel.
  static final Set<String> chars = byChar.keys.toSet();

  static final Map<String, DecorationAction> byChar = Map.unmodifiable({
    for (final action in DecorationAction.values) action.char: action,
  });
}
