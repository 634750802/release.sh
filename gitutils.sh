# Assert that git work tree is clean
function assert-work-tree-clean() {
  if [[ -n $(git status -s) ]]; then
    echo-exit 1 "work tree is not clean"
  fi
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
}

function git-delete-tag() {
  local tag=$1
  git tag -d "$tag"
  git push --delete origin "$tag"
}
