# claude-obsidian E2E harness image (CI fast tier — local full tier shares it).
#
# Cache-optimized layer order: base OS → Node + Claude Code → Obsidian →
# plugin discovery wiring → entrypoints. Rare changes go first so frequent
# entrypoint edits don't bust the upper layers.
#
# Pinning policy (AC15): no `latest` tags. Bump VERSION envs deliberately and
# re-run `make e2e-build` (or push, and let CI rebuild) to validate.
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
# Symlink the cache to the mount point — at runtime the working tree is
# bind-mounted at /opt/plugin-src (read-only). This lets the harness validate
# pre-release / uncommitted state instead of whatever the marketplace has.
# Hooks are blanked so PostToolUse auto-commit and SessionEnd reflection
# don't fire inside the container.
ENV PLUGIN_NAME=claude-obsidian \
    MARKETPLACE_NAME=claude-obsidian \
    PLUGIN_VERSION=1.0.0 \
    PLUGIN_SRC=/opt/plugin-src \
    VAULT_PATH=/tmp/vault

RUN mkdir -p "/root/.claude/plugins/cache/${MARKETPLACE_NAME}/${PLUGIN_NAME}" \
 && ln -s "${PLUGIN_SRC}" \
        "/root/.claude/plugins/cache/${MARKETPLACE_NAME}/${PLUGIN_NAME}/${PLUGIN_VERSION}" \
 && printf '%s\n' '{' \
        '  "enabledPlugins": { "claude-obsidian@claude-obsidian": true },' \
        '  "pluginConfigs": {' \
        '    "claude-obsidian@claude-obsidian": {' \
        '      "options": { "vault_path": "/tmp/vault" }' \
        '    }' \
        '  },' \
        '  "hooks": {}' \
        '}' > /root/.claude/settings.json

# ── Layer 5 — entrypoints and helpers ────────────────────────────────────────
# Most-frequently-changed layer; bottom of the stack.
COPY tests/e2e/register-vault.sh \
     tests/e2e/wait-for-obsidian.sh \
     tests/e2e/entrypoint-ci.sh \
     /e2e/
RUN chmod +x /e2e/*.sh

# Shell-form ENTRYPOINT so ${ENTRYPOINT_TYPE} expands at run time. Defaults
# to `ci`; the local entrypoint is added in the follow-up issue.
ENTRYPOINT bash /e2e/entrypoint-${ENTRYPOINT_TYPE:-ci}.sh
