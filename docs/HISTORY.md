# Flolinr for Omarchy — prototype

Workflowyの余白・箇条書き・項目へのズームを参考にした、Omarchy Quattro用アウトライナー。
既存のFlolinrデータとの互換性はありません。

## ローカル導入

このフォルダの `manifest.json`, `BarWidget.qml`, `Outliner.qml`, `Model.js`, `Keybindings.js`, `ActionLink.qml` を
`~/.config/omarchy/plugins/yozniax.flolinr/` に配置します。
Omarchyのターミナルから次を実行してください。

```sh
omarchy plugin validate ~/.config/omarchy/plugins/yozniax.flolinr
omarchy-shell shell rescanPlugins
omarchy plugin enable yozniax.flolinr
omarchy-shell shell summon yozniax.flolinr '{}'
```

バーの `☷` でも開閉できます。ショートカットの追加は任意です。
QuickshellはOmarchyの既存シェルを使用し、別プロセスを起動しません。

## Text links / expanding Roll lists (0.8.1)

Active・Archived一覧は件数に応じた高さで全行を表示し、一覧内のスクロールは行いません。
項目が多い場合は左カラム全体のナビゲーション領域をスクロールします。
Roll作成はActive右側の `[+]`、本文の項目追加も `[+]` です。
カレンダー・絵文字選択・モーダルの操作を含め、機能コントロールは背景・枠のないテキストリンクです。
キーボードでのフォーカス・Enter/Spaceによる実行は従来どおり利用できます。

## Input focus / search (0.8.0, historical)

Roll・memopadを開くと、ルート末尾の空項目へフォーカスして入力待ちにします。
末尾に空項目がある場合はそれを再利用し、開くたびに空行が増えることを防ぎます。
ズーム時も項目へフォーカスし、子がない階層には空の子項目を作ります。
マウスの点・パンくず・キーバインドのいずれでも同じ動作です。
左カラムのツールチップと検索欄はなくしました。
**Ctrl+F**で検索ダイアログを開き、Enterで結果の編集へ移動、Escで検索を解除します。

## Today / memopad (0.7.0, historical)

New Roll作成後は最初の項目にフォーカスし、そのまま入力できます。
Calendarは起動時に閉じており、開くとTodayと年が見えます。年→月→日と順に展開します。
Todayは当日の固定メモ `memopad(YYYY-MM-DD)` を開く入口です。
**Ctrl+Shift+T** で当日のメモへ移動して入力できます（Flolinr内）。
日付ごとに1つだけ作成し、日が変わっても過去のメモは残します。
メモのArchive・Delete・Renameは無効です。絵文字は変更できます。
Calendarの日付を開くと **MEMOPAD** 枠にその日のメモを別表示します。
通常Rollの更新一覧には混ぜません。過去日付のメモも同じ枠から作成できます。

Rollの絵文字は見出しのアイコンをクリック、一覧のRollを右クリック、
または **Ctrl+Shift+E** で変更できます。候補を96個に増やしました。

## Layout (0.6.0, historical)

左カラムは折りたたみ可能なアウトラインです。

```text
Rolls
  Active
    Roll…
    + Add Roll
  Archived
    Roll…
Calendar
  YYYY
    MM
      DD
```

