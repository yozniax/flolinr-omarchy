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

- ↑↓: ノード内の表示行を移動。先頭・末尾の行から前後のノードへ移動。
- ←→: 文章の先頭・末尾から前後のノードへ移動。
- Enter: カーソル位置で分割し、画面上のすぐ下に新規ノードを挿入。後半の文章を移す。Shift+Enterはノード内改行。
- Tab / Shift+Tab: 子孫を含めてインデント / アウトデント。
- Alt+上下: 子孫を含めて同じ親の項目と移動。
- ノード先頭でBackspace: 直前の表示ノードに文章を結合。子項目も保持。
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

### Import / Export（OPML・Markdown・Plaintext）

**左カラム下部のImport**、または開いているRollの**右ボディ上部のExport**から、ファイル選択画面を開きます。
パスを手で記入する必要はありません。Importはファイルを選び、Exportはファイルの種類で
形式を選択して、保存先とファイル名を指定します。

| 形式 | 拡張子 | 交換する内容 |
|---|---|---|
| OPML 2.0 | `.opml` | タイトル・項目の文章（複数行を含む）・階層 |
| Markdown | `.md`, `.markdown` | `# Roll名` と2スペースで階層を表す箇条書き |
| Plaintext | `.txt`, `.text` | 一行につき一項目。インデントを階層として扱う |

Importは**新しいRollの追加**で、既存Rollを変更しません。
Exportはズーム位置に関係なく、現在のRoll全体を書き出します（日付メモも可）。
既存ファイルを選んだ場合は選択画面で上書きを確認し、完成したファイルに原子的に置き換えます。
ファイル名の拡張子と選択形式が違う場合は、保存せずエラーを表示します。

色・ID・折りたたみ・日時は交換対象ではなく、Import時に新しいID・日時を付けます。
Markdownは一般的な全構文をアウトライン化する機能ではありません。
Plaintextの書き出しは2スペースインデントで、複数行の項目は一行ずつ別項目になります。
文章と階層を忠実に往復させたい場合はOPMLを選んでください。
ImportはUTF-8の最大2 MBのファイルに対応し、OPMLのDTD・エンティティ宣言は受け付けません。

### AIで表示中のアウトラインを整理

右ボディ右上のAIからSummarize / Expand / Reorderを選びます。
RollルートではRoll全体、ズーム中は見出しと子孫全体が対象です。
CLIの結果は編集可能なプレビューに入り、Apply previewで初めて置き換えます。
元の枝が変更されていた場合は適用を拒否します。適用はCtrl+Zで取り消せます。
Roll全体では複数のルート箇条書き、ズーム中は1つの見出し箇条書きと子孫の形式にしてください。

SettingsでAI接続を登録して選択します。Codex／Claude CLI、OpenAI／Anthropic API、
Ollama／互換APIに対応します。新規環境では未設定です。
CLIログインとAPIキー認証は別の導線です。具体的な設定は下記「0.12.0」を参照してください。
実行画面で接続先・モデル・対象の枝を確認し、操作を選んだときだけ文章を送信します。
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

## 0.10.1 — コンパクトな表示

アプリアイコンは外枠を維持し、図柄だけ75%に縮小して中央配置します。
左上はFlolinrの文字の右にバージョンを表示します。
左カラムのRollsより上にToday's noteを固定し、Calendarは機能リンクへまとめました。
年月日ツリーは表示しません。カレンダーモーダルは最大400×460、
各モーダルは本文11px・見出し13pxの共通スタイルで表示します。
Ctrl+Shift+Lは、従来のカレンダー一覧へのフォーカスに代わりカレンダーを開きます。

## 0.11.0 — ファイル選択による3形式の入出力

Import / Exportを左カラムから右ボディ上部へ移動しました。
Qt標準のファイル選択画面でOPML・Markdown・Plaintextを選択します。
形式変換とファイル選択の確認は次のコマンドでも実行できます。

```sh
python tests/test_bridge.py
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME= QT_QUICK_CONTROLS_STYLE=Basic \
  /usr/lib/qt6/bin/qmltestrunner -input tests/tst_filetransfer.qml
```

