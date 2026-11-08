import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

void main() {
  test('payloadArgument reads name(...) and declines anything else', () {
    const expected = <String, String?>{
      'note(say this)': 'say this',
      'note()': '',
      'note(a (b) c)': 'a (b) c',
      'note( spaced )': ' spaced ',
      'notes(say this)': null,
      'note(say this) ': null,
      'note(unclosed': null,
      'note': null,
    };

    for (final MapEntry(key: text, value: argument) in expected.entries) {
      expect(payloadArgument(text, 'note'), argument, reason: '"$text"');
    }
  });
}
