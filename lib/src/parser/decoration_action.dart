/// What a single decoration character does, and the character that
/// triggers it. Deriving [byChar] from the enum's own values (rather
/// than hand-writing a separate map) means a value can never silently fall
/// out of sync with its lookup entry: add a case here and it's
/// automatically included in [byChar] too.
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

  static final Map<String, DecorationAction> byChar = {
    for (final action in DecorationAction.values) action.char: action,
  };
}
