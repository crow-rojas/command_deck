# Command Deck

Convenient, unobtrusive, dev-oriented Rails engine that allows you to run custom actions and quick admin tasks through a floating panel without opening the Rails console.

Define panels/tabs/actions with a minimal class-based DSL. Each action can declare parameters (text, boolean, number, selector), run Ruby code, and return a JSON result shown in the UI.

![Demo](public/img/demo.gif)

## Installation

Add the gem to your application:

```ruby
# Gemfile (development only recommended)
group :development do
  gem 'command_deck'
end
```

Mount the engine:

```ruby
# config/routes.rb
mount CommandDeck::Engine => '/command_deck' if Rails.env.development?
```

Add middleware to inject the floating panel:

```ruby
# config/application.rb

module YourApp
  class Application < Rails::Application
    # ... other config ...
    
    config.middleware.insert_after ActionDispatch::DebugExceptions, CommandDeck::Middleware if Rails.env.development?
  end
end
```

## Define actions

Create panel classes in `app/command_deck/panels/*.rb`:

```ruby
# app/command_deck/panels/utilities.rb
module Panels
  class Utilities < CommandDeck::BasePanel
    panel 'Utilities' do
      tab 'Demo' do
        action 'Greet', key: 'utils.greet' do
          param :name, :string, label: 'Your name', required: true

          perform do |p, _ctx|
            { message: "Hello, #{p[:name]}!" }
          end
        end

        action 'Pick a Color', key: 'utils.color' do
          # You can pass simple arrays, pairs, or hashes as choices
          param :color, :selector,
            options: [
              ['Red',   'red'],
              ['Green', 'green'],
              ['Blue',  'blue']
            ],
            include_blank: true

          perform do |p, _ctx|
            { chosen: p[:color] }
          end
        end
      end
    end
  end
end
```

This creates a panel with a tab and two actions. File path matches constant: `app/command_deck/panels/utilities.rb` → `Panels::Utilities`

![Demo](public/img/demo.png)

## DSL API

Panels inherit from `CommandDeck::BasePanel`. Define tabs within a panel:

```ruby
tab(title) { ... }
```

Define actions within a tab:

```ruby
action(title, key:) { ... }
```

Declare params and execution logic within an action:

```ruby
param(name, type, **opts)
perform { |params, ctx| ... }
```

Supported param types:

- `:string` – free text input.
- `:boolean` – checkbox; coerces to true/false.
- `:integer` – number input; coerces to Integer or nil when blank.
- `:selector` – dropdown. See options below.

Common param options:

- `label:` String – UI label. Defaults to a humanized `name`.
- `required:` true/false – disables Run button until filled. Default: false.

Selector-specific options:

- `options:` Enumerable – static choices.
- `collection:` -> Enumerable – dynamic choices (block is called each render).
- `include_blank:` true/false – prepend an empty choice. Default: false.
- `return:` `:value` (default), `:label`, or `:both` (`{ label:, value: }`).
- Choice shapes accepted:
  - Values: `%w[a b c]`
  - Pairs: `[['Label A', 'a'], ['Label B', 'b']]`
  - Objects: `{ label:, value:, meta?: { ... } }`

The `perform` block receives coerced params and a context hash. Return any JSON-serializable object (Hash recommended).

## Security

Intended for development only. **DO NOT ENABLE IN PRODUCTION**.

## Development

Run tests and lint:

```bash
bundle install
bundle exec rake test
bundle exec rubocop
```

## License

MIT License. See `LICENSE.txt`.

## Code of Conduct

Everyone interacting in this project is expected to follow the [Code of Conduct](https://github.com/crow-rojas/command_deck/blob/master/CODE_OF_CONDUCT.md).
