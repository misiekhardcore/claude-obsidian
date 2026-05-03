# claude-obsidian E2E harness image (CI fast tier — local full tier shares it).
#
# Cache-optimized layer order: base OS → Node + Claude Code → Obsidian →
# plugin discovery wiring → entrypoints. Rare changes go first so frequent
# entrypoint edits don't bust the upper layers.
#
# Pinning policy (AC15): no `latest` tags. Bump VERSION envs deliberately and
# rebuild the image to validate (push to trigger CI, or rebuild locally).
#
# AC2 — broken docs blow up the image build by design. The install steps
# below mirror the published prerequisites (Obsidian 1.12.7+ on $PATH; the
# `@anthropic-ai/claude-code` npm package on a Node 20 LTS host). If an
# upstream URL or package shape changes, the failing RUN surfaces it.

# ── Layer 1 — base OS + Electron / Xvfb runtime deps ─────────────────────────
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dbus-x11 \
        fontconfig \
        fonts-liberation \
        git \
        gnupg \
        jq \
        libasound2t64 \
        libatk-bridge2.0-0t64 \
        libatk1.0-0t64 \
        libcairo2 \
        libdbus-1-3 \
        libdrm2 \
        libfuse2t64 \
        libgbm1 \
        libgtk-3-0t64 \
        libnotify4 \
        libnss3 \
        libpango-1.0-0 \
        libsecret-1-0 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxrandr2 \
        libxshmfence1 \
        libxss1 \
        libxtst6 \
        xdg-utils \
        xvfb \
    && rm -rf /var/lib/apt/lists/*

# ── Layer 2 — Node 20 LTS + Claude Code CLI ──────────────────────────────────
ENV NODE_MAJOR=20 \
    CLAUDE_CODE_VERSION=2.1.126

RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/* \
 && npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
 && claude --version

# ── Layer 3 — Obsidian ───────────────────────────────────────────────────────
# AppImage extraction (vs. running the AppImage directly) sidesteps the FUSE
# mount that requires SYS_ADMIN inside containers. The 1.12.7 AppImage ships
# two binaries: `obsidian` (the Electron GUI) and `obsidian-cli` (the IPC
# client). Per skills/wiki/references/cli-setup.md, `obsidian` on $PATH refers
# to the CLI binary; the GUI is launched explicitly via AppRun.
ENV OBSIDIAN_VERSION=1.12.7

RUN curl -fsSL \
        "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/Obsidian-${OBSIDIAN_VERSION}.AppImage" \
        -o /tmp/Obsidian.AppImage \
 && chmod +x /tmp/Obsidian.AppImage \
 && cd /opt && /tmp/Obsidian.AppImage --appimage-extract \
 && mv /opt/squashfs-root /opt/Obsidian \
 && ln -s /opt/Obsidian/obsidian-cli /usr/local/bin/obsidian \
 && rm /tmp/Obsidian.AppImage

# ── Layer 4 — plugin discovery wiring ────────────────────────────────────────
# Claude Code resolves plugins by reading three files at startup:
#   1. ~/.claude/plugins/known_marketplaces.json    declared marketplaces
#   2. ~/.claude/plugins/installed_plugins.json     installed plugin records
#   3. ~/.claude/settings.json                      enable flags + plugin config
# A populated cache directory is necessary but not sufficient — without
# entries in (1) and (2), `claude` boots without the plugin and slash
# commands like `/wiki` come back as "Unknown command".
#
# At runtime the working tree is bind-mounted at /opt/plugin-src (read-only).
# Both the cache slot and the marketplace slot symlink to it, so the harness
# validates pre-release / uncommitted state instead of whatever the published
# marketplace has.
#
# Hooks are blanked in settings.json so PostToolUse auto-commit and
# SessionEnd reflection don't fire inside the container.
#
# PLUGIN_VERSION is the directory-name segment for the symlink target inside
# the plugin cache. Claude Code resolves plugins by name, not by this path
# component, so it does not need to track the published
# plugin.json/marketplace.json version. Using a synthetic value avoids drift
# when the plugin's real version is bumped.
ENV PLUGIN_NAME=claude-obsidian \
    MARKETPLACE_NAME=claude-obsidian \
    PLUGIN_VERSION=0.0.0-e2e \
    PLUGIN_SRC=/opt/plugin-src \
    VAULT_PATH=/tmp/vault

RUN mkdir -p "/root/.claude/plugins/cache/${MARKETPLACE_NAME}/${PLUGIN_NAME}" \
        "/root/.claude/plugins/marketplaces" \
 && ln -s "${PLUGIN_SRC}" \
        "/root/.claude/plugins/cache/${MARKETPLACE_NAME}/${PLUGIN_NAME}/${PLUGIN_VERSION}" \
 && ln -s "${PLUGIN_SRC}" \
        "/root/.claude/plugins/marketplaces/${MARKETPLACE_NAME}" \
 && printf '%s\n' '{' \
        '  "enabledPlugins": { "claude-obsidian@claude-obsidian": true },' \
        '  "pluginConfigs": {' \
        '    "claude-obsidian@claude-obsidian": {' \
        '      "options": { "vault_path": "/tmp/vault" }' \
        '    }' \
        '  },' \
        '  "hooks": {}' \
        '}' > /root/.claude/settings.json \
 && printf '%s\n' '{' \
        '  "claude-obsidian": {' \
        '    "source": { "source": "local", "repo": "claude-obsidian" },' \
        '    "installLocation": "/root/.claude/plugins/marketplaces/claude-obsidian",' \
        '    "lastUpdated": "2026-01-01T00:00:00Z"' \
        '  }' \
        '}' > /root/.claude/plugins/known_marketplaces.json \
 && printf '%s\n' '{' \
        '  "version": 2,' \
        '  "plugins": {' \
        '    "claude-obsidian@claude-obsidian": [' \
        '      {' \
        '        "scope": "user",' \
        "        \"installPath\": \"/root/.claude/plugins/cache/${MARKETPLACE_NAME}/${PLUGIN_NAME}/${PLUGIN_VERSION}\"," \
        "        \"version\": \"${PLUGIN_VERSION}\"," \
        '        "installedAt": "2026-01-01T00:00:00Z",' \
        '        "lastUpdated": "2026-01-01T00:00:00Z",' \
        '        "gitCommitSha": "e2e"' \
        '      }' \
        '    ]' \
        '  }' \
        '}' > /root/.claude/plugins/installed_plugins.json

# ── Layer 5 — entrypoints and helpers ────────────────────────────────────────
# Most-frequently-changed layer; bottom of the stack.
COPY tests/e2e/register-vault.sh \
     tests/e2e/wait-for-obsidian.sh \
     tests/e2e/entrypoint-ci.sh \
     tests/e2e/entrypoint-local.sh \
     tests/e2e/test-entrypoint.sh \
     /e2e/
COPY tests/e2e/assertions/ /e2e/assertions/
COPY tests/e2e/fixtures/ /e2e/fixtures/
RUN chmod +x /e2e/*.sh /e2e/assertions/*.sh

# Shell-form ENTRYPOINT so ${ENTRYPOINT_TYPE} expands at run time.
# ENTRYPOINT_TYPE=ci → CI fast tier (no auth, no claude calls)
# ENTRYPOINT_TYPE=local → local full tier (credentials + LLM exercises)
ENTRYPOINT bash /e2e/entrypoint-${ENTRYPOINT_TYPE:-ci}.sh
