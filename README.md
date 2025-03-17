## 後継ソフト
https://github.com/suihakei/voice_divider

## ソフト説明

### ソフト名

無音でカッター


### 何するやつ？

ADVとか作るときに、声優さんのボイスを無音で自動カットしていくソフト。

将来的には色々機能乗せていきたい。


### どこからダウンロードできるの？

[releases](https://github.com/suihakei/muon_de_cutter/releases)ページからできますわ。

only windowsだけどね。ごめんね。


## 開発

## Nim version

- ver 1.0.6利用中
- choosenim のダウンロードは[ここ](https://github.com/dom96/choosenim)の[releases](https://github.com/dom96/choosenim/releases)から

```
choosenim 1.0.6
```

### 依存性

```
nimble install nigui
```


### コンパイル

**通常**

```
nim c -r main.nim
```


**リリースコンパイル**

```
nim c -d:release --opt:size --app:gui main.nim
```


### コントリビュート

こまめにコメント書いてね。

日本語でね。オレ日本人だから。
