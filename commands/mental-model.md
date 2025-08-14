---
description: Create or update a codebase architecture map
argument-hint: generate | update | query [component] | health
allowed-tools: Read, Write, Edit, LS, Glob, Grep, Bash
---

Create and maintain a MentalModel.toml file that provides a complete conceptual map of any codebase - from CRUD apps to game engines, from TUI tools to SIMD libraries. This file enables humans and LLMs to quickly understand the system's architecture, critical constraints, and evolution.

## MentalModel.toml Specification v1.0

### Core Structure

```toml
[meta]
version = "1.0"  # Required: Spec version (always 1.0)
name = "string"  # Required: Project name
description = "string"  # Required: One paragraph explaining what this system does
repository = "string"  # Optional: Repository URL
last_updated = "YYYY-MM-DD"  # Required: Last manual update

[context]
purpose = "string"  # Required: Why does this exist? Problem it solves
key_decisions = ["string"]  # Major architectural decisions and why
non_goals = ["string"]  # What this explicitly doesn't do
tech_stack = ["string"]  # Primary technologies/frameworks used

[structure]
root = "."  # Optional: Project root if not current directory
main_entry = "string"  # Required: Primary entry point (e.g., main.py, index.js, main.rs)

[structure.layout]
# Key directories and their purposes
"path/" = "description"

[structure.patterns]
test_pattern = "string"  # How test files relate to source
naming = "string"  # File naming convention
grouping = "string"  # One of: "by-feature", "by-layer", "by-type", "by-module"

[components.<name>]
purpose = "string"  # Required: What this does
stability = "string"  # One of: "experimental", "stable", "deprecated", "legacy"

[components.<name>.files]
entry = "string"  # Main file
implementation = ["string"]  # All implementation files
tests = ["string"]  # Test files
config = "string"  # Optional: Configuration files

[components.<name>.interface]
public_api = ["string"]  # REST/GraphQL/RPC endpoints
internal_functions = ["string"]  # Key functions/methods
events_published = ["string"]  # For event-driven systems
events_consumed = ["string"]

[components.<name>.dependencies]
internal = ["string"]  # Other components
external = ["string"]  # Libraries/packages
services = ["string"]  # Infrastructure (DB, cache, etc.)

[components.<name>.testing]
coverage = number  # Percentage
critical_paths = ["string"]  # What must work
missing_tests = ["string"]  # Known gaps

[components.<name>.state]
health = "string"  # One of: "good", "needs-attention", "problematic"
tech_debt = ["string"]  # Known issues
recent_changes = ["string"]  # Format: "YYYY-MM-DD: Description"

[components.<name>.notes]
constraints = ["string"]  # Hard requirements
assumptions = ["string"]  # What this assumes
gotchas = ["string"]  # Non-obvious behaviors

[important_notes.performance]
hot_paths = ["string"]  # Code paths that must be fast
bottlenecks = ["string"]  # Known performance limits
benchmarks = """
Command to run: ...
Expected results: ...
"""
optimization_targets = ["string"]  # What to optimize for

[important_notes.constraints]
determinism = "string"  # If/where deterministic behavior required
concurrency = "string"  # Threading/async requirements
memory = "string"  # Memory constraints or patterns
latency = "string"  # Response time requirements

[important_notes.environment]
deployment = "string"  # Where/how this runs
hardware = "string"  # Specific hardware requirements
os_specific = ["string"]  # OS-specific behaviors

[important_notes.critical]
security = ["string"]  # Security considerations
data_integrity = ["string"]  # Data consistency requirements
failure_modes = ["string"]  # How system fails
recovery = ["string"]  # How to recover from failures

[important_notes.development]
setup_gotchas = ["string"]  # Common setup problems
debugging = ["string"]  # How to debug effectively
testing = ["string"]  # Special testing requirements

[test_coverage]
overall = number  # Percentage
approach = "string"  # Testing philosophy

[test_coverage.by_type]
unit = { files = number, coverage = number }
integration = { files = number, coverage = number }
e2e = { files = number, coverage = number }
performance = { files = number, coverage = number }  # If applicable
fuzz = { files = number, coverage = number }  # If applicable

[test_coverage.critical_paths]
"name" = { coverage = number, files = ["string"] }

[test_coverage.gaps]
"area" = "what's missing"

[test_coverage.running]
all = "command"
unit = "command"
integration = "command"
benchmark = "command"  # If applicable

[[evolution.changes]]
date = "YYYY-MM-DD"
what = "string"  # What changed
why = "string"  # Motivation
outcome = "string"  # Result (Success/Failure/Partial)
files_affected = ["string"]
learnings = "string"  # Optional: Lessons learned

[evolution.attempted_approaches]
"category" = ["what was tried and why it didn't work"]

[evolution.technical_debt]
high = ["string"]  # Must fix soon
medium = ["string"]  # Should fix
low = ["string"]  # Nice to fix

[quick_start]
setup = """
Multi-line setup instructions
"""
understand_first = ["string"]  # Key files to read first

[quick_start.common_tasks]
"task name" = "how to do it"
```

