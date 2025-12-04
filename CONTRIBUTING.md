# Contributing to TinniCap

Thank you for your interest in contributing to TinniCap!

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- A clear description of the problem
- Steps to reproduce the issue
- Your macOS version and hardware setup
- Screenshots if applicable

### Suggesting Features

Aweome! Please open an issue with:
- A clear description of the feature
- The use case and why it would be helpful
- Any implementation ideas you might have

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following our coding guidelines
3. **Test your changes** thoroughly on your Mac
4. **Update documentation** if you're changing functionality
5. **Submit a pull request** with a clear description of your changes

### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/macos-vol-limiter.git
cd macos-vol-limiter

# Open in Xcode
open TinniCap.xcodeproj

# Build and run
# Press Cmd+R in Xcode
```

### Coding Guidelines

- Follow Swift naming conventions
- Use clear, descriptive variable and function names
- Add comments for complex logic
- Keep functions focused and single-purpose
- Test with multiple audio devices when possible

### Code Style

- Use 4 spaces for indentation (not tabs)
- Keep lines under 120 characters when practical
- Use `// MARK:` to organize code sections
- Follow Apple's Swift API Design Guidelines

### Testing Audio Devices

When testing, please verify with:
- Built-in speakers
- Bluetooth headphones/speakers
- USB audio devices
- HDMI/DisplayPort audio (if available)

### Commit Messages

Write clear commit messages:
- Use present tense ("Add feature" not "Added feature")
- Keep the first line under 50 characters
- Add detailed description if needed

Example:
```
Add support for per-app volume limiting

- Implement app detection service
- Add UI for selecting target apps
- Update settings persistence
```

### Questions?

Feel free to open an issue with the `question` label if you need help or clarification.

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Accept constructive criticism gracefully
- Focus on what's best for the community

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or insulting comments
- Publishing others' private information
- Other unprofessional conduct

Project maintainers have the right to remove, edit, or reject comments, commits, code, issues, and other contributions that don't align with these standards.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
