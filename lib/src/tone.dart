// 【解説】[読む順 2/23] トーン(良い・悪いの向き)。negative と positive と none。
// 【解説】
// 【解説】 :! が negative、:% が positive。1本の軸の両端なので、片方を書くと
// 【解説】 もう片方と入れ替わる。赤か緑かは描画側が決めることで、木が持つのは
// 【解説】 良い・悪いだけ。none は「何も書かれていない」を表す値で、null の代わり。
// 【解説】 次: src/horizontal_align.dart
enum Tone { none, negative, positive }
