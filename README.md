#HindleyMilner D
HindleyMilner Type Inference System for mini-ML.  
  
##About  
mini-ML向けのHM型推論器のD言語での実装です。  
実装にあたり、[Groovyでの実装](https://gist.github.com/uehaj/8743580)を大変参考にさせていただきました。    
Groovyでの実装に書かれていた素晴らしいコメントの多くをこちらのD言語での実装でも残させていただきました。 
一部、D言語とGroovyで実装上の差異があるのでその場合は逐次コメントを書きました。  
現在、HindleyMilner型推論器などについて勉強中ですのでそれにともなって色々な変更を加えていく予定です。  
また、Groovyでの実装には[テストコードつき版](https://gist.github.com/uehaj/8743580)が存在します。
そのテスト群を使わせていただかないては無いので、D言語向けに書きなおしたものが`hmdtest`ディレクトリにあります。  
いかの`Requirements`にあるとおり、ビルドツールとして`dub`をコンパイラとして`dmd`を必要とします。
てすとは`hmdtest`ディレクトリで`$ dub`と実行すると、ビルド&テストが実行されます。  
ビルドとテストを分けたい場合は、`$ dub build`と実行するとビルドのみが行われるのでそのあとに`$ ./hmdtest`を実行してください。
  
  
##Requirements

  - DUB(Latest)
  - DMD(Latest)


##LICENSE
  This programs are relased under the MIT License.  
  See the `LICENSE` file for details.  
  Copyright (C) 2016 Akihiro Shoji <alpha.kai.net at alpha-kai-net.info>
  
