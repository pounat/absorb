var book = ePub();
var rendition;
var displayed;
var chapters = []
var clearSelectionOnPageChange = true; // Global flag for selection clearing behavior
var selectAnnotationRange = false; // Global flag for programmatically selecting annotation ranges
var initialXPathProcessed = false; // Flag to prevent processing initialXPath multiple times
var xpathDisplayInProgress = false; // Flag to prevent multiple XPath displays
var initialPositionLoading = false; // Flag to track if initial position is being loaded
// Global selection state tracking (needed for blocking navigation when selection is active)
var isSelecting = false;
var lastCfiRange = null;
var selectionTimeout = null;
var hasSentSelection = false; // Track if we've actually sent a selection event to Flutter
var lastTapCoords = null; // Store the last tap coordinates for onTouchDown/onTouchUp callbacks

// Absorb patch: the browser's native text-selection auto-scroll (notably
// Samsung's) drags the paginated container to arbitrary offsets to keep the
// selection handles visible, leaving the view stuck showing the halves of two
// adjacent pages until a layout toggle forces a re-render. epub.js never
// re-aligns on its own. Watch for any scroll that SETTLES off a page
// boundary and snap it back - legitimate page turns settle exactly on a
// boundary, so this is a no-op for them.
var snapGuardAttached = false;
var snapGuardTimer = null;

// Absorb patch: dragging a selection handle into the page margin makes the
// browser map the touch point to a far-away document position - the selection
// balloons to the whole page for a beat, then collapses to nothing. Remember
// the last sane range while handles are being dragged; refuse the balloon and
// resurrect the selection when the balloon's collapse follows. Programmatic
// clears (tap-to-dismiss, page turns) suppress the resurrection.
var lastGoodSelection = null; // {win, range, len}
var selectionBlowUpAt = 0;
var suppressSelectionGuard = false;

function snapToPageBoundary() {
  try {
    if (!rendition || !rendition.manager || !rendition.manager.container) return;
    var settings = rendition.settings || {};
    // Only paginated horizontal flows have page boundaries to snap to.
    if (settings.flow && String(settings.flow).indexOf('scrolled') === 0) return;
    if (settings.defaultDirection === 'rtl') return;
    var manager = rendition.manager;
    if (manager.settings && manager.settings.axis === 'vertical') return;
    var container = manager.container;
    var step = (manager.layout && manager.layout.delta) || container.clientWidth;
    if (!step || step <= 0) return;
    var off = container.scrollLeft;
    var mis = off % step;
    if (mis < 2 || step - mis < 2) return; // already aligned (within rounding)
    container.scrollLeft = Math.round(off / step) * step;
  } catch (e) {
    // Never let the guard break reading.
  }
}

function attachSnapGuard() {
  if (snapGuardAttached) return;
  try {
    if (!rendition || !rendition.manager || !rendition.manager.container) return;
    var container = rendition.manager.container;
    snapGuardAttached = true;
    container.addEventListener('scroll', function () {
      // While a selection is active, any container scroll is the browser
      // chasing the drag handles (page turns are blocked during selection).
      // Correct it immediately: letting it settle first shifted the content
      // under the finger, which both flashed a misaligned page and collapsed
      // the selection when a handle was dragged into the margin.
      if (isSelecting) {
        snapToPageBoundary();
        return;
      }
      if (snapGuardTimer) clearTimeout(snapGuardTimer);
      snapGuardTimer = setTimeout(snapToPageBoundary, 250);
    }, { passive: true });
  } catch (e) {
    // Ignore - guard just won't arm.
  }
}

