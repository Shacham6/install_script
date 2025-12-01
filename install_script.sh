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

title() {
	local width=$(tput cols)
	printf "\n"
	printf '%*s' "$width" '' | tr ' ' '='
	printf "\n  %s\n" "${*}"
	printf '%*s' "$width" '' | tr ' ' '='
	printf "\n\n"
}

title "installing git..."


