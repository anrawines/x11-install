# Contributing to bspwm Installer

Thank you for your interest in improving this installer!

## How to Contribute

### Adding New Packages

Edit the package list files:

- **base.txt** - Essential packages everyone needs
- **additional.txt** - Optional packages users might want
- **aur.txt** - AUR-only packages

Format: One package per line, with optional comments starting with `#`

Example:
```
# My favorite package
my-package-name
```

### Creating New Modules

1. Create a new file in `modules/` with a descriptive name
2. Follow the existing module pattern:
   ```bash
   #!/usr/bin/env bash

   ##############################################################################
   # Module Name - Brief Description
   ##############################################################################

   main_function() {
       log_info "Starting..."
       # Your code here
       log_success "Done!"
   }
   ```

3. Source the module in `install.sh`
4. Call the appropriate function in the main workflow

### Adding Configuration Examples

1. Create new example files in `config/` directory
2. Use `.example` extension
3. Add comprehensive comments
4. Reference them in the README

### Improving Existing Modules

- Ensure backward compatibility
- Add comments for complex logic
- Test on clean Arch installations
- Update README if behavior changes

## Code Style

- Use `set -euo pipefail` for error handling
- Use the provided log functions: `log_info`, `log_success`, `log_warn`, `log_error`
- Keep functions focused and modular
- Add descriptive comments
- Use meaningful variable names

## Testing

Before submitting changes:

1. Test on a fresh Arch Linux installation (VM recommended)
2. Test with different inputs (skip steps, use alternatives)
3. Verify all configuration files are created
4. Check that backups are created correctly
5. Test with different login managers (if modified)

## Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/description`
3. Make your changes
4. Test thoroughly
5. Commit with clear messages: `git commit -m "Add/Fix: Clear description"`
6. Push to your fork
7. Create a Pull Request with description of changes

## Documentation

- Update README.md if adding features
- Add inline comments for complex logic
- Document any new configuration options
- Include usage examples

## Issues and Suggestions

- Check existing issues first
- Describe the problem clearly
- Include steps to reproduce (for bugs)
- Suggest solutions if you have them
- Mention your Arch Linux version and environment

## Code Review Standards

Code will be reviewed for:
- Correctness and reliability
- Security implications
- Code style and clarity
- Documentation quality
- Backward compatibility

## Questions?

Feel free to open an issue with the `question` label or discussion thread.

---

Thank you for helping make this installer better! 🚀
