---
name: click-path-audit
description: "ユーザー向けのすべてのボタン/タッチポイントを完全な状態変化シーケンスでトレースし、個別には機能するが互いにキャンセルし合う、誤った最終状態を生成する、または UI を一貫しない状態に残す関数のバグを見つける。利用する場面: 体系的デバッグでバグが見つからないがユーザーがボタンが壊れていると報告する、または共有状態ストアに触れる大規模リファクタの後 (click-path audit, behavioural flow, state interaction, race condition, sequential undo, Zustand, Redux)。"
origin: community
---

# /click-path-audit — 挙動フロー監査

静的コード読み取りが見逃すバグを見つける: 状態相互作用の副作用、順次呼び出し間のレースコンディション、互いを密かに取り消すハンドラ。

## このスキルが解決する問題

従来のデバッグはチェックする:
- 関数は存在するか? (配線欠落)
- クラッシュするか? (ランタイムエラー)
- 正しい型を返すか? (データフロー)

しかし以下はチェックしない:
- **最終 UI 状態がボタンラベルが約束するものと一致するか?**
- **関数 B が関数 A が行ったことを密かに取り消すか?**
- **共有状態 (Zustand/Redux/context) が意図したアクションをキャンセルする副作用を持つか?**

実例: 「New Email」ボタンが `setComposeMode(true)` 次に `selectThread(null)` を呼んだ。両方は個別に機能した。しかし `selectThread` には `composeMode: false` をリセットする副作用があった。ボタンは何もしなかった。体系的デバッグで 54 のバグが見つかった — これは見逃された。

---

## 仕組み

対象エリアのすべてのインタラクティブタッチポイントについて:

```
1. IDENTIFY the handler (onClick, onSubmit, onChange, etc.)
2. TRACE every function call in the handler, IN ORDER
3. For EACH function call:
   a. What state does it READ?
   b. What state does it WRITE?
   c. Does it have SIDE EFFECTS on shared state?
   d. Does it reset/clear any state as a side effect?
4. CHECK: Does any later call UNDO a state change from an earlier call?
5. CHECK: Is the FINAL state what the user expects from the button label?
6. CHECK: Are there race conditions (async calls that resolve in wrong order)?
```

---

## 実行ステップ

### Step 1: 状態ストアをマップする

任意のタッチポイントを監査する前に、すべての状態ストアアクションの副作用マップを構築する:

```
For each Zustand store / React context in scope:
  For each action/setter:
    - What fields does it set?
    - Does it RESET other fields as a side effect?
    - Document: actionName → {sets: [...], resets: [...]}
```

これが決定的な参照である。「New Email」バグは `selectThread` が `composeMode` をリセットすることを知らずには不可視だった。

**出力フォーマット:**
```
STORE: emailStore
  setComposeMode(bool) → sets: {composeMode}
  selectThread(thread|null) → sets: {selectedThread, selectedThreadId, messages, drafts, selectedDraft, summary} RESETS: {composeMode: false, composeData: null, redraftOpen: false}
  setDraftGenerating(bool) → sets: {draftGenerating}
  ...

DANGEROUS RESETS (actions that clear state they don't own):
  selectThread → resets composeMode (owned by setComposeMode)
  reset → resets everything
```

### Step 2: 各タッチポイントを監査する

対象エリアの各ボタン/トグル/フォーム送信について:

```
TOUCHPOINT: [Button label] in [Component:line]
  HANDLER: onClick → {
    call 1: functionA() → sets {X: true}
    call 2: functionB() → sets {Y: null} RESETS {X: false}  ← CONFLICT
  }
  EXPECTED: User sees [description of what button label promises]
  ACTUAL: X is false because functionB reset it
  VERDICT: BUG — [description]
```

**以下の各バグパターンをチェックする:**

#### Pattern 1: 順次取り消し
```
handler() {
  setState_A(true)     // sets X = true
  setState_B(null)     // side effect: resets X = false
}
// Result: X is false. First call was pointless.
```

#### Pattern 2: 非同期レース
```
handler() {
  fetchA().then(() => setState({ loading: false }))
  fetchB().then(() => setState({ loading: true }))
}
// Result: final loading state depends on which resolves first
```

#### Pattern 3: 古いクロージャ
```
const [count, setCount] = useState(0)
const handler = useCallback(() => {
  setCount(count + 1)  // captures stale count
  setCount(count + 1)  // same stale count — increments by 1, not 2
}, [count])
```

