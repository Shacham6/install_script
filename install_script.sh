#!/usr/bin/env sh

set -euo pipefail

## Some infrastructure functions

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
	if [[ "$(ostype)" = "arch" ]]; then
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

_on_missing() {
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

_run() {
	name=${1}
	msg_installing ${1}
	printf "\n"
	if ${2} ; then
		msg_install_ok ${1}
		return 0

	fi
	msg_install_err ${1}
	return 1
}

if _is_on_mac; then  # Making the brew installs non-interactive
	export NONINTERACTIVE=1
fi

# Installing Brew on mac.

_install_brew() {
	if ! _is_on_mac; then
		return 0
	fi
	_on_missing brew /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	msg_fenced "you might need to do extra things like add this in path"
}
_run brew _install_brew

_install_yay() {
	if ! _is_on_arch; then
		return 0
	fi
	msg_installing yay
	sudo pacman -Syu --noconfirm
	sudo pacman -S --noconfirm --needed base-devel git

	git clone https://aur.archlinux.org/yay.git
	cd yay

	makepkg -si

	_which yay
}

_run yay _install_yay

# Installing git.

_install_git() {
	if  _which git ; then
		return 0
	fi
	_on_mac brew install git
	if _is_on_arch; then
		sudo pacman -Syu --noconfirm
		sudo pacman -S --noconfirm git
	fi
}

_run git _install_git

_install_stow() {
	if _which stow; then
		return 0
	fi

	_on_mac brew install stow
	_on_arch yay -S --noconfirm stow
}

_run stow _install_stow

_install_gh() {
	if _which gh; then
		return 0
	fi

	_on_mac brew install gh
	_on_arch yay -S --noconfirm github-cli-bin
	if ! _which gh; then
		echo "Attempted installing gh but I can't see it in path. something might be wrong"
		return 1
	fi
}

_install_gh_auth() {
	if gh auth status >/dev/null 2>/dev/null ; then
		msg_fenced "github cli is configured"
		return 0
	fi


# echo "==== IN ORDER TO CLONE DOTFILES LATER, YOU WILL NEED TO LOG IN TO YOUR GITHUB ACCOUNT ===="
	echo " If you need to quit for now in order to generate ssh keys, you can. Simply re-do the installation of the machine and you'll be back here in no time."
	gh auth login -p ssh --hostname github.com
	gh auth setup-git
}

_run gh _install_gh \
	&& _run "gh authentication" _install_gh_auth

_install_zen_browser() {
	if _which zen-browser; then
		return 0
	fi

	_on_mac brew install --cask zen-browser
	_on_arch yay -S --noconfirm zen-browser-bin
}
_run zen-browser _install_zen_browser

_install_ghostty() {
	if _which ghostty; then
		return 0
	fi

	_on_mac brew install --cask ghostty
	_on_arch yay -S --noconfirm ghostty
}
_run ghostty _install_ghostty

_install_tailscale() {
	if which tailscale; then
		return 0
	fi

	if _is_on_mac; then
		brew install --formula tailscale
		brew install tailscale-app
		sudo brew services start tailscale
	fi

	if _is_on_arch; then
		sudo pacman -S --noconfirm tailscale
		sudo systemctl enable --now tailscaled
	fi
}
_run tailscale _install_tailscale

_install_fzf() {
	if which fzf; then
		return 0
	fi
	_on_mac brew install fzf
	_on_arch yay -S fzf-bin
}
_run fzf _install_fzf

_install_dotfiles() {
	if ! [[ -d ~/dotfiles/ ]]; then
		git clone git@github.com:Shacham6/dotfiles.git ~/dotfiles
	fi

	echo "placing dotfiles"
	pushd ~/dotfiles
	if _is_on_mac; then
		echo "placing mac things"
		./stow.sh zsh
		./stow.sh yabai
		./stow.sh tmux
		./stow.sh skhd
		./stow.sh sketchybar
		./stow.sh nvim
		./stow.sh ghostty_mac
		./stow.sh aerospace
		./stow.sh ghostty_mac
		./stow.sh wezterm_mac
	fi

	if _is_on_arch; then
		if [[ -d ~/.config/waybar/ ]]; then
			mv -f ~/.config/waybar/ ~/.config/waybar-bak
			./stow.sh waybar
		fi

		if [[ -d ~/.config/tmux ]]; then
			mv -f ~/.config/tmux ~/.config/tmux-bak
			./stow.sh tmux
		fi

		if [[ -d ~/.config/nvim/ ]]; then
			mv -f ~/.config/nvim ~/.config/nvim-bak
			./stow.sh nvim
		fi

		if [[ -d ~/.config/ghostty/ ]]; then
			mv -f ~/.config/ghostty/ ~/.config/ghostty-bak
			./stow.sh ghostty_omarchy
		fi

		if [[ -d ~/.config/hypr/ ]]; then
			mv -f ~/.config/hypr ~/.config/hypr-bak
			./stow.sh hypr_omarchy
		fi

		./stow.sh wezterm_arch
	fi
	popd
}
_run dotfiles _install_dotfiles

_install_asdf() {
	_on_missing asdf _on_mac brew install asdf
	_on_missing asdf _on_arch yay -S --noconfirm asdf

	msg_fenced "you will need to add 'export PATH=\${PATH}:\${HOME}/.asdf/shims' to your zshrc"
}

_run asdf _install_asdf

_install_nvim() {
	_on_missing nvim _on_mac brew install neovim
	_on_missing nvim _on_arch yay -S --noconfirm neovim
}

_run neovim _install_nvim

_install_tmux() {
	_on_missing tmux _on_mac brew install tmux
	_on_missing tmux _on_arch yay -S --noconfirm tmux
}

_install_tmux_tpm() {
	if  [[ -d ~/.tmux/plugins/tpm/ ]]; then
		return 0
	fi
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   msg_fenced "Might need to enter tmux and press <C-Space>I "
}

_run tmux _install_tmux \
	&& _run "tmux plugin manager" _install_tmux_tpm

_install_zsh() {
	_on_missing zsh _on_mac brew install zsh
	_on_missing zsh _on_arch yay -S --noconfirm zsh
}

_install_make_zsh_default_shell() {
	if ! _which zsh ; then
		printf " ## ----> Can't find zsh installation, so can't make it default"
		return 1
	fi

	# Assuming that the current shell is the default shell.
	if [ "$SHELL" = "$(which zsh)" ]; then
		printf " ## ----> zsh is already the default shell\n"
		return 0
	fi

	chsh -s $(which zsh)
}

_install_oh_my_zsh() {
	if [[ -d ~/.oh-my-zsh ]]; then
		return 0
	fi

	RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

_run zsh _install_zsh \
	&& _run "make-zsh-default-shell" _install_make_zsh_default_shell \
	&& _run "oh-my-zsh" _install_oh_my_zsh

_install_zoom() {
	_on_missing zoom _on_mac brew install zoom
}

_run zoom _install_zoom

_install_docker() {
	if _which docker; then
		return 0
	fi

	if _is_on_mac; then
		brew install --cask docker
	fi

	if _is_on_arch; then
		sudo pacman -S --noconfirm docker
		sudo systemctl enable --now docker
		sudo usermod -aG docker $USER
		msg_fenced "You may need to log out and back in for docker group membership to take effect"
	fi
}
_run docker _install_docker

_install_yabai() {
	if _which yabai; then
		return 0
	fi
	brew install koekeishiya/formulae/yabai

	yabai --install-service

	MESSAGE=$(cat<<EOT
yabai is installed but not yet active until you set the relevant sudoers things.
consult the official guide here: https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(latest-release)
afterwards activate yabai (& skhd) by running 'yabai --start-service && skhd --start-service'
EOT
)

	msg_fenced "${MESSAGE}"
}

_on_mac install_func yabai _install_yabai

_install_skhd() {
	if _which skhd; then
		return 0
	fi
	brew install koekeishiya/formulae/skhd

	skhd --install-service
	msg_fenced "when ready, run 'skhd --start-service'"
}

_on_mac install_func skhd _install_skhd

_install_fonts() {
	_on_mac brew install font-jetbrains-mono-nerd-font
	_on_mac brew install font-hack-nerd-font
}
_run fonts _install_fonts

_install_sketchybar() {
	if _which sketchybar; then
		return 0
	fi

	brew tap FelixKratz/formulae
	brew install sketchybar
	brew services start sketchybar
}

_on_mac install_func sketchybar _install_sketchybar

_install_yq() {
	_on_missing yq _on_mac brew install yq
	_on_missing yq _on_arch yay -S --noconfirm yq
}
_run yq _install_yq

_install_rg() {
	_on_missing rg _on_mac brew install ripgrep
	_on_missing rg _on_arch yay -S --noconfirm ripgrep
}
_run rg _install_rg
