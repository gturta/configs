# pi-box

Run the [pi coding agent](https://github.com/earendil-works/pi) inside a sandboxed Podman container. Only two paths on your host are visible inside the container:

| Mount | Inside container | Access |
|-------|-----------------|--------|
| Current project directory | `/workspace` | Read-write |
| `~/.pi/` (pi config, credentials, skills) | `/root/.pi` | Read-write |

Everything else on your filesystem is inaccessible to pi.

---

## Prerequisites

- [Podman](https://podman.io/) installed and running
  - macOS: `brew install podman && podman machine init && podman machine start`
  - Linux: see [podman.io/docs/installation](https://podman.io/docs/installation)

---

## One-time setup

### 1. Build the container image

From this directory:

```sh
podman build -t pi-box .
```

Verify it worked:

```sh
podman run --rm pi-box:latest pi --version
```

### 2. Install the wrapper script

**User install (recommended):**

```sh
mkdir -p ~/.local/bin
cp pi-box ~/.local/bin/pi-box
chmod +x ~/.local/bin/pi-box
```

Make sure `~/.local/bin` is on your `$PATH`. Add this to your `~/.zshrc` or `~/.bashrc` if needed:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

**System-wide install:**

```sh
sudo cp pi-box /usr/local/bin/pi-box
sudo chmod +x /usr/local/bin/pi-box
```

---

## Daily usage

```sh
cd ~/projects/my-app
pi-box
```

That's it. `pi-box` accepts all the same arguments as `pi`:

```sh
pi-box chat
pi-box --help
```

---

## Updating pi

The pi version is baked into the image. To update:

```sh
podman build --no-cache -t pi-box .
```

---

## Troubleshooting

### Podman machine not running (macOS)

```
Cannot connect to Podman. Please verify your connection...
```

Start the Podman machine:

```sh
podman machine start
```

### TTY warning when running non-interactively

```
The input device is not a TTY. The --tty and --interactive flags might not work properly
```

This is expected when `pi-box` is invoked from a non-interactive context (e.g. a script or CI). It is harmless in normal terminal use.

### SELinux volume mount errors (Linux)

The `:z` label on volume mounts handles SELinux relabelling automatically. If you see permission errors on a SELinux-enforcing system, check that Podman is up to date:

```sh
podman --version   # should be 4.x or newer
```

### `~/.pi` not found warning

```
pi-box: warning: '/home/you/.pi' not found — pi config and credentials will not be available.
```

Pi will start but won't have access to your credentials or custom config. Run `pi` (outside the container) at least once to initialise `~/.pi`, then retry.

### Rebuilding after a failed build

```sh
podman rmi pi-box:latest
podman build -t pi-box .
```
