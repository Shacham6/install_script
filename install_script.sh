#!/usr/bin/env sh

set -euo pipefail

ostype() {
	if [[ "$OSTYPE" == darwin* ]]; then
	  echo "mac"
	elif [[ "$OSTYPE" == linux* ]]; then
	  echo "arch"
	else
	  echo "os type unrecognized!" >&2
	  exit 1
	fi
}

_which() {
	if [[ "${#}" -eq 0 ]]; then
		echo "_whitch requires an argument" >&2
		exit 1
	fi

	which -s "${*}" >/dev/null 2>/dev/null
}

_not_exists() {
	if [[ "${#}" -eq 0 ]]; then
		echo "_not_exists requires an argument for a binary name"
	fi

	if _which ${*} ; then
		return 1
	fi
	return 0
}

_screen_fence() {
	local width=$(tput cols)
	printf "\n"
	printf '%*s' "$width" '' | tr ' ' '='
	printf "\n"
}

yellow() {
	printf '\033[33m%s\033[0m' "${*}"
}
green() {
	printf '\033[32m%s\033[0m' "${*}"
}
red() {
	printf '\033[31m%s\033[0m' "${*}"
}

msg_installing() {
	printf " ## ----> Installing $(yellow ${1})...\n"
}

msg_install_ok() {
	printf " ## ----> $(yellow ${1}) was $(green installed successfully)\n"
}

msg_install_err() {
	printf " ## ----> $(yellow ${1}) installation has $(red failed)\n"
}

msg_fenced() {
	_screen_fence
	printf "${*}"
	printf "\n"
	_screen_fence
}

msg_installing "git"
msg_install_ok "git"
msg_install_err "git"
