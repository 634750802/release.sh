export PROJECT_NAME=release.sh

function get-mod() {
  if [[ "$OSTYPE" == "linux"* ]]; then
    stat --format '%a' "$1"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    stat -f "%OLp" "$1"
  else
    echo-exit 2 "$OSTYPE not supported"
  fi
}

function build-release-note() {
  local log
  # shellcheck disable=SC2046
  log=$(git-pretty-log $(git-last-releases))
  echo "# Release Notes"
  echo "## Features"
  echo ""
  echo "$log" | grep -E "\s+feat(\([^)]+\))?:" | sed -e 's/^/- /'
  echo ""
  echo ""
  echo "## Bug fixes"
  echo ""
  echo "$log" | grep -E "\s+fix(\([^)]+\))?:" | sed -e 's/^/- /'
  echo ""
  echo ""
  echo "## Optimizes"
  echo ""
  echo "$log" | grep -E "\s+opt(\([^)]+\))?:" | sed -e 's/^/- /'
  echo ""
  echo ""
  echo "## Others"
  echo ""
  echo "$log" | grep -vE "\s+(feat|fix|opt|release)(\([^)]+\))?:" | grep -E "." | sed -e 's/^/- /'
}

function init-staging-version() {
  set-staging-version "$1"
  return $?
}

function deinit-staging-version() {
  gh release delete -y "$2"
  return $?
}

function verify-staging-sources() {
  echo-log success "nothing to verify for release.sh, it's a bash project"
  echo-log todo "i will add [shellcheck](https://github.com/koalaman/shellcheck) later"
  return 0
}

function build-staging-sources() {
  zip "release.sh.$1.staging.zip" ./*.sh
  return 0
}

function distribute-staging-assets() {
  local filename="release.sh.$1.staging.zip"

  gh release delete -y "$2"
  if ! gh release create -p "$2" "$filename" --title "$1-staging" --notes "$(build-release-note)"; then
    return 1
  fi

  rm "$filename"
  return 0
}

function verify-releasing-sources() {
  echo-log success "nothing to verify for release.sh, it's a bash project"
  echo-log todo "i will add [shellcheck](https://github.com/koalaman/shellcheck) later"
  return 0
}

function build-releasing-sources() {
  zip "release.sh.$1.zip" ./*.sh
  return 0
}

function distribute-releasing-assets() {
  local filename="release.sh.$1.zip"

  # release assets wherever you want other than github
  gh release delete -y "$3"
  if ! gh release create "$2" "$filename" --title "$1" --notes "$(build-release-note)"; then
    return 1
  fi

  rm "$filename"
  return 0
}

function set-releasing-version() {
  local new_version=$1
  local fmod
  fmod=$(get-mod release.sh)
  sed "s/RELEASE_SH_VER=.*/RELEASE_SH_VER=$new_version/" release.sh >release.sh.1
  mv release.sh.1 release.sh
  chmod "$fmod" release.sh
  return $?
}

function set-staging-version() {
  local new_version=$1
  local fmod
  fmod=$(get-mod release.sh)
  sed "s/RELEASE_SH_VER=.*/RELEASE_SH_VER=$new_version-STAGING/" release.sh >release.sh.1
  mv release.sh.1 release.sh
  chmod "$fmod" release.sh
  return $?
}
