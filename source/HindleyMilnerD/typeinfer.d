/*
  Copyright (C) 2016 Akihiro Shoji <alpha.kai.net at alpha-kai-net.info> 
*/
module HindleyMilnerD.typeinfer;

import HindleyMilnerD.util,
       HindleyMilnerD.term,
       HindleyMilnerD.type,
       HindleyMilnerD.subst,
       HindleyMilnerD.typeschema,
       HindleyMilnerD.env;

import std.array,
       std.stdio,
       std.conv;

/**
 * TypeInferはHM型推論の全体を含む。
 *
 * Groovy版が
 *「Scalaではオブジェクトだったので、 @SIngletonとして定義してある。
 * サービスメソッドを呼び出すための静的
 * import可能な変数として、static typeInferを容易してある」
 * とあったので、それに習ってSingletonな実装にした。
 * この実装方法は個人的には余り好みではないため、今後変更する可能性がある。
 *
 * なお、型チェックの全体の流れは
 *
 * showType ->  predefinedEnv
 *          ->  typeOf         ->    tp  ->  mgu
 *
 * である。
 */

class TypeInfer {
  //シングルトンぽくする
  static TypeInfer instance() {
    return new TypeInfer;
  }

  //使用済みの型変数のsuffixを管理する。
  static int n;

  static void reset() {
    n = 0;
  }

  /**
   * 名前が重ならない新規の型変数を作成する。
   */
  Tyvar newTyvar() {
    return new Tyvar("a" ~ (n++).to!string);
  }

  /**
   * 環境中にで定義された識別子xに対応する型スキーマを取得する。
   */
  TypeSchema lookup(Env e, string x) {
    return e.contains(x) ? e[x] : null;
  }

  /**
   * 型tに含まれているすべての型変数の集合(A)から、この環境に登録され
   * ているすべての型スキーマの「全称量化に関するフリー型変数の集合
   * (※1)」=(B)を除外したもの((A)-(B))を全称量化することで型スキーマ
   * を生成する。
   *
   * (※1)λx.yのとき変数xに束縛されていることを「λ束縛」と呼び、
   *     「λ束縛されていない変数」をフリー変数と呼ぶが、それと同様に、
   *     型変数に関する∀y...のとき型変数yに束縛されていることを「全
   *     称量化束縛」と呼び、「全称量化束縛」されていない型変数を「全
   *     称量化に関するフリー型変数」とする(ここで作った言葉)。
   *
   * 環境において「全称量化に関するフリー型変数」が発生するケースとい
   * うのは、具体的にはラムダ式
   *
   *    λ x . y
   *
   * において、識別子xに対応する型は、新規の型変数として環境に登録さ
   * れ、そのもとでyが型推論されるが、y解析中でのxの登場はスキーマ内
   * で全称量化されていない、という状態である。
   */
  TypeSchema gen(Env env, Type t) {
    return new TypeSchema(Sub2Groups(tyvars(t), tyvars(env)), t);
  }

  /**
   * 型に対するtyvars()は、指定した型Type t中に含まれる型変数のリスト
   * を返す。
   */
  Tyvar[] tyvars(Type t) {
    final switch (t.type) {
      case TypeType.Tyvar:
        return [cast(Tyvar)t];
      case TypeType.Arrow:
        return tyvars((cast(Arrow)t).t1) ~ tyvars((cast(Arrow)t).t2);
      // 型コンストラクタ T[a,b]のとき、Tは型変数ではない。
      case TypeType.Tycon:
        Tyvar[] tyvs = [];
        return (cast(Tycon)t).ts.fold!((tvs, elem) => tvs ~ tyvars(elem))(tyvs).array;
    }
  }

  /**
   * 型スキーマに対するtyvars()は、指定した型スキーマTypeSchema tsの
   * 型テンプレート(ts.tpe)が使用している型変数から、全称量化された変
   * 数(ts.tyvars)を除外したものを返す。これは、何かというと、型スキー
   * マの型テンプレート(TypeSchema.tpe)が含む「全称量化に関するフリー
   * 型変数)の集合」である。
   */
  Tyvar[] tyvars(TypeSchema ts) {
    return Sub2Groups(tyvars(ts.tpe), ts.tyvars);
  }

  /**
   * 環境Envに対するtyvarsは、その環境に登録されているすべての型スキー
   * マに対するtvarsの値全体を返す。
   * つまり、環境全体が含む「全称量化に関するフリー変数の集合」を返す。
   */
  Tyvar[] tyvars(Env env) {
    Tyvar[] tyvs = [];
    return env.values.fold!((acc, it) => acc ~ tyvars(it))(tyvs);
  }

