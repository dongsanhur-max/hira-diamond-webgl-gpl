# T3 Runtime Mapping Evidence

Date: 2026-08-07

Scope: canonical `docs/jewelry/` runtime. Protected minified scripts were not
changed. This evidence is stored outside `docs/` so the static-site build does
not copy it into `dist/`.

## Reproducible Marker

[`marker-cube.obj`](marker-cube.obj) is the exact harmless test asset used in
M1 and M2. It is 434 bytes, SHA-256
`48db61ed858d53099781ba454a76b697884649b83421e2ec54d9f2a4fc80ed4f`, and
contains exactly 8 `v` records and 12 triangular `f` records. No customer,
HIRA, or third-party design asset was used in this experiment.

## Method and Results

Each experiment used a fresh headless Chromium context against the Vite local
server. The JSON logs preserve the HTTP status, byte count, and SHA-256 of the
actual OBJ response body received by the browser; this directly verifies the
loaded content. Screenshots provide the required initial and rotated views.

| Experiment | Temporary replacement | Browser-proven response | Result |
| --- | --- | --- | --- |
| M0 | none | `engagement-ring.obj`: 1,366,647 bytes, `05714a04...`; `ring.obj`: 444,480 bytes, `32e5eca1...` | PASS |
| M1 | `ring.obj` = `marker-cube.obj` | `ring.obj`: 434 bytes, `48db61ed...` | PASS |
| M2 | `engagement-ring.obj` = `marker-cube.obj` | `engagement-ring.obj`: 434 bytes, `48db61ed...` | PASS |
| M3/M4 | HIRA candidates | Not run | BLOCKED: no approved HIRA package passed T2. |

- M0: [runtime log](M0-runtime.json), [initial](M0-initial.png), [rotated](M0-rotated.png)
- M1: [runtime log](M1-runtime.json), [initial](M1-initial.png), [rotated marker](M1-marker-rotated.png)
- M2: [runtime log](M2-runtime.json), [initial marker](M2-marker-initial.png), [rotated marker](M2-marker-rotated.png)

The engine console logged both filenames as `Retrieving of support model`.
Every OBJ request returned HTTP 200; no request failed and no fatal console
error occurred. The only warnings were Chromium WebGL `ReadPixels` GPU-stall
performance messages while capturing screenshots.

## Triangle Counter Clarification

The on-screen `Triangles` count is a scene total, not a support-OBJ face count.
With the 12-face marker, M1 still displayed `Triangles: 14,268` and `Gems: 81`;
M2 displayed `Triangles: 994` and `Gems: 9`. Those numbers include runtime gem
geometry, so they cannot identify the support model. The response-body SHA-256
records above are the authoritative proof that the 12-face marker was loaded.

## Mapping Conclusion

| Runtime filename | UI selection | Proven engine role |
| --- | --- | --- |
| `engagement-ring.obj` | `Ring 1` (default) | Complete support/ring model |
| `ring.obj` | `Ring 2` (lazy-loaded) | Complete support/ring model |

T3 upstream role mapping is **PASS**: both filenames are alternate complete
support-model scenes, not separate metal and diamond slots. Directly mapping a
HIRA `metal.obj` and `diamond.obj` pair to these two filenames is unsupported;
M3/M4 remain blocked pending an approved T2 package and an adapter design.