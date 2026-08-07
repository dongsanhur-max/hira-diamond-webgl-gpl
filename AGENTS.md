# HIRA Diamond WebGL — Agent Rules

Status: v1.1

These instructions apply to the entire repository.

## 1. Project intent

- Build an independent HIRA 3D jewelry viewer from the GPL v3 `diamond-webgl` baseline in this repository.
- Keep the customer viewer separate from HIRA's Cafe24 storefront and from the future admin upload service.
- The first technical gate is one HIRA solitaire OBJ rendered successfully in the unmodified baseline engine.
- Do not reuse code from the discontinued `hira-jewelry-3d-viewer-mit-bvh` project.

## 2. License boundary

- Preserve `LICENSE`, upstream attribution, and the original project link.
- Record material changes in `CHANGELOG.md` as part of the same commit or pull request.
- Do not remove or hide GPL notices.
- Do not copy Cafe24 proprietary templates, credentials, customer data, or unrelated HIRA private code into this repository.
- Treat the viewer as a separately deployed GPL component.
- GPL/commercial-release review owner: the HIRA business owner is accountable for commissioning the review; a qualified Korean copyright/software-license lawyer selected by that owner performs it.
- Review procedure: provide the lawyer with the upstream source/link, `LICENSE`, `CHANGELOG.md`, deployed build, corresponding-source delivery plan, attribution screen, deployment architecture, and all third-party dependency licenses; record the written decision or required actions in a private legal record and record only the completion date/status in the release checklist.
- Deadline: complete the review before the first customer-accessible commercial URL, Cafe24 link, paid campaign, or production deployment. A repository build or private compatibility test is not commercial launch approval.

## 3. Current scope

Included in the first implementation phase:

- Validate the upstream desktop and mobile demos.
- Replace the sample asset manually with one approved HIRA solitaire OBJ package.
- Add a customer-facing product URL and minimal viewer controls only after the model gate passes.
- Later, add an admin flow in which the operator explicitly selects metal and diamond files.

Explicitly excluded unless the user changes scope:

- GLB material auto-classification.
- Direct editing, beautifying, or reverse-engineering of `main.min.js` or `page.min.js`.
- Rebuilding the discontinued BVH/lookup engine.
- Automatic synchronization of the full Cafe24 product catalog.
- Cafe24/Gabia integration before the compatibility gate passes and the user separately authorizes that phase.
- Deployment, DNS changes, GitHub push, or production publication without explicit approval.

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

Before parallel edits, every agent must post this declaration in the task/PR discussion or shared work log:

```text
Agent/role:
Task:
Owned files or globs:
Expected handoff:
Dependencies on other agents:
```

Rules:

1. Ownership is temporary and task-scoped; it does not grant permission to change protected files.
2. Two active agents must not claim the same file or overlapping glob.
3. The lead records declarations and reports the final ownership map in the milestone handoff.
4. On overlap, both agents stop edits to the affected files, preserve their diffs, and notify the lead.
5. The lead resolves the conflict by splitting files, sequencing handoffs, or assigning one integrator. No agent resolves it by overwriting another diff.
