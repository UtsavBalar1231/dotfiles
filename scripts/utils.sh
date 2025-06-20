#!/usr/bin/env bash
# ====================================================================
# utils.sh - Core utility functions for dotfiles setup scripts
# ====================================================================

# Global constants
readonly LOG_FILE="${HOME}/.dotfiles_install.log"
readonly COLORS=("" "31" "32" "33" "34" "35" "36" "37")
readonly LOG_LEVELS=("NONE" "ERROR" "WARNING" "INFO" "DEBUG" "TRACE")
readonly LOG_LEVEL_DEFAULT=3  # INFO level

# Global variables
VERBOSE=false
DRY_RUN=false
LOG_LEVEL=${LOG_LEVEL_DEFAULT}
SCRIPT_NAME=$(basename "${0}")

# ---------------------------------------------------------------------
# Logging Functions
# ---------------------------------------------------------------------

# Initialize logging
init_logging() {
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    # Clear log file if it's too large (>10MB)
    if [[ -f "${LOG_FILE}" ]] && [[ $(stat -c%s "${LOG_FILE}") -gt 10485760 ]]; then
        mv "${LOG_FILE}" "${LOG_FILE}.old"
    fi
    
    # Create/append to log file with header
    {
        echo "======================================================================"
        echo "Log started at $(date '+%Y-%m-%d %H:%M:%S')"
        echo "System: $(uname -a)"
        echo "User: $(whoami)"
        echo "======================================================================"
    } >> "${LOG_FILE}"
}

# Log a message with a specific level
log() {
    local level=$1
    local message="${2:-No message provided}"
    local level_index=0
    
    # Convert level name to index if string is provided
    if [[ "${level}" =~ ^[A-Z]+$ ]]; then
        for i in "${!LOG_LEVELS[@]}"; do
            if [[ "${LOG_LEVELS[$i]}" == "${level}" ]]; then
                level_index=$i
                break
            fi
        done
    else
        level_index=$level
        level="${LOG_LEVELS[$level_index]}"
    fi
    
    # Skip if current log level is lower than message level
    [[ $level_index -gt $LOG_LEVEL ]] && return 0
    
    local color="${COLORS[$level_index]:-37}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to file
    echo -e "${timestamp} [${level}] ${SCRIPT_NAME}: ${message}" >> "${LOG_FILE}"
    
    # Log to console if needed
    if [[ $VERBOSE == true || $level_index -le 2 ]]; then
        # shellcheck disable=SC2059
        printf "\033[${color}m[${level}]\033[0m ${message}\n" >&2
    fi
}

# Helper functions for each log level
error() { log "ERROR" "$1"; }
warning() { log "WARNING" "$1"; }
info() { log "INFO" "$1"; }
debug() { log "DEBUG" "$1"; }
trace() { log "TRACE" "$1"; }

# Set log level from environment or argument
set_log_level() {
    local level_name="${1:-INFO}"
    
    for i in "${!LOG_LEVELS[@]}"; do
        if [[ "${LOG_LEVELS[$i]}" == "${level_name}" ]]; then
            LOG_LEVEL=$i
            return 0
        fi
    done
    
    warning "Unknown log level: ${level_name}, using INFO"
    LOG_LEVEL=${LOG_LEVEL_DEFAULT}
}

# ---------------------------------------------------------------------
# System Detection Functions
# ---------------------------------------------------------------------

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "${ID}"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]]; then
        echo "redhat"
    else
        echo "unknown"
    fi
}

# Get distribution version
get_distro_version() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "${VERSION_ID}"
    elif command -v lsb_release >/dev/null 2>&1; then
        lsb_release -rs
    else
        echo "unknown"
    fi
}

# Get Ubuntu/Debian version
get_ubuntu_version() {
    if command -v lsb_release >/dev/null 2>&1; then
        lsb_release -rs | cut -d. -f1
    else
        warning "lsb_release not found, guessing distribution version"
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release
            echo "${VERSION_ID}" | cut -d. -f1
        else
            echo "unknown"
        fi
    fi
}

# Check if running as root
is_root() {
    [[ "$(id -u)" -eq 0 ]]
}

# Check if system is using systemd
has_systemd() {
    [[ -d /run/systemd/system ]]
}

# ---------------------------------------------------------------------
# Command and Dependency Functions
# ---------------------------------------------------------------------

# Check if a command exists
has_command() {
    command -v "$1" >/dev/null 2>&1
}

