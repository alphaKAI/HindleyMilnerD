/*
  Copyright (C) 2016 Akihiro Shoji <alpha.kai.net at alpha-kai-net.info>
*/
module HindleyMilnerD.util;

import HindleyMilnerD.term,
       HindleyMilnerD.type;

import std.algorithm,
       std.array,
       std.range;

/**
 * 2つの集合の差をとる。
 * A - B はA\B st x ∈A ∧ x ∉ Bを満たす集合を返す
 */
static T Sub2Groups(T, U)(T t, U u) if (is(T == U)) {
  return t.filter!(e => !u.canFind(e)).array;
}

/*
 * 最新のPhobosにはあるが、alphaKAIの開発環境ではまだ無かったのでPhobosより引用。
 */
template fold(fun...) if (fun.length >= 1) {
  auto fold(R, S...)(R r, S seed) {
    static if (S.length < 2) {
      return reduce!fun(seed, r);
    } else {
      import std.typecons : tuple;
      return reduce!fun(tuple(seed), r);
    }
  }
}

/**
 * 二つの集合 xs=[x1,x2,x3..], ys=[y1,y2,y3]が与えられたとき(ただし, |xs| = |ys|)
 * Z = {(x_i, y_i)| 0 <= i < |xs| }
 * Z = [[x1,y1],[x2,y2],[x3,y3]..]を返す。
 */
static T[] zipPairs(T, U)(T t, U u) if ((is(T == Term[]) || is (T == Type[])) && (is(U == Term[]) || is (U == Type[]))) {
  if (t.length != u.length) {
    // unify [AA[]] with [], 
    string arrayShow(Z)(Z z) {
      string[] ar;
      
      ar = z.map!(x => x.toString).array;
      
      return ar.join;
    }

    throw new TypeError("cannot unify [" ~ arrayShow(t) ~ "] with [" ~ arrayShow(u) ~ "], number of type arguments are different");
  }

  return zip(t, u).map!(t => t.array).array;
}


