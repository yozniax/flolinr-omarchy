# Flolinr for Omarchy

Omarchy Quattro用の、キーボード中心のアウトライナーです。
Roll、日付ごとのmemopad、項目へのズーム、色、検索、Undo/Redoに対応します。
既存のWeb版・ターミナル版とはデータ互換性がありません。

## インストール・更新

開発ディレクトリで次を実行します。既存プラグインをバックアップし、
検証済みの実行ファイルだけをユーザー所有のプラグインディレクトリへ配置します。
ソース側の編集は、インストールするまで実行中のアプリには反映されません。

```sh
python scripts/install.py
omarchy plugin enable yozniax.flolinr
omarchy-shell shell summon yozniax.flolinr '{}'
```

配置したファイルはシェルが自動再読み込みします。必要な場合のみ次を実行します。

```sh
omarchy-shell shell rescanPlugins
```

バーのアウトライン型アイコンを左クリックすると開閉します。
指定のSVGを `flolinr.svg` として収録し、バーと見出しを同じ形状で描画します。

## データと設定

| 用途 | 保存先 |
|---|---|
| プラグイン本体 | `$XDG_CONFIG_HOME/omarchy/plugins/yozniax.flolinr/`（既定は `~/.config/` 以下） |
| コンテンツ | 既定は `~/.local/share/flolinr/outline.json`。Settingsで変更可能 |
| 保存先・AI CLI設定 | `$XDG_CONFIG_HOME/flolinr/settings.json` |
| キーバインド | `$XDG_CONFIG_HOME/flolinr/keybindings.json`（既定は `~/.config/` 以下） |
| 更新時のコードのバックアップ | `$XDG_STATE_HOME/flolinr/plugin-backups/`（既定は `~/.local/state/` 以下） |

コンテンツの保存先は従来の場所を維持しています。全Roll・memopadはversion 2の
JSONにまとめ、変更後400msで自動保存します。Ctrl+Sでも保存できます。
原子的なファイル置換を行い、不正な読込データは上書きしません。
プラグインを削除してもコンテンツと設定は残ります。同期サービス自体は内蔵しません。

## 操作

- Enter: 同階層の項目を現在の枝の後ろに追加。
- Tab / Shift+Tab: 子孫を含めてインデント / アウトデント。
- Alt+上下: 子孫を含めて同じ親の項目と移動。
- 空の末端行でBackspace: 項目を削除。
- 点をクリック: 項目にズーム。三角: 折りたたみ / 展開。
- Ctrl+F: 全Roll・日付メモを横断検索。↑↓で選択し、Enterまたはクリックで該当項目へズーム。
- Ctrl+Z / Ctrl+Shift+Z: Undo / Redo。Ctrl+W: 保存して閉じる。
- Ctrl+Shift+N: Roll作成。Ctrl+Shift+T: 今日のmemopad。
- Ctrl+/: 現在のキーバインドの一覧。左下のShortcutsからも開けます。

RollごとにUndo/Redo・ズーム位置をセッション中保持します。
memopadは日付ごとに1つで、Rename・Archive・Deleteはできません。
通常RollはArchive後だけ、確認ダイアログを経て削除できます。
カレンダーの活動表示は各項目の最新更新日時を使い、全編集履歴ではありません。

## キーバインドの変更

`~/.config/flolinr/` を必要に応じて作成し、`keybindings.json` に
変更するアクションだけを書きます。

```json
{
  "newRoll": "Ctrl+N",
  "today": "Alt+T",
  "color": ""
}
```

省略は既定値、空文字は無効化です。全26項目は `keybindings.example.json` を参照。
保存時に自動反映し、Shortcuts一覧にも現在の設定を表示します。
不正JSON・不明なアクション・重複キーは設定全体を拒否し、直前の正常な設定を維持します。
エラーはShortcuts下部に表示します。ファイル削除で既定値へ戻ります。

Qt形式のCtrl/Alt/Shift/Meta、英大文字・数字・F1〜F35・方向キー・Home・End・
PgUp・PgDown・Space・Delete・Insert・Tab・Backspace・Return・Escape・/を使えます。
Omarchyのデスクトップ操作との衝突を避けるには、アプリ内ではCtrl/Altを使います。
Enter、Tab/Shift+Tab、空行のBackspace、Alt+上下による枝移動、
ダイアログ内の矢印・Enter・Esc、標準の文字編集操作は固定です。
これらのキーをアプリのコマンドに割り当てると、標準編集操作を妨げる場合があります。

## 開発・検証

