import HindleyMilnerD.term,
       HindleyMilnerD.type,
       HindleyMilnerD.subst,
       HindleyMilnerD.typeschema,
       HindleyMilnerD.env,
       HindleyMilnerD.typeinfer;
import std.string;
//Groovyでの実装にあったTest群
static class Tests {
  static void testTerms() {
    // 構文木の試験。
    assert (Variable("a").toString == "a");
    assert (Lambda("a", Variable("b")).toString() == "λ a . b");
    assert (Apply(Variable("a"), Variable("b")).toString == "(a b)");
  }
  
  static void testTermsEquals() {
    // 構文木に対する@Immutableが生成した自明なequalsの動作を確認(一致する場合)。
    assert (Variable("a") == Variable("a"));
    assert (Lambda("a", Variable("b")) == Lambda("a", Variable("b")));
    assert (Apply(Variable("a"), Variable("b")) == Apply(Variable("a"), Variable("b")));
    assert (Let("a", Variable("b"), Variable("c")) == Let("a", Variable("b"), Variable("c")));
    assert (LetRec("a", Variable("b"), Variable("c")) == LetRec("a", Variable("b"), Variable("c")));
  }
  
  static void testTermsNotEquals() {
    // 構文木に対する@Immutableが生成した自明なequalsの動作を確認(一致しない場合)。
    assert (Variable("a") != Variable("a0"));
    assert (Lambda("a", Variable("b")) != Lambda("a", Variable("b0")));
    assert (Apply(Variable("a"), Variable("b")) != Apply(Variable("a"), Variable("b0")));
    assert (Let("a", Variable("b"), Variable("c")) != Let("a", Variable("b"), Variable("c0")));
    assert (LetRec("a", Variable("b"), Variable("c")) != LetRec("a", Variable("b"), Variable("c0")));
  }
  
  static void testTypes1() {
    // 型の構成要素に対する@Immutableが生成した自明なtoStringの動作を確認。
    assert (Tyvar("a").toString() == "a");
    assert (Arrow(Tyvar("a"), Tyvar("b")).toString() == "(a -> b)");
    assert (Tycon("A", []).toString() == "A[]");
    assert (Tycon("A", []).toString() == "A[]");
    assert (Tycon("A", [Tyvar("b")]).toString() == "A[b]");
  }
  
  static void testTypes2() {
    // 型の構成要素に対する@Immutableが生成した自明なequalsの動作を確認。
    assert (Tyvar("a") == Tyvar("a"));
    assert (Arrow(Tyvar("a"), Tyvar("b")) == Arrow(Tyvar("a"), Tyvar("b")));
    assert (Tycon("A", []) == Tycon("A", []));
    assert (Tycon("A", []) == Tycon("A", []));
    assert (Tycon("A", [Tyvar("b")]) == Tycon("A", [Tyvar("b")]));
  }
  
  static void testSubstLookup1() {
    // substの羃等性をチェック。置換対象ではない型変数はそのものが返る。
    Subst subst0 = Subst.emptySubst;
    assert (subst0.lookup(Tyvar("a")) == Tyvar("a"));
  }
  
  static void testSubstLookup2() {
    // substの羃等性をチェック。置換対象ではない型変数はそのものが返る。
    Subst subst0 = Subst.emptySubst,
          subst1 = subst0.extend(Tyvar("a"), Tyvar("b")); // a→b

    assert (subst0.lookup(Tyvar("a")) == Tyvar("a")); // subst0は変化していない
    assert (subst0 != subst1);
    assert (subst1.lookup(Tyvar("a")) == Tyvar("b")); // a == b
    assert (subst1.lookup(Tyvar("b")) == Tyvar("b")); // b == b
  }
  
  static void testSubstCallTyvar1() {
    // substによる2段置換のテスト。
    Subst subst = Subst.emptySubst
      .extend(Tyvar("b"), Tyvar("c")) // b → c
      .extend(Tyvar("a"), Tyvar("b")); // a → b

    assert (subst(Tyvar("a")) == Tyvar("c")); // a (→b) == c
    assert (subst(Tyvar("b")) == Tyvar("c")); // b == c
    assert (subst(Tyvar("c")) == Tyvar("c")); // c == c
  }

  static void testSubstCallTyvar2() {
    // substによる2段置換のテスト。extendの順序を変更しても同じ結果 。
    Subst subst = Subst.emptySubst
      .extend(Tyvar("a"), Tyvar("b")) // a → b
      .extend(Tyvar("b"), Tyvar("c")); // b → c

    assert (subst(Tyvar("a")) == Tyvar("c")); // a (→ b) == c
    assert (subst(Tyvar("b")) == Tyvar("c")); // b == c
    assert (subst(Tyvar("c")) == Tyvar("c")); // c == c
  }
  
