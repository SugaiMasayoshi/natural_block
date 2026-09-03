enum DecorationAction {
  larger('+'),
  smaller('-'),
  danger('!'),
  success('%'),
  info('?'),
  emphasis('*'),
  action('@'),
  reset(':');

  final String char;
  const DecorationAction(this.char);

  static final Map<String, DecorationAction> byChar = Map.unmodifiable({
    for (final action in DecorationAction.values) action.char: action,
  });
}
