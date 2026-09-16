/// One character for each kind of thing the parser tells apart, keyed by the
/// name the grid files show it under.
///
/// The parser decides from the character it is on and the one after it, so
/// every pair of these, in every context, passes through every decision it
/// makes. `!` stands for all decoration characters and `<` for all alignment
/// markers; `representative_test.dart` checks that standing in is sound.
// 【解説】 試す記号の一覧。キー = 一覧での表示名、値 = 実際に入力に入れる文字。
// 【解説】 'b' は「普通の文字」の代表。状況の前置きに使う 'a' と区別するため b。
// 【解説】 '!' は装飾の文字(+ - ! % * @)の代表、'<' は寄せ(< = >)の代表。
// 【解説】 代表で足りることは representative_test.dart が確かめる。
// 【解説】 '⏎' は改行の表示名で、実際の文字は '\n'。
// 【解説】 grid・性質・代表の3つのテストがこの一覧を使う。記号を足すのはここだけ。
const Map<String, String> gridTokens = {
  'b': 'b',
  '|': '|',
  '^': '^',
  '~': '~',
  '`': '`',
  ':': ':',
  '!': '!',
  r'\': r'\',
  '⏎': '\n',
  '<': '<',
};

/// Where a pair is written, keyed by the name of its grid file.
///
/// A prefix leaves at most the letter `a` in the tree, so the placeholder
/// substitution in the grid cannot mistake a prefix character for the pair's.
/// The line start is written `|\n` rather than `a\n` for that reason: the `|`
/// ends the block before it and the newline is the one a block drops at its
/// start, so nothing of the prefix reaches the tree. `cluster_escape` is the
/// one exception — its backslash can survive as text, so a `\` in its shapes
/// is the prefix's whenever the pair has no backslash of its own.
///
/// A prefix also puts the pair where a decision reads it as its *next*
/// character: in `cluster_escape` the cluster is sitting on the backslash, so
/// the pair's first character is what it escapes.
// 【解説】 状況(記号2つを書く場所)。キー = 期待値ファイルの名前、
// 【解説】 値 = 記号の前に置く文字列。
// 【解説】 どの前置きも、木に残るのは 'a' だけ(または何も残らない)。だから
// 【解説】 grid の置き換えが、前置きの文字を X や Y と取り違えることがない。
// 【解説】 行頭が 'a⏎' でなく '|⏎' なのはそのため。'|' が手前のブロックを閉じ、
// 【解説】 続く改行はブロックの始まりの改行として食べられるので、何も残らない。
// 【解説】 例外は cluster_escape で、前置きの '\' は文字として木に残ることがある。
// 【解説】 その一覧に出る '\' は、組の側に '\' がない限り前置きのもの。
// 【解説】 前置きは「記号2つを、ある判断が“次の1文字”として読む位置」に置く役も
// 【解説】 する。cluster_escape では '\' の上にいるので、X が打ち消される文字になる。
const Map<String, String> gridContexts = {
  'document': '', // 【解説】 文書の先頭
  'text': 'a', // 【解説】 文の途中
  'row_cell': 'a^', // 【解説】 行のセルの中
  'table_cell': '~', // 【解説】 表のセルの中
  'decorated': ':!a', // 【解説】 装飾が付いた run の中
  'cluster': ':!', // 【解説】 クラスタの中(まだ読み終えていない)
  'cluster_escape': r':!\', // 【解説】 クラスタの中で '\' の上にいる
  'table_row': '~a|', // 【解説】 表の行の始まり(表が | を食べた直後)
  'line_start': '|\n', // 【解説】 行頭
};
