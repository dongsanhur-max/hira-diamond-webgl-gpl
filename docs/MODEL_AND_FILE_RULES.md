# HIRA Model and File Rules

Status: v1.1 — compatibility-gate rules
Applies to: HIRA jewelry assets submitted for the GPL diamond-webgl viewer

## 1. Purpose

These rules make HIRA model submissions repeatable and testable. They do not assume that the upstream runtime already supports separate metal and diamond OBJ files. The first model package is a controlled compatibility experiment.

## 2. First approved reference product

Use one simple solitaire ring as the initial reference:

- one center diamond;
- uncomplicated prongs and shank;
- no halo, pavé, animation, engraving, or optional parts;
- approved HIRA product proportions;
- matching reference image or screenshot supplied with the model.

Do not begin with a multi-stone, halo, or high-polygon product.

## 3. Submission package

Each source submission uses this structure:

```text
ring-001/
├── metal.obj
├── diamond.obj
├── thumbnail.webp
├── reference-front.jpg       # optional but recommended
├── reference-side.jpg        # optional but recommended
└── model-info.json
```

The first compatibility package is stored outside public runtime paths until it passes validation. Do not put private or unapproved customer designs under `docs/`.

## 4. Naming rules

### 4.1 Product ID

- Format: lowercase ASCII letters, numbers, and hyphens only.
- Pattern: `^[a-z0-9]+(?:-[a-z0-9]+)*$`
- Example: `ring-001`, `solitaire-rb-100`.
- Product IDs are permanent and must not be reused for a different design.

### 4.2 Filenames

Required:

- `metal.obj`
- `diamond.obj`
- `thumbnail.webp` or `thumbnail.jpg`
- `model-info.json`

Forbidden:

- spaces;
- Korean characters;
- parentheses;
- version words such as `final`, `final2`, or `new`;
- ambiguous filenames such as `object.obj` or `model.obj`.

Revision information belongs in Git history and `model-info.json`, not in filenames.

## 5. Geometry rules

### 5.1 Separation

- Export metal and diamond as separate OBJ files.
- Do not include the diamond mesh inside `metal.obj`.
- Do not include prongs, shank, or basket geometry inside `diamond.obj`.
- During the compatibility gate, side stones may be combined in `diamond.obj` only when they all use the same diamond role. Record this decision in `model-info.json`.
- After the compatibility gate, the same explicit-role rule remains the default. Any automated grouping/classification requires a separately approved specification, a representative-model test set, zero unresolved role swaps, and a rollback path before it may replace manual assignment.

### 5.2 Transform and axis

- Apply scale and rotation before export.
- Both OBJ files must share the same origin and coordinate system.
- A model must reassemble correctly when both files are loaded at position `(0, 0, 0)` with scale `(1, 1, 1)` and no rotation.
- Center the product around a stable jewelry reference point. For the initial solitaire, use the ring center as the common origin unless the compatibility test documents another requirement.
- Do not independently center metal and diamond after separation.

### 5.3 Mesh health

- Diamond meshes must be closed/manifold unless the reference engine demonstrably requires another structure.
- Remove duplicate vertices, zero-area faces, loose geometry, and accidental internal copies.
- Recalculate and visually inspect normals; no unintended flipped faces.
- Triangulate deterministically before final export, or document the triangulation step used by the exporter.
- Preserve hard facet boundaries on diamonds. Do not apply smoothing that rounds cut facets.
- Metal shading may use appropriate smooth normals, but prong and edge silhouettes must remain faithful to the CAD model.

### 5.4 Complexity

No fixed polygon limit is claimed before measuring the baseline engine. For every submission, record:

- vertex count;
- triangle count;
- OBJ file size;
- bounding-box dimensions;
- Blender/exporter version;
- export duration and any optimization applied.

The first reference model establishes the initial budget. Later models that exceed it require a performance test rather than automatic acceptance.

## 6. Units and scale

- Author jewelry in millimeters in CAD/Blender.
- OBJ does not reliably encode units; therefore `model-info.json` must declare `sourceUnit: "mm"` and the export scale.
- Never guess scale during ingestion.
- Compare the exported bounding box against the known ring diameter and center-stone dimensions.
- A scale mismatch greater than 1% is a validation failure unless explicitly approved.

## 7. Material and texture rules

- OBJ source separation, not material-name inference, defines metal versus diamond.
- The upstream sample contains no dependable `o`, `g`, `usemtl`, or `mtllib` contract; do not build automatic classification around those fields without new evidence.
- Do not bake lighting, reflections, diamonds, logos, or backgrounds into model textures.
- Do not require HDRI/EXR files inside each product package.
- Product-specific texture support is out of scope for the first compatibility test.
- Metal color is a viewer setting, not a separate duplicate geometry file.

