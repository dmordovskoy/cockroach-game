#!/usr/bin/env bash
# Resolve all unresolved review threads on a PR: ./tools/resolve_threads.sh <PR-number>
# Run this yourself after fixes are verified — the architect agent is blocked from
# raw API calls and cannot do it.
set -euo pipefail

if [ $# -ne 1 ]; then
	echo "Usage: ./tools/resolve_threads.sh <PR-number>"
	exit 1
fi

REPO_OWNER="dmordovskoy"
REPO_NAME="cockroach-game"

ids=$(gh api graphql -f query="{repository(owner:\"$REPO_OWNER\",name:\"$REPO_NAME\"){pullRequest(number:$1){reviewThreads(first:50){nodes{id isResolved}}}}}" \
	--jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved|not) | .id')

if [ -z "$ids" ]; then
	echo "No unresolved threads on PR #$1."
	exit 0
fi

for id in $ids; do
	result=$(gh api graphql -f query="mutation{resolveReviewThread(input:{threadId:\"$id\"}){thread{isResolved}}}" \
		--jq '.data.resolveReviewThread.thread.isResolved')
	echo "Resolved $id: $result"
done
