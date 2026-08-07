# HIRA Diamond WebGL Test Plan

Status: v1.0 — pre-implementation test contract  
Primary gate: upstream engine compatibility with one HIRA solitaire model

## 1. Purpose

This plan defines how HIRA decides whether the GPL diamond-webgl baseline is suitable for continued development. It separates facts verified by automated checks from visual judgments that require real browser captures and user approval.

No test that was not executed may be reported as PASS.

## 2. Result labels

Use exactly one label for every test case:

| Label | Meaning | Phase effect |
| --- | --- | --- |
| PASS | Executed and met every written acceptance criterion | May advance |
| CONDITIONAL | Executed; minor documented limitation accepted by the user | May advance only with written acceptance |
| FAIL | Executed and missed a mandatory criterion | Stop the dependent phase |
| BLOCKED | Could not execute because an asset, device, permission, or environment was unavailable | Remains unverified; do not advance |

Every non-PASS result must include evidence, impact, owner, and next action.

## 3. Test phases and gates

| Phase | Goal | Exit gate |
| --- | --- | --- |
| T0 — Repository baseline | Prove the preserved project installs and builds | Build and asset checks PASS |
| T1 — Upstream runtime | Prove the unchanged demos render and controls work | Desktop runtime checks PASS |
| T2 — Model package | Prove the HIRA source package follows the file contract | All mandatory static/model checks PASS |
| T3 — Runtime mapping | Determine which sample OBJ represents each runtime role | Mapping evidence recorded |
| T4 — HIRA compatibility | Load one HIRA solitaire without editing protected scripts | Mandatory compatibility checks PASS |
| T5 — Mobile acceptance | Confirm usable behavior on agreed customer devices | Required device matrix PASS/accepted CONDITIONAL |
| T6 — User approval | HIRA visually approves the model | Signed-off result recorded |

Admin upload/API development is blocked until T0–T6 pass or the user explicitly accepts a CONDITIONAL result.

## 4. Test environments

### 4.1 Required desktop

- Windows 11
- Current stable Google Chrome
- Hardware acceleration enabled
- Normal display scaling and one high-DPI check where available

### 4.2 Required mobile

- Android Chrome on the user's primary Android phone
- Samsung Internet on a Samsung test device when available
- iPhone Safari on one supported iPhone when available

If a required device is unavailable, record BLOCKED rather than substituting a desktop responsive viewport.

### 4.3 Network profiles

- Local or fast Wi-Fi for functional verification
- One throttled/mobile-data observation for loading behavior before customer release

No fixed loading-time promise is set before the first real HIRA model is measured. Record actual transfer size, first visible frame time, and time until controls respond.

## 5. Required evidence

Each executed browser test stores:

- date and tester;
- commit SHA and branch;
- device, OS, browser, and browser version;
- exact URL and model revision;
- result label;
- console error text or confirmation that no fatal error appeared;
- screenshot of initial view;
- screenshot after rotation;
- short note on zoom/orbit behavior;
- measured file sizes and observed loading times;
- issue link or next action for every failure.

Store test reports under `test-results/` when that directory is introduced. Do not commit private customer assets or credentials with the report.

## 6. T0 — Repository baseline tests

### T0-01 Clean source state

Procedure:

1. Record `git status --short --branch`.
2. Confirm no unexpected tracked or untracked files.
3. Record `git rev-parse HEAD`.

Acceptance:

- repository identity and commit are known;
- no unrelated user changes are overwritten;
- generated `dist/` and `node_modules/` remain ignored.

### T0-02 Dependency install

Procedure:

1. Use the supported Node.js/npm environment.
2. Run `npm install` or `npm ci` on a fresh checkout.
3. Record warnings and failures.

Acceptance:

- install exits with code 0;
- no credential is requested or written into the repository;
- dependency source is reproducible from `package-lock.json`.

### T0-03 Production build

Procedure:

1. Run `npm run build`.
2. Verify the expected output files.

Mandatory output checks:

```text
dist/index.html
dist/script/main.min.js
dist/jewelry/index.html
dist/jewelry/script/main.min.js
dist/jewelry/models/ring.obj
dist/jewelry/models/engagement-ring.obj
dist/jewelry/textures/skybox.jpg
```

Acceptance:

- build exits with code 0;
- every listed file exists and is non-empty;
- source files under `docs/` are not modified by the build.

### T0-04 Protected baseline integrity

Record hashes for the six protected minified scripts listed in `AGENTS.md`. Before and after compatibility experiments, compare those hashes.

Acceptance:

- protected script hashes are unchanged;
- any difference is an immediate FAIL until explicitly approved.

## 7. T1 — Upstream runtime tests

### T1-01 Main demo opens

- Open `/` from a local HTTP server.
- Confirm the canvas renders instead of a blank or error page.
- Confirm there is no fatal console error.

### T1-02 Jewelry demo opens

- Open `/jewelry/`.
- Confirm the upstream sample jewelry is visible.
- Record whether both sample OBJ requests return HTTP 200.
- Record WebGL errors and failed network requests.

### T1-03 Interaction

Verify individually:

- pointer/touch rotation;
- zoom in and out;
- camera does not become permanently lost;
- resize/orientation change does not blank the canvas;
- controls remain responsive after repeated interaction.

### T1-04 Baseline screenshots

