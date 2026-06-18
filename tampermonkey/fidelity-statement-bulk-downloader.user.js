// ==UserScript==
// @name         Fidelity Statement Bulk Downloader
// @namespace    http://tampermonkey.net/
// @version      3.2
// @updateURL    https://raw.githubusercontent.com/lehmacdj/.dotfiles/main/tampermonkey/fidelity-statement-bulk-downloader.user.js
// @downloadURL  https://raw.githubusercontent.com/lehmacdj/.dotfiles/main/tampermonkey/fidelity-statement-bulk-downloader.user.js
// @description  Bulk download Fidelity statements with proper naming
// @match        https://digital.fidelity.com/ftgw/digital/portfolio/documents*
// @grant        GM_download
// @grant        GM_setValue
// @grant        GM_getValue
// @grant        unsafeWindow
// @connect      digital.fidelity.com
// @connect      fidelity.com
// @run-at       document-idle
// ==/UserScript==
//
// published: https://gist.github.com/lehmacdj/5de59f2f29fbef322b6cf47122660ba4
// js Console filter for Firefox console:
// ```
// -/(Storage access automatically granted for origin “resource://pdf.js” on “resource://pdf.js”. |provided to “https://digital.fidelity.com|storage access was provided to “https://dpm.demdex.net|Datadog Browser SDK|servicemessages.fidelity.com|Script "ensighten"|downloadable font|Source map error|WEBGL_debug_renderer_info|LaunchDarkly|OpaqueResponseBlocking|Property "(pvdReadonlyShowCheckbox|pvdChecked|pvdCheckboxReadonlyLabel|pvdCheckboxLabel|pvdLinkageName)")/
// ```

