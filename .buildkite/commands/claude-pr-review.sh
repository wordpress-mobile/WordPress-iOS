#!/usr/bin/env bash
# Experimental CI check: Claude reviews the PR with full shell access to this
# VM. It can build, run tests and use simulators.
#
# Exit status: 0 = no proven bugs, 1 = Claude proved a bug caused by the PR,
# 2 = the review didn't complete (any other failure in this script).
#
# Claude runs with an allowlisted environment: the Anthropic key and the test
# site sign-in only. It has no GitHub token and no Buildkite agent token. This
# script fetches the PR's data for it and posts its result, always as a plain
# comment review, so it can't approve or request changes.
#
# Prompt: .buildkite/claude/pr-review-prompt.md, plus the CI notes in
# .buildkite/claude/pr-review-ci-context.md.

set -eEuo pipefail
# Any unexpected failure means the review didn't complete (exit 2, retried
# once). Exit 1 is reserved for a "fail" verdict.
trap 'echo "^^^ +++ Unexpected failure at line ${LINENO}: the review did not complete."; exit 2' ERR

CLAUDE_CODE_VERSION="2.1.310"
CLAUDE_MODEL="claude-opus-5-5"
# Pinned so a Claude Code update can't change it silently. It is also the current default.
CLAUDE_EFFORT="medium"
GH_VERSION="2.103.3"
GH_ARM64_SHA256="d700207eae9ae98fe2b89535c2c087c07823d4628c56364695a5a07ef311c062"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 18 Pro}"
INPUT_DIR="build/claude-review-input"
EVIDENCE_DIR="build/claude-review"
MARKER="<!-- claude-ci-review -->"
# Optional: publish screenshots to a public Spacefast Space so GitHub can show
# them. Needs SPACEFAST_TOKEN (a `ci_deploy` key), SPACEFAST_SPACE (slug),
# SPACEFAST_TEAM and SPACEFAST_BASE_URL (e.g. https://<slug>.space.fast).
# Without them, screenshots are linked to the Buildkite build instead.

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

# ── Gates ────────────────────────────────────────────────────────────
# Turns git@github.com:org/repo.git or https://github.com/org/repo.git into org/repo.
repo_slug() { sed -E 's#^(git@github\.com:|https://github\.com/)##; s#\.git$##' <<<"$1"; }
REPO_SLUG=$(repo_slug "$BUILDKITE_REPO")

# Claude can run any code, so never run it on code from a fork.
if [[ "$(repo_slug "${BUILDKITE_PULL_REQUEST_REPO:-}")" != "$REPO_SLUG" ]]; then
  echo "PR comes from a fork (${BUILDKITE_PULL_REQUEST_REPO:-unknown}). Skipping."
  exit 0
fi

for var in ANTHROPIC_API_KEY GITHUB_TOKEN; do
  if [[ -z "${!var:-}" ]]; then
    echo "^^^ +++ ${var} is not set, so the review can't run."
    exit 2
  fi
done

PR_NUMBER="$BUILDKITE_PULL_REQUEST"
BASE_BRANCH="$BUILDKITE_PULL_REQUEST_BASE_BRANCH"
HEAD_SHA="$BUILDKITE_COMMIT"
OWNER="${REPO_SLUG%/*}"
NAME="${REPO_SLUG#*/}"

# ── Tools ────────────────────────────────────────────────────────────
echo "--- :claude: Installing Claude Code ${CLAUDE_CODE_VERSION}"
curl -fsSL https://claude.ai/install.sh | bash -s "$CLAUDE_CODE_VERSION"
export PATH="$HOME/.local/bin:$PATH"
claude --version

if ! command -v gh >/dev/null; then
  echo "--- :github: Installing gh ${GH_VERSION}"
  gh_dir="$(mktemp -d)"
  curl -fsSL -o "$gh_dir/gh.zip" "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_macOS_arm64.zip"
  echo "${GH_ARM64_SHA256}  ${gh_dir}/gh.zip" | shasum -a 256 -c -
  unzip -q -o "$gh_dir/gh.zip" -d "$gh_dir"
  cp "$gh_dir/gh_${GH_VERSION}_macOS_arm64/bin/gh" "$HOME/.local/bin/gh"
fi
export GH_TOKEN="$GITHUB_TOKEN"
# The account the script posts as. Only threads it started count as Claude's.
BOT_LOGIN=$(gh api user --jq .login)