  /**
   * 型tと型uのユニフィケーション。
   * 型tと型uに対してs'(t) s'(u)が一致するような、sを拡張した置換s'
   * を返す。
   */
  
  Subst mgu(Type t, Type u, Subst s) {
    auto st = s(t),
         su = s(u);

    if (st.type == TypeType.Tyvar && su.type == TypeType.Tyvar && (cast(Tyvar)st).a == (cast(Tyvar)su).a) { // 等しい型変数
      return s;
    } else if (st.type == TypeType.Tyvar) { // 左辺が型変数
      return s.extend(cast(Tyvar)st, su);
    } else if (su.type == TypeType.Tyvar) { // 右辺が型変数
      return mgu(u, t, s);
    } else if (st.type == TypeType.Arrow && su.type == TypeType.Arrow) { // Arrow同士
      return mgu((cast(Arrow)su).t1, (cast(Arrow)st).t1, mgu((cast(Arrow)su).t2, (cast(Arrow)st).t2, s));
    } else if (st.type == TypeType.Tycon && su.type == TypeType.Tycon && (cast(Tycon)st).k == (cast(Tycon)su).k) {
      return zipPairs((cast(Tycon)st).ts, (cast(Tycon)su).ts).fold!((acc, it) => mgu(it[0], it[1], acc))(s);
    }

    throw new TypeError("cannot unify " ~ st.toString ~ " with " ~ su.toString);
  }

  /**
   * エラーメッセージに含めるための、処理中の項への参照。
   */
  Term current = null;

  /**  
   *  envのもとで、eの型がt型に一致するためのsを拡張した置換s'を返す。
   *  数式で書くと以下のとおり。
   *
   *    s'(env) ├ ∈ e:s'(t)
   *  
   *  つまり、型の間の関係制約式(型変数を含む)の集合envのもとで、「eの型はtで
   *  ある」を満たすような、sを拡張した置換s'を値を返す。
   */

	Subst tp(Env env, Term e, Type t, Subst s) {
		current = e;

    final switch (e.type) {
			case TermType.Variable:
				// 変数参照eの型は、eの識別子e.xとして登録された型スキーマを実体化(全称量
				// 化された変数のリネーム)をした型である。
				TypeSchema u = lookup(env, (cast(Variable)e).x);
				if (u is null) {
					throw new TypeError("undefined: " ~ (cast(Variable)e).x);
				}

        return mgu(u.newInstance, t, s);
			case TermType.Lambda:
				// λで束縛される変数とletで束縛される変数の扱いの違いにつ
				// いて。
				// 変数(識別子)は、HMの多相型の解決において、キーとなる存在
				// である。型スキーマは変数(識別子)にのみ結びつく。変数を介
				// 在して得た型スキーマを基軸に、インスタンス化=全称量化=型
				// 変数置換が実行される。
				//
				// 識別子x,yに束縛される式が多相型であるとき、型変数の解決
				// の扱いに関して両者には違いがある。
				//
				// λx.eの場合、xに対応して環境に登録されるのは、xの型を表
				// わす新規の型変数(a = newTyvar())を型テンプレートとする型
				// スキーマ(型抽象)であり、かつaについては全称限量されない。
				// つまり「全称量化に関するフリー型変数を含む型スキーマ」に
				// なっている。
				//
				// let y=e1 in e2の場合、yに対応して環境に登録されるのは、
				// e1の型を元にして、e1中の型変数群
				// 
				// 「e1.tyvars-tyvars(e1.e)」…(*)
				// 
				// を全称限量した型スキーマ(型抽象)。例えば「new
				// TypeSchema(tyvars(e1), e1)」が登録される。(*)における、
				// tyvars(e1.e)は、e1中のフリー型変数だが、これが生じるのは、
				// λ束縛の本体の型検査の場合である。つまり
				//
				//   \ x -> let y=e1 in e2
				//
				// のように、λ本体の中にlet式が出現するときに、let束縛され
				// る識別子yのために登録される型スキーマでは、xに対応する型
				// スキーマで使用されている型変数がフリーなので全称限量対象
				// から除外される。
				// 
				// [ここでのλとletの違いがどのような動作の違いとして現われるか?]
				// 
				// Haskellで確認する。
				// 
				// ghci> let x=length in x [1,2,3]+x "abc"
				// 6
				// ghci> (\ x -> x [1,2,3]+x "abc") length
				//         <interactive>:5:12:
				//     No instance for (Num Char)
				//       arising from the literal `1'
				//     Possible fix: add an instance declaration for (Num Char)
				//     In the expression: 1
				//     In the first argument of `x', namely `[1, 2, 3]'
				//     In the first argument of `(+)', namely `x [1, 2, 3]'
				//
				// letでのxに束縛された多相関数lengthの型(a->a)における型変
				// 数aは全称限量されるので、「x [1,2,3]」と「x "abc"」それ
				// ぞれにおけるxの出現それぞれでaがリネームされ(1回目はa',
				// 二回目はa''など)、別の型変数扱いになる。そのため、a'と
				// a''がそれぞれのIntとCharに実体化されても、型エラーになら
				// ない。
				// 
				// λの場合、xの型は全称限量されない(a->a)なので、a=Intと
				// a=Charの型制約が解決できず型エラーとなる。この動作はテス
				// トケースtestTpLamP2()、testTpLetP1() で確認する。
				Tyvar a = newTyvar,
              b = newTyvar;
        Subst s1 = mgu(t, new Arrow(a, b), s);

        return tp(env ~ new Env([(cast(Lambda)e).x : new TypeSchema([], a)]), (cast(Lambda)e).e, b, s1);
			case TermType.Apply:
				Tyvar a = newTyvar;
        Subst s1 = tp(env, (cast(Apply)e).f, new Arrow(a, t), s);

        return tp(env, (cast(Apply)e).e, a, s1);
			case TermType.Let:
        // λ x ...で束縛される変数とlet x= ..in..で束縛され
        // る変数の違いについては前述の通り。
        Tyvar a = newTyvar;
        Subst s1 = tp(env, (cast(Let)e).e, a, s);
        Env env1 = env ~ new Env([(cast(Let)e).x: this.gen(s1(env), s1(a))]);

        return tp(env1, (cast(Let)e).f, t, s1);
			case TermType.LetRec:
        Tyvar a = newTyvar,
              b = newTyvar;

        Env env1 = env ~ new Env([(cast(LetRec)e).x: (new TypeSchema([], a))]);

        Subst s1 = tp(env1, (cast(LetRec)e).e, b, s);
        Subst s2 = mgu(a, b, s1);
        Env env2 = env ~ new Env([(cast(LetRec)e).x : this.gen(s2(env), s2(a))]);

        return tp(env2, (cast(LetRec)e).f, t, s2);
		}
	}

