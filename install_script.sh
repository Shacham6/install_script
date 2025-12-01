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

_is_on_mac() {
	[ "$(ostype)" = "mac" ]
}

_on_mac() {
	if _is_on_mac; then
		${*}
	fi
}

_is_on_arch() {
	[ "$(ostype)" = "arch" ]
}

_on_arch() {
	if [[ "$(ostype)" -eq "arch" ]]; then
		${*}
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

_when_missing() {
	if _not_exists ${1}; then
		${*:2}
	fi
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
	printf " ## ----> Installing $(yellow ${1})..."
}

msg_install_ok() {
	printf " ## ----> $(yellow ${1}) was $(green installed successfully)\n"
}

msg_install_err() {
	printf " ## ----> $(yellow ${1}) installation has $(red failed)\n"
	return 1
}

msg_fenced() {
	_screen_fence
	printf "${*}"
	_screen_fence
}

# nl is just newline
nl() {
	printf "\n"
}

if _is_on_mac; then  # Making the brew installs non-interactive
	export NONINTERACTIVE=1
fi

# Installing Brew on mac.

if _is_on_mac; then
	msg_installing brew
	_when_missing brew /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	msg_fenced "you might need to do extra things like add this in path"
	msg_install_ok brew
fi

# Intalling yay on arch.

if _is_on_arch; then
	msg_installing yay
	sudo pacman -Syu --noconfirm
	sudo pacman -S --noconfirm --needed base-devel git

	git clone https://aur.archlinux.org/yay.git
	cd yay

	makepkg -si

	_which yay && msg_install_ok yay || msg_install_err yay
fi

# Installing git.

if _not_exists git; then
	msg_installing git
	_on_mac brew install git && msg_install_ok git || msg_install_err git

	if _is_on_arch; then
		sudo pacman -Syu --no-confirm
		sudo pacman -S --no-confirm git
	fi
fi