# ── Project setup, so Claude can build and test ──────────────────────
# a8c-secrets is deliberately not installed: builds fall back to the example
# credentials, so the app's secrets are never decrypted on this VM.
.buildkite/commands/shared-set-up.sh

echo "--- :git: Fetching ${BASE_BRANCH}"
git fetch --quiet origin "${BASE_BRANCH}:refs/remotes/origin/${BASE_BRANCH}"

echo "--- :iphone: Booting ${SIMULATOR_NAME}"
SIMULATOR_UDID="$(ruby Scripts/ci/find-booted-simulator.rb "$SIMULATOR_NAME" 2>/dev/null || true)"
if [[ -z "$SIMULATOR_UDID" ]]; then
  xcrun simctl boot "$SIMULATOR_NAME" 2>/dev/null || true
  SIMULATOR_UDID="$(ruby Scripts/ci/find-booted-simulator.rb "$SIMULATOR_NAME" 30 1)"
fi
echo "Simulator UDID: ${SIMULATOR_UDID}"

echo "--- :xcode: Enabling Xcode MCP"
# Headless Xcode asks before an agent or folder may use it. Nobody can answer
# on CI, so allow every agent: this VM is thrown away after the job, and Claude
# already has full shell access. Claude falls back to plain xcodebuild and
# simctl if this fails (e.g. no passwordless sudo).
XCODE_MCP=no
# The folder grant covers this checkout and everything below it, in case
# folder approval is still asked for with all agents allowed.
if sudo -n xcrun mcp-server enable --unsafe-always-allow-all-agents \
  && sudo -n xcrun mcp-server allow-folder "$PWD" --always; then
  XCODE_MCP=yes
  xcrun mcp-server status || true
else
  echo "Could not enable Xcode MCP; continuing without it."
fi

echo "--- :lock: Removing sudo before Claude runs"
# Claude must not have root: it could read the secrets this job was started
# with. sudo uses the last matching rule, and sudoers.d is read after the main
# file, so this rule overrides any earlier grant for this user. The VM is thrown
# away after the job, so nothing has to restore it.
no_sudo_rule="$(mktemp)"
printf '%s ALL=(ALL) !ALL\n' "$(id -un)" > "$no_sudo_rule"
/usr/sbin/visudo -c -q -f "$no_sudo_rule"
sudo -n install -m 0440 -o root -g wheel "$no_sudo_rule" /etc/sudoers.d/zz-no-sudo-for-claude
if sudo -n true 2>/dev/null; then
  echo "^^^ +++ sudo still works, so Claude will not run."
  exit 2
fi
echo "sudo is now refused for $(id -un)."

# ── PR data for Claude ───────────────────────────────────────────────
echo "--- :github: Fetching PR #${PR_NUMBER}"
mkdir -p "$INPUT_DIR" "$EVIDENCE_DIR"
gh pr view "$PR_NUMBER" --repo "$REPO_SLUG" \
  --json number,title,body,author,baseRefName,headRefName,headRefOid,labels > "$INPUT_DIR/pr.json"
gh pr diff "$PR_NUMBER" --repo "$REPO_SLUG" > "$INPUT_DIR/pr.diff"
gh api graphql -F owner="$OWNER" -F name="$NAME" -F number="$PR_NUMBER" -f query='
  query($owner: String!, $name: String!, $number: Int!) {
    repository(owner: $owner, name: $name) {
      pullRequest(number: $number) {
        reviewThreads(first: 100) {
          nodes {
            id isResolved isOutdated path line
            comments(first: 50) { nodes { author { login } body createdAt } }
          }
        }
      }
    }
  }' --jq '.data.repository.pullRequest.reviewThreads.nodes' > "$INPUT_DIR/review-threads.json"
gh api "repos/${REPO_SLUG}/issues/${PR_NUMBER}/comments" --paginate \
  --jq '[.[] | {author: .user.login, body, created_at}]' > "$INPUT_DIR/comments.json"

# ── Prompt ───────────────────────────────────────────────────────────
if [[ -n "${SIMULATOR_LLM_PILOT_SITE_URL:-}" ]]; then
  SITE_SIGN_IN='A self-hosted test site is available: its address, username and application password are in the `SIMULATOR_LLM_PILOT_SITE_URL`, `SIMULATOR_LLM_PILOT_USERNAME` and `SIMULATOR_LLM_PILOT_APP_PASSWORD` environment variables. There is no WordPress.com account, so say in the summary when a flow needs one and you could not check it.'
