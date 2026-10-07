#!/bin/sh
# Installs or updates ai-native-sdlc in a Claude Code profile. Safe to rerun.
# Usage: ./install.sh   or   CLAUDE_CONFIG_DIR=/path/to/profile ./install.sh
set -eu

fail() {
  echo "ai-native-sdlc: $*" >&2
  exit 1
}

dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
repo="$(cd "$(dirname "$0")" && pwd)"
settings="$dir/settings.json"
hook_cmd="bash \"$dir/skills/ai-native-sdlc/scripts/load-intent.sh\""

[ -f "$repo/AI-NATIVE-SDLC.md" ] && [ -f "$repo/skills/ai-native-sdlc/SKILL.md" ] ||
  fail "run this script from inside the ai-native-sdlc repository."
command -v jq >/dev/null 2>&1 || fail "jq is required to edit settings.json; install it and rerun."

# A real file or directory in the way may be the user's own work, so it is never replaced.
# Checked before any change, so a refusal leaves the profile exactly as it was.
for target in "$dir/AI-NATIVE-SDLC.md" "$dir/skills/ai-native-sdlc"; do
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    fail "$target exists and is not a symlink; nothing changed."
  fi
done

# Symlinks instead of copies, so a git pull in the repo updates every profile at once.
mkdir -p "$dir/skills"
ln -sfn "$repo/AI-NATIVE-SDLC.md" "$dir/AI-NATIVE-SDLC.md"
ln -sfn "$repo/skills/ai-native-sdlc" "$dir/skills/ai-native-sdlc"

# A missing CLAUDE.md is expected on a fresh profile; the import creates it.
# The leading newline keeps the import off a last line that lacks one.
grep -qx '@AI-NATIVE-SDLC.md' "$dir/CLAUDE.md" 2>/dev/null ||
  printf '\n@AI-NATIVE-SDLC.md\n' >> "$dir/CLAUDE.md"

[ -f "$settings" ] || echo '{}' > "$settings"
tmp="$(mktemp "$dir/settings.json.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
# Drops any earlier copy of this hook first, wherever it pointed, so reruns and moved
# installs leave exactly one; every other hook is kept as it was.
jq --arg cmd "$hook_cmd" '
  def ours: (.command // "") | contains("ai-native-sdlc/scripts/load-intent.sh");
  .hooks.SessionStart = (
    [ (.hooks.SessionStart // [])[]
      | if any(.hooks[]?; ours)
        then (.hooks |= map(select(ours | not))) | select(.hooks != [])
        else . end ]
    + [ { matcher: "startup|resume|clear|compact",
          hooks: [ { type: "command", command: $cmd } ] } ]
  )' "$settings" > "$tmp" ||
  fail "could not update $settings (is it valid JSON?); nothing changed in it."
# Written over the existing file instead of moved into place, to keep its permissions
# (settings.json is often 600) and any symlink pointing at it.
cat "$tmp" > "$settings"

echo "ai-native-sdlc installed in $dir. Start a new Claude Code session."
