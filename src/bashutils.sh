function call-or-ignore() {
  local func=$1

  if ! type "$func" >null; then
    echo-log log "$func was not provided by .release.sh"
    return 0
  fi

  $func "${@:2}"
  return $?
}
