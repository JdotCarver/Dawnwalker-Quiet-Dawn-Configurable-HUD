#!/usr/bin/env bash
# ressources/tools/arena-turn-start.sh
#
# Arena turn-start sync + harness repair
#
# Run at the START of every turn:   bash ressources/tools/arena-turn-start.sh
# Run again BEFORE EVERY COMMIT:    bash ressources/tools/arena-turn-start.sh --verify
#
# --verify skips all git classification and only answers "is the tree still the
# one I have been editing?". Use it before committing: a snapshot restore can
# land MID-TURN, and when it does it reverts tracked files to HEAD while
# leaving untracked files in place. Observed twice on 2026-10-05: once it threw
# away a feature's worth of edits to tracked files between writing them and
# running git status, while new untracked files survived and left the tree
# looking healthy; once it knocked HEAD back to the base commit. Only the
# integrity checks catch the first case, and the turn-start pass cannot,
# because by then it has already run.
#
# Why this exists
# ---------------
# The Arena harness occasionally restores this checkout from a snapshot instead of
# leaving it in place. Two symptoms show up:
#   1. HEAD is reset to the base commit, so the branch looks "behind".
#   2. The working tree keeps changing after the first glance: restored files land
#      in WAVES, minutes apart, appearing and vanishing.
# Both are handled below. Nothing here touches the remote.
#
# What it does
#   1. Waits out an in-flight snapshot restore (the tree churns while it lands).
#   2. Fetches the session branch and classifies the local state:
#        - clean + in sync          -> nothing to do
#        - no remote branch yet     -> INFO only (first turn; never fetch-fail)
#        - local BEHIND             -> fast-forward (the user pushes between turns)
#        - local AHEAD              -> LEAVE HEAD ALONE (unpushed mid-turn work)
#        - HEAD == base commit      -> RE-CLONE: hard-reset to the remote tip
#        - both sides diverged      -> stop; repair by hand (docs/AGENT_NOTES.md)
#   3. Settles: requires the status hash to hold steady before trusting the tree.
#   4. Verifies the tree is whole (key files present, manifest.json parses).
#
# HISTORY / READ THIS BEFORE EDITING
# ----------------------------------
# An earlier version of this script (in a previous repository) classified with
# `reset --hard` whenever HEAD != remote, which would have eaten unpushed commits
# made mid-turn. The ancestry checks below are the fix; do not simplify them away.
#
# The first version here also died on a missing tracking ref (`git rev-parse
# FETCH_HEAD` aborts under `set -e`) on the very first turn, before the session
# branch existed on the remote. Hence the explicit "no remote branch yet" branch.
#
# CHICKEN-AND-EGG: after a re-clone this file itself may be missing until the
# snapshot restore settles. If it is absent, repair by hand using docs/AGENT_NOTES.md.

set -uo pipefail

# This script lives in ressources/tools/, so the repository root is TWO levels up.
# (It sat in tools/ in the previous project; a stale "/.." silently rooted every
# check at ressources/ and made the integrity checks pass against nothing.)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRANCH="arena/8dd537f7-dawnwalker-quiet-dawn-configur"
BASE_COMMIT="49d0f635849b114fb6f353f76baa6156006d05ae"

# Files whose absence means "the snapshot restore is incomplete".
# Keep this in sync when load-bearing files appear.
KEY_FILES=(
    README.md
    ue4ss-common.lock.json
    package/mod.manifest
    package/Data/QuietDawnHUD/mod_settings.ini
    package/Data/QuietDawnHUD/Scripts/Gameplay.lua
    package/Data/QuietDawnHUD/Scripts/SettingsSchema.lua
    package/Data/QuietDawnHUD/Scripts/QuietDawnDiagnostics.lua
)

VERIFY_ONLY=0
for argument in "$@"; do
    case "$argument" in
        --verify) VERIFY_ONLY=1 ;;
        *) echo "!! unknown argument: $argument (expected --verify)"; exit 2 ;;
    esac
done

cd "$REPO_ROOT" || exit 1

if [ "$VERIFY_ONLY" -eq 1 ]; then
    echo "== arena verify ($(date +%H:%M:%S)) =="
else
    echo "== arena turn-start ($(date +%H:%M:%S)) =="
fi
echo "   branch=$(git rev-parse --abbrev-ref HEAD)  HEAD=$(git rev-parse --short HEAD)  dirty=$(git status --porcelain | wc -l)"

# --- 1. Is a snapshot restore still landing files? ---------------------------
# Runs BEFORE the branch guard on purpose: while files are still landing, a "dirty"
# reading (or a half-restored branch) is an artifact of the restore, not a real
# reason to refuse to do anything.
status_hash() { git status --porcelain | md5sum; }