## 8. `model-info.json` contract

Use this minimum schema:

```json
{
  "schemaVersion": 1,
  "productId": "ring-001",
  "title": "HIRA Solitaire Ring",
  "revision": 1,
  "sourceUnit": "mm",
  "exportScale": 1.0,
  "metalFile": "metal.obj",
  "diamondFile": "diamond.obj",
  "thumbnailFile": "thumbnail.webp",
  "metalTriangles": 0,
  "diamondTriangles": 0,
  "boundingBoxMm": {
    "x": 0.0,
    "y": 0.0,
    "z": 0.0
  },
  "exportedFrom": "Blender",
  "exporterVersion": "record-exact-version",
  "notes": ""
}
```

Replace placeholder zero values before validation. JSON must parse without comments or trailing commas.

Numeric precision:

- `exportScale` must be a finite positive JSON number, use no more than six decimal places, and reproduce the intended size within the 1% scale tolerance. Use `1.0` when no scale conversion was applied.
- `boundingBoxMm` values use millimeters and no more than three decimal places.
- Triangle counts and revisions are non-negative integers; do not encode numeric values as strings.

## 9. Thumbnail rules

- Preferred format: WebP; JPEG is allowed during the first phase.
- Square canvas, recommended 1200 × 1200 px.
- Neutral HIRA background and sufficient whitespace.
- No customer names, order numbers, watermarks, EXIF location, or private metadata.
- Thumbnail orientation should match the initial 3D camera view where practical.
- Validate metadata before acceptance with `exiftool -G1 -a -s thumbnail.webp` (or the JPEG filename). The output must not contain GPS, owner/author, serial number, customer, order, comment, or other private fields.
- If `exiftool` is unavailable, mark metadata inspection BLOCKED; visual inspection alone is not a substitute.

## 10. Upstream runtime mapping

The preserved upstream jewelry demo currently references:

- `docs/jewelry/models/ring.obj`
- `docs/jewelry/models/engagement-ring.obj`

Those sample OBJ files contain vertices, normals, and faces but no observed object/group/material declarations. Their exact semantic roles must be determined by controlled replacement tests.

Therefore:

1. keep the HIRA source package as `metal.obj` and `diamond.obj`;
2. do not overwrite the upstream sample on `main`;
3. create a compatibility branch for mapping experiments;
4. change one asset at a time;
5. capture the rendered result and console output;
6. document which runtime filename and geometry role each HIRA export maps to;
7. add an adapter only after the mapping is proven.

## 11. Pre-upload validation checklist

Mark each item `PASS`, `CONDITIONAL`, `FAIL`, or `BLOCKED`.

### Files

- [ ] Product directory and ID follow naming rules.
- [ ] Required files exist and names match exactly.
- [ ] JSON parses and contains measured values.
- [ ] No temporary, backup, customer, or credential files are included.

### Geometry

- [ ] Metal and diamond are separate.
- [ ] Shared origin and transforms are preserved.
- [ ] Scale and known dimensions are within tolerance.
- [ ] Diamond facets and normals are correct.
- [ ] No duplicate, loose, or zero-area geometry remains.
- [ ] Triangle counts and bounding box are recorded.

### Visual reference

- [ ] Thumbnail and reference views match the intended HIRA design.
- [ ] Prongs, stone count, center-stone ratio, basket height, and silhouette are approved.
- [ ] No unapproved design change was introduced during optimization.
- [ ] Thumbnail metadata was inspected with `exiftool`; command output or a redacted report is attached to the test evidence.

## 12. Compatibility acceptance test

A submitted model is not runtime-approved until all mandatory items pass:

- the unchanged upstream demo still renders;
- HIRA geometry loads without fatal errors;
- metal and diamond appear in the intended roles;
- the assembled model keeps correct position, scale, and orientation;
- orbit and zoom remain usable;
- no black screen or missing mesh occurs;
- desktop and agreed mobile browsers complete the test;
- the user visually approves the result.

If any mandatory criterion is `FAIL`, do not start the admin upload system. If a criterion is `BLOCKED`, report it as unverified rather than treating it as success.

The required device/browser matrix is defined only in `TEST_PLAN.md` §4.2. Model acceptance reports reference that matrix rather than maintaining a second device list here.

## 13. Change control

- Increment `revision` for every accepted geometry change.
- Preserve the original approved source export outside the public viewer.
- Record why optimization, re-export, or replacement was necessary.
- Do not silently replace a published model.
- Public model replacement must support rollback to the previous approved revision.
