mi --- Emacs MIDI Instrument
============================
EmacsからMIDIを操作します。

Emacs Lispなので、無理な演奏させるとテンポが狂ったりします。
なのでSchemeで作り直し中。

MIDIのみなので、音は別に用意しないといけません。
Mac OS Xでは内蔵のシンセが使えます。

参考: [Impromptu: Scheme ベースのライブコーディング環境 - Radium Software](http://d.hatena.ne.jp/KZR/20090915/p2), [impromputu](http://impromptu.moso.com.au/)

Install
-------
midiator( http://github.com/bleything/midiator )をインストール

    $ gem install midiator

.emacsに追記

    (require 'mi)
    (setq mi-use-dls-synth t) ;; OSXの内蔵シンセを使う場合

Summary
-------
scratchバッファ等で`M-x mi-setup`するとmiのプロセスが起動します。

S式で記述し`C-x C-e`で`eval-last-sexp`することで音を鳴らします。

4オクターブ目(キーボード中央)のドが1拍鳴ります。

    (mi-play 60)

シンボルで音を指定できます。

    (mi-play 'C4)

複数の音をリストで指定し和音を表現。

    (mi-play '(C4 E4 G4))

第二引数は遅延です。指定した拍数の後で鳴らします(ドーミーソー)。

    (progn
      (mi-play 'C4 0)
      (mi-play 'E4 1)
      (mi-play 'G4 2))

二小節のドラムシーケンスマクロ。

    (mi-seq 1/8
        (crash-cymbal1 x--- ---- ---- ----)
        (closed-hi-hat --x- x-x- x-x- x-x-)
        (snare-drum1   --x- --x- --x- --x-)
        (bass-drum1    x--- xx-- x--x -x--))

`M-x mi-destroy`でプロセスを終了させます。