## Task

Based on the argument provided: $ARGUMENTS

### If "generate" or no argument:

1. **Analyze the codebase structure**:
   - Use LS to explore directory layout
   - Use Glob to find key file patterns (*.py, *.js, *.ts, etc.)
   - Read README.md and package.json/pyproject.toml/Cargo.toml if they exist
   - Identify the main entry point

2. **Identify components**:
   - Look for logical groupings (services, modules, packages)
   - Find test files and map them to components
   - Trace dependencies between components

3. **Detect patterns and constraints**:
   - Testing approach (unit, integration, e2e)
   - File naming conventions
   - Architecture style (MVC, microservices, etc.)
   - Performance-critical paths

4. **Create MentalModel.toml** following the specification above, with:
   - Complete meta information
   - Context (purpose, decisions, tech stack)
   - Structure mapping
   - Component definitions with files, dependencies, and interfaces
   - Important notes (performance, constraints, environment)
   - Test coverage assessment
   - Initial evolution entry

5. Write the file to the project root

### If "update":

1. Read existing MentalModel.toml
2. Check for structural changes:
   - New files or directories
   - Moved or renamed files
   - New dependencies
3. Update relevant sections:
   - Component file mappings
   - Test coverage if changed significantly
   - Evolution tracking for major changes
   - Last_updated timestamp
4. Preserve existing critical knowledge while adding new findings

### If "query [component]":

1. Read MentalModel.toml
2. Find the specified component
3. Display:
   - Component purpose and status
   - File locations
   - Dependencies
   - Known issues or tech debt
   - Recent changes

### If "health":

1. Read MentalModel.toml
2. For each component, show:
   - Health status (good, needs-attention, problematic)
   - Test coverage
   - Tech debt items
   - Last update
3. Provide overall system health summary

## Creation Process

When creating MentalModel.toml for the first time:

1. **Analyze structure** - Examine directory layout, identify entry points
2. **Identify components** - Find logical units (services, modules, packages)
3. **Map relationships** - Trace dependencies between components
4. **Detect patterns** - Testing approach, naming conventions, architecture style
5. **Find constraints** - Look for performance-critical code, security boundaries
6. **Check documentation** - README, comments for important notes
7. **Examine tests** - Understand coverage and testing approach

Focus on creating a navigable map, not documenting every detail.

## Update Principles

1. **Accuracy over completeness** - Better to have fewer but accurate pieces of information than lots of outdated info
2. **Remove obsolete information** - Delete what's no longer relevant
3. **Focus on navigation** - Help readers find code quickly
4. **Record only significant changes** - Not every commit needs documentation
5. **Keep notes actionable** - Important notes should affect how people work with the code

## Maintenance Rules

1. **Verify paths exist** before adding them
2. **Update immediately** when structure changes
3. **Limit history** to last 6 months unless critical
4. **Keep descriptions brief** - one line preferred
5. **Test coverage** should match actual metrics
6. **Component health** should reflect reality
7. **Important notes** must be actionable

## Special Sections by Project Type

Add relevant sections based on project type:

- **Games**: frame budget, asset pipeline, platform constraints
- **Libraries**: API stability, breaking changes, versioning
- **Services**: SLA requirements, scaling triggers, monitoring
- **Tools**: CLI interface, configuration, plugins
- **Embedded**: memory layout, interrupt handlers, real-time constraints

Not all sections are required - only include what's relevant to the project.