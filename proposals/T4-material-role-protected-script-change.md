# Proposal: protected-script change to resolve the T4 material-role FAIL

Status: PROPOSAL ONLY -- no protected file has been edited. Per `AGENTS.md`
§4, this package must be reviewed and explicitly approved by the user
before any change described here is implemented. Nothing in this document
authorizes work to begin.

Date: 2026-08-08
Prepared by: Claude (interactive Lead/review session), based on read-only
inspection of `docs/jewelry/script/main.min.js` and `page.min.js` (pre-
authorized under the project's read-only min.js analysis policy) plus the
accumulated evidence from `test-results/t4-hira-load/`,
`test-results/t4b-gem-parametrization/`, and today's T4c work.

## 1. The exact blocking behavior

`TEST_PLAN.md` §10's mandatory T4 visual checks require that HIRA's metal
and diamond display in visually distinct roles (diamond does not appear as
an entirely black/metal object; metal does not receive the diamond optical
treatment). This has been FAIL since the first T4 attempt and remains FAIL
after T4b (dead end) and T4c (CONDITIONAL, scale/camera fixed, material role
untouched).

Root cause, now traced at the code level rather than only observed as a
symptom:

- The engine draws each "support" model (the file named by
  `ESupportModel.RING` = `ring.obj` / `ESupportModel.ENGAGEMENT_RING` =
  `engagement-ring.obj`) through a single `SupportDrawer` class bound to one
  shader pair the minified code calls `Ma1Pxxl*` (`Ma1PxxlVert`/
  `Ma1PxxlFrag`), whose only configurable input is a flat metal color
  (`ma1PxxlColor`, gold vs. platinum/silver RGB based on the metal-type tab).
  There is no per-vertex or per-submesh material distinction available on
  this path -- everything fed through it renders as metal. This is why
  T4/T4c's merged `metal.obj + diamond.obj` adapter (fed entirely through
  this single support model slot) makes the diamond look like dark metal:
  geometrically it's a diamond shape, but it's being shaded as metal.
- Separately, the engine has a real, working gem-rendering path
  (`GemDrawable` / `GemOptions` / `GemDrawerStore.getGemDrawer(cut)`) used
  both for the built-in "Gems: 9" showcase and for the actual center/side
  stones on the *unmodified* upstream engagement-ring and ring scenes. This
  is a proper ray-traced gem shader, not the metal shader.
- For the engagement-ring scene specifically, the class that assembles it
  (an internal `JewelryDrawer` subclass, unnamed in the minified output)
  hardcodes exactly two pre-built `GemDrawable` instances for the major
  stone -- one for `EGem.ROUND`, one for `EGem.CUSHION` -- each with its own
  hand-tuned `GemOptions.modelMatrix` (scale + translate) positioning it
  correctly inside that scene's prong/basket geometry. Its `draw()` method
  selects between exactly these two via
  `Parameters.majorGem === EGem.ROUND ? majorGemRound : majorGemCushion`
  (falls through to Cushion for anything else). This matches the existing
  "Major gem cut" UI control in `docs/jewelry/index.html` (lines ~301-307),
  which offers exactly `cushion`/`round` radio options and nothing else.
- `GemDrawerStore.getGemDrawer()` itself is generic and already supports all
  nine standard cuts (`asscher, cushion, emerald, marquise, oval, pear,
  princess, radiant, round`), including `oval` -- confirmed via the
  `EGem.OVAL` enum entry and the `Oval` component class, and via the
  built-in 9-gem showcase, which already cycles through all nine cuts
  successfully using this same factory. The *factory* is not the
  limitation. The engagement-ring scene's own hand-built class, with its
  hardcoded two-branch selection and lack of a third pre-built instance, is.

In short: the engine's architecture already supports rendering a real,
optically-correct gem alongside separately-shaded metal -- HIRA's model just
isn't wired into that path, because doing so for a cut the original author
didn't anticipate (oval, to match HIRA's actual 5.8x8.1x3.6mm stone) requires
adding a third hardcoded case to a class inside the protected `main.min.js`.

## 2. Evidence that configuration, HTML, or asset replacement cannot solve it

Three independent non-protected-file attempts, in order:

1. **T4** (`test-results/t4-hira-load/`): merged `metal.obj` + `diamond.obj`
   into one adapter OBJ, fed entirely through the single support-model slot.
   Confirmed FAIL: diamond renders as metal, because that slot has no gem
   shading capability at all (see §1).
2. **T4c** (`test-results/t4-hira-load/scale-calibration-v2/`): fixed the
   scale and camera-fit problems on the same merged-adapter approach.
   Explicitly did not and could not touch the material-role problem, since
   it's the same single-shader slot -- CONDITIONAL result records this FAIL
   as unchanged and out of scope for that task.