  static void testSubstCallTyvar3() {
    // substによる2段置換のテスト。同じ変数に対する置換は、後勝ち。
    Subst subst0 = Subst.emptySubst.extend(Tyvar("a"), Tyvar("x")); // a → b
    Subst subst1 = subst0.extend(Tyvar("a"), Tyvar("y")); // b → c

    assert (subst0(Tyvar("a")) == Tyvar("x")); // a == x
    assert (subst1(Tyvar("a")) == Tyvar("y")); // a == y
  }

  static void testSubstCallTyvar4() { // Ignore me
    // 循環参照のテスト。
    Subst subst = Subst.emptySubst
      .extend(Tyvar("a"), Tyvar("b")) // a = b
      .extend(Tyvar("b"), Tyvar("c")) // b = c
      .extend(Tyvar("c"), Tyvar("a")); // c = a
      // 循環参照に対応していない(以下をコメントアウトすると無限ループする)。
      // TODO: should avoid infinite loop
      //assert (subst(Tyvar("a")) == Tyvar("c"));
      //assert (subst(Tyvar("b")) == Tyvar("c"));
      //assert (subst(Tyvar("c")) == Tyvar("c"));
  }
  
  static void testSubstCallArrow1() {
    // Arrowへの置換
    Subst subst = Subst.emptySubst.extend(Tyvar("a"), Arrow(Tyvar("b"), Tyvar("c"))); // a → (b->c)
    
    assert (subst.lookup(Tyvar("a")) == Arrow(Tyvar("b"), Tyvar("c"))); // a == (b->c)
    assert (subst(Tyvar("a")) == Arrow(Tyvar("b"), Tyvar("c"))); // a == (b->c)
  }

  static void testSubstCallArrow2() {
    // Arrowとtyvarへの両方を含み、置換対象のtyvarをArrowが含む。
    Subst subst = Subst.emptySubst
      .extend(Tyvar("b"), Tyvar("c")) // b→c
      .extend(Tyvar("a"), Arrow(Tyvar("b"), Tyvar("c"))); // a→(b->c)
    assert (subst(Tyvar("a")) == Arrow(Tyvar("c"), Tyvar("c"))); // a==(c->c)
    
    Subst subst2 = subst.extend(Tyvar("d"), Tyvar("a"));          // d→a
    assert (subst2(Tyvar("d")) == Arrow(Tyvar("c"), Tyvar("c"))); // a==(c->c)
    
    Subst subst3 = subst.extend(Tyvar("c"), Tyvar("d"));          // c→d
    assert (subst3(Tyvar("a")) == Arrow(Tyvar("d"), Tyvar("d"))); // a==(d->d)
  }
  
  static void testSubstCallTycon1() { // a→B
    // 単相型への置換
    Subst subst = Subst.emptySubst.extend(Tyvar("a"), Tycon("B", []));

    assert (subst(Tyvar("a")) == Tycon("B", []));
  }

  static void testSubstCallTycon2() { // a→B[c,d]
    // 多相型への置換
    Subst subst = Subst.emptySubst.extend(Tyvar("a"), Tycon("B", [Tyvar("c"), Tyvar("d")]));

    assert (subst(Tyvar("a")) == Tycon("B", [Tyvar("c"), Tyvar("d")]));
  }

  static void testSubstCallTycon3() { // a→B[c,d], b → x,  c → y, d → z
    // 置換の連鎖
    Subst subst = Subst.emptySubst
      .extend(Tyvar("a"), Tycon("B", [Tyvar("c"), Tyvar("d")])) // a → B[c, d]
      .extend(Tyvar("b"), Tyvar("x")) // b → x
      .extend(Tyvar("c"), Tyvar("y")) // c → y
      .extend(Tyvar("d"), Tyvar("z")); // d → z

    assert (subst(Tyvar("a")) == Tycon("B", [Tyvar("y"), Tyvar("z")]));
    // type constructor name "b" is not substituted.
  }

  static void testSubstCallEnv1() {
    // Envに対する置換。環境に登録されている型スキーマの型変数が(フリーか否かにかかわらず)置換される。
    Subst subst = Subst.emptySubst;
    Env env = new Env;
    assert (subst(env).length == 0);

    env["x"] = new TypeSchema([Tyvar("a"), Tyvar("b")], Arrow(Tyvar("a"), Tyvar("c")));
    subst = subst.extend(Tyvar("a"), Tyvar("b"));
    
    assert (env.length == 1);
    assert (subst(env)["x"].toString == "∀ (a,b) . ((b -> c))");
  }

  static void testTypeSchemaNewInstance1() {
    // 型スキーマをnewInstance()するときに型変数が置換されることの確認
    typeInfer.reset();
    TypeSchema ts = new TypeSchema([Tyvar("a"), Tyvar("b")], Tyvar("a"));

    // where "a" is bounded
    assert (ts.tyvars == [Tyvar("a"), Tyvar("b")]);
    assert (ts.tpe == Tyvar("a"));
    assert (ts.toString == "∀ (a,b) . (a)");

    Type t1 = ts.newInstance; // "a" of ts1.tpe is replaced to "a0"
    assert (t1.toString == "a0");
  }