# Get latest version from GitHub release
get_github_release() {
    local repo="${1}"
    local latest
    
    if has_command curl; then
        latest=$(curl --silent --connect-timeout 10 "https://api.github.com/repos/${repo}/releases/latest" | 
            grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    elif has_command wget; then
        latest=$(wget -qO- --timeout=10 "https://api.github.com/repos/${repo}/releases/latest" | 
            grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        error "Neither curl nor wget is available"
        return 1
    fi
    
    if [[ -z "${latest}" ]]; then
        error "Failed to get latest release for ${repo}"
        return 1
    fi
    
    echo "${latest}"
}

# Execute command with proper output and error handling
run_cmd() {
    local cmd=("$@")
    local cmd_str="${*}"
    local exit_code=0
    
    debug "Running command: ${cmd_str}"
    
    if [[ ${DRY_RUN} == true ]]; then
        info "[DRY RUN] Would execute: ${cmd_str}"
        return 0
    fi
    
    # Create a temporary file for stderr
    local stderr_file
    stderr_file=$(mktemp)
    
    # Run the command
    if ! "${cmd[@]}" 2>"${stderr_file}"; then
        exit_code=$?
        error "Command failed (${exit_code}): ${cmd_str}"
        error "Error output: $(cat "${stderr_file}")"
        rm -f "${stderr_file}"
        return ${exit_code}
    fi
    
    rm -f "${stderr_file}"
    return 0
}

# Run command with sudo if needed
run_with_sudo() {
    if is_root; then
        run_cmd "$@"
    else
        run_cmd sudo "$@"
    fi
}

# Install a package based on the detected distribution
install_package() {
    local package="$1"
    local distro
    distro=$(detect_distro)
    
    info "Installing package: ${package}"
    
    case "${distro}" in
        arch)
            run_with_sudo pacman -S --noconfirm "${package}"
            ;;
        debian|ubuntu)
            run_with_sudo apt-get install -y "${package}"
            ;;
        fedora)
            run_with_sudo dnf install -y "${package}"
            ;;
        *)
            error "Unsupported distribution for package installation: ${distro}"
            return 1
            ;;
    esac
}

# Check if package is installed
is_package_installed() {
    local package="$1"
    local distro
    distro=$(detect_distro)
    
    case "${distro}" in
        arch)
            pacman -Qi "${package}" >/dev/null 2>&1
            ;;
        debian|ubuntu)
            dpkg -s "${package}" >/dev/null 2>&1
            ;;
        fedora)
            rpm -q "${package}" >/dev/null 2>&1
            ;;
        *)
            error "Unsupported distribution for package check: ${distro}"
            return 2
            ;;
    esac
}

# ---------------------------------------------------------------------
# File and Directory Functions
# ---------------------------------------------------------------------

# Create directory with proper permissions
make_dir() {
    local dir="$1"
    
    if [[ ! -d "${dir}" ]]; then
        debug "Creating directory: ${dir}"
        if [[ ${DRY_RUN} == true ]]; then
            info "[DRY RUN] Would create directory: ${dir}"
            return 0
        fi
        
        mkdir -p "${dir}" || {
            error "Failed to create directory: ${dir}"
            return 1
        }
    else
        debug "Directory already exists: ${dir}"
    fi
}

# Create a symbolic link with backup of existing file
create_symlink() {
    local source="$1"
    local target="$2"
    
    if [[ ! -e "${source}" ]]; then
        error "Source file/directory does not exist: ${source}"
        return 1
    fi
    
    if [[ -L "${target}" ]]; then
        local current_link
        current_link=$(readlink -f "${target}")
        
        if [[ "${current_link}" == "${source}" ]]; then
            debug "Symlink already exists and points to the correct location: ${target} -> ${source}"
            return 0
        else
            debug "Updating existing symlink: ${target} -> ${source} (was -> ${current_link})"
        fi
    elif [[ -e "${target}" ]]; then
        local backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        debug "Backing up existing file/directory: ${target} -> ${backup}"
        
        if [[ ${DRY_RUN} == true ]]; then
            info "[DRY RUN] Would backup: ${target} -> ${backup}"
        else
            mv "${target}" "${backup}" || {
                error "Failed to backup file/directory: ${target}"
                return 1
            }
        fi
    fi
    
    debug "Creating symlink: ${target} -> ${source}"
    if [[ ${DRY_RUN} == true ]]; then
        info "[DRY RUN] Would create symlink: ${target} -> ${source}"
        return 0
    fi
    
    ln -sf "${source}" "${target}" || {
        error "Failed to create symlink: ${target} -> ${source}"
        return 1
    }
}

# ---------------------------------------------------------------------
# Miscellaneous Functions
# ---------------------------------------------------------------------

# Parse command line arguments
parse_args() {
    local args=("$@")
    local i=0
    
    while [[ $i -lt ${#args[@]} ]]; do
        case "${args[$i]}" in
            -v|--verbose)
                VERBOSE=true
                ;;
            -d|--debug)
                set_log_level "DEBUG"
                VERBOSE=true
                ;;
            -t|--trace)
                set_log_level "TRACE"
                VERBOSE=true
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --log-level=*)
                set_log_level "${args[$i]#*=}"
                ;;
            --log-level)
                if [[ $((i+1)) -lt ${#args[@]} ]]; then
                    set_log_level "${args[$((i+1))]}"
                    ((i++))
                else
                    warning "Missing value for --log-level"
                fi
                ;;
            *)
                # Return the current index to calling script
                return $i
                ;;
        esac
        ((i++))
    done
    
    # If we processed all arguments, return -1
    return -1
}

# Function to display progress
show_progress() {
    local current="$1"
    local total="$2"
    local prefix="${3:-Progress}"
    local width=50
    
    # Calculate percentage and bar length
    local percent=$((current * 100 / total))
    local bar_length=$((width * current / total))
    
    # Create the progress bar
    local bar=""
    for ((i=0; i<bar_length; i++)); do
        bar+="="
    done
    for ((i=bar_length; i<width; i++)); do
        bar+=" "
    done
    
    # Print the progress bar
    printf "\r%s: [%s] %d%%" "${prefix}" "${bar}" "${percent}"
    
    if [[ ${current} -eq ${total} ]]; then
        echo
    fi
}

# Initialization
init_logging
