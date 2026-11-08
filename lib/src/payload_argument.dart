/// What is between the parentheses when [payload] is exactly `name(...)`, as
/// `image(<source>)` is, or null. How the argument splits further is the
/// caller's to decide. It reads a custom run's text wherever that text is
/// found, in a renderer or in a tree walked before drawing:
///
/// ```dart
/// // :@note(say this slowly):@
/// payloadArgument(span.text, 'note') // 'say this slowly'
/// payloadArgument('page(fade)', 'page') // 'fade'
/// payloadArgument('page', 'page') // null
/// ```
String? payloadArgument(String payload, String name) {
  final open = '$name(';
  if (!payload.startsWith(open) || !payload.endsWith(')')) return null;
  return payload.substring(open.length, payload.length - 1);
}