else
  SITE_SIGN_IN='No test site credentials are available in this job, so you cannot sign in. Say so in the summary if it stopped you from checking something.'
fi

if [[ "$XCODE_MCP" == yes ]]; then
  XCODE_TOOLS='The Xcode MCP tools are available (`mcp__xcode__*`), including `DeviceInteraction*` to tap, type and take screenshots in a simulator. Prefer them over WebDriverAgent. Open `WordPress.xcworkspace` with `XcodeOpenWorkspace` first.'
else
  XCODE_TOOLS='The Xcode MCP tools are not available in this job. Drive the app with launch arguments, deep links (`xcrun simctl openurl`), a temporary XCUITest, or WebDriverAgent (`SIMULATOR_UDID=... .buildkite/commands/build-wda.sh` builds it).'
fi

PROMPT_FILE="$(mktemp)"
{
  cat .buildkite/claude/pr-review-prompt.md
  echo
  cat .buildkite/claude/pr-review-ci-context.md
} | REPO="$REPO_SLUG" PR_NUMBER="$PR_NUMBER" HEAD_SHA="$HEAD_SHA" BASE_BRANCH="$BASE_BRANCH" \
    INPUT_DIR="$INPUT_DIR" EVIDENCE_DIR="$EVIDENCE_DIR" SITE_SIGN_IN="$SITE_SIGN_IN" XCODE_TOOLS="$XCODE_TOOLS" BOT_LOGIN="$BOT_LOGIN" \
    SIMULATOR_NAME="$SIMULATOR_NAME" SIMULATOR_UDID="$SIMULATOR_UDID" \
    ruby -e 'print STDIN.read.gsub(/\{\{([A-Z_]+)\}\}/) { ENV.fetch($1) }' > "$PROMPT_FILE"

# ── Review ───────────────────────────────────────────────────────────
# Only these variables reach Claude. Everything else in the job environment
# (GitHub token, Buildkite agent token, SSH agent, other CI secrets) stays out.
claude_env=(
  "HOME=$HOME" "PATH=$PATH" "USER=${USER:-$(id -un)}" "LOGNAME=${LOGNAME:-$(id -un)}"
  "TMPDIR=${TMPDIR:-/tmp}" "LANG=en_US.UTF-8" "CI=true" "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY"
)
for var in DEVELOPER_DIR SIMULATOR_LLM_PILOT_SITE_URL SIMULATOR_LLM_PILOT_USERNAME SIMULATOR_LLM_PILOT_APP_PASSWORD; do
  if [[ -n "${!var:-}" ]]; then claude_env+=("$var=${!var}"); fi
done

echo "--- :claude: Reviewing PR #${PR_NUMBER}"
env -i "${claude_env[@]}" claude -p "$(cat "$PROMPT_FILE")" \
  --model "$CLAUDE_MODEL" --effort "$CLAUDE_EFFORT" \
  --dangerously-skip-permissions \
  --strict-mcp-config --mcp-config '{"mcpServers": {"xcode": {"type": "stdio", "command": "xcrun", "args": ["mcpbridge"]}}}' \
  --json-schema "$(jq -c . .buildkite/claude/pr-review-schema.json)" \
  --output-format stream-json --verbose \
  < /dev/null > "${EVIDENCE_DIR}/transcript.jsonl" || true

RESULT=$(jq -c 'select(.type == "result")' "${EVIDENCE_DIR}/transcript.jsonl" 2>/dev/null | tail -n 1)
RESULT=${RESULT:-'{}'}
jq -r '"Cost: $\(.total_cost_usd)  Turns: \(.num_turns)  Duration: \((.duration_ms // 0) / 1000 | floor)s"' <<<"$RESULT" || true
REVIEW=$(jq -c '.structured_output // empty' <<<"$RESULT")
if [[ -z "$REVIEW" ]] || ! jq -e '.verdict == "pass" or .verdict == "fail"' <<<"$REVIEW" >/dev/null; then
  echo "^^^ +++ Claude's review did not complete, so there is no verdict."
  exit 2
fi
echo "$REVIEW" > "${EVIDENCE_DIR}/result.json"
VERDICT=$(jq -r .verdict <<<"$REVIEW")

