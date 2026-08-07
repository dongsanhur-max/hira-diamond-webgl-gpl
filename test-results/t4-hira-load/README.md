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
