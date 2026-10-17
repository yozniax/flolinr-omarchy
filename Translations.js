.pragma library
.import "EuropeanTranslations.js" as European
// English source strings are stable keys. Never translate user-authored content.
// English first; the remaining entries follow English language names alphabetically.
var languages = [
    {code:"en",name:"English"},
    {code:"zh-CN",name:"简体中文"}, {code:"zh-TW",name:"繁體中文"},
    {code:"da",name:"Dansk"}, {code:"fr",name:"Français"},
    {code:"de",name:"Deutsch"}, {code:"it",name:"Italiano"},
    {code:"ja",name:"日本語"}, {code:"ko",name:"한국어"},
    {code:"pl",name:"Polski"}, {code:"pt",name:"Português"},
    {code:"ru",name:"Русский"}, {code:"es",name:"Español"}
];
// Catalog storage order is independent of the presentation order above.
var legacyCodes = ["ja","zh-CN","zh-TW","ko","es","pt","fr","it"];

function normalize(code) {
    return languages.some(function(entry) { return entry.code === code; }) ? code : "en";
}
function localeName(code) {
    return {en: "en_US", ja: "ja_JP", "zh-CN": "zh_CN", "zh-TW": "zh_TW", ko: "ko_KR", es: "es_ES", pt: "pt_PT", fr: "fr_FR", it: "it_IT", da: "da_DK", de: "de_DE", ru: "ru_RU", pl: "pl_PL"}[normalize(code)];
}
var english = {
  "Settings · AI connections": "Settings",
  " Use Connection test to verify.": " Use Test connection to verify.",
  "Custom CLI found; use Connection test to verify authentication.": "Custom CLI found. Use Test connection to verify authentication.",
  "Go to parent": "Go to the parent item",
  "Settings saved. AI settings apply immediately. A workspace location change requires shell reload.": "Settings saved. Language and AI settings apply immediately. Changing the workspace location requires reloading the shell.",
  "Node timestamps": "Item timestamps",
  "Node color": "Item color",
  "Connection test": "Test connection",
  "Download .md": "Save Markdown…",
  "Open today’s fixed memopad and start typing": "Open Today's Memo and start typing",
  "Choose a node color": "Choose an item color",
  "Return to a parent or Home": "Return to a parent or the Roll root",
  "Export current Roll": "Export the current Roll",
  "Save stores the key in this device’s desktop keyring, separate from notes and settings. Test uses a typed key without saving it.": "Saving stores the key in this device’s keyring, separate from notes and settings. Testing uses the entered key without saving it.",
  "Today's note": "Today's Memo",
  "Daily note": "Today's Memo",
  "DAILY NOTE": "Today's Memo",
  "Add today's note": "Add to Today's Memo",
  "Today’s note · Enter to save · Esc to cancel": "Today's Memo · Enter to save · Esc to cancel",
  "Daily notes & calendar": "Notes & calendar",
  "Search all Rolls and daily notes": "Search all Rolls and notes",
  "Customize shortcuts: {0}\nEnter, Tab, Backspace and dialog navigation use fixed editing keys.\n\nSearch spans all Rolls and daily notes. Select a result to zoom into the matching item.": "Customize shortcuts: {0}\nEnter, Tab, Backspace and dialog navigation use fixed editing keys.\n\nSearch spans all Rolls and notes. Select a result to zoom into the matching item.",
  "Insert a copy under the selected item. Embedded content is never sent to AI.": "The slash-command item becomes the inserted block. Embedded content is never sent to AI."
};
// Each row: Japanese, Simplified Chinese, Traditional Chinese, Korean,
// Spanish, Portuguese, French, Italian. All entries must have eight translations.
var catalog = {
  "Language": [
    "言語",
    "语言",
    "語言",
    "언어",
    "Idioma",
    "Idioma",
    "Langue",
    "Lingua"
  ],
  "Settings · AI connections": [
    "設定",
    "设置",
    "設定",
    "설정",
    "Ajustes",
    "Definições",
    "Paramètres",
    "Impostazioni"
  ],
  "Settings": [
    "設定",
    "设置",
    "設定",
    "설정",
    "Ajustes",
    "Definições",
    "Paramètres",
    "Impostazioni"
  ],
  "Today's note": [
    "今日のメモ",
    "今日笔记",
    "今日筆記",
    "오늘의 메모",
    "Nota de hoy",
    "Nota de hoje",
    "Note du jour",
    "Nota di oggi"
  ],
  "Add today's note": [
    "今日のメモを追加",
    "添加今日笔记",
    "新增今日筆記",
    "오늘의 메모 추가",
    "Añadir nota de hoy",
    "Adicionar nota de hoje",
    "Ajouter une note du jour",
    "Aggiungi una nota di oggi"
  ],
  "Rolls": [
    "Rolls",
    "Roll 列表",
    "Roll 清單",
    "Roll 목록",
    "Rolls",
    "Rolls",
    "Rolls",
    "Rolls"
  ],
  "Active": [
    "使用中",
    "使用中",
    "使用中",
    "사용 중",
    "Activos",
    "Ativos",
    "Actifs",
    "Attivi"
  ],
  "Archived": [
    "アーカイブ済み",
    "已归档",
    "已封存",
    "보관됨",
    "Archivados",
    "Arquivados",
    "Archivés",
    "Archiviati"
  ],
  "No archived Rolls": [
    "アーカイブ済みのRollはありません",
    "没有已归档的 Roll",
    "沒有已封存的 Roll",
    "보관된 Roll이 없습니다",
    "No hay Rolls archivados",
    "Sem Rolls arquivados",
    "Aucun Roll archivé",
    "Nessun Roll archiviato"
  ],
  "Import": [
    "インポート",
    "导入",
    "匯入",
    "가져오기",
    "Importar",
    "Importar",
    "Importer",
    "Importa"
  ],
  "Export": [
    "エクスポート",
    "导出",
    "匯出",
    "내보내기",
    "Exportar",
    "Exportar",
    "Exporter",
    "Esporta"
  ],
  "Calendar": [
    "カレンダー",
    "日历",
    "行事曆",
    "달력",
    "Calendario",
    "Calendário",
    "Calendrier",
    "Calendario"
  ],
  "Shortcuts": [
    "ショートカット",
    "快捷键",
    "快捷鍵",
    "단축키",
    "Atajos",
    "Atalhos",
    "Raccourcis",
    "Scorciatoie"
  ],
  "Close": [
    "閉じる",
    "关闭",
    "關閉",
    "닫기",
    "Cerrar",
    "Fechar",
    "Fermer",
    "Chiudi"
  ],
  "Close · Esc": [
    "閉じる · Esc",
    "关闭 · Esc",
    "關閉 · Esc",
    "닫기 · Esc",
    "Cerrar · Esc",
    "Fechar · Esc",
    "Fermer · Échap",
    "Chiudi · Esc"
  ],
  "Cancel": [
    "キャンセル",
    "取消",
    "取消",
    "취소",
    "Cancelar",
    "Cancelar",
    "Annuler",
    "Annulla"
  ],
  "Apply": [
    "適用",
    "应用",
    "套用",
    "적용",
    "Aplicar",
    "Aplicar",
    "Appliquer",
    "Applica"
  ],
  "Create": [
    "作成",
    "创建",
    "建立",
    "만들기",
    "Crear",
    "Criar",
    "Créer",
    "Crea"
  ],
  "Rename": [
    "名前を変更",
    "重命名",
    "重新命名",
    "이름 변경",
    "Renombrar",
    "Mudar nome",
    "Renommer",
    "Rinomina"
  ],
  "Delete": [
    "削除",
    "删除",
    "刪除",
    "삭제",
    "Eliminar",
    "Eliminar",
    "Supprimer",
    "Elimina"
  ],
  "Archive": [
    "アーカイブ",
    "归档",
    "封存",
    "보관",
    "Archivar",
    "Arquivar",
    "Archiver",
    "Archivia"
  ],
  "Restore": [
    "復元",
    "恢复",
    "還原",
    "복원",
    "Restaurar",
    "Restaurar",
    "Restaurer",
    "Ripristina"
  ],
  "New Roll": [
    "新しいRoll",
    "新建 Roll",
    "新增 Roll",
    "새 Roll",
    "Nuevo Roll",
    "Novo Roll",
    "Nouveau Roll",
    "Nuovo Roll"
  ],
  "Rename Roll": [
    "Roll名を変更",
    "重命名 Roll",
    "重新命名 Roll",
    "Roll 이름 변경",
    "Renombrar Roll",
    "Mudar nome do Roll",
    "Renommer le Roll",
    "Rinomina Roll"
  ],
  "Delete Roll": [
    "Rollを削除",
    "删除 Roll",
    "刪除 Roll",
    "Roll 삭제",
    "Eliminar Roll",
    "Eliminar Roll",
    "Supprimer le Roll",
    "Elimina Roll"
  ],
  "Add Roll": [
    "Rollを追加",
    "添加 Roll",
    "新增 Roll",
    "Roll 추가",
    "Añadir Roll",
    "Adicionar Roll",
    "Ajouter un Roll",
    "Aggiungi Roll"
  ],
  "Roll name": [
    "Roll名",
    "Roll 名称",
    "Roll 名稱",
    "Roll 이름",
    "Nombre del Roll",
    "Nome do Roll",
    "Nom du Roll",
    "Nome del Roll"
  ],
  "Roll icon": [
    "Rollのアイコン",
    "Roll 图标",
    "Roll 圖示",
    "Roll 아이콘",
    "Icono del Roll",
    "Ícone do Roll",
    "Icône du Roll",
    "Icona del Roll"
  ],
  "Add item": [
    "項目を追加",
    "添加条目",
    "新增項目",
    "항목 추가",
    "Añadir elemento",
    "Adicionar item",
    "Ajouter un élément",
    "Aggiungi elemento"
  ],
  "Untitled": [
    "無題",
    "无标题",
    "未命名",
    "제목 없음",
    "Sin título",
    "Sem título",
    "Sans titre",
    "Senza titolo"
  ],
  "Home": [
    "ホーム",
    "首页",
    "首頁",
    "홈",
    "Inicio",
    "Início",
    "Accueil",
    "Inizio"
  ],
  "Saved": [
    "保存済み",
    "已保存",
    "已儲存",
    "저장됨",
    "Guardado",
    "Guardado",
    "Enregistré",
    "Salvato"
  ],
  "Unsaved changes": [
    "未保存の変更",
    "未保存的更改",
    "尚未儲存的變更",
    "저장되지 않은 변경 사항",
    "Cambios sin guardar",
    "Alterações não guardadas",
    "Modifications non enregistrées",
    "Modifiche non salvate"
  ],
  "Loading…": [
    "読み込み中…",
    "正在加载…",
    "載入中…",
    "불러오는 중…",
    "Cargando…",
    "A carregar…",
    "Chargement…",
    "Caricamento…"
  ],
  "Saving…": [
    "保存中…",
    "正在保存…",
    "儲存中…",
    "저장 중…",
    "Guardando…",
    "A guardar…",
    "Enregistrement…",
    "Salvataggio…"
  ],
  "Working…": [
    "処理中…",
    "正在处理…",
    "處理中…",
    "처리 중…",
    "Procesando…",
    "A processar…",
    "Traitement…",
    "Elaborazione…"
  ],
  "Search": [
    "検索",
    "搜索",
    "搜尋",
    "검색",
    "Buscar",
    "Pesquisar",
    "Rechercher",
    "Cerca"
  ],
  "Search all Rolls and daily notes": [
    "すべてのRollと日付メモを検索",
    "搜索所有 Roll 和每日笔记",
    "搜尋所有 Roll 與每日筆記",
    "모든 Roll과 일일 메모 검색",
    "Buscar en todos los Rolls y notas diarias",
    "Pesquisar em todos os Rolls e notas diárias",
    "Rechercher dans tous les Rolls et notes quotidiennes",
    "Cerca in tutti i Roll e nelle note giornaliere"
  ],
  "Search all content, including archived Rolls": [
    "アーカイブを含むすべての内容を検索",
    "搜索全部内容，包括已归档的 Roll",
    "搜尋所有內容，包含已封存的 Roll",
    "보관된 Roll을 포함한 모든 내용 검색",
    "Buscar en todo, incluidos los Rolls archivados",
    "Pesquisar tudo, incluindo Rolls arquivados",
    "Rechercher partout, y compris dans les Rolls archivés",
    "Cerca ovunque, inclusi i Roll archiviati"
  ],
  "{0} results · ↑↓ to select · Enter to zoom": [
    "{0}件 · ↑↓で選択 · Enterでズーム",
    "{0} 个结果 · ↑↓ 选择 · Enter 聚焦",
    "{0} 個結果 · ↑↓ 選取 · Enter 聚焦",
    "결과 {0}개 · ↑↓ 선택 · Enter 확대",
    "{0} resultados · ↑↓ seleccionar · Enter ampliar",
    "{0} resultados · ↑↓ selecionar · Enter ampliar",
    "{0} résultats · ↑↓ sélectionner · Entrée zoomer",
    "{0} risultati · ↑↓ seleziona · Invio ingrandisci"
  ],
  " [Archived]": [
    " ［アーカイブ済み］",
    " [已归档]",
    " [已封存]",
    " [보관됨]",
    " [Archivado]",
    " [Arquivado]",
    " [Archivé]",
    " [Archiviato]"
  ],
  "Delete archived Roll?": [
    "アーカイブ済みのRollを削除しますか？",
    "删除已归档的 Roll？",
    "刪除已封存的 Roll？",
    "보관된 Roll을 삭제할까요?",
    "¿Eliminar el Roll archivado?",
    "Eliminar o Roll arquivado?",
    "Supprimer le Roll archivé ?",
    "Eliminare il Roll archiviato?"
  ],
  "Permanently delete “{0}” and all its items? This cannot be undone.": [
    "「{0}」とすべての項目を完全に削除しますか？この操作は取り消せません。",
    "永久删除“{0}”及其所有条目？此操作无法撤销。",
    "永久刪除「{0}」及其所有項目？此操作無法復原。",
    "“{0}” 및 모든 항목을 영구 삭제할까요? 되돌릴 수 없습니다.",
    "¿Eliminar «{0}» y todos sus elementos de forma permanente? No se puede deshacer.",
    "Eliminar permanentemente «{0}» e todos os seus itens? Esta ação não pode ser desfeita.",
    "Supprimer définitivement « {0} » et tous ses éléments ? Cette action est irréversible.",
    "Eliminare definitivamente «{0}» e tutti i suoi elementi? L'operazione è irreversibile."
  ],
  "Choose an emoji or enter your own": [
    "絵文字を選ぶか入力してください",
    "选择或输入表情符号",
    "選擇或輸入表情符號",
    "이모지를 선택하거나 입력하세요",
    "Elige un emoji o escribe uno",
    "Escolha ou introduza um emoji",
    "Choisissez ou saisissez un emoji",
    "Scegli o inserisci un'emoji"
  ],
  "Custom emoji": [
    "任意の絵文字",
    "自定义表情符号",
    "自訂表情符號",
    "사용자 지정 이모지",
    "Emoji personalizado",
    "Emoji personalizado",
    "Emoji personnalisé",
    "Emoji personalizzata"
  ],
  "Arrow keys to choose · Enter to apply · Esc to close": [
    "矢印キーで選択 · Enterで適用 · Escで閉じる",
    "方向键选择 · Enter 应用 · Esc 关闭",
    "方向鍵選取 · Enter 套用 · Esc 關閉",
    "방향키 선택 · Enter 적용 · Esc 닫기",
    "Flechas para elegir · Enter aplicar · Esc cerrar",
    "Setas para escolher · Enter aplicar · Esc fechar",
    "Flèches pour choisir · Entrée appliquer · Échap fermer",
    "Frecce per scegliere · Invio applica · Esc chiudi"
  ],
  "Node timestamps": [
    "項目の日時",
    "条目时间",
    "項目時間",
    "항목 시간",
    "Fechas del elemento",
    "Datas do item",
    "Dates de l'élément",
    "Date dell'elemento"
  ],
  "Node color": [
    "項目の色",
    "条目颜色",
    "項目顏色",
    "항목 색상",
    "Color del elemento",
    "Cor do item",
    "Couleur de l'élément",
    "Colore dell'elemento"
  ],
  "Created: {0}\nUpdated: {1}": [
    "作成日時：{0}\n更新日時：{1}",
    "创建时间：{0}\n更新时间：{1}",
    "建立時間：{0}\n更新時間：{1}",
    "생성: {0}\n수정: {1}",
    "Creado: {0}\nActualizado: {1}",
    "Criado: {0}\nAtualizado: {1}",
    "Créé : {0}\nModifié : {1}",
    "Creato: {0}\nModificato: {1}"
  ],
  "Unknown (created before timestamps were introduced)": [
    "不明（日時記録の導入前に作成）",
    "未知（创建时尚未记录时间）",
    "未知（建立時尚未記錄時間）",
    "알 수 없음 (시간 기록 도입 이전에 생성됨)",
    "Desconocido (creado antes del registro de fechas)",
    "Desconhecido (criado antes do registo de datas)",
    "Inconnu (créé avant l'enregistrement des dates)",
    "Sconosciuto (creato prima della registrazione delle date)"
  ],
  "Default": [
    "標準",
    "默认",
    "預設",
    "기본값",
    "Predeterminado",
    "Predefinido",
    "Par défaut",
    "Predefinito"
  ],
  "Blue": [
    "青",
    "蓝色",
    "藍色",
    "파랑",
    "Azul",
    "Azul",
    "Bleu",
    "Blu"
  ],
  "Green": [
    "緑",
    "绿色",
    "綠色",
    "초록",
    "Verde",
    "Verde",
    "Vert",
    "Verde"
  ],
  "Amber": [
    "琥珀",
    "琥珀色",
    "琥珀色",
    "호박색",
    "Ámbar",
    "Âmbar",
    "Ambre",
    "Ambra"
  ],
  "Rose": [
    "ローズ",
    "玫瑰色",
    "玫瑰色",
    "장미색",
    "Rosa",
    "Rosa",
    "Rose",
    "Rosa"
  ],
  "Purple": [
    "紫",
    "紫色",
    "紫色",
    "보라",
    "Morado",
    "Roxo",
    "Violet",
    "Viola"
  ],
  "Today": [
    "今日",
    "今天",
    "今天",
    "오늘",
    "Hoy",
    "Hoje",
    "Aujourd'hui",
    "Oggi"
  ],
  "DAILY NOTE": [
    "今日のメモ",
    "今日笔记",
    "今日筆記",
    "오늘의 메모",
    "Nota de hoy",
    "Nota de hoje",
    "Note du jour",
    "Nota di oggi"
  ],
  "Daily note": [
    "今日のメモ",
    "今日笔记",
    "今日筆記",
    "오늘의 메모",
    "Nota de hoy",
    "Nota de hoje",
    "Note du jour",
    "Nota di oggi"
  ],
  "ROLL ACTIVITY": [
    "Rollの更新",
    "Roll 动态",
    "Roll 動態",
    "Roll 활동",
    "ACTIVIDAD DE ROLLS",
    "ATIVIDADE DOS ROLLS",
    "ACTIVITÉ DES ROLLS",
    "ATTIVITÀ DEI ROLL"
  ],
  "{0} items": [
    "{0}項目",
    "{0} 个条目",
    "{0} 個項目",
    "항목 {0}개",
    "{0} elementos",
    "{0} itens",
    "{0} éléments",
    "{0} elementi"
  ],
  "No activity on this day": [
    "この日の更新はありません",
    "当天没有动态",
    "當日沒有動態",
    "이 날짜에 활동이 없습니다",
    "Sin actividad este día",
    "Sem atividade neste dia",
    "Aucune activité ce jour",
    "Nessuna attività in questa data"
  ],
  "Arrows: date · PgUp/PgDn: month · T: today\nCtrl+↑↓: activity · Enter: open · Esc: close": [
    "矢印：日付 · PgUp/PgDn：月 · T：今日\nCtrl+↑↓：更新 · Enter：開く · Esc：閉じる",
    "方向键：日期 · PgUp/PgDn：月份 · T：今天\nCtrl+↑↓：动态 · Enter：打开 · Esc：关闭",
    "方向鍵：日期 · PgUp/PgDn：月份 · T：今天\nCtrl+↑↓：動態 · Enter：開啟 · Esc：關閉",
    "방향키: 날짜 · PgUp/PgDn: 월 · T: 오늘\nCtrl+↑↓: 활동 · Enter: 열기 · Esc: 닫기",
    "Flechas: fecha · PgUp/PgDn: mes · T: hoy\nCtrl+↑↓: actividad · Enter: abrir · Esc: cerrar",
    "Setas: data · PgUp/PgDn: mês · T: hoje\nCtrl+↑↓: atividade · Enter: abrir · Esc: fechar",
    "Flèches : date · PgUp/PgDn : mois · T : aujourd'hui\nCtrl+↑↓ : activité · Entrée : ouvrir · Échap : fermer",
    "Frecce: data · PgUp/PgDn: mese · T: oggi\nCtrl+↑↓: attività · Invio: apri · Esc: chiudi"
  ],
  "Import as a new Roll": [
    "新しいRollとしてインポート",
    "导入为新 Roll",
    "匯入為新 Roll",
    "새 Roll로 가져오기",
    "Importar como nuevo Roll",
    "Importar como novo Roll",
    "Importer dans un nouveau Roll",
    "Importa come nuovo Roll"
  ],
  "Export current Roll": [
    "現在のRollをエクスポート",
    "导出当前 Roll",
    "匯出目前的 Roll",
    "현재 Roll 내보내기",
    "Exportar el Roll actual",
    "Exportar o Roll atual",
    "Exporter le Roll actuel",
    "Esporta il Roll corrente"
  ],
  "Supported files (*.opml *.md *.markdown *.txt *.text)": [
    "対応ファイル (*.opml *.md *.markdown *.txt *.text)",
    "支持的文件 (*.opml *.md *.markdown *.txt *.text)",
    "支援的檔案 (*.opml *.md *.markdown *.txt *.text)",
    "지원 파일 (*.opml *.md *.markdown *.txt *.text)",
    "Archivos compatibles (*.opml *.md *.markdown *.txt *.text)",
    "Ficheiros suportados (*.opml *.md *.markdown *.txt *.text)",
    "Fichiers pris en charge (*.opml *.md *.markdown *.txt *.text)",
    "File supportati (*.opml *.md *.markdown *.txt *.text)"
  ],
  "Plaintext (*.txt *.text)": [
    "プレーンテキスト (*.txt *.text)",
    "纯文本 (*.txt *.text)",
    "純文字 (*.txt *.text)",
    "일반 텍스트 (*.txt *.text)",
    "Texto sin formato (*.txt *.text)",
    "Texto simples (*.txt *.text)",
    "Texte brut (*.txt *.text)",
    "Testo semplice (*.txt *.text)"
  ],
  "Plaintext (*.txt)": [
    "プレーンテキスト (*.txt)",
    "纯文本 (*.txt)",
    "純文字 (*.txt)",
    "일반 텍스트 (*.txt)",
    "Texto sin formato (*.txt)",
    "Texto simples (*.txt)",
    "Texte brut (*.txt)",
    "Testo semplice (*.txt)"
  ],
  "Workspace file (.json)": [
    "保存先ファイル (.json)",
    "工作区文件 (.json)",
    "工作區檔案 (.json)",
    "작업 공간 파일 (.json)",
    "Archivo del espacio de trabajo (.json)",
    "Ficheiro do espaço de trabalho (.json)",
    "Fichier de l'espace de travail (.json)",
    "File dell'area di lavoro (.json)"
  ],
  "Browse…": [
    "参照…",
    "浏览…",
    "瀏覽…",
    "찾아보기…",
    "Examinar…",
    "Procurar…",
    "Parcourir…",
    "Sfoglia…"
  ],
  "Choose workspace file (existing or new)": [
    "保存先ファイルを選択（既存または新規）",
    "选择工作区文件（现有或新建）",
    "選擇工作區檔案（現有或新增）",
    "작업 공간 파일 선택 (기존 또는 새 파일)",
    "Elegir archivo del espacio de trabajo (existente o nuevo)",
    "Escolher ficheiro do espaço de trabalho (existente ou novo)",
    "Choisir un fichier d'espace de travail (existant ou nouveau)",
    "Scegli un file dell'area di lavoro (esistente o nuovo)"
  ],
  "Flolinr workspace (*.json)": [
    "Flolinrの保存ファイル (*.json)",
    "Flolinr 工作区 (*.json)",
    "Flolinr 工作區 (*.json)",
    "Flolinr 작업 공간 (*.json)",
    "Espacio de trabajo de Flolinr (*.json)",
    "Espaço de trabalho Flolinr (*.json)",
    "Espace de travail Flolinr (*.json)",
    "Area di lavoro Flolinr (*.json)"
  ],
  "Save settings": [
    "設定を保存",
    "保存设置",
    "儲存設定",
    "설정 저장",
    "Guardar ajustes",
    "Guardar definições",
    "Enregistrer les paramètres",
    "Salva impostazioni"
  ],
  "AI · current view": [
    "AI · 現在の表示範囲",
    "AI · 当前视图",
    "AI · 目前視圖",
    "AI · 현재 보기",
    "IA · vista actual",
    "IA · vista atual",
    "IA · vue actuelle",
    "IA · vista corrente"
  ],
  "Add connection": [
    "接続を追加",
    "添加连接",
    "新增連線",
    "연결 추가",
    "Añadir conexión",
    "Adicionar ligação",
    "Ajouter une connexion",
    "Aggiungi connessione"
  ],
  "Connection name": [
    "接続名",
    "连接名称",
    "連線名稱",
    "연결 이름",
    "Nombre de la conexión",
    "Nome da ligação",
    "Nom de la connexion",
    "Nome della connessione"
  ],
  "Model ID": [
    "モデルID",
    "模型 ID",
    "模型 ID",
    "모델 ID",
    "ID del modelo",
    "ID do modelo",
    "Identifiant du modèle",
    "ID del modello"
  ],
  "Leave empty for CLI default": [
    "空欄でCLIの既定値を使用",
    "留空以使用 CLI 默认值",
    "留空以使用 CLI 預設值",
    "비워 두면 CLI 기본값 사용",
    "Dejar vacío para usar el valor del CLI",
    "Deixe vazio para usar o padrão do CLI",
    "Laisser vide pour utiliser le modèle par défaut du CLI",
    "Lascia vuoto per usare il modello predefinito della CLI"
  ],
  "Enter the model ID available on your account / server": [
    "アカウントやサーバーで利用できるモデルID",
    "输入账户或服务器可用的模型 ID",
    "輸入帳戶或伺服器可用的模型 ID",
    "계정 또는 서버에서 사용 가능한 모델 ID",
    "ID del modelo disponible en tu cuenta o servidor",
    "ID do modelo disponível na conta ou servidor",
    "Identifiant du modèle disponible sur votre compte ou serveur",
    "ID del modello disponibile nel tuo account o server"
  ],
  "Refresh status": [
    "状態を更新",
    "刷新状态",
    "重新整理狀態",
    "상태 새로 고침",
    "Actualizar estado",
    "Atualizar estado",
    "Actualiser l'état",
    "Aggiorna stato"
  ],
  "Log in": [
    "ログイン",
    "登录",
    "登入",
    "로그인",
    "Iniciar sesión",
    "Iniciar sessão",
    "Se connecter",
    "Accedi"
  ],
  "Connection test": [
    "接続をテスト",
    "测试连接",
    "測試連線",
    "연결 테스트",
    "Probar conexión",
    "Testar ligação",
    "Tester la connexion",
    "Verifica connessione"
  ],
  "Advanced": [
    "詳細設定",
    "高级设置",
    "進階設定",
    "고급 설정",
    "Avanzado",
    "Avançado",
    "Avancé",
    "Avanzate"
  ],
  "CLI executable path (optional)": [
    "CLIの実行ファイル（任意）",
    "CLI 可执行文件路径（可选）",
    "CLI 執行檔路徑（選填）",
    "CLI 실행 파일 경로 (선택)",
    "Ruta del ejecutable CLI (opcional)",
    "Caminho do executável CLI (opcional)",
    "Chemin de l'exécutable CLI (facultatif)",
    "Percorso dell'eseguibile CLI (facoltativo)"
  ],
  "Delete saved API key on this device": [
    "この端末のAPIキーを削除",
    "删除此设备保存的 API 密钥",
    "刪除此裝置儲存的 API 金鑰",
    "이 기기에 저장된 API 키 삭제",
    "Eliminar la clave API de este dispositivo",
    "Eliminar a chave API deste dispositivo",
    "Supprimer la clé API de cet appareil",
    "Elimina la chiave API da questo dispositivo"
  ],
  "Remove connection (save to apply)": [
    "接続を削除（保存で反映）",
    "移除连接（保存后生效）",
    "移除連線（儲存後套用）",
    "연결 삭제 (저장 시 적용)",
    "Eliminar conexión (guardar para aplicar)",
    "Remover ligação (guardar para aplicar)",
    "Retirer la connexion (enregistrer pour appliquer)",
    "Rimuovi connessione (salva per applicare)"
  ],
  "AI not configured": [
    "AIは未設定です",
    "尚未配置 AI",
    "尚未設定 AI",
    "AI가 설정되지 않았습니다",
    "IA sin configurar",
    "IA não configurada",
    "IA non configurée",
    "IA non configurata"
  ],
  "AI disabled / not configured": [
    "AIを使用しない／未設定",
    "AI 已禁用／未配置",
    "AI 已停用／未設定",
    "AI 비활성화 / 미설정",
    "IA desactivada / sin configurar",
    "IA desativada / não configurada",
    "IA désactivée / non configurée",
    "IA disattivata / non configurata"
  ],
  "CLI default": [
    "CLIの既定値",
    "CLI 默认值",
    "CLI 預設值",
    "CLI 기본값",
    "Predeterminado del CLI",
    "Padrão do CLI",
    "Valeur par défaut du CLI",
    "Valore predefinito della CLI"
  ],
  "Change AI connection": [
    "AI接続を変更",
    "更改 AI 连接",
    "變更 AI 連線",
    "AI 연결 변경",
    "Cambiar conexión de IA",
    "Alterar ligação de IA",
    "Changer la connexion IA",
    "Cambia connessione IA"
  ],
  "Summarize": [
    "要約",
    "总结",
    "摘要",
    "요약",
    "Resumir",
    "Resumir",
    "Résumer",
    "Riassumi"
  ],
  "Expand": [
    "展開",
    "扩展",
    "擴展",
    "확장",
    "Desarrollar",
    "Desenvolver",
    "Développer",
    "Espandi"
  ],
  "Reorder": [
    "並べ替え",
    "重新排序",
    "重新排序",
    "재정렬",
    "Reorganizar",
    "Reorganizar",
    "Réorganiser",
    "Riordina"
  ],
  "Convert to Markdown": [
    "Markdownに変換",
    "转换为 Markdown",
    "轉換為 Markdown",
    "Markdown으로 변환",
    "Convertir a Markdown",
    "Converter para Markdown",
    "Convertir en Markdown",
    "Converti in Markdown"
  ],
  "Apply preview": [
    "プレビューを適用",
    "应用预览",
    "套用預覽",
    "미리보기 적용",
    "Aplicar vista previa",
    "Aplicar pré-visualização",
    "Appliquer l'aperçu",
    "Applica anteprima"
  ],
  "Download .md": [
    "Markdownを保存…",
    "保存 Markdown…",
    "儲存 Markdown…",
    "Markdown 저장…",
    "Guardar Markdown…",
    "Guardar Markdown…",
    "Enregistrer le Markdown…",
    "Salva Markdown…"
  ],
  "Save AI Markdown": [
    "AIのMarkdownを保存",
    "保存 AI Markdown",
    "儲存 AI Markdown",
    "AI Markdown 저장",
    "Guardar Markdown de IA",
    "Guardar Markdown da IA",
    "Enregistrer le Markdown de l'IA",
    "Salva Markdown dell'IA"
  ],
  "Preview appears here. Edit it before applying or saving as Markdown.": [
    "ここにプレビューを表示します。適用・Markdown保存前に編集できます。",
    "预览将显示在此处。应用或保存为 Markdown 前可编辑。",
    "預覽會顯示於此。套用或儲存為 Markdown 前可編輯。",
    "미리보기가 여기에 표시됩니다. 적용하거나 Markdown으로 저장하기 전에 편집할 수 있습니다.",
    "La vista previa aparecerá aquí. Edítala antes de aplicarla o guardarla como Markdown.",
    "A pré-visualização aparece aqui. Edite antes de aplicar ou guardar como Markdown.",
    "L'aperçu s'affichera ici. Modifiez-le avant de l'appliquer ou de l'enregistrer en Markdown.",
    "L'anteprima apparirà qui. Modificala prima di applicarla o salvarla come Markdown."
  ],
  "Markdown saved: {0}": [
    "Markdownを保存しました：{0}",
    "Markdown 已保存：{0}",
    "Markdown 已儲存：{0}",
    "Markdown 저장됨: {0}",
    "Markdown guardado: {0}",
    "Markdown guardado: {0}",
    "Markdown enregistré : {0}",
    "Markdown salvato: {0}"
  ],
  "Connection: {0} · {1}": [
    "接続：{0} · {1}",
    "连接：{0} · {1}",
    "連線：{0} · {1}",
    "연결: {0} · {1}",
    "Conexión: {0} · {1}",
    "Ligação: {0} · {1}",
    "Connexion : {0} · {1}",
    "Connessione: {0} · {1}"
  ],
  "Scope: {0}": [
    "対象：{0}",
    "范围：{0}",
    "範圍：{0}",
    "범위: {0}",
    "Ámbito: {0}",
    "Âmbito: {0}",
    "Portée : {0}",
    "Ambito: {0}"
  ],
  "Entire Roll": [
    "Roll全体",
    "整个 Roll",
    "整個 Roll",
    "전체 Roll",
    "Roll completo",
    "Roll completo",
    "Roll entier",
    "Roll intero"
  ],
  "Zoomed branch": [
    "Zoom中の枝全体",
    "当前聚焦的分支",
    "目前聚焦的分支",
    "확대한 가지 전체",
    "Rama ampliada",
    "Ramo ampliado",
    "Branche zoomée",
    "Ramo ingrandito"
  ],
  "(empty item)": [
    "（空の項目）",
    "（空条目）",
    "（空白項目）",
    "(빈 항목)",
    "(elemento vacío)",
    "(item vazio)",
    "(élément vide)",
    "(elemento vuoto)"
  ],
  "Flolinr · Quick note": [
    "Flolinr · クイックメモ",
    "Flolinr · 快速笔记",
    "Flolinr · 快速筆記",
    "Flolinr · 빠른 메모",
    "Flolinr · Nota rápida",
    "Flolinr · Nota rápida",
    "Flolinr · Note rapide",
    "Flolinr · Nota rapida"
  ],
  "Today’s note · Enter to save · Esc to cancel": [
    "今日のメモ · Enterで保存 · Escでキャンセル",
    "今日笔记 · Enter 保存 · Esc 取消",
    "今日筆記 · Enter 儲存 · Esc 取消",
    "오늘의 메모 · Enter 저장 · Esc 취소",
    "Nota de hoy · Enter guardar · Esc cancelar",
    "Nota de hoje · Enter guardar · Esc cancelar",
    "Note du jour · Entrée enregistrer · Échap annuler",
    "Nota di oggi · Invio salva · Esc annulla"
  ],
  "Keyboard shortcuts": [
    "キーボードショートカット",
    "键盘快捷键",
    "鍵盤快捷鍵",
    "키보드 단축키",
    "Atajos de teclado",
    "Atalhos de teclado",
    "Raccourcis clavier",
    "Scorciatoie da tastiera"
  ],
  "Choose an existing workspace or name a new .json file. Selection does not write a file. Save settings to apply; changing the workspace requires a shell reload.": [
    "既存の保存ファイルを選ぶか、新しい.jsonファイル名を指定します。選択だけでは保存されません。設定を保存して反映してください。保存先の変更にはシェルの再読み込みが必要です。",
    "选择现有工作区或指定新的 .json 文件名。选择不会写入文件。保存设置后生效；更改工作区需要重新加载 Shell。",
    "選擇現有工作區或指定新的 .json 檔名。選取不會寫入檔案。儲存設定後套用；變更工作區需要重新載入 Shell。",
    "기존 작업 공간을 선택하거나 새 .json 파일 이름을 지정하세요. 선택만으로 파일이 저장되지는 않습니다. 설정을 저장하면 적용되며, 작업 공간 변경 시 셸을 다시 불러와야 합니다.",
    "Elige un archivo existente o un nombre .json nuevo. Seleccionar no escribe el archivo. Guarda los ajustes para aplicar; cambiar el espacio requiere recargar el shell.",
    "Escolha um ficheiro existente ou um novo nome .json. A seleção não grava ficheiros. Guarde para aplicar; mudar o espaço de trabalho exige recarregar a shell.",
    "Choisissez un fichier existant ou un nouveau nom .json. La sélection n'écrit aucun fichier. Enregistrez pour appliquer ; changer d'espace nécessite de recharger le shell.",
    "Scegli un file esistente o un nuovo nome .json. La selezione non scrive file. Salva per applicare; cambiare area di lavoro richiede il ricaricamento della shell."
  ],
  "AI connection · selected connection becomes active when saved": [
    "AI接続 · 選択した接続は保存後に有効になります",
    "AI 连接 · 保存后启用所选连接",
    "AI 連線 · 儲存後啟用所選連線",
    "AI 연결 · 선택한 연결은 저장 시 활성화됩니다",
    "Conexión de IA · se activa al guardar",
    "Ligação de IA · ativa ao guardar",
    "Connexion IA · activée après enregistrement",
    "Connessione IA · si attiva al salvataggio"
  ],
  "Add a connection to enable AI. Nothing is sent automatically.": [
    "接続を追加するとAIを利用できます。自動送信はしません。",
    "添加连接以启用 AI。不会自动发送任何内容。",
    "新增連線以啟用 AI。不會自動傳送任何內容。",
    "AI를 사용하려면 연결을 추가하세요. 자동으로 전송되는 내용은 없습니다.",
    "Añade una conexión para activar la IA. No se envía nada automáticamente.",
    "Adicione uma ligação para ativar a IA. Nada é enviado automaticamente.",
    "Ajoutez une connexion pour activer l'IA. Rien n'est envoyé automatiquement.",
    "Aggiungi una connessione per abilitare l'IA. Non viene inviato nulla automaticamente."
  ],
  "Choose and save an AI connection first.": [
    "先にAI接続を選び、保存してください。",
    "请先选择并保存 AI 连接。",
    "請先選擇並儲存 AI 連線。",
    "먼저 AI 연결을 선택하고 저장하세요.",
    "Primero elige y guarda una conexión de IA.",
    "Escolha e guarde primeiro uma ligação de IA.",
    "Choisissez et enregistrez d'abord une connexion IA.",
    "Prima scegli e salva una connessione IA."
  ],
  "Choose a local workspace file": [
    "ローカルの保存ファイルを選択してください",
    "请选择本地工作区文件",
    "請選擇本機工作區檔案",
    "로컬 작업 공간 파일을 선택하세요",
    "Elige un archivo local del espacio de trabajo",
    "Escolha um ficheiro local do espaço de trabalho",
    "Choisissez un fichier local d'espace de travail",
    "Scegli un file locale dell'area di lavoro"
  ],
  "Path selected. Save settings to apply.": [
    "保存先を選択しました。設定を保存して反映してください。",
    "路径已选择。保存设置后生效。",
    "已選取路徑。儲存設定後套用。",
    "경로를 선택했습니다. 설정을 저장하면 적용됩니다.",
    "Ruta seleccionada. Guarda para aplicar.",
    "Caminho selecionado. Guarde para aplicar.",
    "Chemin sélectionné. Enregistrez pour appliquer.",
    "Percorso selezionato. Salva per applicare."
  ],
  "Could not read the selected path": [
    "選択したパスを読み取れませんでした",
    "无法读取所选路径",
    "無法讀取所選路徑",
    "선택한 경로를 읽을 수 없습니다",
    "No se pudo leer la ruta seleccionada",
    "Não foi possível ler o caminho selecionado",
    "Impossible de lire le chemin sélectionné",
    "Impossibile leggere il percorso selezionato"
  ],
  "Endpoint: {0} · API usage is billed separately.": [
    "接続先：{0} · APIの利用料金は別途発生します。",
    "端点：{0} · API 使用单独计费。",
    "端點：{0} · API 使用另行計費。",
    "엔드포인트: {0} · API 사용 요금은 별도입니다.",
    "Endpoint: {0} · El uso de la API se factura aparte.",
    "Endpoint: {0} · A utilização da API é faturada à parte.",
    "Point d'accès : {0} · L'utilisation de l'API est facturée séparément.",
    "Endpoint: {0} · L'uso dell'API viene fatturato separatamente."
  ],
  "Base URL · Ollama uses /api/chat; compatible APIs use /chat/completions. Remote servers require HTTPS.": [
    "ベースURL · Ollamaは/api/chat、互換APIは/chat/completionsを使用します。リモートサーバーにはHTTPSが必要です。",
    "基础 URL · Ollama 使用 /api/chat，兼容 API 使用 /chat/completions。远程服务器必须使用 HTTPS。",
    "基底 URL · Ollama 使用 /api/chat，相容 API 使用 /chat/completions。遠端伺服器必須使用 HTTPS。",
    "기본 URL · Ollama는 /api/chat, 호환 API는 /chat/completions를 사용합니다. 원격 서버에는 HTTPS가 필요합니다.",
    "URL base · Ollama usa /api/chat; las API compatibles, /chat/completions. Los servidores remotos requieren HTTPS.",
    "URL base · Ollama usa /api/chat; APIs compatíveis usam /chat/completions. Servidores remotos exigem HTTPS.",
    "URL de base · Ollama utilise /api/chat ; les API compatibles, /chat/completions. Les serveurs distants exigent HTTPS.",
    "URL di base · Ollama usa /api/chat; le API compatibili usano /chat/completions. I server remoti richiedono HTTPS."
  ],
  "Endpoint changed. Refresh status; a key saved for the old endpoint will not be reused.": [
    "接続先を変更しました。状態を更新してください。旧接続先のキーは再利用しません。",
    "端点已更改。请刷新状态；不会复用旧端点的密钥。",
    "端點已變更。請重新整理狀態；不會重用舊端點的金鑰。",
    "엔드포인트가 변경되었습니다. 상태를 새로 고치세요. 이전 엔드포인트의 키는 재사용하지 않습니다.",
    "Endpoint cambiado. Actualiza el estado; no se reutilizará la clave anterior.",
    "Endpoint alterado. Atualize o estado; a chave anterior não será reutilizada.",
    "Point d'accès modifié. Actualisez l'état ; l'ancienne clé ne sera pas réutilisée.",
    "Endpoint modificato. Aggiorna lo stato; la vecchia chiave non verrà riutilizzata."
  ],
  "Uses this device’s CLI login. Flolinr does not copy CLI credentials.": [
    "この端末のCLIログインを使用します。FlolinrはCLIの認証情報をコピーしません。",
    "使用此设备的 CLI 登录。Flolinr 不复制 CLI 凭据。",
    "使用此裝置的 CLI 登入。Flolinr 不會複製 CLI 憑證。",
    "이 기기의 CLI 로그인을 사용합니다. Flolinr는 CLI 인증 정보를 복사하지 않습니다.",
    "Usa la sesión CLI de este dispositivo. Flolinr no copia sus credenciales.",
    "Usa a sessão CLI deste dispositivo. O Flolinr não copia as credenciais.",
    "Utilise la connexion CLI de cet appareil. Flolinr ne copie pas les identifiants CLI.",
    "Usa l'accesso CLI di questo dispositivo. Flolinr non copia le credenziali CLI."
  ],
  "API key · leave empty to keep saved key (optional for local services)": [
    "APIキー · 空欄で保存済みキーを維持（ローカルサービスでは任意）",
    "API 密钥 · 留空保留已保存的密钥（本地服务可选）",
    "API 金鑰 · 留空保留已儲存的金鑰（本機服務選填）",
    "API 키 · 비워 두면 저장된 키 유지 (로컬 서비스는 선택)",
    "Clave API · dejar vacía para conservarla (opcional en local)",
    "Chave API · deixe vazio para manter a chave (opcional em serviços locais)",
    "Clé API · laisser vide pour conserver la clé (facultative en local)",
    "Chiave API · lascia vuoto per mantenere quella salvata (facoltativa in locale)"
  ],
  "Save stores the key in this device’s desktop keyring, separate from notes and settings. Test uses a typed key without saving it.": [
    "保存するとキーをメモや設定とは別に、この端末のキーリングに保存します。テストでは入力したキーを保存せず使用します。",
    "保存时将密钥存入此设备的密钥环，与笔记和设置分开。测试使用输入的密钥但不保存。",
    "儲存時會將金鑰存入此裝置的鑰匙圈，與筆記和設定分開。測試會使用輸入的金鑰但不儲存。",
    "저장 시 키를 메모 및 설정과 별도로 이 기기의 키링에 저장합니다. 테스트는 입력한 키를 저장하지 않고 사용합니다.",
    "La clave se guarda en el llavero del dispositivo, separada de notas y ajustes. La prueba usa la clave introducida sin guardarla.",
    "A chave é guardada no porta-chaves do dispositivo, separada das notas e definições. O teste usa a chave introduzida sem a guardar.",
    "La clé est enregistrée dans le trousseau de cet appareil, séparément des notes et paramètres. Le test utilise la clé saisie sans l'enregistrer.",
    "La chiave viene salvata nel portachiavi del dispositivo, separata da note e impostazioni. Il test usa la chiave inserita senza salvarla."
  ],
  "Connection test sends a fixed sentence, never your notes. Provider usage limits / charges may apply.": [
    "接続テストは固定文だけを送り、メモは送りません。接続先の利用制限や料金が適用される場合があります。",
    "连接测试仅发送固定句子，不发送笔记。可能适用服务商的用量限制或费用。",
    "連線測試僅傳送固定句子，不傳送筆記。可能適用供應商的用量限制或費用。",
    "연결 테스트는 고정 문장만 전송하며 메모는 보내지 않습니다. 제공업체의 사용 제한이나 요금이 적용될 수 있습니다.",
    "La prueba envía una frase fija, nunca tus notas. Pueden aplicarse límites o cargos del proveedor.",
    "O teste envia uma frase fixa, nunca as notas. Podem aplicar-se limites ou custos do fornecedor.",
    "Le test envoie une phrase fixe, jamais vos notes. Des limites ou frais du fournisseur peuvent s'appliquer.",
    "Il test invia una frase fissa, mai le tue note. Potrebbero applicarsi limiti o costi del fornitore."
  ],
  "Command · JSON argument array; stdin → Markdown stdout": [
    "コマンド · JSON引数配列、標準入力 → Markdown標準出力",
    "命令 · JSON 参数数组；标准输入 → Markdown 标准输出",
    "命令 · JSON 引數陣列；標準輸入 → Markdown 標準輸出",
    "명령 · JSON 인수 배열; 표준 입력 → Markdown 표준 출력",
    "Comando · matriz de argumentos JSON; stdin → Markdown stdout",
    "Comando · lista de argumentos JSON; stdin → Markdown stdout",
    "Commande · tableau d'arguments JSON ; stdin → Markdown stdout",
    "Comando · array di argomenti JSON; stdin → Markdown stdout"
  ],
  "Zoom limits the target to that branch, including its collapsed descendants. Markdown conversion saves a separate .md file; your outline stays unchanged.": [
    "Zoom中は、その枝と折りたたんだ子項目だけが対象です。Markdown変換は別の.mdファイルとして保存し、元のOutlineは変更しません。",
    "聚焦后仅处理该分支及其折叠的子条目。Markdown 转换保存为独立的 .md 文件，不更改原大纲。",
    "聚焦後僅處理該分支及其折疊的子項目。Markdown 轉換會另存為 .md 檔案，不變更原大綱。",
    "확대하면 해당 가지와 접힌 하위 항목만 대상이 됩니다. Markdown 변환은 별도 .md 파일로 저장하며 원본 개요는 변경하지 않습니다.",
    "El zoom limita el ámbito a esa rama, incluidos sus descendientes contraídos. Markdown se guarda en otro archivo .md; el esquema no cambia.",
    "O zoom limita o âmbito ao ramo, incluindo os descendentes recolhidos. O Markdown é guardado num ficheiro .md separado; o esquema não muda.",
    "Le zoom limite la portée à cette branche, y compris les descendants repliés. Le Markdown est enregistré dans un fichier .md séparé ; le plan reste inchangé.",
    "Lo zoom limita l'ambito al ramo e ai discendenti compressi. Il Markdown viene salvato in un file .md separato; la struttura originale non cambia."
  ],
  "Settings saved. AI settings apply immediately. A workspace location change requires shell reload.": [
    "設定を保存しました。言語とAI設定はすぐに反映されます。保存先の変更にはシェルの再読み込みが必要です。",
    "设置已保存。语言和 AI 设置立即生效。更改工作区位置需要重新加载 Shell。",
    "設定已儲存。語言和 AI 設定立即生效。變更工作區位置需要重新載入 Shell。",
    "설정을 저장했습니다. 언어와 AI 설정은 즉시 적용됩니다. 작업 공간 위치 변경 시 셸을 다시 불러와야 합니다.",
    "Ajustes guardados. El idioma y la IA se aplican al instante. Cambiar la ubicación requiere recargar el shell.",
    "Definições guardadas. O idioma e a IA aplicam-se de imediato. Mudar a localização exige recarregar a shell.",
    "Paramètres enregistrés. La langue et l'IA s'appliquent immédiatement. Changer d'emplacement nécessite de recharger le shell.",
    "Impostazioni salvate. Lingua e IA si applicano subito. Cambiare percorso richiede il ricaricamento della shell."
  ],
  "CLI command must be a JSON argument array": [
    "CLIコマンドはJSONの引数配列で指定してください",
    "CLI 命令必须为 JSON 参数数组",
    "CLI 命令必須為 JSON 引數陣列",
    "CLI 명령은 JSON 인수 배열이어야 합니다",
    "El comando CLI debe ser una matriz de argumentos JSON",
    "O comando CLI deve ser uma lista de argumentos JSON",
    "La commande CLI doit être un tableau d'arguments JSON",
    "Il comando CLI deve essere un array di argomenti JSON"
  ],
  "Import completed": [
    "インポート完了",
    "导入完成",
    "匯入完成",
    "가져오기 완료",
    "Importación completada",
    "Importação concluída",
    "Importation terminée",
    "Importazione completata"
  ],
  "Could not complete import / export": [
    "インポート／エクスポートに失敗しました",
    "无法完成导入／导出",
    "無法完成匯入／匯出",
    "가져오기 / 내보내기를 완료하지 못했습니다",
    "No se pudo completar la importación o exportación",
    "Não foi possível concluir a importação ou exportação",
    "Impossible de terminer l'importation ou l'exportation",
    "Impossibile completare l'importazione o l'esportazione"
  ],
  "Exported: {0}": [
    "エクスポートしました：{0}",
    "已导出：{0}",
    "已匯出：{0}",
    "내보냄: {0}",
    "Exportado: {0}",
    "Exportado: {0}",
    "Exporté : {0}",
    "Esportato: {0}"
  ],
  "Choose a local file": [
    "ローカルファイルを選んでください",
    "请选择本地文件",
    "請選擇本機檔案",
    "로컬 파일을 선택하세요",
    "Elige un archivo local",
    "Escolha um ficheiro local",
    "Choisissez un fichier local",
    "Scegli un file locale"
  ],
  "Add an item before using AI": [
    "AIを使う前に項目を追加してください",
    "请先添加条目再使用 AI",
    "請先新增項目再使用 AI",
    "AI를 사용하기 전에 항목을 추가하세요",
    "Añade un elemento antes de usar la IA",
    "Adicione um item antes de usar a IA",
    "Ajoutez un élément avant d'utiliser l'IA",
    "Aggiungi un elemento prima di usare l'IA"
  ],
  "Generate an outline preview before applying": [
    "適用する前にOutlineのプレビューを生成してください",
    "请先生成大纲预览再应用",
    "請先產生大綱預覽再套用",
    "적용하기 전에 개요 미리보기를 생성하세요",
    "Genera una vista previa del esquema antes de aplicar",
    "Gere uma pré-visualização do esquema antes de aplicar",
    "Générez un aperçu du plan avant de l'appliquer",
    "Genera un'anteprima della struttura prima di applicarla"
  ],
  "The displayed scope changed. Generate a new preview first": [
    "表示範囲が変わりました。プレビューを生成し直してください",
    "显示范围已更改。请重新生成预览",
    "顯示範圍已變更。請重新產生預覽",
    "표시 범위가 변경되었습니다. 미리보기를 다시 생성하세요",
    "El ámbito ha cambiado. Genera otra vista previa",
    "O âmbito mudou. Gere uma nova pré-visualização",
    "La portée a changé. Générez un nouvel aperçu",
    "L'ambito è cambiato. Genera una nuova anteprima"
  ],
  "Could not start the import / export / AI helper": [
    "インポート／エクスポート／AIの補助処理を起動できませんでした",
    "无法启动导入／导出／AI 辅助程序",
    "無法啟動匯入／匯出／AI 輔助程式",
    "가져오기 / 내보내기 / AI 도우미를 시작하지 못했습니다",
    "No se pudo iniciar el asistente de importación, exportación o IA",
    "Não foi possível iniciar o assistente de importação, exportação ou IA",
    "Impossible de démarrer l'assistant d'importation, d'exportation ou d'IA",
    "Impossibile avviare l'assistente di importazione, esportazione o IA"
  ],
  "Writing & editing": [
    "入力と編集",
    "书写与编辑",
    "書寫與編輯",
    "작성 및 편집",
    "Escritura y edición",
    "Escrita e edição",
    "Rédaction et édition",
    "Scrittura e modifica"
  ],
  "Cursor movement & zoom": [
    "カーソル移動とZoom",
    "光标移动与聚焦",
    "游標移動與聚焦",
    "커서 이동 및 확대",
    "Movimiento del cursor y zoom",
    "Movimento do cursor e zoom",
    "Déplacement du curseur et zoom",
    "Movimento del cursore e zoom"
  ],
  "Daily notes & calendar": [
    "日付メモとカレンダー",
    "每日笔记与日历",
    "每日筆記與行事曆",
    "일일 메모 및 달력",
    "Notas diarias y calendario",
    "Notas diárias e calendário",
    "Notes quotidiennes et calendrier",
    "Note giornaliere e calendario"
  ],
  "Color & information": [
    "色と情報",
    "颜色与信息",
    "顏色與資訊",
    "색상 및 정보",
    "Color e información",
    "Cor e informação",
    "Couleur et informations",
    "Colore e informazioni"
  ],
  "Save, window & help": [
    "保存・ウィンドウ・ヘルプ",
    "保存、窗口与帮助",
    "儲存、視窗與說明",
    "저장, 창 및 도움말",
    "Guardado, ventana y ayuda",
    "Guardar, janela e ajuda",
    "Enregistrement, fenêtre et aide",
    "Salvataggio, finestra e aiuto"
  ],
  "Mouse": [
    "マウス",
    "鼠标",
    "滑鼠",
    "마우스",
    "Ratón",
    "Rato",
    "Souris",
    "Mouse"
  ],
  "Insert immediately below; move the remaining text to the new item": [
    "直下に項目を追加し、カーソル以降の文を移動",
    "在下方插入条目，并移入光标后的文本",
    "在下方插入項目，並移入游標後的文字",
    "바로 아래에 삽입하고 나머지 텍스트를 새 항목으로 이동",
    "Insertar debajo y mover el texto restante al nuevo elemento",
    "Inserir abaixo e mover o texto restante para o novo item",
    "Insérer en dessous et déplacer le texte restant vers le nouvel élément",
    "Inserisci sotto e sposta il testo rimanente nel nuovo elemento"
  ],
  "Insert a line break within the item": [
    "項目内で改行",
    "在条目内换行",
    "在項目內換行",
    "항목 안에 줄바꿈 삽입",
    "Insertar un salto de línea en el elemento",
    "Inserir uma quebra de linha no item",
    "Insérer un saut de ligne dans l'élément",
    "Inserisci un'interruzione di riga nell'elemento"
  ],
  "Join the item above; place the cursor at the join": [
    "上の項目と結合し、結合位置にカーソルを移動",
    "与上一条合并，并将光标放在连接处",
    "與上一項合併，並將游標放在連接處",
    "위 항목과 합치고 연결 지점에 커서 배치",
    "Unir con el elemento anterior y situar el cursor en la unión",
    "Juntar ao item anterior e colocar o cursor na junção",
    "Fusionner avec l'élément précédent et placer le curseur à la jonction",
    "Unisci all'elemento precedente e posiziona il cursore nel punto di unione"
  ],
  "Indent / outdent the item and its children": [
    "項目と子項目をインデント／解除",
    "增加／减少条目及子项的缩进",
    "增加／減少項目及子項的縮排",
    "항목 및 하위 항목 들여쓰기 / 내어쓰기",
    "Aumentar o reducir la sangría del elemento y sus hijos",
    "Aumentar ou reduzir o recuo do item e dos descendentes",
    "Augmenter ou réduire le retrait de l'élément et de ses enfants",
    "Aumenta o riduci il rientro dell'elemento e dei figli"
  ],
  "Reorder a branch among its siblings": [
    "同じ階層内で枝を並べ替え",
    "在同级条目间移动分支",
    "在同層項目間移動分支",
    "같은 수준의 가지 순서 변경",
    "Reordenar una rama entre sus hermanas",
    "Reordenar um ramo entre os seus pares",
    "Réordonner une branche parmi ses voisines",
    "Riordina un ramo tra quelli dello stesso livello"
  ],
  "Undo": [
    "元に戻す",
    "撤销",
    "復原",
    "실행 취소",
    "Deshacer",
    "Desfazer",
    "Annuler",
    "Annulla"
  ],
  "Redo": [
    "やり直す",
    "重做",
    "重做",
    "다시 실행",
    "Rehacer",
    "Refazer",
    "Rétablir",
    "Ripeti"
  ],
  "Add an item at the end of this zoom": [
    "現在の表示範囲の末尾に項目を追加",
    "在当前聚焦范围末尾添加条目",
    "在目前聚焦範圍末端新增項目",
    "현재 확대 범위 끝에 항목 추가",
    "Añadir un elemento al final de esta vista",
    "Adicionar um item no fim desta vista",
    "Ajouter un élément à la fin de cette vue",
    "Aggiungi un elemento alla fine della vista"
  ],
  "Move through text; cross items at the first / last visual line": [
    "文字内を移動し、先頭／末尾行で前後の項目へ移動",
    "在文本中移动，在首／末显示行跨越条目",
    "在文字中移動，在首／末顯示行跨越項目",
    "텍스트 안에서 이동하고 첫 줄 / 마지막 줄에서 항목 간 이동",
    "Moverse por el texto y cambiar de elemento en la primera o última línea visual",
    "Mover no texto e mudar de item na primeira ou última linha visual",
    "Se déplacer dans le texte et changer d'élément à la première ou dernière ligne affichée",
    "Spostati nel testo e passa tra elementi alla prima o ultima riga visiva"
  ],
  "Cross items at the beginning / end of text": [
    "文の先頭／末尾で前後の項目へ移動",
    "在文本首／尾跨越条目",
    "在文字首／尾跨越項目",
    "텍스트 시작 / 끝에서 항목 간 이동",
    "Cambiar de elemento al inicio o final del texto",
    "Mudar de item no início ou fim do texto",
    "Changer d'élément au début ou à la fin du texte",
    "Passa tra elementi all'inizio o alla fine del testo"
  ],
  "Focus previous visible item": [
    "前の表示項目へ移動",
    "聚焦上一个可见条目",
    "聚焦上一個可見項目",
    "이전 표시 항목으로 이동",
    "Enfocar el elemento visible anterior",
    "Focar o item visível anterior",
    "Activer l'élément visible précédent",
    "Passa all'elemento visibile precedente"
  ],
  "Focus next visible item": [
    "次の表示項目へ移動",
    "聚焦下一个可见条目",
    "聚焦下一個可見項目",
    "다음 표시 항목으로 이동",
    "Enfocar el siguiente elemento visible",
    "Focar o próximo item visível",
    "Activer l'élément visible suivant",
    "Passa all'elemento visibile successivo"
  ],
  "Zoom into the focused item": [
    "選択中の項目にZoom",
    "聚焦当前条目",
    "聚焦目前項目",
    "현재 항목 확대",
    "Ampliar el elemento enfocado",
    "Ampliar o item focado",
    "Zoomer sur l'élément actif",
    "Ingrandisci l'elemento attivo"
  ],
  "Go to parent": [
    "親の項目へ移動",
    "转到父条目",
    "移至父項目",
    "상위 항목으로 이동",
    "Ir al elemento padre",
    "Ir para o item superior",
    "Aller à l'élément parent",
    "Vai all'elemento padre"
  ],
  "Return to the Roll root": [
    "Rollの最上位へ戻る",
    "返回 Roll 根级",
    "返回 Roll 根層",
    "Roll 최상위로 돌아가기",
    "Volver a la raíz del Roll",
    "Voltar à raiz do Roll",
    "Revenir à la racine du Roll",
    "Torna alla radice del Roll"
  ],
  "Collapse / expand the current item": [
    "現在の項目を折りたたむ／展開",
    "折叠／展开当前条目",
    "折疊／展開目前項目",
    "현재 항목 접기 / 펼치기",
    "Contraer o expandir el elemento actual",
    "Recolher ou expandir o item atual",
    "Replier ou déplier l'élément actif",
    "Comprimi o espandi l'elemento corrente"
  ],
  "Switch focus between Rolls and editor": [
    "Roll一覧とエディターの間でフォーカスを切り替え",
    "在 Roll 列表与编辑器间切换焦点",
    "在 Roll 清單與編輯器間切換焦點",
    "Roll 목록과 편집기 간 포커스 전환",
    "Cambiar el foco entre Rolls y el editor",
    "Alternar o foco entre os Rolls e o editor",
    "Basculer le focus entre les Rolls et l'éditeur",
    "Sposta il focus tra Roll ed editor"
  ],
  "Create a new Roll and start typing": [
    "新しいRollを作成して入力",
    "创建新 Roll 并开始输入",
    "建立新 Roll 並開始輸入",
    "새 Roll을 만들고 입력 시작",
    "Crear un Roll y empezar a escribir",
    "Criar um Roll e começar a escrever",
    "Créer un Roll et commencer à écrire",
    "Crea un Roll e inizia a scrivere"
  ],
  "Rename the current Roll": [
    "現在のRoll名を変更",
    "重命名当前 Roll",
    "重新命名目前的 Roll",
    "현재 Roll 이름 변경",
    "Renombrar el Roll actual",
    "Mudar o nome do Roll atual",
    "Renommer le Roll actif",
    "Rinomina il Roll corrente"
  ],
  "Previous Roll": [
    "前のRoll",
    "上一个 Roll",
    "上一個 Roll",
    "이전 Roll",
    "Roll anterior",
    "Roll anterior",
    "Roll précédent",
    "Roll precedente"
  ],
  "Next Roll": [
    "次のRoll",
    "下一个 Roll",
    "下一個 Roll",
    "다음 Roll",
    "Siguiente Roll",
    "Próximo Roll",
    "Roll suivant",
    "Roll successivo"
  ],
  "Archive / restore the current Roll": [
    "現在のRollをアーカイブ／復元",
    "归档／恢复当前 Roll",
    "封存／還原目前的 Roll",
    "현재 Roll 보관 / 복원",
    "Archivar o restaurar el Roll actual",
    "Arquivar ou restaurar o Roll atual",
    "Archiver ou restaurer le Roll actif",
    "Archivia o ripristina il Roll corrente"
  ],
  "Confirm deletion of an archived Roll": [
    "アーカイブ済みRollの削除を確認",
    "确认删除已归档的 Roll",
    "確認刪除已封存的 Roll",
    "보관된 Roll 삭제 확인",
    "Confirmar la eliminación de un Roll archivado",
    "Confirmar a eliminação de um Roll arquivado",
    "Confirmer la suppression d'un Roll archivé",
    "Conferma l'eliminazione di un Roll archiviato"
  ],
  "Choose an emoji icon for this Roll": [
    "このRollの絵文字アイコンを選択",
    "为此 Roll 选择表情图标",
    "為此 Roll 選擇表情圖示",
    "이 Roll의 이모지 아이콘 선택",
    "Elegir un emoji para este Roll",
    "Escolher um emoji para este Roll",
    "Choisir un emoji pour ce Roll",
    "Scegli un'emoji per questo Roll"
  ],
  "Open today’s fixed memopad and start typing": [
    "今日のメモを開いて入力",
    "打开今日笔记并开始输入",
    "開啟今日筆記並開始輸入",
    "오늘의 메모를 열고 입력 시작",
    "Abrir la nota de hoy y escribir",
    "Abrir a nota de hoje e escrever",
    "Ouvrir la note du jour et écrire",
    "Apri la nota di oggi e scrivi"
  ],
  "Open the activity calendar": [
    "更新カレンダーを開く",
    "打开动态日历",
    "開啟動態行事曆",
    "활동 달력 열기",
    "Abrir el calendario de actividad",
    "Abrir o calendário de atividade",
    "Ouvrir le calendrier d'activité",
    "Apri il calendario delle attività"
  ],
  "Open the calendar": [
    "カレンダーを開く",
    "打开日历",
    "開啟行事曆",
    "달력 열기",
    "Abrir el calendario",
    "Abrir o calendário",
    "Ouvrir le calendrier",
    "Apri il calendario"
  ],
  "Select a result": [
    "検索結果を選択",
    "选择结果",
    "選取結果",
    "결과 선택",
    "Seleccionar un resultado",
    "Selecionar um resultado",
    "Sélectionner un résultat",
    "Seleziona un risultato"
  ],
  "Open the selected result / close search": [
    "選択した結果を開く／検索を閉じる",
    "打开所选结果／关闭搜索",
    "開啟所選結果／關閉搜尋",
    "선택한 결과 열기 / 검색 닫기",
    "Abrir el resultado o cerrar la búsqueda",
    "Abrir o resultado ou fechar a pesquisa",
    "Ouvrir le résultat ou fermer la recherche",
    "Apri il risultato o chiudi la ricerca"
  ],
  "Choose a color for the focused item": [
    "選択中の項目の色を変更",
    "选择当前条目的颜色",
    "選擇目前項目的顏色",
    "현재 항목의 색상 선택",
    "Elegir el color del elemento enfocado",
    "Escolher a cor do item focado",
    "Choisir la couleur de l'élément actif",
    "Scegli il colore dell'elemento attivo"
  ],
  "Show the current item's timestamps": [
    "現在の項目の作成・更新日時を表示",
    "显示当前条目的时间信息",
    "顯示目前項目的時間資訊",
    "현재 항목의 생성 및 수정 시간 표시",
    "Mostrar las fechas del elemento actual",
    "Mostrar as datas do item atual",
    "Afficher les dates de l'élément actif",
    "Mostra le date dell'elemento corrente"
  ],
  "Save now (changes also save automatically)": [
    "今すぐ保存（自動保存も有効）",
    "立即保存（也会自动保存）",
    "立即儲存（也會自動儲存）",
    "지금 저장 (자동 저장도 지원)",
    "Guardar ahora (también se guarda automáticamente)",
    "Guardar agora (também guarda automaticamente)",
    "Enregistrer maintenant (l'enregistrement automatique est actif)",
    "Salva ora (è attivo anche il salvataggio automatico)"
  ],
  "Save and close Flolinr": [
    "保存してFlolinrを閉じる",
    "保存并关闭 Flolinr",
    "儲存並關閉 Flolinr",
    "저장하고 Flolinr 닫기",
    "Guardar y cerrar Flolinr",
    "Guardar e fechar o Flolinr",
    "Enregistrer et fermer Flolinr",
    "Salva e chiudi Flolinr"
  ],
  "Show or hide this help": [
    "このヘルプを表示／非表示",
    "显示／隐藏此帮助",
    "顯示／隱藏此說明",
    "이 도움말 표시 / 숨기기",
    "Mostrar u ocultar esta ayuda",
    "Mostrar ou ocultar esta ajuda",
    "Afficher ou masquer cette aide",
    "Mostra o nascondi questa guida"
  ],
  "Close the current dialog": [
    "現在のダイアログを閉じる",
    "关闭当前对话框",
    "關閉目前對話框",
    "현재 대화상자 닫기",
    "Cerrar el diálogo actual",
    "Fechar a caixa de diálogo atual",
    "Fermer la boîte de dialogue active",
    "Chiudi la finestra di dialogo corrente"
  ],
  "Click a bullet": [
    "箇条書きの点をクリック",
    "点击圆点",
    "點選圓點",
    "글머리표 클릭",
    "Clic en una viñeta",
    "Clique num marcador",
    "Clic sur une puce",
    "Clic su un punto elenco"
  ],
  "Zoom into the item": [
    "項目にZoom",
    "聚焦条目",
    "聚焦項目",
    "항목 확대",
    "Ampliar el elemento",
    "Ampliar o item",
    "Zoomer sur l'élément",
    "Ingrandisci l'elemento"
  ],
  "Right-click a bullet": [
    "箇条書きの点を右クリック",
    "右键点击圆点",
    "在圓點上按右鍵",
    "글머리표 오른쪽 클릭",
    "Clic derecho en una viñeta",
    "Clique direito num marcador",
    "Clic droit sur une puce",
    "Clic destro su un punto elenco"
  ],
  "Choose a node color": [
    "項目の色を選択",
    "选择条目颜色",
    "選擇項目顏色",
    "항목 색상 선택",
    "Elegir el color del elemento",
    "Escolher a cor do item",
    "Choisir la couleur de l'élément",
    "Scegli il colore dell'elemento"
  ],
  "Click a triangle": [
    "三角をクリック",
    "点击三角形",
    "點選三角形",
    "삼각형 클릭",
    "Clic en un triángulo",
    "Clique num triângulo",
    "Clic sur un triangle",
    "Clic su un triangolo"
  ],
  "Collapse / expand children": [
    "子項目を折りたたむ／展開",
    "折叠／展开子条目",
    "折疊／展開子項目",
    "하위 항목 접기 / 펼치기",
    "Contraer o expandir los hijos",
    "Recolher ou expandir descendentes",
    "Replier ou déplier les enfants",
    "Comprimi o espandi i figli"
  ],
  "Click a breadcrumb": [
    "パンくずをクリック",
    "点击导航路径",
    "點選導覽路徑",
    "탐색 경로 클릭",
    "Clic en la ruta de navegación",
    "Clique no caminho de navegação",
    "Clic sur le fil d'Ariane",
    "Clic sul percorso di navigazione"
  ],
  "Return to a parent or Home": [
    "親の項目またはRollの最上位へ戻る",
    "返回父条目或 Roll 根级",
    "返回父項目或 Roll 根層",
    "상위 항목 또는 Roll 최상위로 돌아가기",
    "Volver al padre o a la raíz del Roll",
    "Voltar ao item superior ou à raiz do Roll",
    "Revenir au parent ou à la racine du Roll",
    "Torna al padre o alla radice del Roll"
  ],
  "Disabled": [
    "無効",
    "已禁用",
    "已停用",
    "비활성화",
    "Desactivado",
    "Desativado",
    "Désactivé",
    "Disattivato"
  ],
  "Customize shortcuts: {0}\nEnter, Tab, Backspace and dialog navigation use fixed editing keys.\n\nSearch spans all Rolls and daily notes. Select a result to zoom into the matching item.": [
    "ショートカットの設定：{0}\nEnter・Tab・Backspaceとダイアログ操作のキーは固定です。\n\n検索はすべてのRollと日付メモが対象です。結果を選ぶと該当項目にZoomします。",
    "自定义快捷键：{0}\nEnter、Tab、Backspace 及对话框导航使用固定按键。\n\n搜索范围包括所有 Roll 和每日笔记。选择结果可聚焦匹配条目。",
    "自訂快捷鍵：{0}\nEnter、Tab、Backspace 及對話框導覽使用固定按鍵。\n\n搜尋範圍包含所有 Roll 與每日筆記。選取結果可聚焦符合的項目。",
    "단축키 설정: {0}\nEnter, Tab, Backspace 및 대화상자 탐색 키는 고정입니다.\n\n모든 Roll과 일일 메모를 검색합니다. 결과를 선택하면 해당 항목이 확대됩니다.",
    "Personalizar atajos: {0}\nEnter, Tab, Backspace y la navegación de diálogos usan teclas fijas.\n\nLa búsqueda incluye todos los Rolls y notas diarias. Selecciona un resultado para ampliarlo.",
    "Personalizar atalhos: {0}\nEnter, Tab, Backspace e a navegação de diálogos usam teclas fixas.\n\nA pesquisa inclui todos os Rolls e notas diárias. Selecione um resultado para ampliar o item.",
    "Personnaliser les raccourcis : {0}\nEntrée, Tab, Retour arrière et la navigation des dialogues utilisent des touches fixes.\n\nLa recherche couvre tous les Rolls et notes quotidiennes. Sélectionnez un résultat pour zoomer dessus.",
    "Personalizza scorciatoie: {0}\nInvio, Tab, Backspace e la navigazione dei dialoghi usano tasti fissi.\n\nLa ricerca include tutti i Roll e le note giornaliere. Seleziona un risultato per ingrandire l'elemento."
  ],
  "Backspace at start": [
    "先頭でBackspace",
    "在开头按 Backspace",
    "在開頭按 Backspace",
    "시작에서 Backspace",
    "Backspace al inicio",
    "Backspace no início",
    "Retour arrière au début",
    "Backspace all'inizio"
  ],
  "Up / Down in search": [
    "検索中に↑／↓",
    "搜索中按 ↑／↓",
    "搜尋中按 ↑／↓",
    "검색에서 ↑ / ↓",
    "↑ / ↓ en la búsqueda",
    "↑ / ↓ na pesquisa",
    "↑ / ↓ dans la recherche",
    "↑ / ↓ nella ricerca"
  ],
  "Enter / Esc in search": [
    "検索中にEnter／Esc",
    "搜索中按 Enter／Esc",
    "搜尋中按 Enter／Esc",
    "검색에서 Enter / Esc",
    "Enter / Esc en la búsqueda",
    "Enter / Esc na pesquisa",
    "Entrée / Échap dans la recherche",
    "Invio / Esc nella ricerca"
  ],
  "Change Roll icon ({0})": [
    "Rollのアイコンを変更（{0}）",
    "更改 Roll 图标（{0}）",
    "變更 Roll 圖示（{0}）",
    "Roll 아이콘 변경 ({0})",
    "Cambiar icono del Roll ({0})",
    "Alterar ícone do Roll ({0})",
    "Changer l'icône du Roll ({0})",
    "Cambia icona del Roll ({0})"
  ],
  "Custom CLI": [
    "カスタムCLI",
    "自定义 CLI",
    "自訂 CLI",
    "사용자 지정 CLI",
    "CLI personalizado",
    "CLI personalizado",
    "CLI personnalisé",
    "CLI personalizzata"
  ],
  "OpenAI-compatible API": [
    "OpenAI互換API",
    "OpenAI 兼容 API",
    "OpenAI 相容 API",
    "OpenAI 호환 API",
    "API compatible con OpenAI",
    "API compatível com OpenAI",
    "API compatible OpenAI",
    "API compatibile con OpenAI"
  ],
  "CLI not installed or not on PATH. Set executable path in Advanced.": [
    "CLIが未インストールかPATHにありません。詳細設定で実行ファイルを指定してください。",
    "CLI 未安装或不在 PATH 中。请在高级设置中指定可执行文件路径。",
    "CLI 未安裝或不在 PATH 中。請在進階設定中指定執行檔路徑。",
    "CLI가 설치되지 않았거나 PATH에 없습니다. 고급 설정에서 실행 파일 경로를 지정하세요.",
    "CLI no instalado o fuera de PATH. Indica su ruta en Avanzado.",
    "CLI não instalado ou fora do PATH. Defina o caminho em Avançado.",
    "CLI non installé ou absent du PATH. Indiquez son chemin dans Avancé.",
    "CLI non installata o assente dal PATH. Imposta il percorso in Avanzate."
  ],
  "Not logged in. Choose Log in.": [
    "未ログインです。「ログイン」を選んでください。",
    "尚未登录。请选择“登录”。",
    "尚未登入。請選擇「登入」。",
    "로그인하지 않았습니다. 로그인을 선택하세요.",
    "Sin sesión iniciada. Selecciona Iniciar sesión.",
    "Sessão não iniciada. Escolha Iniciar sessão.",
    "Non connecté. Choisissez Se connecter.",
    "Accesso non effettuato. Scegli Accedi."
  ],
  "Logged in": [
    "ログイン済み",
    "已登录",
    "已登入",
    "로그인됨",
    "Sesión iniciada",
    "Sessão iniciada",
    "Connecté",
    "Accesso effettuato"
  ],
  " (this device)": [
    "（この端末）",
    "（此设备）",
    "（此裝置）",
    " (이 기기)",
    " (este dispositivo)",
    " (este dispositivo)",
    " (cet appareil)",
    " (questo dispositivo)"
  ],
  "Could not read CLI login status. Update Claude Code.": [
    "CLIのログイン状態を取得できません。Claude Codeを更新してください。",
    "无法读取 CLI 登录状态。请更新 Claude Code。",
    "無法讀取 CLI 登入狀態。請更新 Claude Code。",
    "CLI 로그인 상태를 읽지 못했습니다. Claude Code를 업데이트하세요.",
    "No se pudo leer la sesión CLI. Actualiza Claude Code.",
    "Não foi possível ler a sessão CLI. Atualize o Claude Code.",
    "Impossible de lire l'état de connexion CLI. Mettez à jour Claude Code.",
    "Impossibile leggere lo stato di accesso CLI. Aggiorna Claude Code."
  ],
  "Custom CLI found; use Connection test to verify authentication.": [
    "カスタムCLIが見つかりました。接続テストで認証を確認してください。",
    "已找到自定义 CLI；请测试连接以验证身份认证。",
    "已找到自訂 CLI；請測試連線以驗證身分認證。",
    "사용자 지정 CLI를 찾았습니다. 연결 테스트로 인증을 확인하세요.",
    "CLI personalizado encontrado; prueba la conexión para verificar la autenticación.",
    "CLI personalizado encontrado; teste a ligação para verificar a autenticação.",
    "CLI personnalisé trouvé ; testez la connexion pour vérifier l'authentification.",
    "CLI personalizzata trovata; verifica la connessione per controllare l'autenticazione."
  ],
  "Custom CLI executable not found.": [
    "カスタムCLIの実行ファイルが見つかりません。",
    "未找到自定义 CLI 可执行文件。",
    "找不到自訂 CLI 執行檔。",
    "사용자 지정 CLI 실행 파일을 찾지 못했습니다.",
    "No se encontró el ejecutable CLI personalizado.",
    "Executável CLI personalizado não encontrado.",
    "Exécutable CLI personnalisé introuvable.",
    "Eseguibile CLI personalizzato non trovato."
  ],
  "API key saved in this device’s keyring.": [
    "APIキーはこの端末のキーリングに保存されています。",
    "API 密钥已保存在此设备的密钥环中。",
    "API 金鑰已儲存於此裝置的鑰匙圈。",
    "API 키가 이 기기의 키링에 저장되었습니다.",
    "Clave API guardada en el llavero del dispositivo.",
    "Chave API guardada no porta-chaves deste dispositivo.",
    "Clé API enregistrée dans le trousseau de cet appareil.",
    "Chiave API salvata nel portachiavi del dispositivo."
  ],
  "No API key saved on this device.": [
    "この端末にAPIキーは保存されていません。",
    "此设备未保存 API 密钥。",
    "此裝置尚未儲存 API 金鑰。",
    "이 기기에 저장된 API 키가 없습니다.",
    "No hay clave API guardada en este dispositivo.",
    "Sem chave API guardada neste dispositivo.",
    "Aucune clé API enregistrée sur cet appareil.",
    "Nessuna chiave API salvata su questo dispositivo."
  ],
  "No key saved; optional for local / compatible services.": [
    "キーは未保存です。ローカル／互換サービスでは任意です。",
    "尚未保存密钥；本地／兼容服务可选。",
    "尚未儲存金鑰；本機／相容服務可選填。",
    "저장된 키가 없습니다. 로컬 / 호환 서비스에서는 선택 사항입니다.",
    "Sin clave guardada; es opcional en servicios locales o compatibles.",
    "Sem chave guardada; opcional para serviços locais ou compatíveis.",
    "Aucune clé enregistrée ; facultative pour les services locaux ou compatibles.",
    "Nessuna chiave salvata; facoltativa per servizi locali o compatibili."
  ],
  " Use Connection test to verify.": [
    " 接続テストで確認してください。",
    " 请测试连接以验证。",
    " 請測試連線以驗證。",
    " 연결 테스트로 확인하세요.",
    " Prueba la conexión para verificarlo.",
    " Teste a ligação para verificar.",
    " Testez la connexion pour vérifier.",
    " Verifica la connessione per controllare."
  ],
  "API key removed from this device.": [
    "この端末からAPIキーを削除しました。",
    "已从此设备移除 API 密钥。",
    "已從此裝置移除 API 金鑰。",
    "이 기기에서 API 키를 삭제했습니다.",
    "Clave API eliminada de este dispositivo.",
    "Chave API removida deste dispositivo.",
    "Clé API supprimée de cet appareil.",
    "Chiave API rimossa da questo dispositivo."
  ],
  "Login terminal opened. Complete login, then choose Refresh status.": [
    "ログイン用の端末を開きました。ログイン後に「状態を更新」を選んでください。",
    "已打开登录终端。完成登录后请选择“刷新状态”。",
    "已開啟登入終端。完成登入後請選擇「重新整理狀態」。",
    "로그인 터미널을 열었습니다. 로그인 후 상태 새로 고침을 선택하세요.",
    "Terminal de acceso abierto. Inicia sesión y actualiza el estado.",
    "Terminal de início de sessão aberto. Inicie sessão e atualize o estado.",
    "Terminal de connexion ouvert. Connectez-vous, puis actualisez l'état.",
    "Terminale di accesso aperto. Accedi e poi aggiorna lo stato."
  ],
  "Connection OK. Only a fixed test sentence was sent; no notes were sent.": [
    "接続を確認しました。固定のテスト文だけを送り、メモは送っていません。",
    "连接正常。仅发送了固定测试句子，未发送笔记。",
    "連線正常。僅傳送固定測試句子，未傳送筆記。",
    "연결 성공. 고정 테스트 문장만 전송했으며 메모는 보내지 않았습니다.",
    "Conexión correcta. Solo se envió una frase de prueba, sin notas.",
    "Ligação bem-sucedida. Foi enviada apenas uma frase de teste, sem notas.",
    "Connexion réussie. Seule une phrase de test fixe a été envoyée, aucune note.",
    "Connessione riuscita. È stata inviata solo una frase di prova, nessuna nota."
  ],
  "Choose an AI connection in Settings": [
    "設定でAI接続を選んでください",
    "请在设置中选择 AI 连接",
    "請在設定中選擇 AI 連線",
    "설정에서 AI 연결을 선택하세요",
    "Elige una conexión de IA en Ajustes",
    "Escolha uma ligação de IA nas Definições",
    "Choisissez une connexion IA dans les paramètres",
    "Scegli una connessione IA nelle impostazioni"
  ],
  "Enter a valid API key": [
    "有効なAPIキーを入力してください",
    "请输入有效的 API 密钥",
    "請輸入有效的 API 金鑰",
    "유효한 API 키를 입력하세요",
    "Introduce una clave API válida",
    "Introduza uma chave API válida",
    "Saisissez une clé API valide",
    "Inserisci una chiave API valida"
  ],
  "Enter the model ID in AI settings": [
    "AI設定にモデルIDを入力してください",
    "请在 AI 设置中输入模型 ID",
    "請在 AI 設定中輸入模型 ID",
    "AI 설정에 모델 ID를 입력하세요",
    "Introduce el ID del modelo en los ajustes de IA",
    "Introduza o ID do modelo nas definições de IA",
    "Saisissez l'identifiant du modèle dans les paramètres IA",
    "Inserisci l'ID del modello nelle impostazioni IA"
  ],
  "No API key saved on this device. Add it in AI settings": [
    "この端末にAPIキーがありません。AI設定で追加してください",
    "此设备未保存 API 密钥。请在 AI 设置中添加",
    "此裝置尚未儲存 API 金鑰。請在 AI 設定中新增",
    "이 기기에 API 키가 없습니다. AI 설정에서 추가하세요",
    "No hay clave API. Añádela en los ajustes de IA",
    "Sem chave API. Adicione-a nas definições de IA",
    "Aucune clé API enregistrée. Ajoutez-la dans les paramètres IA",
    "Nessuna chiave API salvata. Aggiungila nelle impostazioni IA"
  ],
  "Authentication failed; check the API key": [
    "認証に失敗しました。APIキーを確認してください",
    "认证失败，请检查 API 密钥",
    "認證失敗，請檢查 API 金鑰",
    "인증 실패. API 키를 확인하세요",
    "Error de autenticación; revisa la clave API",
    "Falha de autenticação; verifique a chave API",
    "Échec d'authentification ; vérifiez la clé API",
    "Autenticazione non riuscita; controlla la chiave API"
  ],
  "Authentication failed; log in to the selected CLI": [
    "認証に失敗しました。選択したCLIにログインしてください",
    "认证失败，请登录所选 CLI",
    "認證失敗，請登入所選 CLI",
    "인증 실패. 선택한 CLI에 로그인하세요",
    "Error de autenticación; inicia sesión en el CLI elegido",
    "Falha de autenticação; inicie sessão no CLI escolhido",
    "Échec d'authentification ; connectez-vous au CLI choisi",
    "Autenticazione non riuscita; accedi alla CLI selezionata"
  ],
  "Could not connect to the AI server. Check URL, network and server availability": [
    "AIサーバーに接続できません。URL・ネットワーク・稼働状況を確認してください",
    "无法连接 AI 服务器。请检查 URL、网络和服务器状态",
    "無法連線至 AI 伺服器。請檢查 URL、網路和伺服器狀態",
    "AI 서버에 연결하지 못했습니다. URL, 네트워크 및 서버 상태를 확인하세요",
    "No se pudo conectar al servidor de IA. Revisa la URL, la red y el servidor",
    "Não foi possível ligar ao servidor de IA. Verifique o URL, a rede e o servidor",
    "Impossible de joindre le serveur IA. Vérifiez l'URL, le réseau et le serveur",
    "Impossibile connettersi al server IA. Controlla URL, rete e server"
  ],
  "Choose a smaller scope (under 100 KB); zoom into a smaller branch": [
    "対象を100KB未満にしてください。小さな枝にZoomできます",
    "请选择小于 100 KB 的范围，可聚焦更小的分支",
    "請選擇小於 100 KB 的範圍，可聚焦較小的分支",
    "범위를 100KB 미만으로 줄이세요. 더 작은 가지를 확대할 수 있습니다",
    "Elige un ámbito menor de 100 KB; amplía una rama más pequeña",
    "Escolha um âmbito inferior a 100 KB; amplie um ramo menor",
    "Choisissez une portée inférieure à 100 Ko ; zoomez sur une branche plus petite",
    "Scegli un ambito inferiore a 100 KB; ingrandisci un ramo più piccolo"
  ],
  "AI returned empty or oversized output": [
    "AIの応答が空か、サイズ上限を超えています",
    "AI 返回的内容为空或过大",
    "AI 回傳的內容為空或過大",
    "AI 응답이 비어 있거나 너무 큽니다",
    "La respuesta de IA está vacía o es demasiado grande",
    "A resposta da IA está vazia ou é demasiado grande",
    "La réponse de l'IA est vide ou trop volumineuse",
    "La risposta dell'IA è vuota o troppo grande"
  ],
  "AI server returned an invalid response": [
    "AIサーバーの応答形式が不正です",
    "AI 服务器返回无效响应",
    "AI 伺服器回傳無效回應",
    "AI 서버가 잘못된 응답을 반환했습니다",
    "El servidor de IA devolvió una respuesta no válida",
    "O servidor de IA devolveu uma resposta inválida",
    "Le serveur IA a renvoyé une réponse invalide",
    "Il server IA ha restituito una risposta non valida"
  ],
  "LLM CLI timed out; check login and connectivity": [
    "LLM CLIがタイムアウトしました。ログインと接続を確認してください",
    "LLM CLI 超时，请检查登录状态和网络连接",
    "LLM CLI 逾時，請檢查登入狀態和網路連線",
    "LLM CLI 시간 초과. 로그인 및 연결 상태를 확인하세요",
    "El CLI de LLM agotó el tiempo; revisa la sesión y la conexión",
    "O CLI de LLM excedeu o tempo; verifique a sessão e a ligação",
    "Délai du CLI LLM dépassé ; vérifiez la connexion et l'authentification",
    "Tempo scaduto per la CLI LLM; controlla accesso e connessione"
  ],
  "Choose an absolute .json file path": [
    "絶対パスで.jsonファイルを指定してください",
    "请选择 .json 文件的绝对路径",
    "請選擇 .json 檔案的絕對路徑",
    ".json 파일의 절대 경로를 지정하세요",
    "Elige una ruta absoluta de archivo .json",
    "Escolha um caminho absoluto para um ficheiro .json",
    "Choisissez un chemin absolu de fichier .json",
    "Scegli un percorso assoluto per un file .json"
  ],
  "Could not create settings directory": [
    "設定フォルダを作成できませんでした",
    "无法创建设置目录",
    "無法建立設定目錄",
    "설정 폴더를 만들지 못했습니다",
    "No se pudo crear la carpeta de ajustes",
    "Não foi possível criar a pasta de definições",
    "Impossible de créer le dossier des paramètres",
    "Impossibile creare la cartella delle impostazioni"
  ],
  "Could not read settings: {0}": [
    "設定を読み込めませんでした：{0}",
    "无法读取设置：{0}",
    "無法讀取設定：{0}",
    "설정을 읽지 못했습니다: {0}",
    "No se pudieron leer los ajustes: {0}",
    "Não foi possível ler as definições: {0}",
    "Impossible de lire les paramètres : {0}",
    "Impossibile leggere le impostazioni: {0}"
  ],
  "Could not save settings: {0}": [
    "設定を保存できませんでした：{0}",
    "无法保存设置：{0}",
    "無法儲存設定：{0}",
    "설정을 저장하지 못했습니다: {0}",
    "No se pudieron guardar los ajustes: {0}",
    "Não foi possível guardar as definições: {0}",
    "Impossible d'enregistrer les paramètres : {0}",
    "Impossibile salvare le impostazioni: {0}"
  ],
  "Pending note changed. Reopen quick capture to retry.": [
    "保存待ちのメモが変更されました。クイックメモを開き直してください。",
    "待保存笔记已更改。请重新打开快速笔记以重试。",
    "待儲存筆記已變更。請重新開啟快速筆記重試。",
    "대기 중인 메모가 변경되었습니다. 빠른 메모를 다시 여세요.",
    "La nota pendiente cambió. Vuelve a abrir la nota rápida.",
    "A nota pendente mudou. Reabra a nota rápida.",
    "La note en attente a changé. Rouvrez la saisie rapide.",
    "La nota in sospeso è cambiata. Riapri la nota rapida."
  ],
  "Imported {0} items.": [
    "{0}項目をインポートしました。",
    "已导入 {0} 个条目。",
    "已匯入 {0} 個項目。",
    "항목 {0}개를 가져왔습니다.",
    "Se importaron {0} elementos.",
    "Foram importados {0} itens.",
    "{0} éléments importés.",
    "Importati {0} elementi."
  ],
  "Expansion instructions (optional)": [
    "展開の追加指示（任意）",
    "扩展指令（可选）",
    "擴展指示（選填）",
    "확장 지침 (선택)",
    "Instrucciones de desarrollo (opcionales)",
    "Instruções de expansão (opcionais)",
    "Instructions de développement (facultatives)",
    "Istruzioni di espansione (facoltative)"
  ],
  "For example: add practical examples and break each step into smaller tasks.": [
    "例：具体例を加え、各手順を小さなタスクに分けてください。",
    "例如：添加实际示例，并将各步骤细分为小任务。",
    "例如：加入實際範例，並將各步驟細分為小任務。",
    "예: 실용적인 예시를 추가하고 각 단계를 작은 작업으로 나눠 주세요.",
    "Ejemplo: añade ejemplos prácticos y divide cada paso en tareas pequeñas.",
    "Exemplo: adicione exemplos práticos e divida cada passo em tarefas menores.",
    "Exemple : ajoutez des exemples pratiques et divisez chaque étape en petites tâches.",
    "Esempio: aggiungi esempi pratici e suddividi ogni passaggio in attività più piccole."
  ],
  "Generate expansion": [
    "指示に沿って展開",
    "生成扩展",
    "產生擴展",
    "확장 생성",
    "Generar desarrollo",
    "Gerar expansão",
    "Générer le développement",
    "Genera l'espansione"
  ],
  "Expansion instructions must be text under 10,000 characters": [
    "追加指示は10,000文字以内で入力してください",
    "扩展指令须为不超过 10,000 字符的文本",
    "擴展指示須為不超過 10,000 字元的文字",
    "확장 지침은 10,000자 이하의 텍스트여야 합니다",
    "Las instrucciones no pueden superar los 10.000 caracteres",
    "As instruções não podem exceder 10.000 caracteres",
    "Les instructions ne doivent pas dépasser 10 000 caractères",
    "Le istruzioni non possono superare i 10.000 caratteri"
  ],
  "Insert…": [
    "挿入…",
    "插入…",
    "插入…",
    "삽입…",
    "Insertar…",
    "Inserir…",
    "Insérer…",
    "Inserisci…"
  ],
  "Insert file or code": [
    "ファイル・コードを挿入",
    "插入文件或代码",
    "插入檔案或程式碼",
    "파일 또는 코드 삽입",
    "Insertar archivo o código",
    "Inserir ficheiro ou código",
    "Insérer un fichier ou du code",
    "Inserisci file o codice"
  ],
  "Insert file": [
    "ファイルを挿入",
    "插入文件",
    "插入檔案",
    "파일 삽입",
    "Insertar archivo",
    "Inserir ficheiro",
    "Insérer un fichier",
    "Inserisci file"
  ],
  "Choose file…": [
    "ファイルを選択…",
    "选择文件…",
    "選擇檔案…",
    "파일 선택…",
    "Elegir archivo…",
    "Escolher ficheiro…",
    "Choisir un fichier…",
    "Scegli file…"
  ],
  "All files (*)": [
    "すべてのファイル (*)",
    "所有文件 (*)",
    "所有檔案 (*)",
    "모든 파일 (*)",
    "Todos los archivos (*)",
    "Todos os ficheiros (*)",
    "Tous les fichiers (*)",
    "Tutti i file (*)"
  ],
  "Filename or title": [
    "ファイル名または見出し",
    "文件名或标题",
    "檔名或標題",
    "파일 이름 또는 제목",
    "Nombre de archivo o título",
    "Nome do ficheiro ou título",
    "Nom du fichier ou titre",
    "Nome file o titolo"
  ],
  "Language: html, css, json, markdown, text…": [
    "言語：html、css、json、markdown、text…",
    "语言：html、css、json、markdown、text…",
    "語言：html、css、json、markdown、text…",
    "언어: html, css, json, markdown, text…",
    "Lenguaje: html, css, json, markdown, text…",
    "Linguagem: html, css, json, markdown, text…",
    "Langage : html, css, json, markdown, text…",
    "Linguaggio: html, css, json, markdown, text…"
  ],
  "Paste code or text here": [
    "コードやテキストを貼り付け",
    "在此粘贴代码或文本",
    "在此貼上程式碼或文字",
    "코드 또는 텍스트 붙여넣기",
    "Pega código o texto aquí",
    "Cole código ou texto aqui",
    "Collez du code ou du texte ici",
    "Incolla codice o testo qui"
  ],
  "Insert code or text": [
    "コード・テキストを挿入",
    "插入代码或文本",
    "插入程式碼或文字",
    "코드 또는 텍스트 삽입",
    "Insertar código o texto",
    "Inserir código ou texto",
    "Insérer le code ou le texte",
    "Inserisci codice o testo"
  ],
  "Insert a copy under the selected item. Embedded content is never sent to AI.": [
    "スラッシュコマンドの項目を挿入ブロックに置き換えます。挿入内容はAIに送信しません。",
    "将斜杠命令条目替换为嵌入块。嵌入内容不会发送给 AI。",
    "將斜線命令項目替換為嵌入區塊。嵌入內容不會傳送給 AI。",
    "슬래시 명령 항목을 삽입 블록으로 바꿉니다. 삽입 내용은 AI로 전송되지 않습니다.",
    "Sustituye el elemento del comando por el bloque. El contenido no se envía a la IA.",
    "Substitui o item do comando pelo bloco. O conteúdo não é enviado à IA.",
    "Remplace l'élément de commande par le bloc. Le contenu n'est pas envoyé à l'IA.",
    "Sostituisce l'elemento del comando con il blocco. Il contenuto non viene inviato all'IA."
  ],
  "Protected from AI": [
    "AIによる編集から保護",
    "受 AI 编辑保护",
    "受 AI 編輯保護",
    "AI 편집으로부터 보호됨",
    "Protegido frente a la IA",
    "Protegido contra a IA",
    "Protégé contre l'IA",
    "Protetto dall'IA"
  ],
  "Edit content": [
    "内容を編集",
    "编辑内容",
    "編輯內容",
    "내용 편집",
    "Editar contenido",
    "Editar conteúdo",
    "Modifier le contenu",
    "Modifica contenuto"
  ],
  "Save file…": [
    "ファイルを保存…",
    "保存文件…",
    "儲存檔案…",
    "파일 저장…",
    "Guardar archivo…",
    "Guardar ficheiro…",
    "Enregistrer le fichier…",
    "Salva file…"
  ],
  "Remove content": [
    "挿入内容を削除",
    "移除嵌入内容",
    "移除嵌入內容",
    "삽입 내용 제거",
    "Quitar contenido",
    "Remover conteúdo",
    "Retirer le contenu",
    "Rimuovi contenuto"
  ],
  "Image preview unavailable": [
    "画像をプレビューできません",
    "无法预览图片",
    "無法預覽圖片",
    "이미지를 미리 볼 수 없습니다",
    "Vista previa no disponible",
    "Pré-visualização indisponível",
    "Aperçu indisponible",
    "Anteprima non disponibile"
  ],
  "Show content": [
    "内容を展開",
    "展开内容",
    "展開內容",
    "내용 펼치기",
    "Mostrar contenido",
    "Mostrar conteúdo",
    "Afficher le contenu",
    "Mostra contenuto"
  ],
  "Hide content": [
    "内容を折りたたむ",
    "折叠内容",
    "折疊內容",
    "내용 접기",
    "Ocultar contenido",
    "Ocultar conteúdo",
    "Masquer le contenu",
    "Nascondi contenuto"
  ],
  "Invalid attachment": [
    "挿入内容の形式が不正です",
    "嵌入内容格式无效",
    "嵌入內容格式無效",
    "삽입 내용 형식이 잘못되었습니다",
    "Contenido incrustado no válido",
    "Conteúdo incorporado inválido",
    "Contenu intégré invalide",
    "Contenuto incorporato non valido"
  ],
  "The insertion target changed": [
    "挿入先が変更されました",
    "插入目标已更改",
    "插入目標已變更",
    "삽입 대상이 변경되었습니다",
    "El destino de inserción ha cambiado",
    "O destino de inserção mudou",
    "La destination d'insertion a changé",
    "La destinazione è cambiata"
  ],
  "Inserted files must be 2 MB or smaller": [
    "挿入ファイルは2MB以内にしてください",
    "插入文件不能超过 2 MB",
    "插入檔案不能超過 2 MB",
    "삽입 파일은 2MB 이하여야 합니다",
    "El archivo no puede superar 2 MB",
    "O ficheiro não pode exceder 2 MB",
    "Le fichier ne doit pas dépasser 2 Mo",
    "Il file non può superare 2 MB"
  ],
  "Text and code files must use UTF-8 encoding": [
    "テキストとコードはUTF-8形式にしてください",
    "文本和代码文件必须使用 UTF-8 编码",
    "文字和程式碼檔案必須使用 UTF-8 編碼",
    "텍스트 및 코드 파일은 UTF-8이어야 합니다",
    "Los archivos de texto y código deben usar UTF-8",
    "Os ficheiros de texto e código devem usar UTF-8",
    "Les fichiers texte et code doivent utiliser UTF-8",
    "I file di testo e codice devono usare UTF-8"
  ],
  "AI changed a protected attachment marker. Generate a new preview.": [
    "AIが保護用の目印を変更したため適用できません。生成し直してください。",
    "AI 更改了保护标记，无法应用。请重新生成预览。",
    "AI 變更了保護標記，無法套用。請重新產生預覽。",
    "AI가 보호 표식을 변경했습니다. 미리보기를 다시 생성하세요.",
    "La IA cambió un marcador protegido. Genera otra vista previa.",
    "A IA alterou um marcador protegido. Gere nova pré-visualização.",
    "L'IA a modifié un marqueur protégé. Générez un nouvel aperçu.",
    "L'IA ha modificato un marcatore protetto. Genera una nuova anteprima."
  ],
  "AI changed a protected attachment's indentation. Generate a new preview.": [
    "AIが挿入項目のインデントを変更したため適用できません。生成し直してください。",
    "AI 更改了受保护条目的缩进。请重新生成预览。",
    "AI 變更了受保護項目的縮排。請重新產生預覽。",
    "AI가 보호된 항목의 들여쓰기를 변경했습니다. 미리보기를 다시 생성하세요.",
    "La IA cambió la sangría de un elemento protegido. Genera otra vista previa.",
    "A IA alterou o recuo de um item protegido. Gere nova pré-visualização.",
    "L'IA a modifié le retrait d'un élément protégé. Générez un nouvel aperçu.",
    "L'IA ha modificato il rientro di un elemento protetto. Genera una nuova anteprima."
  ]
};
// Slash command dialogs and actions.
Object.assign(catalog, {
  "Insert date": [
    "日付を挿入",
    "插入日期",
    "插入日期",
    "날짜 삽입",
    "Insertar fecha",
    "Inserir data",
    "Insérer une date",
    "Inserisci data"
  ],
  "Link to a Roll or item": [
    "Roll・項目へのリンク",
    "链接到 Roll 或条目",
    "連結至 Roll 或項目",
    "Roll 또는 항목에 연결",
    "Enlazar a un Roll o elemento",
    "Ligar a um Roll ou item",
    "Lien vers un Roll ou un élément",
    "Collega a un Roll o elemento"
  ],
  "Insert template": [
    "テンプレートを挿入",
    "插入模板",
    "插入範本",
    "템플릿 삽입",
    "Insertar plantilla",
    "Inserir modelo",
    "Insérer un modèle",
    "Inserisci modello"
  ],
  "Insert": [
    "挿入",
    "插入",
    "插入",
    "삽입",
    "Insertar",
    "Inserir",
    "Insérer",
    "Inserisci"
  ],
  "Search Rolls and items": [
    "Roll・項目を検索",
    "搜索 Roll 和条目",
    "搜尋 Roll 與項目",
    "Roll 및 항목 검색",
    "Buscar Rolls y elementos",
    "Pesquisar Rolls e itens",
    "Rechercher des Rolls et éléments",
    "Cerca Roll ed elementi"
  ],
  "Task": [
    "タスク",
    "任务",
    "任務",
    "작업",
    "Tarea",
    "Tarefa",
    "Tâche",
    "Attività"
  ],
  "Could not complete action": [
    "操作を完了できませんでした",
    "无法完成操作",
    "無法完成操作",
    "작업을 완료할 수 없습니다",
    "No se pudo completar la acción",
    "Não foi possível concluir a ação",
    "Impossible de terminer l’action",
    "Impossibile completare l’azione"
  ],
  "Link unavailable": [
    "リンク先が見つかりません",
    "链接不可用",
    "連結無法使用",
    "링크를 사용할 수 없습니다",
    "Enlace no disponible",
    "Ligação indisponível",
    "Lien indisponible",
    "Collegamento non disponibile"
  ],
  "The linked item no longer exists": [
    "リンク先のRollまたは項目が見つかりません",
    "链接的 Roll 或条目已不存在",
    "連結的 Roll 或項目已不存在",
    "연결된 Roll 또는 항목이 더 이상 없습니다",
    "El Roll o elemento enlazado ya no existe",
    "O Roll ou item ligado já não existe",
    "Le Roll ou l’élément lié n’existe plus",
    "Il Roll o elemento collegato non esiste più"
  ],
  "Meeting notes": [
    "議事録",
    "会议记录",
    "會議記錄",
    "회의록",
    "Notas de reunión",
    "Notas de reunião",
    "Notes de réunion",
    "Note della riunione"
  ],
  "Daily review": [
    "日次レビュー",
    "每日回顾",
    "每日回顧",
    "일일 회고",
    "Revisión diaria",
    "Revisão diária",
    "Bilan quotidien",
    "Riepilogo giornaliero"
  ],
  "Project plan": [
    "プロジェクト計画",
    "项目计划",
    "專案計畫",
    "프로젝트 계획",
    "Plan de proyecto",
    "Plano de projeto",
    "Plan de projet",
    "Piano di progetto"
  ],
  "Choose a template": [
    "テンプレートを選択してください",
    "请选择模板",
    "請選擇範本",
    "템플릿을 선택하세요",
    "Elige una plantilla",
    "Escolha um modelo",
    "Choisissez un modèle",
    "Scegli un modello"
  ],
  "Choose a valid date": [
    "有効な日付を選択してください",
    "请选择有效日期",
    "請選擇有效日期",
    "유효한 날짜를 선택하세요",
    "Elige una fecha válida",
    "Escolha uma data válida",
    "Choisissez une date valide",
    "Scegli una data valida"
  ]
});

