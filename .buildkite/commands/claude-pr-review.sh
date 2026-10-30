#!/usr/bin/env bash
# Experimental CI check: Claude reviews the PR with full shell access to this
# VM. It can build, run tests and use simulators.
#
# Exit status: 0 = no proven bugs, 1 = Claude proved a bug caused by the PR,
# 2 = the review didn't complete (any other failure in this script).
#
# Claude runs as a separate, non-admin macOS user that only gets the Anthropic
# key. It has no GitHub token and can't reach the
# build user's secrets. This script fetches the PR's data for it and posts its
# result, always as a plain comment review, so it can't approve or request
# changes. Claude's part runs in claude-pr-review-as-reviewer.sh.
#
# Prompt: .buildkite/claude/pr-review-prompt.md, plus the CI notes in
# .buildkite/claude/pr-review-ci-context.md.

set -eEuo pipefail
# Any unexpected failure means the review didn't complete (exit 2, retried
# once). Exit 1 is reserved for a "fail" verdict.
trap 'echo "^^^ +++ Unexpected failure at line ${LINENO}: the review did not complete."; exit 2' ERR

CLAUDE_CODE_VERSION="2.1.310"
# darwin-arm64 binary, from https://downloads.claude.ai/claude-code-releases/<version>/manifest.json
CLAUDE_CODE_SHA256="ffb64331bc0ee1b69efb7c2c428bd3ab516bc31b75bf60886b356c97c1c25ffd"
CLAUDE_MODEL="claude-opus-5-5"
# Pinned so a Claude Code update can't change it silently. It is also the current default.
CLAUDE_EFFORT="medium"
GH_VERSION="2.103.3"
GH_ARM64_SHA256="d700207eae9ae98fe2b89535c2c087c07823d4628c56364695a5a07ef311c062"
SF_VERSION="0.4.0"
# spacefast-darwin-arm64.gz, from the release's latest.json
SF_ARM64_SHA256="f9d3e396de0919450792917c6c91e97048aafce5b35dbeeb4166a1426689e1c7"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 18 Pro}"
INPUT_DIR="build/claude-review-input"
EVIDENCE_DIR="build/claude-review"
# Written only by this script (the build user), so the reviewer can't change it.
AUDIT_DIR="build/claude-audit"
# Claude writes its transcript here. It is append-only (see below).
TRANSCRIPT_FILE="/Users/Shared/claude-review-audit/transcript.jsonl"
MARKER="<!-- claude-ci-review -->"
# Screenshots are published to this public Spacefast Space so GitHub can show
# them. Needs SPACEFAST_TOKEN (a `ci_deploy` key) from the pipeline's secrets;
# without it, screenshots are linked to the Buildkite build instead.
SPACEFAST_SPACE="jkmassel-screenshots"
SPACEFAST_TEAM="jeremy-team-2"
SPACEFAST_BASE_URL="https://jkmassel-screenshots.space.fast"

# `--validate-setup` also runs .buildkite/claude/validate-setup.sh before Claude.
CLAUDE_REVIEW_VALIDATE_SETUP=false
if [[ "${1:-}" == --validate-setup ]]; then CLAUDE_REVIEW_VALIDATE_SETUP=true; fi

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

# shellcheck source=.buildkite/claude/audit.sh
source .buildkite/claude/audit.sh

# A review request for wpmobilebot re-runs this step, so clear it however the
# run ends, to let it be requested again. GitHub only clears it when a review
# is submitted, and a run that fails early doesn't submit one. Before BOT_LOGIN
# is set, there's nothing to clear.
clear_review_request() {
  [[ -n "${BOT_LOGIN:-}" ]] || return 0
  gh api --method DELETE "repos/${REPO_SLUG}/pulls/${PR_NUMBER}/requested_reviewers" \
    -f "reviewers[]=${BOT_LOGIN}" > /dev/null 2>&1 || echo "Warning: could not clear the review request."
}
trap 'clear_review_request; audit_stop; audit_archive' EXIT

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
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
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
# The reviewer's copy can't read the shared git mirror, so make this checkout
# self-contained before copying it.
if [[ -s .git/objects/info/alternates ]]; then
  echo "Copying objects from the git mirror into the checkout"
  git repack -a -d -q
  rm .git/objects/info/alternates
fi

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

# ── The reviewer user ────────────────────────────────────────────────
# Claude runs as a separate, non-admin macOS user. As the build user it could
# read this job's secrets: the AWS keys and bot SSH key mounted into every VM,
# files in the build user's home, and (with `ps -E`) the environment of the
# build user's processes, including the Buildkite job token. A different user
# can do none of that. The build user keeps sudo, which Claude can't use.
REVIEWER=claude-reviewer
REVIEWER_HOME="/Users/${REVIEWER}"
REVIEWER_REPO="${REVIEWER_HOME}/wordpress-ios"

