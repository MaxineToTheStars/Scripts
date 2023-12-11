#!/usr/bin/env bash

# Fail on error
set -e

# File Docstring
# --------------
# Installs the GNOME Desktop Environment on Debian systems. The selected packages are
# meant for AArch64 devices. Tested on ThinkPad X13s Gen 1
#
# Author: https://github.com/MaxineToTheStars
# Last Updated On: 11/12/23
# -----------------------------------------------------------------------------------

# Constants
CONSTANT_DIRECTORY_ROOT="${PWD}"
CONSTANT_DIRECTORY_RESOURCES="${CONSTANT_DIRECTORY_ROOT}/resources/"
CONSTANT_THEMING_CATPPUCCIN_GTK_THEME_VERSION="0.7.1"

# Variables
THEMING_CATPPUCCIN_GTK_THEME="Catppuccin-Frappe-Standard-Red-Dark"
THEMING_CATPPUCCIN_CURSORS_THEME="Catppuccin-Frappe-Red-Cursors"
THEMING_CATPPUCCIN_PAPIRUS_ICONS_FOLDER_COLOR="cat-frappe-red"
THEMING_MINEGRUB_BACKGROUND_IMAGE_URL=""

# Main
function main() {
	# Show startup message
	_ui_show_startup_message
	
	# Show user the installation prompt
	_ui_show_user_installation_type_prompt
}

# Methods
# Allows for printing to console with specialized character formatting
function _utils_print_to_console() {
	echo -e $1 
}

# Shows the script's startup message
function _ui_show_startup_message() {
	_utils_print_to_console "Type: Post-Installation\nArchitecture: AArch64\nBase: Debian\nDesktop: GNOME"
	_utils_print_to_console "-----------------------"
}

# Shows the installation type prompt
function _ui_show_user_installation_type_prompt() {
	# Show available options
	_utils_print_to_console "(1) Install GNOME\n(2) Configure GNOME Extensions\n(3) Change GNOME Theme"

	# Retrieve user input
	userSelection=""
	read -p ":" -n 2 userSelection

	# Check the input
	if [[ "${userSelection}" == "1" ]]; then
		_installer_install_gnome_desktop_environment
		elif [[ "${userSelection}" == "2" ]]; then
		_utils_print_to_console $userSelection
		elif [[ "${userSelection}" == "3" ]]; then
		_utils_print_to_console $userSelection
	fi
}

# Installs the GNOME Desktop Environment
function _installer_install_gnome_desktop_environment() {
	# Configure the environment
	_installer_configure_environment_for_installation

	# Install packages
	_installer_install_all_packages

	# Configure the system
	_installer_configure_environment_post_installation

	# Theme the system
	_installer_theme_system_to_user_specification

	# Finalization
	_installer_finalize_system_installation
}