  /**
   * 環境envにおいてTerm eの型として推定される型を返す。
   */

  Type typeOf(Env env, Term e) {
    Tyvar a = newTyvar;
    return tp(env, e, a, Subst.emptySubst)(a);
  }


  /**
   * 既定義の識別子(処理系の組み込み関数もしくはライブラリ関数を想定)を
   * いくつか定義した型環境を返す。型のみの情報でありそれらに対する構
   * 文木の情報はない。
   */

  Env predefinedEnv() {
    Type                      booleanType = new Tycon("Boolean", []);
    Type                      intType     = new Tycon("Int", []);
    Type function(Type)       listType    = (Type t) => new Tycon("List", [t]);
    TypeSchema delegate(Type) gen         = (Type t) => gen(new Env, t);

    Tyvar a = newTyvar;
    
    return new Env([
        "true" : gen(booleanType),
        "false": gen(booleanType),
        "if"   : gen(new Arrow(booleanType, new Arrow(a, new Arrow(a, a)))),
        "zero" : gen(intType),
        "succ" : gen(new Arrow(intType, intType)),
        "nil"  : gen(listType(a)),
        "cons" : gen(new Arrow(a, new Arrow(listType(a), listType(a)))),
        "isEmpty" : gen(new Arrow(listType(a), booleanType)),
        "head" : gen(new Arrow(listType(a), a)),
        "tail" : gen(new Arrow(listType(a), listType(a))),
        "fix"  : gen(new Arrow(new Arrow(a, a), a))]);
  }

  /**
   * 項の型を返す。
   */
  string showType(Term e) {
    try {
      return typeOf(predefinedEnv(), e).toString();
    } catch (TypeError ex) {
      return "\n cannot type: " ~ current.toString ~ "\n reason: " ~ ex.msg;
    }
  }

  /*
    shared static thisでmain関数が実行される前にtypeInferなstaticなインスタンスを作成する。
  */
  static TypeInfer typeInfer;
  shared static this() {
    typeInfer = TypeInfer.instance();
  }
}
//グローバルなスコープで上のtypeInferが使えるようにaliasを張る
alias typeInfer = TypeInfer.typeInfer;
