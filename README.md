# MentalModel.toml for Claude Code

A structured file that helps Claude understand your codebase architecture using a single TOML file that gets read on startup.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/jasonjmcghee/claude-code-mental-model/main/install.sh | sh
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/jasonjmcghee/claude-code-mental-model/main/uninstall.sh | sh
```

## Usage

Generate a MentalModel.toml:
```
> /mental-model generate
```

(Optional) Manually request an update when things change (e.g. when Claude did not make the changes):
```
> /mental-model update
```

Claude reads it on startup and knows your codebase structure.

## What's in `MentalModel.toml`?

- Components and their relationships
- File structure and entry points
- Performance constraints and hot paths
- Test coverage
- Tech debt and evolution history

See `examples/` for real examples or `mental-model-spec.md` for the full spec.

## License

MIT