#### Pattern 4: 状態遷移欠落
```
// Button says "Save" but handler only validates, never actually saves
// Button says "Delete" but handler sets a flag without calling the API
// Button says "Send" but the API endpoint is removed/broken
```

#### Pattern 5: 条件付きデッドパス
```
handler() {
  if (someState) {        // someState is ALWAYS false at this point
    doTheActualThing()    // never reached
  }
}
```

#### Pattern 6: useEffect 干渉
```
// Button sets stateX = true
// A useEffect watches stateX and resets it to false
// User sees nothing happen
```

### Step 3: 報告

見つかった各バグについて:

```
CLICK-PATH-NNN: [severity: CRITICAL/HIGH/MEDIUM/LOW]
  Touchpoint: [Button label] in [file:line]
  Pattern: [Sequential Undo / Async Race / Stale Closure / Missing Transition / Dead Path / useEffect Interference]
  Handler: [function name or inline]
  Trace:
    1. [call] → sets {field: value}
    2. [call] → RESETS {field: value}  ← CONFLICT
  Expected: [what user expects]
  Actual: [what actually happens]
  Fix: [specific fix]
```

---

## スコープ制御

この監査は高コストである。適切にスコープする:

- **フルアプリ監査:** ローンチ時や大規模リファクタ後に使う。ページごとに並列エージェントを起動。
- **単一ページ監査:** 新しいページを構築した後やユーザーが壊れたボタンを報告した後に使う。
- **ストア重点監査:** Zustand ストアを変更した後 — 変更されたアクションのすべての消費者を監査する。

### フルアプリの推奨エージェント分割:

```
Agent 1: Map ALL state stores (Step 1) — this is shared context for all other agents
Agent 2: Dashboard (Tasks, Notes, Journal, Ideas)
Agent 3: Chat (DanteChatColumn, JustChatPage)
Agent 4: Emails (ThreadList, DraftArea, EmailsPage)
Agent 5: Projects (ProjectsPage, ProjectOverviewTab, NewProjectWizard)
Agent 6: CRM (all sub-tabs)
Agent 7: Profile, Settings, Vault, Notifications
Agent 8: Management Suite (all pages)
```

Agent 1 は最初に完了しなければならない。その出力は他のすべてのエージェントの入力である。

---

## 利用するタイミング

- 体系的デバッグが「バグなし」を見つけたがユーザーが壊れた UI を報告した後
- 任意の Zustand ストアアクションを変更した後 (すべての呼び出し元をチェック)
- 共有状態に触れる任意のリファクタの後
- リリース前、重要なユーザーフローで
- ボタンが「何もしない」とき — これがそのためのツールである

## 利用しないタイミング

- API レベルバグ (誤ったレスポンス形状、欠落エンドポイント) — systematic-debugging を使う
- スタイル/レイアウトの問題 — ビジュアル検査
- パフォーマンス問題 — プロファイリングツール

---

## 他スキルとの統合

- `/superpowers:systematic-debugging` (他の 54 バグタイプを見つける) の **後** に実行
- `/superpowers:verification-before-completion` (修正が機能することを検証) の **前** に実行
- `/superpowers:test-driven-development` に供給 — ここで見つかった各バグはテストを得るべき

---

## 例: このスキルにインスパイアしたバグ

**ThreadList.tsx「New Email」ボタン:**
```
onClick={() => {
  useEmailStore.getState().setComposeMode(true)   // ✓ sets composeMode = true
  useEmailStore.getState().selectThread(null)      // ✗ RESETS composeMode = false
}}
```

ストア定義:
```
selectThread: (thread) => set({
  selectedThread: thread,
  selectedThreadId: thread?.id ?? null,
  messages: [],
  drafts: [],
  selectedDraft: null,
  summary: null,
  composeMode: false,     // ← THIS silent reset killed the button
  composeData: null,
  redraftOpen: false,
})
```

**体系的デバッグが見逃した理由:**
- ボタンに onClick ハンドラがある (デッドではない)
- 両関数が存在する (配線欠落なし)
- どちらの関数もクラッシュしない (ランタイムエラーなし)
- データ型が正しい (型不一致なし)

**click-path 監査がそれをキャッチする理由:**
- Step 1 が `selectThread` が `composeMode` をリセットするとマップ
- Step 2 がハンドラをトレース: call 1 が true を設定、call 2 が false にリセット
- 判定: 順次取り消し — 最終状態がボタン意図と矛盾
