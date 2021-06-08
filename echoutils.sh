declare -A LOG_COLORS
LOG_COLORS=(
  ["log"]=7
  ["info"]=117
  ["error"]=9
  ["warn"]=3
  ["success"]=2
)

function echo-exit() {
  local exit_code=$1
  echo-log error "${*:2}" >&2
  exit "$exit_code"
}

function echo-log() {
  local color=${LOG_COLORS[$1]:-6}

  printf "\u001b[38;5;%s;1m[%7s][release.sh] %s\u001b[0m: %s\n" "$color" "$1" "$(date "+%F %T")" "${*:2}"
}