## 0.11.1 — Import起動時のクラッシュ回避

Importを左カラム下部へ移動しました。Exportは右ボディ上部です。
GTK/GIO内で異常終了するネイティブのファイル選択画面を避け、
Import・ExportともQt Quickのファイル選択画面を明示的に使用します。
OPML・Markdown・Plaintextの形式選択、保存先選択、上書き確認は維持します。

## 0.11.2 — Workflowy OPMLの制御文字への対応

WorkflowyなどのOPMLにXMLで許可されない制御文字が含まれている場合、
その文字だけを除去して取り込み、完了画面で補正したことを通知します。
通常の改行・タブ・本文・階層は保持し、元ファイルは変更しません。
DTD・エンティティ宣言などの拒否は維持しています。
読み込みに失敗した場合も、エラーをダイアログで表示します。

## 0.12.0 — 利用者ごとのAI接続設定

AIは初期状態では未設定です。**Settings → Add connection**で接続を登録し、
一覧から使う接続を選んで **Save settings** を押します。複数登録できます。
AIを未設定で開くと設定画面へ案内します。AI設定の変更は再起動せず反映されます。

| 接続 | 設定・認証 |
|---|---|
| Codex CLI | `codex`を別途導入。Log inでCodexのログインを開始し、Refresh statusで確認。ChatGPTログインまたはCLIに設定済みのAPI認証を使用 |
| Claude Code CLI | `claude`を別途導入。Log inでClaudeのログインを開始。CLIの既存認証を使用 |
| OpenAI API | APIキーと利用可能なモデルID。OpenAI Responses APIを使用 |
| Anthropic API | APIキーと利用可能なモデルID。Messages APIを使用 |
| Ollama | Base URL（既定`http://localhost:11434`）とインストール済みのモデルID |
| OpenAI-compatible API | `/chat/completions`の前までのBase URL（例`https://server.example/v1`）、モデルID、必要ならキー |
| Custom CLI | Advancedで標準入力→Markdown標準出力のJSON引数配列を指定 |

CLIのモデル欄は空ならCLIの既定値、APIのモデル欄は必須です。モデル名は自由入力なので、
プロバイダにないモデルはConnection testのエラーで確認します。
CLIが見つからない場合はAdvancedで実行ファイルの絶対パスを指定できます。
ログイン用端末はfoot・kitty・alacrittyに対応します。

**Connection test**は固定の短い文だけを送信し、ノートを送りません。
未保存の接続・入力中のキーでも試せます。サービスの利用枠・料金が適用される場合があります。
CLIログインとAPI利用の課金は別の方式です。接続先・モデル・対象の枝はAI実行画面にも表示します。
Summarize / Expand / Reorderの結果は従来どおり、Apply previewするまで本文を変更しません。

APIキーは`secret-tool`（Archの`libsecret`）経由でOSのSecret Serviceキーリングに保存します。
キーリングがロック中・未導入なら保存エラーにし、平文ファイルへ代替保存しません。
キーはノート・`settings.json`・プラグイン・プロジェクトに含めず、別端末では再設定します。
接続テストだけでは入力キーを保存しません。CLI認証情報はFlolinrでは管理・コピーしません。
AdvancedのDelete saved API keyで端末上のキーを削除できます。
接続の一覧からの削除は設定の削除です。キーも削除する場合は先にDelete saved API keyを実行してください。
互換APIのURLを変更すると旧URLのキーは使いません。リモート接続はHTTPS必須で、HTTPはループバックだけ許可します。

旧`aiCommand`設定がある場合はPrevious CLIとして引き継ぎます。
旧バージョンの暗黙のClaude既定値は自動選択しません。
保存先の変更だけは従来どおりシェル再読み込みが必要です。

追加検証:

```sh
node tests/ai-settings.test.cjs
python tests/test_ai_backend.py
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME= QT_QUICK_CONTROLS_STYLE=Basic \
  /usr/lib/qt6/bin/qmltestrunner -import tests/fixtures -input tests/tst_aiconnections.qml
```