// Book bytes arrive from Flutter in base64 chunks so no single string ever
// holds the whole file; loadBook(null, ...) assembles them.
var bookParts = [];
// Settings the live rendition was built with. The blind has to be laid out
// identically or its page boundaries drift from the real ones.
var lastRenderOpts = null;
var lastTheme = {bg: null, fg: null, css: null, fontSize: null};
var bookPartsLen = 0;
function beginBookData() {
  bookParts = [];
  bookPartsLen = 0;
}
function appendBookData(b64) {
  var bin = atob(b64);
  var arr = new Uint8Array(bin.length);
  for (var i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
  bookParts.push(arr);
  bookPartsLen += arr.length;
}

function loadBook(data, cfi, initialXPath, manager, flow, spread, snap, allowScriptedContent, direction, useCustomSwipe, backgroundColor, foregroundColor, fontSize, clearSelectionOnNav, selectAnnotationRangeParam, customCss) {
  // Reset flags for new book
  initialXPathProcessed = false;
  xpathDisplayInProgress = false;
  initialPositionLoading = false;
  snapGuardAttached = false; // new rendition = new container to watch
  // Store the clearSelectionOnPageChange setting
  clearSelectionOnPageChange = clearSelectionOnNav !== undefined ? clearSelectionOnNav : true;
  // Store the selectAnnotationRange setting
  selectAnnotationRange = selectAnnotationRangeParam !== undefined ? selectAnnotationRangeParam : false;
  var viewportHeight = window.innerHeight;
  document.getElementById('viewer').style.height = viewportHeight;
  var uint8Array;
  if (data) {
    uint8Array = new Uint8Array(data);
  } else {
    uint8Array = new Uint8Array(bookPartsLen);
    var off = 0;
    for (var p = 0; p < bookParts.length; p++) {
      uint8Array.set(bookParts[p], off);
      off += bookParts[p].length;
      bookParts[p] = null; // let each chunk collect while assembling
    }
    bookParts = [];
    bookPartsLen = 0;
  }
  book.open(uint8Array,)
  lastRenderOpts = {
    manager: manager,
    flow: flow,
    spread: spread,
    width: "100vw",
    height: "100vh",
    snap: snap && !useCustomSwipe,
    allowScriptedContent: allowScriptedContent,
    defaultDirection: direction
  };
  lastTheme.bg = backgroundColor;
  lastTheme.fg = foregroundColor;
  lastTheme.css = customCss;
  lastTheme.fontSize = fontSize;
  rendition = book.renderTo("viewer", lastRenderOpts);

  // Apply initial theme
  updateTheme(backgroundColor, foregroundColor, customCss);

  // Initial display - skip if we have XPath (we'll display after conversion)
  // If we have XPath, we'll display after converting it, so skip initial display
  if (initialXPath) {
    // Just display the default location, we'll navigate to XPath after conversion
    displayed = rendition.display()
    // XPath conversion will happen later in book.ready, callback will be fired there
  } else if (cfi) {
    // CFI display happens immediately, so fire callback now
    initialPositionLoading = true;
    try {
      window.flutter_inappwebview.callHandler('initialPositionLoading', { type: 'cfi' });
    } catch (e) {
      console.error('Error calling initialPositionLoading callback:', e);
    }
    displayed = rendition.display(cfi)
  } else {
    displayed = rendition.display()
  }

  // Setup blocking immediately after rendition is created
  // Use setTimeout to ensure rendition object is fully initialized
  setTimeout(function () {
    setupRenditionBlocking();
  }, 100);

  rendition.on("displayed", function (renderer) {
    window.flutter_inappwebview.callHandler('displayed');
    attachSnapGuard();
    // If we were loading initial position, notify that it's complete
    if (initialPositionLoading) {
      initialPositionLoading = false;
      try {
        window.flutter_inappwebview.callHandler('initialPositionLoaded');
      } catch (e) {
        console.error('Error calling initialPositionLoaded callback:', e);
      }
    }
    // Setup blocking again to ensure it's active (in case it wasn't set up earlier)
    setupRenditionBlocking();
  });

  // Reset selection state tracking (use global variables)
  selectionTimeout = null;
  isSelecting = false;
  lastCfiRange = null;
  hasSentSelection = false;

  // Helper function to check and process selection
  function checkAndProcessSelection(contents) {
    try {
      // Try contents window first
      var selection = contents.window.getSelection();
      var range = null;
      var selectedText = '';

      if (selection && selection.rangeCount > 0) {
        try {
          range = selection.getRangeAt(0);
          selectedText = selection.toString();
        } catch (e) {
          // Ignore errors
        }
      }

      // If no selection in contents, try parent window (iPad sometimes puts it there)
      if ((!selectedText || !range || range.collapsed) && window.getSelection) {
        try {
          var parentSelection = window.getSelection();
          if (parentSelection && parentSelection.rangeCount > 0) {
            var parentRange = parentSelection.getRangeAt(0);
            var parentText = parentSelection.toString();
            // Check if parent selection is actually in the epub content
            if (parentText && !parentRange.collapsed) {
              // Try to find which iframe this selection is in
              var iframe = contents.document.defaultView.frameElement;
              if (iframe && parentRange.commonAncestorContainer) {
                // Check if the selection is within our iframe
                try {
                  if (iframe.contentDocument &&
                    (iframe.contentDocument === parentRange.commonAncestorContainer.ownerDocument ||
                      iframe.contentDocument.contains(parentRange.commonAncestorContainer))) {
                    selection = parentSelection;
                    range = parentRange;
                    selectedText = parentText;
                  }
                } catch (e) {
                  // Cross-origin or other error, try anyway
                  selection = parentSelection;
                  range = parentRange;
                  selectedText = parentText;
                }
              }
            }
          }
        } catch (e) {
          // Ignore errors
        }
      }

      if (!selection || !range || selection.rangeCount === 0) {
        return false;
      }

      if (!selectedText || range.collapsed) {
        return false;
      }

      // If we already have this selection, don't process again
      if (isSelecting && lastCfiRange) {
        return true;
      }

      // Try to get CFI from range using epub.js API
      try {
        if (typeof contents.cfiFromRange === 'function') {
          var cfiRange = contents.cfiFromRange(range);
          if (cfiRange) {
            lastCfiRange = cfiRange;
            isSelecting = true;
            // Clear any existing timeout
            if (selectionTimeout) {
              clearTimeout(selectionTimeout);
            }
            // Debounce to allow selection to stabilize
            selectionTimeout = setTimeout(function () {
              // Verify selection still exists before sending
              var stillHasSelection = false;
              try {
                var currentSelection = contents.window.getSelection();
                if (currentSelection && currentSelection.rangeCount > 0) {
                  var currentRange = currentSelection.getRangeAt(0);
                  var currentText = currentSelection.toString();
                  if (currentText && currentRange && !currentRange.collapsed) {
                    stillHasSelection = true;
                  }
                }
              } catch (e) {
                // Ignore errors
              }

              if (stillHasSelection && lastCfiRange === cfiRange) {
                sendSelectionData(cfiRange, contents);
              } else {
                // Selection was cleared before timeout fired, clear flags
                if (lastCfiRange === cfiRange) {
                  isSelecting = false;
                  lastCfiRange = null;
                  hasSentSelection = false;
                }
              }
            }, 200);
            return true;
          }
        }
      } catch (e) {
        // Ignore errors
      }
    } catch (e) {
      // Ignore errors
    }
    return false;
  }

  // Continuous polling for iPad (as last resort when events don't fire)
  var pollIntervals = []; // Store intervals for each content frame
  var lastPolledSelections = new Map(); // Track last selection per contents

  function startPolling(contents) {
    // Check if we're already polling this contents
    var contentsId = contents.document ? contents.document.URL : 'unknown';
    if (lastPolledSelections.has(contentsId)) {
      return;
    }

    lastPolledSelections.set(contentsId, null);

    var pollCount = 0;
    var noSelectionCount = 0;
    var interval = setInterval(function () {
      try {
        pollCount++;

        // Stop polling if no selection found for 5 seconds (50 polls * 100ms)
        // This optimizes performance - only poll when there might be a selection
        if (pollCount > 50 && noSelectionCount > 40) {
          clearInterval(interval);
          lastPolledSelections.delete(contentsId);
          return;
        }

        // Check if window/selection API is available
        if (!contents.window || !contents.window.getSelection) {
          return;
        }

        var selection = contents.window.getSelection();
        if (!selection) {
          noSelectionCount++;
          return;
        }

        // Check selection properties even if toString() is empty
        var rangeCount = selection.rangeCount || 0;
        var selectedText = selection.toString() || '';
        var hasRanges = rangeCount > 0;

        // Even if toString() is empty, check if there are ranges (iPad quirk)
        var currentSelection = selectedText || (hasRanges ? 'HAS_RANGE_BUT_NO_TEXT' : null);
        var lastSelection = lastPolledSelections.get(contentsId);

        // Only process if selection changed
        if (currentSelection !== lastSelection) {
          lastPolledSelections.set(contentsId, currentSelection);
          noSelectionCount = 0; // Reset counter when selection found

          if (!selectedText && !hasRanges) {
            // Clear flags if they're set (even if we haven't sent a selection yet)
            if (isSelecting || lastCfiRange) {
              // Only fire selectionCleared if we've actually sent a selection
              if (hasSentSelection) {
                window.flutter_inappwebview.callHandler('selectionCleared');
              }
              // Always clear the flags when there's no selection
              isSelecting = false;
              lastCfiRange = null;
              hasSentSelection = false;
              if (selectionTimeout) {
                clearTimeout(selectionTimeout);
                selectionTimeout = null;
              }
            }
          } else {
            // Selection exists - try to process it
            if (!isSelecting) {
              checkAndProcessSelection(contents);
            }
          }
        } else if (!currentSelection) {
          noSelectionCount++;
        }
      } catch (e) {
        // Ignore errors
      }
    }, 200); // Check every 200ms

    pollIntervals.push({ contentsId: contentsId, interval: interval });
  }

  function stopPolling() {
    pollIntervals.forEach(function (item) {
      clearInterval(item.interval);
    });
    pollIntervals = [];
    lastPolledSelections.clear();
  }

  // Handle selection clearing and changes
  rendition.hooks.content.register(function (contents) {
    // Listen on document
    contents.window.document.addEventListener('selectionchange', function () {
      var selection = contents.window.getSelection();
      var selectedText = selection.toString();

      // Check if there's actually a range, not just text (more reliable)
      var hasRange = selection && selection.rangeCount > 0;
      var hasNonCollapsedRange = false;
      if (hasRange) {
        try {
          var range = selection.getRangeAt(0);
          hasNonCollapsedRange = range && !range.collapsed;
        } catch (e) {
          // Ignore errors
        }
      }

      // Only clear selection if there's truly no range AND no text
      // This prevents clearing when toString() is temporarily empty but range exists
      if (!hasNonCollapsedRange && !selectedText) {
        // Double-check across all content frames before clearing
        var stillHasSelection = false;
        try {
          var allContents = rendition.getContents();
          for (var i = 0; i < allContents.length; i++) {
            try {
              var cont = allContents[i];
              if (cont.window && cont.window.getSelection) {
                var contSel = cont.window.getSelection();
                if (contSel && contSel.rangeCount > 0) {
                  var contRange = contSel.getRangeAt(0);
                  var contText = contSel.toString();
                  if (contText || (contRange && !contRange.collapsed)) {
                    stillHasSelection = true;
                    break;
                  }
                }
              }
            } catch (e) {
              // Ignore errors
            }
          }
          // Also check parent window
          if (!stillHasSelection && window.getSelection) {
            var parentSel = window.getSelection();
            if (parentSel && parentSel.rangeCount > 0) {
              var parentRange = parentSel.getRangeAt(0);
              var parentText = parentSel.toString();
              if (parentText || (parentRange && !parentRange.collapsed)) {
                stillHasSelection = true;
              }
            }
          }
        } catch (e) {
          // Ignore errors
        }

        if (!stillHasSelection) {
          // A margin-drag balloon usually collapses right after - bring the
          // last sane selection back instead of losing it. Programmatic
          // clears suppress this so tap-to-dismiss still works.
          if (!suppressSelectionGuard && lastGoodSelection &&
              selectionBlowUpAt && Date.now() - selectionBlowUpAt < 1200) {
            try {
              var rsel = lastGoodSelection.win.getSelection();
              rsel.removeAllRanges();
              rsel.addRange(lastGoodSelection.range.cloneRange());
              selectionBlowUpAt = 0;
              return;
            } catch (eR) {}
          }
          lastGoodSelection = null;
          selectionBlowUpAt = 0;
          // Clear flags if they're set (even if we haven't sent a selection yet)
          // This handles the case where checkAndProcessSelection set flags but selection was cleared before timeout
          if (isSelecting || lastCfiRange) {
            // Only fire selectionCleared if we've actually sent a selection
            if (hasSentSelection) {
              window.flutter_inappwebview.callHandler('selectionCleared');
            }
            // Always clear the flags when there's no selection
            isSelecting = false;
            lastCfiRange = null;
            hasSentSelection = false;
            if (selectionTimeout) {
              clearTimeout(selectionTimeout);
              selectionTimeout = null;
            }
          }
        }
      } else if (isSelecting) {
        // Margin-drag guard: a sudden many-fold jump in selection size is the
        // browser ballooning to the whole page, not the user extending word
        // by word - put the last sane range back and ignore the event.
        if (hasNonCollapsedRange && lastGoodSelection) {
          var curLen = selectedText.length;
          if (curLen > Math.max(lastGoodSelection.len * 5, lastGoodSelection.len + 400)) {
            selectionBlowUpAt = Date.now();
            try {
              var gsel = contents.window.getSelection();
              gsel.removeAllRanges();
              gsel.addRange(lastGoodSelection.range.cloneRange());
            } catch (eG) {}
            return;
          }
        }
        if (hasNonCollapsedRange && selectedText) {
          try {
            lastGoodSelection = {
              win: contents.window,
              range: selection.getRangeAt(0).cloneRange(),
              len: selectedText.length,
            };
          } catch (eG2) {}
        }
        // Selection is being modified (dragging handles)
        // Notify Flutter to hide the widget
        window.flutter_inappwebview.callHandler('selectionChanging');

        // Find the contents object that actually contains the current selection
        // The passed contents might be from a different page after navigation
        var actualContents = contents;
        try {
          var allContents = rendition.getContents();
          for (var i = 0; i < allContents.length; i++) {
            var cont = allContents[i];
            try {
              if (cont.window && cont.window.getSelection) {
                var sel = cont.window.getSelection();
                if (sel && sel.rangeCount > 0) {
                  var range = sel.getRangeAt(0);
                  if (range && !range.collapsed) {
                    // This contents has an active selection, use it
                    actualContents = cont;
                    break;
                  }
                }
              }
            } catch (e) {
              // Ignore errors, continue checking other contents
            }
          }
        } catch (e) {
          // If we can't find the right contents, use the passed one
          actualContents = contents;
        }

        // Get the current CFI from the current selection range (not the stale lastCfiRange)
        // This ensures we use the correct CFI for the current page after navigation
        try {
          var currentSelection = actualContents.window.getSelection();
          if (currentSelection && currentSelection.rangeCount > 0) {
            var currentRange = currentSelection.getRangeAt(0);
            if (currentRange && !currentRange.collapsed) {
              // Get the current CFI from the current selection
              if (typeof actualContents.cfiFromRange === 'function') {
                var currentCfi = actualContents.cfiFromRange(currentRange);
                if (currentCfi) {
                  // Update lastCfiRange with the current CFI
                  lastCfiRange = currentCfi;
                }
              }
            }
          }
        } catch (e) {
          // If we can't get the current CFI, we'll use lastCfiRange as fallback
          // but this might cause issues if it's from a different page
        }

        // Clear existing timeout
        if (selectionTimeout) {
          clearTimeout(selectionTimeout);
        }

        // Set timeout to detect when dragging stops
        selectionTimeout = setTimeout(function () {
          // Selection has stabilized, send the final selection
          // Find the correct contents again in case it changed
          var finalContents = actualContents;
          try {
            var allContents = rendition.getContents();
            for (var i = 0; i < allContents.length; i++) {
              var cont = allContents[i];
              try {
                if (cont.window && cont.window.getSelection) {
                  var sel = cont.window.getSelection();
                  if (sel && sel.rangeCount > 0) {
                    var range = sel.getRangeAt(0);
                    if (range && !range.collapsed) {
                      finalContents = cont;
                      break;
                    }
                  }
                }
              } catch (e) {
                // Ignore errors
              }
            }
          } catch (e) {
            // Use actualContents as fallback
            finalContents = actualContents;
          }

          // Get the current CFI again in case it changed during dragging
          var finalCfi = lastCfiRange;
          try {
            var finalSelection = finalContents.window.getSelection();
            if (finalSelection && finalSelection.rangeCount > 0) {
              var finalRange = finalSelection.getRangeAt(0);
              if (finalRange && !finalRange.collapsed) {
                if (typeof finalContents.cfiFromRange === 'function') {
                  var updatedCfi = finalContents.cfiFromRange(finalRange);
                  if (updatedCfi) {
                    finalCfi = updatedCfi;
                    lastCfiRange = updatedCfi;
                  }
                }
              }
            }
          } catch (e) {
            // Use lastCfiRange as fallback
          }

          if (finalCfi) {
            sendSelectionData(finalCfi, finalContents);
          }
          // Set isSelecting = false, but keep lastCfiRange so hasActiveSelection() still returns true
          // This allows navigation to remain blocked while selection is active
          isSelecting = false;
        }, 300); // 300ms debounce
      } else {
        // Fallback for iPad/iOS: Detect initial selection when epub.js "selected" event doesn't fire
        checkAndProcessSelection(contents);
      }
    });

    // Also listen on window (some browsers fire it there)
    if (contents.window.addEventListener) {
      contents.window.addEventListener('selectionchange', function () {
        var selection = contents.window.getSelection();
        var selectedText = selection.toString();
        if (selectedText && !isSelecting) {
          checkAndProcessSelection(contents);
        }
      });
    }

    // Start polling for this content frame (optimized - stops if no selection found)
    try {
      startPolling(contents);
    } catch (e) {
      // Ignore errors
    }

    // Also try to get all contents and poll them (important for spread layout with 2 pages)
    try {
      var allContents = rendition.getContents();
      allContents.forEach(function (cont, index) {
        var frameId = cont.document ? cont.document.URL : ('frame' + index);
        if (cont.window && !lastPolledSelections.has(frameId)) {
          startPolling(cont);
        }
      });

      // Set up a periodic check to ensure all frames are being polled
      // (in case frames are added/removed dynamically)
      setInterval(function () {
        try {
          var currentContents = rendition.getContents();
          currentContents.forEach(function (cont, index) {
            var frameId = cont.document ? cont.document.URL : ('frame' + index);
            if (cont.window && !lastPolledSelections.has(frameId)) {
              startPolling(cont);
            }
          });
        } catch (e) {
          // Ignore errors in periodic check
        }
      }, 2000); // Check every 2 seconds for new frames
    } catch (e) {
      // Ignore errors
    }

    // Also poll parent window selection (iPad often puts selection there)
    if (!lastPolledSelections.has('parent')) {
      lastPolledSelections.set('parent', null);
      var parentNoSelectionCount = 0;
      var parentInterval = setInterval(function () {
        try {
          if (!window.getSelection) return;
          var parentSelection = window.getSelection();
          var parentText = parentSelection ? parentSelection.toString() : '';
          var currentParentSelection = parentText || null;
          var lastParentSelection = lastPolledSelections.get('parent');

          if (currentParentSelection !== lastParentSelection) {
            lastPolledSelections.set('parent', currentParentSelection);
            parentNoSelectionCount = 0;

            if (parentText && parentSelection.rangeCount > 0) {
              // Try to process with each content frame (important for spread with 2 pages)
              try {
                var allContents = rendition.getContents();
                allContents.forEach(function (cont, index) {
                  if (!isSelecting) {
                    checkAndProcessSelection(cont);
                  }
                });
              } catch (e) {
                // Ignore errors
              }
            } else {
              parentNoSelectionCount++;
            }
          } else if (!currentParentSelection) {
            parentNoSelectionCount++;
          }

          // Stop polling if no selection found for 5 seconds
          if (parentNoSelectionCount > 25) {
            clearInterval(parentInterval);
            lastPolledSelections.delete('parent');
          }
        } catch (e) {
          // Ignore errors
        }
      }, 200);
      pollIntervals.push({ contentsId: 'parent', interval: parentInterval });
    }
  });

  book.loaded.navigation.then(function (toc) {
    chapters = parseChapters(toc)
    window.flutter_inappwebview.callHandler('chapters');
  })

  rendition.on("rendered", function () {
    window.flutter_inappwebview.callHandler('rendered');
  })

  // Function to calculate and send selection data
  // Make it globally accessible for native callbacks (needed for iPad support)
  function sendSelectionData(cfiRange, contents) {
    // Find the contents object that actually contains the current selection
    // This is important after navigation - the passed contents might be from a different page
    var actualContents = contents;
    var selection = null;
    var selRange = null;
    var selectedText = '';

    try {
      var allContents = rendition.getContents();
      for (var i = 0; i < allContents.length; i++) {
        var cont = allContents[i];
        try {
          if (cont.window && cont.window.getSelection) {
            var sel = cont.window.getSelection();
            if (sel && sel.rangeCount > 0) {
              var range = sel.getRangeAt(0);
              if (range && !range.collapsed) {
                // This contents has an active selection, use it
                actualContents = cont;
                selection = sel;
                selRange = range;
                // Get text directly from the selection range to avoid calling book.getRange()
                // which can cause navigation if the CFI is from a different page
                selectedText = sel.toString() || range.toString();
                break;
              }
            }
          }
        } catch (e) {
          // Ignore errors, continue checking other contents
        }
      }

      // If we didn't find a selection in any contents, try the passed contents
      if (!selection && contents && contents.window && contents.window.getSelection) {
        selection = contents.window.getSelection();
        if (selection && selection.rangeCount > 0) {
          selRange = selection.getRangeAt(0);
          if (selRange && !selRange.collapsed) {
            selectedText = selection.toString() || selRange.toString();
            actualContents = contents;
          }
        }
      }
    } catch (e) {
      // If we can't find the right contents, use the passed one
      actualContents = contents;
      try {
        if (contents && contents.window && contents.window.getSelection) {
          selection = contents.window.getSelection();
          if (selection && selection.rangeCount > 0) {
            selRange = selection.getRangeAt(0);
            if (selRange && !selRange.collapsed) {
              selectedText = selection.toString() || selRange.toString();
            }
          }
        }
      } catch (e2) {
        // Ignore
      }
    }

    // Convert CFI to XPath (this doesn't cause navigation)
    cfiRangeToXPath(cfiRange.toString()).then(function (selectionXpath) {
      try {
        // Get selection coordinates from the actual contents that has the selection
        var rect = null;

        if (selection && selRange) {
          // Get the range and its client rect (relative to iframe viewport)
          var clientRect = selRange.getBoundingClientRect();

          // Get the WebView dimensions (parent window)
          var webViewWidth = window.innerWidth;
          var webViewHeight = window.innerHeight;

          // Get the iframe element in the parent document
          var iframe = actualContents.document.defaultView.frameElement;
          var iframeRect = iframe.getBoundingClientRect();

          // Calculate absolute position in WebView (iframe offset + selection position)
          var absoluteLeft = iframeRect.left + clientRect.left;
          var absoluteTop = iframeRect.top + clientRect.top;

          // Normalize to 0-1 range relative to WebView dimensions
          rect = {
            left: absoluteLeft / webViewWidth,
            top: absoluteTop / webViewHeight,
            width: clientRect.width / webViewWidth,
            height: clientRect.height / webViewHeight,
            contentHeight: webViewHeight
          };
        }

        var args = [cfiRange.toString(), selectedText, rect, selectionXpath];
        window.flutter_inappwebview.callHandler('selection', ...args);
        hasSentSelection = true; // Mark that we've sent a selection
      } catch (e) {
        // Still send the selection without coordinates if there's an error
        var args = [cfiRange.toString(), selectedText, null, selectionXpath];
        window.flutter_inappwebview.callHandler('selection', ...args);
        hasSentSelection = true; // Mark that we've sent a selection
      }
    }).catch(function (e) {
      // If XPath conversion fails, still send CFI
      try {
        var rect = null;
        if (selection && selRange) {
          var clientRect = selRange.getBoundingClientRect();
          var webViewWidth = window.innerWidth;
          var webViewHeight = window.innerHeight;
          var iframe = actualContents.document.defaultView.frameElement;
          var iframeRect = iframe.getBoundingClientRect();
          var absoluteLeft = iframeRect.left + clientRect.left;
          var absoluteTop = iframeRect.top + clientRect.top;
          rect = {
            left: absoluteLeft / webViewWidth,
            top: absoluteTop / webViewHeight,
            width: clientRect.width / webViewWidth,
            height: clientRect.height / webViewHeight,
            contentHeight: webViewHeight
          };
        }
        var args = [cfiRange.toString(), selectedText, rect, null];
        window.flutter_inappwebview.callHandler('selection', ...args);
        hasSentSelection = true; // Mark that we've sent a selection
      } catch (e2) {
        var args = [cfiRange.toString(), selectedText, null, null];
        window.flutter_inappwebview.callHandler('selection', ...args);
        hasSentSelection = true; // Mark that we've sent a selection
      }
    });
  }

  // Make sendSelectionData globally accessible for iPad native callbacks
  window.sendSelectionData = sendSelectionData;

  ///text selection callback
  rendition.on("selected", function (cfiRange, contents) {
    lastCfiRange = cfiRange;

    if (!isSelecting) {
      // Initial selection - send immediately
      isSelecting = true;
      sendSelectionData(cfiRange, contents);
    }
    // If already selecting, the selectionchange handler will debounce it
  });

  //book location changes callback
  rendition.on("relocated", function (location) {
    // BLOCK navigation if there's an active selection
    // This is a final safeguard - if something bypassed our other blocks, prevent the navigation
    // BUT: Don't block if the user is actively dragging selection handles (isSelecting is true)
    // because that would cause the page to snap back when dragging handles after navigation
    if (hasActiveSelection() && !isSelecting) {
      console.log('Blocked relocated event - selection active, attempting to revert');
      // Try to revert to previous location
      // Store the previous location before blocking
      if (rendition.location && rendition.location.start) {
        try {
          // Get the current location before this navigation
          var currentCfi = rendition.location.start.cfi;
          // If we have a stored previous location, go back to it
          // BUT: Only revert if the current location is different from lastValidLocation
          // and we're not in the middle of a selection operation
          // AND: Don't revert if lastValidLocation is null or undefined (initial state)
          if (window.lastValidLocation &&
            window.lastValidLocation !== currentCfi &&
            !isSelecting &&
            window.lastValidLocation !== null &&
            window.lastValidLocation !== undefined) {
            console.log('Reverting to last valid location:', window.lastValidLocation);
            setTimeout(function () {
              // Double-check that selection is still active and we're not selecting
              if (!hasActiveSelection() || isSelecting) {
                return; // Don't revert if selection was cleared or user is actively selecting
              }
              if (originalDisplay && !hasActiveSelection()) {
                originalDisplay(window.lastValidLocation);
              } else if (rendition.display && !hasActiveSelection()) {
                rendition.display(window.lastValidLocation);
              }
            }, 10);
          }
        } catch (e) {
          console.error('Error reverting location:', e);
        }
      }
      // Don't process the relocation - return early (don't update lastValidLocation)
      return;
    }

    // Only store valid location for potential revert if navigation succeeded
    // (i.e., we didn't block it above)
    if (location && location.start && location.start.cfi) {
      window.lastValidLocation = location.start.cfi;
    }

    // Clear selection when navigating to a new page (if enabled)
    if (clearSelectionOnPageChange && hasSentSelection && (isSelecting || lastCfiRange)) {
      isSelecting = false;
      lastCfiRange = null;
      hasSentSelection = false;
      if (selectionTimeout) {
        clearTimeout(selectionTimeout);
        selectionTimeout = null;
      }

      // Clear the actual browser selection across all iframe contents
      rendition.getContents().forEach(function (contents) {
        try {
          if (contents.window.getSelection) {
            contents.window.getSelection().removeAllRanges();
          }
        } catch (e) {
          // Ignore errors if iframe is not accessible
        }
      });

      // Notify Flutter that selection was cleared
      window.flutter_inappwebview.callHandler('selectionCleared');
    }

    var percent = location.start.percentage;

    // Convert CFIs to XPath
    Promise.all([
      cfiToXPath(location.start.cfi),
      cfiToXPath(location.end.cfi)
    ]).then(function (xpaths) {
      var locationData = {
        startCfi: location.start.cfi,
        endCfi: location.end.cfi,
        startXpath: xpaths[0],
        endXpath: xpaths[1],
        progress: percent
      }
      var args = [locationData]
      window.flutter_inappwebview.callHandler('relocated', ...args);
    }).catch(function (e) {
      // If XPath conversion fails, still send CFI
      var locationData = {
        startCfi: location.start.cfi,
        endCfi: location.end.cfi,
        startXpath: null,
        endXpath: null,
        progress: percent
      }
      var args = [locationData]
      window.flutter_inappwebview.callHandler('relocated', ...args);
    });
  });

  rendition.on('displayError', function (e) {
    window.flutter_inappwebview.callHandler('displayError');
  })

  rendition.on('markClicked', function (cfiRange) {
    // Forward to Flutter. This was missing: the Dart side registers a
    // "markClicked" handler but nothing here ever called it, so annotation
    // taps never reached the app.
    try {
      window.flutter_inappwebview.callHandler('markClicked', cfiRange.toString());
    } catch (e) {
      console.error('Error forwarding markClicked:', e);
    }

    // Only programmatically select if enabled
    if (selectAnnotationRange) {
      // Programmatically select the annotation range to trigger the selection event
      // The selection event will provide the correct rect automatically
      try {
        var allContents = rendition.getContents();
        var contents = null;
        var range = null;

        // Try to get the range from each contents frame
        for (var i = 0; i < allContents.length; i++) {
          try {
            var testContents = allContents[i];
            if (typeof testContents.range === 'function') {
              var testRange = testContents.range(cfiRange);
              if (testRange && testRange.startContainer && testRange.endContainer) {
                if (testContents.document.contains(testRange.startContainer) ||
                  testContents.document.contains(testRange.endContainer)) {
                  contents = testContents;
                  range = testRange;
                  break;
                }
              }
            }
          } catch (e) {
            // Continue to next contents
          }
        }

        // If we didn't find it in contents, fall back to book.getRange()
        if (!range || !contents) {
          book.getRange(cfiRange).then(function (bookRange) {
            var allContents2 = rendition.getContents();
            var contents2 = null;

            if (bookRange && bookRange.startContainer) {
              var rangeDoc = bookRange.startContainer.ownerDocument;
              for (var j = 0; j < allContents2.length; j++) {
                try {
                  if (allContents2[j].document === rangeDoc) {
                    contents2 = allContents2[j];
                    break;
                  }
                } catch (e) {
                  // Continue
                }
              }
            }

            if (!contents2 && allContents2.length > 0) {
              contents2 = allContents2[0];
            }

            if (contents2 && bookRange) {
              selectAnnotationRangeHelper(contents2, bookRange);
            }
          }).catch(function (e) {
            console.error('Error getting range for annotation:', e);
          });
          return;
        }

        // We found the range, select it
        selectAnnotationRangeHelper(contents, range);

      } catch (e) {
        console.error('Error in markClicked handler:', e);
      }
    }

    // Helper function to programmatically select the range
    // This will trigger the selection event with the correct rect
    function selectAnnotationRangeHelper(contents, range) {
      try {
        var selection = contents.window.getSelection();
        if (selection && range) {
          // Clear existing selection
          selection.removeAllRanges();
          // Select the annotation range - this will trigger the selection event
          selection.addRange(range);
        }
      } catch (e) {
        console.error('Error selecting annotation range:', e);
      }
    }
  })

  book.ready.then(function () {
    book.locations.generate(1600).then(() => {
      // Handle initial position after locations are generated
      // XPath takes precedence over CFI
      if (initialXPath && !initialXPathProcessed) {
        initialXPathProcessed = true; // Mark as processed to prevent multiple calls
        initialPositionLoading = true; // Mark that we're loading initial position
        // Notify parent app that initial position loading has started
        try {
          window.flutter_inappwebview.callHandler('initialPositionLoading', { type: 'xpath' });
        } catch (e) {
          console.error('Error calling initialPositionLoading callback:', e);
        }
        xpathToCfi(initialXPath).then(function (convertedCfi) {
          if (convertedCfi && !xpathDisplayInProgress) {
            xpathDisplayInProgress = true; // Mark as in progress
            // Wait for the initial display to complete, then navigate to the XPath location
            // Use the displayed promise if available, or wait a bit
            var displayPromise = displayed;
            if (displayPromise && typeof displayPromise.then === 'function') {
              displayPromise.then(function () {
                setTimeout(function () {
                  if (xpathDisplayInProgress) { // Double-check flag
                    try {
                      rendition.display(convertedCfi);
                      xpathDisplayInProgress = false; // Mark as complete
                    } catch (e) {
                      console.error('Error displaying converted CFI:', e);
                      xpathDisplayInProgress = false; // Reset on error
                    }
                  }
                }, 50);
              }).catch(function (e) {
                console.error('Error waiting for initial display:', e);
                // Try anyway after a delay
                setTimeout(function () {
                  if (xpathDisplayInProgress) { // Double-check flag
                    try {
                      rendition.display(convertedCfi);
                      xpathDisplayInProgress = false; // Mark as complete
                    } catch (e2) {
                      console.error('Error displaying converted CFI after delay:', e2);
                      xpathDisplayInProgress = false; // Reset on error
                    }
                  }
                }, 200);
              });
            } else {
              // No promise, just wait a bit
              setTimeout(function () {
                if (xpathDisplayInProgress) { // Double-check flag
                  try {
                    rendition.display(convertedCfi);
                    xpathDisplayInProgress = false; // Mark as complete
                  } catch (e) {
                    console.error('Error displaying converted CFI:', e);
                    xpathDisplayInProgress = false; // Reset on error
                  }
                }
              }, 200);
            }
          } else {
            console.warn('Failed to convert XPath to CFI, falling back to CFI or default');
            if (cfi) {
              rendition.display(cfi);
              // initialPositionLoading flag will be cleared when "displayed" event fires
            } else {
              // No CFI fallback, clear the loading flag immediately
              initialPositionLoading = false;
              window.flutter_inappwebview.callHandler('initialPositionLoaded');
            }
          }
          window.flutter_inappwebview.callHandler('locationLoaded');
        }).catch(function (e) {
          console.error('Error converting XPath to CFI in ready:', e);
          if (cfi) {
            rendition.display(cfi);
            // initialPositionLoading flag will be cleared when "displayed" event fires
          } else {
            // No CFI fallback, clear the loading flag immediately
            initialPositionLoading = false;
            window.flutter_inappwebview.callHandler('initialPositionLoaded');
          }
          window.flutter_inappwebview.callHandler('locationLoaded');
        });
      } else if (cfi) {
        // CFI callback was already fired when we did the initial display above
        // Just ensure locationLoaded is called
        window.flutter_inappwebview.callHandler('locationLoaded');
      } else {
        window.flutter_inappwebview.callHandler('locationLoaded');
      }
    })
  })

  rendition.hooks.content.register((contents) => {
    var doc = contents.document;
    if (!doc) return;

    // Track touch positions to detect horizontal swipes
    var touchStartX = null;
    var touchStartY = null;
    var currentTouchX = null;
    var currentTouchY = null;
    var hasMoved = false; // Track if touch has moved significantly (swipe vs tap)
    var touchStartTime = null; // Track when touch started

    // Helper function to calculate normalized touch coordinates (0-1 range)
    // Uses the same logic as selection coordinate calculation
    function getNormalizedTouchCoordinates(touchEvent) {
      try {
        if (!touchEvent.touches || touchEvent.touches.length === 0) {
          return null;
        }

        var touch = touchEvent.touches[0];
        // Touch coordinates are relative to the iframe viewport (same as selection clientRect)
        var clientX = touch.clientX;
        var clientY = touch.clientY;

        // Get the WebView dimensions (parent window)
        var webViewWidth = window.innerWidth;
        var webViewHeight = window.innerHeight;

        // Get the iframe element in the parent document
        var iframe = contents.document.defaultView.frameElement;
        if (!iframe) {
          // Fallback: use clientX/Y directly if no iframe
          return {
            x: clientX / webViewWidth,
            y: clientY / webViewHeight
          };
        }

        var iframeRect = iframe.getBoundingClientRect();

        // Calculate absolute position in WebView (iframe offset + touch position)
        // Same logic as selection: absoluteLeft = iframeRect.left + clientRect.left
        var absoluteX = iframeRect.left + clientX;
        var absoluteY = iframeRect.top + clientY;

        // Normalize to 0-1 range relative to WebView dimensions
        return {
          x: absoluteX / webViewWidth,
          y: absoluteY / webViewHeight
        };
      } catch (e) {
        console.error('Error calculating touch coordinates:', e);
        return null;
      }
    }

    // Helper function to get normalized coordinates from changedTouches (for touchend)
    // Uses the same logic as selection coordinate calculation
    function getNormalizedTouchCoordinatesFromChanged(touchEvent) {
      try {
        if (!touchEvent.changedTouches || touchEvent.changedTouches.length === 0) {
          return null;
        }

        var touch = touchEvent.changedTouches[0];
        // Touch coordinates are relative to the iframe viewport (same as selection clientRect)
        var clientX = touch.clientX;
        var clientY = touch.clientY;

        // Get the WebView dimensions (parent window)
        var webViewWidth = window.innerWidth;
        var webViewHeight = window.innerHeight;

        // Get the iframe element in the parent document
        var iframe = contents.document.defaultView.frameElement;
        if (!iframe) {
          // Fallback: use clientX/Y directly if no iframe
          return {
            x: clientX / webViewWidth,
            y: clientY / webViewHeight
          };
        }

        var iframeRect = iframe.getBoundingClientRect();

        // Calculate absolute position in WebView (iframe offset + touch position)
        // Same logic as selection: absoluteLeft = iframeRect.left + clientRect.left
        var absoluteX = iframeRect.left + clientX;
        var absoluteY = iframeRect.top + clientY;

        // Normalize to 0-1 range relative to WebView dimensions
        return {
          x: absoluteX / webViewWidth,
          y: absoluteY / webViewHeight
        };
      } catch (e) {
        console.error('Error calculating touch coordinates:', e);
        return null;
      }
    }

    // Helper function to safely call flutter_inappwebview handler
    // On iOS, window.flutter_inappwebview might not be available in iframe context
    // Try parent window as fallback
    function callFlutterHandler(handlerName, ...args) {
      try {
        if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
          window.flutter_inappwebview.callHandler(handlerName, ...args);
          return true;
        }
      } catch (err) {
        // Try parent window as fallback (for iOS iframe context)
        try {
          if (window.parent && window.parent !== window && window.parent.flutter_inappwebview && window.parent.flutter_inappwebview.callHandler) {
            window.parent.flutter_inappwebview.callHandler(handlerName, ...args);
            return true;
          }
        } catch (parentErr) {
          // Ignore parent window errors
        }
      }
      return false;
    }

    // Helper function to get normalized coordinates from parent window perspective (for iOS fallback)
    // When called from parent window event, touch.clientX/Y are already relative to parent window
    function getNormalizedTouchCoordinatesFromParent(touchEvent) {
      try {
        var touch = null;
        if (touchEvent.touches && touchEvent.touches.length > 0) {
          touch = touchEvent.touches[0];
        } else if (touchEvent.changedTouches && touchEvent.changedTouches.length > 0) {
          touch = touchEvent.changedTouches[0];
        }
        if (!touch) return null;

        // Get parent window dimensions
        var parentWindow = window.parent && window.parent !== window ? window.parent : window;
        var webViewWidth = parentWindow.innerWidth;
        var webViewHeight = parentWindow.innerHeight;

        // When called from parent window event listener, touch.clientX/Y are already in parent window coordinates
        // So we can normalize directly
        return {
          x: touch.clientX / webViewWidth,
          y: touch.clientY / webViewHeight
        };
      } catch (e) {
        console.error('Error calculating touch coordinates from parent: ', e);
        return null;
      }
    }

    // Block horizontal swipe gestures when there's a selection
    // This must be done at the document level in capture phase to intercept early
    // Use { passive: false } to allow preventDefault() to work
    var touchStartHandler = function (e) {
      // Fire onTouchDown callback with normalized coordinates FIRST (before any preventDefault)
      var touchCoords = null;
      try {
        var coords = getNormalizedTouchCoordinates(e);
        if (coords) {
          touchCoords = coords;
          // Store tap coordinates for later checking in selectionchange
          lastTapCoords = coords;
          callFlutterHandler('onTouchDown', coords.x, coords.y);
        }
      } catch (err) {
        // Ignore errors in callback
      }

      if (hasActiveSelection()) {
        // Store initial touch position and time to detect if this is a tap or swipe
        if (e.touches && e.touches.length > 0) {
          touchStartX = e.touches[0].clientX;
          touchStartY = e.touches[0].clientY;
          currentTouchX = touchStartX;
          currentTouchY = touchStartY;
          touchStartTime = Date.now();
          hasMoved = false; // Reset movement flag
        }
        // Don't preventDefault yet - wait to see if it's a tap or swipe
      } else {
        // Track for normal swipe detection
        if (e.touches && e.touches.length > 0) {
          touchStartX = e.touches[0].clientX;
          touchStartY = e.touches[0].clientY;
          currentTouchX = touchStartX;
          currentTouchY = touchStartY;
          touchStartTime = Date.now();
          hasMoved = false;
        }
      }
    };

    // Attach to iframe document
    doc.addEventListener('touchstart', touchStartHandler, { capture: true, passive: false });

    // Also attach to parent window as fallback for iOS
    // On iOS, touch events in iframes may not fire, so we also listen on the parent window
    try {
      if (window.parent && window.parent !== window && window.parent.document) {
        // Get iframe element from parent document
        var iframe = contents.document.defaultView.frameElement;
        if (iframe) {
          window.parent.document.addEventListener('touchstart', function (e) {
            // Only handle if touch is within iframe bounds
            try {
              var iframeRect = iframe.getBoundingClientRect();
              var touch = e.touches && e.touches.length > 0 ? e.touches[0] : null;
              if (touch) {
                var touchX = touch.clientX;
                var touchY = touch.clientY;
                // Check if touch is within iframe bounds
                if (touchX >= iframeRect.left && touchX <= iframeRect.right &&
                  touchY >= iframeRect.top && touchY <= iframeRect.bottom) {
                  // Calculate normalized coordinates (touch is already in parent window coordinates)
                  var coords = getNormalizedTouchCoordinatesFromParent(e);
                  if (coords) {
                    lastTapCoords = coords;
                    callFlutterHandler('onTouchDown', coords.x, coords.y);
                  }
                }
              }
            } catch (err) {
              // Ignore errors in event handler
            }
          }, { capture: true, passive: false });
        }
      }
    } catch (err) {
      // Ignore errors when accessing parent window (cross-origin restrictions)
    }

    doc.addEventListener('touchmove', function (e) {
      if (hasActiveSelection()) {
        // Update position
        if (e.touches && e.touches.length > 0 && touchStartX !== null) {
          currentTouchX = e.touches[0].clientX;
          currentTouchY = e.touches[0].clientY;

          var deltaX = Math.abs(currentTouchX - touchStartX);
          var deltaY = Math.abs(currentTouchY - touchStartY);

          // If there's significant movement (more than 10px), it's a swipe - block it
          if (deltaX > 10 || deltaY > 10) {
            hasMoved = true;
            // Block horizontal swipes completely
            if (deltaX > 30 && deltaX > deltaY * 1.5) {
              e.preventDefault();
              e.stopPropagation();
              e.stopImmediatePropagation();
              return false;
            }
            // Also block if it's a significant horizontal movement (even if not strictly horizontal)
            if (deltaX > 50) {
              e.preventDefault();
              e.stopPropagation();
              e.stopImmediatePropagation();
              return false;
            }
          }
        }
      } else {
        // Update current position for normal swipe detection
        if (e.touches && e.touches.length > 0) {
          currentTouchX = e.touches[0].clientX;
          currentTouchY = e.touches[0].clientY;
        }
      }
    }, { capture: true, passive: false }); // Use options object with passive: false

    var touchEndHandler = function (e) {
      // Fire onTouchUp callback with normalized coordinates
      var tapCoords = null;
      try {
        var coords = getNormalizedTouchCoordinatesFromChanged(e);
        if (coords) {
          tapCoords = coords;
          callFlutterHandler('onTouchUp', coords.x, coords.y);
        }
      } catch (err) {
        // Ignore errors in callback
      }

      if (hasActiveSelection()) {
        // Check if this was a tap (no significant movement) or a swipe
        if (touchStartX !== null && currentTouchX !== null && touchStartTime !== null) {
          var deltaX = Math.abs(currentTouchX - touchStartX);
          var deltaY = Math.abs(currentTouchY - touchStartY);
          var touchDuration = Date.now() - touchStartTime;

          // If there was minimal movement (< 10px) and short duration (< 300ms), it's a tap
          if (!hasMoved && deltaX < 10 && deltaY < 10 && touchDuration < 300) {
            // Simple tap - allow normal behavior
          } else if (deltaX > 30 && deltaX > deltaY * 1.5) {
            // It was a horizontal swipe - block it
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
            return false;
          } else if (deltaX > 50) {
            // Significant horizontal movement - block it
            e.preventDefault();
            e.stopPropagation();
            e.stopImmediatePropagation();
            return false;
          }
        }
      }
      // Reset tracking
      touchStartX = null;
      touchStartY = null;
      currentTouchX = null;
      currentTouchY = null;
      hasMoved = false;
      touchStartTime = null;
      // Keep lastTapCoords for longer to allow click handler and selectionchange to check it
      // Clear after a longer delay to handle quick taps
      setTimeout(function () {
        lastTapCoords = null;
      }, 500);
    };

    // Attach to iframe document
    doc.addEventListener('touchend', touchEndHandler, { capture: true, passive: false });

    // Also attach to parent window as fallback for iOS
    // On iOS, touch events in iframes may not fire, so we also listen on the parent window
    try {
      if (window.parent && window.parent !== window && window.parent.document) {
        // Get iframe element from parent document (same as touchstart)
        var iframe = contents.document.defaultView.frameElement;
        if (iframe) {
          window.parent.document.addEventListener('touchend', function (e) {
            // Only handle if touch is within iframe bounds
            try {
              var iframeRect = iframe.getBoundingClientRect();
              var touch = e.changedTouches && e.changedTouches.length > 0 ? e.changedTouches[0] : null;
              if (touch) {
                var touchX = touch.clientX;
                var touchY = touch.clientY;
                // Check if touch is within iframe bounds
                if (touchX >= iframeRect.left && touchX <= iframeRect.right &&
                  touchY >= iframeRect.top && touchY <= iframeRect.bottom) {
                  // Calculate normalized coordinates (touch is already in parent window coordinates)
                  var coords = getNormalizedTouchCoordinatesFromParent(e);
                  if (coords) {
                    callFlutterHandler('onTouchUp', coords.x, coords.y);
                  }
                }
              }
            } catch (err) {
              // Ignore errors in event handler
            }
          }, { capture: true, passive: false });
        }
      }
    } catch (err) {
      // Ignore errors when accessing parent window (cross-origin restrictions)
    }

    if (useCustomSwipe) {
      const el = contents.document.documentElement;

      if (el) {
        detectSwipe(el, function (el, direction) {
          // Block swipes if there's an active selection
          if (hasActiveSelection()) {
            console.log('Blocked swipe - selection active, direction:', direction);
            return;
          }

          if (direction == 'l') {
            // Double-check before calling
            if (!hasActiveSelection()) {
              rendition.next();
            }
          }
          if (direction == 'r') {
            // Double-check before calling
            if (!hasActiveSelection()) {
              rendition.prev();
            }
          }
        });
      }
    }

    // Block epub.js built-in click/tap navigation when there's a selection
    // epub.js typically handles clicks on the left/right sides of the page
    try {
      if (doc) {
        // Helper function to check if event is in navigation zone and should be blocked
        function shouldBlockNavigation(e) {
          if (!hasActiveSelection()) {
            return false;
          }

          // Don't block if clicking on links or interactive elements
          var target = e.target;
          if (target && target.tagName &&
            target.tagName.toLowerCase() !== 'a' &&
            target.tagName.toLowerCase() !== 'button' &&
            !target.closest('a') &&
            !target.closest('button')) {
            // Get click/touch position
            var clickX = null;
            if (e.clientX !== undefined) {
              clickX = e.clientX;
            } else if (e.touches && e.touches.length > 0) {
              clickX = e.touches[0].clientX;
            } else if (e.changedTouches && e.changedTouches.length > 0) {
              clickX = e.changedTouches[0].clientX;
            }

            if (clickX !== null) {
              var pageWidth = doc.documentElement.clientWidth || window.innerWidth;
              var leftThird = pageWidth / 3;
              var rightThird = pageWidth * 2 / 3;

              // Block navigation clicks/taps in left/right thirds when selection is active
              if (clickX < leftThird || clickX > rightThird) {
                return true;
              }
            }
          }
          return false;
        }

        // Intercept click events to prevent navigation when selection is active
        doc.addEventListener('click', function (e) {
          // Block navigation clicks if needed
          if (shouldBlockNavigation(e)) {
            e.preventDefault();
            e.stopPropagation();
            return false;
          }
        }, { capture: true, passive: false }); // Use options object with passive: false

        // Also intercept touch events for mobile devices (backup)
        // But only block if it's in navigation zone AND not a simple tap
        doc.addEventListener('touchend', function (e) {
          // Check if this was a simple tap
          var wasSimpleTap = false;
          if (touchStartX !== null && currentTouchX !== null && touchStartTime !== null) {
            var deltaX = Math.abs(currentTouchX - touchStartX);
            var deltaY = Math.abs(currentTouchY - touchStartY);
            var touchDuration = Date.now() - touchStartTime;
            wasSimpleTap = (!hasMoved && deltaX < 10 && deltaY < 10 && touchDuration < 300);
          }

          // Only block navigation if it's NOT a simple tap
          if (!wasSimpleTap && shouldBlockNavigation(e)) {
            e.preventDefault();
            e.stopPropagation();
            return false;
          }
        }, { capture: true, passive: false }); // Use options object with passive: false
      }
    } catch (e) {
      // Ignore errors
    }
  });
  rendition.themes.fontSize(fontSize + "px");
  //set background and foreground color
  updateTheme(backgroundColor, foregroundColor);
}

