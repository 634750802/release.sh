# Assert that git work tree is clean
function assert-work-tree-clean() {
  if [[ -n $(git status -s) ]]; then
    echo-exit 1 "work tree is not clean"
  fi
}

function git-fetch-tags() {
  git fetch --tags
  return $?
}

function work-tree-clean() {
  if [[ -z $(git status -s) ]]; then
    return 0
  else
    return 1
  fi
}

function git-current-branch() {
  local branch
  branch=$(git symbolic-ref -q --short HEAD)

  if [[ -z $branch ]]; then
    echo-exit 1 "HEAD is detached, please checkout a certain branch"
  fi

  echo "$branch"
}

function git-delete-tag() {
  local tag=$1
  git tag -d "$tag"
  git push --delete origin "$tag"
}

function git-tag-exists() {
  git tag -l | grep -q -e "$1"
  return $?
}

function git-last-release() {
  git tag -l | sort -r | grep "/release/" | head -1
  return $?
}

function git-pretty-log() {
  local start=$1
  local end=$2
  local range
  if [[ -z "$end" ]]; then
    end=HEAD
  fi
  if [[ -z "$start" ]]; then
    range="$end"
  else
    range="$start...$end"
  fi
  git log --pretty=format:"[%h] %s <@%an>" "$range"
  return $?
}
