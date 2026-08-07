# Changelog

All notable modifications to the upstream GPL `diamond-webgl` baseline are recorded here. This project follows the structure of Keep a Changelog; versions are assigned when a release is prepared.

## [Unreleased]

### Added

- Vite-based static development and build wrapper for the preserved upstream files.
- Repository-wide agent, model/file, test-plan, and definition-of-done rules.
- Explicit GPL legal-review procedure and commercial-launch deadline.
- Required mobile-device matrix, console/WebGL classifications, and post-T5 performance-baseline procedure.
- Model metadata, numeric-precision, security-review, agent-ownership, and phased Cafe24/Gabia criteria.
- Committed SHA-256 manifest and reproducible verification procedure for all six protected minified scripts.
- T3 runtime-mapping evidence and screenshots for the upstream jewelry OBJ slots.

### Changed

- Declared `docs/jewelry/` as the canonical jewelry demo path while preserving the upstream `docs/jewelery/` path.
- Replaced hardcoded GitHub Pages illustration paths in the runtime HTML with repository-relative asset paths.

### Security

- Added release gates for secrets, private/customer data, admin authorization, upload validation, and scored security findings.

## Release-entry guide

For each release, move relevant items out of `[Unreleased]` into a dated section such as `## [0.1.0] - YYYY-MM-DD`. Describe behavior and licensing-impacting modifications, not only commit hashes. Keep entries concise and link the release to its exact Git commit or tag.