window.addEventListener("flutterInAppWebViewPlatformReady", function (event) {
  window.flutter_inappwebview.callHandler('readyToLoad');
});

// Global touch event handlers for iOS compatibility
// On iOS, touch events in iframes may not fire, so we also listen on the main document
(function () {
  // Helper function to safely call flutter_inappwebview handler
  function callFlutterHandlerGlobal(handlerName, ...args) {
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler(handlerName, ...args);
        return true;
      } else {
        // Debug: log if flutter_inappwebview is not available
        if (typeof console !== 'undefined' && console.log) {
          console.log('flutter_inappwebview not available when calling:', handlerName);
        }
      }
    } catch (err) {
      if (typeof console !== 'undefined' && console.error) {
        console.error('Error calling flutter handler:', err);
      }
    }
    return false;
  }

  // Helper function to get normalized coordinates from main window
  function getNormalizedCoordinatesFromMainWindow(touchEvent, isTouchEnd) {
    try {
      var touch = null;
      if (isTouchEnd) {
        touch = touchEvent.changedTouches && touchEvent.changedTouches.length > 0 ? touchEvent.changedTouches[0] : null;
      } else {
        touch = touchEvent.touches && touchEvent.touches.length > 0 ? touchEvent.touches[0] : null;
      }
      if (!touch) return null;

      var webViewWidth = window.innerWidth;
      var webViewHeight = window.innerHeight;

      // Get viewer element to check if touch is within bounds
      var viewer = document.getElementById('viewer');
      if (!viewer) {
        // If no viewer element, normalize directly to WebView
        return {
          x: touch.clientX / webViewWidth,
          y: touch.clientY / webViewHeight
        };
      }

      var viewerRect = viewer.getBoundingClientRect();

      // Check if touch is within viewer bounds (with small tolerance for edge cases)
      var touchX = touch.clientX;
      var touchY = touch.clientY;
      var tolerance = 5; // 5px tolerance
      if (touchX < viewerRect.left - tolerance || touchX > viewerRect.right + tolerance ||
        touchY < viewerRect.top - tolerance || touchY > viewerRect.bottom + tolerance) {
        return null; // Touch is outside viewer
      }

      // Clamp coordinates to viewer bounds
      var clampedX = Math.max(viewerRect.left, Math.min(viewerRect.right, touchX));
      var clampedY = Math.max(viewerRect.top, Math.min(viewerRect.bottom, touchY));

      // Calculate position relative to viewer
      var relativeX = clampedX - viewerRect.left;
      var relativeY = clampedY - viewerRect.top;

      // Normalize to 0-1 range relative to viewer dimensions
      // This matches the coordinate system used by the iframe-based handlers
      var normalizedX = relativeX / viewerRect.width;
      var normalizedY = relativeY / viewerRect.height;

      // However, we need to account for the viewer's position in the WebView
      // If the viewer doesn't fill the entire WebView, we need to adjust
      // For now, let's assume the viewer fills most of the WebView and use viewer-relative coordinates
      // But actually, the iframe handlers normalize to WebView, so we should too
      // Let's calculate absolute position in WebView
      var absoluteX = clampedX / webViewWidth;
      var absoluteY = clampedY / webViewHeight;

      return {
        x: absoluteX,
        y: absoluteY
      };
    } catch (e) {
      if (typeof console !== 'undefined' && console.error) {
        console.error('Error calculating coordinates from main window:', e);
      }
      return null;
    }
  }

  // Track if we've already fired touch events to avoid duplicates
  var lastTouchDownTime = 0;
  var lastTouchUpTime = 0;
  var TOUCH_DEBOUNCE_MS = 50; // Prevent duplicate events within 50ms

  // Touch event handler function
  function handleTouchStart(e) {
    try {
      if (typeof console !== 'undefined' && console.log) {
        console.log('TOUCHSTART FIRED on', e.target, 'touches:', e.touches ? e.touches.length : 0);
      }
      var coords = getNormalizedCoordinatesFromMainWindow(e, false);
      if (coords) {
        var now = Date.now();
        // Only fire if enough time has passed since last event (debounce)
        if (now - lastTouchDownTime > TOUCH_DEBOUNCE_MS) {
          lastTouchDownTime = now;
          // Debug log for iOS
          if (typeof console !== 'undefined' && console.log) {
            console.log('Global touchstart - calling onTouchDown:', coords.x, coords.y);
          }
          callFlutterHandlerGlobal('onTouchDown', coords.x, coords.y);
        }
      } else {
        if (typeof console !== 'undefined' && console.log) {
          console.log('Touchstart: coords calculation returned null');
        }
      }
    } catch (err) {
      // Debug log errors
      if (typeof console !== 'undefined' && console.error) {
        console.error('Error in global touchstart handler:', err);
      }
    }
  }

  function handleTouchEnd(e) {
    try {
      if (typeof console !== 'undefined' && console.log) {
        console.log('TOUCHEND FIRED on', e.target, 'changedTouches:', e.changedTouches ? e.changedTouches.length : 0);
      }
      var coords = getNormalizedCoordinatesFromMainWindow(e, true);
      if (coords) {
        var now = Date.now();
        // Only fire if enough time has passed since last event (debounce)
        if (now - lastTouchUpTime > TOUCH_DEBOUNCE_MS) {
          lastTouchUpTime = now;
          // Debug log for iOS
          if (typeof console !== 'undefined' && console.log) {
            console.log('Global touchend - calling onTouchUp:', coords.x, coords.y);
          }
          callFlutterHandlerGlobal('onTouchUp', coords.x, coords.y);
        }
      } else {
        if (typeof console !== 'undefined' && console.log) {
          console.log('Touchend: coords calculation returned null');
        }
      }
    } catch (err) {
      // Debug log errors
      if (typeof console !== 'undefined' && console.error) {
        console.error('Error in global touchend handler:', err);
      }
    }
  }

  // Try multiple attachment points for maximum compatibility
  // 1. Document (capture phase)
  document.addEventListener('touchstart', handleTouchStart, { capture: true, passive: true });
  document.addEventListener('touchend', handleTouchEnd, { capture: true, passive: true });

  // 2. Document (bubble phase)
  document.addEventListener('touchstart', handleTouchStart, { capture: false, passive: true });
  document.addEventListener('touchend', handleTouchEnd, { capture: false, passive: true });

  // 3. Window
  window.addEventListener('touchstart', handleTouchStart, { capture: true, passive: true });
  window.addEventListener('touchend', handleTouchEnd, { capture: true, passive: true });

  // 4. Body element (when available)
  if (document.body) {
    document.body.addEventListener('touchstart', handleTouchStart, { capture: true, passive: true });
    document.body.addEventListener('touchend', handleTouchEnd, { capture: true, passive: true });
  } else {
    // Wait for body to be available
    document.addEventListener('DOMContentLoaded', function () {
      if (document.body) {
        document.body.addEventListener('touchstart', handleTouchStart, { capture: true, passive: true });
        document.body.addEventListener('touchend', handleTouchEnd, { capture: true, passive: true });
      }
    });
  }

  // 5. Also try pointer events as fallback (iOS 13+)
  function handlePointerDown(e) {
    try {
      if (typeof console !== 'undefined' && console.log) {
        console.log('POINTERDOWN FIRED:', e.pointerType, e.clientX, e.clientY);
      }
      if (e.pointerType === 'touch' || e.pointerType === '') {
        var webViewWidth = window.innerWidth;
        var webViewHeight = window.innerHeight;
        var coords = {
          x: e.clientX / webViewWidth,
          y: e.clientY / webViewHeight
        };
        var now = Date.now();
        if (now - lastTouchDownTime > TOUCH_DEBOUNCE_MS) {
          lastTouchDownTime = now;
          if (typeof console !== 'undefined' && console.log) {
            console.log('PointerDown - calling onTouchDown:', coords.x, coords.y);
          }
          callFlutterHandlerGlobal('onTouchDown', coords.x, coords.y);
        }
      }
    } catch (err) {
      if (typeof console !== 'undefined' && console.error) {
        console.error('Error in pointerdown handler:', err);
      }
    }
  }

  function handlePointerUp(e) {
    try {
      if (typeof console !== 'undefined' && console.log) {
        console.log('POINTERUP FIRED:', e.pointerType, e.clientX, e.clientY);
      }
      if (e.pointerType === 'touch' || e.pointerType === '') {
        var webViewWidth = window.innerWidth;
        var webViewHeight = window.innerHeight;
        var coords = {
          x: e.clientX / webViewWidth,
          y: e.clientY / webViewHeight
        };
        var now = Date.now();
        if (now - lastTouchUpTime > TOUCH_DEBOUNCE_MS) {
          lastTouchUpTime = now;
          if (typeof console !== 'undefined' && console.log) {
            console.log('PointerUp - calling onTouchUp:', coords.x, coords.y);
          }
          callFlutterHandlerGlobal('onTouchUp', coords.x, coords.y);
        }
      }
    } catch (err) {
      if (typeof console !== 'undefined' && console.error) {
        console.error('Error in pointerup handler:', err);
      }
    }
  }

  document.addEventListener('pointerdown', handlePointerDown, { capture: true, passive: true });
  document.addEventListener('pointerup', handlePointerUp, { capture: true, passive: true });
  window.addEventListener('pointerdown', handlePointerDown, { capture: true, passive: true });
  window.addEventListener('pointerup', handlePointerUp, { capture: true, passive: true });

  // Debug: Log that listeners are attached
  if (typeof console !== 'undefined' && console.log) {
    console.log('Global touch/pointer event listeners attached');
    console.log('window.flutter_inappwebview available:', !!(window.flutter_inappwebview && window.flutter_inappwebview.callHandler));
  }
})();

