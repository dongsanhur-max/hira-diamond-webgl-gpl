# T1 Upstream Runtime Evidence

Date: 2026-08-07
Tester: Claude (interactive Lead/review session)
Commit / branch at time of test: `ffe7b75` (`main`), served unmodified from `docs/`
Server: `npm run dev` (Vite v7.3.6) at `http://127.0.0.1:5173`, local only, stopped after this evidence was captured.

Scope: this closes the T1 documentation gap noted during the T4c review --
T1 had been exercised implicitly via T3's M0 baseline experiment
(`test-results/t3-runtime-mapping/README.md`) but had no standalone report.
This report stands on its own and adds fresh evidence for T1-01 and T1-03,
which M0 did not directly cover.

## T1-01 Main demo opens (`/`)

- `GET http://127.0.0.1:5173/` -> HTTP 200.
- One `<canvas>` element present and rendering (not blank): see
  [`root-canvas-closeup.png`](root-canvas-closeup.png). A first attempt,
  [`root-initial.png`](root-initial.png), caught the canvas before it had
  scrolled into view/finished its first paint and looked like a flat gray
  box -- recorded here as a reminder that "a canvas element exists" is not
  the same claim as "it rendered content," and a second, scrolled capture
  ([`root-scrolled.png`](root-scrolled.png)) was taken to confirm actual
  rendered geometry rather than trusting the DOM-presence check alone.
- Console: only `debug` (shader-compile timing, vite HMR connect) and
  `warning` (`GL_CLOSE_PATH_NV` / "GPU stall due to ReadPixels", a Chromium
  WebGL performance diagnostic during screenshot capture, not a rendering
  failure) messages. No `error`-level console output.
- `pageErrors`: none. `failedRequests`: none.
- Full raw log: [`root-runtime.json`](root-runtime.json).

**Result: PASS.**

## T1-02 Jewelry demo opens (`/jewelry/`)

- `GET http://127.0.0.1:5173/jewelry/` -> HTTP 200 (this session, see
  [`jewelry-interaction-runtime.json`](jewelry-interaction-runtime.json)).
- Both sample OBJ requests independently verified in T3's M0 baseline
  (same unmodified upstream assets, `docs/jewelry/models/`, run the same
  day): `engagement-ring.obj` 1,366,647 bytes, SHA-256 `05714a04...`;
  `ring.obj` 444,480 bytes, SHA-256 `32e5eca1...`; both HTTP 200. See
  `../t3-runtime-mapping/M0-runtime.json` for the full log -- not
  re-duplicated here since the assets are unchanged and re-hashing would
  just reproduce the same values.
- Visible sample jewelry confirmed visually: [`jewelry-initial.png`](jewelry-initial.png).
- No WebGL `RENDER_FAILURE`, `CONTEXT_LOSS`, or `RESOURCE_FAILURE` per the
  `TEST_PLAN.md` §5 classification in either this session's log or M0's --
  only the same `ReadPixels` performance diagnostic as T1-01, classified
  `DIAGNOSTIC`/`INFO`.

**Result: PASS.**

## T1-03 Interaction

All four checks run in one session against the unmodified `/jewelry/` page
(no HIRA substitution -- this is deliberately separate from the T4/T4c
evidence, which tests the same interactions but with a swapped-in model):

- **Pointer rotation**: 20-step mouse drag across the canvas.
  [`jewelry-initial.png`](jewelry-initial.png) vs.
  [`jewelry-rotated.png`](jewelry-rotated.png) show a clearly different
  camera angle after the drag. PASS.
- **Zoom in/out**: five in-canvas wheel events (`deltaY=-300` each).
  [`jewelry-zoomed.png`](jewelry-zoomed.png) shows a closer framing than
  the initial view, consistent with zoom responding to input. PASS.
- **Camera not permanently lost**: no `pageerror` or `webglcontextlost`
  event fired at any point across rotation, zoom, resize, or the
  post-resize interaction below; canvas remained present and paintable
  throughout. PASS.
- **Resize / orientation-change does not blank the canvas**: viewport
  resized from `1280x900` to `900x1280` (portrait) mid-session; the canvas
  bounding box was still present and non-empty immediately after
  ([`jewelry-after-resize.png`](jewelry-after-resize.png) is not blank).
  PASS.
- **Controls remain responsive after repeated interaction**: a further
  drag was performed *after* the resize;
  [`jewelry-after-resize-interaction.png`](jewelry-after-resize-interaction.png)
  shows the view changed again in response, confirming input handling
  survived the resize rather than becoming stuck. PASS.

Full raw log (console, page errors, failed requests, both canvas bounding
boxes): [`jewelry-interaction-runtime.json`](jewelry-interaction-runtime.json).
`pageErrors`: none. `failedRequests`: none, across the entire sequence.

**Result: PASS.**

## T1-04 Baseline screenshots

Captured at 1280x900 (root, pre-resize jewelry views) and 900x1280
(post-resize jewelry view), same viewport used consistently within each
comparison pair above:

- Root: [`root-canvas-closeup.png`](root-canvas-closeup.png)
- Jewelry initial / rotated / zoomed: [`jewelry-initial.png`](jewelry-initial.png),
  [`jewelry-rotated.png`](jewelry-rotated.png), [`jewelry-zoomed.png`](jewelry-zoomed.png)
- Jewelry post-resize: [`jewelry-after-resize.png`](jewelry-after-resize.png),
  [`jewelry-after-resize-interaction.png`](jewelry-after-resize-interaction.png)

T3's [`M0-initial.png`](../t3-runtime-mapping/M0-initial.png) and
[`M0-rotated.png`](../t3-runtime-mapping/M0-rotated.png) are additional,
independently captured baseline evidence of the same unmodified page from
earlier the same day, included there rather than duplicated here.

These are evidence of what was tested, not a substitute for the required
live desktop/mobile matrix in `TEST_PLAN.md` §4 -- no physical-device or
Samsung Internet / iOS Safari testing is claimed here; this report covers
desktop Chromium only (Chromium 151.0.7922.34, headless, via Playwright),
consistent with the "Required desktop" environment in `TEST_PLAN.md` §4.1.
Mobile-device T5 testing remains separately BLOCKED pending device
availability and a reachable HTTPS URL (no deployment has occurred).

## Summary

| Check | Result |
| --- | --- |
| T1-01 Main demo opens | PASS |
| T1-02 Jewelry demo opens | PASS |
| T1-03 Interaction (rotation, zoom, no context loss, resize, repeated interaction) | PASS |
| T1-04 Baseline screenshots | PASS (evidence captured; not a substitute for T5's live device matrix) |

T1 is **PASS** on the required desktop environment (Windows 11, Chromium,
local `npm run dev` server). This does not by itself change the T4 gate
status recorded in `../t4-hira-load/README.md`; it closes a separate
documentation gap identified during the T4c review.