Object.assign(catalog, {"No results": ["結果なし", "无结果", "沒有結果", "결과 없음", "Sin resultados", "Sem resultados", "Aucun résultat", "Nessun risultato"]});

Object.assign(catalog, {"Templates": ["テンプレート", "模板", "範本", "템플릿", "Plantillas", "Modelos", "Modèles", "Modelli"], "Add": ["追加", "添加", "新增", "추가", "Añadir", "Adicionar", "Ajouter", "Aggiungi"], "Save": ["保存", "保存", "儲存", "저장", "Guardar", "Guardar", "Enregistrer", "Salva"], "Template name": ["テンプレート名", "模板名称", "範本名稱", "템플릿 이름", "Nombre de plantilla", "Nome do modelo", "Nom du modèle", "Nome modello"], "One item per line. Use two spaces or a Tab to indent.": ["1行に1項目。半角スペース2つかTabで字下げします。", "每行一个条目，用两个空格或 Tab 缩进。", "每行一個項目，用兩個空格或 Tab 縮排。", "한 줄에 한 항목. 공백 두 개 또는 Tab으로 들여쓰기합니다.", "Un elemento por línea. Usa dos espacios o Tab para sangrar.", "Um item por linha. Use dois espaços ou Tab para indentar.", "Un élément par ligne. Deux espaces ou Tab pour indenter.", "Un elemento per riga. Due spazi o Tab per rientrare."], "Restore defaults": ["標準に戻す", "恢复默认", "還原預設", "기본값 복원", "Restaurar valores", "Restaurar predefinições", "Rétablir par défaut", "Ripristina predefiniti"], "Invalid templates": ["テンプレートの形式が正しくありません", "模板格式无效", "範本格式無效", "잘못된 템플릿", "Plantillas no válidas", "Modelos inválidos", "Modèles invalides", "Modelli non validi"], "Use two spaces per indentation level": ["字下げ1段につき半角スペース2つを使ってください", "每级缩进使用两个空格", "每層縮排使用兩個空格", "들여쓰기 단계마다 공백 두 개를 사용하세요", "Usa dos espacios por nivel", "Use dois espaços por nível", "Utilisez deux espaces par niveau", "Usa due spazi per livello"]});

