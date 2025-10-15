# CHANGELOG

## [0.3.2] - 2025-10-15

### Added

- **Auto-populate feature**: New `auto_populate: true` option for params that automatically fills text/number inputs with values from selector meta data
- **Dark mode support**: Panel selector now properly respects dark theme settings
- **Form accessibility improvements**: All form inputs now have proper `id`, `name`, `for`, and `autocomplete` attributes for better accessibility and browser compatibility

### Fixed

- **Dropdown text overflow**: Long labels in selectors are now properly truncated (50 chars for action params, 35 chars for panel selector) with full text shown on hover
- **Select2 conflict prevention**: Added `data-select-type="default"` to prevent third-party select enhancement libraries from interfering with Command Deck selectors
- **CSS cascade issues**: Fixed dark mode styles not applying due to CSS specificity problems

### Changed

- **DRY code improvements**: Extracted label truncation logic into shared `truncateLabel()` utility function in `core/dom.js`
- Better hint display: "Current:" hints now only show for boolean values (ON/OFF badges), while string values are populated directly in inputs

## [0.3.1] - 2025-10-10

### Fixed

- Fixed bugs related to the load of panels and middleware insertion.

## [0.3.0] - 2025-10-10

### Added

- **Auto-discovery**: Panels can now be defined in any `command_deck` directory (e.g., `app/command_deck`, `packs/**/command_deck`)
- **Automatic middleware insertion**: Middleware is now auto-injected when `COMMAND_DECK_ENABLED=true` in development
- **Flexible namespacing**: Use any namespace that matches your project structure (e.g., `CommandDeck::Panels`, `DevTools::Panels`)

### Changed

- **Zero configuration required in application.rb**: No need to manually add autoload paths or middleware
- Improved documentation with examples for modularized monoliths (packwerk/pack-rails)
- Recommended gem group changed to `:development, :test` for better Sorbet/Tapioca compatibility

### Migration from 0.2.0

**Before (0.2.0):**

```ruby
# config/application.rb
config.middleware.insert_after ActionDispatch::DebugExceptions, CommandDeck::Middleware if Rails.env.development?

# app/command_deck/panels/global.rb
module Panels
  class Global < CommandDeck::BasePanel
    # ...
  end
end
```

**After (0.3.0):**

```ruby
# config/application.rb - NO CONFIG NEEDED!
# Just set COMMAND_DECK_ENABLED=true in your .env

# app/command_deck/panels/global.rb
module CommandDeck::Panels  # More descriptive namespace
  class Global < CommandDeck::BasePanel
    # ...
  end
end
```

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
