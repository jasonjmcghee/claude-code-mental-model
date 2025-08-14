#!/bin/sh

# Claude Code Mental Model Installer
# Works with: curl -fsSL https://raw.githubusercontent.com/jasonjmcghee/claude-code-mental-model/main/install.sh | sh

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
    local missing=""
    
    # Check for curl or wget (needed if we're piped)
    if is_piped; then
        if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
            missing="${missing}curl or wget, "
        fi
    fi
    
    # Check for JSON processor (python3, python, or node)
    if ! command -v python3 >/dev/null 2>&1 && \
       ! command -v python >/dev/null 2>&1 && \
       ! command -v node >/dev/null 2>&1; then
        missing="${missing}python3/python/node (for JSON processing), "
    fi
    
    if [ -n "$missing" ]; then
        print_error "Missing required tools: ${missing%??}"
        print_info "Please install the missing tools and try again"
        exit 1
    fi
}

# Download file from GitHub
download_file() {
    local url="$1"
    local dest="$2"
    local dest_dir
    
    dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"
    
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$dest" || {
            print_error "Failed to download: $url"
            return 1
        }
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$dest" "$url" || {
            print_error "Failed to download: $url"
            return 1
        }
    else
        print_error "Neither curl nor wget found. Cannot download files."
        return 1
    fi
}