# ── Report ───────────────────────────────────────────────────────────
echo "--- :buildkite: Annotating the build"
# Reporting is best-effort: a failure here must not change the verdict.
jq -r '.summary' <<<"$REVIEW" | buildkite-agent annotate \
  --style "$([[ "$VERDICT" == pass ]] && echo success || echo error)" --context claude-pr-review \
  || echo "Warning: could not annotate the build."

ANNOTATION_URL="${BUILDKITE_BUILD_URL}#annotation-claude-pr-review"

# Screenshots and videos for GitHub. Best-effort: on any failure, IMAGE_BASE
# stays empty and the comments link to the Buildkite build instead. This runs
# in the script, not in Claude's session, so Claude never sees the token.
IMAGE_BASE=""
media=()
while IFS= read -r -d '' file; do media+=("$file"); done < <(
  find "$EVIDENCE_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.mp4' \) -print0)
if [[ ${#media[@]} -gt 0 && -n "${SPACEFAST_TOKEN:-}" && -n "${SPACEFAST_SPACE:-}" && -n "${SPACEFAST_TEAM:-}" && -n "${SPACEFAST_BASE_URL:-}" ]]; then
  echo "--- :frame_with_picture: Publishing ${#media[@]} screenshot(s) to Spacefast"
  media_path="wordpress-ios/pr-${PR_NUMBER}/build-${BUILDKITE_BUILD_NUMBER}"
  stage="$(mktemp -d)"
  mkdir -p "$stage/$media_path"
  cp "${media[@]}" "$stage/$media_path/"
  published=no
  if command -v sf >/dev/null || curl -fsSL https://spacefast.com/install.sh | sh -s -- --method binary; then
    # Additive, so other PRs' files in the Space are kept.
    if (cd "$stage" && sf publish . --publish-mode additive --space "$SPACEFAST_SPACE" --team "$SPACEFAST_TEAM" \
          --token "$SPACEFAST_TOKEN" --json --wait > /dev/null); then
      published=yes
      for file in "${media[@]}"; do
        url="${SPACEFAST_BASE_URL%/}/${media_path}/$(basename "$file")"
        if [[ "$(curl -s -o /dev/null -w '%{http_code}' "$url")" != 200 ]]; then
          echo "Not reachable: ${url}"
          published=no
        fi
      done
    fi
  fi
  if [[ "$published" == yes ]]; then
    IMAGE_BASE="${SPACEFAST_BASE_URL%/}/${media_path}"
    echo "Published to ${IMAGE_BASE}/"
  else
    echo "Warning: could not publish screenshots; linking to the Buildkite build instead."
  fi
fi

# Turns <img src="artifact://build/claude-review/x.png"> into a Spacefast image,
# or into a link to the Buildkite build when nothing was published.
JQ_MEDIA='
  def media: gsub("<img(?<pre>[^>]*)src=\"artifact://(?<p>[^\"]+)\"(?<post>[^>]*)>";
    if $imgbase == "" then "[`\(.p | split("/") | last)`](\($url))"
    else "<img\(.pre)src=\"\($imgbase)/\(.p | split("/") | last)\"\(.post)>" end);
'

echo "--- :github: Posting to PR #${PR_NUMBER}"
post_failed=0

# New findings: one review, always event COMMENT.
if jq -e '.findings | length > 0' <<<"$REVIEW" >/dev/null; then
  review_payload() {  # $1 = include inline comments (true/false)
    jq --arg marker "$MARKER" --arg sha "$HEAD_SHA" --arg url "$ANNOTATION_URL" --arg imgbase "$IMAGE_BASE" --argjson inline "$1" "$JQ_MEDIA"'
      def tag: if .proven then "**Proven**" else "**Unproven**" end;
      def text: "\(tag): \(.title)\n\n\(.body | media)";
      {
        commit_id: $sha,
        event: "COMMENT",
        body: ("\($marker)\n🤖 **Claude CI review** – verdict: **\(.verdict)**. The full result is in the Claude CI review comment below; evidence is on the [Buildkite build](\($url)).\n\n"
          + (if $inline then "" else (.findings | map("### `\(.path):\(.line)`\n\n" + text) | join("\n\n")) end)),
        comments: (if $inline then .findings | map({path, line, side: "RIGHT", body: ("\($marker)\n" + text)}) else [] end)
      }' <<<"$REVIEW"
  }
  if ! review_payload true | gh api --method POST "repos/${REPO_SLUG}/pulls/${PR_NUMBER}/reviews" --input - >/dev/null; then
    # Usually a line that isn't in the diff. Fall back to listing the findings in the review body.
    echo "Inline review failed; posting the findings in the review body instead."
    review_payload false | gh api --method POST "repos/${REPO_SLUG}/pulls/${PR_NUMBER}/reviews" --input - >/dev/null || post_failed=1
  fi
fi

# Replies to Claude's earlier threads. Only threads that are Claude's own may be touched.
own_threads=$(jq -c --arg marker "$MARKER" --arg bot "$BOT_LOGIN" '
  [.[] | select(.comments.nodes[0] | (.author.login == $bot) and (.body | contains($marker))) | .id]' "$INPUT_DIR/review-threads.json")
while IFS= read -r reply; do
  thread_id=$(jq -r .thread_id <<<"$reply")
  if ! jq -e --arg id "$thread_id" 'index($id) != null' <<<"$own_threads" >/dev/null; then
    echo "Skipping a reply to thread ${thread_id}: it isn't one of Claude's threads."
    continue
  fi
  body="${MARKER}
$(jq -r .body <<<"$reply")"
  gh api graphql -F thread="$thread_id" -f body="$body" -f query='
    mutation($thread: ID!, $body: String!) {
      addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $thread, body: $body}) { comment { id } }
    }' >/dev/null || post_failed=1
  if jq -e '.resolved' <<<"$reply" >/dev/null; then
    gh api graphql -F thread="$thread_id" -f query='
      mutation($thread: ID!) { resolveReviewThread(input: {threadId: $thread}) { thread { id } } }' >/dev/null || post_failed=1
  fi
done < <(jq -c '.thread_replies[]' <<<"$REVIEW")

# The full result as one PR comment, updated in place on every run. Comments
# over GitHub's 65,536-character limit are cut short.
SUMMARY_MARKER="<!-- claude-ci-review-summary -->"
summary_body=$(jq -r --arg marker "$SUMMARY_MARKER" --arg url "$ANNOTATION_URL" --arg sha "$HEAD_SHA" --arg imgbase "$IMAGE_BASE" "$JQ_MEDIA"'
  def tag: if .proven then "**Proven**" else "**Unproven**" end;
  "\($marker)\n## 🤖 Claude CI review: \(if .verdict == "fail" then "❌ fail" else "✅ pass" end)\n\n"
  + "Commit `\($sha[0:10])`. Test output and the transcript are on the [Buildkite build](\($url)).\n\n"
  + (.summary | media) + "\n"
  + (if (.findings | length) > 0 then
       "\n## New findings\n\n" + (.findings | map("### \(tag): \(.title)\n\n`\(.path):\(.line)`\n\n\(.body | media)") | join("\n\n")) + "\n"
     else "" end)
  + (if (.thread_replies | length) > 0 then
       "\n## Earlier findings\n\n" + (.thread_replies | map("- \(if .resolved then "✅ Resolved" else "❌ Not resolved" end): \(.body | media | gsub("\n"; " "))") | join("\n")) + "\n"
     else "" end)
  | if length > 65000 then .[0:65000] + "\n\n…cut short. The full result is on the Buildkite build." else . end
' <<<"$REVIEW")
existing_summary=$(gh api "repos/${REPO_SLUG}/issues/${PR_NUMBER}/comments" --paginate \
  --jq ".[] | select(.user.login == \"${BOT_LOGIN}\" and (.body | startswith(\"${SUMMARY_MARKER}\"))) | .id" 2>/dev/null | head -n 1) || true
if [[ -n "$existing_summary" ]]; then
  gh api --method PATCH "repos/${REPO_SLUG}/issues/comments/${existing_summary}" -f body="$summary_body" >/dev/null || post_failed=1
else
  gh api --method POST "repos/${REPO_SLUG}/issues/${PR_NUMBER}/comments" -f body="$summary_body" >/dev/null || post_failed=1
fi

if [[ "$post_failed" == 1 ]]; then
  echo "Warning: some comments could not be posted to GitHub. The verdict is unaffected."
fi

# ── Verdict ──────────────────────────────────────────────────────────
if [[ "$VERDICT" == "fail" ]]; then
  echo "^^^ +++ Claude proved a bug caused by this PR. See the annotation."
  exit 1
fi
echo "Claude found no proven bugs."
