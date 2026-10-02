#!/usr/bin/env python3
"""
statusline with gruvbox-material soft colors.
Minimal separators, smart color thresholds, Nerd Font icons only.
"""

import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import TypedDict


class GitDiffStats(TypedDict):
    added: int
    modified: int
    removed: int


class GitRemoteStatus(TypedDict):
    ahead: int
    behind: int


class Gruvbox:
    """Gruvbox-material soft palette - muted by default, colors only for alerts"""

    # Default muted grey for everything
    MUTED = 245  # #928374 - primary text color
    DIM = 243  # #7c6f64 - secondary/less important
    SEP = 239  # #504945 - separator

    # Alert colors (only used when thresholds hit)
    GREEN = 143  # #a9b665 - positive/clean
    YELLOW = 179  # #d8a657 - warning
    ORANGE = 208  # #e78a4e - attention
    RED = 167  # #ea6962 - critical

    RESET = "\033[0m"


class Icons:
    """Nerd Font icons (no emojis)"""

    MODEL = ""
    GIT = ""
    FOLDER = ""
    CLOCK = "󰥔"
    PLUS = ""
    MINUS = ""
    MODIFIED = "󰪥"
    CONTEXT = "󰍛"
    AHEAD = "↑"   # commits ahead of remote
    BEHIND = "↓"  # commits behind remote


class Config:
    """Configurable via environment variables"""

    CTX_WARN = float(os.environ.get("STATUSLINE_CTX_WARN", "50"))
    CTX_CRIT = float(os.environ.get("STATUSLINE_CTX_CRIT", "70"))
    GIT_TIMEOUT = float(os.environ.get("STATUSLINE_GIT_TIMEOUT", "2"))
    MAX_BRANCH_LEN = int(os.environ.get("STATUSLINE_MAX_BRANCH", "25"))


def fg(color_code: int) -> str:
    """Set foreground color"""
    return f"\033[38;5;{color_code}m"


def sep() -> str:
    """Minimal separator with breathing room"""
    return f" {fg(Gruvbox.SEP)}│ "


def git_color(has_changes: bool) -> int:
    """Muted when clean, orange when dirty"""
    return Gruvbox.ORANGE if has_changes else Gruvbox.MUTED


def context_color(percent: float) -> int:
    """Muted by default, yellow > CTX_WARN, red > CTX_CRIT"""
    if percent > Config.CTX_CRIT:
        return Gruvbox.RED
    if percent > Config.CTX_WARN:
        return Gruvbox.YELLOW
    return Gruvbox.MUTED


def get_git_dir(cwd: str) -> Path | None:
    """Get actual git directory, handling worktrees"""
    git_path = Path(cwd) / ".git"
    if git_path.is_file():
        # Worktree: .git is a file containing "gitdir: /path/to/git"
        try:
            content = git_path.read_text().strip()
            if content.startswith("gitdir: "):
                return Path(content[8:])
        except Exception:
            pass
        return None
    elif git_path.is_dir():
        return git_path
    return None


def get_git_branch(cwd: str) -> tuple[str | None, Path | None]:
    """Get current git branch name and git directory"""
    git_dir = get_git_dir(cwd)
    if git_dir is None:
        return None, None

    git_head = git_dir / "HEAD"
    if not git_head.exists():
        return None, git_dir

    try:
        ref = git_head.read_text().strip()
        if ref.startswith("ref: refs/heads/"):
            return ref.replace("ref: refs/heads/", ""), git_dir
        return ref[:7], git_dir  # Detached HEAD
    except Exception:
        return None, git_dir


def get_git_state(git_dir: Path) -> str | None:
    """Detect special git states (merge, rebase, etc.)"""
    if (git_dir / "MERGE_HEAD").exists():
        return "MERGING"
    if (git_dir / "rebase-merge").exists() or (git_dir / "rebase-apply").exists():
        return "REBASING"
    if (git_dir / "CHERRY_PICK_HEAD").exists():
        return "CHERRY-PICK"
    if (git_dir / "BISECT_LOG").exists():
        return "BISECTING"
    return None


def truncate_branch(name: str) -> str:
    """Truncate long branch names"""
    if len(name) <= Config.MAX_BRANCH_LEN:
        return name
    return name[: Config.MAX_BRANCH_LEN - 1] + "…"


def get_git_diff_stats(cwd: str) -> GitDiffStats | None:
    """Get git diff statistics"""
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=Config.GIT_TIMEOUT,
        )

        if result.returncode != 0:
            return None

        lines = [line for line in result.stdout.strip().split("\n") if line]
        if not lines:
            return None

        added, modified, removed = 0, 0, 0

        for line in lines:
            status = line[:2]
            # Count each file once, prioritizing the most significant status
            # Untracked files
            if status == "??":
                added += 1
            # Deleted (in index or working tree)
            elif "D" in status:
                removed += 1
            # Added to index
            elif status[0] == "A":
                added += 1
            # Modified (in index or working tree)
            elif "M" in status:
                modified += 1

        if added == 0 and modified == 0 and removed == 0:
            return None

        return {"added": added, "modified": modified, "removed": removed}

    except Exception:
        return None


