#!/bin/bash

# Guard against multiple sourcing
if [[ -n "${_COLORS_SOURCED:-}" ]]; then
    return
fi
readonly _COLORS_SOURCED=1

# Color definitions

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color