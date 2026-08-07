# Changelog

All notable modifications to the upstream GPL `diamond-webgl` baseline are recorded here. This project follows the structure of Keep a Changelog; versions are assigned when a release is prepared.

## [Unreleased]

### Added

- Vite-based static development and build wrapper for the preserved upstream files.
- Deterministic OBJ merge adapter for the controlled HIRA runtime compatibility experiment, including an optional uniform `--scale` flag needed because HIRA source packages are authored in real-world millimeters while the upstream sample OBJs use a much smaller unrelated engine-unit convention, and `--offset-x`/`--offset-y`/`--offset-z` flags to align the adapter's band/grip-center with the upstream model's own off-origin convention (fixes initial-camera-view clipping).
- Repository-wide agent, model/file, test-plan, and definition-of-done rules.
- Explicit GPL legal-review procedure and commercial-launch deadline.
- Required mobile-device matrix, console/WebGL classifications, and post-T5 performance-baseline procedure.
- Model metadata, numeric-precision, security-review, agent-ownership, and phased Cafe24/Gabia criteria.
- Committed SHA-256 manifest and reproducible verification procedure for all six protected minified scripts.

### Changed

- Declared `docs/jewelry/` as the canonical jewelry demo path while preserving the upstream `docs/jewelery/` path.
- Replaced the experimental HIRA adapter's bounding-box-diagonal scale estimate with a documented 15 mm inner-band calibration (`0.12427608443898043` engine units per millimeter) and recorded fresh T4 runtime, interaction, restoration, and limitation evidence without changing the protected engine.

### Security

- Added release gates for secrets, private/customer data, admin authorization, upload validation, and scored security findings.

## Release-entry guide

For each release, move relevant items out of `[Unreleased]` into a dated section such as `## [0.1.0] - YYYY-MM-DD`. Describe behavior and licensing-impacting modifications, not only commit hashes. Keep entries concise and link the release to its exact Git commit or tag.