// Helper function to check if there's an active text selection (global version)
function hasActiveSelection() {
  // Check our tracking variables first
  if (isSelecting || lastCfiRange) {
    return true;
  }

  // Also check actual DOM selection across all content frames
  try {
    if (typeof rendition !== 'undefined' && rendition) {
      var allContents = rendition.getContents();
      for (var i = 0; i < allContents.length; i++) {
        try {
          var contents = allContents[i];
          if (contents.window && contents.window.getSelection) {
            var selection = contents.window.getSelection();
            if (selection && selection.rangeCount > 0) {
              var range = selection.getRangeAt(0);
              var selectedText = selection.toString();
              if (selectedText && range && !range.collapsed) {
                return true;
              }
            }
          }
        } catch (e) {
          // Ignore errors for this content frame
        }
      }

      // Also check parent window selection
      if (window.getSelection) {
        var parentSelection = window.getSelection();
        if (parentSelection && parentSelection.rangeCount > 0) {
          var parentRange = parentSelection.getRangeAt(0);
          var parentText = parentSelection.toString();
          if (parentText && parentRange && !parentRange.collapsed) {
            return true;
          }
        }
      }
    }
  } catch (e) {
    // Ignore errors
  }

  return false;
}

// Store original rendition methods to override them
var originalNext = null;
var originalPrev = null;
var originalDisplay = null;

// Override rendition methods to block when selection exists
function setupRenditionBlocking() {
  if (typeof rendition !== 'undefined' && rendition && !originalNext) {
    // Store original methods
    originalNext = rendition.next.bind(rendition);
    originalPrev = rendition.prev.bind(rendition);
    originalDisplay = rendition.display.bind(rendition);

    // Override next()
    rendition.next = function () {
      if (hasActiveSelection()) {
        console.log('Blocked next() - selection active');
        return Promise.resolve(rendition.location);
      }
      return originalNext();
    };

    // Override prev()
    rendition.prev = function () {
      if (hasActiveSelection()) {
        console.log('Blocked prev() - selection active');
        return Promise.resolve(rendition.location);
      }
      return originalPrev();
    };

    // Override display() - this is what actually changes the page
    rendition.display = function (cfi) {
      if (hasActiveSelection()) {
        console.log('Blocked display() - selection active, cfi:', cfi);
        return Promise.resolve(rendition.location);
      }
      return originalDisplay(cfi);
    };
  }
}

//move to next page
function next() {
  // Block navigation if there's an active selection
  if (hasActiveSelection()) {
    console.log('Blocked next() - selection active');
    return;
  }
  if (rendition) {
    rendition.next();
  }
}

//move to previous page
function previous() {
  // Block navigation if there's an active selection
  if (hasActiveSelection()) {
    console.log('Blocked previous() - selection active');
    return;
  }
  if (rendition) {
    rendition.prev();
  }
}

//move to given cfi location or xpath
function toCfi(cfiOrXPath) {
  // Check if it looks like an XPath (starts with /)
  if (cfiOrXPath && cfiOrXPath.startsWith('/')) {
    xpathToCfi(cfiOrXPath).then(function (convertedCfi) {
      if (convertedCfi) {
        rendition.display(convertedCfi);
      } else {
        console.error('Failed to convert XPath to CFI:', cfiOrXPath);
      }
    }).catch(function (e) {
      console.error('Error converting XPath to CFI:', e);
    });
  } else {
    // Treat as CFI
    rendition.display(cfiOrXPath);
  }
}

//get all chapters
function getChapters() {
  return chapters;
}

