# E2E harness

Docker-based end-to-end harness that builds an Ubuntu image, boots Obsidian
under Xvfb, and runs `tests/cli-smoke.sh` against a freshly scaffolded vault.

The same image is used by the GitHub Actions workflow (`.github/workflows/e2e.yml`)
and for local debugging.

## Layout

| File | Purpose |
|---|---|
| `Dockerfile` | 5-layer image: Ubuntu 24.04 → Node + Claude Code → Obsidian AppImage → plugin wiring → entrypoints |
| `entrypoint-ci.sh` | CI fast-tier sequence: scaffold vault → register → boot Xvfb/D-Bus/Obsidian → probe → run `cli-smoke.sh` |
| `entrypoint-local.sh` | Local full-tier sequence: credentials → vault init → boot → `/wiki init` → ingest → `/daily ×3` → `/daily-close` → assertions |
| `test-entrypoint.sh` | Shared bash helpers sourced by assertion scripts: `pass`/`fail` counters, `assert_exit`, `assert_contains`, `assert_file_exists` |
| `register-vault.sh` | Writes `~/.config/obsidian/obsidian.json` with `cli: true` and the vault entry |
| `wait-for-obsidian.sh` | Compound readiness probe (`obsidian version && obsidian read path=wiki/hot.md`), 1s poll, 60s cap |
| `assertions/vault-shape.sh` | Assert vault dirs + key files exist after `/wiki init` (AC4) |
| `assertions/frontmatter.sh` | Assert YAML frontmatter has `name`/`description` keys after ingest (AC5) |
| `assertions/daily-shape.sh` | Assert daily file has `## Captures` + ≥3 bullets after `/daily ×3` (AC6) |
| `assertions/section-header.sh` | Assert named section header exists + has ≥1 non-blank body line (AC7) |
| `fixtures/sample.md` | Minimal markdown source for the ingest test (~200 bytes, valid frontmatter) |

## Pinned versions

Bump in the Dockerfile and rebuild — no `latest` tags.

| Component | Version | Source |
|---|---|---|
| Base OS | `ubuntu:24.04` | `FROM` line |
| Node | 20 LTS (latest patch) | `NODE_MAJOR=20` |
| `@anthropic-ai/claude-code` | 2.1.126 | `CLAUDE_CODE_VERSION` |
| Obsidian | 1.12.7 | `OBSIDIAN_VERSION` |

## Build

From the repository root:

```bash
docker build -f tests/e2e/Dockerfile -t claude-obsidian-e2e:local .
```

Cold build: ~2–3 min. Warm rebuild (entrypoint changes only): <1s.

## Run the CI fast tier

```bash
docker run --rm \
  -e ENTRYPOINT_TYPE=ci \
  -v "$(pwd):/opt/plugin-src:ro" \
  claude-obsidian-e2e:local
```

Expected output (tail):

```
entrypoint-ci: scaffolding vault at /tmp/vault
register-vault: registered /tmp/vault (id=...)
entrypoint-ci: starting Xvfb on :99
entrypoint-ci: starting D-Bus session
entrypoint-ci: launching Obsidian GUI
wait-for-obsidian: ready after 1s
entrypoint-ci: running tests/cli-smoke.sh
... 21 assertions ...
entrypoint-ci: cli-smoke.sh exited with 0
```

Total wall-clock: ~5–10 s after the image is built. Exit code 0 = green.

## Run the local full tier (`make e2e`)

Requires `~/.claude/.credentials.json` with an `api_key` field.

```bash
make e2e
```

Or with explicit AppArmor bypass for native Linux Docker hosts (see below):

```bash
make e2e-preflight && make e2e-build
docker run --rm \
  --security-opt apparmor=unconfined \
  -e ENTRYPOINT_TYPE=local \
  -e ANTHROPIC_API_KEY="$(jq -r '.api_key' ~/.claude/.credentials.json)" \
  -v "$(pwd):/opt/plugin-src:ro" \
  -v "$HOME/.claude/.credentials.json:/credentials.json:ro" \
  claude-obsidian-e2e:latest
```

`make e2e-preflight` fails fast (exit 2) before any build if credentials are
missing or missing an `api_key` field (AC12).

Expected exit 0 sequence:

1. Credentials validated
2. Vault scaffolded at `/tmp/vault`
3. Obsidian booted, CLI ready
4. `/wiki init` — vault-shape assertion (AC4)
5. `ingest .raw/sample.md` — frontmatter + index-mutated assertions (AC5)
6. `/daily` ×3 — daily-shape assertion (AC6)
7. `/daily-close` — section-header assertion (AC7)

Wall-clock target ≤5 min from `make e2e` with a cached image (AC18).

## Debug a failing run

Drop into the container before the entrypoint runs:

```bash
docker run --rm -it \
  -e ENTRYPOINT_TYPE=ci \
  -v "$(pwd):/opt/plugin-src:ro" \
  --entrypoint /bin/bash \
  claude-obsidian-e2e:local
```

Inside the container:

```bash
bash /e2e/entrypoint-ci.sh    # run the full sequence
cat /tmp/obsidian.log         # Obsidian / Electron stderr
cat /tmp/xvfb.log             # Xvfb stderr
obsidian version              # test the CLI directly
obsidian read path=wiki/hot.md
```

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `ENTRYPOINT_TYPE` | `ci` | Selects the entrypoint script: `ci` or `local` |
| `PLUGIN_SRC` | `/opt/plugin-src` | Where the plugin tree is mounted in the container |
| `VAULT_PATH` | `/tmp/vault` | Where the test vault is scaffolded |
| `DISPLAY_NUM` | `:99` | Xvfb display number |
| `WAIT_FOR_OBSIDIAN_TIMEOUT` | `60` | Readiness probe deadline (seconds) |
| `ANTHROPIC_API_KEY` | — | API key for `claude -p` calls (local tier only) |
| `CREDENTIALS` | `/credentials.json` | Path to credentials inside container (local tier) |

## Constraints

- Container is always run with `--rm`; no persistence between runs.
- Plugin tree is mounted **read-only** at `/opt/plugin-src`.
- No GitHub Secrets, no `ANTHROPIC_API_KEY`, no `claude` invocations in the CI tier.
- `bin/setup-vault.sh` and `tests/cli-smoke.sh` are reused as-is — never modified.
- All assertions are shape-only — no content-match assertions exist anywhere in the harness (AC16).

## AppArmor on Linux hosts

CI passes `--security-opt apparmor=unconfined` to `docker run`. GitHub's
`ubuntu-24.04` runners (and any native Linux Docker on Ubuntu 24.04+) apply
the `docker-default` AppArmor profile, which blocks the user-namespace
syscalls Chromium uses during Electron init even with `--no-sandbox`.
Without the flag, Obsidian crashes with `SIGTRAP` mid-boot. Docker Desktop
(macOS / Windows / WSL) runs containers in a linuxkit VM with no host
AppArmor and is unaffected, so locally the flag is optional. Add it when
reproducing a CI failure on a native Linux Docker host.

## Reference

- Umbrella spec: [#89](https://github.com/misiekhardcore/claude-obsidian/issues/89)
- CI fast tier: [#90](https://github.com/misiekhardcore/claude-obsidian/issues/90)
- Local full tier: [#91](https://github.com/misiekhardcore/claude-obsidian/issues/91)
