# CHANGELOG

## [0.2.0] - 2025-10-09

### Breaking Changes

- Panels must now be defined as classes inheriting from `CommandDeck::BasePanel`
- Panel files define `Panels::*` constants (not `CommandDeck::Panels::*`)
- Middleware is no longer automatically injected (must be added manually in `config/application.rb`)

### Added

- Full Rails autoloading and Zeitwerk compatibility
- Proper class-based panel architecture
- Automatic panel registration via `BasePanel.inherited` hook

### Changed

- Consolidated Railtie into Engine for simpler initialization
- Panels namespace changed: `app/command_deck/panels/global.rb` → `Panels::Global`
- Cleaner, self-documenting code architecture

### Fixed

- Middleware stack freezing conflicts with other gems (Bullet, etc.)
- CI/test environment compatibility
- Zeitwerk constant resolution errors

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
