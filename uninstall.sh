#!/bin/sh

# Claude Code Mental Model Uninstaller
# Works with: curl -fsSL https://raw.githubusercontent.com/jasonjmcghee/claude-code-mental-model/main/uninstall.sh | sh

# Use POSIX shell for maximum compatibility
# Avoid bash-specific features when piped through curl

set -e

# Color codes for output (using printf for compatibility)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Helper functions
print_error() {
    printf "${RED}✗ Error: %s${NC}\n" "$1" >&2
}

print_success() {
    printf "${GREEN}✓ %s${NC}\n" "$1"
}

print_warning() {
    printf "${YELLOW}⚠ %s${NC}\n" "$1"
}

print_info() {
    printf "${BLUE}→ %s${NC}\n" "$1"
}

# Check if we're running through curl/wget pipe
is_piped() {
    [ ! -t 0 ] || [ ! -t 1 ]
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Check for required commands
check_requirements() {
    # Check for JSON processor (python3, python, or node)
    if ! command -v python3 >/dev/null 2>&1 && \
       ! command -v python >/dev/null 2>&1 && \
       ! command -v node >/dev/null 2>&1; then
        print_warning "No JSON processor found (python3/python/node)"
        print_info "Settings.json will need to be manually cleaned"
        return 1
    fi
    return 0
}

# Main uninstallation function
main() {
    printf "\n"
    print_info "Uninstalling Claude Code Mental Model Integration..."
    printf "\n"
    
    # Check OS
    OS="$(detect_os)"
    if [ "$OS" = "unknown" ]; then
        print_warning "Unknown operating system detected. Proceeding with generic Unix uninstallation..."
    else
        print_success "Detected OS: $OS"
    fi
    
    # Set up paths
    CLAUDE_DIR="$HOME/.claude"
    COMMANDS_DIR="$CLAUDE_DIR/commands"
    HOOKS_DIR="$CLAUDE_DIR/hooks"
    SETTINGS_FILE="$CLAUDE_DIR/settings.json"
    
    # Track if any files were found
    FOUND_FILES=0
    
    # Remove command file
    if [ -f "$COMMANDS_DIR/mental-model.md" ]; then
        rm -f "$COMMANDS_DIR/mental-model.md" || {
            print_warning "Could not remove mental-model.md"
        }
        print_success "Removed mental-model.md"
        FOUND_FILES=1
    else
        print_info "mental-model.md not found (already removed?)"
    fi
    
    # Remove hook scripts
    if [ -f "$HOOKS_DIR/mental-model-read.sh" ]; then
        rm -f "$HOOKS_DIR/mental-model-read.sh" || {
            print_warning "Could not remove mental-model-read.sh"
        }
        print_success "Removed mental-model-read.sh"
        FOUND_FILES=1
    else
        print_info "mental-model-read.sh not found (already removed?)"
    fi
    
    if [ -f "$HOOKS_DIR/mental-model-update.sh" ]; then
        rm -f "$HOOKS_DIR/mental-model-update.sh" || {
            print_warning "Could not remove mental-model-update.sh"
        }
        print_success "Removed mental-model-update.sh"
        FOUND_FILES=1
    else
        print_info "mental-model-update.sh not found (already removed?)"
    fi
    
    # Handle settings.json
    if [ -f "$SETTINGS_FILE" ]; then
        print_info "Updating settings.json..."
        
        # Check if we have JSON processing capabilities
        if check_requirements; then
            # Backup settings
            BACKUP_FILE="$SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S 2>/dev/null || date +%s)"
            cp "$SETTINGS_FILE" "$BACKUP_FILE" || {
                print_warning "Could not create backup of settings.json"
            }
            
            # Update settings using available JSON processor
            TEMP_FILE="$(mktemp 2>/dev/null || echo "/tmp/claude_settings_$$")"
            HOOK_READ_COMMAND="$HOOKS_DIR/mental-model-read.sh"
            HOOK_UPDATE_COMMAND="$HOOKS_DIR/mental-model-update.sh"
            
            # Try Python first (most reliable)
            if command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1; then
                PYTHON_CMD="python3"
                command -v python3 >/dev/null 2>&1 || PYTHON_CMD="python"
                
                $PYTHON_CMD - "$SETTINGS_FILE" "$TEMP_FILE" "$HOOK_READ_COMMAND" "$HOOK_UPDATE_COMMAND" << 'PYTHON_EOF'
import json
import sys
import os

settings_file = sys.argv[1]
temp_file = sys.argv[2]
hook_read_command = sys.argv[3]
hook_update_command = sys.argv[4]

try:
    with open(settings_file, 'r') as f:
        settings = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    print("Could not parse settings.json")
    sys.exit(1)

# Remove our hooks from SessionStart and PostToolUse
removed_count = 0

# Remove SessionStart hook
if 'hooks' in settings and 'SessionStart' in settings['hooks']:
    original_length = len(settings['hooks']['SessionStart'])
    settings['hooks']['SessionStart'] = [
        item for item in settings['hooks']['SessionStart']
        if not (isinstance(item, dict) and 'hooks' in item and 
                any(isinstance(h, dict) and h.get('command') == hook_read_command 
                    for h in item.get('hooks', [])))
    ]
    if len(settings['hooks']['SessionStart']) < original_length:
        removed_count += 1
    
    # Clean up empty SessionStart
    if not settings['hooks']['SessionStart']:
        del settings['hooks']['SessionStart']

# Remove PostToolUse hook
if 'hooks' in settings and 'PostToolUse' in settings['hooks']:
    original_length = len(settings['hooks']['PostToolUse'])
    settings['hooks']['PostToolUse'] = [
        item for item in settings['hooks']['PostToolUse']
        if not (isinstance(item, dict) and 'hooks' in item and 
                any(isinstance(h, dict) and h.get('command') == hook_update_command 
                    for h in item.get('hooks', [])))
    ]
    if len(settings['hooks']['PostToolUse']) < original_length:
        removed_count += 1
    
    # Clean up empty PostToolUse
    if not settings['hooks']['PostToolUse']:
        del settings['hooks']['PostToolUse']

# Clean up empty hooks
if 'hooks' in settings and not settings['hooks']:
    del settings['hooks']

if removed_count > 0:
    print(f"{removed_count} hook(s) removed from settings")
else:
    print("Hooks not found in settings")

with open(temp_file, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
PYTHON_EOF
                
                if [ $? -eq 0 ] && [ -f "$TEMP_FILE" ]; then
                    mv "$TEMP_FILE" "$SETTINGS_FILE"
                    print_success "Cleaned settings.json"
                    FOUND_FILES=1
                else
                    print_warning "Could not automatically clean settings.json"
                    rm -f "$TEMP_FILE"
                fi
                
            # Try Node.js as fallback
            elif command -v node >/dev/null 2>&1; then
                node - "$SETTINGS_FILE" "$TEMP_FILE" "$HOOK_READ_COMMAND" "$HOOK_UPDATE_COMMAND" << 'NODE_EOF'
const fs = require('fs');

const settingsFile = process.argv[2];
const tempFile = process.argv[3];
const hookReadCommand = process.argv[4];
const hookUpdateCommand = process.argv[5];

let settings;
try {
    settings = JSON.parse(fs.readFileSync(settingsFile, 'utf8'));
} catch (e) {
    console.error("Could not parse settings.json");
    process.exit(1);
}

let removedCount = 0;

// Remove SessionStart hook
if (settings.hooks && settings.hooks.SessionStart) {
    const originalLength = settings.hooks.SessionStart.length;
    settings.hooks.SessionStart = settings.hooks.SessionStart.filter(item =>
        !(item.hooks && item.hooks.some(h => h.command === hookReadCommand))
    );
    if (settings.hooks.SessionStart.length < originalLength) {
        removedCount++;
    }
    
    // Clean up empty SessionStart
    if (settings.hooks.SessionStart.length === 0) {
        delete settings.hooks.SessionStart;
    }
}

// Remove PostToolUse hook
if (settings.hooks && settings.hooks.PostToolUse) {
    const originalLength = settings.hooks.PostToolUse.length;
    settings.hooks.PostToolUse = settings.hooks.PostToolUse.filter(item =>
        !(item.hooks && item.hooks.some(h => h.command === hookUpdateCommand))
    );
    if (settings.hooks.PostToolUse.length < originalLength) {
        removedCount++;
    }
    
    // Clean up empty PostToolUse
    if (settings.hooks.PostToolUse.length === 0) {
        delete settings.hooks.PostToolUse;
    }
}

// Clean up empty hooks
if (settings.hooks && Object.keys(settings.hooks).length === 0) {
    delete settings.hooks;
}

if (removedCount > 0) {
    console.log(`${removedCount} hook(s) removed from settings`);
} else {
    console.log("Hooks not found in settings");
}

fs.writeFileSync(tempFile, JSON.stringify(settings, null, 2) + '\n');
NODE_EOF
                
                if [ $? -eq 0 ] && [ -f "$TEMP_FILE" ]; then
                    mv "$TEMP_FILE" "$SETTINGS_FILE"
                    print_success "Cleaned settings.json"
                    FOUND_FILES=1
                else
                    print_warning "Could not automatically clean settings.json"
                    rm -f "$TEMP_FILE"
                fi
            fi
            
            # Clean up
            rm -f "$TEMP_FILE" 2>/dev/null || true
        else
            print_warning "Cannot automatically clean settings.json (no JSON processor)"
            print_info "Please manually remove the mental-model-read.sh hook from:"
            printf "  ${BLUE}$SETTINGS_FILE${NC}\n"
            printf "\n"
            print_info "Look for and remove this entry:"
            cat << 'MANUAL_REMOVE'
    {
      "hooks": [{
        "type": "command",
        "command": "$HOME/.claude/hooks/mental-model-read.sh"
      }]
    }
MANUAL_REMOVE
        fi
    else
        print_info "settings.json not found (nothing to clean)"
    fi
    
    # Clean up empty directories (optional)
    if [ -d "$COMMANDS_DIR" ]; then
        # Check if directory is empty (POSIX compatible)
        if [ -z "$(ls -A "$COMMANDS_DIR" 2>/dev/null)" ]; then
            rmdir "$COMMANDS_DIR" 2>/dev/null && print_info "Removed empty commands directory"
        fi
    fi
    
    if [ -d "$HOOKS_DIR" ]; then
        # Check if directory is empty (POSIX compatible)
        if [ -z "$(ls -A "$HOOKS_DIR" 2>/dev/null)" ]; then
            rmdir "$HOOKS_DIR" 2>/dev/null && print_info "Removed empty hooks directory"
        fi
    fi
    
    # Final message
    printf "\n"
    if [ "$FOUND_FILES" -eq 1 ]; then
        print_success "Uninstallation complete!"
        print_info "MentalModel.toml integration has been removed."
    else
        print_warning "No Mental Model files were found to remove."
        print_info "The integration may have already been uninstalled."
    fi
    
    printf "\n"
    print_info "To reinstall, run:"
    printf "  ${BLUE}curl -fsSL https://raw.githubusercontent.com/jasonjmcghee/claude-code-mental-model/main/install.sh | sh${NC}\n"
    printf "\n"
}

# Run main function
main "$@"