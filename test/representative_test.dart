import 'package:natural_block/natural_block.dart';
import 'package:natural_block/src/markup.dart';
import 'package:test/test.dart';

import 'support/grid.dart';
import 'support/show.dart';

/// The grid writes one decoration character and one alignment marker, and
/// leaves values out. This file is what makes that sound: the rest of each
/// kind gives the same shapes, and a table says which symbol sets which
/// value.
const _decorationRepresentative = '!';
const _alignRepresentative = '<';

/// `:` is a decoration character too, but it also opens a cluster, so it
/// does not stand in for the others.
final _decorationSwaps = DecorationAction.values
    .map((action) => action.char)
    .where((char) => char != _decorationRepresentative && char != clusterChar)
    .toList();

final _alignSwaps = alignMarkers.keys
    .where((char) => char != _alignRepresentative)
    .toList();

/// The shape of [source]. With [swap], the swapped character is written back
/// as [representative] wherever it survived as text (`a!`), so only the
/// shapes are compared.
String _shape(String source, {String? swap, String? representative}) => show(
  NaturalBlockParser.parse(source),
  shapeOnly: true,
  rewriteText: swap == null
      ? null
      : (text) => text.replaceAll(swap, representative!),
);

void _swapKeepsShape(String source, String representative, List<String> swaps) {
  if (!source.contains(representative)) return;
  final expected = _shape(source);
  for (final swap in swaps) {
    expect(
      _shape(
        source.replaceAll(representative, swap),
        swap: swap,
        representative: representative,
      ),
      expected,
      reason: '$source changes shape when $representative becomes $swap',
    );
  }
}

void main() {
  test('swapping a representative for its kind keeps every shape', () {
    for (final prefix in gridContexts.values) {
      for (final x in gridTokens.values) {
        for (final y in [...gridTokens.values, '']) {
          final source = '$prefix$x$y';
          _swapKeepsShape(source, _decorationRepresentative, _decorationSwaps);
          _swapKeepsShape(source, _alignRepresentative, _alignSwaps);
        }
      }
    }
  });

  const values = {
    '<a': 'Col<["a"]',
    '=a': 'Col=["a"]',
    '>a': 'Col>["a"]',
    '~<a': 'Col[Table[<["a"]]]',
    ':+a': 'Col["a"{+1}]',
    ':++a': 'Col["a"{+2}]',
    ':-a': 'Col["a"{-1}]',
    ':+-a': 'Col["a"]',
    ':!a': 'Col["a"{negative}]',
    ':%a': 'Col["a"{positive}]',
    ':!!a': 'Col["a"]',
    ':!%a': 'Col["a"{positive}]',
    ':*a': 'Col["a"{*}]',
    ':**a': 'Col["a"]',
    ':@a': 'Col["a"{@}]',
    ':@@a': 'Col["a"]',
    ':+!*@a': 'Col["a"{+1 negative * @}]',
    // `:` clears everything but the size.
    ':+!*@:a': 'Col["a"{+1}]',
  };
  values.forEach((source, expected) {
    test('value: $source', () {
      expect(show(NaturalBlockParser.parse(source)), expected);
    });
  });
}
