// ==UserScript==
// @name         Project-iMAS Wiki Japanese Lyrics Extractor
// @namespace    https://project-imas.wiki/
// @version      3.0
// @updateURL    https://raw.githubusercontent.com/lehmacdj/.dotfiles/main/tampermonkey/project-imas-wiki-japanese-lyrics-extractor.user.js
// @downloadURL  https://raw.githubusercontent.com/lehmacdj/.dotfiles/main/tampermonkey/project-imas-wiki-japanese-lyrics-extractor.user.js
// @description  Extracts Japanese/Kanji lyrics (full or short version) from song pages on project-imas.wiki
// @match        https://project-imas.wiki/*
// @grant        GM_setClipboard
// @run-at       document-end
// ==/UserScript==

(function () {
    'use strict';

    const THEME_PINK = '#ff8fb1';
    const THEME_PINK_DARK = '#e56a93';

    /** Find the index of the Japanese/Kanji column in a lyrics table. */
    function findJapaneseColumnIndex(table) {
        const headerRow = table.querySelector('tr');
        if (!headerRow) return -1;
        const headers = headerRow.querySelectorAll('th');
        for (let i = 0; i < headers.length; i++) {
            const t = headers[i].textContent.trim().toLowerCase();
            if (t.includes('japanese') || t.includes('kanji')) return i;
        }
        return -1;
    }

    /** Extract plain text from a cell, preserving single line breaks from <br>. */
    function extractCellText(cell) {
        const clone = cell.cloneNode(true);
        // Convert <br> to a newline, swallowing any whitespace immediately after
        // it so that "<br>\n" in the source doesn't become a double newline.
        clone.querySelectorAll('br').forEach(br => {
            // Remove a leading whitespace-only text node after the <br>
            const next = br.nextSibling;
            if (next && next.nodeType === Node.TEXT_NODE) {
                next.textContent = next.textContent.replace(/^[ \t\r\n]+/, '');
            }
            br.replaceWith('\n');
        });
        // Treat each <p> as a single stanza unit (no forced break inside it).
        return clone.textContent
            .replace(/\u00a0/g, ' ')
            .replace(/[ \t]+\n/g, '\n')     // trim trailing spaces before newlines
            .replace(/\n[ \t]+/g, '\n')     // trim leading spaces after newlines
            .replace(/\n{2,}/g, '\n')       // collapse runs of blank lines within a cell
            .trim();
    }
    /**
     * Classify a row by its class attribute.
     *   unclassed rows -> 'fullOnly'  (long-version-only content)
     *   tr.master      -> 'shared'    (core song, appears in both versions)
     *   tr.short       -> 'shortOnly' (short-version-only content)
     *
     * Rationale: the wiki marks the short arrangement with .master (shared core)
     * and .short (short-only inserts). Plain rows are content that exists only
     * in the full version.
     */
    function classifyRow(row) {
        if (row.classList.contains('short')) return 'shortOnly';
        if (row.classList.contains('master')) return 'shared';
        return 'fullOnly';
    }
    /** Extract the Japanese lyrics for a given version ('full' or 'short'). */
    function extractJapaneseLyrics(version) {
        const tables = document.querySelectorAll('table.lyrics');
        const stanzas = [];

        tables.forEach(table => {
            const jpIndex = findJapaneseColumnIndex(table);
            if (jpIndex === -1) return;

            const rows = table.querySelectorAll('tr');
            rows.forEach((row, rowIdx) => {
                if (rowIdx === 0) return; // skip header
                const cells = row.querySelectorAll('td');
                if (cells.length <= jpIndex) return;

                const cls = classifyRow(row);
                const include =
                    cls === 'shared' ||
                    (version === 'full'  && cls === 'fullOnly') ||
                    (version === 'short' && cls === 'shortOnly');
                if (!include) return;

                const text = extractCellText(cells[jpIndex]);
                if (text) stanzas.push(text);
            });
        });

        return stanzas.join('\n\n');
    }

    /** Copy text to clipboard with graceful fallback. */
    function copyToClipboard(text) {
        try {
            if (typeof GM_setClipboard === 'function') {
                GM_setClipboard(text, 'text');
                return true;
            }
            if (navigator.clipboard) {
                navigator.clipboard.writeText(text);
                return true;
            }
        } catch (e) {
            console.warn('Clipboard copy failed:', e);
        }
        return false;
    }

    /** Small temporary toast near a given element. */
    function showToast(anchor, message) {
        const toast = document.createElement('div');
        toast.textContent = message;
        Object.assign(toast.style, {
            position: 'absolute',
            background: '#333',
            color: '#fff',
            padding: '4px 8px',
            borderRadius: '4px',
            fontSize: '12px',
            fontFamily: 'sans-serif',
            zIndex: 999999,
            pointerEvents: 'none',
            opacity: '0',
            transition: 'opacity 0.15s ease'
        });
        document.body.appendChild(toast);

        const rect = anchor.getBoundingClientRect();
        toast.style.left = (window.scrollX + rect.left + rect.width / 2 - toast.offsetWidth / 2) + 'px';
        toast.style.top  = (window.scrollY + rect.top  - toast.offsetHeight - 6) + 'px';
        requestAnimationFrame(() => { toast.style.opacity = '1'; });

        setTimeout(() => {
            toast.style.opacity = '0';
            setTimeout(() => toast.remove(), 200);
        }, 1200);
    }

    /** Does the given table contain any rows marked as short-version-only?
     * A short-version button is only meaningful when the full and short versions
     * would actually differ — i.e., there's at least one unclassed row (full-only
     * content) or at least one .short row (short-only content). A table made up
     * entirely of .master rows has no distinction between the two versions.
     */
    function tableHasShortVersion(table) {
        const rows = table.querySelectorAll('tr');
        for (let i = 1; i < rows.length; i++) { // skip header
            const row = rows[i];
            if (row.classList.contains('short')) return true;
            if (!row.classList.contains('master')) return true; // unclassed = full-only
        }
        return false;
    }

    /** Build the Full + Short button control. */
    function buildButton(table) {
        const hasShort = tableHasShortVersion(table);

        const wrapper = document.createElement('div');
        Object.assign(wrapper.style, {
            display: 'inline-flex',
            flexDirection: 'column',
            alignItems: 'stretch',
            gap: '4px',
            fontFamily: 'sans-serif'
        });

        const baseBtnStyle = {
            background: THEME_PINK,
            color: '#fff',
            border: 'none',
            borderRadius: '6px',
            padding: '8px 12px',
            fontSize: '13px',
            fontWeight: 'bold',
            cursor: 'pointer',
            boxShadow: '0 1px 3px rgba(0,0,0,0.15)',
            whiteSpace: 'nowrap',
            transition: 'background 0.15s ease, opacity 0.15s ease'
        };

        const fullBtn = document.createElement('button');
        fullBtn.type = 'button';
        fullBtn.textContent = '📋 Copy JP Lyrics';
        fullBtn.title = hasShort
            ? 'Copy full-version Japanese lyrics'
            : 'Copy Japanese lyrics';
        Object.assign(fullBtn.style, baseBtnStyle);

        fullBtn.addEventListener('mouseenter', () => {
            fullBtn.style.background = THEME_PINK_DARK;
        });
        fullBtn.addEventListener('mouseleave', () => {
            fullBtn.style.background = THEME_PINK;
        });
        fullBtn.addEventListener('click', () => {
            const text = extractJapaneseLyrics('full');
            if (!text) { showToast(fullBtn, 'No lyrics found'); return; }
            const ok = copyToClipboard(text);
            showToast(fullBtn, ok ? '✓ Full version copied' : 'Copy failed');
        });

        wrapper.appendChild(fullBtn);

        // Only add the short-version button if this song actually has a short version.
        if (hasShort) {
            const shortBtn = document.createElement('button');
            shortBtn.type = 'button';
            shortBtn.textContent = '📋 Short ver.';
            shortBtn.title = 'Copy short-version Japanese lyrics';
            Object.assign(shortBtn.style, baseBtnStyle, {
                background: '#fff',
                color: THEME_PINK_DARK,
                border: `1px solid ${THEME_PINK}`,
                fontSize: '12px',
                padding: '5px 10px',
                opacity: '0',
                pointerEvents: 'none'
            });

            const reveal = () => {
                shortBtn.style.opacity = '1';
                shortBtn.style.pointerEvents = 'auto';
            };
            const hide = () => {
                shortBtn.style.opacity = '0';
                shortBtn.style.pointerEvents = 'none';
            };
            wrapper.addEventListener('mouseenter', reveal);
            wrapper.addEventListener('mouseleave', hide);
            wrapper.addEventListener('focusin', reveal);
            wrapper.addEventListener('focusout', (e) => {
                if (!wrapper.contains(e.relatedTarget)) hide();
            });

            shortBtn.addEventListener('mouseenter', () => {
                shortBtn.style.background = THEME_PINK;
                shortBtn.style.color = '#fff';
            });
            shortBtn.addEventListener('mouseleave', () => {
                shortBtn.style.background = '#fff';
                shortBtn.style.color = THEME_PINK_DARK;
            });
            shortBtn.addEventListener('click', () => {
                const text = extractJapaneseLyrics('short');
                if (!text) { showToast(shortBtn, 'No short version'); return; }
                const ok = copyToClipboard(text);
                showToast(shortBtn, ok ? '✓ Short version copied' : 'Copy failed');
            });

            wrapper.appendChild(shortBtn);
        }

        return wrapper;
    }

    /** Float the button(s) to the left of the lyrics table without taking up layout space. */
    function mountButton() {
        const tables = document.querySelectorAll('table.lyrics');
        for (const table of tables) {
            if (findJapaneseColumnIndex(table) === -1) continue;

            // Ensure the table's parent is a positioning context so we can
            // absolutely position the button relative to it.
            const parent = table.parentElement;
            const parentPos = getComputedStyle(parent).position;
            if (parentPos === 'static') {
                parent.style.position = 'relative';
            }

            const floater = document.createElement('div');
            Object.assign(floater.style, {
                position: 'absolute',
                top: table.offsetTop + 'px',
                left: '0',
                transform: 'translateX(calc(-100% - 8px))',
                zIndex: '100',
                pointerEvents: 'auto'
            });
            floater.appendChild(buildButton(table));

            parent.appendChild(floater);

            // Keep the button vertically aligned with the table if layout shifts
            // (e.g. images loading). Recompute on resize and after full load.
            const sync = () => { floater.style.top = table.offsetTop + 'px'; };
            window.addEventListener('resize', sync);
            window.addEventListener('load', sync);

            return; // only mount once
        }
    }

    mountButton();
})();
