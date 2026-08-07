# T4 HIRA Runtime Load

Date: 2026-08-07
Branch: `compat/t4-hira-load`
Result: **FAIL**

## Scope

The T2-approved external `ring-001` source package was inspected in place and
not copied into the repository. `scripts/merge-hira-model.mjs` combines the
explicitly assigned `metal.obj` and `diamond.obj` roles into a temporary
runtime OBJ. The upstream `docs/jewelry/models/engagement-ring.obj` was
temporarily replaced only for local experiments, then restored to its
upstream SHA-256 after every experiment:
`05714a046ba1338948dfc02e936626a90c8fbedc11973ff8d494cb1bd4756c4d`.

## Inputs and Adapter Output

| Asset | SHA-256 | Vertices | Normals | Faces |
| --- | --- | ---: | ---: | ---: |
| T2 `metal.obj` | `c4c965454086e80b34f9ce8a9fecc26eb0901a2efc91a2bca9361eea70e5090e` | 2,554 | 2,554 | 4,344 |
| T2 `diamond.obj` | `f8506e5680e54c24e58897e92fe7539244a04a3622058b7d64cf5f397eca72de` | 844 | 844 | 742 |
| Merged OBJ, scale 1.0 (unscaled) | `2de5f602e7832454d377e141ecfae2c5e7e9bb9a532b1b4366f7fa96fa79d9c5` | 3,398 | 3,398 | 5,086 |
| Merged OBJ, scale 0.1111 (scale-fixed) | `ae325d99f31a2e0e18d04185e0c69aec6eaa8009b019122bb29f1987e04125a5` | 3,398 | 3,398 | 5,086 |

The source roles were explicit before the merge; no material-name inference
or automatic role classification occurred.

## Loader Contract Finding

Read-only analysis of the protected `ObjModel.fromString` loader established
that it accepts only `v`, `vn`, `f`, comments, and blank lines. It rejects
`vt`, `mtllib`, `usemtl`, `o`, `g`, and `s` lines. The adapter therefore:

- preserves source `mtllib`, `usemtl`, object, group, and smoothing statements
  as `# source ...` comments for auditability;
- omits unused `vt` records;
- emits `v//vn` faces with the correct vertex and normal offsets.

Three early attempts, which retained unsupported directives, fetched the OBJ
but rendered no support triangles. Their captures/logs are retained as
evidence: `runtime.json`, `runtime-normalized.json`, `runtime-vt-stripped.json`.

## Correction: the unscaled "geometry loads" claim was invalid

An earlier revision of this report marked "Merged HIRA geometry loads" as
**PASS**, based on an A/B/A `Geometry only` canvas-hash comparison (support
on/off/on) where the "on" and "restored" hashes matched and the "off" hash
differed. That comparison was re-verified with a pixel-level diff
(`pixelmatch`, threshold 8/255 per channel) between
`geometry-only-support-on-canvas.png` and `geometry-only-support-off-canvas.png`:

**0 of 246,506 pixels outside the on-canvas HUD text box differed.** All 389
differing pixels in the full image were confined to the `Triangles: 982` vs
`Triangles: 6,068` HUD counter text. The 3D-rendered scene content was
byte-identical whether the merged support model was present or not. The
triangle counter increasing by exactly the merged model's face count proved
only that the loader parsed the OBJ, not that it rendered visibly. This
invalidated the PASS claim; those two canvas files and
`runtime-geometry-visibility.json` are kept for audit but the conclusion
drawn from them was wrong.

## Root cause and fix: unit/scale mismatch

Comparing bounding boxes explains the invisible geometry:

| Model | x span | y span | z span |
| --- | ---: | ---: | ---: |
| Upstream `engagement-ring.obj` | 2.077 | 0.774 | 2.480 |
| Upstream `ring.obj` | 2.267 | 0.540 | 2.264 |
| T2 `metal.obj` (real mm from 3Design) | 18.149 | 7.857 | 22.469 |