before="$(status_hash)"
sleep 3
if [ "$before" != "$(status_hash)" ]; then
    echo "!! working tree still changing (snapshot restore in flight) — waiting 10s"
    sleep 10
fi

# --- 2 and 3. Git state. Skipped by --verify, which never touches HEAD. ------
# --verify must stay side-effect free: it is called with uncommitted work in
# the tree, where a reset or a fast-forward would be destructive.
if [ "$VERIFY_ONLY" -eq 0 ]; then

# --- 2. Guard: the session branch must be checked out. -----------------------
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    echo "!! on '$CURRENT_BRANCH' but this session must run on '$BRANCH'"
    if [ -z "$(git status --porcelain)" ]; then
        echo "   -> switching back to the session branch (tree is clean)"
        git checkout "$BRANCH"
    else
        echo "   -> tree is dirty; NOT switching automatically. Resolve by hand:"
        echo "        git status --porcelain    # inspect"
        echo "        git stash                 # park it, then: git checkout $BRANCH"
        exit 1
    fi
fi

# --- 3. Fetch and classify. NEVER move HEAD when local is ahead. -------------
git fetch origin --quiet 2>/dev/null || echo "!! fetch failed (offline?) — classifying against the last known state"

if ! git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
    echo "== no remote branch '$BRANCH' yet (first turn, or the user has not pushed)"
    REMOTE=""
else
    REMOTE="$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo "")"
fi

# A depth-1 harness re-clone truncates BOTH sides at one commit each, so
# `merge-base --is-ancestor` fails in both directions and the classifier below
# would false-alarm "DIVERGED". Unshallow first, then classify against real history.
if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
    echo "   shallow clone detected — unshallowing before classifying"
    git fetch --unshallow origin --quiet 2>/dev/null || true
    REMOTE="$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo "$REMOTE")"
fi

HEAD_NOW="$(git rev-parse HEAD)"
DIRTY="$(git status --porcelain)"

reset_to_remote() {
    git reset --hard "$REMOTE" >/dev/null
    # A hard reset restores tracked files only. Anything listed here is a leftover
    # from the disturbed checkout (or the user's mid-turn scribbles) — worth seeing
    # rather than silently dragging along.
    local leftovers
    leftovers="$(git status --porcelain)"
    if [ -n "$leftovers" ]; then
        echo "   note: untracked/leftover entries after the reset:"
        echo "$leftovers" | sed 's/^/     /'
    fi
}

if [ -z "$REMOTE" ]; then
    echo "   local only: HEAD=$(git rev-parse --short HEAD) — nothing to sync against"
elif [ "$HEAD_NOW" = "$REMOTE" ] && [ -z "$DIRTY" ]; then
    echo "== clean and in sync with origin/$BRANCH ($(git rev-parse --short HEAD))"
elif [ "$HEAD_NOW" = "$REMOTE" ]; then
    # At the tip with a dirty tree: in-progress work or a stale snapshot, never a
    # reason to reset. The integrity check below reports anything actually broken.
    echo "!! HEAD at remote tip but tree dirty — leaving uncommitted work ALONE"
elif [ "$HEAD_NOW" = "$BASE_COMMIT" ]; then
    # A repaired/rebased session branch may no longer descend from the immutable
    # harness base. Detect the exact base before ancestry checks for that reason.
    echo "!! RE-CLONE DETECTED (HEAD == base commit) — hard-resetting to the remote tip"
    reset_to_remote
elif git merge-base --is-ancestor "$REMOTE" "$HEAD_NOW"; then
    echo "== local is AHEAD of origin/$BRANCH (unpushed commits) — leaving HEAD alone"
elif git merge-base --is-ancestor "$HEAD_NOW" "$REMOTE"; then
    echo "== behind origin/$BRANCH (user pushed between turns) — fast-forwarding"
    reset_to_remote
else
    echo "!! DIVERGED (both sides have unique commits) — repair by hand"
    echo "   do NOT force-push over the user's work; follow the recovery steps below"
    # The usual cause is a re-clone arriving mid-turn (observed twice on 2026-09-29,
    # both times right after a user-facing pause): HEAD is knocked back to the base
    # commit, the next commit therefore sits on top of BASE, and the push is rejected
    # because the remote still holds the earlier commits from this same session.
    # The re-parenting recipe below is the safe repair: it keeps the local tree
    # verbatim and makes it a child of the remote tip. Verify the tree first!
    echo "   if this session's local commit was rebuilt on top of $BASE_COMMIT"
    echo "   while the remote holds your earlier commits, re-parent it (nothing is lost):"
    echo "        git diff --stat origin/$BRANCH    # confirm only your intended changes"
    echo "        git reset --soft origin/$BRANCH"
    echo "        git commit -C HEAD@{1}            # re-use the previous message"
    exit 1
