module HindleyMilnerD.env;
import HindleyMilnerD.typeschema;
import kontainer.orderedAssocArray;
//import assoc;
/**
 * 環境Envは、プログラムのある位置における、識別子と型情報(型スキー
 * マ)の対応表である。
 * Env is map of identifier to type schema.
 * 環境Envは、意味的には型変数を含む制約の集合と見做すことができる。
 * Env can be regarded as set of constraints of relationships concerning
 * types include type variables. So HM type checker is constraints solver for it.
 * 環境は、tp()が解くべき、型方程式の制約条件を表現している。
 *     Env: 「プログラム中の識別子→型スキーマ」の対応の集合
 * 
 * ちなみに、Substもある種の対応表であるが、型変数の書き換えルールの
 * 集合。
 * 
 *     Subst: 「型変数→型(型変数|Arrow|Tycon)」という書き換え規則の集合
 * 
 * なお、明かにこの実装は空間効率が悪い。Scalaではタプルのリスト(連想リ
 * スト)で実現されていたところをGroovy化する際に、安易にMapにしてコピー
 * して受け渡すようにしたが、実用的には連想リストにすべき。
 */

//class Env : AssocTuple!(string, TypeSchema) {}
alias Env     = OrderedAssocArray!(string, TypeSchema);
alias EnvElem = Pair!(string, TypeSchema);
