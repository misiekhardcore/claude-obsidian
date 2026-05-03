.PHONY: e2e e2e-build e2e-clean e2e-preflight

# AC12: preflight runs before docker build; fails fast (exit 2) if credentials
# are missing or malformed, before any image build or container work begins.
e2e-preflight:
	@command -v jq >/dev/null 2>&1 || { \
	  echo "Error: jq is required on the host but was not found on PATH"; \
	  exit 2; }
	@[ -f ~/.claude/.credentials.json ] || { \
	  echo "Error: ~/.claude/.credentials.json not found — run 'claude login' first"; \
	  exit 2; }
	@jq -e '.api_key | type == "string" and length > 0' ~/.claude/.credentials.json >/dev/null 2>&1 || { \
	  echo "Error: api_key missing, empty, or not a string in ~/.claude/.credentials.json"; \
	  exit 2; }

e2e-build:
	docker build -f tests/e2e/Dockerfile -t claude-obsidian-e2e:latest .

# Full local tier: preflight → build → run with credentials + working tree.
# On Linux hosts add --security-opt apparmor=unconfined if Obsidian crashes
# with SIGTRAP (see tests/e2e/README.md — AppArmor section).
#
# The API key is read by entrypoint-local.sh from the mounted credentials
# file rather than passed via -e ANTHROPIC_API_KEY=..., so the key never
# appears in `docker inspect` output or the host shell history.
e2e: e2e-preflight e2e-build
	docker run --rm \
	  -e ENTRYPOINT_TYPE=local \
	  -v "$(PWD):/opt/plugin-src:ro" \
	  -v "$$HOME/.claude/.credentials.json:/credentials.json:ro" \
	  claude-obsidian-e2e:latest

e2e-clean:
	docker image rm claude-obsidian-e2e:latest 2>/dev/null || true
