#!/usr/bin/env bash
# Git dual-account helper functions for personal (rj9884) & work (rajan9884)

# Show current git identity and active repository account
git-whoami() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not inside a git repository."
        echo "Global Identity: $(git config --global user.name 2>/dev/null || echo 'not set') <$(git config --global user.email 2>/dev/null || echo 'not set')>"
        return 0
    fi

    local name email remote profile
    name="$(git config user.name 2>/dev/null || echo 'unset')"
    email="$(git config user.email 2>/dev/null || echo 'unset')"
    remote="$(git remote get-url origin 2>/dev/null || echo 'no remote origin')"

    if [[ "$email" == *"rj.vidyagyan@gmail.com"* ]] || [[ "$name" == "rj9884" ]] || [[ "$remote" == *"github.com-personal"* ]]; then
        profile="Personal (rj9884)"
    elif [[ "$email" == *"rajan.dev.jaiswal@gmail.com"* ]] || [[ "$name" == "rajan9884" ]] || [[ "$remote" == *"github.com-work"* ]]; then
        profile="Work (rajan9884)"
    else
        profile="Custom / Default"
    fi

    printf "\033[1;34m[Git Status]\033[0m Repo: %s\n" "$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")")"
    printf "  Profile: \033[1;32m%s\033[0m\n" "$profile"
    printf "  User:    %s <%s>\n" "$name" "$email"
    printf "  Remote:  %s\n" "$remote"
}

# Switch current repository to Personal identity
git-use-personal() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: Must be run inside a git repository." >&2
        return 1
    fi
    git config user.name "rj9884"
    git config user.email "rj.vidyagyan@gmail.com"

    local remote
    remote="$(git remote get-url origin 2>/dev/null || true)"
    if [[ "$remote" == *"github.com:"* ]]; then
        local new_remote="${remote/github.com:/github.com-personal:}"
        git remote set-url origin "$new_remote"
    elif [[ "$remote" == *"github.com-work:"* ]]; then
        local new_remote="${remote/github.com-work:/github.com-personal:}"
        git remote set-url origin "$new_remote"
    fi

    printf "\033[1;32m[OK]\033[0m Switched repository to Personal account (rj9884 <rj.vidyagyan@gmail.com>)\n"
    git-whoami
}

# Switch current repository to Work identity
git-use-work() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Error: Must be run inside a git repository." >&2
        return 1
    fi
    git config user.name "rajan9884"
    git config user.email "rajan.dev.jaiswal@gmail.com"

    local remote
    remote="$(git remote get-url origin 2>/dev/null || true)"
    if [[ "$remote" == *"github.com:"* ]]; then
        local new_remote="${remote/github.com:/github.com-work:}"
        git remote set-url origin "$new_remote"
    elif [[ "$remote" == *"github.com-personal:"* ]]; then
        local new_remote="${remote/github.com-personal:/github.com-work:}"
        git remote set-url origin "$new_remote"
    fi

    printf "\033[1;32m[OK]\033[0m Switched repository to Work account (rajan9884 <rajan.dev.jaiswal@gmail.com>)\n"
    git-whoami
}

# Interactive account switcher
git-switch-account() {
    local choice
    if command -v gum >/dev/null 2>&1; then
        choice=$(gum choose "Personal (rj9884)" "Work (rajan9884)" "Check current (git-whoami)")
    else
        echo "Select Git Account:"
        echo "1) Personal (rj9884)"
        echo "2) Work (rajan9884)"
        echo "3) Check current (git-whoami)"
        read -r -p "Choice [1-3]: " c
        case "$c" in
            1) choice="Personal (rj9884)" ;;
            2) choice="Work (rajan9884)" ;;
            *) choice="Check current (git-whoami)" ;;
        esac
    fi

    case "$choice" in
        *"Personal"*) git-use-personal ;;
        *"Work"*)     git-use-work ;;
        *)            git-whoami ;;
    esac
}

# Clone helpers
git-clone-personal() {
    if [ -z "${1:-}" ]; then
        echo "Usage: git-clone-personal <repo-or-url> [dir]" >&2
        return 1
    fi
    local repo="$1"
    shift
    if [[ "$repo" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$ ]]; then
        git clone "git@github.com-personal:${repo}.git" "$@"
    else
        local adjusted="${repo/github.com:/github.com-personal:}"
        git clone "$adjusted" "$@"
    fi
}

git-clone-work() {
    if [ -z "${1:-}" ]; then
        echo "Usage: git-clone-work <repo-or-url> [dir]" >&2
        return 1
    fi
    local repo="$1"
    shift
    if [[ "$repo" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$ ]]; then
        git clone "git@github.com-work:${repo}.git" "$@"
    else
        local adjusted="${repo/github.com:/github.com-work:}"
        git clone "$adjusted" "$@"
    fi
}
