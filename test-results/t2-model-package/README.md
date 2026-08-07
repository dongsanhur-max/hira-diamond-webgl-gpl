# T2 Model Package Validation

Date: 2026-08-07
Result: **FAIL**

## Submitted Input

The user supplied one source file named `Ring.obj`. It was inspected in place
and was **not** copied into this repository or any public runtime path.

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

## T2 Checks

| Check | Result | Evidence / impact |
| --- | --- | --- |
| T2-01 required files | FAIL | `metal.obj`, `diamond.obj`, `model-info.json`, and a supplied `thumbnail.webp` or `thumbnail.jpg` are absent. |
| T2-02 naming and JSON | FAIL | No product-ID directory or `model-info.json`; source unit and export scale are undeclared. |
| T2-03 separate geometry measurements | FAIL | A mixed single OBJ cannot prove role separation, shared origin, or separate bounds. |
| T2-04 CAD/Blender inspection | BLOCKED | Requires the explicitly separated exports, known dimensions, reference image, and CAD/export details. |

T2 cannot advance to T4. The runtime samples remain unchanged.

## Required Resubmission

Provide one product-ID directory outside `docs/`, for example:

```text
ring-001/
  metal.obj
  diamond.obj
  thumbnail.webp
  model-info.json
  reference-front.jpg  # recommended
```

The exporter must create `metal.obj` and `diamond.obj` explicitly in CAD or
Blender with a common origin, applied transforms, and no geometry-role swaps.
Do not rename or split the submitted `Ring.obj` by material name as a
substitute. Include `sourceUnit: "mm"`, export scale, measured triangle counts,
and measured millimeter bounding box in `model-info.json`.