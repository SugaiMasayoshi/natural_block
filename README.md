# natural_block

A lightweight, intuitive markup language parser for Dart. `natural_block` allows you to effortlessly define complex text layouts, semantic styling, and inline typography adjustments using simple ASCII symbols.

It's perfect for chat applications, document editors, or anywhere you need a rich text structure without the heavy boilerplate of HTML or Markdown.

## Features

* **Vertical Layout (Column)**
  Use the `|` (pipe) symbol to create column blocks. Trims trailing spaces and newlines automatically.
* **Horizontal Layout (Row)**
  Use the `=` (equal) symbol to split text into horizontal row nodes.
  Layout symbols reset all decoration (size, color, emphasis) at the block boundary they create -- each block starts from a clean style.
* **Decoration clusters (`:`-led)**
  All decoration -- size, semantic color, and emphasis -- is triggered by a `:` immediately followed by one or more decoration characters, forming a *cluster*. Each character in the cluster applies in order:
  * `:+` one step larger, `:-` one step smaller -- repeat the character to stack without retyping the colon (`:+++` is +3).
  * `:!` Danger / Warning color, `:%` Success color, `:?` Info color -- each **toggles**: typing it again turns it back off.
  * `:*` Emphasis / Bold -- also toggles.
  * `::` resets color and emphasis together (a cluster whose only character is `:`). It does **not** reset the size offset.
  * Multiple characters can share one cluster to apply together, e.g. `:!*` applies Danger color and Emphasis at the same time. Two clusters typed back-to-back are *not* the same as one combined cluster -- see [Combining decorations](#combining-decorations) below.
* **Size, color, and emphasis are independent axes**
  None of them resets another. A size change survives a following color/emphasis symbol and vice versa; only a layout symbol (`|` or `=`) resets everything.
* **Bare punctuation is always literal -- no escaping needed**
  A `+`, `-`, `!`, `%`, `?`, or `*` with no `:` immediately before it is always ordinary text. This is the whole point of the `:` prefix: everyday prose like `C++`, `10-20`, `100%`, `well-known`, or `Really?!` renders completely unchanged, in both Japanese and English, with zero escaping.
* **Escape characters**
  Use `\` to escape the three symbols that are otherwise always active: `\|`, `\=`, and `\:` render as literal `|`, `=`, and `:`. A backslash before any other character (e.g. `\+`, `\!`) is *not* an escape sequence -- the backslash itself is kept in the output text.

## Getting started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  natural_block: ^1.0.0
```

Or install it via the Dart CLI:

```bash
dart pub add natural_block
```

## Usage

Create an instance of `NaturalBlockParser` and pass your markup text to the `parse` method. It will return a syntax tree (`ColumnNode`, `RowNode`, `TextNode`, `TextSpanNode`) that you can easily map to Flutter widgets like `Column`, `Row`, and `RichText`.

```dart
import 'package:natural_block/natural_block.dart';

void main() {
  final parser = NaturalBlockParser();

  // Example 1: Layout with semantic color clusters.
  // Layout symbols (| and =) reset styles at each boundary they create.
  const input1 = "|:!Danger Zone=:?Safe Zone|";
  final nodes1 = parser.parse(input1);
  print(nodes1);

  // Example 2: Inline size adjustment, stacked without retyping the colon.
  // ":++" is +2, ":--" right after is -2 more, netting back to the base size.
  const input2 = ":++Huge Text:--Normal Text";
  final nodes2 = parser.parse(input2);
  print(nodes2);

  // Example 3: Bare punctuation needs no escaping at all -- only `:`, `|`,
  // and `=` are ever active symbols, and even those can be escaped with `\`.
  const input3 = "It costs -100 and has 100% success rate.";
  final nodes3 = parser.parse(input3);
  print(nodes3);
}
```

### Combining decorations

A single cluster can carry more than one decoration character, and each is applied in order -- `:!*` turns on Danger color *and* Emphasis together:

```dart
parser.parse(":!*緊急対応"); // color: danger, emphasis: true, in one span
```

Writing two clusters back-to-back is *not* equivalent, because a `:` always continues extending the cluster it follows -- including a further `:`, which is read as a reset. `:!:*` opens Danger with `:!`, but the very next `:` is absorbed as a `::` reset before `*` opens Emphasis, so Danger is wiped out and only Emphasis survives:

```dart
parser.parse(":!*結果");  // -> color: danger, emphasis: true
parser.parse(":!:*結果"); // -> color: none,   emphasis: true  (danger was reset)
```

To combine symbols, always write them in one cluster.

For more comprehensive and advanced usage, please check the `/example` folder in the repository.

## Additional information

* **Source Code & Issues:** If you encounter any bugs, have feature requests, or want to contribute, please visit our [GitHub repository](https://github.com/SugaiMasayoshi/natural_block).
* **Contributions:** We welcome pull requests! Please ensure that all new features include unit tests covering edge cases (such as symbol escaping and boundary resets).
* **Support:** We aim to respond to issues within a few days. Feel free to open a discussion for any usage questions.
