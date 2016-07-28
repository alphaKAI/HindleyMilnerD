/*
  Copyright (C) 2016 Akihiro Shoji <alpha.kai.net at alpha-kai-net.info> 
*/
module HindleyMilnerD.env;
import HindleyMilnerD.typeschema;
import kontainer.orderedAssocArray;

/**
 * 環境Envは、プログラムのある位置における、識別子と型情報(型スキー
 * マ)の対応表である。
 * 環境Envは、意味的には型変数を含む制約の集合と見做すことができる。
 * 環境は、tp()が解くべき、型方程式の制約条件を表現している。
 *     Env: 「プログラム中の識別子→型スキーマ」の対応の集合
 * 
 * ちなみに、Substもある種の対応表であるが、型変数の書き換えルールの
 * 集合。
 * 
 *     Subst: 「型変数→型(型変数|Arrow|Tycon)」という書き換え規則の集合
 */

alias Env     = OrderedAssocArray!(string, TypeSchema);
alias EnvElem = Pair!(string, TypeSchema);