(function () {
  "use strict";

  const CONFIG = {
    // Timing (ms)
    delayBetweenDownloads: 3000,
    delayAfterLoadMore: 2000,
    delayAfterYearChange: 2500,
    delayForMenu: 400,
    delayForNewTab: 1500,
  };

  let stopDownload = false;
  let downloadedFiles = new Set();
  let totalDownloaded = 0;
  let totalSkipped = 0;

  const DOCUMENTS_URL =
    "https://digital.fidelity.com/ftgw/digital/portfolio/documents";

  // Check if we're on a PDF page
  function isPdfPage() {
    return window.location.href.includes("/PDFStatement/");
  }

  // Handle PDF page - download and navigate back
  async function handlePdfPage() {
    const pdfUrl = window.location.href;
    console.log("[FidelityDL] On PDF page:", pdfUrl);

    // Get the pending download info from storage
    const pendingDownload = await GM_getValue("pendingDownload", null);

    if (pendingDownload) {
      console.log("[FidelityDL] Found pending download:", pendingDownload);

      // Download the PDF with the correct filename
      try {
        GM_download({
          url: pdfUrl,
          name: pendingDownload.filename,
          saveAs: false,
          onload: () => {
            console.log(
              "[FidelityDL] PDF downloaded successfully:",
              pendingDownload.filename
            );
          },
          onerror: (err) => {
            console.error("[FidelityDL] PDF download error:", err);
          },
        });
      } catch (e) {
        console.error("[FidelityDL] GM_download exception:", e);
      }

      // Mark this file as downloaded
      const downloadedSet = await GM_getValue("downloadedFiles", []);
      downloadedSet.push(pendingDownload.filename);
      await GM_setValue("downloadedFiles", downloadedSet);

      // Clear the pending download
      await GM_setValue("pendingDownload", null);

      // Small delay to let download start, then navigate back
      await new Promise((r) => setTimeout(r, 1000));
      console.log("[FidelityDL] Navigating back to documents page...");
      window.location.href = DOCUMENTS_URL;
    } else {
      console.log(
        "[FidelityDL] No pending download found, this might be a manual navigation"
      );
    }
  }

  // Save state before navigating to PDF
  async function saveDownloadState(filename, yearIndex, rowIndex, years) {
    await GM_setValue("pendingDownload", { filename });
    await GM_setValue("resumeState", { yearIndex, rowIndex, years });
    console.log("[FidelityDL] Saved state:", { filename, yearIndex, rowIndex });
  }

  // Get resume state
  async function getResumeState() {
    return await GM_getValue("resumeState", null);
  }

  // Clear resume state
  async function clearResumeState() {
    await GM_setValue("resumeState", null);
    await GM_setValue("pendingDownload", null);
  }

  // Restore downloaded files set from storage
  async function restoreDownloadedFiles() {
    const stored = await GM_getValue("downloadedFiles", []);
    stored.forEach((f) => downloadedFiles.add(f));
    console.log(
      "[FidelityDL] Restored",
      stored.length,
      "downloaded files from storage"
    );
  }

  // Storage for document data from GraphQL API
  let documentData = [];

  // Inject XHR/Fetch interceptor to capture GraphQL responses
  function injectApiInterceptor() {
    const script = document.createElement("script");
    script.textContent = `
      (function() {
        if (window._fidelityDLApiInterceptorActive) return;
        window._fidelityDLApiInterceptorActive = true;
        window._fidelityDLDocuments = [];

        const origFetch = window.fetch;
        window.fetch = async function(url, options) {
          const response = await origFetch.apply(this, arguments);

          try {
            const urlStr = String(url);
            if (urlStr.includes('/api/graphql') && options?.body) {
              const body = typeof options.body === 'string' ? options.body : '';
              if (body.includes('GetStatements') || body.includes('getStatement')) {
                const clone = response.clone();
                const data = await clone.json();

                if (data?.data?.getStatement?.statement?.docDetails?.docDetail) {
                  const docs = data.data.getStatement.statement.docDetails.docDetail;
                  console.log("[FidelityDL-API] Captured", docs.length, "documents from GraphQL");
                  window._fidelityDLDocuments = window._fidelityDLDocuments.concat(docs);
                  window.dispatchEvent(new CustomEvent("FidelityDL_DocumentsLoaded", {
                    detail: docs
                  }));
                }
              }
            }
          } catch(e) {
            console.log("[FidelityDL-API] Error parsing response:", e);
          }

          return response;
        };

        console.log("[FidelityDL-API] GraphQL interceptor installed");
      })();
    `;
    document.documentElement.appendChild(script);
    script.remove();
  }

  // Listen for document data from the interceptor
  window.addEventListener("FidelityDL_DocumentsLoaded", (e) => {
    const docs = e.detail;
    console.log("[FidelityDL] Received", docs.length, "documents from API");
    documentData = documentData.concat(docs);

    // Update the document count display
    const countEl = document.getElementById("dl-doc-count");
    if (countEl) {
      countEl.textContent = `Documents captured: ${documentData.length}`;
    }
  });

  // Construct PDF URL from document data
  function constructPdfUrl(doc) {
    console.log("[FidelityDL] Constructing URL for doc:", doc);

    // Handle different date formats - can be numeric like 9302018 or string like "2025-11-28"
    let endDate = doc.periodEndDate || doc.generatedDate;
    if (!endDate) {
      console.error("[FidelityDL] No date found in doc:", doc);
      return null;
    }

    // Convert to string
    let dateStr = String(endDate);

    // Parse date - could be numeric MMDDYYYY (9302018) or string "2025-11-28"
    let mmddyyyy;
    if (dateStr.includes("-")) {
      const dateParts = dateStr.split("-");
      mmddyyyy = dateParts[1] + dateParts[2] + dateParts[0]; // MMDDYYYY
    } else {
      // Already in MMDDYYYY format (or close to it)
      mmddyyyy = dateStr;
    }

    // The ID from API is ALREADY base64 encoded - don't double-encode!
    const encodedId = doc.id;

    const url = `https://digital.fidelity.com/ftgw/digital/documents/PDFStatement/STMT/pdf/Statement${mmddyyyy}.pdf?id=${encodedId}`;
    console.log("[FidelityDL] Constructed URL:", url);
    return url;
  }

  // Install the API interceptor immediately
  injectApiInterceptor();

  // Download a document directly using API data (no navigation needed!)
  async function downloadDocumentDirect(doc) {
    const pdfUrl = constructPdfUrl(doc);
    if (!pdfUrl) {
      console.error("[FidelityDL] Could not construct URL for doc:", doc);
      return { downloaded: false, skipped: true };
    }

    const filename = generateFilenameFromDoc(doc);

    if (downloadedFiles.has(filename)) {
      console.log("[FidelityDL] Already downloaded:", filename);
      return { downloaded: false, skipped: true };
    }

    console.log("[FidelityDL] Downloading directly:", filename, "from", pdfUrl);
    updateStatus(`Downloading: ${filename}`);

    try {
      await downloadWithFilename(pdfUrl, filename);
      downloadedFiles.add(filename);

      // Persist to storage
      const stored = await GM_getValue("downloadedFiles", []);
      stored.push(filename);
      await GM_setValue("downloadedFiles", stored);

      return { downloaded: true, skipped: false };
    } catch (e) {
      console.error("[FidelityDL] Download failed:", e);
      return { downloaded: false, skipped: true };
    }
  }

  // Parse date from API format (numeric MMDDYYYY or string YYYY-MM-DD)
  function parseApiDate(dateVal) {
    if (!dateVal) return { year: "unknown", month: "00", day: "00" };

    let dateStr = String(dateVal);

    if (dateStr.includes("-")) {
      // Format: YYYY-MM-DD
      const parts = dateStr.split("-");
      return { year: parts[0], month: parts[1], day: parts[2] || "00" };
    } else if (dateStr.length >= 7) {
      // Numeric format: MMDDYYYY (e.g., 9302018 or 11302025)
      if (dateStr.length === 7) {
        // Single digit month: MDDYYYY
        return {
          year: dateStr.slice(3, 7),
          month: dateStr.slice(0, 1).padStart(2, "0"),
          day: dateStr.slice(1, 3)
        };
      } else {
        // Double digit month: MMDDYYYY
        return {
          year: dateStr.slice(4, 8),
          month: dateStr.slice(0, 2),
          day: dateStr.slice(2, 4)
        };
      }
    }

    return { year: "unknown", month: "00", day: "00" };
  }

  // Generate filename from document API data
  // Format: FidelityStatement_(account-number)_(start-date)_(end-date).pdf
  // Note: doc.householdNum is also available in the API data if needed
  function generateFilenameFromDoc(doc) {
    const acctNum = doc.acctNum || "unknown";

    const startDate = parseApiDate(doc.periodStartDate);
    const endDate = parseApiDate(doc.periodEndDate || doc.generatedDate);

    const startStr = `${startDate.year}-${startDate.month}-${startDate.day}`;
    const endStr = `${endDate.year}-${endDate.month}-${endDate.day}`;

    return `FidelityStatement_${acctNum}_${startStr}_${endStr}.pdf`;
  }

  // Capture documents from all years by switching through each year
  async function captureAllYears() {
    stopDownload = false;
    updateStatus("Capturing documents from all years...");

    await openYearDropdown();
    await sleep(300);

    const years = getAvailableYears();
    document.body.click();
    await sleep(200);

    if (years.length === 0) {
      updateStatus("No years found!");
      return;
    }

    updateStatus(`Found ${years.length} years. Capturing...`);

    for (let i = 0; i < years.length; i++) {
      if (stopDownload) break;

      const yearInfo = years[i];
      updateStatus(`Capturing year ${yearInfo.year} (${i + 1}/${years.length})...`);

      await selectYear(yearInfo);
      await sleep(CONFIG.delayAfterYearChange);

      // Load all statements for this year (triggers API calls)
      await loadAllStatements();
      await sleep(500);
    }

    updateStatus(`Capture complete! ${documentData.length} documents ready.`);
  }

  // Clear captured documents
  function clearCapturedDocuments() {
    documentData = [];
    const countEl = document.getElementById("dl-doc-count");
    if (countEl) {
      countEl.textContent = "Documents captured: 0";
    }
    updateStatus("Captured documents cleared.");
  }

  // Check if a document should be skipped based on filters
  function shouldSkipDoc(doc) {
    const docType = doc.type || "";

    // Only download "PI Monthly/Quarterly Statement" type
    if (docType !== "PI Monthly/Quarterly Statement") {
      return true;
    }

    return false;
  }

  // Download all documents using API data directly
  async function downloadAllDirect() {
    if (documentData.length === 0) {
      updateStatus("No documents captured. Click 'Capture All Years' first.");
      return;
    }

    stopDownload = false;

    // Filter documents based on user preferences
    const docsToDownload = documentData.filter(doc => !shouldSkipDoc(doc));
    const skippedByFilter = documentData.length - docsToDownload.length;

    updateStatus(`Downloading ${docsToDownload.length} documents (${skippedByFilter} filtered out)...`);

    for (let i = 0; i < docsToDownload.length; i++) {
      if (stopDownload) break;

      const doc = docsToDownload[i];
      updateStatus(`Downloading ${i + 1}/${docsToDownload.length}: ${doc.periodEndDate}`);

      const result = await downloadDocumentDirect(doc);

      if (result.downloaded) {
        totalDownloaded++;
      } else if (result.skipped) {
        totalSkipped++;
      }
      updateProgress();

      // Small delay between downloads
      await sleep(500);
    }

    updateStatus(stopDownload ? "Stopped by user" : `Complete! Downloaded ${totalDownloaded} files.`);
  }

  function addControlPanel() {
    const panel = document.createElement("div");
    panel.id = "fidelity-bulk-dl";
    panel.style.cssText = `
            position: fixed;
            top: 10px;
            right: 10px;
            background: #368727;
            color: white;
            padding: 15px;
            border-radius: 8px;
            z-index: 999999;
            font-family: "Fidelity Sans", sans-serif;
            box-shadow: 0 4px 12px rgba(0,0,0,0.3);
            min-width: 280px;
            max-width: 350px;
        `;
    panel.innerHTML = `
            <div style="font-weight: bold; margin-bottom: 10px; font-size: 14px;">📄 Statement Bulk Downloader</div>
            <div id="dl-status" style="margin-bottom: 10px; font-size: 12px; min-height: 40px; line-height: 1.4;">
                Ready. Click "Capture All Years" first, then "Download All".
            </div>
            <div id="dl-progress" style="margin-bottom: 10px; font-size: 11px; color: #cfc;"></div>
            <div style="margin-bottom: 8px;">
                <button id="dl-capture" style="padding: 8px 12px; cursor: pointer; background: white; color: #368727; border: none; border-radius: 4px; font-weight: bold;">
                    1. Capture All Years
                </button>
            </div>
            <div id="dl-doc-count" style="margin-bottom: 8px; font-size: 11px; color: #cfc;">
                Documents captured: 0
            </div>
            <div style="margin-bottom: 8px;">
                <button id="dl-direct" style="padding: 8px 12px; cursor: pointer; background: white; color: #368727; border: none; border-radius: 4px; font-weight: bold;">
                    2. Download All
                </button>
                <button id="dl-clear-captured" style="padding: 8px 12px; cursor: pointer; background: #666; color: white; border: none; border-radius: 4px; margin-left: 5px;">
                    Clear
                </button>
            </div>
            <div style="margin-top: 8px;">
                <button id="dl-stop" style="padding: 6px 12px; cursor: pointer; background: #c33; color: white; border: none; border-radius: 4px;">
                    Stop
                </button>
                <button id="dl-reset" style="padding: 6px 12px; cursor: pointer; background: #666; color: white; border: none; border-radius: 4px; margin-left: 5px;">
                    Reset Counter
                </button>
            </div>
            <div style="margin-top: 10px; font-size: 10px; opacity: 0.8;">
                PDFs download with proper filenames.
            </div>
        `;
    document.body.appendChild(panel);

    document
      .getElementById("dl-capture")
      .addEventListener("click", captureAllYears);
    document
      .getElementById("dl-direct")
      .addEventListener("click", downloadAllDirect);
    document
      .getElementById("dl-clear-captured")
      .addEventListener("click", clearCapturedDocuments);
    document.getElementById("dl-stop").addEventListener("click", () => {
      stopDownload = true;
      updateStatus("Stopping...");
    });
    document.getElementById("dl-reset").addEventListener("click", async () => {
      downloadedFiles.clear();
      totalDownloaded = 0;
      totalSkipped = 0;
      await clearResumeState();
      await GM_setValue("downloadedFiles", []);
      updateProgress();
      updateStatus("All state cleared.");
    });
  }

  function updateStatus(msg) {
    const el = document.getElementById("dl-status");
    if (el) el.textContent = msg;
    console.log("[FidelityDL]", msg);
  }

  function updateProgress() {
    const el = document.getElementById("dl-progress");
    if (el)
      el.textContent = `Downloaded: ${totalDownloaded} | Skipped: ${totalSkipped}`;
  }

  function sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  // Download a file from URL with a specific filename using Tampermonkey's API
  function downloadWithFilename(url, filename) {
    console.log("[FidelityDL] Starting GM_download:", { url, filename });
    return new Promise((resolve, reject) => {
      const downloadHandle = GM_download({
        url: url,
        name: filename,
        saveAs: false,
        onload: () => {
          console.log("[FidelityDL] Download complete:", filename);
          resolve();
        },
        onerror: (err) => {
          console.error("[FidelityDL] Download error:", err);
          console.error("[FidelityDL] Error details:", JSON.stringify(err));
          reject(err);
        },
        onprogress: (progress) => {
          console.log("[FidelityDL] Download progress:", progress);
        },
        ontimeout: () => {
          console.error("[FidelityDL] Download timeout");
          reject(new Error("Download timeout"));
        },
      });
      console.log("[FidelityDL] GM_download returned:", downloadHandle);
    });
  }

  // Test function to verify GM_download works
  function testDownload() {
    const testUrl =
      "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf";
    console.log("[FidelityDL] Testing GM_download with:", testUrl);
    downloadWithFilename(testUrl, "test-download.pdf")
      .then(() => console.log("[FidelityDL] Test download succeeded!"))
      .catch((e) => console.error("[FidelityDL] Test download failed:", e));
  }

  // Expose test function globally for console access
  window.testFidelityDownload = testDownload;

  // Inject a script into the page context to intercept fetch calls.
  // This is necessary because userscripts run in a sandbox, and even unsafeWindow
  // doesn't reliably allow us to override page-level APIs like fetch.
  function injectPageScript(code) {
    const script = document.createElement("script");
    script.textContent = code;
    document.documentElement.appendChild(script);
    script.remove();
  }

  // Set up communication channel between page context and userscript
  let pendingResolve = null;
  let pendingFilename = null;

  window.addEventListener("FidelityDL_URLCaptured", (e) => {
    const url = e.detail;
    console.log("[FidelityDL] Received captured URL from page:", url);
    if (pendingResolve && pendingFilename) {
      downloadWithFilename(url, pendingFilename)
        .then(() => {
          console.log("[FidelityDL] Download initiated successfully");
          pendingResolve({ success: true, url: url });
        })
        .catch((err) => {
          console.error("[FidelityDL] Download failed:", err);
          pendingResolve({ success: false });
        });
      pendingResolve = null;
      pendingFilename = null;
    }
  });

  // Intercept fetch to capture PDF URL, then download with proper filename.
  // We inject code into the page context because userscript sandbox prevents
  // direct fetch interception even with unsafeWindow.
  function setupFetchInterceptor(expectedFilename) {
    return new Promise((resolve) => {
      pendingResolve = resolve;
      pendingFilename = expectedFilename;

      // Inject the fetch interceptor into page context
      injectPageScript(`
        (function() {
          console.log("[FidelityDL-PageContext] Injecting fetch interceptor...");

          if (window._fidelityDLInterceptorActive) {
            console.log("[FidelityDL-PageContext] Interceptor already active, skipping");
            return;
          }
          window._fidelityDLInterceptorActive = true;

          const origFetch = window.fetch;
          console.log("[FidelityDL-PageContext] Original fetch saved, overriding...");

          window.fetch = function(url, ...args) {
            const urlStr = String(url);
            console.log("[FidelityDL-PageContext] fetch called with:", urlStr.substring(0, 100));

            if (urlStr.includes("pdf") || urlStr.includes("PDF") || urlStr.includes("PDFStatement")) {
              console.log("[FidelityDL-PageContext] PDF URL detected! Capturing...");

              // Send URL to userscript via custom event
              window.dispatchEvent(new CustomEvent("FidelityDL_URLCaptured", { detail: urlStr }));

              // Restore original fetch
              window.fetch = origFetch;
              window._fidelityDLInterceptorActive = false;

              // Return rejected promise to prevent navigation
              return Promise.reject(new Error("Download intercepted by FidelityDL"));
            }
            return origFetch.apply(this, [url, ...args]);
          };

          console.log("[FidelityDL-PageContext] Fetch interceptor installed successfully");

          // Auto-cleanup after 5 seconds
          setTimeout(() => {
            if (window._fidelityDLInterceptorActive) {
              console.log("[FidelityDL-PageContext] Cleaning up interceptor (timeout)");
              window.fetch = origFetch;
              window._fidelityDLInterceptorActive = false;
            }
          }, 5000);
        })();
      `);

      // Timeout if no URL captured
      setTimeout(() => {
        if (pendingResolve === resolve) {
          pendingResolve = null;
          pendingFilename = null;
          resolve({ success: false });
        }
      }, 5000);
    });
  }

  function getAvailableYears() {
    const items = document.querySelectorAll(
      "#select-options-container .select-item"
    );
    const years = [];
    items.forEach((item) => {
      const title =
        item.querySelector(".select-item-name")?.getAttribute("title") || "";
      if (/^\d{4}$/.test(title.trim())) {
        years.push({
          element: item,
          year: title.trim(),
          id: item.getAttribute("select-item-id"),
        });
      }
    });
    return years;
  }

  async function openYearDropdown() {
    const button = document.querySelector("#select-button");
    if (button) {
      button.click();
      await sleep(300);
    }
  }

  async function selectYear(yearInfo) {
    await openYearDropdown();
    await sleep(200);

    const items = document.querySelectorAll(
      "#select-options-container .select-item"
    );
    for (const item of items) {
      const title =
        item.querySelector(".select-item-name")?.getAttribute("title") || "";
      if (title.trim() === yearInfo.year) {
        item.click();
        await sleep(CONFIG.delayAfterYearChange);
        return true;
      }
    }
    return false;
  }

  function findLoadMoreButton() {
    const allElements = document.querySelectorAll(
      'button, pvd3-button, [role="button"]'
    );
    for (const el of allElements) {
      if (el.textContent.includes("Load more results")) {
        return el;
      }
    }
    const spans = document.querySelectorAll("span");
    for (const span of spans) {
      if (span.textContent.includes("Load more results")) {
        const btn =
          span.closest("button") ||
          span.closest("pvd3-button") ||
          span.closest('[role="button"]');
        if (btn) return btn;
      }
    }
    return null;
  }

  async function loadAllStatements() {
    let iterations = 0;
    const maxIterations = 30;

    while (!stopDownload && iterations < maxIterations) {
      const loadMoreBtn = findLoadMoreButton();

      if (!loadMoreBtn) break;

      const rect = loadMoreBtn.getBoundingClientRect();
      if (rect.height === 0) break;

      iterations++;
      updateStatus(`Loading more statements... (${iterations})`);

      loadMoreBtn.click();
      await sleep(CONFIG.delayAfterLoadMore);
    }
  }

  function parseStatementInfo(row) {
    const cell = row.querySelector("td.gridData");
    if (!cell) return null;

    const divs = cell.querySelectorAll("div");
    let docInfo = "";
    let accountInfo = "";

    divs.forEach((div) => {
      const text = div.textContent.trim();
      if (div.classList.contains("color-change")) {
        accountInfo = text;
      } else if (text && !docInfo) {
        docInfo = text;
      }
    });

    const parts = docInfo.split("—").map((s) => s.trim());
    let dateText = parts[0] || "";
    let docType = parts[1] || "";

    docType = docType.replace(/\s*\(\w+\)\s*$/, "").trim();

    if (
      parts.length >= 2 &&
      /^\w+$/.test(parts[0]) &&
      /^\w+\s+\d{4}/.test(parts[1])
    ) {
      dateText = `${parts[0]} - ${parts[1]}`;
      docType = parts[2]
        ? parts[2].replace(/\s*\(\w+\)\s*$/, "").trim()
        : "Statement";
    }

    return {
      dateText: dateText,
      docType: docType,
      accountName: accountInfo,
      raw: docInfo,
    };
  }

  function generateFilename(info) {
    const clean = (s) =>
      s
        .replace(/[<>:"/\\|?*]/g, "")
        .replace(/\s+/g, "_")
        .replace(/_+/g, "_")
        .replace(/^_|_$/g, "");

    const accountMatch = info.accountName.match(/([A-Z]\d+)$/);
    const accountId = accountMatch ? accountMatch[1] : clean(info.accountName);
    const dateClean = clean(info.dateText);

    return `Fidelity_${accountId}_${dateClean}_Statement.pdf`;
  }

  function shouldSkip(info) {
    const skipYearEnd = document.getElementById("dl-skip-yearend")?.checked;
    const onlyStatements =
      document.getElementById("dl-only-statements")?.checked;

    if (skipYearEnd) {
      const skipPatterns = [
        "Year End",
        "Investment Report",
        "Year-End",
        "Annual",
      ];
      for (const pattern of skipPatterns) {
        if (info.docType.includes(pattern) || info.raw.includes(pattern)) {
          return true;
        }
      }
    }

    if (onlyStatements) {
      if (!info.docType.includes("Statement")) {
        return true;
      }
    }

    return false;
  }

  async function downloadStatement(row) {
    const info = parseStatementInfo(row);
    if (!info) {
      console.log("[FidelityDL] Could not parse row");
      return { downloaded: false, skipped: true };
    }

    if (shouldSkip(info)) {
      console.log("[FidelityDL] Skipping:", info.raw);
      return { downloaded: false, skipped: true };
    }

    const filename = generateFilename(info);

    if (downloadedFiles.has(filename)) {
      console.log("[FidelityDL] Already downloaded:", filename);
      return { downloaded: false, skipped: true };
    }

    updateStatus(`Downloading: ${info.dateText}\n${info.accountName}`);

    const dlBtn = row.querySelector("button.downloadIconButton");
    if (!dlBtn) {
      console.log("[FidelityDL] No download button found");
      return { downloaded: false, skipped: true };
    }

    // Regular click to open the dropdown menu
    dlBtn.click();
    await sleep(CONFIG.delayForMenu);

    // Find the "Download as PDF" option
    const menuOptions = document.querySelectorAll(
      ".downloadDropdownContainer .modal-options"
    );
    let pdfOption = null;

    for (const option of menuOptions) {
      if (option.textContent.includes("PDF")) {
        pdfOption = option;
        break;
      }
    }

    if (!pdfOption) {
      console.log("[FidelityDL] PDF option not found");
      document.body.click();
      return { downloaded: false, skipped: true, navigated: false };
    }

    // Save state before clicking - page will navigate to PDF
    // When we return to this page, we'll resume from saved state
    await GM_setValue("pendingDownload", { filename });
    console.log("[FidelityDL] Saved pending download:", filename);

    // Click the PDF option - this will navigate away from this page
    // The script will continue when we navigate back
    pdfOption.click();

    // Return indicator that we're navigating (this code likely won't run)
    return { downloaded: false, skipped: false, navigated: true };
  }

  async function downloadCurrentView() {
    stopDownload = false;
    updateStatus("Loading all statements for current view...");

    await loadAllStatements();

    const rows = document.querySelectorAll("tbody.gridRow");
    updateStatus(`Processing ${rows.length} documents...`);

    for (const row of rows) {
      if (stopDownload) break;

      const result = await downloadStatement(row);
      if (result.downloaded) {
        totalDownloaded++;
      } else if (result.skipped) {
        totalSkipped++;
      }
      updateProgress();
    }

    updateStatus(stopDownload ? "Stopped by user" : "Current view complete!");
  }

  async function downloadAllYears() {
    stopDownload = false;
    updateStatus("Getting available years...");

    await openYearDropdown();
    await sleep(300);

    const years = getAvailableYears();

    document.body.click();
    await sleep(200);

    if (years.length === 0) {
      updateStatus("No years found! Make sure you're on the Statements page.");
      return;
    }

    updateStatus(
      `Found ${years.length} years: ${years.map((y) => y.year).join(", ")}`
    );
    await sleep(1000);

    // Convert to simple year strings for storage
    const yearStrings = years.map((y) => y.year);

    for (let yi = 0; yi < years.length; yi++) {
      if (stopDownload) break;

      const yearInfo = years[yi];
      updateStatus(`Switching to year ${yearInfo.year}...`);
      await selectYear(yearInfo);

      updateStatus(`Loading statements for ${yearInfo.year}...`);
      await loadAllStatements();

      const rows = document.querySelectorAll("tbody.gridRow");
      updateStatus(
        `Year ${yearInfo.year}: Processing ${rows.length} documents...`
      );

      for (let ri = 0; ri < rows.length; ri++) {
        if (stopDownload) break;

        const row = rows[ri];

        // Save current position before attempting download
        await GM_setValue("resumeState", {
          yearIndex: yi,
          rowIndex: ri + 1, // Next row after this one
          years: yearStrings,
        });

        const result = await downloadStatement(row);

        if (result.navigated) {
          // Page is navigating to PDF, script will stop
          console.log("[FidelityDL] Navigating to PDF, will resume after...");
          return;
        }

        if (result.downloaded) {
          totalDownloaded++;
        } else if (result.skipped) {
          totalSkipped++;
        }
        updateProgress();
      }
    }

    // All done - clear state
    await clearResumeState();
    updateStatus(
      stopDownload
        ? "Stopped by user"
        : `Complete! Downloaded ${totalDownloaded} files.`
    );
  }

  function init() {
    console.log("[FidelityDL] Initializing...");

    const checkInterval = setInterval(() => {
      const rows = document.querySelectorAll("tbody.gridRow");
      const yearBtn = document.querySelector("#select-button");

      if (rows.length > 0 || yearBtn) {
        clearInterval(checkInterval);
        console.log("[FidelityDL] Page ready, adding control panel");
        addControlPanel();
      }
    }, 1000);

    setTimeout(() => {
      clearInterval(checkInterval);
      if (!document.getElementById("fidelity-bulk-dl")) {
        addControlPanel();
      }
    }, 30000);
  }

  // Check if we need to resume a download session
  async function checkAndResume() {
    await restoreDownloadedFiles();

    const resumeState = await getResumeState();
    if (resumeState) {
      console.log("[FidelityDL] Found resume state:", resumeState);
      updateStatus("Resuming download session...");

      // Wait a bit for page to stabilize
      await sleep(2000);

      // Clear resume state since we're handling it
      await clearResumeState();

      // Continue downloading from where we left off
      resumeDownloadAllYears(resumeState);
    }
  }

  // Resume download all years from saved state
  async function resumeDownloadAllYears(state) {
    stopDownload = false;
    const { yearIndex, rowIndex, years } = state;

    console.log(
      "[FidelityDL] Resuming from year",
      years[yearIndex],
      "row",
      rowIndex
    );

    // Need to get the year dropdown options to select properly
    await openYearDropdown();
    await sleep(300);
    const yearOptions = getAvailableYears();
    document.body.click();
    await sleep(200);

    for (let yi = yearIndex; yi < years.length; yi++) {
      if (stopDownload) break;

      const yearStr = years[yi];
      const yearInfo = yearOptions.find((y) => y.year === yearStr);

      if (!yearInfo) {
        console.log("[FidelityDL] Could not find year:", yearStr);
        continue;
      }

      updateStatus(`Resuming year ${yearStr}...`);

      await selectYear(yearInfo);
      await sleep(CONFIG.delayAfterYearChange);
      await loadAllStatements();

      const rows = document.querySelectorAll("tbody.gridRow");
      const startRow = yi === yearIndex ? rowIndex : 0;

      updateStatus(
        `Year ${year}: Processing from row ${startRow + 1} of ${rows.length}...`
      );

      for (let ri = startRow; ri < rows.length; ri++) {
        if (stopDownload) break;

        const row = rows[ri];

        // Save current position before attempting download
        await GM_setValue("resumeState", {
          yearIndex: yi,
          rowIndex: ri + 1, // Next row to process
          years: years,
        });

        const result = await downloadStatement(row);

        if (result.navigated) {
          // Page is navigating, script will stop
          console.log("[FidelityDL] Navigating to PDF, will resume after...");
          return;
        }

        if (result.downloaded) {
          totalDownloaded++;
        } else if (result.skipped) {
          totalSkipped++;
        }
        updateProgress();
      }
    }

    // All done - clear state
    await clearResumeState();
    updateStatus("All downloads complete!");
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => setTimeout(init, 2000));
  } else {
    setTimeout(init, 2000);
  }

  // After init, check for resume
  setTimeout(async () => {
    if (document.getElementById("fidelity-bulk-dl")) {
      await checkAndResume();
    }
  }, 5000);
})();