async function getBookInfo() {
  const metadata = book.package.metadata;
  metadata['coverImage'] = book.cover;
  return metadata;
}

function getCurrentLocation() {
  var percent = rendition.location.start.percentage;
  percent = parseFloat(percent);

  // Convert CFIs to XPath
  return Promise.all([
    cfiToXPath(rendition.location.start.cfi),
    cfiToXPath(rendition.location.end.cfi)
  ]).then(function (xpaths) {
    const args = {
      startCfi: rendition.location.start.cfi,
      endCfi: rendition.location.end.cfi,
      startXpath: xpaths[0],
      endXpath: xpaths[1],
      progress: percent
    };
    window.flutter_inappwebview.callHandler("currentLocation", args);
  }).catch(function (e) {
    // If XPath conversion fails, still return CFI
    const args = {
      startCfi: rendition.location.start.cfi,
      endCfi: rendition.location.end.cfi,
      startXpath: null,
      endXpath: null,
      progress: percent
    };
    window.flutter_inappwebview.callHandler("currentLocation", args);
  });
}

///parsing chapters and subitems recursively
var parseChapters = function (toc) {
  var chapters = []
  toc.forEach(function (chapter) {
    chapters.push({
      title: chapter.label,
      href: chapter.href,
      id: chapter.id,
      subitems: parseChapters(chapter.subitems)
    })
  })
  return chapters;
}

function searchInBook(query) {
  search(query).then(function (data) {
    // Convert each search result's CFI to XPath
    var xpathPromises = data.map(function (result) {
      return cfiToXPath(result.cfi).then(function (xpath) {
        return {
          cfi: result.cfi,
          excerpt: result.excerpt,
          xpath: xpath
        };
      }).catch(function (e) {
        // If XPath conversion fails, still return CFI
        return {
          cfi: result.cfi,
          excerpt: result.excerpt,
          xpath: null
        };
      });
    });

    Promise.all(xpathPromises).then(function (resultsWithXpath) {
      var args = [resultsWithXpath]
      window.flutter_inappwebview.callHandler('search', ...args);
    }).catch(function (e) {
      // If all conversions fail, still send original data
      var args = [data]
      window.flutter_inappwebview.callHandler('search', ...args);
    });
  })
}


// adds highlight with given color
function addHighlight(cfiRange, color, opacity) {
  rendition.annotations.highlight(cfiRange, {}, (e) => {
    // Highlight clicked handler (can be extended if needed)
  }, "hl", { "fill": color, "fill-opacity": '0.3', "mix-blend-mode": "multiply" });
}

function addUnderLine(cfiString) {
  rendition.annotations.underline(cfiString)
}

function addMark(cfiString) {
  rendition.annotations.mark(cfiString)
}

function removeHighlight(cfiString) {
  rendition.annotations.remove(cfiString, "highlight");
}

function removeUnderLine(cfiString) {
  rendition.annotations.remove(cfiString, "underline");
}

function removeMark(cfiString) {
  rendition.annotations.remove(cfiString, "mark");
}

function clearSelection() {
  // Deliberate clear: the margin-drag guard must not resurrect it.
  suppressSelectionGuard = true;
  lastGoodSelection = null;
  selectionBlowUpAt = 0;
  setTimeout(function () { suppressSelectionGuard = false; }, 500);
  try {
    if (typeof rendition !== 'undefined' && rendition) {
      // Clear selection in all content frames (iframes)
      rendition.getContents().forEach(function (contents) {
        try {
          if (contents.window.getSelection) {
            contents.window.getSelection().removeAllRanges();
          }
        } catch (e) {
          // Ignore errors if iframe is not accessible
        }
      });

      // Also clear selection in parent window as fallback
      if (window.getSelection) {
        window.getSelection().removeAllRanges();
      }

      // Notify Flutter that selection was cleared - only if we've actually sent a selection
      if (hasSentSelection && (isSelecting || lastCfiRange) && window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        isSelecting = false;
        lastCfiRange = null;
        hasSentSelection = false;
        if (selectionTimeout) {
          clearTimeout(selectionTimeout);
          selectionTimeout = null;
        }
        window.flutter_inappwebview.callHandler('selectionCleared');
      }
    } else {
      // Fallback if rendition is not available
      if (window.getSelection) {
        window.getSelection().removeAllRanges();
      }
    }
  } catch (e) {
    console.error('Error clearing selection:', e);
  }
}

// Explicitly attach to window for global access
window.clearSelection = clearSelection;

function toProgress(progress) {
  var cfi = book.locations.cfiFromPercentage(progress);
  rendition.display(cfi);
}


function search(q) {
  return Promise.all(
    book.spine.spineItems.map(item => item.load(book.load.bind(book)).then(item.find.bind(item, q)).finally(item.unload.bind(item)))
  ).then(results => Promise.resolve([].concat.apply([], results)));
};

function setSpread(spread) {
  rendition.spread(spread);
}

function setFlow(flow) {
  rendition.flow(flow);
}

function setManager(manager) {
  rendition.manager(manager);
}

// ══════════════════════════════════════════════════════════════
// Auto-scroll: rolling blind
//
// The text never moves. The next page is rendered into its own stacked
// rendition and revealed from the top down, so by the time the eye gets back
// to the top of the screen it is already reading the next page. Stopping
// retracts the blind, leaving the current page whole.
//
// The blind rendition is deliberately dumb: no selection wiring, no highlight
// forwarding, no location reporting. Only the live rendition below it owns
// reading position, or auto-scroll would quietly corrupt saved progress.
// ══════════════════════════════════════════════════════════════

var blindRendition = null;
var blindY = 0;              // how far down the blind has come, px
var blindSpeed = 40;         // px per second
var blindRaf = null;
var blindLastTs = 0;
var blindSwapping = false;
var blindPaused = false;   // the reader asked for it, survives touches
var blindTouchHold = false; // finger is down, transient

function blindHeight() {
  var host = document.getElementById("viewerNext");
  if (host && host.offsetHeight) return host.offsetHeight;
  return window.innerHeight || document.documentElement.clientHeight || 0;
}

// The blind has to occupy the live viewer's exact box. #viewer sits in a
// centred flex body with margins, so a full-screen blind paginates at a
// different width and its "next page" is not the live rendition's next page.
function blindMatchViewerBox() {
  var live = document.getElementById("viewer");
  var host = document.getElementById("viewerNext");
  if (!live || !host) return;
  var r = live.getBoundingClientRect();
  host.style.left = r.left + "px";
  host.style.top = r.top + "px";
  host.style.width = r.width + "px";
  host.style.height = r.height + "px";
}

// The line has to read on white, black, grey and cream alike, so it borrows
// the page's own text colour - whatever contrasts with that theme's background
// by definition - rather than a fixed grey that washes out on the light ones.
var blindLineRgb = null;

function blindResolveLineColor() {
  blindLineRgb = null;
  try {
    var contents = rendition.getContents();
    if (contents && contents.length) {
      var doc = contents[0].document;
      var col = contents[0].window.getComputedStyle(doc.body).color;
      var m = col && col.match(/rgba?\((\d+)[,\s]+(\d+)[,\s]+(\d+)/);
      if (m) blindLineRgb = m[1] + ", " + m[2] + ", " + m[3];
    }
  } catch (e) {}
}

function blindLineColor(paused) {
  var rgb = blindLineRgb || "150, 150, 150";
  return "rgba(" + rgb + ", " + (paused ? 0.95 : 0.45) + ")";
}

function blindApply() {
  var host = document.getElementById("viewerNext");
  if (!host) return;
  var h = blindHeight();
  var y = Math.max(0, Math.min(h, blindY));
  host.style.clipPath = "inset(0px 0px " + (h - y) + "px 0px)";
  host.style.webkitClipPath = "inset(0px 0px " + (h - y) + "px 0px)";
  var line = document.getElementById("blindLine");
  if (line) {
    if (y <= 0.5 || y >= h - 0.5) {
      line.style.display = "none";
    } else {
      var box = host.getBoundingClientRect();
      line.style.display = "block";
      line.style.left = box.left + "px";
      line.style.width = box.width + "px";
      line.style.top = (box.top + y) + "px";
      // Frozen white while paused, so the stopped edge is unmistakable.
      line.style.height = blindPaused ? "3px" : "2px";
      line.style.background = blindLineColor(blindPaused);
    }
  }
}

// Mirror whatever the live rendition actually has, rather than rebuilding it
// from remembered arguments. Themes get registered, selected and overridden
// from several places (load, theme change, font size), so a reconstruction
// drifts - copying the live objects cannot.
function blindThemeApply(r) {
  if (!r || !rendition) return;
  try {
    var liveThemes = rendition.themes;
    var name = liveThemes._current;
    var defs = liveThemes._themes || {};
    Object.keys(defs).forEach(function (key) {
      var def = defs[key];
      if (def && def.rules) r.themes.register(key, def.rules);
    });
    if (name && defs[name]) r.themes.select(name);
    // font-size and friends live in overrides, not in the theme rules
    var ov = liveThemes._overrides || {};
    Object.keys(ov).forEach(function (key) {
      var o = ov[key];
      if (o && typeof o.value !== "undefined") r.themes.override(key, o.value, o.priority);
    });
  } catch (e) {}
  // A downloadable font is an @font-face inside each iframe's own document,
  // so it has to be stamped into the blind's document too.
  try {
    if (window.__absorbApplyFontToDoc) {
      r.getContents().forEach(function (c) { window.__absorbApplyFontToDoc(c.document); });
    }
  } catch (e) {}
}

// ── Auto-scroll touch handling ──
// Lives here rather than in Flutter because the WebView is a platform view:
// a Flutter overlay never wins these touches, so taps and drags fell straight
// through to the live page and turned pages or selected text under the blind.

var blindTouchY = 0;
var blindTouchStartAt = 0;
var blindSpeedAtTouch = 0;
var blindTouchMoved = 0;
var BLIND_DRAG_SLOP = 12;      // px before a touch counts as a speed drag
var BLIND_LONG_PRESS_MS = 550; // hold this long to stop instead of pause
// A 200px drag moves the speed about a fifth of its range. It used to be two
// thirds, which made 5% to 12% a flick of the thumb.
var BLIND_DRAG_GAIN = 45;
// Android's gesture nav lives along the bottom edge. A swipe up from there is
// the system's, not ours - claiming it sent the speed to 100% and resumed.
var BLIND_SYS_GESTURE_PX = 56;
var blindLongPressTimer = null;
var blindTouchIgnored = false;
var blindLongPressFired = false;

function blindNotify(name, value) {
  try {
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler(name, value);
    }
  } catch (e) {}
}

function blindTouchStart(e) {
  var t = e.touches ? e.touches[0] : e;
  // Leave the system gesture strip alone - no preventDefault, no speed change,
  // so swiping up for recents or home behaves like it does everywhere else.
  var h = window.innerHeight || document.documentElement.clientHeight || 0;
  if (h && t.clientY > h - BLIND_SYS_GESTURE_PX) {
    blindTouchIgnored = true;
    return;
  }
  blindTouchIgnored = false;
  blindTouchHold = true;
  blindTouchY = t.clientY;
  blindTouchStartAt = Date.now();
  blindSpeedAtTouch = blindSpeed;
  blindTouchMoved = 0;
  blindLongPressFired = false;
  if (blindLongPressTimer) clearTimeout(blindLongPressTimer);
  blindLongPressTimer = setTimeout(function () {
    if (blindTouchMoved < 8) {
      blindLongPressFired = true;
      blindNotify("absorbAutoScrollLongPress", true);
    }
  }, BLIND_LONG_PRESS_MS);
  e.preventDefault();
}

function blindTouchMove(e) {
  if (blindTouchIgnored) return;
  var t = e.touches ? e.touches[0] : e;
  var dy = blindTouchY - t.clientY;
  if (Math.abs(dy) > blindTouchMoved) blindTouchMoved = Math.abs(dy);
  if (blindTouchMoved >= BLIND_DRAG_SLOP && blindLongPressTimer) {
    clearTimeout(blindLongPressTimer);
    blindLongPressTimer = null;
  }
  if (blindLongPressFired) return;
  // Below the slop this is a tap being held, not a drag. Without this a
  // one-pixel wobble opened the speed toast and nudged the speed.
  if (blindTouchMoved < BLIND_DRAG_SLOP) {
    e.preventDefault();
    return;
  }
  // up = faster, and 200px of travel covers most of the range
  var next = blindSpeedAtTouch + (dy / 200) * BLIND_DRAG_GAIN;
  next = Math.max(6, Math.min(220, next));
  blindSpeed = next;
  blindNotify("absorbAutoScrollSpeed", next);
  blindNotify("absorbAutoScrollDragging", true);
  e.preventDefault();
}

function blindTouchEnd(e) {
  if (blindTouchIgnored) {
    blindTouchIgnored = false;
    blindTouchHold = false;
    return;
  }
  if (blindLongPressTimer) {
    clearTimeout(blindLongPressTimer);
    blindLongPressTimer = null;
  }
  if (blindLongPressFired) {
    blindLongPressFired = false;
    return;
  }
  var quick = Date.now() - blindTouchStartAt < BLIND_LONG_PRESS_MS;
  blindTouchHold = false;
  if (quick && blindTouchMoved < BLIND_DRAG_SLOP) {
    // Flutter decides what a tap means - with the reader's control bars up it
    // dismisses those instead of pausing.
    blindNotify("absorbAutoScrollTap", true);
  } else {
    blindNotify("absorbAutoScrollDragEnd", true);
  }
  if (e && e.preventDefault) e.preventDefault();
}

// The system stealing a gesture (nav swipe, notification shade) arrives here.
// Put the speed back where it was and just resume - it was never our gesture.
function blindTouchCancel(e) {
  if (blindLongPressTimer) {
    clearTimeout(blindLongPressTimer);
    blindLongPressTimer = null;
  }
  blindLongPressFired = false;
  blindTouchIgnored = false;
  if (blindTouchMoved >= BLIND_DRAG_SLOP) {
    blindSpeed = blindSpeedAtTouch;
    blindNotify("absorbAutoScrollSpeed", blindSpeed);
  }
  blindNotify("absorbAutoScrollDragEnd", true);
  blindTouchHold = false;
  blindApply();
}

function blindTouchAttach() {
  var pad = document.getElementById("autoScrollTouch");
  if (!pad) return;
  pad.style.display = "block";
  pad.addEventListener("touchstart", blindTouchStart, {passive: false});
  pad.addEventListener("touchmove", blindTouchMove, {passive: false});
  pad.addEventListener("touchend", blindTouchEnd, {passive: false});
  pad.addEventListener("touchcancel", blindTouchCancel, {passive: false});
  pad.addEventListener("mousedown", blindTouchStart);
  pad.addEventListener("mousemove", function (e) { if (blindTouchHold) blindTouchMove(e); });
  pad.addEventListener("mouseup", blindTouchEnd);
  pad.addEventListener("click", blindSwallow, true);
  pad.addEventListener("pointerdown", blindSwallow, true);
  pad.addEventListener("pointerup", blindSwallow, true);
}

function blindSwallow(e) {
  e.preventDefault();
  e.stopPropagation();
}

function blindTouchDetach() {
  var pad = document.getElementById("autoScrollTouch");
  if (!pad) return;
  pad.removeEventListener("touchstart", blindTouchStart);
  pad.removeEventListener("touchmove", blindTouchMove);
  pad.removeEventListener("touchend", blindTouchEnd);
  pad.removeEventListener("touchcancel", blindTouchCancel);
  pad.removeEventListener("click", blindSwallow, true);
  pad.removeEventListener("pointerdown", blindSwallow, true);
  pad.removeEventListener("pointerup", blindSwallow, true);
  pad.style.display = "none";
}

// epub.js resolves display() before its manager has finished laying the
// section out in columns, and next() on an unlaid-out manager quietly does
// nothing - which left the blind showing the live page. Give layout a couple
// of frames, then advance, then confirm it actually moved and retry if not.
function blindFrames(n) {
  return new Promise(function (resolve) {
    var left = n;
    (function step() {
      if (left-- <= 0) return resolve();
      requestAnimationFrame(step);
    })();
  });
}

function blindCfiOf(r) {
  try {
    var loc = r.currentLocation();
    return loc && loc.start ? loc.start.cfi : null;
  } catch (e) {
    return null;
  }
}

// "Different CFI" is too weak a test: the blind could move and still show the
// same text, because a page is a span and two different positions can sit
// inside one visible page. The real question is whether the blind starts at or
// after where the live page ends, which epub.js can answer positionally.
function blindIsAhead() {
  try {
    var live = rendition.currentLocation();
    var blind = blindRendition.currentLocation();
    if (!live || !live.end || !blind || !blind.start) return false;
    var cmp = new ePub.CFI().compare(blind.start.cfi, live.end.cfi);
    return cmp >= 0;
  } catch (e) {
    var a = blindCfiOf(blindRendition);
    var b = blindCfiOf(rendition);
    return !!(a && b && a !== b);
  }
}

