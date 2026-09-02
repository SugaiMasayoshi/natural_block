// 【解説】[8/21] 装飾文字の表。ここの文字は「: の直後」でだけ効く。
// 【解説】 単独の ! や % や * は常にただの文字なので、C++ や 50% や Really?! が
// 【解説】 エスケープ無しでそのまま書ける。: を前置にした唯一の理由がこれ。
// 【解説】 次: lib/src/parser/literal_scanner.dart

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

  static final Map<String, DecorationAction> byChar = Map.unmodifiable({
    for (final action in DecorationAction.values) action.char: action,
  });
}
