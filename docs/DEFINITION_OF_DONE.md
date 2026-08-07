# HIRA Diamond WebGL — Definition of Done

Status: v1.0  
Applies to: every task, milestone, and release in this repository

## 1. Core rule

“Code written,” “build passed,” and “screenshot produced” do not individually mean done. A task is DONE only when all criteria for its level are satisfied and evidence is recorded.

Allowed task states:

- NOT STARTED
- IN PROGRESS
- BLOCKED
- READY FOR REVIEW
- DONE

Do not use DONE when a required check is BLOCKED or FAIL.

## 2. Universal task completion criteria

Every completed task must satisfy all applicable items:

### Scope

- [ ] The implemented behavior matches the authorized task and no unrelated feature was added.
- [ ] Excluded scope in `AGENTS.md` was not introduced.
- [ ] No protected minified script was edited without explicit approval.
- [ ] Existing user changes and upstream GPL files were preserved.

### Code and files

- [ ] Source-of-truth files were edited, not generated `dist/` output.
- [ ] File and model rules are followed.
- [ ] No credentials, customer data, private model, temporary export, or `node_modules/` entered Git.
- [ ] New configuration has a documented default and failure behavior.
- [ ] There is no placeholder presented as production data.

### Verification

- [ ] The smallest relevant automated checks were executed. **Minimum checks by task type:**
  - Documentation-only: `git diff --check`, link validation, status/version verification
  - Model package: JSON parsing, file naming regex, geometry measurements, metadata inspection
  - Build/runtime change: `npm run build` exit code 0, expected files exist and non-empty, `git diff --check`
  - Browser-affecting: above + real browser test or BLOCKED (no responsive viewport substitution)
- [ ] `npm run build` passes when application source or runtime assets changed.
- [ ] Expected build files exist and are non-empty.
- [ ] Browser-affecting changes were tested in a real browser or marked BLOCKED.
- [ ] Console/network failures were reviewed and categorized (WARNING/ERROR/FATAL/CRASH per TEST_PLAN.md §5).
- [ ] Every result is labeled PASS, CONDITIONAL, FAIL, or BLOCKED.

### Documentation

- [ ] User-visible behavior or workflow changes are documented.
- [ ] Test evidence records branch, commit, environment, asset revision, and result.
- [ ] Known limitations and follow-up work are explicit.
- [ ] Material GPL changes are queued for `CHANGELOG.md` before public release.

### Review and handoff

- [ ] Git diff was reviewed for accidental changes and whitespace errors.
- [ ] Another reviewer/agent checks milestone-level work when available.
- [ ] The user receives a concise account of what changed, what was verified, and what remains blocked.
- [ ] No push, deployment, DNS change, or publication occurred without explicit authorization.

## 3. Documentation-only task DONE

A documentation task is DONE when:

- [ ] statements are consistent with `AGENTS.md` and existing repository facts;
- [ ] uncertain behavior is labeled as unverified rather than asserted;
- [ ] filenames, commands, and paths match the repository;
- [ ] `git diff --check` passes;
- [ ] links and referenced files exist;
- [ ] the document clearly identifies its status/version;
- [ ] no application behavior is claimed as tested solely because a document was written.

## 4. Model package DONE

A model package is DONE only when:

- [ ] it follows `MODEL_AND_FILE_RULES.md`;
- [ ] `metal.obj`, `diamond.obj`, thumbnail, and `model-info.json` are present;
- [ ] product ID and filenames pass validation;
- [ ] measured counts, sizes, dimensions, unit, and exporter version are recorded;
- [ ] metal and diamond share the same origin and transform;
- [ ] scale matches known dimensions within 1% or a deviation is explicitly accepted;
- [ ] normals, duplicate geometry, loose geometry, and zero-area faces were inspected;
- [ ] diamond facets remain sharp and geometrically faithful;
- [ ] prong count/position, basket height, stone ratio, and silhouette match the approved reference;
- [ ] private/customer metadata is absent;
- [ ] the user approves the model for compatibility testing.

This status means “source package ready for engine testing,” not “customer runtime approved.”

## 5. Compatibility gate DONE

The compatibility milestone is DONE only when:

- [ ] T0 repository baseline tests PASS;
- [ ] the unchanged upstream jewelry demo renders;
- [ ] runtime roles of `ring.obj` and `engagement-ring.obj` are documented through controlled tests;
- [ ] one approved HIRA solitaire loads without editing protected scripts;
- [ ] metal and diamond appear in intended roles;
- [ ] position, scale, orientation, and camera framing are acceptable;
- [ ] orbit and zoom work;
- [ ] no fatal console error, black canvas, or missing mesh occurs;
- [ ] protected script hashes match the baseline;
- [ ] required desktop test passes;
- [ ] required mobile tests pass or have explicitly accepted CONDITIONAL limitations;
- [ ] evidence includes screenshots, environment details, and model revision;
- [ ] the user gives visual approval;
- [ ] an overall gate decision is recorded using `TEST_PLAN.md`.