// Advance the blind until its first visible position is past the live page's
// last one, confirming each step rather than trusting next() to have worked.
function blindAdvancePastLive(attempt) {
  attempt = attempt || 0;
  if (!blindRendition) return Promise.resolve();
  var before = blindCfiOf(blindRendition);
  return blindFrames(2)
    .then(function () { return blindRendition.next(); })
    .then(function () { return blindFrames(1); })
    .then(function () {
      var moved = blindCfiOf(blindRendition) !== before;
      if (blindIsAhead() || attempt >= 5) return;
      // Not moving at all means layout still is not ready; give it longer.
      return blindFrames(moved ? 0 : 3)
        .then(function () { return blindAdvancePastLive(attempt + 1); });
    });
}

function autoScrollStart(speed) {
  if (!rendition || blindRendition) return;
  if (typeof speed === "number" && speed > 0) blindSpeed = speed;
  var host = document.getElementById("viewerNext");
  if (!host) return;
  host.style.display = "block";
  blindMatchViewerBox();
  if (lastTheme.bg && lastTheme.bg !== "null") host.style.background = lastTheme.bg;
  // A live selection makes rendition.next() a no-op (setupRenditionBlocking),
  // which would leave the reader stuck on one page for the whole run.
  try { clearSelection(); } catch (e) {}
  blindY = 0;
  blindApply();
  blindTouchAttach();
  blindResolveLineColor();
  blindPaused = false;
  var liveRendition = rendition;
  blindRendition = book.renderTo("viewerNext", lastRenderOpts);
  window.__absorbBlindRendition = blindRendition;
  try {
    blindRendition.hooks.content.register(function (contents) {
      if (window.__absorbApplyFontToDoc) window.__absorbApplyFontToDoc(contents.document);
    });
  } catch (e) {}
  // renderTo points book.rendition at whatever it just made - epub.js internals
  // still expect the live one.
  book.rendition = liveRendition;
  blindThemeApply(blindRendition);
  var loc = rendition.currentLocation();
  var cfi = loc && loc.start ? loc.start.cfi : null;
  blindRendition.on("rendered", function () { blindThemeApply(blindRendition); });
  Promise.resolve(cfi ? blindRendition.display(cfi) : blindRendition.display())
    .then(function () { return blindAdvancePastLive(0); })
    .then(function () {
      blindThemeApply(blindRendition);
      blindLastTs = 0;
      blindRaf = requestAnimationFrame(blindTick);
    })
    .catch(function () { autoScrollStop(); });
}

function blindTick(ts) {
  if (!blindRendition) return;
  if (!blindLastTs) blindLastTs = ts;
  var dt = (ts - blindLastTs) / 1000;
  blindLastTs = ts;
  // rAF stops while the app is away; the first frame back carries the whole gap
  if (dt > 0.25) dt = 0;
  if (!blindPaused && !blindTouchHold && !blindSwapping) {
    blindY += blindSpeed * dt;
    var h = blindHeight();
    if (blindY >= h) {
      blindY = h;
      blindApply();
      blindSwap();
    } else {
      blindApply();
    }
  }
  blindRaf = requestAnimationFrame(blindTick);
}

// The blind is fully open here, so the screen is already showing the next page.
// Advancing the live rendition underneath it is therefore invisible, and the
// blind can snap back to zero before it fetches the page after that.
function blindSwap() {
  blindSwapping = true;
  try { clearSelection(); } catch (e) {}
  Promise.resolve(rendition.next())
    // next() resolving does not mean the live page has painted. Retracting the
    // blind on that promise showed the old page for a frame, which read as a
    // page turn. Hold the blind up until the live page is actually there.
    .then(function () { return blindFrames(2); })
    .then(function () {
      blindY = 0;
      blindApply();
      return blindAdvancePastLive(0);
    })
    .then(function () {
      blindThemeApply(blindRendition);
      blindSwapping = false;
    })
    .catch(function () { autoScrollStop(); });
}

window.addEventListener("resize", function () {
  if (blindRendition) {
    blindMatchViewerBox();
    autoScrollResync();
  }
});

function autoScrollSpeed(speed) {
  if (typeof speed === "number" && speed >= 0) blindSpeed = speed;
}

function autoScrollPause(paused) {
  blindPaused = !!paused;
  blindApply();
}

// Re-seat the blind on the page after the live one. Used when the live
// rendition moves for any reason other than our own swap - a font size change,
// a manual page turn, a jump from the table of contents.
function autoScrollResync() {
  if (!blindRendition || !rendition) return;
  blindSwapping = true;
  blindY = 0;
  blindApply();
  var loc = rendition.currentLocation();
  var cfi = loc && loc.start ? loc.start.cfi : null;
  Promise.resolve(cfi ? blindRendition.display(cfi) : blindRendition.display())
    .then(function () { return blindAdvancePastLive(0); })
    .then(function () { blindSwapping = false; })
    .catch(function () { autoScrollStop(); });
}

function autoScrollStop() {
  blindTouchHold = false;
  if (blindRaf) cancelAnimationFrame(blindRaf);
  blindRaf = null;
  blindLastTs = 0;
  blindSwapping = false;
  blindPaused = false;
  blindY = 0;
  var line = document.getElementById("blindLine");
  if (line) line.style.display = "none";
  var host = document.getElementById("viewerNext");
  if (host) {
    host.style.clipPath = "inset(0px 0px 100% 0px)";
    host.style.webkitClipPath = "inset(0px 0px 100% 0px)";
    host.style.display = "none";
  }
  if (blindRendition) {
    try { blindRendition.destroy(); } catch (e) {}
    blindRendition = null;
  }
  window.__absorbBlindRendition = null;
  if (host) host.innerHTML = "";
  blindTouchDetach();
}

function autoScrollActive() {
  return blindRendition !== null;
}

function setFontSize(fontSize) {
  lastTheme.fontSize = fontSize;
  rendition.themes.fontSize(`${fontSize}px`);
  rendition.reportLocation();
  if (blindRendition) autoScrollResync();
}

//get current page text
function getCurrentPageText() {
  var startCfi = rendition.location.start.cfi
  var endCfi = rendition.location.end.cfi
  var cfiRange = makeRangeCfi(startCfi, endCfi)
  book.getRange(cfiRange).then(function (range) {
    var text = range.toString();
    // Convert CFI range to XPath
    cfiRangeToXPath(cfiRange).then(function (xpathRange) {
      var args = [text, cfiRange, xpathRange]
      window.flutter_inappwebview.callHandler('epubText', ...args);
    }).catch(function (e) {
      // If XPath conversion fails, still send CFI
      var args = [text, cfiRange, null]
      window.flutter_inappwebview.callHandler('epubText', ...args);
    });
  })
}

//get text from a range
function getTextFromCfi(startCfi, endCfi) {
  var cfiRange = makeRangeCfi(startCfi, endCfi)
  book.getRange(cfiRange).then(function (range) {
    var text = range.toString();
    // Convert CFI range to XPath
    cfiRangeToXPath(cfiRange).then(function (xpathRange) {
      var args = [text, cfiRange, xpathRange]
      window.flutter_inappwebview.callHandler('epubText', ...args);
    }).catch(function (e) {
      // If XPath conversion fails, still send CFI
      var args = [text, cfiRange, null]
      window.flutter_inappwebview.callHandler('epubText', ...args);
    });
  })
}

///update theme
function updateTheme(backgroundColor, foregroundColor, customCss) {
  lastTheme.bg = backgroundColor;
  lastTheme.fg = foregroundColor;
  lastTheme.css = customCss;
  var host = document.getElementById("viewerNext");
  if (host && backgroundColor && backgroundColor !== "null") {
    host.style.background = backgroundColor;
  }
  if (blindRendition) {
    blindThemeApply(blindRendition);
    blindResolveLineColor();
  }
  var rules = buildThemeRules(backgroundColor, foregroundColor, customCss);

  // Update theme if there are rules
  if (Object.keys(rules).length > 0) {
    rendition.themes.register("user-theme", rules);
    rendition.themes.select("user-theme");
  }
}

// Shared by the live rendition and the auto-scroll blind. The blind used to
// build its own cut-down version and lost customCss, which is where the
// reader's font lives - so the incoming page came in with the wrong typeface.
function buildThemeRules(backgroundColor, foregroundColor, customCss) {
  var rules = {};
  var themeObj = {};
  if (backgroundColor && backgroundColor !== "" && backgroundColor !== "null") {
    themeObj["background"] = backgroundColor;
  }
  if (foregroundColor && foregroundColor !== "" && foregroundColor !== "null") {
    themeObj["color"] = foregroundColor;
  }
  if (Object.keys(themeObj).length > 0) {
    rules["body"] = themeObj;
  }
  if (customCss && customCss !== "null" && typeof customCss === "object") {
    Object.assign(rules, customCss);
  }
  return rules;
}

const makeRangeCfi = (a, b) => {
  const CFI = new ePub.CFI()
  const start = CFI.parse(a), end = CFI.parse(b)
  const cfi = {
    range: true,
    base: start.base,
    path: {
      steps: [],
      terminal: null
    },
    start: start.path,
    end: end.path
  }
  const len = cfi.start.steps.length
  for (let i = 0; i < len; i++) {
    if (CFI.equalStep(cfi.start.steps[i], cfi.end.steps[i])) {
      if (i == len - 1) {
        // Last step is equal, check terminals
        if (cfi.start.terminal === cfi.end.terminal) {
          // CFI's are equal
          cfi.path.steps.push(cfi.start.steps[i])
          // Not a range
          cfi.range = false
        }
      } else cfi.path.steps.push(cfi.start.steps[i])
    } else break
  }
  cfi.start.steps = cfi.start.steps.slice(cfi.path.steps.length)
  cfi.end.steps = cfi.end.steps.slice(cfi.path.steps.length)

  return 'epubcfi(' + CFI.segmentString(cfi.base)
    + '!' + CFI.segmentString(cfi.path)
    + ',' + CFI.segmentString(cfi.start)
    + ',' + CFI.segmentString(cfi.end)
    + ')'
}

// Convert a DOM node to XPath
function getXPath(node) {
  if (node.nodeType === Node.DOCUMENT_NODE) {
    return '/';
  }

  if (node.nodeType === Node.TEXT_NODE) {
    var parent = node.parentNode;
    var xpath = getXPath(parent);
    var index = 1;
    var sibling = node.previousSibling;
    while (sibling) {
      if (sibling.nodeType === Node.TEXT_NODE && sibling.nodeName === node.nodeName) {
        index++;
      }
      sibling = sibling.previousSibling;
    }
    return xpath + '/text()[' + index + ']';
  }

  if (node.nodeType === Node.ELEMENT_NODE) {
    var parts = [];
    var current = node;

    while (current && current.nodeType === Node.ELEMENT_NODE) {
      var index = 1;
      var sibling = current.previousSibling;
      while (sibling) {
        if (sibling.nodeType === Node.ELEMENT_NODE && sibling.nodeName === current.nodeName) {
          index++;
        }
        sibling = sibling.previousSibling;
      }

      var tagName = current.nodeName.toLowerCase();
      var xpathSegment = tagName + '[' + index + ']';

      // Add ID if available for more precise targeting
      if (current.id) {
        xpathSegment = tagName + '[@id="' + current.id + '"]';
      }

      parts.unshift(xpathSegment);
      current = current.parentNode;
    }

    return '/' + parts.join('/');
  }

  return '';
}

// Convert CFI to XPath/XPointer
// Returns a promise that resolves to an XPointer string or null if conversion fails
function cfiToXPath(cfiString) {
  if (!cfiString) {
    return Promise.resolve(null);
  }

  try {
    var cfi = new ePub.CFI(cfiString);
    var spineIndex = cfi.spinePos;

    // Get the spine item
    var spineItem = book.spine.get(spineIndex);
    if (!spineItem) {
      return Promise.resolve(null);
    }

    // Load the item and convert CFI to Range
    return spineItem.load(book.load.bind(book)).then(function () {
      try {
        var range = cfi.toRange(spineItem.document);
        if (!range) {
          return null;
        }

        // Build XPath from the range
        var startXPath = getXPath(range.startContainer);
        var endXPath = getXPath(range.endContainer);

        // Convert to KoReader format: /body/DocFragment[N]/body/...
        // Extract the path after /html[N]/body[N] and prepend /body/DocFragment[N]/body
        function convertToKoReaderFormat(xpath, offset) {
          // Match /html[N]/body[N] and extract the rest
          var match = xpath.match(/^\/html\[\d+\]\/body\[\d+\](.*)$/);
          if (match) {
            var elementPath = match[1] || '';
            // Convert /text()[1] to /text() for KoReader format
            elementPath = elementPath.replace(/\/text\(\)\[\d+\]$/, '/text()');
            // DocFragment index is spineIndex + 1 (1-based)
            var docFragmentIndex = spineIndex + 1;
            // Build KoReader format: /body/DocFragment[N]/body/...
            var koreaderPath = '/body/DocFragment[' + docFragmentIndex + ']/body' + elementPath;
            // Add offset for text nodes
            if (offset !== undefined && offset !== null) {
              koreaderPath += '.' + offset;
            }
            return koreaderPath;
          }
          // If format doesn't match, return original with offset
          if (offset !== undefined && offset !== null) {
            return xpath + '.' + offset;
          }
          return xpath;
        }

        // Add offset for text nodes and convert to KoReader format
        var startOffset = null;
        var endOffset = null;
        if (range.startContainer.nodeType === Node.TEXT_NODE) {
          startOffset = range.startOffset;
        }
        if (range.endContainer.nodeType === Node.TEXT_NODE) {
          endOffset = range.endOffset;
        }

        var startXPathKoReader = convertToKoReaderFormat(startXPath, startOffset);
        var endXPathKoReader = convertToKoReaderFormat(endXPath, endOffset);

        // Format as XPointer: /body/DocFragment[1]/body/div[2]/p[3]/text().123
        // For ranges, we return start and end separated by comma
        if (startXPathKoReader === endXPathKoReader && startOffset === endOffset) {
          return startXPathKoReader;
        } else {
          return startXPathKoReader + ',' + endXPathKoReader;
        }
      } catch (e) {
        console.error('Error converting CFI to XPath:', e);
        return null;
      }
    }).catch(function (e) {
      console.error('Error loading spine item for CFI conversion:', e);
      return null;
    });
  } catch (e) {
    console.error('Error parsing CFI:', e);
    return Promise.resolve(null);
  }
}

// Helper to convert CFI range to XPath range
function cfiRangeToXPath(cfiRangeString) {
  if (!cfiRangeString) {
    return Promise.resolve(null);
  }

  try {
    // Parse the CFI range to extract start and end CFIs
    var cfi = new ePub.CFI(cfiRangeString);
    var spineIndex = cfi.spinePos;

    var spineItem = book.spine.get(spineIndex);
    if (!spineItem) {
      return Promise.resolve(null);
    }

    return spineItem.load(book.load.bind(book)).then(function () {
      try {
        var range = cfi.toRange(spineItem.document);
        if (!range) {
          return null;
        }

        var startXPath = getXPath(range.startContainer);
        var endXPath = getXPath(range.endContainer);

        // Convert to KoReader format: /body/DocFragment[N]/body/...
        function convertToKoReaderFormat(xpath, offset) {
          // Match /html[N]/body[N] and extract the rest
          var match = xpath.match(/^\/html\[\d+\]\/body\[\d+\](.*)$/);
          if (match) {
            var elementPath = match[1] || '';
            // Convert /text()[1] to /text() for KoReader format
            elementPath = elementPath.replace(/\/text\(\)\[\d+\]$/, '/text()');
            // DocFragment index is spineIndex + 1 (1-based)
            var docFragmentIndex = spineIndex + 1;
            // Build KoReader format: /body/DocFragment[N]/body/...
            var koreaderPath = '/body/DocFragment[' + docFragmentIndex + ']/body' + elementPath;
            // Add offset for text nodes
            if (offset !== undefined && offset !== null) {
              koreaderPath += '.' + offset;
            }
            return koreaderPath;
          }
          // If format doesn't match, return original with offset
          if (offset !== undefined && offset !== null) {
            return xpath + '.' + offset;
          }
          return xpath;
        }

        // Add offset for text nodes and convert to KoReader format
        var startOffset = null;
        var endOffset = null;
        if (range.startContainer.nodeType === Node.TEXT_NODE) {
          startOffset = range.startOffset;
        }
        if (range.endContainer.nodeType === Node.TEXT_NODE) {
          endOffset = range.endOffset;
        }

        var startXPathKoReader = convertToKoReaderFormat(startXPath, startOffset);
        var endXPathKoReader = convertToKoReaderFormat(endXPath, endOffset);

        if (startXPathKoReader === endXPathKoReader && startOffset === endOffset) {
          return startXPathKoReader;
        } else {
          return startXPathKoReader + ',' + endXPathKoReader;
        }
      } catch (e) {
        console.error('Error converting CFI range to XPath:', e);
        return null;
      }
    }).catch(function (e) {
      console.error('Error loading spine item for CFI range conversion:', e);
      return null;
    });
  } catch (e) {
    console.error('Error parsing CFI range:', e);
    return Promise.resolve(null);
  }
}

