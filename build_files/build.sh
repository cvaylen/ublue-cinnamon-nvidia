#!/bin/bash
set -ouex pipefail

cp -avf "/ctx/system_files"/. /

dnf5 -y group install cinnamon-desktop
dnf5 -y install lightdm slick-greeter   # the group pulls slick-greeter but not lightdm itself
systemctl enable lightdm.service
systemctl set-default graphical.target

dnf5 -y install \
    android-tools \
    bcc \
    bpftop \
    bpftrace \
    ccache \
    flatpak-builder \
    git-subtree \
    google-noto-sans-fonts \
    nicstat \
    numactl \
    podman-machine \
    podman-tui \
    ramalama \
    restic \
    rclone \
    sysprof \
    tiptop \
    usbmuxd \
    waypipe \
    zsh

dnf5 --setopt=install_weak_deps=False -y install \
    qemu \
    qemu-kvm \
    libvirt \
    virt-manager \
    virt-install \
    virt-viewer \
    edk2-ovmf \
    guestfs-tools

dnf5 config-manager addrepo --from-repofile="https://packages.microsoft.com/yumrepos/vscode/config.repo"
dnf5 config-manager setopt vscode-yum.enabled=0
dnf5 -y install --enable-repo="vscode-yum" code

dnf5 config-manager addrepo --from-repofile="https://download.docker.com/linux/fedora/docker-ce.repo"
dnf5 config-manager setopt docker-ce-stable.enabled=0
dnf5 -y install --enable-repo="docker-ce-stable" \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin

mkdir -p /etc/modules-load.d
echo iptable_nat > /etc/modules-load.d/ip_tables.conf

dnf5 config-manager addrepo --from-repofile="https://negativo17.org/repos/fedora-steam.repo"
dnf5 config-manager setopt fedora-steam.enabled=0
dnf5 -y install --enable-repo="fedora-steam" steam

dnf5 -y install \
    lutris \
    gamescope \
    mangohud.x86_64 mangohud.i686 \
    vkBasalt.x86_64 vkBasalt.i686 \
    gamemode \
    winetricks \
    vulkan-tools \
    evtest

dnf5 -y install \
    distrobox \
    btop \
    nvtop \
    fastfetch \
    duf \
    lm_sensors \
    7zip 7zip-standalone \
    fira-code-fonts \
    vim-enhanced \
    fish

[[ -f /etc/bluetooth/input.conf ]] && sed -i 's/#UserspaceHID.*/UserspaceHID=true/' /etc/bluetooth/input.conf

covered=$(systemd-tmpfiles --cat-config 2>/dev/null | awk '!/^#/ && NF >= 2 {print $2}' | sort -u)
find /var/lib /var/spool -mindepth 1 -type d \
    -not -path '/var/lib/dnf*' -not -path '/var/lib/rpm-state*' \
    -printf '%p\t%#m\t%u\t%g\n' | sort |
while IFS=$'\t' read -r path mode user group; do
    grep -qxF "$path" <<<"$covered" || echo "d $path $mode $user $group -"
done > /usr/lib/tmpfiles.d/zz-image-var.conf

systemctl mask systemd-remount-fs.service

systemctl enable docker.socket
systemctl enable podman.socket
systemctl enable dx-groups.service
systemctl enable system-flatpaks.service

systemctl disable getty@tty1.service