# CommandDeck

TODO: Delete this and the text below, and describe your gem

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/command_deck`. To experiment with that code, run `bin/console` for an interactive prompt.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/command_deck. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/command_deck/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the CommandDeck project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/command_deck/blob/master/CODE_OF_CONDUCT.md).

# Command Deck (Rails Gem)

A tiny **dev‑only** Rails engine that gives you a quick **CRUD UI for any model** and a **simple command runner** (buttons/inputs) so you don’t have to open `rails console` for everyday tasks.

> Scope for v0: **development only**, zero prod features, minimal DSL, fast to drop into any app.

---

## ✨ What it does (v0)

* **Model CRUD (fast)**: pick a model, list/create/update/destroy rows.
* **Command Runner**: define tiny snippets as buttons with a couple of params.
* **Dev‑only**: only mounts in `Rails.env.development?`.

Examples it should handle out of the box:

* `Buk::Feature.enable(:flag) / disable / enabled?`
* `General.habilitar_omniauth` (read)
* `General.find_or_initialize_by(nombre: "general").update!(valor: "true")`
* Kick/retry jobs, toggle booleans, run small backfills on a scoped set.

---

## 📦 Installation (dev only)

Add the gem (local path while developing your own):

```ruby
# Gemfile
gem "command_deck", path: "../command_deck" # or gem "command_deck"
```

Mount the engine only in dev:

```ruby
# config/routes.rb
if Rails.env.development?
  mount CommandDeck::Engine => "/command_deck"
end
```

Minimal initializer (optional in v0):

```ruby
# config/initializers/command_deck.rb
CommandDeck.configure do |c|
  c.authorize = ->(_user, _action) { true } # dev only, keep it wide open
end
```

---

## 🧩 Minimal DSL (panels, tabs, actions)

Create files under `app/command_deck/**/*.rb`.

```ruby
# app/command_deck/panels/buk_examples.rb
CommandDeck.panel "Buk" do
  tab "Features" do
    action "Enable feature", key: "buk.features.enable" do
      param :key, :string
      perform { |p, _| { ok: Buk::Feature.enable(p[:key].to_sym) } }
    end

    action "Disable feature", key: "buk.features.disable" do
      param :key, :string
      perform { |p, _| { ok: Buk::Feature.disable(p[:key].to_sym) } }
    end

    action "Enabled?", key: "buk.features.enabled" do
      param :key, :string
      perform { |p, _| { enabled: Buk::Feature.enabled?(p[:key].to_sym) } }
    end
  end

  tab "General" do
    action "Mostrar omniauth", key: "buk.general.omniauth" do
      perform { |_| { habilitado: General.habilitar_omniauth } }
    end

    action "Forzar general true", key: "buk.general.force_true" do
      perform do |_p, _|
        g = General.find_or_initialize_by(nombre: "general")
        g.update!(valor: "true")
        { id: g.id, valor: g.valor }
      end
    end
  end
end
```

**Param types in v0:** `:string`, `:boolean`, `:integer` (that’s it). More can come later.

---

## 🧠 Execution model (v0)

* Runs inline in the app process.
* Validates a tiny set of types; values passed to your `perform` block.
* Returns a Ruby hash; rendered as pretty JSON in the UI.
* No transactions/dry‑run in v0 (keep simple). Add later if needed.

---

## 🔐 Security (v0)

* Only mounts in `development`.
* Authorization defaults to allow‑all. No CSRF/rate limits in v0.
* Add proper gates later when/if you enable in staging/prod.

---

## 🧱 Gem structure (super slim)

```
command_deck/
  lib/command_deck.rb
  lib/command_deck/engine.rb
  lib/command_deck/railtie.rb
  lib/command_deck/configuration.rb
  lib/command_deck/registry.rb
  lib/command_deck/executor.rb
  app/controllers/command_deck/{base,home,actions,crud}_controller.rb
  app/views/command_deck/{home/index,actions/_form,crud/index}.html.erb
  config/routes.rb
