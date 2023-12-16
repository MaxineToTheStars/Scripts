# Fail on error
set -e

# Refresh the package list
sudo apt-get --assume-yes --no-install-recommends \
--no-install-suggests \
update

# Update the base system
sudo apt-get --assume-yes --verbose-versions \
--show-progress --no-install-recommends \
--no-install-suggests \
upgrade

# Add Box86/64 mirror entry
sudo wget https://ryanfortner.github.io/box64-debs/box64.list -O /etc/apt/sources.list.d/box64.list
wget -qO- https://ryanfortner.github.io/box64-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box64-debs-archive-keyring.gpg

sudo wget https://ryanfortner.github.io/box86-debs/box86.list -O /etc/apt/sources.list.d/box86.list
wget -qO- https://ryanfortner.github.io/box86-debs/KEY.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/box86-debs-archive-keyring.gpg

# Allow aarch64 to run armhf
sudo dpkg --add-architecture armhf

# Refresh the package list
sudo apt-get --assume-yes --no-install-recommends \
--no-install-suggests \
update

# Install box86/64
sudo apt-get --assume-yes --verbose-versions \
--show-progress --no-install-recommends \
--no-install-suggests \
install box64-arm64 box86-generic-arm:armhf