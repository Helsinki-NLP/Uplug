**********************************************************************
  ChaSen1.5 を Prolog から利用するためのインタフェース
			    1997年7月 9日(水)
			    奈良先端科学技術大学院大学 情報科学研究科
			    今一 修     <osamu-im@is.aist-nara.ac.jp>
**********************************************************************
このディレクトリには ChaSen1.0を SICStus Prolog Release 3から利用す
るための以下のファイル群が収められている．
	README.prolog  … このファイル
	jinput.pl      … 日本語入力ルーチン
	chasen.pl      … 本体プログラム 
	chasen_user.pl … ユーザ定義ファイル
	utils.pl       … ユーティリティ
        juman.pl       … JUMAN2.0付属版互換プログラム
----------------------------------------------------------------------
  使用法
----------------------------------------------------------------------
・chasen.pl内のcha_default_pathとchasen_user.pl内のcha_pathにchasenの
  パスを指定する．
    cha_default_path … jumanの標準パス
    cha_path         … 各ユーザごとのjumanのパス
  例: cha_default_path('/usr/local/bin/chasen').
・出力形式は，
	f … カラムを整えて出力 (formatted)
	e … 完全な形態素情報を出力 (entire)
        s … 簡素化された出力 (simple)
  の三種類があり，
  cha_print_form/1の引数に f/e/s のいずれかを指定して評価することにより
  変更することができる．初期設定は'e である．
・コマンド一覧
	cha_version
          ChaSenのバージョン情報を表示
	cha_open
	  ChaSenとパイプで接続
	cha_close
	  ChaSenとのパイプを切断
	chatty
	  ChaSenの起動 (tty版)
	cha
	  ChaSenの起動
        cha_show_opion
          現在の出力オプションを表示
	cha_print_form(Form)
	  出力形式を Form に変更
	cha_print_mode(Mode)
	  出力モードを Mode に変更
	cha(Sentence)
	  入力文 Sentence を形態素解析
	cha(Sentence, MorphList, Cost)
	  入力文 Sentence を形態素解析し，形態素のリスト MorphList と
          その解析コスト Cost を返す．
・他のモジュールから使用する場合は，
	cha_open
	  …
	入力文を変数 Sentence に入れる．
	  …
	cha(Sentence,MorphList,Cost)
	  …
	形態素リスト MorphListと解析コスト Costを利用した処理をする．
	  …
	cha_close
  とすれば良い．
・茶筌システムから受け取るデータは，
	morph([識別子(ID), 
               開始位置(From), 
               終了位置(To), 
               コスト(Cost),
               見出し語(Md),
               読み(Ym), 
               基本形(Kh),
               品詞名(Hn0),
               品詞細分類(Hn), 
               活用型名(KT), 
               活用形名(KF), 
               付加情報(Imi),
               形態素コスト(MrphCost), 
               前節形態素との接続コストのリスト(PreCCL), 
               前接形態素の識別子のリスト(PreIDL)])
  となっており，cha/3内の read(InStr, -MorphList)から読み込まれる．
----------------------------------------------------------------------
 JUMAN2.0付属版からの変更点
---------------------------------------------------------------------
chasen.pl
・JUMAN版では，JUMANのサーバとソケットを介してデータのやりとりを行なっ
  ていたが，茶筌対応版では SICStus Prolog 3で提供されているパイプ機能
  を利用してChaSenとデータのやりとりを行なっている．
・出力形式 として f(formatted)/e(entire)/s(simple) を導入した．
  cha_print_form/1 で変更できる．
  [出力例: cha_print_form(f)]
    見出し  (読み)       基本形   品詞細分類 活用型 活用形
    ------------------------------------------------------
    太郎    (たろう)     太郎     固有名詞      
    が      (が)         が       格助詞        
    学校    (がっこう)   学校     普通名詞      
    へ      (へ)         へ       格助詞        
    行く    (いく)       行く     動詞      子音動詞カ行促 基本形

  [出力例: cha_print_form(e)]
    見出し 読み 基本形 品詞名 品詞細分類名 活用型 活用形 付加情報
    -------------------------------------------------------------
    太郎 たろう 太郎 名詞 固有名詞 * * *
    が が が 助詞 格助詞 * * *
    学校 がっこう 学校 名詞 普通名詞 * * *
    へ へ へ 助詞 格助詞 * * *
    行く いく 行く 動詞 動詞 子音動詞カ行促音便形 基本形 *

  [出力例: cha_print_form(s)]
    見出し 品詞細分類名
    -------------------
    太郎 固有名詞
    が 格助詞
    学校 普通名詞
    へ 格助詞
    行く 動詞

juman.pl
・JUMAN2.0付属版との見掛け上の互換性を考慮したプログラムで，内部でchasen.pl
  を読み込んでいる．