# Main installation function
main() {
    printf "\n"
    print_info "Installing Claude Code Mental Model Integration..."
    printf "\n"
    
    # Check OS
    OS="$(detect_os)"
    if [ "$OS" = "unknown" ]; then
        print_warning "Unknown operating system detected. Proceeding with generic Unix installation..."
    else
        print_success "Detected OS: $OS"
    fi
    
    # Check requirements
    check_requirements
    
    # Set up paths
    CLAUDE_DIR="$HOME/.claude"
    COMMANDS_DIR="$CLAUDE_DIR/commands"
    HOOKS_DIR="$CLAUDE_DIR/hooks"
    SETTINGS_FILE="$CLAUDE_DIR/settings.json"
    
    # GitHub raw content base URL
    GITHUB_RAW="https://raw.githubusercontent.com/jasonjmcghee/claude-code-mental-model/main"
    
    # Create directories
    print_info "Creating directories..."
    mkdir -p "$COMMANDS_DIR" || {
        print_error "Failed to create commands directory"
        exit 1
    }
    mkdir -p "$HOOKS_DIR" || {
        print_error "Failed to create hooks directory"
        exit 1
    }
    
    # Download files
    print_info "Downloading files..."
    
    # Download command file
    download_file "$GITHUB_RAW/commands/mental-model.md" "$COMMANDS_DIR/mental-model.md" || exit 1
    print_success "Downloaded mental-model.md"
    
    # Download hook scripts
    download_file "$GITHUB_RAW/hooks/mental-model-read.sh" "$HOOKS_DIR/mental-model-read.sh" || exit 1
    chmod +x "$HOOKS_DIR/mental-model-read.sh" 2>/dev/null || true
    print_success "Downloaded and made executable mental-model-read.sh"
    
    download_file "$GITHUB_RAW/hooks/mental-model-update.sh" "$HOOKS_DIR/mental-model-update.sh" || exit 1
    chmod +x "$HOOKS_DIR/mental-model-update.sh" 2>/dev/null || true
    print_success "Downloaded and made executable mental-model-update.sh"
    
    # Handle settings.json
    print_info "Updating settings.json..."
    
    # Create settings file if it doesn't exist
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo '{}' > "$SETTINGS_FILE"
        print_info "Created new settings.json"
    fi
    
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
    settings = {}

# Ensure hooks structure exists
if 'hooks' not in settings:
    settings['hooks'] = {}
if 'SessionStart' not in settings['hooks']:
    settings['hooks']['SessionStart'] = []
if 'PostToolUse' not in settings['hooks']:
    settings['hooks']['PostToolUse'] = []

# Check and add SessionStart hook
hook_exists = False
for item in settings['hooks']['SessionStart']:
    if isinstance(item, dict) and 'hooks' in item:
        for hook in item['hooks']:
            if isinstance(hook, dict) and hook.get('command') == hook_read_command:
                hook_exists = True
                break
        if hook_exists:
            break

if not hook_exists:
    settings['hooks']['SessionStart'].append({
        "hooks": [{
            "type": "command",
            "command": hook_read_command
        }]
    })
    print("SessionStart hook added")
else:
    print("SessionStart hook already exists")

# Check and add PostToolUse hook
hook_exists = False
for item in settings['hooks']['PostToolUse']:
    if isinstance(item, dict) and 'hooks' in item:
        for hook in item['hooks']:
            if isinstance(hook, dict) and hook.get('command') == hook_update_command:
                hook_exists = True
                break
        if hook_exists:
            break

if not hook_exists:
    settings['hooks']['PostToolUse'].append({
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [{
            "type": "command",
            "command": hook_update_command
        }]
    })
    print("PostToolUse hook added")
else:
    print("PostToolUse hook already exists")

with open(temp_file, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
PYTHON_EOF
        
        if [ $? -eq 0 ] && [ -f "$TEMP_FILE" ]; then
            mv "$TEMP_FILE" "$SETTINGS_FILE"
            print_success "Updated settings.json with hook"
        else
            print_error "Failed to update settings.json with Python"
            rm -f "$TEMP_FILE"
            exit 1
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
    settings = {};
}

// Ensure hooks structure exists
if (!settings.hooks) settings.hooks = {};
if (!settings.hooks.SessionStart) settings.hooks.SessionStart = [];
if (!settings.hooks.PostToolUse) settings.hooks.PostToolUse = [];

// Check and add SessionStart hook
let hookExists = settings.hooks.SessionStart.some(item => 
    item.hooks && item.hooks.some(hook => hook.command === hookReadCommand)
);

if (!hookExists) {
    settings.hooks.SessionStart.push({
        hooks: [{
            type: "command",
            command: hookReadCommand
        }]
    });
    console.log("SessionStart hook added");
} else {
    console.log("SessionStart hook already exists");
}

// Check and add PostToolUse hook
hookExists = settings.hooks.PostToolUse.some(item => 
    item.hooks && item.hooks.some(hook => hook.command === hookUpdateCommand)
);

if (!hookExists) {
    settings.hooks.PostToolUse.push({
        matcher: "Write|Edit|MultiEdit",
        hooks: [{
            type: "command",
            command: hookUpdateCommand
        }]
    });
    console.log("PostToolUse hook added");
} else {
    console.log("PostToolUse hook already exists");
}

fs.writeFileSync(tempFile, JSON.stringify(settings, null, 2) + '\n');
NODE_EOF
        
        if [ $? -eq 0 ] && [ -f "$TEMP_FILE" ]; then
            mv "$TEMP_FILE" "$SETTINGS_FILE"
            print_success "Updated settings.json with hook"
        else
            print_error "Failed to update settings.json with Node.js"
            rm -f "$TEMP_FILE"
            exit 1
        fi
        
    else
        print_error "No JSON processor found (python3, python, or node required)"
        print_warning "Please manually add the following to your settings.json:"
        printf "\n"
        cat << 'MANUAL_JSON'
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [{
          "type": "command",
          "command": "$HOME/.claude/hooks/mental-model-read.sh"
        }]
      }
    ]
  }
}
MANUAL_JSON
        printf "\n"
        exit 1
    fi
    
    # Clean up
    rm -f "$TEMP_FILE" 2>/dev/null || true
    
    # Final success message
    printf "\n"
    print_success "Installation complete!"
    printf "\n"
    print_info "MentalModel.toml integration is now active."
    print_info "Use the following command in Claude Code:"
    printf "  ${GREEN}/mental-model generate${NC}\n"
    printf "\n"
    print_info "To uninstall, run:"
    printf "  ${BLUE}curl -fsSL https://raw.githubusercontent.com/jasonjmcghee/claude-code-mental-model/main/uninstall.sh | sh${NC}\n"
    printf "\n"
}

# Run main function
main "$@"