```sh
node tests/model.test.cjs
node tests/keybindings.test.cjs
omarchy plugin validate .
```

QMLの静的検証には `qmllint` と、`qs.Commons` / `qs.Ui` を解決できる
Omarchyシェルのインポートパスが必要です。詳細は [開発メモ](docs/DEVELOPMENT.md) を参照。
コード構成と参照した公式資料、手動確認項目もそちらに記載しています。
過去の仕様変更は [履歴](docs/HISTORY.md) に保存しています。

## 無効化

```sh
omarchy plugin disable yozniax.flolinr
```

## 0.10.0 — 日付メモ・全体検索・Markdown・AI・保存先

### 全体検索と日付メモ

検索はズーム位置に制限せず、Archive済みRollや折りたたまれた項目、過去の日付メモも対象です。
結果には所属Rollまたは日付・親のパスを表示します。ジャンプ後は見出しで該当項目を編集できます。
memopadは通常のRoll一覧・Roll切り替えに混ぜず、Calendarの日付を選んで開きます。
日付は作成・更新時刻から再計算せず固定され、後日追記しても元の日付に残ります。
既存のmemopadデータは同じIDで引き継ぎます。空の今日メモを自動作成する処理は廃止しました。

### どこからでも一行メモ

この端末では **Super+Ctrl+M** を追加しました。任意の端末からも呼べます。

```sh
omarchy-shell shell summon yozniax.flolinr '{"mode":"capture"}'
```

小さな入力欄に一行を入力し、Enterで今日の日付メモに追記します。
保存成功後に閉じ、Escでキャンセルします。保存失敗時は入力を残し、再試行で二重追加しません。
日付は端末のローカル日付です。通常の編集画面を開かずに使用できます。
ホットキーとウィンドウサイズは `~/.config/hypr/bindings.lua` で変更できます。

### Markdownとの往復

左下のImport Markdown / Export Markdownから、絶対パスまたは `~/...` を指定します。
書き出しは現在のRoll（日付メモも可）全体、読み込みは**新しいRollの追加**です。
既存Rollやファイルは上書きしません。再書き出しでは別のファイル名を指定してください。

形式は `# Roll名` と、2スペースで階層を表す箇条書きです。
本文・階層・複数行テキストを往復できます。色、ID、折りたたみ、日時はMarkdownに含めず、
インポート時に新しいID・日時を付けます。一般的なMarkdownの全構文をアウトライン化する機能ではありません。

### AIで選んだ枝を整理

項目を選び、AI · selected branchからSummarize / Expand / Reorderを選びます。
CLIの結果は編集可能なプレビューに入り、Apply previewで初めて置き換えます。
元の枝が変更されていた場合は適用を拒否します。適用はCtrl+Zで取り消せます。
プレビューは1つのルート箇条書きと、その子孫を持つ形式にしてください。

既定はClaude Codeの非対話モードです。CLIのインストール・ログインや利用契約は別途必要です。
APIキーをFlolinrへ渡す必要はありませんが、無料利用を保証するものではありません。
この環境ではCLIのバージョン取得がネットワーク制限で失敗したため、実サービスへの接続は未確認です。

SettingsのAI commandは、標準入力でプロンプトを受け、標準出力にMarkdownを返す
CLIのJSON引数配列に変更できます。シェル経由では実行しません。
選んだ枝だけを空の一時ディレクトリから送信します。既定コマンドはツールとMCPを無効化します。
CLIによっては文章が外部サービスへ送信されます。実行はユーザーがAI操作を選んだときだけです。
120秒でタイムアウトし、失敗時は文章を置き換えません。

### 保存先を同期フォルダに変更

Settingsで保存ファイルの絶対パスを指定します（例: `~/Sync/Flolinr/outline.json`）。
新しいファイルなら現在のワークスペースをコピーし、既存ファイルなら上書きしません。
設定保存後に `omarchy restart shell` を実行すると、その場所を読み込みます。
元のファイルは削除しません。キーバインド設定は保存先の変更とは独立です。

外部変更はファイル監視で読み込みます。未保存のローカル編集と外部更新が衝突した場合は
保存を停止して警告します。必要なRollをMarkdownへ退避し、再読み込み後に調整してください。
同期サービスを内蔵せず、競合の自動マージや複数端末同時編集は保証しません。

### 検証の追加

```sh
node tests/features.test.cjs
python tests/test_bridge.py
```

全体検索・日付メモ追記・Markdown往復・AI適用の競合検知・ファイル上書き拒否・
模擬CLIとの標準入出力を検証します。AI実サービスの呼び出しはテストに含めません。
