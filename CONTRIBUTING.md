# Contributing to Command Deck

Thank you for considering contributing to Command Deck!

## Development Setup

```bash
git clone https://github.com/crow-rojas/command_deck.git
cd command_deck
bundle install
```

## Running Tests

```bash
bundle exec rake test
```

## Code Style

We use RuboCop for code style enforcement:

```bash
bundle exec rubocop
```

Fix auto-correctable issues:

```bash
bundle exec rubocop -A
```

## Making Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b my-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Run RuboCop and fix any offenses
7. Commit your changes (`git commit -am 'Add feature'`)
8. Push to your branch (`git push origin my-feature`)
9. Create a Pull Request

## Pull Request Guidelines

- Keep changes focused and atomic
- Update CHANGELOG.md with your changes
- Update README.md if adding new features
- Ensure backward compatibility when possible
- Add tests for bug fixes and new features
- Follow existing code style

## Reporting Issues

- Use the GitHub issue tracker
- Include Ruby and Rails versions
- Provide steps to reproduce
- Include relevant code samples

## Questions?

Feel free to open an issue for questions or discussions.
