# frozen_string_literal: true

require_relative "lib/command_deck/version"

Gem::Specification.new do |spec|
  spec.name = "command_deck"
  spec.version = CommandDeck::VERSION
  spec.authors = ["crowrojas"]
  spec.email = ["cristobal.rojasbrito@gmail.com"]

  spec.summary = "Command Deck is a tiny floating UI that allows you to run commands in your Rails app."
  spec.description = "Command Deck is a tiny floating UI that allows you to run commands in your Rails app."
  spec.homepage = "https://github.com/crow-rojas/command_deck"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/crow-rojas/command_deck"
  spec.metadata["changelog_uri"] = "https://github.com/crow-rojas/command_deck/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack", ">= 7.0"
  spec.add_dependency "railties", ">= 7.0"
end