fi

fi  # end of the git classification sections

# --- 4. Settle: restored files can keep arriving in waves. -------------------
for round in 1 2 3; do
    before="$(status_hash)"
    sleep 3
    if [ "$before" = "$(status_hash)" ]; then
        break
    fi
    echo "!! worktree still churning (restore wave $round) — waiting"
    sleep 5
done

# --- 5. Verify the tree is whole. -------------------------------------------
sleep 2
missing=0
for file in "${KEY_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "!! MISSING: $file"
        missing=1
    fi
done

# Any JSON we ship must at least parse; a corrupted manifest is invisible otherwise.
for json_file in DMM-API-SOURCE.json ue4ss-common.lock.json package/vortex_override_instructions.json; do
    if [ -f "$json_file" ]; then
        if ! python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$json_file"; then
            echo "!! $json_file is not valid JSON"
            missing=1
        fi
    fi
done

# Vendored-module guard.
#
# Seven files under package/Data/QuietDawnHUD/Scripts/ are NOT this repository's
# code. They are copied from github.com/my-mods/ue4ss-common and pinned by sha256
# in ue4ss-common.lock.json. Editing them here desyncs the lock, so changes to
# those files belong upstream instead.
#
# This check exists for two reasons: it proves a snapshot restore did not corrupt
# them, and it catches the agent accidentally editing one of them.
if [ -f ue4ss-common.lock.json ]; then
    python3 - <<'PY'
import hashlib, json, os, sys

lock = json.load(open("ue4ss-common.lock.json"))
drifted = []
for module in lock["modules"]:
    for destination in module["destinations"]:
        if not os.path.exists(destination):
            drifted.append(f"MISSING  {destination}")
            continue
        digest = hashlib.sha256(open(destination, "rb").read()).hexdigest()
        if digest != module["sha256"]:
            drifted.append(f"MODIFIED {destination}  (expected {module['sha256'][:12]}, got {digest[:12]})")

if drifted:
    print("!! vendored ue4ss-common modules no longer match ue4ss-common.lock.json:")
    for entry in drifted:
        print("     " + entry)
    print("   These files are upstream-owned. Revert them here and send the change")
    print("   to github.com/my-mods/ue4ss-common instead, or re-pin the lock on purpose.")
    sys.exit(1)

print(f"== vendored ue4ss-common modules verified ({len(lock['modules'])} pinned)")
PY
    if [ $? -ne 0 ]; then
        missing=1
    fi
fi

if [ "$missing" -ne 0 ]; then
    echo "!! tree incomplete — repair by hand; inspect the missing files above"
    exit 1
fi

if [ "$VERIFY_ONLY" -eq 1 ]; then
    echo "== verified: HEAD=$(git rev-parse --short HEAD) dirty=$(git status --porcelain | wc -l)"
    # Printing the pending changes is the point: if a mid-turn restore has
    # reverted the files you were editing, this list is suddenly far shorter
    # than you expect, which is the signal to re-apply before committing.
    changes="$(git status --porcelain)"
    if [ -n "$changes" ]; then
        echo "   pending changes:"
        echo "$changes" | sed 's/^/     /'
    else
        echo "   no pending changes (expected? a mid-turn restore looks exactly like this)"
    fi
    exit 0
fi

# Run the offline suite. These are fast (a couple of seconds all told) and
# each one exists because something shipped broken without it, so the cost of
# running them unconditionally is far below the cost of forgetting to.
#
# Every test needs lupa, which lives in ~/.local and is therefore wiped by a
# sandbox restore. setup.sh is cheap when it is already installed.
bash "$(dirname "$0")/setup.sh" >/dev/null 2>&1 || true

suite_failed=0
for test in check-lua.py check-mod-settings.py test-settings-migration.py test-fade.py; do
    output="$(python3 "$(dirname "$0")/$test" 2>&1)" || suite_failed=1
    printf '%s\n' "$output" | tail -1 | sed 's/^/   /'
    if printf '%s\n' "$output" | grep -q '^FAIL\|^!!'; then
        suite_failed=1
        printf '%s\n' "$output" | grep '^FAIL\|^!!' | sed 's/^/   /'
        echo "!! $test reported problems"
    fi
done
if [ "$suite_failed" -ne 0 ]; then
    echo "!! the offline suite is not green BEFORE you have changed anything —"
    echo "   investigate that first; do not assume it is your edit."
fi

echo "== ready: HEAD=$(git rev-parse --short HEAD) dirty=$(git status --porcelain | wc -l)"
git log --oneline -3
