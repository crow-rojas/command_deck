# Command Deck

![Demo](public/img/demo.gif)

Command Deck is a tiny, dev-only Rails engine that gives you a floating panel to run custom actions and quick admin tasks without opening Rails console.

You define panels/tabs/actions in a minimal DSL. Each action can declare a few params (text, boolean, number, selector), run Ruby code, and return a JSON-ish result shown in the UI.

## Installation

Add the gem to your application:

```ruby
# Gemfile (development only recommended)
group :development do
  gem "command_deck"
end
```

Mount the engine (dev only):

```ruby
# config/routes.rb
if Rails.env.development?
  mount CommandDeck::Engine => "/command_deck"
end
```

Start your app and the floating panel should appear.

## Define actions (DSL)

Create Ruby files in `app/command_deck/**/*.rb`. Example:

```ruby
CommandDeck.panel "Utilities" do
  tab "Demo" do
    action "Greet", key: "utils.greet" do
      param :name, :string, label: "Your name", required: true

      perform do |p, _ctx|
        { message: "Hello, #{p[:name]}!" }
      end
    end

    action "Pick a Color", key: "utils.color" do
      # You can pass simple arrays, pairs, or hashes as choices
      param :color, :selector,
        options: [
          ["Red",   "red"],
          ["Green", "green"],
          ["Blue",  "blue"]
        ],
        include_blank: true

      perform do |p, _ctx|
        { chosen: p[:color] }
      end
    end
  end
end
```

This will create a panel called "Utilities" with a tab called "Demo" and two actions: "Greet" and "Pick a Color".

![Demo](public/img/demo.png)

## DSL API

Define panels under `app/command_deck/**/*.rb`.

```ruby
CommandDeck.panel(title, owner: nil, group: nil, key: nil) { ... }
```

Inside a panel, define tabs:

```ruby
tab(title) { ... }
```

Inside a tab, define actions:

```ruby
action(title, key:) { ... }
```

Inside an action, declare params and the code to run:

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
  - Pairs: `[["Label A", "a"], ["Label B", "b"]]`
  - Objects: `{ label:, value:, meta?: { ... } }`

Action execution:

- The block `perform { |params, ctx| ... }` receives your coerced params and a context hash (reserved for future use).
- Return any object serializable to JSON (Hash recommended) to show it in the UI.

## Security

Command Deck is intended for development only. The engine mounts only in dev and skips CSRF by default. **DO NOT ENABLE IT IN PRODUCTION**.

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