def get_git_remote_status(cwd: str) -> GitRemoteStatus | None:
    """Get commits ahead/behind remote tracking branch"""
    try:
        # Check if upstream exists
        result = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "@{upstream}"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=Config.GIT_TIMEOUT,
        )
        if result.returncode != 0:
            return None  # No upstream configured

        # Get ahead/behind counts
        result = subprocess.run(
            ["git", "rev-list", "--left-right", "--count", "HEAD...@{upstream}"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=Config.GIT_TIMEOUT,
        )
        if result.returncode != 0:
            return None

        ahead, behind = map(int, result.stdout.strip().split())
        if ahead == 0 and behind == 0:
            return None
        return {"ahead": ahead, "behind": behind}

    except Exception:
        return None


def get_all_git_info(cwd: str) -> tuple[GitDiffStats | None, GitRemoteStatus | None]:
    """Get git diff and remote status in parallel"""
    with ThreadPoolExecutor(max_workers=2) as executor:
        diff_future = executor.submit(get_git_diff_stats, cwd)
        remote_future = executor.submit(get_git_remote_status, cwd)

        try:
            diff = diff_future.result(timeout=Config.GIT_TIMEOUT)
        except Exception:
            diff = None
        try:
            remote = remote_future.result(timeout=Config.GIT_TIMEOUT)
        except Exception:
            remote = None

        return diff, remote


def format_duration(ms: float | None) -> str:
    """Format duration from milliseconds"""
    if not ms or ms < 0:
        return "0s"

    seconds = int(ms / 1000)
    if seconds < 60:
        return f"{seconds}s"

    minutes = seconds // 60
    if minutes < 60:
        return f"{minutes}m"

    hours = minutes // 60
    remaining_min = minutes % 60
    if hours < 24:
        return f"{hours}h{remaining_min}m" if remaining_min else f"{hours}h"

    days = hours // 24
    remaining_hours = hours % 24
    return f"{days}d{remaining_hours}h"


def get_context_percent(data: dict) -> float | None:
    """Calculate context window usage percentage"""
    ctx = data.get("context_window", {})

    # Use pre-calculated percentage if available (new field)
    used_pct = ctx.get("used_percentage")
    if used_pct is not None:
        return used_pct

    # Fallback: manual calculation for backwards compatibility
    window_size = ctx.get("context_window_size")
    usage = ctx.get("current_usage")

    if not window_size or not usage:
        return None

    current = (
        usage.get("input_tokens", 0)
        + usage.get("cache_creation_input_tokens", 0)
        + usage.get("cache_read_input_tokens", 0)
    )

    return (current / window_size) * 100 if window_size > 0 else 0


def main():
    try:
        data = json.load(sys.stdin)

        # Extract data
        model_name = data.get("model", {}).get("display_name", "Claude")
        cwd = data.get("workspace", {}).get("current_dir", os.getcwd())
        stats = data.get("cost", {})

        session_duration = stats.get("total_duration_ms", 0)
        lines_added = stats.get("total_lines_added", 0)
        lines_removed = stats.get("total_lines_removed", 0)

        git_branch, git_dir = get_git_branch(cwd)
        git_state = get_git_state(git_dir) if git_dir else None
        git_diff, git_remote = get_all_git_info(cwd) if git_branch else (None, None)
        has_changes = git_diff is not None

        dir_name = os.path.basename(cwd) or "~"
        context_pct = get_context_percent(data)

        # Build statusline components (muted grey by default, colors only for alerts)
        parts = []

        # Model (muted)
        parts.append(f"{fg(Gruvbox.MUTED)}{Icons.MODEL} {model_name}")

        # Git (muted when clean, orange when dirty)
        if git_branch:
            branch_color = git_color(has_changes)
            display_branch = truncate_branch(git_branch)
            if git_state:
                display_branch += f"|{git_state}"
            git_part = f"{fg(branch_color)}{Icons.GIT} {display_branch}"

            # Remote status (ahead/behind)
            if git_remote:
                if git_remote["ahead"] > 0:
                    git_part += f" {Icons.AHEAD}{git_remote['ahead']}"
                if git_remote["behind"] > 0:
                    git_part += f" {Icons.BEHIND}{git_remote['behind']}"

            # File diff stats
            if git_diff:
                diff_bits = []
                if git_diff["added"] > 0:
                    diff_bits.append(f"{Icons.PLUS} {git_diff['added']}")
                if git_diff["modified"] > 0:
                    diff_bits.append(f"{Icons.MODIFIED} {git_diff['modified']}")
                if git_diff["removed"] > 0:
                    diff_bits.append(f"{Icons.MINUS} {git_diff['removed']}")
                if diff_bits:
                    git_part += " " + " ".join(diff_bits)

            parts.append(git_part)

        # Directory (muted)
        parts.append(f"{fg(Gruvbox.MUTED)}{Icons.FOLDER} {dir_name}")

        # Duration (dim)
        if session_duration > 0:
            parts.append(
                f"{fg(Gruvbox.DIM)}{Icons.CLOCK} {format_duration(session_duration)}"
            )

        # Lines changed (muted)
        if lines_added > 0 or lines_removed > 0:
            lines_part = f"{fg(Gruvbox.MUTED)}"
            if lines_added > 0:
                lines_part += f"{Icons.PLUS} {lines_added}"
            if lines_removed > 0:
                if lines_added > 0:
                    lines_part += " "
                lines_part += f"{Icons.MINUS} {lines_removed}"
            parts.append(lines_part)

        # Context window (muted by default, colored on threshold)
        if context_pct is not None:
            ctx_col = context_color(context_pct)
            parts.append(f"{fg(ctx_col)}{Icons.CONTEXT} {context_pct:.0f}%")

        # Join with minimal separators
        statusline = sep().join(parts) + Gruvbox.RESET
        print(statusline, flush=True)

    except Exception:
        print("Claude Code", flush=True)


if __name__ == "__main__":
    main()