```

---

## ⚙️ Core code (trimmed for v0)

```ruby
# lib/command_deck/railtie.rb
module CommandDeck
  class Railtie < ::Rails::Railtie
    initializer "command_deck.load_panels", after: :load_config_initializers do
      path = Rails.root.join("app/command_deck")
      Dir[path.join("**/*.rb")].sort.each { |f| load f } if Dir.exist?(path)
    end
  end
end
```

```ruby
# lib/command_deck/registry.rb
module CommandDeck
  class Registry
    Action = Struct.new(:title, :key, :params, :block, keyword_init: true)
    Tab    = Struct.new(:title, :actions, keyword_init: true)
    Panel  = Struct.new(:title, :tabs, keyword_init: true)

    class << self
      def panels = (@panels ||= [])
      def panel(title, &blk); PanelBuilder.new(title).tap { _1.instance_eval(&blk) }.build.then { panels << _1 }; end
      def find_action(key)
        panels.each { |p| p.tabs.each { |t| t.actions.each { |a| return a if a.key == key } } }
        nil
      end
    end

    class PanelBuilder
      def initialize(title) = (@title, @tabs = title, [])
      def tab(title, &blk) = (@tabs << TabBuilder.new(title).tap { _1.instance_eval(&blk) }.build)
      def build = Panel.new(title: @title, tabs: @tabs)
    end

    class TabBuilder
      def initialize(title) = (@title, @actions = title, [])
      def action(title, key:, &blk)
        @actions << ActionBuilder.new(title, key).tap { _1.instance_eval(&blk) }.build
      end
      def build = Tab.new(title: @title, actions: @actions)
    end

    class ActionBuilder
      def initialize(title, key)
        @title, @key, @params, @block = title, key, [], nil
      end
      def param(name, type, **opts) = (@params << { name: name, type: type, **opts })
      def perform(&b) = (@block = b)
      def build = Action.new(title: @title, key: @key, params: @params, block: @block)
    end
  end

  def self.panel(title, &blk) = Registry.panel(title, &blk)
end
```

```ruby
# lib/command_deck/executor.rb
module CommandDeck
  class Executor
    def self.call(key:, params:, controller:)
      action = Registry.find_action(key) or raise ArgumentError, "Unknown action #{key}"
      coerced = coerce(action.params, params)
      action.block.call(coerced, {}) # no ctx in v0
    end

    def self.coerce(schema, raw)
      out = {}
      schema.each do |p|
        v = raw[p[:name].to_s]
        v = (v == "1" || v == true) if p[:type] == :boolean
        v = v.to_i if p[:type] == :integer
        out[p[:name]] = v
      end
      out
    end
  end
end
```

```ruby
# config/routes.rb (inside gem)
CommandDeck::Engine.routes.draw do
  root to: "home#index"
  resources :actions, only: [:create]
  get ":model", to: "crud#index", as: :crud # /command_deck/User
end
```

```ruby
# app/controllers/command_deck/crud_controller.rb
module CommandDeck
  class CrudController < BaseController
    def index
      model = params[:model].classify.safe_constantize or raise ActiveRecord::RecordNotFound
      @columns = model.columns.map(&:name)
      @records = model.limit(50).order(model.primary_key => :desc)
    end
  end
end
```

```erb
<!-- app/views/command_deck/crud/index.html.erb -->
<h2>CRUD: <%= params[:model].classify %></h2>
<table>
  <thead>
    <tr>
      <% @columns.each { |c| %><th><%= c %></th><% } %>
    </tr>
  </thead>
  <tbody>
    <% @records.each do |r| %>
      <tr>
        <% @columns.each { |c| %><td><%= r.public_send(c) %></td><% } %>
      </tr>
    <% end %>
  </tbody>
</table>
```

```erb
<!-- app/views/command_deck/actions/_form.html.erb (unchanged idea, minimal inputs) -->
```

---

## 🧪 Testing tips (v0)

* Smoke-test the mount path in dev.
* Unit-test your action blocks as plain Ruby.

---

## ✅ Roadmap (next)

* Transactions + `dry_run` via SAVEPOINT
* More field types (enum/model pickers)
* CSV/JSON export
* Small allowlist for CRUD models to avoid `constantize` footguns
* Basic auth & CSRF so it can be enabled in staging if desired
