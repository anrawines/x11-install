#!/bin/bash

# Guard against multiple sourcing
if [[ -n "${_HELPERS_SOURCED:-}" ]]; then
    return
fi
readonly _HELPERS_SOURCED=1

source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# Global variables for selected helpers
PACMAN_HELPER=""
declare -gA SELECTED_WMS=()
declare -gA SELECTED_PROGRAMS=()

helpers::choose_package_helper() {
    log_section "Package Helper Selection"
    
    # Detect if yay or paru are already installed
    local detected=""
    if command -v yay &>/dev/null; then
        detected="yay"
    elif command -v paru &>/dev/null; then
        detected="paru"
    fi
    
    # If one is already installed, use it
    if [[ -n "$detected" ]]; then
        log_success "Found installed package helper: $detected"
        if helpers::prompt_yn "Use $detected?"; then
            PACMAN_HELPER="$detected"
            log_success "Using $PACMAN_HELPER for all packages"
            return 0
        fi
    fi
    
    # Let user choose between yay and paru, with yay as default
    local options=("yay" "paru")
    
    PS3="Select package helper (1=yay [default], 2=paru, or press Enter for yay): "
    select selected in "${options[@]}"; do
        case $selected in
            yay|paru)
                if ! command -v "$selected" &>/dev/null; then
                    log_info "Installing $selected..."
                    sudo pacman -S --needed --noconfirm base-devel git
                    git clone "https://aur.archlinux.org/${selected}.git" "/tmp/${selected}"
                    pushd "/tmp/${selected}" > /dev/null
                    makepkg -si --noconfirm
                    popd > /dev/null
                fi
                PACMAN_HELPER="$selected"
                log_success "Using $PACMAN_HELPER for all packages"
                break
                ;;
            *)
                if [[ -z "$selected" ]]; then
                    # Default to yay on empty input
                    if ! command -v yay &>/dev/null; then
                        log_info "Installing yay..."
                        sudo pacman -S --needed --noconfirm base-devel git
                        git clone "https://aur.archlinux.org/yay.git" "/tmp/yay"
                        pushd "/tmp/yay" > /dev/null
                        makepkg -si --noconfirm
                        popd > /dev/null
                    fi
                    PACMAN_HELPER="yay"
                    log_success "Using yay (default) for all packages"
                    break
                else
                    log_warn "Invalid selection"
                fi
                ;;
        esac
    done
}

helpers::list_category_options() {
    local category_folder=$1
    local -n options_arr=$2
    
    if [[ ! -d "$category_folder" ]]; then
        log_error "Category folder not found: $category_folder"
        return 1
    fi
    
    local count=0
    local seen=()
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            # Remove .txt or .sh extension
            local name="${file%.*}"
            name=$(basename "$name")
            
            # Skip duplicates (when both .txt and .sh exist, prefer .sh)
            if [[ ! " ${seen[@]} " =~ " $name " ]]; then
                options_arr+=("$name")
                seen+=("$name")
                ((count++))
            fi
        fi
    done < <(find "$category_folder" -maxdepth 1 \( -name "*.sh" -o -name "*.txt" \) | sort)
    
    if [[ $count -eq 0 ]]; then
        log_warn "No options found in $category_folder"
        return 1
    fi
    
    return 0
}

helpers::detect_installed_wms() {
    local -n installed_arr=$1
    local wm_folder="${SCRIPT_DIR}/packages/wm"
    
    # First, use the generic detector from validators
    source "$(dirname "${BASH_SOURCE[0]}")/validators.sh"
    local generic_installed=()
    validators::get_installed_wms generic_installed
    
    # Add generic detections to the list if they are valid WMs
    for wm in "${generic_installed[@]}"; do
        if validators::is_valid_wm "$wm"; then
            if [[ ! " ${installed_arr[@]} " =~ " $wm " ]]; then
                installed_arr+=("$wm")
            fi
        fi
    done
    
    if [[ ! -d "$wm_folder" ]]; then
        return 0
    fi
    
    # For each WM in the folder, check if it's installed (if not already detected)
    for wm_file in "$wm_folder"/{*.txt,*.sh}; do
        if [[ ! -f "$wm_file" ]]; then
            continue
        fi
        
        local wm_name=$(basename "$wm_file" .txt)
        wm_name=$(basename "$wm_name" .sh)
        
        # Skip duplicates (if both .txt and .sh exist, prefer checking .sh first)
        if [[ " ${installed_arr[@]} " =~ " $wm_name " ]]; then
            continue
        fi
        
        local is_installed=false
        
        if [[ "$wm_file" == *.sh ]]; then
            # For .sh files, check if packages::check function exists and validates
            if (
                source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
                source "$wm_file"
                if declare -f packages::check >/dev/null 2>&1; then
                    packages::check >/dev/null 2>&1
                else
                    # If no packages::check function, check for the binary directly
                    case "$wm_name" in
                        dwm) command -v dwm &>/dev/null ;;
                        xmonad) 
                            if pacman -Qi xmonad &>/dev/null 2>&1; then
                                true
                            else
                                command -v xmonad &>/dev/null
                            fi
                            ;;
                        *) false ;;
                    esac
                fi
            ) 2>/dev/null; then
                is_installed=true
            fi
        else
            # For .txt files, check if the main package is installed
            # Get the first non-comment, non-empty line (the main WM package)
            local main_package=$(grep -v "^#" "$wm_file" | grep -v "^$" | head -1)
            
            if [[ -n "$main_package" ]]; then
                if pacman -Qi "$main_package" &>/dev/null 2>&1; then
                    is_installed=true
                fi
            fi
        fi
        
        if $is_installed; then
            installed_arr+=("$wm_name")
        fi
    done
    
    return 0
}

