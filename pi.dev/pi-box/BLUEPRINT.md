# Blueprint: Containerised Pi Wrapper

_Generated from: `REQUIREMENTS.md`_

---

## Architecture Overview

This project consists of two artifacts: a `Containerfile` that produces a `node:lts-slim`-based image with pi installed globally via npm, and a POSIX shell script (`pi-box`) that wraps `podman run` to launch pi inside that image. No framework, database, or network layer is involved — the entire system is a thin shell invocation around Podman.

When the user runs `pi-box` from a project directory, the script mounts the current directory at `/workspace` (read-write) and `~/.pi` at `/root/.pi` (read-only), then starts the container with a TTY attached. The container process replaces any need for the bare `pi` command; when pi exits, the container is automatically removed and the exit code is forwarded to the calling shell.

The image is built once manually by the user (`podman build`). The wrapper script is installed on `$PATH` and works identically on macOS and Linux.

### Tech Stack

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Container runtime | Podman (rootless) | Specified requirement; no-daemon, rootless by default |
| Base image | `node:lts-slim` | Specified requirement; smaller than full image, sufficient for Node/npm |
| Pi installation | npm global install inside image | Standard install method for the pi package |
| Wrapper script | POSIX sh | Specified requirement; compatible with bash and zsh on macOS and Linux |
| Image definition | `Containerfile` (OCI format) | Podman-native; identical syntax to Dockerfile |

### Components

| Component | Responsibility | Technology |
|-----------|---------------|------------|
| `Containerfile` | Defines the container image: base image, pi installation, default working directory | OCI `Containerfile` |
| `pi-box` script | Entry point for the user; validates dependencies, builds the `podman run` command, forwards TTY and signals, propagates exit code | POSIX sh |
| Container image (`pi-box:latest`) | Runtime environment for pi; provides filesystem isolation | Podman / `node:lts-slim` |

### Data Flow

1. User runs `pi-box [args…]` from a project directory.
2. Script verifies Podman is installed; exits with an error if not.
3. Script checks whether `~/.pi` exists; warns if absent but continues.
4. Script assembles the `podman run` command:
   - `--rm` — remove container on exit
   - `-it` — allocate a pseudo-TTY and attach stdin
   - `-v "$(pwd)":/workspace:z` — mount project directory read-write
   - `-v "$HOME/.pi":/root/.pi:ro,z` — mount pi config read-only (if present)
   - `-w /workspace` — set working directory
   - `pi-box:latest pi [args…]` — image name and command
5. Podman starts the container; pi runs with the TUI attached to the terminal.
6. When pi exits, the container is removed; the script exits with pi's exit code.

> **Note on the `:z` volume flag:** required on SELinux-enabled Linux systems (e.g. Fedora, RHEL). It is silently accepted on macOS/Podman-machine and non-SELinux Linux, so it is safe to include unconditionally.

### Project Structure

```
pi_container/
├── Containerfile        # Image definition (build once with: podman build -t pi-box .)
├── pi-box               # Wrapper shell script (install on $PATH)
├── REQUIREMENTS.md      # Requirements spec
├── BLUEPRINT.md         # This file
└── README.md            # Setup and usage instructions
```

### Architectural Decisions

| Decision | Choice | Rationale | Alternative Considered |
|----------|--------|-----------|----------------------|
| Mount path for project dir | Fixed `/workspace` | Predictable, avoids host path leaking into container | Mirror host absolute path — adds complexity, not needed |
| Mount path for `~/.pi` | `/root/.pi` | Pi runs as root inside the container (rootless Podman maps this to the host user on the filesystem) | Run as a mapped non-root user — more complex, no security benefit given rootless Podman |
| Image name | `pi-box:latest` | Simple, matches project name | Versioned tags — unnecessary for a personal tool |
| Signal handling | `exec podman run …` (replace shell process) | `exec` means signals go directly to Podman, which forwards them to pi; no trap needed | `trap` in shell — more code, more edge cases |
| SELinux volume labels | `:z` on both mounts | Required for SELinux hosts; harmless elsewhere | Detect OS and conditionally add — over-engineered for this use case |

---

## Implementation Plan

### Milestone 0 — Foundation
**Goal:** A working container image with pi installed and verified.  
**Done when:** `podman build -t pi-box .` succeeds and `podman run --rm pi-box:latest pi --version` prints a pi version string.

