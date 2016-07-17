module HindleyMilnerD.typeschema;

import HindleyMilnerD.util,
       HindleyMilnerD.type,
       HindleyMilnerD.subst,
       HindleyMilnerD.typeinfer;

import std.algorithm,
       std.array;

/**
 * TypeSchemaは、型抽象(∀X.T)を表わす。
 * 型抽象とは、「型引数」を引数に取り、型変数を含むテンプレートのよう
 * なものを本体とするような、λ式のようなもの。
 *
 * TypeSchemaはTypeを継承していない。その結果、Typeの構造の途中に
 * TypeSchemaが表われることもない。
 *
 * Haskellの「forall.」は型スキーマ(型抽象)に対応しているが、このHMアル
 * ゴリズムでは型スキーマ(抽象)はトップレベルの環境における識別子に直接
 * 結びつく形でしか存在しない。つまりランクN多相を許していない。
 *
 * もしTypeSchemaが型の一種であり、型構造の任意の部分に表われ得るなら
 * (つまりmgu()やtp()の型推定の解決対象の型コンストラクタなら)、ランク
 * N多相が実現されることになる。
 */
class TypeSchema {
  /**
   * tyvarsは型抽象において全称量化された型変数の集合を表す。
   * tyvars are set of universally quantified types in the type scheme.
   *
   * tyvarsは「その外側に対して名前が衝突しないことの保証」を持った型
   * 変数である。なぜなら型スキーマの使用に際してnewInstance()するこ
   * とでtpe中でのtyvars変数の使用がリネームされるからである。
   *
   * 具体的には、プログラム中にVariable(x)の形で識別子xが使用されるとき、
   * 識別子xの型を得るために、環境に登録された「xに対応する型スキーマ」
   * を取得した上で、Type型に変換する処理(TypeSchema.newInstance())が
   * 行なわれる。newInstance()は、tpe中のtyvarsと同じ名前を持った変数
   * を、すべて重ならない新規の名前にリネーム置換したバージョンのtpe
   * を返す。
   */
  Tyvar[] tyvars;

  /**
   * 型のテンプレートを表わす。全称量化されている型変数と同じ型変数を
   * 含んでいれば、その型変数は、型スキーマがインスタンス化されるとき
   * に重ならない別名に置換される。
   */
  Type tpe;

  this(Tyvar[] tyvars, Type tpe) {
    this.tyvars = tyvars;
    this.tpe    = tpe;
  }

  /**
   * 型スキーマ(型抽象)を型に具体化する操作。
   *
   *    newInstance: TypeSchema → Type
   *
   * ちなみにgen()は反対に型から型スキーマを生み出す操作である。
   *
   *    gen: Type → TypeSchema
   * 
   * newInstance()は、全称限量指定された変数およびそれに束縛された変
   * 数(つまりフリー型変数を除いた全ての型変数)の使用を、新規の変数名
   * にリネームする。この操作の結果は、環境には左右されず、
   * TypeSchemaインスタンスのみの情報によって確定される。(変数名のシー
   * ドとなるtypeInfer.nの値には依存するが)
   * 
   * newInstance()の結果として得られる型には全称限量で指定されていた
   * 型変数は含まれない。たとえば、型スキーマ
   * 
   *    TypeSchema s = ∀ a,b . (a,b型を含む型)
   * 
   * に対して、newInstanceした結果は、
   * 
   *      s.newInstance() = (a',b'型を含む型)
   * 
   * であり、a,bは、a'b'に置換されるので、結果の型には決して現われな
   * い。
   */

  Type newInstance() {
    return tyvars.fold!((Subst s, Tyvar tv) => s.extend(tv, TypeInfer.instance.newTyvar()))(Subst.emptySubst).call(tpe);
  }

  @property override string toString() {
    return "∀ (" ~ tyvars.map!(tyvar => tyvar.toString).array.join(",") ~ ") . (" ~ tpe.toString ~ ")";
  }

  alias opEquals = Object.opEquals;
  override bool opEquals(Object obj) {
    if (cast(TypeSchema)obj) {
      return SameTyvars(this.tyvars, (cast(TypeSchema)obj).tyvars) && this.tpe == (cast(TypeSchema)obj).tpe;
    } else {
      throw new Error("Can not compare between different type values. " ~ typeof(this).stringof ~ " - " ~ typeof(obj).stringof);
    }
  }
}