  static void testTypeSchemaNewInstance2() {
    // 型スキーマをnewInstance()するときにフリー型変数が置換されないことの確認
    typeInfer.reset;
    TypeSchema ts = new TypeSchema([Tyvar("a"), Tyvar("b")], Tyvar("c")); // where "c" is a free variable

    assert (ts.tyvars == [Tyvar("a"), Tyvar("b")]);
    assert (ts.tpe == Tyvar("c"));
    assert (ts.toString == "∀ (a,b) . (c)");

    Type t1 = ts.newInstance;// a,b is replaced but "c" of ts.tpe is not changed
    assert (t1.toString == "c");
  }

  static void testEnvLookup1() {
    Env e = new Env;
    // 識別子に結びつけた型スキーマが環境からlookupできること。
    e["a"] = new TypeSchema([Tyvar("a"), Tyvar("b")], Tyvar("c"));
    e["b"] = new TypeSchema([Tyvar("a"), Tyvar("b")], Arrow(Tyvar("c"), Tyvar("a")));

    assert (typeInfer.lookup(e, "a") == new TypeSchema([Tyvar("a"), Tyvar("b")], Tyvar("c")));
    assert (typeInfer.lookup(e, "b") == new TypeSchema([Tyvar("a"), Tyvar("b")], Arrow(Tyvar("c"), Tyvar("a"))));
    assert (typeInfer.lookup(e, "c") is null);
  }

  static void testGenType1() {
    Env e = new Env;

    // 型に含まれる型変数は全称量化される。
    assert (typeInfer.gen(e, Tyvar("a")) == new TypeSchema([Tyvar("a")], Tyvar("a")));
    assert (typeInfer.gen(e, Arrow(Tyvar("a"), Tyvar("b"))) == new TypeSchema([Tyvar("a"), Tyvar("b")], Arrow(Tyvar("a"), Tyvar("b"))));
  }

  static void testGenType2() {
    Env e = new Env;
    e["a"] = new TypeSchema([Tyvar("b"), Tyvar("c")], Tyvar("a")); // a is free

    // 型に含まれる型変数は全称量化されるが、
    // この環境に登録されている型スキーマでフリーな変数aは全称量化の対象外となる。

    assert (typeInfer.gen(e, Tyvar("a")) == new TypeSchema([], Tyvar("a")));
    assert (typeInfer.gen(e, Arrow(Tyvar("a"), Tyvar("b"))) == new TypeSchema([Tyvar("b")], Arrow(Tyvar("a"),Tyvar("b"))));
  }
  
  static void testNewTyvar1() {
    // 重複しない名前の新しい型変数を作成して返す。
    typeInfer.reset;
    assert (typeInfer.newTyvar == Tyvar("a0"));
    assert (typeInfer.newTyvar == Tyvar("a1"));
    assert (typeInfer.newTyvar == Tyvar("a2"));
    assert (typeInfer.newTyvar == Tyvar("a3"));

    typeInfer.reset;
    assert (typeInfer.newTyvar() == Tyvar("a0"));
    assert (typeInfer.newTyvar() == Tyvar("a1"));
    assert (typeInfer.newTyvar() == Tyvar("a2"));
    assert (typeInfer.newTyvar() == Tyvar("a3"));
  }

  static void testTyvarsType1() {
    // 型に対するtyvars()は指定した型Type t中に含まれる型変数のリストが取得できること。
    assert (typeInfer.tyvars(Tyvar("a")) == [Tyvar("a")]);
    assert (typeInfer.tyvars(Arrow(Tyvar("a"), Tyvar("b"))) == [Tyvar("a"), Tyvar("b")]);
    assert (typeInfer.tyvars(Tycon("B", [Tyvar("c"), Tyvar("d")])) == [Tyvar("c"), Tyvar("d")]);
    assert (typeInfer.tyvars(Arrow(Tycon("C",[Tyvar("a"),Tyvar("b")]),
            Tycon("C", [Tyvar("c"), Tyvar("b")]))) == [Tyvar("a"),Tyvar("b"),Tyvar("c"), Tyvar("b")]);
    // リストなので特に重複を回避していない(元のScala版もそうなっている)
    assert (typeInfer.tyvars(Tycon("C", [Arrow(Tyvar("a"), Tyvar("b")),
            Arrow(Tyvar("b"), Tyvar("c"))])) == [Tyvar("a"), Tyvar("b"), Tyvar("b"), Tyvar("c")]);
  }
  
  static void testTyvarsTypeScheume1() {
    // 型スキーマに対するtyvarsは、型本体が使用している型変数から、全
    // 称量化された変数を除外したものを返す。
    assert (typeInfer.tyvars(new TypeSchema([], Tyvar("a"))) == [Tyvar("a")]);
    assert (typeInfer.tyvars(new TypeSchema([Tyvar("a")], Tyvar("a"))) == []);
    assert (typeInfer.tyvars(new TypeSchema([Tyvar("a")], Tyvar("c"))) == [Tyvar("c")]);
    assert (typeInfer.tyvars(new TypeSchema([Tyvar("a")], Arrow(Tyvar("a"), Tyvar("b")))) == [Tyvar("b")]);
    assert (typeInfer.tyvars(new TypeSchema([Tyvar("a")], Arrow(Tyvar("a"), Tyvar("a")))) == []);
  }

