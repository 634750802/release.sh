function bump-version() {
  local current_version_prefix
  local current_version

  current_version_prefix=$(echo "$1" | grep -E -o "^.+\.")
  current_version=$(echo "$1" | grep -E -o "[^.]+$")

  echo "$current_version_prefix$(( "$current_version" + 1))"
}
