# Requirements: Containerised Pi Wrapper

## Overview
A wrapper command that runs the pi coding agent inside a Podman container, restricting all filesystem access to the current project directory and the user's pi configuration folder. This applies globally to all projects and prevents pi from accidentally reading or writing files outside the active project.

## Problem Statement
When running pi from a project directory, there is nothing stopping it from reading or modifying files anywhere on the host filesystem. This creates a risk of accidental changes outside the project. The goal is a hard filesystem boundary so that pi can only see what it needs: the current project and its own configuration.

## Goals
- Pi can never read or write files outside the mounted volumes.
- The wrapper works transparently across all projects — just `cd` and run.
- Works consistently on both macOS and Linux.
- The pi TUI remains fully functional (TTY passthrough).
- No changes required to pi itself or to existing projects.

## Non-Goals
- Replacing the existing `pi` command (a separate command is acceptable).
- Restricting network access (pi must reach LLM provider APIs).
- Managing or modifying pi configuration or credentials.
- Supporting container runtimes other than Podman.

## Users & Actors
| Actor | Description | Notes |
|-------|-------------|-------|
| Developer | Runs pi from a project directory on macOS or Linux | Primary user |
| Pi agent | Executes inside the container; subject to filesystem restrictions | Contained process |

## Functional Requirements

### Wrapper Command
**Description:** A command (`pi-box`) that the user runs instead of `pi`. It builds and starts a Podman container, runs pi inside it with the correct mounts and TTY, then exits cleanly when pi exits.

**Acceptance Criteria:**
- [ ] Running `pi-box` from any directory launches pi inside a Podman container.
- [ ] The container exits and is removed automatically when pi exits.
- [ ] The wrapper passes through all arguments to pi (e.g. `pi-box chat`, `pi-box --help`).
- [ ] The exit code of the wrapper matches the exit code of pi.

### Filesystem Isolation
**Description:** The container has exactly two volume mounts. Everything else on the host filesystem is inaccessible.

**Acceptance Criteria:**
- [ ] The current working directory is mounted at the same absolute path inside the container (read-write).
- [ ] `~/.pi/` is mounted into the container (read-write).
- [ ] No other host paths are accessible inside the container.
- [ ] Attempts by pi to access paths outside these mounts fail (path simply does not exist).

### Pre-installed Developer Tools
**Description:** The container image includes the tools pi relies on internally and the tools most commonly invoked via the `bash` tool during real development work. This avoids runtime downloads and ensures a consistent, fast environment.

**Pi-managed binaries (pre-installed as system packages to avoid first-run downloads):**
- `fd` / `fdfind` — backs pi's built-in `find` tool (pi downloads from GitHub if absent; pre-installing eliminates this)
- `rg` (ripgrep) — backs pi's built-in `grep` tool (same rationale)

**Common developer tools (available via the `bash` tool):**
- `curl` — HTTP requests, downloading files, API testing
- `jq` — JSON processing
- `make` — build automation
- `python3` — scripting and one-off tasks
- `openssh-client` — git operations over SSH

**Acceptance Criteria:**
- [ ] `fd` or `fdfind` is on `$PATH` inside the container; pi's find tool does not trigger a download.
- [ ] `rg` is on `$PATH` inside the container; pi's grep tool does not trigger a download.
- [ ] `curl`, `jq`, `make`, `python3`, and `ssh` are available on `$PATH` inside the container.

### TTY / TUI Passthrough
**Description:** The container is started with a pseudo-TTY and stdin attached so the pi terminal UI works exactly as it does outside the container.

**Acceptance Criteria:**
- [ ] The pi TUI renders correctly inside the container.
- [ ] Keyboard input, resizing, and interactive features work normally.

### Cross-Platform Support
**Description:** The wrapper script runs on both macOS and Linux without modification.

**Acceptance Criteria:**
- [ ] The script uses only POSIX-compatible shell features.
- [ ] Home directory and current directory are resolved correctly on both platforms.
- [ ] Podman is the only runtime dependency.

## Edge Cases & Error Handling
| Scenario | Expected Behaviour |
|----------|--------------------|
| Podman is not installed | Wrapper exits with a clear error message pointing to the missing dependency |
| `~/.pi/` does not exist | Wrapper warns the user and starts the container without that mount |
| Current directory cannot be mounted (permissions) | Podman surfaces an error; wrapper propagates it and exits non-zero |
| Pi crashes inside the container | Container exits; wrapper returns pi's non-zero exit code |
| User presses Ctrl-C | Signal is forwarded to pi; container exits cleanly |

## Non-Functional Requirements
| Category | Requirement |
|----------|-------------|
| Security | No host filesystem paths outside the two mounts are accessible inside the container |
| Portability | Single shell script; no external dependencies beyond Podman and a container image with pi installed |
| Performance | Container start-up overhead should be negligible (< 2 s on a typical machine) |
| Reliability | Container is always removed on exit (use `--rm` flag) to avoid stale containers |

## Technical Constraints
- **Container runtime:** Podman (rootless preferred)
- **Shell:** POSIX sh (compatible with bash and zsh)
- **OS targets:** macOS, Linux
- **Base image:** `node:lts-slim`
- **Pi installation:** Pi must be available inside the container image (pre-installed in image or installed at build time via npm)
- **No root required:** The wrapper and container should run as the current user
- **Working directory inside container:** Fixed path `/workspace`; the current host directory is always mounted there

## Data Model
No persistent data. State is limited to:
- **Current directory** — the project being worked on, bind-mounted read-write.
- **`~/.pi/`** — pi config, skills, and credentials, bind-mounted read-only.

## Interfaces
- **CLI:** `pi-box [args…]` — thin shell script wrapper, installed somewhere on `$PATH` (e.g. `~/.local/bin/pi-box` or `/usr/local/bin/pi-box`)
- **Container image:** A Podman image with pi (Node.js package) pre-installed, built from a `Containerfile` maintained alongside the wrapper script; the user runs `podman build` manually before first use

## Open Questions
| # | Question | Owner | Status |
|---|----------|-------|--------|
| 1 | What should the container image be based on? (e.g. `node:lts-alpine`, `node:lts-slim`) | Developer | Resolved: `node:lts-slim` |
| 2 | Should the wrapper script auto-build the image if it is not found, or require a manual `podman build` step first? | Developer | Resolved: manual `podman build` |
| 3 | Should `cpi` be the final command name, or does the developer prefer something else? | Developer | Resolved: `pi-box` |
| 4 | Should the current directory be mounted at its exact host path or always at a fixed path like `/workspace` inside the container? | Developer | Resolved: fixed path `/workspace` |
