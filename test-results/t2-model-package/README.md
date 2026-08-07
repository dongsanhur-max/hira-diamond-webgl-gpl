# T2 Model Package Validation

## Revision 2 — 2026-08-07 — Result: **PASS**

Submission: `ring-001/` (staged at `C:\Users\chuck\Desktop\ring-001\`, not copied into
this repository per `MODEL_AND_FILE_RULES.md` §3 — stays outside public runtime
paths until a T4 compatibility test is run).

### Files and hashes

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `metal.obj` | 439,301 | `c4c965454086e80b34f9ce8a9fecc26eb0901a2efc91a2bca9361eea70e5090e` |
| `diamond.obj` | 106,910 | `f8506e5680e54c24e58897e92fe7539244a04a3622058b7d64cf5f397eca72de` |
| `thumbnail.jpg` | 62,338 | `4a9bb7c24ea89debb834a59dd7698f81b528ed6643fad30de4dd62bd63c97705` |
| `model-info.json` | 990 | `81dfda34428274a96e35362bbceb182026edffc3885e303c064cb98886252e3d` |

`model-info.json` copy: [ring-001-rev1-evidence/model-info.json](ring-001-rev1-evidence/model-info.json)

### T2-01 Required files — PASS

All four required files present with exact required names (after renaming the
as-exported `Diamond .obj`/`Diamond_.mtl` to `diamond.obj`/`diamond.mtl` — the
original export used a space and capitalized filename, which violates
`MODEL_AND_FILE_RULES.md` §4.2; the `mtllib` reference inside `diamond.obj` was
also corrected to point at the renamed `.mtl`, since the exporter had written a
mismatched `mtllib CenterDiamond_.mtl` line that named a file that didn't
exist).

### T2-02 Naming and JSON — PASS

- `productId` `ring-001` matches `^[a-z0-9]+(?:-[a-z0-9]+)*$`.
- JSON parses cleanly (verified with `JSON.parse`), no comments/trailing commas.
- No placeholder zero values remain.
- No customer/private data in any field.

### T2-03 Geometry measurements — PASS

| Measure | metal.obj | diamond.obj |
| --- | ---: | ---: |
| Vertices (as exported, per-facet split) | 2,554 | 844 |
| Faces (all triangles) | 4,344 | 742 |
| Vertices after merge-by-distance (1e-4) | 2,176 | 373 |
| Zero-area faces | 0 | 1 (negligible, 1/742) |
| Non-manifold edges after merge | 0 | 0 |
| Boundary edges after merge | 0 | 0 |
| Closed/manifold | true | true |
| Faces with flipped normal vs. recalculated | 0 | 0 |
| NaN/Infinity values | none | none |
| Object/group declarations | `OBJECT_Yellow_gold_14K_1` (1 object) | `OBJECT_Diamond_1` (1 object) — single center stone, no halo/side stones |

Measured with a headless Blender 4.5 bmesh script (import → `remove_doubles`
→ manifold/boundary-edge check → `recalc_face_normals` comparison). Full
per-run output is in [ring-001-rev1-evidence/](ring-001-rev1-evidence/).

### T2-04 CAD/Blender inspection — PASS (after one re-export cycle)

**Revision 1 of this submission FAILED T2-04.** Loading `metal.obj` and
`diamond.obj` together at `(0,0,0)`/scale `(1,1,1)`/no rotation placed the
diamond on the opposite side of the shank from the prong basket (diamond
z-range 0.0–3.6mm vs. basket z-range 17.4–22.5mm — an offset of ~18mm, i.e.
essentially the full ring diameter). Root cause: the diamond and metal parts
were exported from 3Design without disabling a plane/origin-reset option, so
each part's position was independently reset instead of preserving the shared
scene position — exactly what `MODEL_AND_FILE_RULES.md` §5.2 prohibits ("Do
not independently center metal and diamond after separation").

**Fix applied by the submitter:** re-exported both `metal` and `CenterDiamond`
from the same 3Design scene position with the plane-reset option disabled.

**Revision 2 (this submission) verification:**
- Raw bounding boxes now overlap correctly: `metal.obj` z: -9.100 to 13.369mm;
  `diamond.obj` z: 9.813 to 13.413mm — the stone sits inside the metal's
  z-range, at its top, matching the prong/basket location.
- Rendered metal.obj + diamond.obj together (headless Blender, both loaded at
  their native OBJ transform, no manual repositioning) from three angles:
  - [render-front.png](ring-001-rev1-evidence/render-front.png) — stone
    centered in a 4-prong setting.
  - [render-side.png](ring-001-rev1-evidence/render-side.png) — stone sits
    directly on top of the band/prongs, not on the opposite side.
  - [render-top.png](ring-001-rev1-evidence/render-top.png) — single stone at
    one point on the band circumference, correct for a solitaire.
- Diamond dimensions (5.8 × 8.1 × 3.6mm oval, 1.03ct) match the 3Design stone
  panel exactly — scale is within tolerance (effectively exact match, not
  merely within 1%).
- No unintended flipped normals or non-manifold shells (see T2-03).
- Prong count (4), single center stone, no halo/pavé — matches the approved
  "first reference product" profile in `MODEL_AND_FILE_RULES.md` §2.

### Thumbnail — CONDITIONAL

- Format: JPEG, 1105×1198px. `MODEL_AND_FILE_RULES.md` §9 recommends a square
  1200×1200 canvas; this is close but not exactly square. Not blocking, but
  should be cropped to square before customer-facing use.
- Metadata inspected with a vendored `exiftool` (system `exiftool` was not
  installed; installed `exiftool-vendored` npm package to run the check
  rather than skipping it or treating visual inspection as a substitute, per
  §9's "mark BLOCKED, don't substitute visual inspection" rule — since a real
  tool was available, this is a completed check, not BLOCKED).
- Result: only standard JPEG/JFIF technical tags present (dimensions,
  resolution, encoding). No GPS, owner/author, serial number, customer,
  order, or comment fields.

### Overall T2 result: **PASS**

This model package is validated as a source package ready for engine
testing (T3/T4), not yet customer-runtime approved, per
`DEFINITION_OF_DONE.md` §4. Next step is loading it into the actual
diamond-webgl runtime (T4) without editing protected scripts.

---

## Revision 1 — 2026-08-07 — Result: FAIL (superseded by Revision 2 above)

### Submitted Input

The user supplied one source file named `Ring.obj` (also found at
`Ring-diamond.obj`, identical content, SHA-256
`f727e990bd03ce0cc228bd93819a707e9ff6bda4936873a4fb2d53d3e51a92fa`). It was
inspected in place and was **not** copied into this repository or any public
runtime path.

| Measure | Observed value |
| --- | --- |
| File bytes | 848,858 |
| SHA-256 | `f727e990bd03ce0cc228bd93819a707e9ff6bda4936873a4fb2d53d3e51a92fa` |
| Vertices / normals / texcoords | 5,045 / 5,045 / 5,045 |
| Faces / triangles | 8,118 / 8,118 |
| Bounding box | 18.152 x 8.100 x 22.513 OBJ units |
| Object / group declarations | 7 / 14 |
| Material declarations | `Yellow_gold_14K`, `Diamond` |
| Material library reference | `Ring.mtl` (not supplied alongside the OBJ) |
| Invalid numeric values | 0 |

The single OBJ contains both metal and diamond material declarations. Per
`MODEL_AND_FILE_RULES.md`, material names are not an approved basis for
automatic role separation; no extraction, repair, or reinterpretation was
performed.

### T2 Checks

| Check | Result | Evidence / impact |
| --- | --- | --- |
| T2-01 required files | FAIL | `metal.obj`, `diamond.obj`, `model-info.json`, and a supplied `thumbnail.webp` or `thumbnail.jpg` are absent. |
| T2-02 naming and JSON | FAIL | No product-ID directory or `model-info.json`; source unit and export scale are undeclared. |
| T2-03 separate geometry measurements | FAIL | A mixed single OBJ cannot prove role separation, shared origin, or separate bounds. |
| T2-04 CAD/Blender inspection | BLOCKED | Requires the explicitly separated exports, known dimensions, reference image, and CAD/export details. |

T2 could not advance to T4 at this revision. The runtime samples remained
unchanged. This was resolved by resubmission as the `ring-001/` package
described above.
