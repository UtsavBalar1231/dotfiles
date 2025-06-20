# Dotfiles Setup Scripts

This directory contains a set of robust setup scripts for configuring Linux environments. The scripts have been completely refactored to provide:

- Improved error handling and recovery
- Comprehensive logging and debugging
- Non-interactive installation options
- Modular design with specialized components
- Cross-distribution compatibility
- Intelligent fallback mechanisms

## Quick Start

To use the setup scripts:

```bash
# Show usage information
./setup.sh --help

# Setup on Arch Linux (auto-detected)
./setup.sh

# Setup on Ubuntu/Debian (auto-detected)
./setup.sh

# Setup specific component only
./setup.sh git      # Git configuration
./setup.sh shell    # ZSH shell setup
./setup.sh env      # Development environment
./setup.sh rust     # Rust environment
```

## Command Line Options

The setup scripts support various command line options:

```
Options:
  -v, --verbose         Enable verbose output
  -d, --debug           Enable debug mode
  -t, --trace           Enable trace mode (very verbose)
  --dry-run             Show actions without performing them
  --log-level=LEVEL     Set log level (ERROR|WARNING|INFO|DEBUG|TRACE)

Commands:
  arch                  Setup Arch Linux
  ubuntu                Setup Ubuntu/Debian
  git                   Setup Git configuration only
  shell                 Setup ZSH shell only
  env                   Setup development environment only
  rust                  Setup Rust environment only
  help                  Show this help message
```

## Script Architecture

The setup system follows a modular architecture:

1. **setup.sh**: Main entry point that coordinates the overall setup process
2. **setup-arch.sh**: Arch Linux-specific setup
3. **setup-linux.sh**: Ubuntu/Debian-specific setup
4. **scripts/utils.sh**: Core utility functions for logging, error handling, etc.
5. **scripts/package_manager.sh**: Package installation management
6. **scripts/setup_env.sh**: Development environment setup
7. **scripts/setup_shell.sh**: Shell configuration and setup
8. **scripts/setup_git.sh**: Git configuration
9. **scripts/setup_rust.sh**: Rust environment setup

## Key Features

### Robust Error Handling

All scripts include proper error detection and handling with:
- Exit code propagation
- Detailed error messages
- Recovery from non-critical failures
- Descriptive logging

### Debugging and Logging

The scripts provide multiple levels of logging:
- ERROR: Critical issues that prevent successful completion
- WARNING: Non-critical issues that may need attention
- INFO: General information about progress
- DEBUG: Detailed information for troubleshooting
- TRACE: Extremely detailed logging for development

### Zero Human Interaction

The scripts are designed to run without human interaction, making them suitable for:
- Automated deployments
- Scripted installations
- First-boot configurations

### Fallback Mechanisms

When a preferred installation method fails, the scripts attempt alternative approaches:
- Package installation via different methods
- Multiple download sources for tools
- Alternative configuration strategies

### Compatibility

The scripts are designed to work across different:
- Linux distributions (primarily Arch Linux and Ubuntu/Debian)
- System architectures (x86_64, ARM64)
- Shell environments (bash, zsh)

## Additional Documentation

For more information about specific components, refer to:

1. **Package Management**: [scripts/package_manager.sh](scripts/package_manager.sh)
2. **Environment Setup**: [scripts/setup_env.sh](scripts/setup_env.sh)
3. **Shell Configuration**: [scripts/setup_shell.sh](scripts/setup_shell.sh)
4. **Git Setup**: [scripts/setup_git.sh](scripts/setup_git.sh)
5. **Rust Environment**: [scripts/setup_rust.sh](scripts/setup_rust.sh)

## Troubleshooting

If you encounter issues:

1. Run with increased verbosity: `./setup.sh --verbose`
2. Check detailed logs: `./setup.sh --debug`
3. Examine the log file: `~/.dotfiles_install.log`
4. Run specific components to isolate issues: `./setup.sh env`

## License

MIT License - See LICENSE file for details. 