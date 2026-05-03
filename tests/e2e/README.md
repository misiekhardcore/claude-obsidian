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
| `register-vault.sh` | Writes `~/.config/obsidian/obsidian.json` with `cli: true` and the vault entry |
| `wait-for-obsidian.sh` | Compound readiness probe (`obsidian version && obsidian read path=wiki/hot.md`), 1s poll, 60s cap |

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
| `ENTRYPOINT_TYPE` | `ci` | Selects the entrypoint script (currently only `ci`) |
| `PLUGIN_SRC` | `/opt/plugin-src` | Where the plugin tree is mounted in the container |
| `VAULT_PATH` | `/tmp/vault` | Where the test vault is scaffolded |
| `DISPLAY_NUM` | `:99` | Xvfb display number |
| `WAIT_FOR_OBSIDIAN_TIMEOUT` | `60` | Readiness probe deadline (seconds) |

## Constraints

- Container is always run with `--rm`; no persistence between runs.
- Plugin tree is mounted **read-only** at `/opt/plugin-src`.
- No GitHub Secrets, no `ANTHROPIC_API_KEY`, no `claude` invocations in the CI tier.
- `bin/setup-vault.sh` and `tests/cli-smoke.sh` are reused as-is — never modified.

## Not yet implemented (deferred to #91)

- `entrypoint-local.sh` — local full tier with `claude -p` scripting
- `make e2e` / `make e2e-local` Makefile targets
- Inline assertions beyond `cli-smoke.sh`
- Credential preflight for the local tier

## Reference

- Umbrella spec: [#89](https://github.com/misiekhardcore/claude-obsidian/issues/89)
- This tier (CI fast): [#90](https://github.com/misiekhardcore/claude-obsidian/issues/90)
- Next tier (local full): [#91](https://github.com/misiekhardcore/claude-obsidian/issues/91)
