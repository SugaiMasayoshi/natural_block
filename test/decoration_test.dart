import 'package:natural_block/natural_block.dart';
import 'package:test/test.dart';

import 'support/show.dart';

/// One claim per line: the source, and the tree `show()` renders it as.
///
/// Decoration is three independent axes -- size, tone, and the two flags --
/// and what needs checking is how a run carries them, which values a symbol
/// sets, and where they stop. Which *character* opens what is the grid's
/// business, and that a symbol stands for its whole kind is
/// `representative_test.dart`'s.
void _table(String name, Map<String, String> cases) {
  group(name, () {
    cases.forEach((source, expected) {
      test(source.replaceAll('\n', r'\n'), () {
        expect(show(NaturalBlockParser.parse(source)), expected);
      });
    });
  });
}

void main() {
  // A symbol toggles rather than opens: the same one written again turns it
  // off, and a different one on the same axis replaces it without needing a
  // reset in between.
  _table('toggling', {
    ':!赤:!通常:%緑:%通常:*太字:*':
        'Col["赤"{negative} "通常" "緑"{positive} "通常" "太字"{*}]',
    ':!危険から:%成功へ切り替え:%最後は通常':
        'Col["危険から"{negative} "成功へ切り替え"{positive} "最後は通常"]',
    ':!危険:!普通:!!普通': 'Col["危険"{negative} "普通" "普通"]',
    ':@https://example.com:@ を参照してください':
        'Col["https://example.com"{@} " を参照してください"]',
  });

  // Nothing closes a decoration but another symbol or a boundary, so an
  // unclosed one runs on rather than being dropped.
  _table('left open', {
    '通常テキスト:!ここから文末までずっと危険状態': 'Col["通常テキスト" "ここから文末までずっと危険状態"{negative}]',
    '詳細は:@#売上データ に記載': 'Col["詳細は" "#売上データ に記載"{@}]',
  });

  // One `:` carries as many characters as follow it, which is the only way
  // to set two axes with no reset landing in between: `:!:*` is one cluster
  // whose `:` resets before `*` opens emphasis.
  _table('one cluster, several characters', {
    ':!*緊急対応': 'Col["緊急対応"{negative *}]',
    ':+!*重要': 'Col["重要"{+1 negative *}]',
    ':++!*重要': 'Col["重要"{+2 negative *}]',
    ':@*重要:@*': 'Col["重要"{* @}]',
    ':!:*結果': 'Col["結果"{*}]',
  });

  // Size accumulates, and a bare `+` or `-` is never markup -- the reason
  // the `:` prefix exists, since prose is full of both.
  _table('size', {
    ':+++大きい': 'Col["大きい"{+3}]',
    ':++大きい:--標準サイズ': 'Col["大きい"{+2} "標準サイズ"]',
    ':-少し小さい:---もっと小さい': 'Col["少し小さい"{-1} "もっと小さい"{-4}]',
    '10-20人がA+の評価、1+1^2も普通の文章': 'Row[Col["10-20人がA+の評価、1+1"], Col["2も普通の文章"]]',
    "Really?! It's on sale for 50% off, and it's *great*!":
        'Col["Really?! It\'s on sale for 50% off, and it\'s *great*!"]',
    'user@example.com': 'Col["user@example.com"]',
    'メール: a@b.jp': 'Col["メール: a@b.jp"]',
  });

  // The axes do not interfere: a symbol from one leaves the others where
  // they were.
  _table('independent axes', {
    ':++大きく:!危険': 'Col["大きく"{+2} "危険"{+2 negative}]',
    ':!危険状態:++大きく': 'Col["危険状態"{negative} "大きく"{+2 negative}]',
    ':!*重要な警告:*危険は継続:!普通': 'Col["重要な警告"{negative *} "危険は継続"{negative} "普通"]',
  });

  // `::` clears the flags and the tone but leaves the size, which is the one
  // asymmetry between the axes.
  _table('reset', {
    ':!*緊急::普通': 'Col["緊急"{negative *} "普通"]',
    ':*太字だけ::普通': 'Col["太字だけ"{*} "普通"]',
    ':!危険::普通': 'Col["危険"{negative} "普通"]',
    ':!*@赤太字押せる::通常': 'Col["赤太字押せる"{negative * @} "通常"]',
    ':+++大:@押せる::普通': 'Col["大"{+3} "押せる"{+3 @} "普通"{+3}]',
    ':!*緊急対応::': 'Col["緊急対応"{negative *}]',
  });

  // A boundary ends a decoration whether or not it was closed, so nothing
  // leaks into the next cell, block, or line.
  _table('stops at a boundary', {
    ':++大きい^右は標準': 'Row[Col["大きい"{+2}], Col["右は標準"]]',
    '|:++上は大きい|下は標準|': 'Col["上は大きい"{+2}], Col["下は標準"]',
    '||:!左は危険:!^右は通常||': 'Row[Col["左は危険"{negative}], Col["右は通常"]]',
    // A newline is a character, not a boundary -- it ends the run's
    // decoration and then sits in the text as its own run.
    '|\n:!警告: システムエラー:!\n:*補足事項:*\n'
            '|エラーコード: 500^解決策: :%管理者へ連絡:%|\n処理完了\n|':
        'Col["警告: システムエラー"{negative} "\\n" "補足事項"{*}], '
        'Row[Col["エラーコード: 500"], '
        'Col["解決策: " "管理者へ連絡"{positive}]], '
        'Col["処理完了"]',
  });
}