3. **T4b** (`test-results/t4b-gem-parametrization/`): tried the *other*
   plausible non-protected angle -- add a third "oval" option to the
   existing "Major gem cut" HTML control, hoping the engine's control-to-
   render binding was generic enough to just work. Two things came out of
   re-examining this today: (a) the `Page.Tabs` UI-binding class itself
   (`page.min.js`) is in fact generic -- it reads whatever `<input>`
   elements exist in a `div.tabs[id]` container with no hardcoded count
   check found on inspection, so a third radio *can* be added at the HTML
   level without protected-file changes; but (b) even if that UI-level
   issue T4b hit were fully solved, it would not matter, because the
   engagement-ring scene's `draw()` method (§1) only recognizes
   `EGem.ROUND` and falls back to Cushion for literally any other value,
   including a hypothetical "oval" tab value -- there is no code path for a
   third rendered gem without a corresponding third pre-built `GemDrawable`
   and an extended selection branch, both of which live inside
   `main.min.js`.

Conclusion: no `docs/`-only combination of HTML, CSS, JS glue code, or asset
replacement can make the engagement-ring scene render a third gem cut,
because the scene's own gem-selection logic is a closed two-way branch
inside the protected file. This is a genuine, traced (not just observed)
architectural constraint, not a configuration gap.

## 3. Proposed change and GPL implications

### Proposed change

In `docs/jewelry/script/main.min.js`, inside the engagement-ring
`JewelryDrawer` subclass:

- Add a third field (e.g. `majorGemOval`), constructed identically to the
  existing `majorGemRound`/`majorGemCushion` fields:
  `new GemDrawable(GemDrawerStore.getGemDrawer(EGem.OVAL), gemOptions)`,
  where `gemOptions.modelMatrix` is a new scale/translate pair sized and
  positioned to match HIRA's real oval stone (5.8 x 8.1 x 3.6mm) within the
  existing prong/basket geometry.
- Extend the `draw()` selection from a binary ternary to a three-way lookup
  (or small switch) that also recognizes `EGem.OVAL` and uses
  `majorGemOval`.
- Correspondingly extend `docs/jewelry/index.html`'s "Major gem cut" control
  with a third `oval` radio option (this part is a non-protected HTML edit,
  already shown feasible by T4b's UI-binding finding above).
- HIRA's merge-adapter approach (`scripts/merge-hira-model.mjs`) would
  simplify alongside this: the support-model slot would only need to carry
  HIRA's *metal* geometry (no more merging `diamond.obj` in at all), since
  the diamond would render through this new `GemDrawable` path instead.

This is additive: the existing Round/Cushion behavior for the unmodified
upstream demo is untouched, preserving backward compatibility.

### What is *not* known yet, honestly

The exact `modelMatrix` scale/translate values for the new Oval gem are not
knowable without actually making the edit and visually iterating against
the real prong geometry (the same way Round's `.706232` scale /
`[0, 0, .695862]` translate values were presumably tuned by the original
author, by eye, against that specific model). This could be a quick
iteration or a slower one; I have no reliable estimate. The earlier T4b
`display:none` control-visibility bug also hasn't been fully root-caused
(§2 argues it's moot given the deeper limitation, but if the HTML-level fix
is attempted too, that specific bug would need to be tracked down for real,
not just designed around).

### GPL implications

`main.min.js` is part of the upstream GPL v3 `diamond-webgl` engine
(`AGENTS.md` §1-2). Editing it directly is a materially different posture
from the project's current one (redistribute the unmodified upstream
minified file plus attribution/link):

- This would need to be recorded in `CHANGELOG.md` as a material change
  (`AGENTS.md` §2), with the exact diff reviewed alongside the
  `docs/baseline/protected-scripts.sha256` manifest update (`AGENTS.md` §4's
  explicit process: review the script diff and record approval before
  regenerating the manifest).
- Corresponding-source delivery becomes concretely harder: today the
  project can point to the unmodified upstream source repository as the
  corresponding source. Once `main.min.js` itself is modified without an
  unminified source counterpart in this repo, providing "corresponding
  source" for the *modified* portions is a real, not theoretical,
  obligation -- likely requiring either reconstructing readable source for
  the changed region or otherwise documenting the exact modification in a
  form a recipient could apply to rebuild it.
- This adds a new, concrete trigger for the GPL/commercial-release legal
  review already required before any customer-facing commercial URL
  (`AGENTS.md` §2) -- the reviewing lawyer would specifically need to look
  at this modification and the corresponding-source plan for it, not just
  the unmodified-baseline posture. Worth surfacing to the business owner
  now, even though the review itself isn't due until commercial launch.

## 4. Rollback plan

- Develop on a dedicated branch (not `main`), following the existing
  `compat/*` pattern.
- Keep the current `main.min.js` as the baseline of record; its SHA-256 is
  already pinned in `docs/baseline/protected-scripts.sha256` and has been
  independently re-verified as unchanged (6/6 `OK`) throughout every T4/T4b/
  T4c experiment to date.
- Per `AGENTS.md` §4's explicit process, the manifest is only regenerated
  after the script diff is reviewed and the change is approved -- not
  before, and not as a side effect of an unrelated commit.
- Reverting is a straight file-level restore from the pinned baseline (the
  same operation already used repeatedly today for the temporary
  `engagement-ring.obj` swaps), plus re-running the six-file hash check to
  confirm. No other system depends on the modified region, so no cascading
  cleanup is expected.

## Decision needed

Per `AGENTS.md` §4: **do not proceed without explicit user approval.** This
document is the stop-and-report; implementation has not started and won't
without a separate, explicit go-ahead.