## 0.12.1 — 矢印キー移動とEnterでの分割

Ctrlを押さずに矢印キーでノード間を移動できます。↑↓はノード内の折り返し・改行を
通常どおり移動し、先頭・末尾の表示行で隣の表示ノードへ移ります。←→も文章の
先頭・末尾から隣へ移動します。折りたたんだ子は飛ばし、ズーム中の範囲内で移動します。

Enterはカーソル前の文章を元のノードに残し、後ろの文章を次の同階層ノードへ移します。
子項目は元のノードに残し、新しいノードはその枝の後ろに作成します。
新しいノードの先頭から入力を続けられます。選択範囲がある場合は選択部分を取り除いて分割します。
Shift+Enterでノード内改行、日本語IMEの変換中は確定を優先します。
ズーム見出しの分割では親の表示へ戻り、新しい兄弟ノードを表示します。
Ctrl+↑↓の従来の移動、Alt+↑↓の枝の並べ替え、Undo/Redoも引き続き利用できます。

```sh
QT_QPA_PLATFORM=offscreen QT_QPA_PLATFORMTHEME= QT_QUICK_CONTROLS_STYLE=Basic \
  /usr/lib/qt6/bin/qmltestrunner -import tests/fixtures -input tests/tst_outlineediting.qml
```

## 0.12.2 — Backspaceで前のノードへ結合

カーソルがノードの先頭にあり、文字を選択していないときのBackspaceで、
直前の表示ノードの末尾に文章をつなげます。カーソルは文章のつなぎ目に置きます。
子項目は結合先の子として保持し、結合先が折りたたまれていれば展開します。
ズーム内の最初の子は見出しに結合します。先頭ノードでは結合しません。
通常の文字削除・選択部分の削除は従来どおりで、結合はCtrl+Zで取り消せます。

## 0.12.3 — ショートカット一覧の分類

Keyboard shortcutsを「Writing & editing」「Cursor movement & zoom」「Rolls」
「Daily notes & calendar」「Search」「Color & information」「Save, window & help」
「Mouse」の8分類に整理しました。区切り線と見出しで操作を探せます。
カスタマイズしたキーや無効化したキーも、各分類へそのまま反映します。

## 0.12.4 — Enterで直下に新規挿入

Enterで現在のノードの直下に新規ノードを作り、文章の後半を移して先頭から入力できます。
展開中の子項目がある場合は先頭の子として挿入し、既存の子項目はその下に残します。
子のないノードは同階層、折りたたみ中のノードは隠れている子を保って次の同階層に挿入します。
これにより、階層が変わる場所でも画面上で枝の末尾まで飛ばず、直下へ移ります。
ズーム見出しに子がある場合もズームを保って先頭の子に挿入します。

## 0.13.0 — 右ボディ全体を対象にするAI

AIリンクをサイドバーから右ボディ右上の機能リンクへ移しました。
カーソルのある項目ではなく、現在開いているRoll全体、またはズーム中の枝全体を対象にします。
折りたたまれた子項目も含みます。別のRollやズーム範囲の外の項目は送りません。
AI画面には接続先・モデル・対象範囲を表示します。
Roll全体のプレビューは複数のルート箇条書きに対応し、ズーム中は見出し1つとその子孫の形式です。
Apply previewまで本文は変更せず、対象の内容や表示範囲が変わった場合は適用を拒否します。
Ctrl+Zで適用前へ戻せます。

## 0.13.1 — Settingsの保存先をファイル選択

SettingsのWorkspace file欄にBrowse…を追加しました。
既存のワークスペースJSONを選ぶか、新しいJSONファイル名を指定できます。
選択した時点ではPath欄の変更だけで、ファイルの作成・上書きは行いません。
Save settingsで保存します。既存ファイルは上書きせず、新しい場所には現在の内容をコピーします。
保存先を切り替えるにはシェル再読み込みが必要です。Pathの直接入力も引き続き使えます。
