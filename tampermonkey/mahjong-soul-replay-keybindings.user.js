// ==UserScript==
// @name         Mahjong Soul Replay Keybindings
// @namespace    https://mahjongsoul.game.yo-star.com/
// @version      1.1
// @updateURL    https://raw.githubusercontent.com/lehmacdj/.dotfiles/main/tampermonkey/mahjong-soul-replay-keybindings.user.js
// @downloadURL  https://raw.githubusercontent.com/lehmacdj/.dotfiles/main/tampermonkey/mahjong-soul-replay-keybindings.user.js
// @description  [WIP — unfinished] Keyboard shortcuts for the Mahjong Soul replay viewer. Disabled by default; set ENABLED = true to use.
// @match        https://mahjongsoul.game.yo-star.com/*
// @grant        none
// ==/UserScript==
//
// ⚠️ WORK IN PROGRESS — this script is not finished yet.
// It ships disabled: the ENABLED flag below is false, so the script loads
// but does nothing. Flip it to true to try it out. (Tampermonkey has no
// header key for installing a script disabled, so this flag is how we opt
// out by default.)
//
(function () {
  "use strict";
  // Set to true to actually enable the keybindings. See the WIP note above.
  const ENABLED = false;
  if (!ENABLED) {
    console.log(
      "%c[MJS Keybinds]%c disabled (WIP) — set ENABLED = true to use",
      "color:#f0c040;font-weight:bold",
      ""
    );
    return;
  }
  // ── Helpers ──────────────────────────────────────────────────────────
  /**
   * Return the active replay‑toolbar controller, or null when not in a
   * replay.  mj_uis[14] is the full‑featured replay bar (class "R");
   * mj_uis[4] is the lighter spectator bar (class "C") — both expose
   * the same navigation surface.
   */
  function getReplayCtrl() {
    try {
      const uis = GameMgr.Inst.uimgr._mj_uis;
      const u14 = uis[14];
      if (u14 && u14._enable && u14.root && u14.root.visible) return u14;
      const u4 = uis[4];
      if (u4 && u4._enable && u4.root && u4.root.visible) return u4;
    } catch (_) {}
    return null;
  }
  function getDesktopMgr() {
    try {
      return view.DesktopMgr.Inst;
    } catch (_) {}
    return null;
  }
  // ── Actions ──────────────────────────────────────────────────────────
  const actions = {
    // — Primary navigation (your requested bindings) —
    prevRound: {
      keys: ["ArrowUp"],
      label: "↑",
      desc: "Previous game (round)",
      fn() {
        const c = getReplayCtrl();
        c && c.preRound();
      },
    },
    nextRound: {
      keys: ["ArrowDown"],
      label: "↓",
      desc: "Next game (round)",
      fn() {
        const c = getReplayCtrl();
        c && c.nextRound();
      },
    },
    prevTurn: {
      keys: ["ArrowLeft"],
      label: "←",
      desc: "Previous turn (xun)",
      fn() {
        const c = getReplayCtrl();
        c && c.preXun();
      },
    },
    nextTurn: {
      keys: ["ArrowRight"],
      label: "→",
      desc: "Next turn (xun)",
      fn() {
        const c = getReplayCtrl();
        c && c.nextXun();
      },
    },
    prevStep: {
      keys: [",", "<"],
      label: ", / <",
      desc: "Step backward",
      fn() {
        const c = getReplayCtrl();
        c && c.preStep();
      },
    },
    nextStep: {
      keys: [".", ">"],
      label: ". / >",
      desc: "Step forward",
      fn() {
        const c = getReplayCtrl();
        c && c.nextStep();
      },
    },
    // — Playback —
    playPause: {
      keys: [" "],
      label: "Space",
      desc: "Play / Pause",
      fn() {
        const c = getReplayCtrl();
        if (!c) return;
        c.auto_play = !c.auto_play;
      },
    },
    // — POV switching (1‑4 for each seat) —
    pov1: {
      keys: ["1"],
      label: "1",
      desc: "Switch POV → seat 0 (host / East start)",
      fn() {
        const dm = getDesktopMgr();
        dm && dm.changeMainbody(0);
        const c = getReplayCtrl();
        c && c.onChangeMainBody();
      },
    },
    pov2: {
      keys: ["2"],
      label: "2",
      desc: "Switch POV → seat 1",
      fn() {
        const dm = getDesktopMgr();
        dm && dm.changeMainbody(1);
        const c = getReplayCtrl();
        c && c.onChangeMainBody();
      },
    },
    pov3: {
      keys: ["3"],
      label: "3",
      desc: "Switch POV → seat 2",
      fn() {
        const dm = getDesktopMgr();
        dm && dm.changeMainbody(2);
        const c = getReplayCtrl();
        c && c.onChangeMainBody();
      },
    },
    pov4: {
      keys: ["4"],
      label: "4",
      desc: "Switch POV → seat 3",
      fn() {
        const dm = getDesktopMgr();
        dm && dm.changeMainbody(3);
        const c = getReplayCtrl();
        c && c.onChangeMainBody();
      },
    },
    // — Jump to specific round / turn —
    firstRound: {
      keys: ["Home"],
      label: "Home",
      desc: "Jump to first round",
      fn() {
        const c = getReplayCtrl();
        c && c.jumpRound(0);
      },
    },
    lastRound: {
      keys: ["End"],
      label: "End",
      desc: "Jump to last round",
      fn() {
        const c = getReplayCtrl();
        if (!c || !c.rounds) return;
        c.jumpRound(c.rounds.length - 1);
      },
    },
    // — Panels & toggles —
    toggleWall: {
      keys: ["w"],
      label: "W",
      desc: "Toggle wall (paishan) view",
      fn() {
        const c = getReplayCtrl();
        if (!c || !c.page_paishan) return;
        if (c.page_paishan.me && c.page_paishan.me.visible) {
          c.page_paishan.close();
        } else {
          c.page_paishan.show();
        }
      },
    },
    toggleRoundPicker: {
      keys: ["r"],
      label: "R",
      desc: "Toggle round picker",
      fn() {
        const c = getReplayCtrl();
        if (!c || !c.page_chang) return;
        if (c.page_chang.isBig) {
          c.page_chang.close();
        } else {
          c.page_chang.show();
        }
      },
    },
    toggleTurnPicker: {
      keys: ["t"],
      label: "T",
      desc: "Toggle turn (xun) picker",
      fn() {
        const c = getReplayCtrl();
        if (!c || !c.page_xun) return;
        if (c.page_xun.me && c.page_xun.me.visible) {
          c.page_xun.close();
        } else {
          c.page_xun.show();
        }
      },
    },
    toggleAnalysis: {
      keys: ["m"],
      label: "M",
      desc: "Toggle MAKA analysis",
      fn() {
        const c = getReplayCtrl();
        if (!c || !c.makaInfo) return;
        c.makaInfo.onClickMakaBtn();
      },
    },
    prevAnalysisDiff: {
      keys: ["["],
      label: "[",
      desc: "Jump to previous analysis difference",
      fn() {
        const c = getReplayCtrl();
        if (!c || !c.makaInfo || !c.makaInfo.lastDifBtn) return;
        const btn = c.makaInfo.lastDifBtn.btn;
        if (btn && btn.clickHandler) btn.clickHandler.run();
      },
    },
    nextAnalysisDiff: {
      keys: ["]"],
      label: "]",
      desc: "Jump to next analysis difference",
      fn() {
        const c = getReplayCtrl();
        if (!c || !c.makaInfo || !c.makaInfo.nextDifBtn) return;
        const btn = c.makaInfo.nextDifBtn.btn;
        if (btn && btn.clickHandler) btn.clickHandler.run();
      },
    },
    toggleScoreDisplay: {
      keys: ["s"],
      label: "S",
      desc: "Toggle score delta display",
      fn() {
        try {
          const ui1 = GameMgr.Inst.uimgr._mj_uis[1];
          ui1 && ui1.onBtnShowScoreDelta();
        } catch (_) {}
      },
    },
    toggleToolbar: {
      keys: ["h"],
      label: "H",
      desc: "Hide / show replay toolbar",
      fn() {
        const c = getReplayCtrl();
        if (!c) return;
        c.changeRootVisible();
      },
    },
    exitReplay: {
      keys: ["Escape"],
      label: "Esc",
      desc: "Exit replay / close panel",
      fn() {
        const c = getReplayCtrl();
        if (!c) return;
        // Close open panels first, then exit
        if (
          c.page_paishan &&
          c.page_paishan.me &&
          c.page_paishan.me.visible
        ) {
          c.page_paishan.close();
          return;
        }
        if (c.page_chang && c.page_chang.isBig) {
          c.page_chang.close();
          return;
        }
        if (c.page_xun && c.page_xun.me && c.page_xun.me.visible) {
          c.page_xun.close();
          return;
        }
        c.onBack();
      },
    },
    // — Help —
    showHelp: {
      keys: ["/", "?"],
      label: "? / /",
      desc: "Show this help overlay",
      fn() {
        toggleHelp();
      },
    },
  };
  // ── Build key → action lookup ────────────────────────────────────────
  const keyMap = new Map();
  for (const [id, action] of Object.entries(actions)) {
    for (const key of action.keys) {
      keyMap.set(key, action);
    }
  }
  // ── Keyboard listener ────────────────────────────────────────────────
  window.addEventListener(
    "keydown",
    (e) => {
      // Don't intercept when an input / textarea is focused
      if (
        e.target.tagName === "INPUT" ||
        e.target.tagName === "TEXTAREA" ||
        e.target.isContentEditable
      )
        return;
      // Don't intercept modified keys (except shift for < > ?)
      if (e.ctrlKey || e.altKey || e.metaKey) return;
      const action = keyMap.get(e.key);
      if (!action) return;
      // Only fire when the replay controller is active (except help)
      if (action !== actions.showHelp && !getReplayCtrl()) return;
      e.preventDefault();
      e.stopPropagation();
      action.fn();
    },
    true
  ); // capture phase so we beat the game's own handlers
  // ── Help overlay ─────────────────────────────────────────────────────
  let helpEl = null;
  function toggleHelp() {
    if (helpEl) {
      helpEl.remove();
      helpEl = null;
      return;
    }
    helpEl = document.createElement("div");
    helpEl.id = "mjs-keybind-help";
    const groups = [
      {
        title: "Navigation",
        ids: [
          "prevStep",
          "nextStep",
          "prevTurn",
          "nextTurn",
          "prevRound",
          "nextRound",
          "firstRound",
          "lastRound",
        ],
      },
      {
        title: "Playback",
        ids: ["playPause"],
      },
      {
        title: "POV",
        ids: ["pov1", "pov2", "pov3", "pov4"],
      },
      {
        title: "Panels & Toggles",
        ids: [
          "toggleWall",
          "toggleRoundPicker",
          "toggleTurnPicker",
          "toggleAnalysis",
          "prevAnalysisDiff",
          "nextAnalysisDiff",
          "toggleScoreDisplay",
          "toggleToolbar",
        ],
      },
      {
        title: "Other",
        ids: ["exitReplay", "showHelp"],
      },
    ];
    let html = `<div style="
      position:fixed; inset:0; z-index:99999;
      background:rgba(0,0,0,.75);
      display:flex; align-items:center; justify-content:center;
      font-family: 'Segoe UI', system-ui, sans-serif;
      cursor:pointer;
    " id="mjs-help-backdrop">
      <div style="
        background:#1a1a2e; color:#eee; border-radius:12px;
        padding:28px 36px; max-width:520px; width:90%;
        box-shadow: 0 8px 32px rgba(0,0,0,.5);
        cursor:default;
      " onclick="event.stopPropagation()">
        <h2 style="margin:0 0 18px; font-size:20px; color:#f0c040; text-align:center;">
          ⌨️ Replay Keyboard Shortcuts
        </h2>`;
    for (const group of groups) {
      html += `<div style="margin-bottom:12px;">
        <div style="font-size:13px; color:#f0c040; font-weight:600;
                    margin-bottom:4px; text-transform:uppercase;
                    letter-spacing:1px;">${group.title}</div>`;
      for (const id of group.ids) {
        const a = actions[id];
        html += `<div style="display:flex; justify-content:space-between;
                    padding:3px 0; font-size:14px;">
          <span style="color:#ccc;">${a.desc}</span>
          <kbd style="background:#2a2a4a; padding:2px 8px; border-radius:4px;
                      font-family:monospace; font-size:13px; color:#f0c040;
                      border:1px solid #3a3a5a; min-width:36px;
                      text-align:center;">${a.label}</kbd>
        </div>`;
      }
      html += `</div>`;
    }
    html += `<div style="text-align:center; margin-top:14px;
                font-size:12px; color:#666;">
                Press <kbd style="background:#2a2a4a; padding:1px 6px;
                border-radius:3px; border:1px solid #3a3a5a;
                color:#f0c040;">?</kbd> or click outside to close
             </div>
      </div>
    </div>`;
    helpEl.innerHTML = html;
    document.body.appendChild(helpEl);
    document.getElementById("mjs-help-backdrop").addEventListener(
      "click",
      () => toggleHelp()
    );
  }
  console.log(
    "%c[MJS Keybinds]%c Loaded — press %c?%c for help",
    "color:#f0c040;font-weight:bold",
    "",
    "color:#f0c040;font-weight:bold",
    ""
  );
})();
