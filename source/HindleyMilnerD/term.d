/*
  Copyright (C) 2016 Akihiro Shoji <alpha.kai.net at alpha-kai-net.info> 
*/
module HindleyMilnerD.term;

import HindleyMilnerD.util;

/**
 * Termおよびそのサブクラスによって構文木を構成する項を定義する。
 * 項とは以下のいずれか。
 *   - 変数(Variable)
 *   - λ抽象(Lambda)
 *   - 関数適用(Apply)
 *   - let式(Let)
 *   - letrec式(LetRec)
 */

/*
  D言語にはinstanceofがない。
  ここで、型安全なダウンキャストを実現するために、ある基底クラスの派生クラスが一意な識別子を持たせることでinstanceofを使わずに
  アップキャストされた派生クラスのインスタンスを型安全にダウンキャストを実現した。
  その識別子として、enumを用いた。
  なお、if(cast(Foo)obj)は一応instanceofのように使うことができるが、enumを用いて識別するほうが都合がよい。
  というのも
  if (cast(Foo)obj) {
  } else if(cast(Bar)obj) {}....
  と続くのは個人的に読みづらく感じる。
  それゆえD言語の言語機能であるfinal swithがつかえるenumを用いたのである。
 */

enum TermType {
  Variable,
  Lambda,
  Apply,
  Let,
  LetRec
}
// Termの抽象クラス
abstract class Term {
  // 派生クラスの識別子
  TermType type;

  this(TermType type) {
    this.type = type;
  }

  @property override string toString();
}

//変数をあらわすVariableの実装
class Variable : Term {
  string x;

  static Variable opCall(string x) {
    return new Variable(x);
  }

  this(string x) {
    super(TermType.Variable);
    this.x = x;
  }

  @property override string toString() {
    return x;
  }

  alias opEquals = Object.opEquals;
  override bool opEquals(Object obj) {
    if (cast(Variable)obj) {
      return this.x == (cast(Variable)obj).x;
    } else {
      throw new Error("Can not compare between different type values. " ~ typeid(this).stringof ~ " - " ~ typeid(obj).stringof);
    }
  }
}

//λ抽象を表すLambdaの実装
class Lambda : Term {
  string x;
  Term   e;

  static opCall(string x, Term e) {
    return new Lambda(x, e);
  }

  this (string x, Term e) {
    super(TermType.Lambda);
    this.x = x;
    this.e = e;
  }

  @property override string toString() {
    return "λ " ~ x ~ " . " ~ e.toString;
  }

  alias opEquals = Object.opEquals;
  override bool opEquals(Object obj) {
    if (cast(Lambda)obj) {
      return this.x == (cast(Lambda)obj).x && this.e == (cast(Lambda)obj).e;
    } else {
      throw new Error("Can not compare between different type values. " ~ typeid(this).stringof ~ " - " ~ typeid(obj).stringof);
    }
  }
}

class Apply : Term {
  Term f,
       e;

  static opCall(Term f, Term e) {
    return new Apply(f, e);
  }

  this (Term f, Term e) {
    super(TermType.Apply);
    this.f = f;
    this.e = e;
  }

  @property override string toString() {
    return "(" ~ f.toString ~ " " ~ e.toString ~ ")";
  }

  alias opEquals = Object.opEquals;
  override bool opEquals(Object obj) {
    if (cast(Apply)obj) {
      return this.e == (cast(Apply)obj).e && this.f == (cast(Apply)obj).f;
    } else {
      throw new Error("Can not compare between different type values. " ~ typeid(this).stringof ~ " - " ~ typeid(obj).stringof);
    }
  }
}

class Let : Term {
  string x;
  Term   e,
         f;

  static opCall(string x, Term e, Term f) {
    return new Let(x, e, f);
  }

  this (string x, Term e, Term f) {
    super(TermType.Let);
    this.x = x;
    this.e = e;
    this.f = f;
  }

  @property override string toString() {
    return "let " ~ x ~ " = " ~ e.toString ~ " in " ~ f.toString;
  }
  
  alias opEquals = Object.opEquals;
  override bool opEquals(Object obj) {
    if (cast(Let)obj) {
      return this.x == (cast(Let)obj).x && this.e == (cast(Let)obj).e && this.f == (cast(Let)obj).f;
    } else {
      throw new Error("Can not compare between different type values. " ~ typeid(this).stringof ~ " - " ~ typeid(obj).stringof);
    }
  }
}

class LetRec : Term {
  string x;
  Term   e,
         f;
  
  static opCall(string x, Term e, Term f) {
    return new LetRec(x, e, f);
  }

  this (string x, Term e, Term f) {
    super(TermType.LetRec);
    this.x = x;
    this.e = e;
    this.f = f;
  }

  @property override string toString() {
    return "letrec " ~ x ~ " = " ~ e.toString ~ " in " ~ f.toString;
  }

  alias opEquals = Object.opEquals;
  override bool opEquals(Object obj) {
    if (cast(LetRec)obj) {
      return this.x == (cast(LetRec)obj).x && this.e == (cast(LetRec)obj).e && this.f == (cast(LetRec)obj).f;
    } else {
      throw new Error("Can not compare between different type values. " ~ typeid(this).stringof ~ " - " ~ typeid(obj).stringof);
    }
  }
}