Object.assign(catalog, {
  "Workspace": ["ワークスペース", "工作区", "工作區", "작업 공간", "Espacio de trabajo", "Espaço de trabalho", "Espace de travail", "Area di lavoro"],
  "AI Connections": ["AI接続", "AI 连接", "AI 連線", "AI 연결", "Conexiones de IA", "Ligações de IA", "Connexions IA", "Connessioni IA"]
});

Object.assign(catalog, {
  "File or pasted content": ["ファイルまたは貼り付けた内容", "文件或粘贴内容", "檔案或貼上的內容", "파일 또는 붙여넣은 내용", "Archivo o contenido pegado", "Ficheiro ou conteúdo colado", "Fichier ou contenu collé", "File o contenuto incollato"],
  "Template outline": ["テンプレートのアウトライン", "模板大纲", "範本大綱", "템플릿 아웃라인", "Esquema de plantilla", "Estrutura do modelo", "Plan du modèle", "Struttura del modello"],
  "Connection details": ["接続の詳細", "连接详情", "連線詳細資料", "연결 세부 정보", "Detalles de conexión", "Detalhes da ligação", "Détails de la connexion", "Dettagli connessione"]
});

function translate(code, source, args) {
    if (typeof source !== "string") return "";
    var normalized = normalize(code);
    var index = legacyCodes.indexOf(normalized);
    var extra = European.catalog[normalized];
    var hasTranslation = Object.prototype.hasOwnProperty.call(catalog, source);
    var hasEnglish = Object.prototype.hasOwnProperty.call(english, source);
    var translated = extra && Object.prototype.hasOwnProperty.call(extra, source) ? extra[source] : index >= 0 && hasTranslation ? catalog[source][index] : hasEnglish ? english[source] : source;
    if (!hasTranslation && !hasEnglish) {
        var device = " (this device)", verify = " Use Connection test to verify.";
        if (source.endsWith(device)) translated = translate(code, source.slice(0, -device.length)) + translate(code, device);
        else if (source.endsWith(verify)) translated = translate(code, source.slice(0, -verify.length)) + translate(code, verify);
        else if (source.startsWith("Logged in · ")) translated = translate(code, "Logged in") + " · " + source.slice(12);
    }
    return translated.replace(/\{(\d+)\}/g, function(match, n) { return args && Number(n) < args.length ? String(args[Number(n)]) : match; });
}
