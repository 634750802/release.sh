#!/usr/bin/env bash

set -e
RELEASE_SH_VER=1.2.2-STAGING
RELEASE_SH_DIR=$(dirname "${BASH_SOURCE[0]}")
WORKING_DIR=$(pwd)

source "$RELEASE_SH_DIR/echoutils.sh"

echo-log info "version $RELEASE_SH_VER"
echo-log info "path: $RELEASE_SH_DIR"
echo-log info "pwd: $WORKING_DIR"

source "$RELEASE_SH_DIR/gitutils.sh"
source "$RELEASE_SH_DIR/bashutils.sh"
source "$RELEASE_SH_DIR/helputils.sh"
source "$RELEASE_SH_DIR/versionutils.sh"

function get-staging-version() {
  local staging_tag_prefix=$1
  local staging_tag_count

  staging_tag_count=$(git tag -l | grep -c "$staging_tag_prefix" )
  if [[ "$staging_tag_count" -gt 1 ]]; then
    echo-exit 1 "more than one staging tags exists. please keep one and remove others:" "$(git tag -l | grep "$staging_tag_prefix")"
  elif [[ "$staging_tag_count" -lt 1 ]]; then
    echo-exit 1 "no staging tags exists. please call 'release.sh init <version>' first"
  fi

  git tag -l | grep "$staging_tag_prefix" | grep -E -o "[^/]+$"
}

function init() {
  assert-work-tree-clean
  git-fetch-tags
  # assert release or staging tag was not exists.

  local project_name
  local project_path=$1
  local project_version=$2
  local branch

  # check params
  if [[ -z $project_version ]]; then
    echo-exit 1 "project path is required"
  fi
  if [[ -z $project_version ]]; then
    echo-exit 1 "project version is required"
  fi

  # load scripts provided by project
  echo-log log "loading $project_path/.release.sh"
  source "$project_path/.release.sh"
  if [[ -z "$PROJECT_NAME" ]]; then
    echo-exit 1 "PROJECT_NAME not set"
  fi
  project_name=$PROJECT_NAME

  branch=$(git-current-branch)

  echo-log log "initializing project $project_name @ $project_version on branch $branch"

  local release_tag="$project_name/release/$project_version"
  if (git-tag-exists "$release_tag"); then
    echo-exit 1 "release tag $release_tag for project $project_name was already exists"
  fi

  local staging_tag="$project_name/$branch-staging/$project_version"
  if (git-tag-exists "$staging_tag"); then
    echo-exit 1 "staging tag $staging_tag for project $project_name was already exists"
  fi

  cd "$project_path"
  if (! call-or-ignore init-staging-version "$project_version" "$staging_tag"); then
    echo-exit 1 "init staging version failed"
  fi
  cd "$WORKING_DIR"
  if ! work-tree-clean; then
    echo-log warn "init-staging-version didn't commit version changes, release.sh will commit it with default message"
    git commit -am "chore($project_name): initialize staging version $next_version"
  fi

  echo-log info "pushing changes to origin"
  git push

  echo-log info "creating tag $staging_tag"
  git tag "$staging_tag"
  git push origin --tags
}

function deinit() {
  assert-work-tree-clean
  git-fetch-tags
  # assert release or staging tag was not exists.

  local project_name
  local project_path=$1
  local project_version
  local branch

  # check params
  if [[ -z $project_path ]]; then
    echo-exit 1 "project path is required"
  fi

  # load scripts provided by project
  echo-log log "loading $project_path/.release.sh"
  source "$project_path/.release.sh"
  if [[ -z "$PROJECT_NAME" ]]; then
    echo-exit 1 "PROJECT_NAME not set"
  fi
  project_name=$PROJECT_NAME

  branch=$(git-current-branch)
  local staging_tag_prefix="$project_name/$branch-staging/"
  project_version=$(get-staging-version "$staging_tag_prefix")

  echo-log log "deinitializing project $project_name @ $project_version on branch $branch"

  local staging_tag="$project_name/$branch-staging/$project_version"
  if (! git-tag-exists "$staging_tag"); then
    echo-exit 1 "staging tag $staging_tag for project $project_name was already exists"
  fi

  if (! call-or-ignore deinit-staging-version "$project_version" "$staging_tag"); then
    echo-exit 1 "deinit staging version failed"
  fi

  echo-log info "deleting tag $staging_tag"
  git tag -d "$staging_tag"
  git push origin --delete "$staging_tag"
}

