#!/usr/bin/env bash
set -e

# Install eza (modern ls replacement)
mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
apt-get update -qq
apt-get install -y -qq eza
rm -f /etc/apt/sources.list.d/gierens.list /etc/apt/keyrings/gierens.gpg
apt-get clean
rm -rf /var/lib/apt/lists/*

# Install modern CLI tools
curl -fsSL https://starship.rs/install.sh | sh -s -- -y
curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh -s -- --bin-dir /usr/local/bin --man-dir /usr/local/share/man
git clone --depth 1 https://github.com/junegunn/fzf.git /tmp/fzf
/tmp/fzf/install --bin && cp /tmp/fzf/bin/fzf /usr/local/bin

# Apply system configurations
sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc
echo 'Defaults !fqdn' > /etc/sudoers.d/no-fqdn
chmod 0440 /etc/sudoers.d/no-fqdn

rm -rf /tmp/*

