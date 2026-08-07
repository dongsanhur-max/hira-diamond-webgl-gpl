# T4b — Procedural Gem Parametrization Investigation

Date: 2026-08-07
Branch: `compat/t4b-gem-parametrization`
Result: **Dead end for this approach; do not pursue further via UI edits**

## Question

Could HIRA skip the "merge metal.obj + diamond.obj into one support OBJ"
approach entirely, and instead render the diamond using the engine's own
existing procedural gem shader (already used for the built-in `Gems: 9`
overlay), parametrized to match the real stone (oval, 5.8×8.1×3.6mm, 1.03ct)?
This would avoid the T4 "single support shader" material-role problem
without touching protected scripts.

## What is genuinely supported (read-only finding, no protected file edited)

Static inspection of `docs/jewelry/script/main.min.js` (read-only, not
modified) shows the underlying engine defines all nine standard cuts:

```
n.ASSCHER="asscher", n.CUSHION="cushion", n.EMERALD="emerald",
n.MARQUISE="marquise", n.OVAL="oval", n.PEAR="pear",
n.PRINCESS="princess", n.RADIANT="radiant", n.ROUND="round"
```

Oval has its own component class (`Oval` from module `6930`) and its own
default gem color in at least one lookup table, so the engine's procedural
gem system does support oval cuts natively somewhere.

## Experiment: expose Oval in the jewelry demo UI

`docs/jewelry/index.html` (not a protected file) has a "Major gem cut"
control with only `Cushion`/`Round` radio options. A third radio,
`value="oval"`, was added temporarily to test whether the UI-to-engine
wiring is generic (reads whatever value is selected) or hardcoded to the two
existing options.

### Result 1 — Ring 1 (`engagement-ring`) scene

Selecting the new Oval option produced **no visible or console-observable
change**. Screenshots before/after are pixel-different only in
incidental/background noise (the rendered gem itself is unchanged — same
round diamond, same facet pattern):
[ring1-before-oval-click.png](ring1-before-oval-click.png),
[ring1-after-oval-click.png](ring1-after-oval-click.png).

This is expected: the "Major/Minor gem cut" control section is not the
control for Ring 1's single center stone at all — it is hidden for Ring 1 in
the unmodified upstream HTML.

### Result 2 — Ring 2 (`ring`) scene: unintended breakage

On the `ring` scene, `getComputedStyle` showed the whole
`#control-major-gem-tabs-id` section had `display: none` — even though this
control is visible on Ring 2 in the **unmodified** upstream page. Adding a
third radio option to an existing `name="major-gem-tabs-id"` group appears
to break whatever generic tab-count/pairing assumption the protected script
uses to decide when to show this control. No console error or exception was
observed; the control simply stayed hidden. See
[ring2-canvas.png](ring2-canvas.png) for the scene the test was run against.

**The experimental HTML change was reverted immediately after this was
observed** (`git checkout -- docs/jewelry/index.html`); the repository is
back to the unmodified upstream page. No protected script was edited at any
point.

## Conclusion

The engine's procedural gem system supports oval cuts at the data-model
level, but the specific jewelry demo page's UI wiring is not a simple
generic "read whatever value is selected" binding — it carries undocumented
assumptions (apparently including an expected option count per tab group)
that break in non-obvious ways when a third option is added, even though no
protected file is edited. Chasing this further would mean reverse-engineering
increasingly more of `main.min.js`'s internal control-binding logic to find
a way to add a working third option, which is the kind of "reverse-engineering
main.min.js" `AGENTS.md` explicitly excludes from scope.

**This path is not recommended.** It does not offer a clean, low-risk way to
get distinct metal/diamond material roles without deeper, riskier engagement
with the protected script's internals than a `docs/`-only edit can safely
achieve.

## Recommendation for the next decision

The two remaining options from the T4 report stand:

1. Derive a proper mm-to-engine-unit scale constant (currently only a
   first-pass approximation, `--scale=0.1111`) so a merged support OBJ at
   least renders at a defensible size — this does not solve the material-role
   problem, only keeps the current (FAIL) T4 approach honest about scale.
2. Decide whether to submit an explicit protected-script change proposal
   under `AGENTS.md` §4 (blocking behavior, evidence that config/asset
   replacement can't solve it — which this investigation now provides —
   proposed change, GPL implications, rollback plan) to get genuine
   metal/diamond material distinction from the engine, or accept that this
   compatibility gate cannot pass with the current baseline engine as-is.

This is a scope/business decision, not a technical one this investigation
can resolve on its own.