| ID | Task | Size | Depends on | Notes |
|----|------|------|------------|-------|
| T0.1 | Write `Containerfile`: base `node:lts-slim`, install system packages (`git`, `fd-find`, `ripgrep`, `curl`, `jq`, `make`, `python3`, `openssh-client`), install pi globally via `npm install -g @earendil-works/pi-coding-agent`, set `WORKDIR /workspace` | S | — | Add `--no-install-recommends` and `rm -rf /var/lib/apt/lists/*` to keep image lean; add `NO_UPDATE_NOTIFIER` env var |
| T0.2 | Build the image locally and verify pi starts: `podman build -t pi-box . && podman run --rm pi-box:latest pi --version` | S | T0.1 | Smoke-test only; confirms npm install and PATH are correct |

---

### Milestone 1 — Wrapper Script
**Goal:** `pi-box` script installed on `$PATH` that launches pi in the container with correct mounts, TTY, and argument forwarding.  
**Done when:** Running `pi-box` from a project directory opens the pi TUI inside the container; the project files are visible and editable; `~/.pi` config is loaded; running `pi-box --help` forwards the flag to pi correctly.

| ID | Task | Size | Depends on | Notes |
|----|------|------|------------|-------|
| T1.1 | Write `pi-box` script skeleton: shebang (`#!/bin/sh`), `set -e`, image name variable, basic `exec podman run --rm -it -v "$(pwd)":/workspace:z -w /workspace pi-box:latest pi "$@"` | S | T0.2 | `exec` replaces the shell process — no exit code handling needed |
| T1.2 | Add `~/.pi` mount: check if `$HOME/.pi` exists; if yes, append `-v "$HOME/.pi":/root/.pi:ro,z` to the run command; if no, print a warning to stderr and continue | S | T1.1 | Warning should not block launch |
| T1.3 | Add Podman presence check at script start: `command -v podman >/dev/null 2>&1 \|\| { echo "pi-box: podman not found. Install podman to use pi-box." >&2; exit 1; }` | S | T1.1 | Must run before any podman invocation |
| T1.4 | Make script executable and verify end-to-end: `chmod +x pi-box`, copy to `~/.local/bin/pi-box`, run from a test project directory | S | T1.2, T1.3 | Manual test: confirm TUI renders, files visible, `~/.pi` config active |

---

### Milestone 2 — Hardening & Documentation
**Goal:** Edge cases handled gracefully; README covers setup and daily use.  
**Done when:** All edge cases from the spec behave as specified; README allows a new user to go from zero to running `pi-box` in under 5 minutes.

| ID | Task | Size | Depends on | Notes |
|----|------|------|------------|-------|
| T2.1 | Write `README.md`: prerequisites (Podman), one-time build step, install instructions for macOS and Linux, daily usage, troubleshooting (SELinux, TTY issues, rebuilding the image) | M | T1.4 | Cover both `~/.local/bin` (Linux/macOS user install) and `/usr/local/bin` (system-wide) |
| T2.2 | Test edge cases manually per spec: (a) rename `podman` temporarily and confirm error message; (b) rename `~/.pi` and confirm warning + successful launch; (c) Ctrl-C inside pi-box and confirm clean exit | S | T1.4 | Document any findings; fix script if a case misbehaves |
| T2.3 | Verify cross-platform: run the full flow on Linux (or a Linux VM/container) — confirm script, mounts, and TUI all work identically | M | T2.1 | 🔍 Minor uncertainty: Podman machine vs native Podman on macOS may behave slightly differently with volume mounts |

---

## Testing Strategy

| Layer | Approach | Tooling |
|-------|----------|---------|
| Image build | `podman build` must succeed; `pi --version` must return output | Manual / can be scripted with `podman run --rm pi-box:latest pi --version` |
| Script logic | Manual invocation against a real project directory covering happy path and all edge cases from the spec | POSIX sh — no unit test framework warranted for a ~30-line script |
| Cross-platform | Run full flow on macOS (Podman machine) and Linux (native Podman) | Manual |
| TTY / TUI | Launch `pi-box` and confirm the TUI renders and responds to input | Manual — terminal rendering cannot be automated meaningfully |

---

## Open Decisions

| # | Decision | Options | Recommendation | Urgency |
|---|----------|---------|----------------|---------|
| 1 | `~/.pi` mount path inside container | `/root/.pi` (root user in container) vs `/home/node/.pi` (non-root `node` user in `node:lts-slim`) | `/root/.pi` — `node:lts-slim` defaults to root; simpler and consistent with rootless Podman UID mapping | Resolve before T1.2 |
| 2 | Whether to add `--sig-proxy=true` explicitly | Implicit (Podman default) vs explicit flag | Leave implicit — Podman enables signal proxying by default with `-it`; adding it is noise | Can defer indefinitely |

---

## Out of Scope

_(Carried forward from `REQUIREMENTS.md` Non-Goals.)_

- Replacing the existing `pi` command.
- Restricting network access inside the container.
- Managing or modifying pi configuration or credentials.
- Supporting container runtimes other than Podman.
- Auto-building the image on first run.
