# CHANGELOG

## [0.1.3] - 2025-09-23

- Unchilenizes the README file

## [0.1.2] - 2025-09-11

### Added

- Support for Turbolinks.
- Copy to clipboard button for results.
- Toggle results visibility button.
- Refactor overlay.js into multiple files.

## [0.1.1] - 2025-09-10

### Fixed

- Fix RuboCop offenses.

## [0.1.0] - 2025-09-10

### Added

- Dev-only Rails engine with floating UI panel.
- Minimal DSL: `panel`/`tab`/`action` with `param` support for `:string`, `:boolean`, `:integer`, `:selector`.
- Selector return modes: `:value` (default), `:label`, `:both`.
- Option `meta` passthrough for selectors and UI hint badge for current boolean state.
- Auto-refresh of panel after running an action and remember last selector choice.
- JSON pretty result viewer in the UI.

### Internal

- Registry, Executor, Middleware, basic controllers and assets pipeline.
- Minitest suite and SimpleCov.
