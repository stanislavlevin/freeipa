#!/bin/bash -eu

# Latest version of this script:
# https://git.altlinux.org/people/slev/public/?p=updater_vendored_nodejs.git
#
# Revendoring is handled by zoryn:
# https://rider.altlinux.team/zoryn/guide/hooks.html#gearmerge-upd
#
# How to configure hook:
# - put update_nodejs_bundle.override and this file into .gear/merge-up.d/
#   Customization can be done in update_nodejs_bundle.override
#   Vars and functions that can be customized:
#   - NODEJS_SRC_DIR: a path to NodeJS sources relative to project root,
#     default: '.' (cwd).
#   - prepare_vendor: a function that is called right before the vendoring
#     (npm), default: empty function (does nothing)
#     args:
#     - $1 version
#     - $2 git tag
#   - post_vendor: a function that is called right after the vendoring (npm),
#     default: empty function (does nothing)
#     args:
#     - $1 version
#     - $2 git tag
#
# - configure zoryn to install required packages:
#   echo -e '[sandbox]\npackages = ["npm", "node"]' >> .gear/version-up
#
# How to revendor:
# - run `zoryn up`
#
# How to apply bundled NodeJS packages:
# - gear rules:
#   - tar: alt_vendor_nodejs:. name=vendor_nodejs base=.
#
# - spec file:
#   - Source2: vendor_nodejs.tar
#   - %setup -a2
set -eu

NODEJS_VENDOR_BRANCH='alt_vendor_nodejs'
NODEJS_VENDOR_DIR='node_modules'
NODEJS_VENDOR_TMPDIR='.alt_nodejs_vendor_tmp'

script_name=$(basename "$0")
script_settings="$(dirname "$0")/update_nodejs_bundle.override"

# per https://rider.altlinux.team/zoryn/guide/hooks.html#gearmerge-upd
upstream_version="$1"
upstream_tag="$TAG"


log() {
    printf "[nodejs vendor] "
    printf "$@"
}

# can be overriden
prepare_vendor() { :; }
post_vendor() { :; }

git show "$upstream_tag" >/dev/null 2>&1 ||
    { log 'there is no such git object: %s\n' "$upstream_tag" ; exit 1 ; }

source "$script_settings"
NODEJS_SRC_DIR="${NODEJS_SRC_DIR:-.}"

# current branch, will be switched back
current_branch="$(git branch --show-current)"
if [[ "$current_branch" == "$NODEJS_VENDOR_BRANCH" ]]; then
    log 'already on branch: %s, please switch manually on target branch\n' \
        "$current_branch"
    exit 1
fi

log 'starting vendoring NodeJS packages for %s\n' "$upstream_tag"

nodejs_src_dir_abs="$(realpath "$NODEJS_SRC_DIR")"

function finish {
    # clean up temp dir
    rm -rf "$nodejs_src_dir_abs/$NODEJS_VENDOR_TMPDIR"
}
trap finish EXIT

pushd "$NODEJS_SRC_DIR" >/dev/null
rm -rf "$NODEJS_VENDOR_TMPDIR"
mkdir "$NODEJS_VENDOR_TMPDIR"
rm -rf "$NODEJS_VENDOR_DIR"

log 'executing prepare_vendor\n'
prepare_vendor "$upstream_version" "$upstream_tag"

log 'downloading NodeJS vendored packages\n'
# https://docs.npmjs.com/cli/v8/commands/npm-ci
# The main differences between using npm install and npm ci are:
#
# - The project must have an existing package-lock.json or npm-shrinkwrap.json.
# - If dependencies in the package lock do not match those in package.json, npm
#   ci will exit with an error, instead of updating the package lock.
# - npm ci can only install entire projects at a time: individual dependencies
#   cannot be added with this command.
# - If a node_modules is already present, it will be automatically removed
#   before npm ci begins its install.
# - It will never write to package.json or any of the package-locks: installs
#   are essentially frozen.

if [ -s package-lock.json ]; then
    log 'running `npm ci` (package-lock.json)\n'
    npm ci -q
else
    log 'running `npm install` (no package-lock.json)\n'
    npm install -q
fi

log 'executing post_vendor\n'
post_vendor "$upstream_version" "$upstream_tag"

# move to allow switch branch
mv "$NODEJS_VENDOR_DIR" -t "$NODEJS_VENDOR_TMPDIR/"
popd >/dev/null

# restore the tree (can be changed by prepare_vendor hook)
git restore -- ":^$NODEJS_VENDOR_DIR/**"

git switch -q "$NODEJS_VENDOR_BRANCH" ||
    git switch -q --orphan "$NODEJS_VENDOR_BRANCH"

rm -rf "$NODEJS_VENDOR_DIR"
mv "$NODEJS_SRC_DIR/$NODEJS_VENDOR_TMPDIR/$NODEJS_VENDOR_DIR" ./

git add -f "$NODEJS_VENDOR_DIR"

# only commit if there are changes
if git diff --quiet --cached -- "$NODEJS_VENDOR_DIR" ; then
    log 'NodeJS vendored packages were not changed\n'
else
    log 'committing updated NodeJS vendored packages\n'
    git commit --quiet \
        -m 'Update NodeJS vendored packages for '"$upstream_tag"'' \
        -m 'Updated with zoryn merge hook (`'"$script_name"'`).' \
        -m 'See for details:'$'\n''https://rider.altlinux.team/zoryn/guide/hooks.html#gearmerge-upd'$'\n''https://git.altlinux.org/people/slev/public/?p=updater_vendored_nodejs.git' \

fi

git switch -q "$current_branch"
git merge -q -s ours "$NODEJS_VENDOR_BRANCH" --allow-unrelated-histories --no-edit