echo "--- :bust_in_silhouette: Creating the ${REVIEWER} user"
reviewer_id=600
while dscl . -list /Users UniqueID | awk '{print $2}' | grep -qx "$reviewer_id" \
   || dscl . -list /Groups PrimaryGroupID | awk '{print $2}' | grep -qx "$reviewer_id"; do
  reviewer_id=$((reviewer_id + 1))
done
# Its own group, so files that are only group-readable by `staff` stay out of reach.
sudo -n dseditgroup -o create -i "$reviewer_id" "$REVIEWER"
sudo -n dscl . -create "/Users/${REVIEWER}"
sudo -n dscl . -create "/Users/${REVIEWER}" UserShell /bin/bash
sudo -n dscl . -create "/Users/${REVIEWER}" RealName "Claude reviewer"
sudo -n dscl . -create "/Users/${REVIEWER}" UniqueID "$reviewer_id"
sudo -n dscl . -create "/Users/${REVIEWER}" PrimaryGroupID "$reviewer_id"
sudo -n dscl . -create "/Users/${REVIEWER}" NFSHomeDirectory "$REVIEWER_HOME"
sudo -n dscl . -create "/Users/${REVIEWER}" IsHidden 1
sudo -n dscl . -passwd "/Users/${REVIEWER}" "$(openssl rand -base64 32)"
# Allowed to log in over SSH, if the VM limits that to a group.
if dscl . -read /Groups/com.apple.access_ssh >/dev/null 2>&1; then
  sudo -n dseditgroup -o edit -a "$REVIEWER" -t user com.apple.access_ssh
fi
sudo -n mkdir -p "$REVIEWER_HOME/.ssh"

# Before the reviewer user runs anything.
audit_start "$reviewer_id" "$REVIEWER_HOME"

echo "--- :wordpress: Installing what the test sites need"
# Homebrew belongs to the build user, so install here; the reviewer only runs them.
.buildkite/claude/wp-test-site.sh install-deps > "$AUDIT_DIR/install-test-site-deps.log" 2>&1 \
  || echo "Warning: could not install the test site dependencies (see install-test-site-deps.log)."

echo "--- :card_file_box: Copying the checkout for ${REVIEWER}"
# APFS clones, so this is quick and uses no extra space.
sudo -n cp -cR "$PWD" "$REVIEWER_REPO" 2>/dev/null || sudo -n ditto "$PWD" "$REVIEWER_REPO"
sudo -n rm -rf "${REVIEWER_REPO:?}/${AUDIT_DIR}" "${REVIEWER_REPO:?}/${AUDIT_RAW}" "${REVIEWER_REPO:?}/${AUDIT_LIVE}"
sudo -n cp .buildkite/claude/pr-review-schema.json "$REVIEWER_HOME/schema.json"
sudo -n cp .buildkite/commands/claude-pr-review-as-reviewer.sh "$REVIEWER_HOME/run-review.sh"

# ── Prompt ───────────────────────────────────────────────────────────
SITE_SIGN_IN='Create a fresh self-hosted site whenever you need one: `.buildkite/claude/wp-test-site.sh start <name>` prints its URL, admin username and application password as JSON, and `.buildkite/claude/wp-test-site.sh wp <name> <WP-CLI args>` adds content or plugins. The simulator reaches it on `http://localhost:<port>`. There is no WordPress.com account, so say in the summary when a flow needs one and you could not check it.'

# SIMULATOR_UDID is filled in by the reviewer script.
PROMPT_FILE="$(mktemp)"
{
  cat .buildkite/claude/pr-review-prompt.md
  echo
  cat .buildkite/claude/pr-review-ci-context.md
} | REPO="$REPO_SLUG" PR_NUMBER="$PR_NUMBER" HEAD_SHA="$HEAD_SHA" BASE_BRANCH="$BASE_BRANCH" \
    INPUT_DIR="$INPUT_DIR" EVIDENCE_DIR="$EVIDENCE_DIR" SITE_SIGN_IN="$SITE_SIGN_IN" BOT_LOGIN="$BOT_LOGIN" \
    SIMULATOR_NAME="$SIMULATOR_NAME" SIMULATOR_UDID="{{SIMULATOR_UDID}}" \
    ruby -e 'print STDIN.read.gsub(/\{\{([A-Z_]+)\}\}/) { ENV.fetch($1) }' > "$PROMPT_FILE"