# Configures the environment for installation
function _installer_configure_environment_for_installation() {
	# Add ignore list of packages
	sudo cp --recursive --update --verbose $CONSTANT_DIRECTORY_RESOURCES/apt/* /etc/apt/preferences.d/

	# Refresh the package list
	sudo apt-get --assume-yes --no-install-recommends \
	--no-install-suggests \
	update

	# Update the base system
	sudo apt-get --assume-yes --verbose-versions \
	--show-progress --no-install-recommends \
	--no-install-suggests \
	upgrade
}

# Installs all packages (Native .deb and Flatpak)
function _installer_install_all_packages() {
	# Install native packages
	sudo apt-get --assume-yes --verbose-versions \
	--show-progress --no-install-recommends \
	--no-install-suggests \
	install $(awk '{print $1}' $CONSTANT_DIRECTORY_RESOURCES/packages/base-packages.txt)

	# Configure Flatpak
	echo $(flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo)

	# Install Flatpak apps
	flatpak install --assumeyes flathub \
	$(awk '{print $1}' $CONSTANT_DIRECTORY_RESOURCES/packages/flatpak-packages.txt)
}

# Configures the evenrioemnt after installing packages
function _installer_configure_environment_post_installation() {
	# Copy over all files under /resources/udev
	sudo cp --recursive --update --verbose $CONSTANT_DIRECTORY_RESOURCES/udev/*.rules /etc/udev/rules.d

	# Configure Avahi NSS
	sudo sed --in-place "s|^hosts:.*|hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns|" /etc/nsswitch.conf

	# GNOME GSettings
	# Mutter
	gsettings set org.gnome.mutter center-new-windows true
	gsettings set org.gnome.mutter attach-modal-dialogs false
	
	# Shell
	gsettings set org.gnome.shell favorite-apps "['']"
	gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Super>s']"
	
	# Desktop Configuration
	gsettings set org.gnome.desktop.calendar show-weekdate true
	# <-- -->
	gsettings set org.gnome.desktop.interface clock-format 12h
	gsettings set org.gnome.desktop.interface clock-show-date true
	gsettings set org.gnome.desktop.interface clock-show-seconds true
	gsettings set org.gnome.desktop.interface clock-show-weekday true
	gsettings set org.gnome.desktop.interface color-scheme prefer-dark
	gsettings set org.gnome.desktop.interface font-antialiasing rgba
	gsettings set org.gnome.desktop.interface show-battery-percentage true
	# <-- -->
	gsettings set org.gnome.desktop.peripherals.mouse accel-profile flat
	gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
	gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
	# <-- -->
	gsettings set org.gnome.desktop.sound event-sounds false
	gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,maximize,close
	
	# App configuration
	gsettings set org.gnome.nautilus.preferences default-sort-order 'type'
	gsettings set org.gnome.nautilus.preferences show-hidden-files true
	gsettings set org.gnome.tweaks show-extensions-notice false

	# Daemon configuration
	gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 12.0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 12.0
	gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3700

	# Flatpak environment configuration
	flatpak override --user --env=GTK_THEME=$THEMING_CATPPUCCIN_GTK_THEME
	flatpak override --user --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.firefox
	flatpak override --user --env=FLATPAK_ENABLE_SDK_EXT=openjdk,node18,rust-stable com.visualstudio.code
	flatpak override --user --filesystem="${HOME}/.icons:ro" --filesystem="${HOME}/.themes:ro" --filesystem="xdg-run/app/com.discordapp.Discord:create"

	# Copy Windows Fonts (perfectly legal)
	sudo cp --recursive --update --verbose $CONSTANT_DIRECTORY_RESOURCES/fonts/windows-fonts/ /usr/share/fonts
	sudo chmod 664 /usr/share/fonts/windows-fonts/*
	sudo fc-cache --force
}

# Themes the system to the specified user parameters
function _installer_theme_system_to_user_specification() {
	# Enable "user-theme" GNOME extension
	gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com

	# Create the ~.themes and ~.icons directories
	mkdir --parents "${HOME}/.themes"
	mkdir --parents "${HOME}/.icons"
	mkdir --parents "${HOME}/.config/gtk-4.0"

	#<-- Minegrub Configuration -->#
	# Clone the repository
	git clone https://github.com/Lxtharia/minegrub-theme.git
	# Download the custom background image if supplied
	if [ $THEMING_MINEGRUB_BACKGROUND_IMAGE_URL != '' ]; then curl --output ./minegrub-theme/minegrub/background.png $THEMING_MINEGRUB_BACKGROUND_IMAGE_URL; fi
	# Convert to .png
	mogrify -format png ./minegrub-theme/minegrub/background.png
	# Blur the .png
	convert ./minegrub-theme/minegrub/background.png -blur 0x8 ./minegrub-theme/minegrub/background.png
	# Copy the theme files
	sudo cp --recursive --update --verbose ./minegrub-theme/minegrub /boot/grub/themes/
	# Copy the systemd service file
	sudo cp ./minegrub-theme/minegrub-update.service /etc/systemd/system
	# Edit /etc/default/grub configuration file
	echo "GRUB_THEME="/boot/grub/themes/minegrub/theme.txt"" | sudo tee --append /etc/default/grub
	# Re-generate grub configuration
	sudo grub-mkconfig --output /boot/grub/grub.cfg
	# Enable Minegrub systemd service
	sudo systemctl enable minegrub-update.service
	# Clean up
	rm --recursive --force ./minegrub-theme

	#<-- Catppuccin Configuration -->#
	# Download the .zip file
	curl --location --output $THEMING_CATPPUCCIN_GTK_THEME.zip https://github.com/catppuccin/gtk/releases/download/v$CONSTANT_THEMING_CATPPUCCIN_GTK_THEME_VERSION/$THEMING_CATPPUCCIN_GTK_THEME.zip
	# Unzip the theme file
	unzip $THEMING_CATPPUCCIN_GTK_THEME.zip
	# Delete unnecessary alternative themes
	rm --recursive --force $THEMING_CATPPUCCIN_GTK_THEME-*
	# Delete the base .zip file
	rm --recursive --force $THEMING_CATPPUCCIN_GTK_THEME.zip
	# Move the folder to the ~/.themes directory
	cp --recursive --update --verbose $THEMING_CATPPUCCIN_GTK_THEME $HOME/.themes
	# Set the theme (GTK3+)
	gsettings set org.gnome.desktop.interface gtk-theme $THEMING_CATPPUCCIN_GTK_THEME
	gsettings set org.gnome.shell.extensions.user-theme name $THEMING_CATPPUCCIN_GTK_THEME
	# Set the theme (GTK4+)
	ln --symbolic --force $HOME/.themes/$THEMING_CATPPUCCIN_GTK_THEME/gtk-4.0/assets $HOME/.config/gtk-4.0/assets
	ln --symbolic --force $HOME/.themes/$THEMING_CATPPUCCIN_GTK_THEME/gtk-4.0/gtk.css $HOME/.config/gtk-4.0/gtk.css
	ln --symbolic --force $HOME/.themes/$THEMING_CATPPUCCIN_GTK_THEME/gtk-4.0/gtk-dark.css $HOME/.config/gtk-4.0/gtk-dark.css
	# Clean up
	rm --recursive --force $THEMING_CATPPUCCIN_GTK_THEME

	#<-- Papirus Icons Configuration -->#
	# Download the .tar.gz file
	curl --location --output Papirus.tar.gz https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/master.tar.gz
	# Extract the tarball
	tar --extract --ungzip --file Papirus.tar.gz
	# Move the folder to the ~/.icons directory
	cp --recursive --update --verbose ./papirus-icon-theme-master/Papirus $HOME/.icons
	# Set the icon theme
	gsettings set org.gnome.desktop.interface icon-theme Papirus
	# Clean up
	rm --recursive --force Papirus.tar.gz papirus-icon-theme-master

	#<-- Papirus Catppuccin Icons Configuration -->#
	# Clone the repository
	git clone https://github.com/catppuccin/papirus-folders.git
	# Copy the new colors to the ~/.icons folder
	cp --recursive --update --verbose ./papirus-folders/src/* $HOME/.icons/Papirus
	# Set the color theme
	./papirus-folders/papirus-folders -C $THEMING_CATPPUCCIN_PAPIRUS_ICONS_FOLDER_COLOR --theme Papirus
	# Clean up
	rm --recursive --force ./papirus-folders

	#<-- Catppuccin Cursor Icons Configuration -->#
	# Clone the repository
	git clone https://github.com/catppuccin/cursors.git
	# Unzip the file to ~/.icons
	unzip ./cursors/cursors/$THEMING_CATPPUCCIN_CURSORS_THEME.zip -d $HOME/.icons
	# Set the theme
	gsettings set org.gnome.desktop.interface cursor-theme $THEMING_CATPPUCCIN_CURSORS_THEME
	# Clean up
	rm --recursive --force ./cursors
}

# Wraps up and cleans the system
function _installer_finalize_system_installation() {
	# Add user to uucp group
	sudo usermod -aG uucp $USER

	# Show done message
	_utils_print_to_console "Done!"
}

# Executer
main