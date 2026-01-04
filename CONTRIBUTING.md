# Contributing to Hyprland Show Desktop

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue with:
- A clear description of the bug
- Steps to reproduce
- Expected behavior vs actual behavior
- Your Hyprland version (`hyprctl version`)
- Relevant configuration snippets

### Suggesting Features

Feature suggestions are welcome! Please open an issue describing:
- The feature you'd like to see
- Why it would be useful
- How it might work

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style

- Use shellcheck to check your shell scripts
- Follow existing code style
- Add comments for complex logic
- Keep functions small and focused

### Testing

Before submitting:
- Test on different workspaces
- Test with different numbers of windows
- Test edge cases (no windows, single window, etc.)
- Verify it works after config reload

## Development Setup

1. Clone the repository
2. Make your changes
3. Test locally:
   ```bash
   ./show-desktop.sh
   ```
4. Test the installation script:
   ```bash
   ./install.sh
   ```

## Questions?

Feel free to open an issue for any questions or discussions!