sudo -n cp "$PROMPT_FILE" "$REVIEWER_HOME/prompt.md"

# What Claude was given and run with, for the audit.
mkdir -p "$AUDIT_DIR/inputs"
cp "$PROMPT_FILE" "$AUDIT_DIR/inputs/prompt.md"
cp .buildkite/claude/pr-review-schema.json "$INPUT_DIR"/* "$AUDIT_DIR/inputs/"
jq -n --arg head "$HEAD_SHA" --arg base "$BASE_BRANCH" --arg pr "$PR_NUMBER" \
  --arg claude "$CLAUDE_CODE_VERSION" --arg claude_sha256 "$CLAUDE_CODE_SHA256" --arg model "$CLAUDE_MODEL" --arg effort "$CLAUDE_EFFORT" \
  --arg gh "$(gh --version | head -n 1)" --arg simulator "$SIMULATOR_NAME" --arg xcode "$(xcodebuild -version | tr '\n' ' ')" \
  --arg reviewer "$REVIEWER" --argjson reviewer_uid "$reviewer_id" \
  --arg scripts "$(shasum -a 256 .buildkite/commands/claude-pr-review*.sh .buildkite/claude/*)" \
  '{pr: $pr, head_commit: $head, base_branch: $base, claude_code: $claude, claude_code_sha256: $claude_sha256,
    model: $model, effort: $effort, gh: $gh, xcode: $xcode, simulator: $simulator,
    reviewer: $reviewer, reviewer_uid: $reviewer_uid, script_sha256: ($scripts | split("\n"))}' > "$AUDIT_DIR/run-info.json"

# The only secret the reviewer gets is the Anthropic key.
env_file="$(mktemp)"
{
  printf 'export %s=%q\n' ANTHROPIC_API_KEY "$ANTHROPIC_API_KEY" CLAUDE_CODE_VERSION "$CLAUDE_CODE_VERSION" \
    CLAUDE_CODE_SHA256 "$CLAUDE_CODE_SHA256" CLAUDE_MODEL "$CLAUDE_MODEL" TRANSCRIPT_FILE "$TRANSCRIPT_FILE" \
    CLAUDE_EFFORT "$CLAUDE_EFFORT" SIMULATOR_NAME "$SIMULATOR_NAME" EVIDENCE_DIR "$EVIDENCE_DIR" \
    BUILDER_USER "$(id -un)" BUILDER_HOME "$HOME" BUILDER_PID "$$" \
    CLAUDE_REVIEW_VALIDATE_SETUP "$CLAUDE_REVIEW_VALIDATE_SETUP"
} > "$env_file"
sudo -n install -m 0600 "$env_file" "$REVIEWER_HOME/review.env"
rm -f "$env_file"

# SSH access for the reviewer, the same way the CI host reaches this VM.
ssh_dir="$(mktemp -d)"
ssh-keygen -q -t ed25519 -N '' -f "$ssh_dir/key"
sudo -n install -m 0600 "$ssh_dir/key.pub" "$REVIEWER_HOME/.ssh/authorized_keys"
sudo -n chown -R "${REVIEWER}:${REVIEWER}" "$REVIEWER_HOME"
sudo -n chmod 0700 "$REVIEWER_HOME"

# Runs a command as the reviewer, in its own login session: over SSH to this
# VM, or with `launchctl asuser` if SSH isn't allowed.
as_reviewer() {
  if [[ "$REVIEWER_TRANSPORT" == ssh ]]; then
    ssh -i "$ssh_dir/key" -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o LogLevel=ERROR "${REVIEWER}@127.0.0.1" "$@"
  else
    sudo -n launchctl asuser "$reviewer_id" sudo -n -H -u "$REVIEWER" bash -lc "$*"
  fi
}
REVIEWER_TRANSPORT=ssh
if ! as_reviewer true 2>/dev/null; then
  REVIEWER_TRANSPORT=launchctl
fi
echo "Running as ${REVIEWER} via ${REVIEWER_TRANSPORT}"


echo "--- :eject: Unmounting the shared credentials folder"
# The host mounts its common credentials (AWS keys, the bot's SSH key) into
# every VM, readable by every user. Nothing after this point needs them: the
# AWS keys were read into the job's environment when it started, and this step
# never pushes. If unmounting fails, the reviewer's checks stop Claude.
shared_mount="/Volumes/My Shared Files"
if mount | grep -qF " on ${shared_mount} "; then
  sudo -n umount "$shared_mount" || sudo -n diskutil unmount force "$shared_mount" || true
fi
if mount | grep -qF " on ${shared_mount} "; then
  echo "Warning: ${shared_mount} is still mounted."
else
  echo "${shared_mount} is not mounted."
fi

# ── Review ───────────────────────────────────────────────────────────
audit_canary

echo "--- :claude: Reviewing PR #${PR_NUMBER} as ${REVIEWER}"
# Claude's transcript, in a root-owned folder, append-only (`sappnd`): the
# reviewer can add to it but can't change or delete what's there, and it
# doesn't depend on the SSH session closing. Each tool call and the result are
# shown in the build log as they happen.
sudo -n install -d -o root -g wheel -m 0755 "$(dirname "$TRANSCRIPT_FILE")"
sudo -n install -o root -g wheel -m 0666 /dev/null "$TRANSCRIPT_FILE"
sudo -n chflags sappnd "$TRANSCRIPT_FILE"
tail -n +1 -F "$TRANSCRIPT_FILE" 2>/dev/null > >(jq --unbuffered -R -r '
  fromjson? |
  if .type == "assistant" then
    .message.content[]? | select(.type == "tool_use")
    | "\(.name): \((.input.command // .input.file_path // .input.pattern // .input.description // "") | tostring | gsub("\n"; " ") | .[0:200])"
  elif .type == "result" then
    "Claude finished: \(.subtype // "?"), \(.num_turns // 0) turns, $\(.total_cost_usd // 0)"
  else empty end') &
transcript_follower=$!
disown "$transcript_follower"
reviewer_status=0
as_reviewer "bash ~/run-review.sh" || reviewer_status=$?
echo "The reviewer session ended."
sleep 2
kill "$transcript_follower" 2>/dev/null || true
cp "$TRANSCRIPT_FILE" "$AUDIT_DIR/transcript.jsonl"

# Bring the evidence back for upload and reporting. The reviewer controls
# everything in its evidence folder, so never copy it as root: a symlink there
# would make root (or the artifact upload) copy files the reviewer can't read.
# Instead the reviewer archives what it can read, and this script unpacks the
# archive as the build user into a fresh folder and keeps only plain files.
rm -rf "$EVIDENCE_DIR"
mkdir -p "$EVIDENCE_DIR"
evidence_tar="$(mktemp)"
if as_reviewer "cd ~/wordpress-ios/${EVIDENCE_DIR} && tar -cf - ." > "$evidence_tar" 2>/dev/null; then
  # bsdtar refuses absolute paths and `..` unless told otherwise (-P).
  tar -xf "$evidence_tar" -C "$EVIDENCE_DIR" || echo "Warning: could not unpack all of the evidence."
fi
rm -f "$evidence_tar"
find "$EVIDENCE_DIR" -mindepth 1 ! -type f ! -type d -print -delete | sed 's/^/Removed (not a plain file): /'

# The test sites, the simulator and anything Claude left running outlive the
# session. Stop them all before any step that uses a secret, so none of them
# can watch for it.
# Its launchd domains go first, so nothing it registered (such as a
# LaunchAgent) is started again.
echo "--- :octagonal_sign: Stopping everything ${REVIEWER} left running"
for domain in "gui/${reviewer_id}" "user/${reviewer_id}"; do
  sudo -n launchctl bootout "$domain" > /dev/null 2>&1 || true
done
for _ in 1 2 3 4 5; do
  sudo -n pkill -KILL -u "$REVIEWER" 2>/dev/null || true
  sleep 2
  pgrep -u "$REVIEWER" > /dev/null || break
done
if pgrep -u "$REVIEWER" > /dev/null; then
  ps -o pid=,comm= -U "$REVIEWER" | sed 's/^/  still running: /'
  echo "^^^ +++ Processes of ${REVIEWER} are still running, so nothing will be posted."
  exit 2
fi
echo "No processes of ${REVIEWER} are left."
audit_stop
if [[ "$reviewer_status" == 3 ]]; then
  echo "^^^ +++ The reviewer user could reach the build user's secrets, so Claude did not run."
  exit 2
elif [[ "$reviewer_status" != 0 ]]; then
  echo "^^^ +++ The reviewer script failed (exit ${reviewer_status}), so there is no verdict."
  exit 2
fi

# A session can end in several result events, one per segment. Show each one
# (whether a segment's cost includes earlier segments isn't documented), and
# take the last structured output.
jq -r 'select(.type == "result") | "Segment: cost $\(.total_cost_usd // 0), \(.num_turns // 0) turns, \((.duration_ms // 0) / 1000 | floor)s"' \
  "$TRANSCRIPT_FILE" 2>/dev/null || true
REVIEW=$(jq -s -c '[.[] | select(.type == "result") | .structured_output // empty] | last // empty' "$TRANSCRIPT_FILE" 2>/dev/null || true)
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
  find "$EVIDENCE_DIR" -maxdepth 2 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.mp4' \) -print0)
if [[ ${#media[@]} -eq 0 ]]; then
  :
elif [[ -z "${SPACEFAST_TOKEN:-}" ]]; then
  echo "SPACEFAST_TOKEN isn't set, so screenshots link to the Buildkite build."
else
  echo "--- :frame_with_picture: Publishing ${#media[@]} screenshot(s) to Spacefast"
  media_path="wordpress-ios/pr-${PR_NUMBER}/build-${BUILDKITE_BUILD_NUMBER}"
  stage="$(mktemp -d)"
  mkdir -p "$stage/$media_path"
  cp "${media[@]}" "$stage/$media_path/"
  published=no
  sf_bin="$HOME/.local/bin/sf-${SF_VERSION}"
  if [[ ! -x "$sf_bin" ]]; then
    sf_gz="$(mktemp)"
    if curl -fsSL -o "$sf_gz" "https://github.com/spacefast/cli/releases/download/v${SF_VERSION}/spacefast-darwin-arm64.gz" \
        && echo "${SF_ARM64_SHA256}  ${sf_gz}" | shasum -a 256 -c -; then
      gzip -dc "$sf_gz" > "$sf_bin" && chmod 0755 "$sf_bin"
    else
      rm -f "$sf_bin"
    fi
    rm -f "$sf_gz"
  fi
  if [[ -x "$sf_bin" ]]; then
    # Additive, so other PRs' files in the Space are kept.
    # sf reads the token from SPACEFAST_TOKEN, which keeps it out of `ps`.
    if (cd "$stage" && SPACEFAST_TOKEN="$SPACEFAST_TOKEN" "$sf_bin" publish . --publish-mode additive --space "$SPACEFAST_SPACE" \
          --team "$SPACEFAST_TEAM" --json --wait) > "$AUDIT_DIR/spacefast-publish.json" 2> "$AUDIT_DIR/spacefast-publish.err"; then
      published=yes
      for file in "${media[@]}"; do
        url="${SPACEFAST_BASE_URL%/}/${media_path}/$(basename "$file")"
        echo "Published: ${url}" | tee -a "$AUDIT_DIR/published-urls.txt"
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
        body: ("\($marker)\n🤖 **Claude CI review** of `\($sha[0:10])`: \(.findings | length) new finding(s). The current verdict is in the Claude CI review comment; evidence is on the [Buildkite build](\($url)).\n\n"
          + (if $inline then "" else (.findings | map("### `\(.path):\(.line)`\n\n" + text) | join("\n\n")) end)),
        comments: (if $inline then .findings | map({path, line, side: "RIGHT", body: ("\($marker)\n" + text)}) else [] end)
      }' <<<"$REVIEW"
  }
  if ! new_review_id=$(review_payload true | gh api --method POST "repos/${REPO_SLUG}/pulls/${PR_NUMBER}/reviews" --input - --jq .id); then
    # Usually a line that isn't in the diff. Fall back to listing the findings in the review body.
    echo "Inline review failed; posting the findings in the review body instead."
    new_review_id=$(review_payload false | gh api --method POST "repos/${REPO_SLUG}/pulls/${PR_NUMBER}/reviews" --input - --jq .id) || post_failed=1
  fi
fi

# Earlier runs' reviews can't be deleted, so mark them superseded: their first
# line (which may say "verdict: fail" in older runs) is replaced, and any
# findings listed below it are kept. The summary comment has the current verdict.
superseded_line="🤖 ~~Claude CI review~~ – superseded by the run on \`${HEAD_SHA:0:10}\`. The current verdict is in the Claude CI review comment."
while IFS=$'\t' read -r review_id review_body_json; do
  [[ -z "$review_id" || "$review_id" == "${new_review_id:-}" ]] && continue
  updated=$(jq -rn --argjson body "$review_body_json" --arg line "$superseded_line" '$body | split("\n") | .[1] = $line | join("\n")')
  gh api --method PUT "repos/${REPO_SLUG}/pulls/${PR_NUMBER}/reviews/${review_id}" -f body="$updated" >/dev/null || post_failed=1
done < <(gh api "repos/${REPO_SLUG}/pulls/${PR_NUMBER}/reviews" --paginate --jq \
  ".[] | select(.user.login == \"${BOT_LOGIN}\" and (.body | startswith(\"${MARKER}\")) and (.body | contains(\"🤖 **Claude CI review**\")))
       | \"\\(.id)\\t\\(.body | tojson)\"" 2>/dev/null || true)

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