  static void testTyvarsEnv1() {
    // 環境Envに対するtyvarsは、その環境に登録されているすべての型スキー
    // マに対するtvarsの値全体を返す。
    // つまり、環境全体が含む全称量化に関するフリー変数の集合を返す。
    Env e = new Env;

    e["a"] = new TypeSchema([Tyvar("b"), Tyvar("c")], Tyvar("a")); // a is free
    assert (typeInfer.tyvars(e)  == [Tyvar("a")]);

    e["b"] = new TypeSchema([Tyvar("f"), Tyvar("e")], Tyvar("d")); // d is free
    assert (SameTyvars(typeInfer.tyvars(e), [Tyvar("a"), Tyvar("d")]));
  }

  static void testMguTyvar1() { // a <=> a
    // 同じ型変数同士のユニフィケーション(一致する)
    Type left0  = Tyvar("a"),
         right0 = Tyvar("a");
    Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    Type left1  = subst(left0),
         right1 = subst(right0);
    assert (left1 == right1);
  }

  static void testMguTyvar2() { // a<=>b
    // 異る型変数同士のユニフィケーション。
    // 片一方をもう一方の型変数に一致させることで一致。
    Type left0  = Tyvar("a"),
         right0 = Tyvar("b");
    Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst); // a→b
    Type left1  = subst(left0),
         right1 = subst(right0); // (a→)b, b

