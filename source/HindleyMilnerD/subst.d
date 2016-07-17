module HindleyMilnerD.subst;

import HindleyMilnerD.util,
       HindleyMilnerD.term,
       HindleyMilnerD.type,
       HindleyMilnerD.env,
       HindleyMilnerD.typeschema;
import std.algorithm,
       std.array,
       std.stdio,
       std.conv;

/**
 * Substは「型に含まれる型変数の置換処理」を表わす。
 * Subst represent a step of substitution of type variables of polymorphic type.
 *
 * Substはcallメソッドが定義されているので、Subst(のサブクラス)のイ
 * ンスタンスに対して関数のように呼び出すことができる(Groovyの機能)。
 * 例えばx = new Subst(); x(..)と呼べるということ。
 * 2種類の引数の型に対してcallが定義されている。
 * 
 *  - call(Type)
 *    型中に含まれる型変数を置換する。
 *  - call(Env)
 *    Envに含まれるすべての型スキーマに含まれる型変数を置換したEnvを返す。
 * 
 * 実装機構としては、Substのサブクラスのインスタンス1つは、「Innerクラ
 * ス→内部クラスを含むOuterクラスのインスタンス」、それをまた含む
 * Outerクラス…というチェインを構成する。そのチェインは複数の置換処理
 * を連鎖である。callはOuterクラスのcallを呼び、という再帰処理が行なわ
 * れるので、複数の置換が適用できる。Innerクラスのインスタンスを作成す
 * るには、extendを呼ぶ。
 */
class Subst {
  /**
   * 指定した型変数の置換結果を返す。
   * SubstのOuter/Innerクラス関係から構成されるチェインを辿って探す。
   */
  //Need overriding
  Type lookup(Tyvar x) { throw new Error("Subst.lookup - Need overriding"); }
  @property override string toString() { throw new Error("Subst.toString - Need overriding"); }

  /**
   * 初期値としての空の置換を返す。
   * 任意のSubstインスタンスについて、OuterクラスのOuterクラスの…
   * という連鎖の最終端となる。
   */
  static Subst emptySubst;
  static this() {
    emptySubst = new class Subst {
      override Type lookup(Tyvar t) {
        return t;
      }

      @property override string toString() {
        return "(empty)";
      }
    };
  }

  /**
   * 型Type t中に含まれる型変数を置換した結果の型を返す。
   * 型に含まれる型変数(つまり多相型の型変数)の変数を、変化しなく
   * なるまでひたすら置換する。置換の結果がさらに置換可能であれば、
   * 置換がなされなくなるまで置換を繰り返す。(循環参照の対処はさ
   * れてないので現実装は置換がループしてないことが前提)。
   */
  Type call(Type t) {
    final switch (t.type) {
      case TypeType.Tyvar:
        Type u = lookup(cast(Tyvar)t);

        return (t.type == u.type && t == u) ? t : call(u);
        // TODO: this code could throw stack overflow in the case of cyclick substitution.
      case TypeType.Arrow:
        return new Arrow(call((cast(Arrow)t).t1), call((cast(Arrow)t).t2));
      case TypeType.Tycon:
        return new Tycon((cast(Tycon)t).k, (cast(Tycon)t).ts.map!(it => call(it)).array);
    }
  }

  /**
   * 環境Env eに含まれるすべての型スキーマに含まれる型変数を置換した
   * Envを返す。
   */
  Env call(Env env) {
    Env sEnv = new Env;

    foreach (EnvElem elem; env) {
      auto x  = elem.key,
           ts = elem.value;

      TypeSchema tmp = new TypeSchema(ts.tyvars, call(ts.tpe));

      sEnv[x] = tmp;
    }

    return sEnv;
  }

  /*
   * opCallをつかって、上のcallにディスパッチさせる
   */
  Type opCall(Type t) {
    return call(t);
  }

  Env opCall(Env env) {
    return call(env);
  }

  /**
   * Innerクラスのインスタンスを生成する操作がextend()であり、「1つの
   * 型変数を一つの型へ置換」に対応するインスタンス1つを返す。ただし
   * extendで生成されたインスタンスは、extendを呼び出した元のオブジェ
   * クト(extendにとってのthisオブジェクト) =Outerクラスのインスタン
   * スとチェインしており、さらにcallにおいて、Outerクラスを呼び出し
   * て実行した置換の結果に対して追加的に置換を行うので、元の置換に対
   * して「拡張された置換」になる。
   */
  Subst extend(Tyvar x, Type t) {
    Subst thisX = this;
    return new class Subst {
      override Type lookup(Tyvar y) {
        return x == y ? t : thisX.lookup(y);
      }

      @property override string toString() {
        return thisX.toString() ~  "\n" ~ x.toString ~ " = " ~ t.toString;
      }
    };
  }
}
