# PROMOTE Operation

Trigger: `/wiki promote <tag>`, "promote tag", "scaffold a hub for X".

Goal: scaffold `wiki/domains/<tag>/_index.md` from a tag-cluster of leaves. The hub starts pre-populated and ready for human curation.

Use this when `/lint` reports a **promotion candidate** (a tag-cluster of ≥10 leaves with no domain hub) or when the user asks to scaffold a hub directly.

## Steps

1. **Resolve the tag.** Take the tag argument (e.g. `knowledge-management`). Strip a leading `#` if present. The slug for the hub directory is the tag verbatim (kebab-case).
2. **Collect cluster leaves.** Find all leaves under `wiki/concepts/`, `wiki/entities/`, `wiki/sources/`, `wiki/solutions/` whose `tags:` frontmatter contains the resolved tag. Use `obsidian search query=tag:<tag>` or grep equivalents.
3. **Bail if the cluster is too small.** If fewer than 5 leaves match, refuse and report: "Cluster has N leaves; below the hub threshold (5). Suggest growing the cluster first or running `/lint` for promotion candidates."
4. **Bail if the hub already exists.** If `wiki/domains/<tag>/_index.md` exists, refuse and report the existing hub. Do not overwrite.
5. **Create the hub** at `wiki/domains/<tag>/_index.md` via `obsidian create`. Frontmatter:
   ```yaml
   ---
   type: domain
   title: "<Title Case of tag>"
   owns_folder: false
   subdomain_of: ""
   page_count: <N>             # length of the related list below
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   tags: [domain, <tag>]
   status: developing
   confidence: EXTRACTED
   evidence: []
   related:
     - "[[<leaf-1>]]"
     - "[[<leaf-2>]]"
     - ...
   ---
   ```
6. **Body template.** Pre-populate stub sections grouped by leaf type so the curator can annotate later:
   ```markdown
   # <Title Case of tag>

   <one-paragraph stub: replace with hub description>

   ## Concepts
   - [[<concept-leaf-1>]] — <one-line description>
   - ...

   ## Entities
   - [[<entity-leaf-1>]] — <one-line description>
   - ...

   ## Sources
   - [[<source-leaf-1>]] — <one-line description>
   - ...

   ## Solutions
   - [[<solution-leaf-1>]] — <one-line description>
   - ...
   ```
   Empty sections (no leaves of that type) can be omitted. The one-line description should be the leaf's own description if its frontmatter has one, otherwise leave it as `<TODO: describe>` for the human curator.
7. **Update `wiki/index.md`.** Prepend an entry under the `## Domains` section.
8. **Update `wiki/hot.md`.** Add the new hub to the `## Recent Changes` list per the hot-cache protocol.
9. **Update `wiki/log.md`.** Prepend a `## [YYYY-MM-DD] promote | <tag>` entry noting the new hub and the cluster size.
10. **Confirm.** "Scaffolded [[domains/<tag>/_index]] with N pre-populated leaves. Open it in Obsidian to curate descriptions and section ordering."

## Idempotency

Safe to re-run via the existence guard at step 4. To regenerate, the user must delete or rename the existing hub first.

## Forward-only contract

This operation does not write any frontmatter on the leaves it links to. Hub membership lives in the hub's `related:` field; the leaf→hub direction is resolved via backlinks. See `${CLAUDE_PLUGIN_ROOT}/_shared/vault-structure.md` §Hub Membership.
