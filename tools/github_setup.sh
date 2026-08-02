#!/usr/bin/env bash
# One-time GitHub repo configuration. Requires `gh auth login` with admin rights.
set -euo pipefail

REPO="dmordovskoy/cockroach-game"

echo "Merge policy: squash only, delete branches after merge"
gh api -X PATCH "repos/$REPO" \
	-F allow_squash_merge=true \
	-F allow_merge_commit=false \
	-F allow_rebase_merge=false \
	-F delete_branch_on_merge=true >/dev/null

echo "Branch protection on main"
# NOTE: after the first PR runs, find the Codex review check's exact name on the
# PR's Checks tab and add it to "contexts" below, then re-run this script.
gh api -X PUT "repos/$REPO/branches/main/protection" --input - <<'JSON' >/dev/null
{
	"required_status_checks": { "strict": true, "contexts": ["Lint", "Tests"] },
	"enforce_admins": false,
	"required_pull_request_reviews": null,
	"restrictions": null,
	"required_conversation_resolution": true,
	"allow_force_pushes": false,
	"allow_deletions": false
}
JSON

echo "Done."