function stage() {
  assert-work-tree-clean
  git-fetch-tags

  local project_path=$1
  local branch
  local project_version
  local staging_tag


  # load scripts provided by project
  echo-log log "loading $project_path/.release.sh"
  source "$project_path/.release.sh"
  if [[ -z "$PROJECT_NAME" ]]; then
    echo-exit 1 "PROJECT_NAME not set"
  fi
  project_name=$PROJECT_NAME

  branch=$(git-current-branch)
  local staging_tag_prefix="$project_name/$branch-staging/"

  # check params
  if [[ -z $project_path ]]; then
    echo-exit 1 "project path is required"
  fi

  project_version=$(get-staging-version "$staging_tag_prefix")
  staging_tag="$staging_tag_prefix$project_version"

  ## TODO: a better way to check if the header was a distributed head
  # # check if HEAD was already staged
  # if (git tag --points-at HEAD | grep -q "$staging_tag"); then
  #   echo-exit 1 "HEAD was already staged"
  # fi

  # verify HEAD sources (like lint or tests)
  echo-log info "verifying HEAD"
  cd "$project_path"
  if ! call-or-ignore verify-staging-sources "$project_version"; then
    echo-exit 1 "failed to verify HEAD"
  fi
  cd "$WORKING_DIR"

  # build HEAD sources
  echo-log success "HEAD is good, building HEAD"
  cd "$project_path"
  if ! call-or-ignore build-staging-sources "$project_version" ; then
    echo-exit 1 "failed to build HEAD sources"
  fi
  cd "$WORKING_DIR"

  # move staging tag to HEAD
  echo-log info "removing tag $staging_tag"
  git-delete-tag "$staging_tag"

  echo-log info "adding tag $staging_tag to HEAD"
  git tag "$staging_tag"

  echo-log info "pushing changes to origin"
  git push
  git push --tags

  # distribute build results
  echo-log info "distributing staging assets"
  cd "$project_path"
  if ! call-or-ignore distribute-staging-assets "$project_version" "$staging_tag"; then
    echo-exit 1 "failed to distribute staging assets"
  fi
  cd "$WORKING_DIR"
  echo-log success "assets distributed"
}

function release() {
  assert-work-tree-clean
  git-fetch-tags

  local project_path=$1
  local branch
  local project_version
  local next_version
  local staging_tag
  local release_tag
  local next_staging_tag

  # load scripts provided by project
  echo-log log "loading $project_path/.release.sh"
  source "$project_path/.release.sh"
  if [[ -z "$PROJECT_NAME" ]]; then
    echo-exit 1 "PROJECT_NAME not set"
  fi
  project_name=$PROJECT_NAME

  branch=$(git-current-branch)
  local staging_tag_prefix="$project_name/$branch-staging/"

  # check params
  if [[ -z $project_path ]]; then
    echo-exit 1 "project path is required"
  fi

  # if HEAD was released
  if (git tag --points-at HEAD | grep -q "$project_name/release/"); then
    echo-exit 1 "HEAD was already released"
  fi

  project_version=$(get-staging-version "$staging_tag_prefix")
  next_version=$(bump-version "$project_version")
  staging_tag="$staging_tag_prefix$project_version"
  next_staging_tag="$staging_tag_prefix$next_version"
  release_tag="$project_name/release/$project_version"

  # if HEAD was staged
  if ! (git tag --points-at HEAD | grep -q "$staging_tag"); then
    echo-exit 1 "HEAD was not staged"
  fi

  echo-log log "releasing project $project_name @ $project_version"

  # verify HEAD sources (like lint or tests)
  echo-log info "verifying HEAD"
  cd "$project_path"
  if ! call-or-ignore verify-releasing-sources "$project_version"; then
    echo-exit 1 "failed to verify HEAD"
  fi
  cd "$WORKING_DIR"

  # set next release version
  echo-log info "updating version to release version"
  cd "$project_path"
  if ! call-or-ignore set-releasing-version "$project_version"; then
    echo-exit 1 "failed to update version"
  fi
  cd "$WORKING_DIR"
  if ! work-tree-clean; then
    echo-log warn "set-release-version didn't commit version changes, release.sh will commit it with default message"
    git commit -am "release($project_name): $project_version"
  fi

  # build HEAD sources
  echo-log info "building release assets"
  cd "$project_path"
  if ! call-or-ignore build-releasing-sources "$project_version"; then
    echo-exit 1 "failed to build HEAD sources"
  fi
  cd "$WORKING_DIR"

  # remove staging tag for current version
  echo-log info "removing tag $staging_tag"
  git-delete-tag "$staging_tag"

  echo-log info "adding tag $release_tag"
  git tag "$release_tag"

  echo-log info "pushing changes to origin"
  git push
  git push --tags

  # distribute build results
  echo-log info "distributing staging assets"
  cd "$project_path"
  if ! call-or-ignore distribute-releasing-assets "$project_version" "$release_tag" "$staging_tag"; then
    echo-exit 1 "failed to distribute staging assets"
  fi
  cd "$WORKING_DIR"

  # set next staging version
  echo-log info "iterating version to $next_version, this step should create a new commit with a new version"
  cd "$project_path"
  if ! call-or-ignore set-staging-version "$next_version" "$project_version"; then
    echo-exit 1 "failed to update version"
  fi
  cd "$WORKING_DIR"
  if ! work-tree-clean; then
    echo-log warn "set-staging-version didn't commit version changes, release.sh will commit it with default message"
    git commit -am "chore($project_name): bump staging version to $next_version"
  fi

  echo-log info "adding tag $next_staging_tag"
  git tag "$next_staging_tag"
  git push
  git push --tags
}

case $1 in
init)
  init "${@:2}"
  exit 0
  ;;
deinit)
  deinit "${@:2}"
  exit 0
  ;;
release)
  release "${@:2}"
  exit 0
  ;;
stage)
  stage "${@:2}"
  exit 0
  ;;
esac

print-usage
exit 1