本文右上のRename Roll / Archive / Restore / Deleteは11pxの薄い文字で表示します。
Shortcutsは **Ctrl+/** で開閉します。左下のリンクからも開けます。

## Layout (0.5.2, historical)

右カラムを廃止し、My Rolls → + Add Roll → Archived Rolls → Calendarを左へ集約しました。
左カラムの下部にSearchとShortcutsを置き、セクションが多い場合は一覧部分をスクロールできます。
本文は左カラムから右端まで使います。

## Layout (0.5.1, historical)

右カラムは **My Rolls → + Add Roll → Archived Rolls → Calendar** の順です。
+ Add Rollは小さい文字・薄い色・左寄せで表示します。
左カラムはブランド、下部のSearch、Shortcuts、保存状態です。
Calendarは更新日時だけを使い、YYYY → MM → DDでネスト表示します。
集計モードのプルダウンとOpen Calendarボタンはありません。
日付クリックとCtrl+Shift+Dによる詳細表示は引き続き利用できます。
Flolinrの末尾のrは緑色です。

## Layout and archive (0.5.0, historical)

- Flolinrの末尾のrは緑色です。
- 左: My Rolls / Archived Rolls、下部にSearchと小さなShortcutsリンク。
- 中央: 右寄せのRename Roll / Archive。Archive済みではRestore / Delete。
- Deleteは対象名を表示する確認モーダルで確定後に実行します。元に戻せません。
  最後のRollを削除した場合は空のInboxを作ります。
- 右: Calendar。YYYY → YYYY-MM → YYYY-MM-DDの階層で新しい順です。
  年・月をクリックすると折りたたみ、日付はその日の項目を開きます。
  最初は直近14日分、Moreで14日ずつ追加します（活動のない日は省略）。
- Calendar欄のUpdated / Createdで集計する日時を切り替えます。
- Ctrl+Shift+H: Archive / Restore。
- Ctrl+Shift+Delete: Archive済みRollの削除確認。
- Ctrl+Shift+L: 右のCalendar欄にフォーカス。矢印キーとEnterで操作できます。
- ShortcutsモーダルはOmarchyテーマの背景・文字・アクセント色に追従します。

## Appearance / emoji

0.4.1では検索、Shortcuts、バージョン、保存状態を左カラムに集約しています。
中央はRoll操作・パンくず・Roll見出し・アウトライン、右端はCalendarです。
Flolinr本体とOmarchyバーのアイコンは、枝分かれを表す 🌿 です。
Rollごとの絵文字アイコンは引き続き変更できます。

Rollごとに絵文字アイコンを保存できます。見出しのアイコンをクリック、または
**Ctrl+Shift+E** で選択画面を開きます。矢印キーで選んで **Enter**、閉じるには **Esc**。
24個の候補に加え、Custom emoji欄へ好きな絵文字を入力できます。
左カラム、パンくず、見出しに同じアイコンを表示します。
Omarchyのテーマ色を使った角丸の選択表示・検索欄・編集行のハイライトを採用しています。
絵文字表示にはインストール済みのNoto Color Emojiを使います。

## Rolls

左カラムでRollを選択します。**+ New Roll** または **Ctrl+Shift+N** で追加できます。
**Rename Roll**、またはRollをダブルクリックすると名前を変更できます。
各Rollは独立したアウトラインです。Undo/Redoとズーム位置はRollごとにセッション中保持します。
検索対象は現在のRoll内です。再起動時は最後に選択したRollを開きます。
旧試作の単一アウトラインは、ID・階層・色を保持して **Inbox** に移行します。
保存形式はversion 2です。Archive済みRollだけ、確認モーダルを経て削除できます。

## Activity calendar / timestamps

新規ノードには `createdAt` / `updatedAt` をISO 8601形式で記録します。
テキスト・色・階層・並び順の変更で `updatedAt` を更新します。
折りたたみ・ズーム・Roll切り替えは閲覧操作として日時を更新しません。
日時のない既存ノードは過去の日付を推測せず、編集後に更新日時だけを持ちます。

**Calendar** または **Ctrl+Shift+D** で月間カレンダーを開きます。
日付に点が付いていれば活動があります。**Created / Updated** で集計を切り替えます。
全Rollが対象です。日時は端末のローカル日付で集計します。
Updatedは各項目の最新の更新日時であり、全編集履歴ではありません。
結果を選ぶと、対応Rollとノードを開きます。

| カレンダー内 | 操作 |
|---|---|
| ← / → / ↑ / ↓ | 前後の日・週 |
| PageUp / PageDown | 前月・翌月 |
| T | 今日 |
| M | Created / Updated 切り替え |
| Ctrl+↑ / Ctrl+↓ | 結果の選択 |
| Enter | 選択結果を開く |
| Esc | 閉じる |

## Keyboard workflow

**Ctrl+/** のヘルプに全コマンドを載せています。

| キー | 操作 |
|---|---|
| Ctrl+Shift+N / Ctrl+Shift+R | Rollの作成 / 名前変更 |
| Ctrl+PageUp / Ctrl+PageDown | 前 / 次のRoll |
| F6 | Roll一覧と編集欄のフォーカス切り替え |
| Roll一覧で↑↓ / Enter | Roll選択 / 編集へ戻る |
| Ctrl+↑ / Ctrl+↓ | 前 / 次のノードへフォーカス |
| Alt+→ / Alt+← | ズーム / 親へ戻る |
| Ctrl+Home | Rollルートへ戻る |
| Ctrl+Shift+Space | 折りたたみ / 展開 |
| Ctrl+Shift+A | 表示中の末尾へ項目を追加（空のRollでも使用可） |
| Ctrl+Shift+C | 色メニュー。↑↓で選択、Enterで適用、Escで閉じる |
| Ctrl+Shift+D | カレンダー |
| Ctrl+I | フォーカス中ノードの作成・更新日時 |
| Ctrl+W | 保存してウィンドウを閉じる |
| 検索欄でEnter / Esc | 結果へ移動 / 検索を解除して編集へ戻る |

文字の選択・コピー・貼り付けなどは通常のテキスト編集操作を使えます。
Roll名はダイアログで入力してEnter、キャンセルはEscです。

## 操作

ノードの点を右クリック、または編集中に **Ctrl+Shift+C** で色を選べます。
Default / Blue / Green / Amber / Rose / Purple を用意し、色は保存・Undoの対象です。

UIは英語です。上部の **Shortcuts** ボタン、または **Ctrl+/** でキーバインド一覧を表示します。
ヘルプは **Esc** または **Close** で閉じます。行間はコンパクトに設定しています。

- Enter: 現在の項目の枝の後に同じ階層の項目を追加
- Tab / Shift+Tab: 子孫を含めて階層を変更
- Alt+↑ / Alt+↓: 子孫を含めて同じ親の項目と入れ替え
- 空の末端行でBackspace: 削除
- 三角: 折りたたみ / 展開
- 点: その項目へズーム。上のパンくずで戻る
- Ctrl+F: ズーム中の範囲を検索（折りたたまれた項目も対象）
- Ctrl+Z / Ctrl+Shift+Z: 元に戻す / やり直す（直近100操作、テキストはフォーカス単位）
- Ctrl+S: 即時保存。通常は変更の400ms後に自動保存

検索中の階層変更・追加・移動・削除は無効です。テキストは編集できます。

## 保存

`~/.local/share/flolinr/outline.json` に保存します。ファイルは原子的に置換します。
読み込みエラー時は編集と保存を無効にし、元ファイルを保持します。
外部依存はOmarchy標準のQuickshell・QtQuick Controlsと `mkdir` です。
ネットワーク接続、アカウント、同期サービスは使いません。

## 検証

```sh
node tests/model.test.cjs
omarchy plugin validate .
```

階層変更・枝移動・ズーム・検索・不正データ拒否のテストを含みます。
初期試作です。実際の画面表示、日本語IME、バーからの起動、保存と再起動の確認は未完了です。
ドラッグ操作、Markdown装飾、画像添付、既存データ移行、同期は未実装です。

## 無効化

```sh
omarchy plugin disable yozniax.flolinr
```

プラグインを削除しても保存ファイルは別ディレクトリに残ります。

## キーバインドの変更

Omarchyのデスクトップ操作はSuper中心、Flolinr内はCtrl/Alt中心です。
既定キーは従来どおりです。Roll・色・カレンダーの操作はFlolinr独自です。

`~/.config/flolinr/keybindings.json`（XDG_CONFIG_HOME設定時はその下）に、
変更したいアクションだけを書きます。設定ディレクトリは必要に応じて作成してください。

```json
{
  "newRoll": "Ctrl+N",
  "today": "Alt+T",
  "color": "",
  "timestamps": "Alt+I"
}
```

空文字は無効化、省略は既定値です。全アクション名は `keybindings.example.json` を参照。
Qt形式のCtrl/Alt/Shift/Meta、英大文字・数字・F1〜F35・方向キー・Home・End・
PgUp・PgDown・Space・Delete・Insert・Tab・Backspace・Return・Escape・/を使用できます。
保存すると自動反映され、Shortcutsにも現在の割り当てを表示します。
不正JSON、不明なアクション、重複キーは設定全体を拒否し、直前の正常な設定を維持します。
エラーはShortcuts下部に表示します。ファイル削除で既定値へ戻せます。

Enter、Tab/Shift+Tab、空行のBackspace、Alt+上下による枝移動、ダイアログ内の
矢印・Enter・Esc、標準の文字編集操作は固定です。
標準編集キーへの割り当ては文字入力を妨げる場合があります。
Super（QtではMeta）はOmarchy側に取られることがあるため、アプリ内設定にはCtrl/Altを推奨します。
アプリの呼び出し用グローバルキーはHyprlandのユーザー設定で別に設定します。