    assert (left1 == right1); // b==b
  }
  
  static void testMguArrow1() { // A->B <=> A->B
    // 同じ単相Arrow同士のユニフィケーション。成功する。
    Type left0  = Arrow(Tycon("A", []), Tycon("B", [])),
         right0 = Arrow(Tycon("A", []), Tycon("B", []));
    Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    Type left1  = subst(left0),
         right1 = subst(right0);
    
    assert (left1 == right1);
  }

  static void testMguArrow2() { // A->B <=> A->C
    // 異る型の単相Arrow同士のユニフィケーション。失敗する。
    Type left0  = Arrow(Tycon("A", []), Tycon("B", [])),
         right0 = Arrow(Tycon("A", []), Tycon("C", []));
    bool failed;

    try {
      Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    } catch (TypeError e) {
      failed = true;
      assert (e.msg == "cannot unify C[] with B[]");
    }

    assert (failed);
  }
  
  static void testMguArrowP1() { // a->b <=> c->d
    // 多相Arrow同士のユニフィケーション。成功する。
    Type left0  = Arrow(Tyvar("a"), Tyvar("b")),
         right0 = Arrow(Tyvar("c"), Tyvar("d"));
    Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    Type left1  = subst(left0),
         right1 = subst(right0);
    
    assert (left1 == right1);
  }

  static void testMguArrowP2() { // A->B <=> A->c
    // 単相Arrowと多相Arrowのユニフィケーション。成功する。
    Type left0  = Arrow(Tycon("A", []), Tycon("B", [])),
         right0 = Arrow(Tycon("A", []), Tyvar("c"));
    Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    Type left1  = subst(left0),
         right1 = subst(right0);

    assert (left1 == right1);
    assert (right1 == Arrow(Tycon("A", []), Tycon("B", [])));
  }

  static void testMguArrowP3() { // a->B <=> C->d
    // 単相Arrowと多相Arrowのユニフィケーション。成功する。
    Type left0  = Arrow(Tyvar("a"), Tycon("B", [])),
         right0 = Arrow(Tycon("C", []), Tyvar("d"));
    Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    Type left1  = subst(left0),
         right1 = subst(right0);
    
    assert (left1  == right1);
    assert (left1  == Arrow(Tycon("C", []), Tycon("B", [])));
    assert (right1 == Arrow(Tycon("C", []), Tycon("B", [])));
  }
  
  static void testMguTycon1() { // A[] <=> A[]
    // 同じ単相型コンストラクタ同士のユニフィケーション(一致する)
    Type left0  = Tycon("A", []),
         right0 = Tycon("A", []);
    Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    Type left1  = subst(left0),
         right1 = subst(right0);

    assert (left1 == right1);
  }

  static void testMguTycon2() { // A[] <=> B[]
    // 異なる単相型コンストラクタ同士のユニフィケーション。
    // 一致する置換はないので型エラー。
    Type left0  = Tycon("A", []),
         right0 = Tycon("B", []);
    bool failed;

    try {
      Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    } catch (TypeError e) {
      failed = true;
      assert (e.msg == "cannot unify A[] with B[]");
    }

    assert (failed);
  }

  static void testMguTycon3() { // A[AA] <=> A[]
    // 異なる単相型コンストラクタ同士(引数の個数が異なる)のユニフィケーション。 
    // 一致する置換はないので型エラー。
    // unify A[AA] and A[]. it fails because there is no valid substitution.
    Type left0  = Tycon("A", [Tycon("AA", [])]),
         right0 = Tycon("A", []);
    bool failed;

    try {
      Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    } catch (TypeError e) {
      failed = true;
      assert (e.msg == "cannot unify [AA[]] with [], number of type arguments are different");
    }

    assert (failed);
  }

  static void testMguTycon4() { // A[AA] <=> A[AB]
    // 異なる単相型コンストラクタ同士(引数の値が異なる)のユニフィケーション。
    // 一致する置換はないので型エラー。
    // unify A[AA] and A[AB]. it fails because there is no valid substitution.
    Type left0  = Tycon("A", [Tycon("AA", [])]),
         right0 = Tycon("A", [Tycon("AB", [])]);
    bool failed;

    try {
      Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    } catch (TypeError e) {
      failed = true;
      assert (e.msg == "cannot unify AA[] with AB[]");
    }

    assert (failed);
  }

  
  static void testMguTyconP1() { // A[a] <=> A[a]
    // 同じ多相型コンストラクタ同士のユニフィケーション(一致する)
    // unify A[a] and A[a]. success (trivial).
    Type left0  = Tycon("A", [Tyvar("a")]),
         right0 = Tycon("A", [Tyvar("a")]);
    Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    Type left1  = subst(left0),
         right1 = subst(right0);
    
    assert (left1 == right1);
  }

  static void testMguTyconP2() { // A[a] <=> A[b]
    // 引数が異なる型変数の多相型コンストラクタ同士のユニフィケーション。
    // 型変数同士のmguによって一致する。(b=a)
    // unify A[a] and A[b]. success with substitiution of b->a (or a->b)
    Type left0  = Tycon("A", [Tyvar("a")]),
         right0 = Tycon("A", [Tyvar("b")]);
    Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    Type left1  = subst(left0),
         right1 = subst(right0);

    assert (left1 == right1);
  }

  static void testMguTyconP3() { // A[a] <=> A[] (TypeError!)
    // 異なる多相型コンストラクタ同士(引数の個数が異なる)のユニフィケーション。
    // 一致する置換はないので型エラー。
    // unify A[a] and A[]. it fails because there is no valid substitution.
    Type left0  = Tycon("A", [Tyvar("a")]),
         right0 = Tycon("A", []);
    bool failed;

    try {
      Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    } catch (TypeError e) {
      failed = true;
      assert (e.msg == "cannot unify [a] with [], number of type arguments are different");
    }

    assert (failed);
  }

  static void testMguTyconP4() { // A[a] <=> B[a] (TypeError!)
    // 異なる多相型コンストラクタ同士(引数の値が異なる)のユニフィケーション。
    // 一致する置換はないので型エラー。
    // unify A[a] and B[a]. it fails because there is no valid substitution.
    Type left0  = Tycon("A", [Tyvar("a")]),
         right0 = Tycon("B",[Tyvar("a")]);
    bool failed;

    try {
      Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    } catch (TypeError e) {
      failed = true;
      assert (e.msg == "cannot unify A[a] with B[a]");
    }

    assert (failed);
  }
  
  static void testMguTyvarArrow1() { // a <=> B->C
    // 型変数aと関数型B->Cのユニフィケーション。成功する(a=B->C)
    // unify type variable a and functional type B->C. succeed with a=B->C
    Type left0  = Tyvar("a"),
         right0 = Arrow(Tycon("B", []), Tycon("C", []));
    Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    Type left1  = subst(left0),
         right1 = subst(right0);

    assert (left1 == right1);
    assert (left1 == Arrow(Tycon("B", []), Tycon("C", [])));
  }

  static void testMguTyvarArrow2() { // B->C <=> a
    // 関数型B->Cと型変数aのユニフィケーション。成功する(a=B->C)。
    // unify functional type B->C and type variable a. succeed with a=B->C
    Type left0  = Arrow(Tycon("B", []), Tycon("C", [])),
         right0 = Tyvar("a");
    Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    Type left1  = subst(left0),
         right1 = subst(right0);
    
    assert (left1 == right1);
    assert (right1 == Arrow(Tycon("B", []), Tycon("C", [])));
  }
  
  static void testMguTyvarTycon1() { // a <=> B
    // 型変数aと型コンストラクタB[]のユニフィケーション。成功する(a=B[])
    // unify type variable a and type constructor B[]. succeed with a=B[]
    Type left0  = Tyvar("a"), 
         right0 = Tycon("B", []);
    Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    Type left1  = subst(left0),
         right1 = subst(right0);
    
    assert (left1 == right1);
    assert (left1 == Tycon("B", []));
  }
  
  static void testMguTyvarTycon2() { // B <=> a
    // 型コンストラクタB[]と型変数aのユニフィケーション。成功する(a=B[])。
    // unify type constructor B[] and type variable a. succeed with a=B[]
    Type left0  = Tycon("B", []),
         right0 = Tyvar("a");
    Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    Type left1  = subst(left0), 
         right1 = subst(right0);

    assert (left1 == right1);
    assert (right1 == Tycon("B", []));
  }
  
  static void testMguTyconArrow1() { // A <=> a->b (TypeError!)
    // 型コンストラクタとArrowのユニフィケーション。失敗する。
    // unify type constructor and arrow. it fails.
    Type left0  = Tycon("A", []),
         right0 = Arrow(Tyvar("a"), Tyvar("b"));
    bool failed;

    try {
      Subst subst = typeInfer.mgu(left0, right0, Subst.emptySubst);
    } catch (TypeError e) {
      failed = true;
      assert (e.msg == "cannot unify A[] with (a -> b)");
    }

    assert (failed);
  }

  
  static void testTpVar1() { // [a:A] |- a : A
    Env env  = new Env;
    env["a"] = new TypeSchema([], Tycon("A", []));

    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env, Variable("a"), type, Subst.emptySubst);
    assert (subst(type) == Tycon("A", []));
  }

  static void testTpVar2() { // [] |- a : TypeError!
    Env  env  = new Env;
    Type type = Tyvar("a");
    bool failed;

    try {
      Subst subst = typeInfer.tp(env, Variable("a"), type, Subst.emptySubst);
    } catch (TypeError e) {
      failed = true;
      assert (e.msg =="undefined: a");
    }

    assert (failed);
  }
  
  static void testTpLam1() { // [1:Int] |- (\a -> a) 1 : Int
    Env env  = new Env;
    env["1"] = new TypeSchema([], Tycon("Int", []));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env, Apply(Lambda("a", Variable("a")), Variable("1")), type, Subst.emptySubst);
    
    assert (subst(type) == Tycon("Int", []));
  }

  static void testTpLam2() { // [true:Bool, 1:Int] |- (\a -> true) 1 : Bool
    Env env = new Env;
    env["true"] = new TypeSchema([], Tycon("Boolean", []));
    env["1"]    = new TypeSchema([], Tycon("Int", []));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env, Apply(Lambda("a", Variable("true")), Variable("1")), type, Subst.emptySubst);
    
    assert (subst(type) == Tycon("Boolean", []));
  }

  static void testTpLam3() { // [1:Int, a:Bool] |- (\a -> a) 1 : Int
    Env env = new Env;
    env["1"] = new TypeSchema([], Tycon("Int", []));
    env["a"] = new TypeSchema([], Tycon("Boolean", []));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env, Apply(Lambda("a", Variable("a")), Variable("1")), type, Subst.emptySubst);
    
    assert (subst(type) == Tycon("Int", []));
  }

  static void testTpLam4() { // [add:Int->(Int->Int),1:Int] |- add(1)1) : Int
    Env env = new Env;
    env["add"] = new TypeSchema([], Arrow(Tycon("Int", []), Arrow(Tycon("Int", []), Tycon("Int", []))));
    env["1"] = new TypeSchema([], Tycon("Int", []));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env, Apply(Apply(Variable("add"), Variable("1")), Variable("1")), type, Subst.emptySubst);
    
    assert (subst(type) == Tycon("Int", []));
  }

  static void testTpLet1() { // [1:Int] |- let a = 1 in a : Int
    Env env = new Env;
    env["1"]  = new TypeSchema([], Tycon("Int", []));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env, Let("a", Variable("1"), Variable("a")), type, Subst.emptySubst);

    assert (subst(type) == Tycon("Int", []));
  }

  static void testTpLet2() { // [true:Bool, 1:Int] |- let a = 1 in true : Bool
    Env env = new Env;
    env["true"] = new TypeSchema([], Tycon("Boolean", []));
    env["1"]    = new TypeSchema([], Tycon("Int", []));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env, Let("a", Variable("1"), Variable("true")), type, Subst.emptySubst);

    assert (subst(type) == Tycon("Boolean", []));
  }

  static void testTpLet3() { // [1:Int, a:Bool] |- let a = 1 in a : Int
    Env env = new Env;
    env["1"] = new TypeSchema([], Tycon("Int", []));
    env["a"] = new TypeSchema([], Tycon("Boolean", []));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env, Let("a", Variable("1"), Variable("a")), type, Subst.emptySubst);
    
    assert (subst(type) == Tycon("Int", []));
  }

  static void testTpLet4() { // [1:Int] |- let a = a in 1 : (TypeError!)
    Env env = new Env;
    env["1"] = new TypeSchema([], Tycon("Int", []));
    Type type = Tyvar("a");
    bool failed;

    try {
      Subst subst = typeInfer.tp(env, Let("a", Variable("a"), Variable("1")), type, Subst.emptySubst);
    } catch (TypeError e) {
      failed = true;
      assert (e.msg == "undefined: a");
    }

    assert (failed);
  }
  
  static void testTpLamLet1() {
    //  [e1:Bool, 1:Int] |- (\ x -> let y=e1 in x) 1 : Int
    //
    // 「 \ x -> let y=e1 in x」のように、λ本体の中にlet式が出現す
    // るときに、let束縛される識別子yのために登録される型スキーマで
    // は、xに対応する型スキーマで使用されている型変数が全称限量対
    // 象から除外される。
    //
    Env env = new Env;
    env["e1"] = new TypeSchema([], Tycon("Boolean", []));
    env["1"]  = new TypeSchema([], Tycon("Int", []));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(
        env,
        Apply(
          Lambda(
            "x",
            Let("y", Variable("e1"), Variable("x"))
          ),
          Variable("1")
        ), type, Subst.emptySubst);

    assert (subst(type) == Tycon("Int", []));
  }

  
  static void testTpLamP1() {
    //  [s:String, 7:Int] |- (\ x -> x s) (\x->7) : Int
    // λ変数xに多相関数を束縛し、x->Intでインスタンス化する。
    // bind lambda variable x to polymorphic function and instantiate with x->Int type.
    Env env = new Env;
    env["s"] = new TypeSchema([], Tycon("String", []));
    env["7"] = new TypeSchema([], Tycon("Int", []));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(
        env,
        Apply(
          Lambda(
            "x",
            Apply(Variable("x"), Variable("s"))
          ),
          Lambda("x", Variable("7"))
        ), type, Subst.emptySubst);

    assert (subst(type) == Tycon("Int", []));
  }


  static void testTpLamP2() {
    //  [s:String, c:Char, 7:Int, add:Int->(Int->Int)] |- (\ x -> (add(x s))(x c)) (\x->7) : TypeError!
    //  λ変数xが多相関数(a->Int)のとき、異なる型での複数回のインスタンス化でエラーになることの確認。
    /// if the lambda variable x is polymorphic function(a->Int), it should be error
    //  every type instantiation for each different type occurence of x.
    Env env = new Env;
    env["add"] = new TypeSchema([], Arrow(Tycon("Int", []), Arrow(Tycon("Int", []),Tycon("Int", []))));
    env["c"] = new TypeSchema([], Tycon("Char", []));
    env["s"] = new TypeSchema([], Tycon("String", []));
    env["7"] = new TypeSchema([], Tycon("Int", []));
    Type type = Tyvar("a");
    bool failed;

    try {
      Subst subst = typeInfer.tp(
          env,
          Apply(
            Lambda("x", Apply(
                      Apply(Variable("add"), Apply(Variable("x"), Variable("s"))),
                      Apply(Variable("x"), Variable("c")))
            ),
            Lambda("x", Variable("7"))
          ), type, Subst.emptySubst);
    } catch (TypeError e) {
      failed = true;
      assert (e.msg == "cannot unify Char[] with String[]");
    }

    assert (failed);
  }

  static void testTpLetP1() {
    //  [s:String, c:Char, 7:Int, add:Int->(Int->Int)] |- (let x=(\x->7) in (add(x s))(x c)) : Int
    //  let変数xが多相関数(a->Int)のとき、異なる型での複数回のインスタンス化でエラーにならないことの確認。
    /// if the let variable x is polymorphic function(a->Int), it should not be error
    //  every type instantiation for each different type occurence of x.
    
    Env env = new Env;
    env["add"] = new TypeSchema([], Arrow(Tycon("Int", []), Arrow(Tycon("Int", []),Tycon("Int", []))));
    env["c"] = new TypeSchema([], Tycon("Char", []));
    env["s"] = new TypeSchema([], Tycon("String", []));
    env["7"] = new TypeSchema([], Tycon("Int", []));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env,
        Let("x",
          Lambda("x", Variable("7")),
          Apply(
            Apply(Variable("add"),
              Apply(Variable("x"), Variable("s"))),
            Apply(Variable("x"), Variable("c")))
          ),
        type, Subst.emptySubst);

    assert (subst(type) == Tycon("Int", []));
  }

  static void testTpLetRec1() { // [1:Int] |- letrec a = 1 in a : Int
    Env env = new Env;
    env["1"] = new TypeSchema([], Tycon("Int", []));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env, LetRec("a", Variable("1"), Variable("a")), type, Subst.emptySubst);

    assert (subst(type) == Tycon("Int", []));
  }

  static void testTpLetRec2() { // [true:Bool, 1:Int] |- letrec a = 1 in true : Bool
    Env env = new Env;
    env["true"] = new TypeSchema([], Tycon("Boolean", []));
    env["1"] = new TypeSchema([], Tycon("Int", []));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env, LetRec("a", Variable("1"), Variable("true")), type, Subst.emptySubst);
    
    assert (subst(type) == Tycon("Boolean", []));
  }

  static void testTpLetRec3() { // [1:Int, a:Bool] |- letrec a = 1 in a : Int
    Env env = new Env;
    env["1"] = new TypeSchema([], Tycon("Int", []));
    env["a"] = new TypeSchema([], Tycon("Boolean", []));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env, LetRec("a", Variable("1"), Variable("a")), type, Subst.emptySubst);
    
    assert (subst(type) == Tycon("Int", []));
  }

  static void testTpLetRecP1() {
    //  [s:String, c:Char, 7:Int, add:Int->(Int->Int)] |- (letrec x=(\x->7) in (add(x s))(x c)) : Int
    //  letrec変数xが多相関数(a->Int)のとき、異なる型での複数回のインスタンス化でエラー
    //  にならないことの確認。
    /// if the letrec variable x is polymorphic function(a->Int), it should not be error
    //  every type instantiation for each different type occurence of x.
    Env env = new Env;
    env["add"] = new TypeSchema([], Arrow(Tycon("Int",[]), Arrow(Tycon("Int",[]),Tycon("Int",[]))));
    env["c"] = new TypeSchema([], Tycon("Char",[]));
    env["s"] = new TypeSchema([], Tycon("String",[]));
    env["7"] = new TypeSchema([], Tycon("Int",[]));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env,
          LetRec("x",
            Lambda("x", Variable("7")),
            Apply(
              Apply(Variable("add"),
                Apply(Variable("x"), Variable("s"))),
              Apply(Variable("x"), Variable("c")))
            ),
          type, Subst.emptySubst);
    assert (subst(type) == Tycon("Int",[]));
  }

  static void testTpLetRec4() { // [1:Int] |- letrec a = a in 1 : Int
    Env env = new Env();
    env["1"] = new TypeSchema([], Tycon("Int",[]));
    Type type = Tyvar("a");
    Subst subst = typeInfer.tp(env, LetRec("a", Variable("a"), Variable("1")), type, Subst.emptySubst);
    assert (subst(type) == Tycon("Int",[]));
  }

  static void testTypeOf() { // [] |- (\a->a) : a->a
    Env env = new Env();
    Type type = typeInfer.typeOf(env, Lambda("a", Variable("a"))); // a->a
    assert (type.type == TypeType.Arrow);
    assert ((cast(Arrow)type).t1 == (cast(Arrow)type).t2);
  }

  static void testPredefinedEnv() {
    Env env = typeInfer.predefinedEnv();
    assert (typeInfer.typeOf(env, Variable("true")) == Tycon("Boolean",[]));
  }

  static void testShowType() {
    // 最終的な型判定のテスト群。
    assert (typeInfer.showType(Variable("true")) == "Boolean[]");
    assert (typeInfer.showType(Variable("xtrue")) == "\n cannot type: xtrue\n reason: undefined: xtrue");
    assert (typeInfer.showType(Variable("zero")) == "Int[]");
    auto intList = Apply(
                      Apply(
                        Variable("cons"),
                        Variable("zero")),
                      Variable("nil"));
    auto zero = Variable("zero");
    auto one = Apply(Variable("succ"), Variable("zero"));
    assert (typeInfer.showType(intList) == "List[Int[]]");
    assert (typeInfer.showType(Apply(Variable("isEmpty"), intList)) == "Boolean[]");
    assert (typeInfer.showType(Apply(Variable("head"), intList)) == "Int[]");
    assert (typeInfer.showType(Apply(Variable("tail"), Apply(Variable("head"), intList))).startsWith("\n cannot type: zero\n reason: cannot unify Int[] with List["));
    assert (typeInfer.showType(Apply(Variable("tail"), Apply(Variable("tail"), intList))) == "List[Int[]]"); // runtime erro but type check is OK
    assert (typeInfer.showType(Apply(Apply(Apply(Variable("if"), Variable("true")), zero), one)) == "Int[]");
    assert (typeInfer.showType(Apply(Apply(Apply(Variable("if"), Variable("true")), intList), one)) == "\n cannot type: succ\n reason: cannot unify List[Int[]] with Int[]");
    auto listLenTest = LetRec("len",
          Lambda("xs",
            Apply(Apply(Apply(Variable("if"),
                  Apply(Variable("isEmpty"), Variable("xs"))),
                Variable("zero")),
              Apply(Variable("succ"),
                Apply(Variable("len"),
                  Apply(Variable("tail"),
                    Variable("xs"))))
              )),
          Apply(Variable("len"),
            Apply(
              Apply(Variable("cons"),
                Variable("zero")),
              Variable("nil"))
            )
          );
    assert (listLenTest.toString() == "letrec len = λ xs . (((if (isEmpty xs)) zero) (succ (len (tail xs)))) in (len ((cons zero) nil))");
    assert (typeInfer.showType(listLenTest) == "Int[]");
  }
}

import std.stdio;
void main() {
  int alltests;
  int passed;

  //do tests
  foreach (e; __traits(allMembers, Tests)) {
    string x = e;
    if (x.length > 5 && x[0..4] == "test") {
      alltests++;
      try {
        write("[begin] Test for - Tests.", e);
        mixin(e[0..4] == "test" ? "Tests." ~ e ~ ";" : "");
        writeln(" -> [passed]");
        passed++;
      } catch(Error er) {
        writeln(" -> [failed] : ", er);
      }
    }
  }

  writeln("All tests are finished. result(passed/alltests): [", passed, "/", alltests, "]");
}