helpers::display_menu_with_installed() {
    local -n opts=$1
    local -n insts=$2
    
    for i in "${!opts[@]}"; do
        local opt="${opts[$i]}"
        local status=""
        
        for inst in "${insts[@]}"; do
            if [[ "$opt" == "$inst" ]]; then
                status=" $(printf '\033[0;32m✓ INSTALLED\033[0m')"
                break
            fi
        done
        
        echo "  $((i+1)). $opt$status"
    done
}

helpers::select_window_managers() {
    log_section "Select Window Managers to Install"
    
    local wm_folder="${SCRIPT_DIR}/packages/wm"
    local wms=()
    local installed_wms=()
    
    helpers::list_category_options "$wm_folder" wms || {
        log_error "Failed to load window managers from $wm_folder"
        return 1
    }
    
    helpers::detect_installed_wms installed_wms
    
    echo "Available window managers:"
    echo
    helpers::display_menu_with_installed wms installed_wms
    echo
    echo "  0. Skip window manager selection (continue with other options)"
    echo
    
    local input
    read -p "Enter numbers separated by spaces or 0 to skip (e.g., 1 2 4): " input
    
    if [[ -z "$input" ]]; then
        log_warn "No input provided, skipping WM selection"
        return 0
    fi
    
    if [[ "$input" == "0" ]]; then
        log_info "Skipping window manager installation"
        return 0
    fi
    
    local valid_count=${#wms[@]}
    local found_valid=false
    
    for num in $input; do
        if [[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= valid_count )); then
            SELECTED_WMS["${wms[$((num-1))]}"]="1"
            found_valid=true
        else
            log_warn "Skipping invalid selection: $num (must be 1-$valid_count or 0 to skip)"
        fi
    done
    
    if $found_valid; then
        log_success "Selected: ${!SELECTED_WMS[@]}"
    else
        log_warn "No valid window managers selected, continuing with other options"
    fi
    
    return 0
}

helpers::select_optional_programs() {
    log_section "Select Additional Programs (Optional)"
    
    local program_folder="${SCRIPT_DIR}/packages/program"
    local programs=()
    
    if ! helpers::list_category_options "$program_folder" programs; then
        log_warn "No optional programs available"
        return 0
    fi
    
    if [[ ${#programs[@]} -eq 0 ]]; then
        log_info "No programs available"
        return 0
    fi
    
    echo "Available program packages:"
    echo
    
    for i in "${!programs[@]}"; do
        echo "  $((i+1)). ${programs[$i]}"
    done
    
    echo
    echo "  0. Skip additional programs"
    echo
    
    local input
    read -p "Enter numbers separated by spaces or 0 to skip (e.g., 1 2): " input
    
    if [[ -z "$input" || "$input" == "0" ]]; then
        log_info "Skipping additional programs"
        return 0
    fi
    
    local valid_count=${#programs[@]}
    local found_valid=false
    
    for num in $input; do
        if [[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= valid_count )); then
            SELECTED_PROGRAMS["${programs[$((num-1))]}"]="1"
            found_valid=true
        else
            log_warn "Skipping invalid selection: $num (must be 1-$valid_count or 0 to skip)"
        fi
    done
    
    if $found_valid; then
        log_success "Selected programs: ${!SELECTED_PROGRAMS[@]}"
    else
        log_warn "No valid programs selected"
    fi
    
    return 0
}

helpers::prompt_yn() {
    local prompt=$1
    local response
    
    read -p "$prompt (y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

helpers::run_with_helper() {
    local helper=$1
    shift
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        return 0
    fi
    
    case "$helper" in
        pacman)
            sudo pacman -S --needed --noconfirm "${packages[@]}" || {
                log_warn "Some pacman packages failed to install"
                return 1
            }
            ;;
        yay|paru)
            # Use --ask=4 to automatically remove conflicting packages
            "$helper" -S --needed --noconfirm --ask=4 "${packages[@]}" || {
                log_warn "Some AUR packages failed to install (may be normal if not found)"
                return 1
            }
            ;;
        *)
            log_error "Unknown helper: $helper"
            return 1
            ;;
    esac
}
