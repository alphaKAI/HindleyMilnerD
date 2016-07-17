module HindleyMilnerD.type;

import HindleyMilnerD.util;

import std.algorithm,
       std.array;

/**
 * 型に関するエラー
 */
class TypeError : Error {
  this (string msg) {
    super(msg);
  }
}

/**
 * Typeおよびそのサブクラスによって式木の構成要素を定義する。
 * 型とは以下のいずれか。
 *  - 型変数(Tyvar)
 *  - 関数型(Arrow)
 *  - 型コンストラクタ呼び出し(Tycon)(具体型)
 * 型変数を含む型を多相型と呼ぶ。
 */

enum TypeType {
  Tyvar,
  Arrow,
  Tycon
}

abstract class Type {
  TypeType type;

  this(TypeType type) {
    this.type = type;
  }

  @property override string toString();
}

class Tyvar : Type {
  string a;

  static opCall(string a) {
    return new Tyvar(a);
  }

  this(string a) {
    super(TypeType.Tyvar);
    this.a = a;
  }

  @property override string toString() {
    return a;
  }

  alias opEquals = Object.opEquals;
  override bool opEquals(Object obj) {
    if (cast(Tyvar)obj) {
      /*      import std.stdio;
              writeln("Tyvar - opEquals");
              writeln("Tyvar - opEquals : this.a -> ", this.a);
              writeln("Tyvar - opEquals : (cast(Tyvar)obj).a -> ", (cast(Tyvar)obj).a);*/
      return this.a == (cast(Tyvar)obj).a;
    } else {
      //ERROR
      throw new Error("Can not compare between different type values. " ~ typeof(this).stringof ~ " - " ~ typeof(obj).stringof);
    }
  }
}

/**
 * Tyvar[]に==(opEquals)をオーバーロードしたかったのだが、
 * class TがあったときにT[]にopEqualsを定義するすべが見当たらなかったので実装した。
 */
bool SameTyvars(Tyvar[] tyvrs1, Tyvar[] tyvrs2) {
  if (tyvrs1.length != tyvrs2.length) {
    return false;
  }

  return tyvrs1.all!(e => tyvrs2.canFind(e));
}

class Arrow : Type {
  Type t1,
       t2;

  static opCall(Type t1, Type t2) {
    return new Arrow(t1, t2);
  }

  this(Type t1, Type t2) {
    super(TypeType.Arrow);
    this.t1 = t1;
    this.t2 = t2;
  }

  @property override string toString() {
    return "(" ~ t1.toString ~ " -> " ~ t2.toString ~ ")";
  }

  alias opEquals = Object.opEquals;
  override bool opEquals(Object obj) {
    if (cast(Arrow)obj) {
      return this.t1 == (cast(Arrow)obj).t1 && this.t2 == (cast(Arrow)obj).t2;
    } else {
      throw new Error("Can not compare between different type values. " ~ typeof(this).stringof ~ " - " ~ typeof(obj).stringof);
    }
  }
}

class Tycon : Type {
  string k;
  Type[] ts;

  static opCall(string k, Type[] ts) {
    return new Tycon(k, ts);
  }

  this (string k, Type[] ts) {
    super(TypeType.Tycon);
    this.k = k;
    this.ts = ts;
  }

  @property override string toString() {
    return k ~ "[" ~ ts.map!(t => t.toString).array.join(",") ~ "]" ;
  }

  alias opEquals = Object.opEquals;
  override bool opEquals(Object obj) {
    if (cast(Tycon)obj) {
      return this.k == (cast(Tycon)obj).k && this.ts == (cast(Tycon)obj).ts;
    } else {
      throw new Error("Can not compare between different type values. " ~ typeof(this).stringof ~ " - " ~ typeof(obj).stringof);
    }
  }
}

