"""Shared helpers for the standards hooks.

Tracks per-session state (last code edit, last validation run) in a temporary
directory and locates the project's plan.md and todo.md files.
"""

import json
import os
import re
import sys
import tempfile

DOC_EXTENSIONS = (".md", ".mdx", ".rst", ".txt")
SKIP_DIRS = {".git", "node_modules", ".venv", "venv", "dist", "build", "target", ".terraform", "__pycache__"}
SECRET_PATTERNS = [
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    re.compile(r"\b(ghp|gho|ghs|ghu)_[A-Za-z0-9]{36}\b"),
    re.compile(r"\bgithub_pat_[A-Za-z0-9_]{20,}"),
    re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}"),
    re.compile(r"\bsk-(ant-)?[A-Za-z0-9_-]{20,}"),
    re.compile(r"(?i)(api[_-]?key|secret|passw(or)?d|token)[\"']?\s*[:=]\s*[\"'][^\"'\s$<{]{8,}[\"']"),
]


def read_payload():
    """Parse the hook payload that Claude Code sends on stdin."""
    return json.load(sys.stdin)


def project_dir(payload):
    """Return the absolute project root for this session.

    Prefers CLAUDE_PROJECT_DIR and falls back to the payload's cwd.
    """
    return os.path.realpath(os.environ.get("CLAUDE_PROJECT_DIR") or payload.get("cwd") or ".")


def state_path(payload, name):
    """Return the path of a per-session state marker file.

    The session directory is created on first use under the system temp dir.
    """
    session = re.sub(r"[^A-Za-z0-9_-]", "", payload.get("session_id", "default")) or "default"
    directory = os.path.join(tempfile.gettempdir(), "claude-standards", session)
    os.makedirs(directory, exist_ok=True)
    return os.path.join(directory, name)


def touch(payload, name):
    """Set a state marker's timestamp to now."""
    path = state_path(payload, name)
    with open(path, "a", encoding="utf-8"):
        pass
    os.utime(path, None)


def marker_time(payload, name):
    """Return a state marker's timestamp, or None when it was never set."""
    path = state_path(payload, name)
    return os.path.getmtime(path) if os.path.exists(path) else None


def session_start(payload):
    """Return the session start time from the transcript file's creation time.

    Returns None when the transcript is unavailable.
    """
    transcript = payload.get("transcript_path")
    if not transcript or not os.path.exists(transcript):
        return None
    info = os.stat(transcript)
    return getattr(info, "st_birthtime", info.st_ctime)


def planning_files(project):
    """Find plan.md and todo.md files in the project, case-insensitively.

    Returns two lists of paths, skipping vendored and generated directories.
    """
    plans, todos = [], []
    base_depth = project.rstrip(os.sep).count(os.sep)
    for root, dirs, files in os.walk(project):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".claude")]
        if root.count(os.sep) - base_depth >= 4:
            dirs[:] = []
        for name in files:
            lower = name.lower()
            if lower == "plan.md":
                plans.append(os.path.join(root, name))
            elif lower == "todo.md":
                todos.append(os.path.join(root, name))
    return plans, todos


def newest(paths):
    """Return the newest modification time among paths, or None if empty."""
    return max((os.path.getmtime(p) for p in paths), default=None)


def classify(path, project):
    """Classify an edited file as 'exempt', 'doc', or 'code'.

    Exempt files are outside the project, Claude config, CLAUDE.md,
    .claudeignore, and the planning files themselves.
    """
    full = os.path.realpath(path)
    if not full.startswith(project + os.sep):
        return "exempt"
    relative = os.path.relpath(full, project)
    name = os.path.basename(full).lower()
    if relative.split(os.sep)[0] == ".claude" or name in ("claude.md", ".claudeignore", "plan.md", "todo.md"):
        return "exempt"
    return "doc" if name.endswith(DOC_EXTENSIONS) else "code"


def find_secret(text):
    """Return the first line of text that looks like a credential, or None."""
    for line in text.splitlines():
        if any(pattern.search(line) for pattern in SECRET_PATTERNS):
            return line.strip()[:120]
    return None
