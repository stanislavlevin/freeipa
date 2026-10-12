#!/bin/bash -eu

# Latest version of this script:
# https://git.altlinux.org/people/slev/public/updater_submodules.git
#
# Revendoring is handled by zoryn:
# https://rider.altlinux.team/zoryn/guide/hooks.html#gearmerge-upd
#
# How to configure hook:
# - put update_submodules.override and this file into .gear/merge-up.d/
#   Customization can be done in update_submodules.override
#   Vars and functions that can be customized:
#   - prepare_vendor: a function that is called right before the vendoring,
#     default: empty function (does nothing)
#     args:
#     - $1 version
#     - $2 git tag
#   - post_vendor: a function that is called right after the vendoring,
#     default: empty function (does nothing)
#     args:
#     - $1 version
#     - $2 git tag
#
# How to revendor:
# - run `zoryn up`
#
# How to apply bundled submodules:
# - gear rules:
#   - tar: alt_submodules:modules name=modules base=.
#
# - spec file:
#   - Source2: modules.tar
#   - %setup -a2
set -eu

SUBMODULES_BRANCH='alt_submodules'
SUBMODULES_DIR='modules'
SUBMODULES_TMPDIR='.alt_submodules_tmp'

script_name=$(basename "$0")
script_settings="$(dirname "$0")/update_submodules.override"

# per https://rider.altlinux.team/zoryn/guide/hooks.html#gearmerge-upd
upstream_version="$1"
upstream_tag="$TAG"


log() {
    printf "[submodules vendor] "
    printf "$@"
}

# can be overriden
prepare_vendor() { :; }
post_vendor() { :; }

git show "$upstream_tag" >/dev/null 2>&1 ||
    { log 'there is no such git object: %s\n' "$upstream_tag" ; exit 1 ; }

source "$script_settings"

# current branch, will be switched back
current_branch="$(git branch --show-current)"
if [[ "$current_branch" == "$SUBMODULES_BRANCH" ]]; then
    log 'already on branch: %s, please switch manually on target branch\n' \
        "$current_branch"
    exit 1
fi

log 'starting vendoring submodules for %s\n' "$upstream_tag"

submodules_src_dir_abs="$(realpath '.')"
pushd "$submodules_src_dir_abs" >/dev/null
submodules_dirs="$submodules_src_dir_abs/.submoduledirs"

function finish {
    # clean up temp dir
    rm -rf "$submodules_src_dir_abs/$SUBMODULES_TMPDIR"
    rm -f "$submodules_dirs"
}
trap finish EXIT

rm -f "$submodules_dirs"
git submodule --quiet foreach --recursive "printf '%s\0' "\$displaypath" >> $submodules_dirs"
xargs -0 rm -rf < "$submodules_dirs"
git restore --recurse-submodules --pathspec-file-nul --pathspec-from-file "$submodules_dirs"
rm -rf "$SUBMODULES_TMPDIR"
mkdir "$SUBMODULES_TMPDIR"
rm -rf "$SUBMODULES_DIR"
mkdir "$SUBMODULES_DIR"

log 'executing prepare_vendor\n'
prepare_vendor "$upstream_version" "$upstream_tag"

log 'initializing submodules\n'
git submodule --quiet update --init --recursive
git submodule --quiet foreach --recursive "cd "\$toplevel" && cp -a --parents -t "$SUBMODULES_DIR" "\$displaypath""
# for commit message
submodules_status="$(git submodule status)"

log 'executing post_vendor\n'
post_vendor "$upstream_version" "$upstream_tag"

# move to allow switch branch
mv "$SUBMODULES_DIR" -t "$SUBMODULES_TMPDIR/"

# restore the tree (can be changed by prepare_vendor hook)
git restore -- ":^$SUBMODULES_DIR/**"

git switch -q "$SUBMODULES_BRANCH" ||
    git switch -q --orphan "$SUBMODULES_BRANCH"

rm -rf "$SUBMODULES_DIR"
mv "$submodules_src_dir_abs/$SUBMODULES_TMPDIR/$SUBMODULES_DIR" ./

git add -f "$SUBMODULES_DIR"

# only commit if there are changes
if git diff --quiet --cached -- "$SUBMODULES_DIR" ; then
    log 'submodules were not changed\n'
else
    log 'committing updated submodules\n'
    git commit --quiet \
        -m 'Update submodules for '"$upstream_tag"'' \
        -m 'Submodules:' \
        -m "$submodules_status" \
        -m 'Updated with zoryn merge hook (`'"$script_name"'`).' \
        -m 'See for details:'$'\n''https://rider.altlinux.team/zoryn/guide/hooks.html#gearmerge-upd'$'\n''https://git.altlinux.org/people/slev/public/updater_submodules.git' \

fi

git switch -q "$current_branch"
git merge -q -s ours "$SUBMODULES_BRANCH" --allow-unrelated-histories --no-edit
