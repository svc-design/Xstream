#!/bin/bash
set -e

GITHUB_REPO="your-username/your-repo-name"  # ← 修改为你的 GitHub 仓库路径
GITHUB_TOKEN="ghp_..."                      # ← 推荐使用环境变量传入

NOW=$(date +%s)
MAX_AGE=$((60 * 60 * 24))  # 1天

echo "🧹 Cleaning old daily-* tags and GitHub releases (keep recent 1-day)..."

for tag in $(git tag | grep '^daily-'); do
  TAG_TIME=$(git log -1 --format=%ct "$tag")
  AGE=$((NOW - TAG_TIME))

  if (( AGE > MAX_AGE )); then
    echo "🗑️ Deleting tag: $tag (age: $((AGE/3600))h)"

    # Delete local + remote git tag
    git tag -d "$tag" || true
    git push origin ":refs/tags/$tag" || true

    # Delete GitHub release (if exists)
    echo "🌐 Attempting to delete GitHub release for tag: $tag"
    RELEASE_ID=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
      https://api.github.com/repos/$GITHUB_REPO/releases/tags/$tag \
      | jq -r '.id')

    if [[ "$RELEASE_ID" != "null" ]]; then
      curl -s -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        https://api.github.com/repos/$GITHUB_REPO/releases/$RELEASE_ID \
        && echo "✅ GitHub release deleted: $tag"
    else
      echo "⚠️ No GitHub release found for: $tag"
    fi
  else
    echo "✅ Keeping recent tag: $tag"
  fi
done

echo "🎉 Cleanup done."
