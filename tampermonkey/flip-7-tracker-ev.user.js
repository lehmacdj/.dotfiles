// ==UserScript==
// @name         Flip 7 Tracker + EV
// @namespace    flip7tracker
// @version      2.1
// @updateURL    https://raw.githubusercontent.com/lehmacdj/.dotfiles/main/tampermonkey/flip-7-tracker-ev.user.js
// @downloadURL  https://raw.githubusercontent.com/lehmacdj/.dotfiles/main/tampermonkey/flip-7-tracker-ev.user.js
// @description  Card tracker and EV hit/stay advisor for Flip 7 on BGA
// @match        https://boardgamearena.com/*/flipseven*
// @run-at       document-idle
// @grant        none
// ==/UserScript==
(function () {
  'use strict';
  // --- CARD MATERIALS (22 types, 94 total) ---
  const MATERIALS = [
    { id: 0,  value: 0,    action: null,      count: 1  },
    { id: 1,  value: 1,    action: null,      count: 1  },
    { id: 2,  value: 2,    action: null,      count: 2  },
    { id: 3,  value: 3,    action: null,      count: 3  },
    { id: 4,  value: 4,    action: null,      count: 4  },
    { id: 5,  value: 5,    action: null,      count: 5  },
    { id: 6,  value: 6,    action: null,      count: 6  },
    { id: 7,  value: 7,    action: null,      count: 7  },
    { id: 8,  value: 8,    action: null,      count: 8  },
    { id: 9,  value: 9,    action: null,      count: 9  },
    { id: 10, value: 10,   action: null,      count: 10 },
    { id: 11, value: 11,   action: null,      count: 11 },
    { id: 12, value: 12,   action: null,      count: 12 },
    { id: 13, value: null,  action: '+2',     count: 1  },
    { id: 14, value: null,  action: '+4',     count: 1  },
    { id: 15, value: null,  action: '+6',     count: 1  },
    { id: 16, value: null,  action: '+8',     count: 1  },
    { id: 17, value: null,  action: '+10',    count: 1  },
    { id: 18, value: null,  action: 'x2',     count: 1  },
    { id: 19, value: null,  action: 'freeze', count: 3  },
    { id: 20, value: null,  action: 'flip3',  count: 3  },
    { id: 21, value: null,  action: 'chance', count: 3  }
  ];
  const TOTAL_CARDS = 94;
  function matLabel(mid) {
    const m = MATERIALS[mid];
    if (!m) return '?';
    if (m.value !== null) return String(m.value);
    return m.action;
  }
  function isNumber(mid) {
    return MATERIALS[mid] && MATERIALS[mid].value !== null;
  }
  // --- SCORING ---
  function scoreHand(nums, mods) {
    let numSum = nums.reduce((a, b) => a + b, 0);
    let hasX2 = mods.includes('x2');
    if (hasX2) numSum *= 2;
    let flat = 0;
    mods.forEach(m => {
      const match = m.match(/^\\+(\\d+)$/);
      if (match) flat += parseInt(match[1]);
    });
    let score = numSum + flat;
    // Flip 7 bonus: if exactly 7 unique number values
    if (new Set(nums).size >= 7) score += 15;
    return score;
  }
  // --- RECONCILE DECK STATE ---
  // Uses DOM .f7_deck as ground truth for deck count, fixes gamedatas discrepancies
  function reconcileDeck(gd) {
    const deckEl = document.querySelector('.f7_deck');
    if (!deckEl) return;
    const domDeckCount = parseInt(deckEl.textContent);
    if (isNaN(domDeckCount)) return;
    const cards = gd.board.cards;
    const knownOut = cards.filter(c => c.location === 'player' || c.location === 'wait').length;
    const trueDiscard = TOTAL_CARDS - domDeckCount - knownOut;
    const currentDeck2Null = cards.filter(
      c => c.location === 'deck2' && (!c.locationId || c.locationId === '' || c.locationId === 'null')
    );
    const currentDeck2NullCount = currentDeck2Null.length;
    if (currentDeck2NullCount > trueDiscard) {
      // Some deck2:null cards were reshuffled back to deck — move them
      const excess = currentDeck2NullCount - trueDiscard;
      let moved = 0;
      for (const c of currentDeck2Null) {
        if (moved >= excess) break;
        c.location = 'deck';
        c.locationId = null;
        c.materialId = null;
        c.visible = '0';
        moved++;
      }
    }
    // Also ensure the gamedatas deck count matches DOM
    const gdDeckCount = cards.filter(c => c.location === 'deck').length;
    if (gdDeckCount < domDeckCount) {
      // More cards in the real deck than gamedatas knows — find unaccounted cards
      const deficit = domDeckCount - gdDeckCount;
      // Move additional deck2:null cards to deck
      const remaining2 = cards.filter(
        c => c.location === 'deck2' && (!c.locationId || c.locationId === '' || c.locationId === 'null')
      );
      let moved = 0;
      for (const c of remaining2) {
        if (moved >= deficit) break;
        c.location = 'deck';
        c.locationId = null;
        c.materialId = null;
        c.visible = '0';
        moved++;
      }
    }
  }
  // --- RESET DECK FOR NEW ROUND ---
  function resetDeckForNewRound(gd) {
    gd.board.cards.forEach(c => {
      if (c.location === 'deck2' || c.location === 'wait') {
        c.location = 'deck';
        c.locationId = null;
        c.materialId = null;
        c.visible = '0';
      }
    });
  }
  // --- COMPUTE EV ---
  function computeEV(gd) {
    const myId = String(window.gameui.player_id);
    const players = gd.players;
    let myNo = null;
    for (const [pid, p] of Object.entries(players)) {
      if (pid === myId) { myNo = p.no; break; }
    }
    if (!myNo) return null;
    const myCards = gd.board.cards.filter(
      c => c.location === 'player' && String(c.locationId) === String(myNo) && c.materialId !== null
    );
    const nums = [];
    const mods = [];
    const myNumberSet = new Set();
    let has2ndChance = false;
    myCards.forEach(c => {
      const mid = parseInt(c.materialId);
      const m = MATERIALS[mid];
      if (!m) return;
      if (m.value !== null) {
        nums.push(m.value);
        myNumberSet.add(m.value);
      } else {
        mods.push(m.action);
        if (m.action === 'chance') has2ndChance = true;
      }
    });
    const currentScore = scoreHand(nums, mods);
    // Cards remaining in deck (face-down, unknown identity)
    const deckEl = document.querySelector('.f7_deck');
    const domDeckCount = deckEl ? parseInt(deckEl.textContent) : 0;
    if (domDeckCount <= 0) return { currentScore, evHit: 0, rec: 'STAY', conf: 'Strong', delta: currentScore, bustPct: 100, safePct: 0 };
    // Build remaining composition: start with full deck, subtract all known cards
    const remaining = MATERIALS.map(m => m.count);
    gd.board.cards.forEach(c => {
      if (c.materialId !== null && c.materialId !== '' && c.location !== 'deck') {
        const mid = parseInt(c.materialId);
        if (mid >= 0 && mid < remaining.length) remaining[mid]--;
      }
    });
    // Clamp negatives
    remaining.forEach((v, i) => { if (v < 0) remaining[i] = 0; });
    const totalKnownRemaining = remaining.reduce((a, b) => a + b, 0);
    // Use domDeckCount as the actual number of draws possible
    // Scale probabilities: each card type's probability = remaining[mid] / totalKnownRemaining
    // but total draws from deck = domDeckCount
    let evHit = 0;
    let bustCount = 0;
    let safeCount = 0;
    for (let mid = 0; mid < MATERIALS.length; mid++) {
      if (remaining[mid] <= 0) continue;
      const m = MATERIALS[mid];
      const prob = remaining[mid] / Math.max(totalKnownRemaining, 1);
      if (m.value !== null) {
        // Number card
        if (myNumberSet.has(m.value)) {
          // Duplicate!
          if (has2ndChance) {
            // 2nd chance absorbs it: lose the 2nd chance + discard duplicate, keep going
            const newNums = [...nums];
            const newMods = mods.filter((x, i) => {
              if (x === 'chance') { return false; } // remove first chance
              return true;
            });
            // Actually just remove one 'chance' from mods
            let removedChance = false;
            const filteredMods = mods.filter(x => {
              if (!removedChance && x === 'chance') { removedChance = true; return false; }
              return true;
            });
            const s = scoreHand(newNums, filteredMods);
            evHit += prob * s;
            safeCount += remaining[mid];
          } else {
            // Bust
            evHit += prob * 0;
            bustCount += remaining[mid];
          }
        } else {
          // Safe number
          const newNums = [...nums, m.value];
          const s = scoreHand(newNums, mods);
          evHit += prob * s;
          safeCount += remaining[mid];
        }
      } else if (m.action === 'freeze') {
        // Bank at current score
        evHit += prob * currentScore;
        safeCount += remaining[mid];
      } else if (m.action === 'flip3') {
        // Forced 3 more draws — approximate as 65% of current score (risky)
        evHit += prob * currentScore * 0.65;
        safeCount += remaining[mid];
      } else if (m.action === 'chance') {
        // 2nd chance — adds protection, value ~ current score
        const newMods = [...mods, 'chance'];
        const s = scoreHand(nums, newMods);
        evHit += prob * s;
        safeCount += remaining[mid];
      } else if (m.action === 'x2') {
        const newMods = [...mods, 'x2'];
        const s = scoreHand(nums, newMods);
        evHit += prob * s;
        safeCount += remaining[mid];
      } else if (m.action && m.action.startsWith('+')) {
        const newMods = [...mods, m.action];
        const s = scoreHand(nums, newMods);
        evHit += prob * s;
        safeCount += remaining[mid];
      }
    }
    const bustPct = Math.round(100 * bustCount / Math.max(totalKnownRemaining, 1));
    const safePct = 100 - bustPct;
    const delta = evHit - currentScore;
    let rec, conf;
    if (delta > 15) { rec = 'HIT'; conf = 'Strong'; }
    else if (delta > 5) { rec = 'HIT'; conf = 'Lean'; }
    else if (delta > -5) { rec = delta >= 0 ? 'HIT' : 'STAY'; conf = 'Marginal'; }
    else if (delta > -15) { rec = 'STAY'; conf = 'Lean'; }
    else { rec = 'STAY'; conf = 'Strong'; }
    return { currentScore, evHit: Math.round(evHit * 10) / 10, rec, conf, delta: Math.round(delta * 10) / 10, bustPct, safePct };
  }
  // --- BUILD UI ---
  function buildTracker() {
    const existing = document.getElementById('flip7-tracker');
    if (existing) existing.remove();
    const gd = window.gameui.gamedatas;
    reconcileDeck(gd);
    const deckEl = document.querySelector('.f7_deck');
    const domDeckCount = deckEl ? parseInt(deckEl.textContent) : '?';
    // Count known cards by materialId outside deck
    const seen = MATERIALS.map(() => 0);
    gd.board.cards.forEach(c => {
      if (c.materialId !== null && c.materialId !== '' && c.location !== 'deck') {
        const mid = parseInt(c.materialId);
        if (mid >= 0 && mid < seen.length) seen[mid]++;
      }
    });
    // Player hands
    const players = gd.players;
    const playerHands = {};
    for (const [pid, p] of Object.entries(players)) {
      playerHands[p.no] = { name: p.name, color: p.color, cards: [], pid };
    }
    gd.board.cards.forEach(c => {
      if ((c.location === 'player' || c.location === 'wait') && c.materialId !== null) {
        const no = String(c.locationId);
        if (playerHands[no]) {
          playerHands[no].cards.push(parseInt(c.materialId));
        }
      }
    });
    // EV
    const ev = computeEV(gd);
    // --- RENDER ---
    const wrap = document.createElement('div');
    wrap.id = 'flip7-tracker';
    wrap.style.cssText = 'position:fixed;top:80px;right:10px;z-index:99999;width:340px;' +
      'background:linear-gradient(135deg,#1a1a2e,#16213e);color:#eee;border-radius:12px;' +
      'box-shadow:0 4px 24px rgba(0,0,0,.5);font-family:system-ui,sans-serif;font-size:13px;' +
      'user-select:none;overflow:hidden;';
    // Header
    const hdr = document.createElement('div');
    hdr.style.cssText = 'display:flex;align-items:center;justify-content:space-between;padding:8px 12px;' +
      'background:linear-gradient(90deg,#c0392b,#8e44ad);cursor:move;';
    hdr.innerHTML = '<span style="font-weight:700;font-size:15px;">\\u{1F0CF} Flip 7 Tracker + EV</span>' +
      '<span>' +
      '<button id="f7-sync" style="background:rgba(255,255,255,.2);border:none;color:#fff;padding:3px 8px;border-radius:4px;cursor:pointer;margin-right:4px;">\\u27F3 Sync</button>' +
      '<button id="f7-min" style="background:rgba(255,255,255,.2);border:none;color:#fff;padding:3px 8px;border-radius:4px;cursor:pointer;">\\u2212</button>' +
      '</span>';
    wrap.appendChild(hdr);
    // Body
    const body = document.createElement('div');
    body.id = 'f7-body';
    body.style.cssText = 'padding:10px 12px;max-height:70vh;overflow-y:auto;';
    // Stats bar
    const knownOutCount = gd.board.cards.filter(c => c.location !== 'deck' && c.materialId !== null && c.materialId !== '').length;
    const statsHtml = '<div style="display:flex;justify-content:space-around;margin-bottom:10px;padding:6px;' +
      'background:rgba(255,255,255,.07);border-radius:8px;">' +
      '<div style="text-align:center;"><div style="font-size:18px;font-weight:700;color:#3498db;">' + domDeckCount + '</div><div style="font-size:10px;opacity:.7;">In Deck</div></div>' +
      '<div style="text-align:center;"><div style="font-size:18px;font-weight:700;color:#e67e22;">' + knownOutCount + '</div><div style="font-size:10px;opacity:.7;">Seen</div></div>' +
      '<div style="text-align:center;"><div style="font-size:18px;font-weight:700;color:#e74c3c;">' + (ev ? ev.bustPct : '?') + '%</div><div style="font-size:10px;opacity:.7;">My Bust</div></div>' +
      '</div>';
    body.innerHTML = statsHtml;
    // Number card grid
    let gridHtml = '<div style="margin-bottom:10px;"><div style="font-size:11px;opacity:.6;margin-bottom:4px;">Number Cards (remaining / total)</div>' +
      '<div style="display:grid;grid-template-columns:repeat(5,1fr);gap:3px;">';
    for (let i = 0; i <= 12; i++) {
      const total = MATERIALS[i].count;
      const out = seen[i];
      const rem = total - out;
      const pct = total > 0 ? rem / total : 0;
      const bg = pct <= 0 ? '#555' : pct < 0.3 ? '#c0392b' : pct < 0.6 ? '#e67e22' : '#27ae60';
      gridHtml += '<div style="text-align:center;padding:4px 2px;background:' + bg + ';border-radius:4px;">' +
        '<div style="font-weight:700;">' + i + '</div>' +
        '<div style="font-size:10px;">' + rem + '/' + total + '</div></div>';
    }
    gridHtml += '</div></div>';
    body.innerHTML += gridHtml;
    // Action cards
    let actHtml = '<div style="margin-bottom:10px;"><div style="font-size:11px;opacity:.6;margin-bottom:4px;">Action / Modifier Cards</div>' +
      '<div style="display:flex;flex-wrap:wrap;gap:3px;">';
    for (let i = 13; i < MATERIALS.length; i++) {
      const m = MATERIALS[i];
      const total = m.count;
      const out = seen[i];
      const rem = total - out;
      const bg = rem <= 0 ? '#555' : '#2c3e50';
      actHtml += '<div style="text-align:center;padding:4px 6px;background:' + bg + ';border-radius:4px;min-width:40px;">' +
        '<div style="font-weight:700;font-size:11px;">' + m.action + '</div>' +
        '<div style="font-size:10px;">' + rem + '/' + total + '</div></div>';
    }
    actHtml += '</div></div>';
    body.innerHTML += actHtml;
    // EV Panel
    if (ev) {
      const recColor = ev.rec === 'HIT' ? '#27ae60' : '#e74c3c';
      const confLabel = ev.conf === 'Strong' ? '\\u{1F4AA}' : ev.conf === 'Lean' ? '\\u{1F914}' : '\\u26A0\\uFE0F';
      let evHtml = '<div style="margin-bottom:10px;padding:8px;background:rgba(255,255,255,.07);border-radius:8px;border-left:4px solid ' + recColor + ';">' +
        '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:4px;">' +
        '<span style="font-weight:700;font-size:15px;color:' + recColor + ';">' + confLabel + ' ' + ev.rec + '</span>' +
        '<span style="font-size:11px;opacity:.7;">' + ev.conf + ' (\\u0394 ' + (ev.delta > 0 ? '+' : '') + ev.delta + ')</span></div>' +
        '<div style="display:flex;justify-content:space-around;font-size:11px;">' +
        '<div>Stay: <b>' + ev.currentScore + ' pts</b></div>' +
        '<div>EV Hit: <b>' + ev.evHit + ' pts</b></div>' +
        '<div>Safe: <b>' + ev.safePct + '%</b></div></div></div>';
      body.innerHTML += evHtml;
    }
    // Player hands
    let phHtml = '<div><div style="font-size:11px;opacity:.6;margin-bottom:4px;">Player Hands</div>';
    const myId = String(window.gameui.player_id);
    const sortedPlayers = Object.values(playerHands).sort((a, b) => (a.pid === myId ? -1 : b.pid === myId ? 1 : 0));
    for (const ph of sortedPlayers) {
      const isMe = ph.pid === myId;
      const border = isMe ? 'border:1px solid #f39c12;' : '';
      const nums = [];
      const modLabels = [];
      ph.cards.forEach(mid => {
        const m = MATERIALS[mid];
        if (m.value !== null) nums.push(m.value);
        else modLabels.push(m.action);
      });
      const s = scoreHand(nums, modLabels);
      const uniqueNums = new Set(nums);
      const dupeCount = nums.length - uniqueNums.size;
      phHtml += '<div style="padding:6px;margin-bottom:4px;background:rgba(255,255,255,.05);border-radius:6px;' + border + '">' +
        '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:2px;">' +
        '<span style="font-weight:600;color:#' + ph.color + ';">' + (isMe ? '\\u2B50 ' : '') + ph.name + '</span>' +
        '<span style="font-weight:700;">' + s + ' pts</span></div>' +
        '<div style="display:flex;flex-wrap:wrap;gap:2px;">';
      ph.cards.sort((a, b) => {
        const ma = MATERIALS[a], mb = MATERIALS[b];
        if (ma.value !== null && mb.value !== null) return ma.value - mb.value;
        if (ma.value !== null) return -1;
        if (mb.value !== null) return 1;
        return 0;
      });
      ph.cards.forEach(mid => {
        const m = MATERIALS[mid];
        let label, bg;
        if (m.value !== null) {
          label = String(m.value);
          const isDupe = nums.filter(n => n === m.value).length > 1;
          bg = isDupe ? '#c0392b' : '#2980b9';
        } else {
          label = m.action;
          bg = '#8e44ad';
        }
        phHtml += '<span style="padding:2px 6px;background:' + bg + ';border-radius:3px;font-size:11px;font-weight:600;">' + label + '</span>';
      });
      phHtml += '</div></div>';
    }
    phHtml += '</div>';
    body.innerHTML += phHtml;
    wrap.appendChild(body);
    document.body.appendChild(wrap);
    // --- DRAG ---
    let dragging = false, dx = 0, dy = 0;
    hdr.addEventListener('mousedown', e => {
      dragging = true;
      dx = e.clientX - wrap.getBoundingClientRect().left;
      dy = e.clientY - wrap.getBoundingClientRect().top;
    });
    document.addEventListener('mousemove', e => {
      if (!dragging) return;
      wrap.style.left = (e.clientX - dx) + 'px';
      wrap.style.top = (e.clientY - dy) + 'px';
      wrap.style.right = 'auto';
    });
    document.addEventListener('mouseup', () => { dragging = false; });
    // Minimize
    document.getElementById('f7-min').addEventListener('click', () => {
      const b = document.getElementById('f7-body');
      b.style.display = b.style.display === 'none' ? 'block' : 'none';
    });
    // Sync button
    document.getElementById('f7-sync').addEventListener('click', () => { buildTracker(); });
  }
  // --- NOTIFICATION INTERCEPTOR ---
  function installInterceptor() {
    if (window._flip7_interceptorInstalled) return;
    const nq = window.gameui && window.gameui.notifqueue;
    if (!nq) return;
    const origOnNotif = nq.onNotification.bind(nq);
    nq.onNotification = function (packet) {
      try {
        if (packet && packet.data && Array.isArray(packet.data)) {
          const gd = window.gameui.gamedatas;
          packet.data.forEach(evt => {
            if (evt.type === 'moveTokens' && evt.args && evt.args.tokens) {
              evt.args.tokens.forEach(tok => {
                const card = gd.board.cards.find(c => String(c.id) === String(tok.id));
                if (card) {
                  card.location = tok.location || card.location;
                  card.locationId = tok.locationId !== undefined ? tok.locationId : card.locationId;
                  if (tok.materialId !== undefined) card.materialId = tok.materialId;
                  if (tok.visible !== undefined) card.visible = tok.visible;
                }
              });
            }
            if (evt.type === 'gameStateChange' && evt.args && evt.args.name === 'STATE_NEXT_ROUND') {
              resetDeckForNewRound(gd);
            }
          });
        }
      } catch (e) {
        console.error('[Flip7 Tracker] interceptor error:', e);
      }
      origOnNotif(packet);
      clearTimeout(window._flip7_refreshTimer);
      window._flip7_refreshTimer = setTimeout(buildTracker, 80);
    };
    window._flip7_interceptorInstalled = true;
  }
  // --- DOM DECK OBSERVER ---
  // Watch .f7_deck for changes to auto-refresh the tracker
  function installDeckObserver() {
    if (window._flip7_deckObserver) return;
    const deckEl = document.querySelector('.f7_deck');
    if (!deckEl) return;
    window._flip7_deckObserver = new MutationObserver(() => {
      clearTimeout(window._flip7_deckRefreshTimer);
      window._flip7_deckRefreshTimer = setTimeout(buildTracker, 100);
    });
    window._flip7_deckObserver.observe(deckEl, { childList: true, characterData: true, subtree: true });
  }
  // --- INIT ---
  function waitForGame() {
    const check = setInterval(() => {
      if (window.gameui && window.gameui.gamedatas && window.gameui.gamedatas.board &&
          document.querySelector('.f7_deck')) {
        clearInterval(check);
        // Fix stale state on inject: reconcile immediately
        reconcileDeck(window.gameui.gamedatas);
        installInterceptor();
        installDeckObserver();
        buildTracker();
        console.log('[Flip7 Tracker] Initialized.');
      }
    }, 600);
  }
  waitForGame();
})();
