# Contributing to PasteMine

Thank you for your interest in contributing to PasteMine! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and constructive
- Welcome newcomers and encourage diverse perspectives
- Focus on what is best for the community
- Show empathy towards other community members

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:

- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- macOS version and PasteMine version
- Screenshots or logs if applicable

### Suggesting Enhancements

Enhancement suggestions are welcome! Please:

- Use a clear, descriptive title
- Provide a detailed description of the proposed feature
- Explain why this enhancement would be useful
- Include mockups or examples if applicable

### Pull Requests

1. **Fork the repository** and create your branch from `main`

2. **Set up your development environment**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/PasteMine_App_Store.git
   cd PasteMine_Compliance
   open PasteMine/PasteMine.xcodeproj
   ```

3. **Configure signing**:
   - Set your Development Team ID in Xcode
   - Update the Bundle Identifier

4. **Make your changes**:
   - Write clear, commented code
   - Follow the existing code style
   - Add tests if applicable
   - Update documentation if needed

5. **Test your changes**:
   - Build and run the app (⌘R)
   - Test all affected features
   - Verify no regressions

6. **Commit your changes**:
   ```bash
   git add .
   git commit -m "Brief description of changes"
   ```

7. **Push to your fork**:
   ```bash
   git push origin your-branch-name
   ```

8. **Create a Pull Request**:
   - Provide a clear title and description
   - Reference any related issues
   - Include screenshots for UI changes

## Development Guidelines

### Code Style

- Use Swift naming conventions
- Write self-documenting code with clear variable names
- Add comments for complex logic
- Keep functions small and focused
- Use SwiftUI best practices

### Project Structure

- `App/` - Application lifecycle and delegates
- `Managers/` - Feature coordinators and managers
- `Models/` - Data models and structures
- `Services/` - Business logic and services
- `Views/` - SwiftUI views and components
- `Utilities/` - Helper functions and extensions
- `Resources/` - Assets, sounds, and localization

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Start with a capital letter
- Keep the first line under 50 characters
- Reference issues and pull requests when relevant

Examples:
- `Add support for RTF clipboard format`
- `Fix crash when clearing empty history`
- `Update README with new installation instructions`

### Testing

Before submitting a PR:

- ✅ App builds without errors or warnings
- ✅ All existing features work correctly
- ✅ New features work as intended
- ✅ No memory leaks or performance issues
- ✅ UI is responsive and follows macOS design guidelines

### Privacy & Security

- Never collect or transmit user data
- Keep all data local
- Follow Apple's privacy guidelines
- Respect user permissions
- Handle sensitive data securely

## Questions?

If you have questions, feel free to:

- Open an issue with the "question" label
- Check existing issues and discussions
- Review the README and documentation

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to PasteMine! 🎉