// Convert XPath/XPointer to CFI
// Returns a promise that resolves to a CFI string or null if conversion fails
function xpathToCfi(xpathString) {
  if (!xpathString) {
    return Promise.resolve(null);
  }

  try {
    // Parse XPath - handle ranges (comma-separated) and offsets
    var parts = xpathString.split(',');
    var startXPath = parts[0].trim();
    var endXPath = parts.length > 1 ? parts[1].trim() : startXPath;

    // Extract offset from XPath if present (e.g., /path/to/text().123)
    var startOffset = 0;
    var endOffset = 0;
    var startXPathWithoutOffset = startXPath;
    var endXPathWithoutOffset = endXPath;

    var startOffsetMatch = startXPath.match(/\.(\d+)$/);
    if (startOffsetMatch) {
      startOffset = parseInt(startOffsetMatch[1]);
      startXPathWithoutOffset = startXPath.replace(/\.\d+$/, '');
    }

    var endOffsetMatch = endXPath.match(/\.(\d+)$/);
    if (endOffsetMatch) {
      endOffset = parseInt(endOffsetMatch[1]);
      endXPathWithoutOffset = endXPath.replace(/\.\d+$/, '');
    }

    // Extract DocFragment index if present (KoReader format: /body/DocFragment[9]/body/...)
    var docFragmentIndex = null;
    var docFragmentMatch = startXPathWithoutOffset.match(/\/DocFragment\[(\d+)\]/);
    if (docFragmentMatch) {
      docFragmentIndex = parseInt(docFragmentMatch[1]) - 1; // Convert to 0-based index
      // Remove /body/DocFragment[N]/ part, leaving /body/... or just the content path
      startXPathWithoutOffset = startXPathWithoutOffset.replace(/^\/body\/DocFragment\[\d+\]/, '');
    }

    // Try to find the node in each spine item (or just the specific one if DocFragment index was found)
    // Optimize: check sequentially and stop on first match to avoid loading all spine items
    var spineItemsToCheck = docFragmentIndex !== null
      ? [book.spine.spineItems[docFragmentIndex]].filter(function (item) { return item != null; })
      : book.spine.spineItems;

    // Optimize: if no DocFragment index, try to check currently displayed spine item first
    // Create a mapping to track original indices when reordering
    var indexMap = [];
    for (var mapIdx = 0; mapIdx < spineItemsToCheck.length; mapIdx++) {
      indexMap.push(mapIdx);
    }

    if (docFragmentIndex === null && rendition && rendition.location) {
      try {
        var currentLocation = rendition.location;
        if (currentLocation && currentLocation.start && currentLocation.start.index !== undefined) {
          var currentSpineIndex = currentLocation.start.index;
          if (currentSpineIndex >= 0 && currentSpineIndex < spineItemsToCheck.length) {
            // Check current spine item first by moving it to the front
            var currentItem = spineItemsToCheck[currentSpineIndex];
            var currentIndexInMap = indexMap[currentSpineIndex];
            spineItemsToCheck = [currentItem].concat(
              spineItemsToCheck.slice(0, currentSpineIndex),
              spineItemsToCheck.slice(currentSpineIndex + 1)
            );
            indexMap = [currentIndexInMap].concat(
              indexMap.slice(0, currentSpineIndex),
              indexMap.slice(currentSpineIndex + 1)
            );
          }
        }
      } catch (e) {
        // Silently fail - optimization is optional
      }
    }

    // Sequential check function that stops on first match
    function checkSpineItemSequentially(itemIndex) {
      if (itemIndex >= spineItemsToCheck.length) {
        // All items checked, no match found
        return Promise.resolve(null);
      }

      var item = spineItemsToCheck[itemIndex];
      // Use the mapped index to get the correct original spine index for CFI creation
      var index = docFragmentIndex !== null ? docFragmentIndex : indexMap[itemIndex];

      // Check if document is already loaded to avoid unnecessary loading
      var doc = item.document;
      var loadPromise = doc ? Promise.resolve() : item.load(book.load.bind(book));

      return loadPromise.then(function () {
        try {
          doc = item.document;
          if (!doc) {
            return null;
          }

          var startNode = null;
          var endNode = null;

          // Parse and resolve XPath manually (following Readest's approach)
          // This is more reliable than XPath evaluation in epub.js context
          function resolveXPointerPath(path) {
            var elementPath = '';
            var current = doc.body || doc.documentElement;

            if (!current) {
              return null;
            }

            // Handle empty path - return body element
            if (!path || path === '') {
              return current;
            }

            // Handle KoReader format: /body/DocFragment[N]/body/p[5]/text()
            var koreaderMatch = path.match(/^\/body\/DocFragment\[\d+\]\/body(.*)$/);
            if (koreaderMatch) {
              elementPath = koreaderMatch[1] || '';
            } else {
              // Handle our library's format: /html[1]/body[1]/p[1]/text()[1]
              var ourFormatMatch = path.match(/^\/html\[\d+\]\/body\[\d+\](.*)$/);
              if (ourFormatMatch) {
                elementPath = ourFormatMatch[1] || '';
              } else {
                // Try /body format
                var bodyMatch = path.match(/^\/body(.*)$/);
                if (bodyMatch) {
                  elementPath = bodyMatch[1] || '';
                } else {
                  // Try /html format
                  var htmlMatch = path.match(/^\/html\[\d+\](.*)$/);
                  if (htmlMatch) {
                    elementPath = htmlMatch[1] || '';
                  } else {
                    return null;
                  }
                }
              }
            }

            if (!elementPath || elementPath === '') {
              return current;
            }

            // Parse path segments (e.g., /p[5]/text() or /p[1]/text()[1] -> ['p[5]'] or ['p[1]', 'text()[1]'])
            var segments = elementPath.split('/').filter(function (s) { return s.length > 0; });

            for (var s = 0; s < segments.length; s++) {
              var segment = segments[s];

              // Handle text() or text()[1] - we'll handle this separately
              if (segment === 'text()' || segment.match(/^text\(\)\[\d+\]$/)) {
                break; // Stop here, current is the element containing the text
              }

              // Match tag[index] or just tag
              var segmentWithIndexMatch = segment.match(/^(\w+)\[(\d+)\]$/);
              var segmentWithoutIndexMatch = segment.match(/^(\w+)$/);

              var tagName = null;
              var index = 0;

              if (segmentWithIndexMatch) {
                tagName = segmentWithIndexMatch[1].toLowerCase();
                index = parseInt(segmentWithIndexMatch[2], 10) - 1; // Convert to 0-based
              } else if (segmentWithoutIndexMatch) {
                tagName = segmentWithoutIndexMatch[1].toLowerCase();
                index = 0;
              } else {
                return null;
              }

              // Find children with matching tag name
              var children = Array.from(current.children || []).filter(function (child) {
                return child.nodeType === Node.ELEMENT_NODE &&
                  child.tagName.toLowerCase() === tagName;
              });

              if (index >= children.length) {
                return null;
              }

              current = children[index];
            }

            return current;
          }

          // Resolve the start element
          var startElement = resolveXPointerPath(startXPathWithoutOffset);
          var startOffsetInNode = startOffset; // Default to original offset

          if (startElement) {
            // Handle text offset if present
            // If we have an offset (including 0) or explicit /text() in path, treat it as text node offset
            // Empty path with offset means we're targeting text nodes within the resolved element
            var hasTextOffset = startXPathWithoutOffset.includes('/text()') ||
              (startOffset >= 0 && (startXPathWithoutOffset === '' || startXPathWithoutOffset === '/body'));

            if (hasTextOffset) {
              // Find text node at the specified offset
              var textNodes = [];
              var walker = doc.createTreeWalker(startElement, NodeFilter.SHOW_TEXT, null, false);
              var textNode;
              while (textNode = walker.nextNode()) {
                if (textNode.textContent && textNode.textContent.length > 0) {
                  textNodes.push(textNode);
                }
              }

              if (textNodes.length > 0) {
                // If offset is 0, use the first text node
                if (startOffset === 0) {
                  startNode = textNodes[0];
                  startOffsetInNode = 0;
                } else {
                  // Calculate cumulative offset to find the right text node
                  var currentOffset = 0;
                  var targetTextNode = null;
                  var offsetInNode = 0;

                  for (var t = 0; t < textNodes.length; t++) {
                    var tn = textNodes[t];
                    var nodeLength = tn.textContent ? tn.textContent.length : 0;

                    // If offset is within this text node's range
                    if (currentOffset + nodeLength > startOffset) {
                      targetTextNode = tn;
                      offsetInNode = startOffset - currentOffset;
                      break;
                    }

                    currentOffset += nodeLength;
                  }

                  if (targetTextNode) {
                    startNode = targetTextNode;
                    startOffsetInNode = offsetInNode;
                  } else {
                    // Offset beyond all text, use last text node
                    var lastNode = textNodes[textNodes.length - 1];
                    startNode = lastNode;
                    var lastLength = lastNode.textContent ? lastNode.textContent.length : 0;
                    startOffsetInNode = lastLength;
                  }
                }
              } else {
                // No text nodes found, use the element itself
                startNode = startElement;
                startOffsetInNode = 0;
              }
            } else {
              // No text offset, use the element itself
              startNode = startElement;
              startOffsetInNode = 0;
            }
          }

          // If manual resolution failed, try XPath evaluation as fallback
          if (!startNode) {
            // Build XPath variations to try
            var xpathVariations = [startXPathWithoutOffset];

            if (startXPathWithoutOffset.startsWith('/body/')) {
              xpathVariations.push('/html' + startXPathWithoutOffset);
              xpathVariations.push(startXPathWithoutOffset.replace(/^\/body\//, '/'));
            }

            try {
              for (var v = 0; v < xpathVariations.length && !startNode; v++) {
                var xpathToTry = xpathVariations[v];
                try {
                  var startResult = doc.evaluate(xpathToTry, doc, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null);
                  startNode = startResult.singleNodeValue;
                  if (startNode) {
                    break;
                  }
                } catch (e) {
                  // Try next variation
                }
              }
            } catch (e) {
              // XPath evaluation failed, continue
            }
          }

          // Resolve end node (same approach as start node)
          var endOffsetInNode = endOffset; // Default to original offset
          if (parts.length > 1) {
            var endElement = resolveXPointerPath(endXPathWithoutOffset);
            if (endElement) {
              // Handle text offset if present (same logic as start node)
              var hasEndTextOffset = endXPathWithoutOffset.includes('/text()') ||
                (endOffset >= 0 && (endXPathWithoutOffset === '' || endXPathWithoutOffset === '/body'));

              if (hasEndTextOffset) {
                var endTextNodes = [];
                var endWalker = doc.createTreeWalker(endElement, NodeFilter.SHOW_TEXT, null, false);
                var endTextNode;
                while (endTextNode = endWalker.nextNode()) {
                  if (endTextNode.textContent && endTextNode.textContent.length > 0) {
                    endTextNodes.push(endTextNode);
                  }
                }

                if (endTextNodes.length > 0) {
                  var endCurrentOffset = 0;
                  var endTargetTextNode = null;
                  var endOffsetInNodeCalc = 0;

                  for (var t = 0; t < endTextNodes.length; t++) {
                    var tn = endTextNodes[t];
                    var nodeLength = tn.textContent ? tn.textContent.length : 0;

                    if (endCurrentOffset + nodeLength >= endOffset) {
                      endTargetTextNode = tn;
                      endOffsetInNodeCalc = endOffset - endCurrentOffset;
                      break;
                    }

                    endCurrentOffset += nodeLength;
                  }

                  if (endTargetTextNode) {
                    endNode = endTargetTextNode;
                    endOffsetInNode = endOffsetInNodeCalc;
                  } else if (endTextNodes.length > 0) {
                    var lastEndNode = endTextNodes[endTextNodes.length - 1];
                    endNode = lastEndNode;
                    endOffsetInNode = lastEndNode.textContent ? lastEndNode.textContent.length : 0;
                  } else {
                    endNode = endElement;
                    endOffsetInNode = 0;
                  }
                } else {
                  endNode = endElement;
                  endOffsetInNode = 0;
                }
              } else {
                endNode = endElement;
                endOffsetInNode = 0;
              }
            }

            // Fallback to startNode if endNode not found
            if (!endNode && startNode) {
              endNode = startNode;
              endOffsetInNode = startOffsetInNode;
            }
          } else {
            endNode = startNode;
            endOffsetInNode = startOffsetInNode;
          }

          if (!startNode || !endNode) {
            console.error('Missing startNode or endNode. startNode:', startNode, 'endNode:', endNode);
            return null;
          }

          // Create a Range from the nodes
          try {
            var range = doc.createRange();

            if (startNode.nodeType === Node.TEXT_NODE) {
              var startTextLength = startNode.textContent ? startNode.textContent.length : 0;
              range.setStart(startNode, Math.min(startOffsetInNode, startTextLength));
            } else {
              range.setStart(startNode, 0);
            }

            if (endNode.nodeType === Node.TEXT_NODE) {
              var endTextLength = endNode.textContent ? endNode.textContent.length : 0;
              range.setEnd(endNode, Math.min(endOffsetInNode, endTextLength));
            } else {
              var endChildNodesLength = (endNode.childNodes && endNode.childNodes.length) || 0;
              range.setEnd(endNode, endChildNodesLength);
            }
          } catch (e) {
            console.error('Error creating range:', e);
            return null;
          }

          // Create CFI from the range
          var spineItem = book.spine.get(index);
          var cfiString = null;

          try {
            // Create CFI from range
            // epub.js CFI constructor needs the document to be in the book context
            var packageIndices = [6, 4];
            var created = false;

            // Check if range is valid
            if (!range || !range.startContainer || !range.endContainer) {
              console.error('Invalid range - missing containers');
              return null;
            }

            // Try creating CFI with base string directly (epub.js needs base)
            // The base format is /{packageIndex}/{spineIndex} where spineIndex is 1-based
            for (var p = 0; p < packageIndices.length && !created; p++) {
              try {
                var packageIndex = packageIndices[p];
                // epub.js uses even numbers for spine indices: 2, 4, 6, 8...
                // So spine index 8 (0-based) = 18 (2 * (8 + 1))
                var spineIndexCfi = (index + 1) * 2;
                var baseString = "/" + packageIndex + "/" + spineIndexCfi;

                var cfi = new ePub.CFI(range, baseString);
                var cfiStringWithoutBase = cfi.toString();

                // Parse it to verify
                var parsedCfi = new ePub.CFI(cfiStringWithoutBase);

                // If spinePos matches, use it
                if (parsedCfi.spinePos === index) {
                  cfiString = cfiStringWithoutBase;
                  created = true;
                  break;
                } else {
                  cfiString = null;
                }
              } catch (e) {
                cfiString = null;
              }
            }

            if (created && cfiString) {
              return cfiString;
            } else {
              console.error('Failed to create valid CFI with any package index');
              return null;
            }
          } catch (e) {
            console.error('Error creating CFI:', e);
            return null;
          }
        } catch (e) {
          console.error('Error creating CFI for spine item', index, ':', e);
          return null;
        }
      }).catch(function (e) {
        console.error('Error loading spine item', index, ':', e);
        return null;
      }).then(function (result) {
        // If we found a match, return it immediately
        if (result) {
          return result;
        }
        // Otherwise, check the next spine item
        return checkSpineItemSequentially(itemIndex + 1);
      });
    }

    // Start sequential checking from the first item
    return checkSpineItemSequentially(0).then(function (result) {
      if (!result) {
        console.warn('No CFI found for XPath:', xpathString);
      }
      return result;
    }).catch(function (e) {
      console.error('Error converting XPath to CFI:', e);
      return null;
    });
  } catch (e) {
    console.error('Error parsing XPath:', e);
    return Promise.resolve(null);
  }
}

// Block or unblock gestures using CSS touch-action when selection is active
function blockGesturesWhenSelected(block) {
  try {
    var styleId = 'epub-selection-block-style';
    var existingStyle = document.getElementById(styleId);

    if (block) {
      // Block horizontal panning/swiping when selection exists
      // Use 'pan-y' to allow vertical scrolling but block horizontal swipes
      // Also add 'manipulation' to prevent double-tap zoom which can interfere
      if (!existingStyle) {
        var style = document.createElement('style');
        style.id = styleId;
        style.textContent = `
          body, html, #viewer {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
            -webkit-touch-callout: none !important;
            user-select: text !important;
          }
          body *, html *, #viewer * {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
            user-select: text !important;
          }
          iframe {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
            pointer-events: auto !important;
          }
          /* Block all horizontal gestures on iframes */
          iframe[src], iframe[srcdoc] {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
          }
        `;
        document.head.appendChild(style);
      }

      // Function to apply touch-action to iframes
      function applyTouchActionToIframes() {
        try {
          var allIframes = document.querySelectorAll('iframe');
          allIframes.forEach(function (iframe) {
            iframe.style.touchAction = 'pan-y manipulation';
            iframe.style.setProperty('-ms-touch-action', 'pan-y manipulation', 'important');
            iframe.style.setProperty('touch-action', 'pan-y manipulation', 'important');
          });
        } catch (e) {
          console.error('Error setting iframe touch-action:', e);
        }

        // Also try to get iframes from epub.js rendition
        if (typeof rendition !== 'undefined' && rendition) {
          try {
            var allContents = rendition.getContents();
            allContents.forEach(function (contents) {
              try {
                // Get the iframe element from the parent document
                var iframe = contents.document.defaultView.frameElement;
                if (iframe && iframe.style) {
                  iframe.style.touchAction = 'pan-y manipulation';
                  iframe.style.setProperty('-ms-touch-action', 'pan-y manipulation', 'important');
                  iframe.style.setProperty('touch-action', 'pan-y manipulation', 'important');
                }
              } catch (e) {
                // Ignore errors - iframe might be sandboxed
              }
            });
          } catch (e) {
            // Ignore errors
          }
        }
      }

      // Apply immediately
      applyTouchActionToIframes();

      // Watch for new iframes being added (epub.js creates them dynamically)
      if (!window.epubIframeObserver) {
        window.epubIframeObserver = new MutationObserver(function (mutations) {
          applyTouchActionToIframes();
        });
        window.epubIframeObserver.observe(document.body || document.documentElement, {
          childList: true,
          subtree: true
        });
      }
    } else {
      // Remove blocking when selection is cleared
      if (existingStyle) {
        existingStyle.remove();
      }

      // Stop observing if observer exists
      if (window.epubIframeObserver) {
        window.epubIframeObserver.disconnect();
        window.epubIframeObserver = null;
      }

      // Reset iframe styles
      try {
        var allIframes = document.querySelectorAll('iframe');
        allIframes.forEach(function (iframe) {
          iframe.style.touchAction = '';
          iframe.style.removeProperty('-ms-touch-action');
          iframe.style.removeProperty('touch-action');
        });
      } catch (e) {
        // Ignore errors
      }

      // Reset epub.js iframe styles
      if (typeof rendition !== 'undefined' && rendition) {
        try {
          var allContents = rendition.getContents();
          allContents.forEach(function (contents) {
            try {
              var iframe = contents.document.defaultView.frameElement;
              if (iframe && iframe.style) {
                iframe.style.touchAction = '';
                iframe.style.removeProperty('-ms-touch-action');
                iframe.style.removeProperty('touch-action');
              }
            } catch (e) {
              // Ignore errors
            }
          });
        } catch (e) {
          // Ignore errors
        }
      }
    }
  } catch (e) {
    console.error('Error blocking gestures:', e);
  }
}

// Check selection after long press (for iPad support)
function checkSelectionAfterLongPress() {
  try {
    // Check all content frames
    if (typeof rendition !== 'undefined' && rendition) {
      var allContents = rendition.getContents();
      allContents.forEach(function (contents, idx) {
        try {
          var selection = contents.window.getSelection();
          if (selection && selection.rangeCount > 0) {
            var range = selection.getRangeAt(0);
            var text = selection.toString();
            if (text && range && !range.collapsed) {
              // Try to get CFI
              if (typeof contents.cfiFromRange === 'function') {
                try {
                  var cfiRange = contents.cfiFromRange(range);
                  if (cfiRange) {
                    // Store this CFI to track changes
                    window.lastProcessedCfi = cfiRange.toString();

                    // Call sendSelectionData if it exists (it should be globally available)
                    if (typeof window.sendSelectionData === 'function') {
                      try {
                        window.sendSelectionData(cfiRange, contents);
                      } catch (e) {
                        // Fallback to direct handler call with manual rect calculation
                        try {
                          var rect = null;
                          if (range) {
                            var clientRect = range.getBoundingClientRect();
                            var webViewWidth = window.innerWidth;
                            var webViewHeight = window.innerHeight;
                            var iframe = contents.document.defaultView.frameElement;
                            if (iframe) {
                              var iframeRect = iframe.getBoundingClientRect();
                              var absoluteLeft = iframeRect.left + clientRect.left;
                              var absoluteTop = iframeRect.top + clientRect.top;
                              rect = {
                                left: absoluteLeft / webViewWidth,
                                top: absoluteTop / webViewHeight,
                                width: clientRect.width / webViewWidth,
                                height: clientRect.height / webViewHeight,
                                contentHeight: webViewHeight
                              };
                            }
                          }
                          window.flutter_inappwebview.callHandler('selection', cfiRange.toString(), text, rect, null);
                        } catch (e2) {
                          window.flutter_inappwebview.callHandler('selection', cfiRange.toString(), text, null, null);
                        }
                      }
                    } else {
                      // Try to get rect manually as fallback
                      try {
                        var rect = null;
                        if (range) {
                          var clientRect = range.getBoundingClientRect();
                          var webViewWidth = window.innerWidth;
                          var webViewHeight = window.innerHeight;
                          var iframe = contents.document.defaultView.frameElement;
                          if (iframe) {
                            var iframeRect = iframe.getBoundingClientRect();
                            var absoluteLeft = iframeRect.left + clientRect.left;
                            var absoluteTop = iframeRect.top + clientRect.top;
                            rect = {
                              left: absoluteLeft / webViewWidth,
                              top: absoluteTop / webViewHeight,
                              width: clientRect.width / webViewWidth,
                              height: clientRect.height / webViewHeight,
                              contentHeight: webViewHeight
                            };
                          }
                        }
                        window.flutter_inappwebview.callHandler('selection', cfiRange.toString(), text, rect, null);
                      } catch (e) {
                        window.flutter_inappwebview.callHandler('selection', cfiRange.toString(), text, null, null);
                      }
                    }
                  }
                } catch (e) {
                  // Ignore errors
                }
              }
            }
          }
        } catch (e) {
          // Ignore errors
        }
      });

      // Also check parent window
      try {
        var parentSel = window.getSelection();
        if (parentSel && parentSel.rangeCount > 0) {
          var parentText = parentSel.toString();
          if (parentText) {
            // Try to match to a content frame
            allContents.forEach(function (contents, idx) {
              try {
                var range = parentSel.getRangeAt(0);
                if (range && !range.collapsed && typeof contents.cfiFromRange === 'function') {
                  var cfiRange = contents.cfiFromRange(range);
                  if (cfiRange) {
                    if (typeof window.sendSelectionData === 'function') {
                      window.sendSelectionData(cfiRange, contents);
                    } else {
                      window.flutter_inappwebview.callHandler('selection', cfiRange.toString(), parentText, null, null);
                    }
                  }
                }
              } catch (e) {
                // Try next frame
              }
            });
          }
        }
      } catch (e) {
        // Ignore errors
      }
    }
  } catch (e) {
    // Ignore errors
  }
}

// Check selection periodically (for tracking selection changes when handles are dragged)
function checkSelectionPeriodically() {
  try {
    if (typeof rendition !== 'undefined' && rendition) {
      var allContents = rendition.getContents();
      var foundSelection = false;
      allContents.forEach(function (contents, idx) {
        try {
          var selection = contents.window.getSelection();
          if (selection && selection.rangeCount > 0) {
            var range = selection.getRangeAt(0);
            var text = selection.toString();
            if (text && range && !range.collapsed) {
              foundSelection = true;
              // Check if this is a new/different selection
              if (typeof contents.cfiFromRange === 'function') {
                try {
                  var cfiRange = contents.cfiFromRange(range);
                  if (cfiRange) {
                    var cfiString = cfiRange.toString();
                    // Only process if CFI changed (selection was modified)
                    if (cfiString !== window.lastProcessedCfi) {
                      window.lastProcessedCfi = cfiString;
                      if (typeof window.sendSelectionData === 'function') {
                        window.sendSelectionData(cfiRange, contents);
                      }
                    }
                  }
                } catch (e) {
                  // Ignore errors
                }
              }
            }
          }
        } catch (e) {
          // Ignore errors
        }
      });

      // Also check parent window
      try {
        var parentSel = window.getSelection();
        if (parentSel && parentSel.rangeCount > 0) {
          var parentText = parentSel.toString();
          if (parentText) {
            foundSelection = true;
            var allContents = rendition.getContents();
            allContents.forEach(function (contents, idx) {
              try {
                var range = parentSel.getRangeAt(0);
                if (range && !range.collapsed && typeof contents.cfiFromRange === 'function') {
                  var cfiRange = contents.cfiFromRange(range);
                  if (cfiRange) {
                    var cfiString = cfiRange.toString();
                    if (cfiString !== window.lastProcessedCfi) {
                      window.lastProcessedCfi = cfiString;
                      if (typeof window.sendSelectionData === 'function') {
                        window.sendSelectionData(cfiRange, contents);
                      }
                    }
                  }
                }
              } catch (e) {
                // Try next frame
              }
            });
          }
        }
      } catch (e) {
        // Ignore
      }
    }
  } catch (e) {
    // Ignore errors
  }
}

// Check if selection still exists and re-apply blocking if needed
function checkSelectionAndReapplyBlocking() {
  try {
    // Check if selection still exists
    var hasSelection = false;

    if (typeof rendition !== 'undefined' && rendition) {
      var allContents = rendition.getContents();
      for (var i = 0; i < allContents.length; i++) {
        try {
          var contents = allContents[i];
          if (contents.window && contents.window.getSelection) {
            var selection = contents.window.getSelection();
            if (selection && selection.rangeCount > 0) {
              var range = selection.getRangeAt(0);
              var text = selection.toString();
              if ((text && text.length > 0) || (range && !range.collapsed)) {
                hasSelection = true;
                break;
              }
            }
          }
        } catch (e) {
          // Ignore errors
        }
      }
    }

    // Also check parent window
    if (!hasSelection && window.getSelection) {
      var parentSel = window.getSelection();
      if (parentSel && parentSel.rangeCount > 0) {
        var parentRange = parentSel.getRangeAt(0);
        var parentText = parentSel.toString();
        if ((parentText && parentText.length > 0) || (parentRange && !parentRange.collapsed)) {
          hasSelection = true;
        }
      }
    }

    // If selection exists, ensure blocking is still active
    if (hasSelection) {
      var styleId = 'epub-selection-block-style';
      var existingStyle = document.getElementById(styleId);

      if (!existingStyle) {
        // Re-apply blocking if it was removed - use 'pan-y manipulation' to block horizontal swipes
        var style = document.createElement('style');
        style.id = styleId;
        style.textContent = `
          body, html, #viewer {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
            -webkit-touch-callout: none !important;
            user-select: text !important;
          }
          body *, html *, #viewer * {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
            user-select: text !important;
          }
          iframe {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
            pointer-events: auto !important;
          }
          iframe[src], iframe[srcdoc] {
            touch-action: pan-y manipulation !important;
            -ms-touch-action: pan-y manipulation !important;
          }
        `;
        document.head.appendChild(style);
      }

      // Re-apply to iframes
      try {
        var allIframes = document.querySelectorAll('iframe');
        allIframes.forEach(function (iframe) {
          iframe.style.touchAction = 'pan-y manipulation';
          iframe.style.setProperty('-ms-touch-action', 'pan-y manipulation', 'important');
          iframe.style.setProperty('touch-action', 'pan-y manipulation', 'important');
        });
      } catch (e) {
        // Ignore errors
      }
    } else {
      // No selection, stop monitoring
      return 'no-selection';
    }
  } catch (e) {
    console.error('Error checking selection:', e);
  }
}

function detectSwipe(el, func) {
  swipe_det = new Object();
  swipe_det.sX = 0;
  swipe_det.sY = 0;
  swipe_det.eX = 0;
  swipe_det.eY = 0;
  swipe_det.blocked = false; // Track if swipe should be blocked
  swipe_det.hasMoved = false; // Track if touch has moved
  swipe_det.touchStartTime = null; // Track when touch started
  var min_x = 50;  //min x swipe for horizontal swipe
  var max_x = 40;  //max x difference for vertical swipe
  var min_y = 40;  //min y swipe for vertical swipe
  var max_y = 50;  //max y difference for horizontal swipe
  var direc = "";
  ele = el
  ele.addEventListener('touchstart', function (e) {
    // Check if selection exists at start of gesture
    if (hasActiveSelection()) {
      // Store position and time to detect if it's a tap or swipe
      swipe_det.blocked = false; // Don't block yet - wait to see if it's a tap
      swipe_det.hasMoved = false;
      swipe_det.touchStartTime = Date.now();
      if (e.touches && e.touches.length > 0) {
        var t = e.touches[0];
        swipe_det.sX = t.screenX;
        swipe_det.sY = t.screenY;
        swipe_det.eX = swipe_det.sX;
        swipe_det.eY = swipe_det.sY;
      }
      // Don't preventDefault yet - allow taps to deselect
    } else {
      swipe_det.blocked = false;
      swipe_det.hasMoved = false;
      swipe_det.touchStartTime = Date.now();
      var t = e.touches[0];
      swipe_det.sX = t.screenX;
      swipe_det.sY = t.screenY;
      swipe_det.eX = swipe_det.sX;
      swipe_det.eY = swipe_det.sY;
    }
  }, { capture: true, passive: false }); // Use options object with passive: false
  ele.addEventListener('touchmove', function (e) {
    // If selection exists, check if it's a swipe
    if (hasActiveSelection()) {
      var t = e.touches[0];
      swipe_det.eX = t.screenX;
      swipe_det.eY = t.screenY;

      var deltaX = Math.abs(swipe_det.eX - swipe_det.sX);
      var deltaY = Math.abs(swipe_det.eY - swipe_det.sY);

      // If there's significant movement, it's a swipe - block it
      if (deltaX > 10 || deltaY > 10) {
        swipe_det.hasMoved = true;
        // Block horizontal swipes
        if (deltaX > 30 && deltaX > deltaY * 1.5) {
          swipe_det.blocked = true;
          e.preventDefault();
          e.stopPropagation();
          return false;
        }
        // Block significant horizontal movement
        if (deltaX > 50) {
          swipe_det.blocked = true;
          e.preventDefault();
          e.stopPropagation();
          return false;
        }
      }
    } else {
      // Only prevent default if we're actually tracking a swipe
      e.preventDefault();
      var t = e.touches[0];
      swipe_det.eX = t.screenX;
      swipe_det.eY = t.screenY;
    }
  }, { capture: true, passive: false }); // Use options object with passive: false
  ele.addEventListener('touchend', function (e) {
    // If selection exists, check if it was a tap or swipe
    if (hasActiveSelection()) {
      if (swipe_det.touchStartTime !== null) {
        var deltaX = Math.abs(swipe_det.eX - swipe_det.sX);
        var deltaY = Math.abs(swipe_det.eY - swipe_det.sY);
        var touchDuration = Date.now() - swipe_det.touchStartTime;

        // If minimal movement and short duration, it's a tap - allow it to deselect
        if (!swipe_det.hasMoved && deltaX < 10 && deltaY < 10 && touchDuration < 300) {
          // Don't preventDefault - allow tap to deselect
        } else if (deltaX > 30 && deltaX > deltaY * 1.5) {
          // It was a horizontal swipe - block it
          swipe_det.blocked = true;
          e.preventDefault();
          e.stopPropagation();
          return false;
        } else if (deltaX > 50) {
          // Significant horizontal movement - block it
          swipe_det.blocked = true;
          e.preventDefault();
          e.stopPropagation();
          return false;
        }
      }
      // If it was a tap, don't preventDefault
      swipe_det.blocked = false;
      return;
    }

    // Don't process swipe if it was blocked
    if (swipe_det.blocked) {
      swipe_det.blocked = false;
      swipe_det.hasMoved = false;
      swipe_det.touchStartTime = null;
      return;
    }

    //horizontal detection
    if ((((swipe_det.eX - min_x > swipe_det.sX) || (swipe_det.eX + min_x < swipe_det.sX)) && ((swipe_det.eY < swipe_det.sY + max_y) && (swipe_det.sY > swipe_det.eY - max_y)))) {
      if (swipe_det.eX > swipe_det.sX) direc = "r";
      else direc = "l";
    }
    //vertical detection
    if ((((swipe_det.eY - min_y > swipe_det.sY) || (swipe_det.eY + min_y < swipe_det.sY)) && ((swipe_det.eX < swipe_det.sX + max_x) && (swipe_det.sX > swipe_det.eX - max_x)))) {
      if (swipe_det.eY > swipe_det.sY) direc = "d";
      else direc = "u";
    }

    if (direc != "") {
      if (typeof func == 'function') func(el, direc);
    }
    direc = "";
    swipe_det.blocked = false;
    swipe_det.hasMoved = false;
    swipe_det.touchStartTime = null;
  }, { capture: true, passive: false }); // Use options object with passive: false
}