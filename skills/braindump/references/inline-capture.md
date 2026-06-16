# Inline CAPTURE (Sequential)

For each chunk in order, re-enumerate `<vault_root>/notes/*.md` fresh (so chunk K can MATCH-append to a note written by chunk K-1). Then:

1. MATCH/NEW per `Skill("capture-pipeline")` §4 — skip `notes/index.md` and `status: deferred`; cap at 20 most recent.
2. MATCH or NEW path per `Skill("capture-pipeline")` §4; slug via `Skill("capture-pipeline")` §3.
3. Index patch per `Skill("capture-pipeline")` §6.
4. Record filename + success/failure. On error: append to failure list, continue — never abort the loop.