Until this milestone is DONE, admin upload/API development remains blocked.

## 6. Customer viewer MVP DONE

This section becomes applicable only after the compatibility gate.

- [ ] Product-specific customer URL loads the intended approved model.
- [ ] Rotation, zoom, reset, loading, and error behavior work.
- [ ] Customer cannot access unpublished/private product files.
- [ ] Mobile controls do not trap or break normal navigation.
- [ ] Cafe24 return/purchase link opens the intended product page.
- [ ] Missing/corrupt model shows a recoverable message or approved fallback.
- [ ] Required desktop/mobile matrix is executed.
- [ ] Accessibility basics are checked: control names, focus visibility, contrast, and touch target usability.
- [ ] GPL attribution and corresponding-source path are available.
- [ ] HIRA visually approves the customer screen.

## 7. Admin upload MVP DONE

**Activation gate**: This section applies ONLY after §5 (Compatibility gate DONE) is PASS.

Before this phase starts:
- [ ] Compatibility gate is PASS (one approved HIRA solitaire loads and renders correctly)
- [ ] User explicitly authorizes admin development phase
- [ ] Legal review has addressed GPL implications for deployment

When active, admin upload MVP is DONE only when:

- [ ] Administrator authentication and logout work.
- [ ] Unauthenticated users cannot access admin APIs or private models.
- [ ] Product creation defaults to draft/unpublished.
- [ ] Operator explicitly selects metal and diamond files; no unapproved auto-classification is used.
- [ ] Naming, JSON, size, and geometry validation run before publication (per MODEL_AND_FILE_RULES.md).
- [ ] Admin preview uses the same approved viewer path as customers.
- [ ] Publish/unpublish transitions are logged and enforced.
- [ ] Product link generation is deterministic and collision-safe.
- [ ] Invalid, missing, corrupt, and oversized file errors have tested recovery paths (per TEST_PLAN.md §12).
- [ ] Published model replacement supports rollback (version history preserved).
- [ ] Backup and recovery procedure is documented and tested once.
- [ ] Secrets remain outside source control.
- [ ] Security review finds no known critical issue and documents attack surface.

## 8. Cafe24/Gabia integration DONE

**Activation gate**: This section applies ONLY after §7 (Admin upload MVP DONE) is PASS.

Before this phase starts:
- [ ] Admin upload MVP is PASS and in production
- [ ] At least one product has been published through admin interface with 2+ weeks stability
- [ ] User explicitly authorizes Cafe24 integration work
- [ ] Legal review has completed deployment/commercial use verification

When active, Cafe24/Gabia integration is DONE only when:

- [ ] Viewer and admin services use approved independent subdomains (approved by DNS owner).
- [ ] Existing root and `www` DNS records were captured and documented before any changes.
- [ ] Only authorized viewer/admin records were added; no unrelated records modified.
- [ ] HTTPS is valid for both services (cert check and browser verification).
- [ ] Cafe24 product page links to the correct product-specific viewer URL.
- [ ] Initial integration uses the approved new-window/full-screen approach unless iframe use is separately authorized.
- [ ] Viewer failure does not break the Cafe24 product page (fallback/error path tested).
- [ ] A rollback procedure for DNS and the Cafe24 button is documented and tested once.
- [ ] No DNS or production change is made without explicit user authorization; all changes logged.

## 9. Release DONE

A release is DONE only when:

- [ ] all included milestones are DONE;
- [ ] release scope and commit SHA are frozen;
- [ ] production build passes from a clean checkout;
- [ ] regression suite passes on the release candidate;
- [ ] backup and rollback artifacts exist;
- [ ] GPL license, attribution, modification record, and corresponding source are published as required;
- [ ] legal review of GPL/commercial deployment is complete;
- [ ] security and privacy checks are complete;
- [ ] one-product limited rollout is approved before wider catalog rollout;
- [ ] monitoring and incident owner are identified;
- [ ] the user explicitly authorizes production deployment.

## 10. Stop conditions

Stop the dependent work and report immediately when:

- a HIRA model cannot render in the baseline without protected-script modification;
- metal and diamond roles cannot be determined reliably;
- a test reveals fatal browser errors or repeatable WebGL context loss;
- mobile devices cannot complete the basic customer interaction;
- a required private asset, device, permission, or credential is unavailable;
- work would expose credentials, customer data, or an unapproved design;
- GPL obligations cannot be satisfied or remain legally unresolved for launch;
- proceeding requires deployment, DNS, push, or publication beyond current authorization.

Do not work around a stop condition by substituting sample assets, hiding errors, or reporting an unexecuted test as PASS.

## 11. Completion report template

Use this template for every milestone:

```text
Milestone:
Scope completed:
Branch / commit:
Model product ID / revision:
Automated tests:
Desktop browser tests:
Mobile tests:
Protected-script integrity:
GPL/documentation updates:
Known limitations:
Blocked items:
User approval:
Final state: DONE | READY FOR REVIEW | BLOCKED
Next authorized action:
```
