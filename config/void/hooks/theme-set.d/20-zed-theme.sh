#!/bin/bash
set -euo pipefail
if command -v void-theme-set-zed >/dev/null 2>&1; then
    void-theme-set-zed >/dev/null 2>&1 || true
elif [ -x "$HOME/omavoid/local/bin/void-theme-set-zed" ]; then
    "$HOME/omavoid/local/bin/void-theme-set-zed" >/dev/null 2>&1 || true
fi