Capture the unchanged sample at the same viewport and camera positions intended for HIRA comparison. These images are evidence, not substitutes for live testing.

## 8. T2 — HIRA model package validation

The submission must follow `MODEL_AND_FILE_RULES.md`.

### T2-01 Required files

- `metal.obj`
- `diamond.obj`
- `thumbnail.webp` or `thumbnail.jpg`
- `model-info.json`

### T2-02 Naming and JSON

Acceptance:

- product ID matches `^[a-z0-9]+(?:-[a-z0-9]+)*$`;
- filenames match the contract exactly;
- JSON parses without comments or trailing commas;
- placeholder zero measurements have been replaced;
- no private/customer information is included.

### T2-03 Geometry measurements

Record separately for metal and diamond:

- file bytes;
- vertex count;
- normal count;
- triangle/face count;
- bounding box;
- presence of object/group/material declarations;
- invalid numeric values such as NaN or Infinity.

### T2-04 Blender/CAD inspection

Acceptance:

- common origin and transforms reassemble correctly;
- scale matches known dimensions within 1%;
- diamond facets are not smoothed incorrectly;
- no unintended flipped normals, duplicate shells, or loose geometry;
- metal/diamond separation matches the approved design;
- prong count, prong position, basket height, stone ratio, and silhouette match the reference.

## 9. T3 — Runtime mapping experiment

The upstream demo references `ring.obj` and `engagement-ring.obj`, but their semantic roles are not yet proven. Determine mapping without editing protected scripts.

Run controlled experiments on a dedicated compatibility branch:

| Experiment | `ring.obj` | `engagement-ring.obj` | Purpose |
| --- | --- | --- | --- |
| M0 | upstream | upstream | Baseline |
| M1 | harmless minimal test geometry | upstream | Identify `ring.obj` role |
| M2 | upstream | harmless minimal test geometry | Identify `engagement-ring.obj` role |
| M3 | HIRA candidate mapping A | HIRA candidate mapping B | First full mapping |
| M4 | swapped HIRA mapping | swapped HIRA mapping | Confirm roles if M3 is ambiguous |

For every experiment:

- change only the named OBJ files;
- record file hashes and sizes;
- capture initial and rotated views;
- record console and network results;
- restore the upstream assets after the experiment;
- do not merge a failed mapping into `main`.

Exit criterion: each runtime filename has a documented, repeatable geometry/material role.

## 10. T4 — HIRA compatibility acceptance

Mandatory functional checks:

- HIRA metal geometry is visible;
- HIRA diamond geometry is visible;
- neither role is accidentally swapped;
- model assembly maintains position, scale, and orientation;
- model fits the initial camera view;
- orbit and zoom remain usable;
- no missing mesh, black canvas, NaN artifact, or fatal console error occurs;
- protected script hashes remain unchanged;
- upstream sample can still be restored and rendered.

Mandatory visual checks:

- center diamond does not appear as an entirely black object;
- metal does not receive the diamond optical treatment;
- diamond does not receive the metal treatment;
- prongs and basket align with the center stone;
- approved product silhouette is preserved;
- no geometry was silently replaced with the upstream sample.

The user, not an automated metric alone, decides visual acceptance.

## 11. T5 — Mobile acceptance

For each required device/browser:

- page loads from a real URL reachable by the device;
- initial model becomes visible;
- one-finger rotation works without scrolling the whole page unexpectedly;
- pinch zoom is controllable;
- portrait and landscape do not permanently blank the canvas;
- controls remain tappable;
- browser back navigation returns safely;
- no browser crash or repeated WebGL context loss occurs;
- device heat and battery behavior are observed for at least three minutes of interaction.

Record observations rather than inventing performance numbers. Initial budgets are established from the accepted solitaire model.

## 12. Negative and recovery tests

Run before admin-system release, not necessarily during the first compatibility gate:

| Case | Expected behavior |
| --- | --- |
| Missing metal OBJ | Clear error; product remains unpublished |
| Missing diamond OBJ | Clear error; product remains unpublished |
| Corrupt OBJ | Validation rejects the file; no blank customer page |
| Invalid `model-info.json` | Validation identifies the exact field/error |
| Oversized model | Upload/validation blocks or requests optimization |
| Unpublished product URL | Customer cannot retrieve private model files |
| Failed model request | Customer sees a recoverable error or fallback, not an infinite loader |
| Expired admin session | Upload is rejected and login is requested again |

## 13. Regression suite

After each material code or asset-pipeline change:

1. run T0 build and integrity checks;
2. render the unchanged upstream sample;
3. render the accepted HIRA solitaire revision;
4. exercise orbit and zoom;
5. review console/network failures;
6. compare against the last accepted evidence;
7. confirm no published product URL broke.

## 14. Compatibility gate decision record

Use this template:

```text
Decision date:
Commit / branch:
HIRA model product ID / revision:
Desktop result:
Android Chrome result:
Samsung Internet result:
iPhone Safari result:
Protected script integrity:
Visual approval by user:
Overall gate: PASS | CONDITIONAL | FAIL | BLOCKED
Accepted limitations:
Blocking failures:
Next authorized phase:
```

No admin/API work begins unless `Overall gate` is PASS or the user explicitly authorizes advancement with documented CONDITIONAL limitations.