The HIRA source package is authored in real-world millimeters (correct per
`MODEL_AND_FILE_RULES.md` §6 and T2's `sourceUnit: "mm"`), but the upstream
sample OBJs use a much smaller unrelated engine-unit convention — roughly
**9x** smaller per axis. Loaded unscaled, the merged model was ~9x larger
than the loader/camera setup expects, which is consistent with it falling
outside the visible/rendered result while still being parsed and counted.

`scripts/merge-hira-model.mjs` was extended with an optional `--scale=<N>`
flag (uniform position scale, `vn` directions untouched since a uniform
positive scale doesn't change normal direction). A first-pass scale of
`0.1111` (derived from the ratio of the merged model's bounding-box diagonal
to `engagement-ring.obj`'s bounding-box diagonal: 3.326 / 29.933) was used to
regenerate the adapter output.

**This scale is an approximation for visibility testing only** — it matches
overall size, not a precisely calibrated real-world-mm-to-engine-unit
constant. Establishing a production constant needs a known reference
dimension (e.g. a HIRA ring of documented real diameter compared against its
correctly-displayed engine size), which is out of scope for this experiment.

### Re-verification with the scale-fixed model

`docs/jewelry/models/engagement-ring.obj` was temporarily replaced with the
scale-fixed merged OBJ (SHA-256 `ae325d99...`, see table above), the local
server was reloaded, and:

- [scaled-initial.png](scale-fix-evidence/scaled-initial.png) and
  [scaled-rotated.png](scale-fix-evidence/scaled-rotated.png) show a
  recognizable ring band and prong/basket structure — not present at any
  camera angle with the unscaled model.
- A repeat of the `Geometry only` on/off comparison, this time with the
  scale-fixed model, shows **clearly different silhouettes**, not just a HUD
  text difference:
  [geoonly-scaled-support-on.png](scale-fix-evidence/geoonly-scaled-support-on.png)
  (6,068 triangles, HIRA ring-001 band/prong shape) vs.
  [geoonly-upstream-off.png](scale-fix-evidence/geoonly-upstream-off.png)
  (25,756 triangles, the real upstream pavé-band engagement ring). The two
  images have different ring silhouettes, different band styles (plain vs.
  pavé-set), and different prong shapes — this is the geometry-shape-level
  evidence the original on/off/on hash comparison failed to provide.
- The upstream file was restored immediately after capture; `git diff` shows
  `docs/jewelry/models/engagement-ring.obj` identical to `HEAD`
  (`05714a04...`), and `sha256sum --check docs/baseline/protected-scripts.sha256`
  still reports `OK` for all six protected scripts.

### Material-role observation (supports, does not replace, the FAIL)

In the full-lighting scaled render, the shape visible inside the prongs at
the model's crown reads as a rounded, faceted white mass — not a
recognizable oval (T2 `diamond.obj` is an oval cut). This is consistent with
the diamond and metal geometry both being drawn by the same flat "support"
shader, blending the oval diamond into the surrounding prong metal, while the
engine's own independent procedural gem overlay (`Gems: 9`, unrelated to our
upload — see the T3 report, gem placement is scene-config-driven, not
mesh-driven) renders its usual separate round/faceted gem on top. This is
observational, not a new measurement, and does not change the gate result
below.

## Gate Decision

| Criterion | Result | Evidence |
| --- | --- | --- |
| Merged HIRA geometry loads | PASS | Corrected: scale-fixed support on/off comparison shows a different rendered silhouette (ring band + prongs vs. no visible support shape), not just a HUD-text difference. Requires the experimental `--scale=0.1111` adapter flag; the unscaled 1.0 output does **not** visibly render (see correction section above). |
| Source roles are explicitly assigned | PASS | T2 `metal.obj` and `diamond.obj` were merged by input position only. |
| Orbit and zoom work | PASS | Distinct canvas hashes and five recorded in-canvas wheel events (unscaled-model interaction test; not re-run against the scale-fixed model). |
| Fatal console/network error | PASS | No failed request or fatal application error, scaled or unscaled. |
| Metal and diamond display in intended distinct roles | FAIL | The unchanged upstream support loader ignores `usemtl` and renders the merged OBJ with one support shader; the oval diamond is not visually distinguishable from the metal prongs in the scaled render. |
| Visual approval of position, scale, and orientation | BLOCKED | The `0.1111` scale is a first-pass approximation, not a calibrated constant, and screenshots still need HIRA sign-off. |

T4 cannot advance while the distinct metal/diamond material-role criterion is
unmet. Any next solution must remain outside the protected scripts unless an
explicitly approved protected-engine change proposal is made. If this
direction continues, the next steps are: (1) derive a proper mm-to-engine-unit
scale constant from a known reference dimension rather than a bounding-box
approximation, and (2) decide whether distinct metal/diamond rendering is
achievable without protected-script changes at all, or whether that requires
an explicitly approved protected-script change proposal per `AGENTS.md` §4.

## T4c scale calibration v2 (2026-08-07)

Branch: `compat/t4c-scale-calibration`

T4c result: **CONDITIONAL**. The scale constant is now derived from a known
15 mm CAD ring-size dimension rather than a bounding-box diagonal, but the
unchanged T4 material-role result remains **FAIL**, initial-camera fit is
**FAIL**, and user visual approval remains **BLOCKED**. This section does not
declare the overall T4 gate PASS.

### Measurement method and dimensional correction

The source package stayed outside the repository at
`C:\Users\chuck\Desktop\ring-001\`. The reproducible Node measurement in
[`scale-calibration-v2/measure-inner-band.mjs`](scale-calibration-v2/measure-inner-band.mjs)
uses the same definition for both meshes:

1. treat `x-z` as the ring plane and `y` as band width;
2. select the lower shank in the center 1% `y` slice;
3. retain vertices whose projected normal points inward (`dot < -0.7`);
4. fit a circle to those `x-z` points.

Raw output is in [`measurement.json`](scale-calibration-v2/measurement.json).

| Measurement | Value | Fit evidence |
| --- | ---: | ---: |
| HIRA `metal.obj` inner diameter | `14.969826521277412 mm` | 37 points, RMSE `0.004651874152237557 mm` |
| Difference from documented 15 mm | `-0.20115652481725496%` | Within the 1% model tolerance |
| Upstream `engagement-ring.obj` inner diameter | `1.8641412665847064 engine units` | 90 points, RMSE `0.00035248562937919637` |

The task brief's literal ratio is preserved as the inverse conversion:

```text
15 mm / 1.8641412665847064 engine units
= 8.046600474373653 mm per engine unit
```

`merge-hira-model.mjs --scale` multiplies millimeter vertex positions and
therefore requires the reciprocal unit direction:

```text
adapter scale
= 1.8641412665847064 engine units / 15 mm
= 0.12427608443898043 engine units per mm
```

Passing `8.046600...` to `--scale` would enlarge the millimeter model and is
dimensionally incorrect. The generated adapter used the reciprocal
`0.12427608443898043` without rounding. It has 3,398 vertices, 3,398 normals,
5,086 faces, no unsupported records, and SHA-256
`93c0cdb7ada78efe7b791f73aa5d7ab7f6dc6fc3a0cf07e1bdb0c848cec8fdff`.
See [`adapter-generation.json`](scale-calibration-v2/adapter-generation.json)
and [`adapter-validation.json`](scale-calibration-v2/adapter-validation.json).

### Fresh runtime evidence

The browser fetched the exact adapter hash twice with HTTP 200. Chromium
`151.0.7922.34` reported no failed requests or page errors. General-lighting
and Geometry-only initial/rotated/zoomed hashes were all distinct; zoom used
five in-canvas wheel events at `deltaY=-300` each. The Geometry-only checkbox
was independently confirmed checked. Full details are in
[`browser-runtime.json`](scale-calibration-v2/browser-runtime.json).

- [full-lighting-initial.png](scale-calibration-v2/full-lighting-initial.png)
- [full-lighting-rotated.png](scale-calibration-v2/full-lighting-rotated.png)
- [full-lighting-zoomed.png](scale-calibration-v2/full-lighting-zoomed.png)
- [geometry-only-initial.png](scale-calibration-v2/geometry-only-initial.png)
- [geometry-only-rotated.png](scale-calibration-v2/geometry-only-rotated.png)
- [geometry-only-zoomed.png](scale-calibration-v2/geometry-only-zoomed.png)

The fresh captures visibly show the HIRA band and basket, but the crown is
clipped at the top edge in the initial camera. The unchanged scene also draws
its nine procedural gems over the support model. Because the merged HIRA
diamond uses the same support shader as the metal, these captures cannot
independently prove HIRA center-stone/prong alignment. That visual criterion
is reported BLOCKED rather than inferred from the triangle counter.

Two failed harness attempts are retained under `attempt1-toggle-failed/` and
`attempt2-hidden-control/`. They failed only to enable Geometry-only and are
not used as passing evidence.

### Updated T4 checks

| Criterion | Result | Fresh evidence / impact / next action |
| --- | --- | --- |
| Calibrated scale from a real reference dimension | PASS | 15 mm CAD anchor cross-checks at 14.9698 mm (`-0.201%`); same center-slice method gives upstream diameter 1.8641413 units and adapter scale 0.12427608443898043. |
| Model assembly maintains position, scale, and orientation | PASS | The adapter applies one uniform positive scale to both explicit source roles with no recentering or rotation; band and basket remain assembled while rotating. |
| Model fits the initial camera view | FAIL | The crown/basket reaches beyond the top canvas edge in `full-lighting-initial.png` and `geometry-only-initial.png`. Impact: incomplete first view. Next action: separately authorize/configure initial camera framing without changing protected scripts. |
| Orbit and zoom remain usable | PASS | Distinct initial/rotated/zoomed hashes in both modes; 20-step drag and five real wheel events recorded. |
| No missing mesh, black canvas, NaN artifact, or fatal console error | CONDITIONAL | Canvas renders, adapter contains no non-finite values, OBJ requests are HTTP 200, and there are no page errors/failed requests. The merged HIRA diamond cannot be visually isolated from metal under the shared support shader, so individual diamond visibility remains unproven. Owner: viewer/model. Next action: material-role decision remains separate. |
| Protected script hashes unchanged | PASS | All six files report `OK` before and after; see `protected-hashes-before.txt` and `protected-hashes-after.txt`. |
| Upstream sample restored and rendered | PASS | Restored source and built output both match `05714a046ba1338948dfc02e936626a90c8fbedc11973ff8d494cb1bd4756c4d`; restored browser response has the same hash and all runtime assertions pass under `upstream-restored/`. |
| Prongs and basket align with the center stone | BLOCKED | Shared support shading plus the unrelated nine-gem procedural overlay prevents an independent visual judgment of the HIRA diamond. No alignment PASS is claimed from parsing or shared origin alone. |
| Approved product silhouette is preserved | BLOCKED | Automated inspection records a recognizable ring and the initial-view clipping, but final silhouette approval belongs to the user. |
| Metal and diamond display in intended distinct roles | FAIL | Unchanged existing T4/T4b result: the protected upstream loader renders the merged OBJ with one support shader. This task did not re-investigate or alter it. |
| Visual approval of position, scale, and orientation | BLOCKED | Awaiting the user's review of the six fresh screenshots. |

### Restoration and regression

The temporary swap is recorded in `temporary-swap.json`. The upstream file
was restored to the known hash in `restoration.json` before the final build.
`npm run build` passed, all required dist assets are non-empty, and the source
and dist upstream model hashes match; see `build-output.txt` and
`postflight.json`.

## T4c addendum: camera-fit offset correction (2026-08-07, same day)

This addendum resolves the "Model fits the initial camera view: FAIL" row
above. It does not change the material-role FAIL or any other criterion.

### Root cause

`measurement.json`'s circle fit recorded not just diameters but the fitted
circle **centers** for both meshes. The upstream `engagement-ring.obj`'s own
band/grip-center sits at `x=0, z=-0.6033947215569887` in its own coordinate
frame -- not at the origin. The v1 scale-only adapter multiplied our source
coordinates by the scale constant but never translated them, so our ring's
band-center landed near `(0, 0, -0.001)` (our source model's own local
origin happens to sit close to its own band-center) while the camera setup
is built around the upstream convention of `z≈-0.603`. That ~0.602-unit gap
pushed our crown outside the top of the frame.

### Fix

`scripts/merge-hira-model.mjs` gained `--offset-x`/`--offset-y`/`--offset-z`
flags: a fixed translation applied to each vertex *after* scaling, in engine
units. The offset used here is
`upstreamCenter[axis] - (ourRawCenter[axis] * scale)` for each axis (full
derivation and source numbers in
[`camera-fit-offset/adapter-generation.json`](scale-calibration-v2/camera-fit-offset/adapter-generation.json)),
computed from the same `measurement.json` this task already produced --
no new measurement pass was needed. This is *not* a recenter-to-origin: it
specifically matches the upstream model's own off-origin convention, which
is why recentering the bounding box to `(0,0,0)` would have been the wrong
fix.

Command used:

```text
node scripts/merge-hira-model.mjs metal.obj diamond.obj <output.obj> \
  --scale=0.12427608443898043 \
  --offset-x=2.479e-9 --offset-y=-0.0012265644163687406 --offset-z=-0.6023866555452744
```

Resulting adapter: 3,398 vertices, 3,398 normals, 5,086 faces, SHA-256
`792e06821a5b65bde2a3b04cbd23da26cd6279def3f4492da570ec944cf44e96`.

### Verification

Same protocol as the rest of this report: temporary swap of
`docs/jewelry/models/engagement-ring.obj`, browser capture, restore, hash
checks before/after.

- [full-lighting-initial.png](scale-calibration-v2/camera-fit-offset/full-lighting-initial.png) --
  crown and basket now fully inside the canvas at every margin, compared
  with the clipped top edge in
  [`../full-lighting-initial.png`](scale-calibration-v2/full-lighting-initial.png).
- [full-lighting-rotated.png](scale-calibration-v2/camera-fit-offset/full-lighting-rotated.png) --
  stays fully framed through a 20-step drag rotation.
- [full-lighting-zoomed.png](scale-calibration-v2/camera-fit-offset/full-lighting-zoomed.png) --
  five in-canvas wheel events, no clipping at the closer distance either.
- [browser-runtime.json](scale-calibration-v2/camera-fit-offset/browser-runtime.json) --
  HTTP 200 for the adapter OBJ, zero page errors, zero failed requests.
- Upstream `engagement-ring.obj` restored and hash-confirmed
  (`05714a046ba1338948dfc02e936626a90c8fbedc11973ff8d494cb1bd4756c4d`);
  `npm run build` and the six-file protected-script check both passed again
  after restoration.

Not independently re-verified this round: Geometry-only mode (the checkbox
click in this session's script did not reliably register against a fresh
page load, so no Geometry-only screenshot is claimed here as passing
evidence -- the full-lighting captures above are the basis for this
result). The existing material-role FAIL is unaffected by this fix and was
not re-investigated, consistent with the rest of this report.

### Updated criterion

| Criterion | Result | Evidence |
| --- | --- | --- |
| Model fits the initial camera view | PASS | Crown/basket fully inside the frame at initial, rotated, and zoomed views with the offset-corrected adapter; see screenshots above. Supersedes the FAIL recorded earlier in this file. |

Overall T4c result is unchanged at **CONDITIONAL**: this addendum closes one
FAIL, but the metal/diamond material-role FAIL and the user visual-approval
BLOCKED item remain open, and the overall T4 gate is still not PASS.
