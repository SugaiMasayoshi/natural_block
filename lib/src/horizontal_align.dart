// 【解説】[読む順 3/23] 寄せ。< が start、= が center、> が end。
// 【解説】
// 【解説】 unstated は「マーカーが書かれていない」で、start とは別の値。
// 【解説】 木は「ソースに何が書かれたか」を記録するので、null ではなく値にしている。
// 【解説】 unstated をどう描くかは描画側が決める。
// 【解説】 次: src/span_decoration.dart
enum HorizontalAlign { unstated, start, center, end }
