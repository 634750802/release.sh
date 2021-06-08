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

  gh release delete -y "$1-staging"
  gh release create -p "$1-staging" "$filename"

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
  gh release create "$1" "$filename"

  rm "$filename"
  return 0
}

function set-release-version() {
  local new_version=$1
  local fmod
  fmod=$(stat -f "%OLp" release.sh)
  sed "s/RELEASE_SH_VER=.*/RELEASE_SH_VER=$new_version/" release.sh >release.sh.1
  mv release.sh.1 release.sh
  chmod "$fmod" release.sh
  return $?
}

function set-staging-version() {
  local new_version=$1
  local fmod
  fmod=$(stat -f "%OLp" release.sh)
  sed "s/RELEASE_SH_VER=.*/RELEASE_SH_VER=$new_version-STAGING/" release.sh >release.sh.1
  mv release.sh.1 release.sh
  chmod "$fmod" release.sh
  return $?
}
