# HIRA Diamond WebGL — Agent Rules

These instructions apply to the entire repository.

## 1. Project intent

- Build an independent HIRA 3D jewelry viewer from the GPL v3 `diamond-webgl` baseline in this repository.
- Keep the customer viewer separate from HIRA's Cafe24 storefront and from the future admin upload service.
- The first technical gate is one HIRA solitaire OBJ rendered successfully in the unmodified baseline engine.
- Do not reuse code from the discontinued `hira-jewelry-3d-viewer-mit-bvh` project.

## 2. License boundary

- Preserve `LICENSE`, upstream attribution, and the original project link.
- Record material changes in `CHANGELOG.md` before public deployment. Use semantic versioning and document GPL-related changes explicitly.
- Do not remove or hide GPL notices.
- Do not copy Cafe24 proprietary templates, credentials, customer data, or unrelated HIRA private code into this repository.
- Treat the viewer as a separately deployed GPL component. Legal review is required before commercial launch:
  - **Process**: Submit to legal team before any public release or commercial deployment.
  - **Owner**: HIRA Legal/Compliance team.
  - **Timing**: Must complete at least 2 weeks before planned public release.
  - **Criteria**: Verify GPL v3 obligations, commercial use compatibility, and corresponding-source publication plan.

## 3. Current scope

### Phase 1 — Compatibility gate (blocking)

Included:
- Validate the upstream desktop and mobile demos.
- Replace the sample asset manually with one approved HIRA solitaire OBJ package.
- Prove metal and diamond render correctly without protected-script changes.
- Document runtime roles of `ring.obj` and `engagement-ring.obj`.

Explicitly excluded in phase 1:
- GLB material auto-classification.
- Direct editing, beautifying, or reverse-engineering of `main.min.js` or `page.min.js`.
- Rebuilding the discontinued BVH/lookup engine.
- Automatic synchronization of the full Cafe24 product catalog.
- Deployment, DNS changes, or production publication.

### Phase 2+ — After compatibility gate

Customer viewer, admin upload, and Cafe24 integration become in-scope ONLY if phase 1 is PASS. See DEFINITION_OF_DONE.md §6-§8 for activation gates.

Each subsequent phase requires explicit user authorization before starting.

## 4. Protected baseline files

The following are upstream/minified baseline assets and must not be edited during the compatibility gate:

- `docs/script/main.min.js`
- `docs/script/page.min.js`
- `docs/jewelry/script/main.min.js`
- `docs/jewelry/script/page.min.js`
- `docs/jewelery/script/main.min.js`
- `docs/jewelery/script/page.min.js`

If a task appears to require changing one of these files, stop and report:

1. the exact blocking behavior;
2. evidence that configuration, HTML, or asset replacement cannot solve it;
3. the proposed change and GPL implications;
4. a rollback plan.

Do not proceed without explicit user approval.

## 5. Source-of-truth directories

- `docs/`: runtime source served by `npm run dev`.
- `dist/`: generated output from `npm run build`; never hand-edit or commit it.
- `docs/jewelry/`: canonical jewelry demo path for new HIRA work.
- `docs/jewelery/`: preserved upstream legacy misspelling; do not use for new features unless compatibility requires it.
- `docs/model-rules/` or `docs/models/`: future documentation/staging only; runtime assets remain in an explicitly documented runtime path.
- `src/readme/`: upstream documentation images, not application source code.

## 6. Model and file contract

- Follow `docs/MODEL_AND_FILE_RULES.md` for every model submission.
- Never silently repair or reinterpret a model. Record validation failures.
- Source packages keep metal and diamond as explicitly named, separate exports.
- A runtime conversion/adapter may be added only after the baseline loader contract is measured and documented.
- Do not claim that separate `metal.obj` and `diamond.obj` are supported by the upstream runtime until a test proves it.

## 7. Work and Git discipline

- Inspect `git status` before and after work.
- Preserve unrelated user changes and never overwrite them.
- Use one branch per bounded feature after the baseline phase.
- Keep commits focused and descriptive.
- Do not commit `node_modules/`, `dist/`, environment files, credentials, raw customer exports, or temporary model uploads.
- Never use destructive Git commands such as `git reset --hard` or force push.
- Do not commit or push unless the user explicitly includes that operation in the task. The two initial repository setup commits are user-authorized by the setup request.

## 8. Required verification

For code or asset changes, run the smallest relevant checks and report exact results:

1. `npm run build`
2. verify expected HTML, scripts, textures, and models exist in `dist/`
3. run a local server when browser behavior is affected
4. inspect browser console errors on desktop and mobile when available
5. compare the HIRA model against the unchanged upstream sample

Use these result labels only:

- `PASS`: verified and meets the written criterion.
- `CONDITIONAL`: works with a documented minor limitation.
- `FAIL`: criterion not met; do not advance the phase.
- `BLOCKED`: could not be tested; never report this as PASS.

## 9. Compatibility gate

Admin-system development must not begin until all of the following are PASS or explicitly accepted as CONDITIONAL:

- upstream jewelry demo renders;
- one HIRA solitaire model loads;
- metal and diamond display in their intended roles;
- orbit, zoom, and reset behavior work;
- no fatal console error occurs;
- the model remains usable on the agreed desktop and mobile browsers;
- the user visually approves the result.

If the gate fails, document the failure and reassess the engine. Do not hide the problem with fake lighting, screenshots, or substituted sample assets.

## 10. Multi-agent ownership

Use at most three active roles for normal implementation:

- Lead/integration: plans, assigns files, integrates, and maintains documentation.
- Viewer/model: owns viewer HTML, runtime asset integration, and visual compatibility tests.
- Admin/API: starts only after the compatibility gate; owns authentication, upload, metadata, and publication APIs.

A fourth reviewer role may run after a milestone, but should not edit files owned by an active implementation agent.

### File ownership declaration

Before parallel edits, agents must declare file ownership using this format:

```
Agent: [name/role]
Owned files:
  - path/to/file1
  - path/to/file2
Duration: [start date] to [end date or "ongoing"]
Conflict resolution: [name of lead agent or process]
```

Store declarations in `docs/AGENT_OWNERSHIP.md`. If two agents edit the same file:
1. Lead/integration agent resolves the conflict.
2. Document the resolution and re-assign ownership.
3. Notify both agents of the result.
4. Do not merge conflicting changes without explicit resolution.

