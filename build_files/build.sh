#!/bin/bash
set -ouex pipefail

cp -avf "/ctx/system_files"/. /

dnf5 -y group install cinnamon-desktop
dnf5 -y install lightdm slick-greeter   # the group pulls slick-greeter but not lightdm itself
dnf5 -y install arc-theme               # GTK, window border (metacity-1) and Cinnamon themes
/ctx/arc-cinnamon/patch-themes.sh /usr/share/themes

# Spices downloads crash on int(None) when the server omits Content-Length (linuxmint/cinnamon#13868).
# No-op once Fedora's cinnamon package carries the upstream fix.
sed -i "s/totalSize = int(response.headers.get('content-length'))/totalSize = int(response.headers.get('content-length') or 0)/" \
    /usr/share/cinnamon/cinnamon-settings/bin/Spices.py

sed -i \
    -e 's/label_box.add(this.event_time, { expand: true, x_fill: true });/label_box.add(this.event_time, { expand: false, x_fill: false });/' \
    -e 's/vbox.add(event_summary, { expand: true });/event_summary.x_expand = true;\n        label_box.insert_child_at_index(event_summary, 1);/' \
    /usr/share/cinnamon/applets/calendar@cinnamon.org/eventView.js

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
    freerdp \
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

dnf5 config-manager addrepo --from-repofile="https://pkgs.tailscale.com/stable/fedora/tailscale.repo"
dnf5 config-manager setopt tailscale-stable.enabled=0
dnf5 -y install --enable-repo="tailscale-stable" tailscale

# mergerfs isn't in Fedora's repos; install a pinned, checksum-verified release RPM.
# Bump both values together (and the fc44 suffix on a Fedora release change).
MERGERFS_VERSION=2.42.0
MERGERFS_SHA256=5b01fba27b22f4a0b16fe4ebef335e73f47593d8c77e3813cc1cafb65d807c62
curl -fsSLo /tmp/mergerfs.rpm \
    "https://github.com/trapexit/mergerfs/releases/download/${MERGERFS_VERSION}/mergerfs-${MERGERFS_VERSION}-1.fc44.x86_64.rpm"
echo "${MERGERFS_SHA256}  /tmp/mergerfs.rpm" | sha256sum -c -
dnf5 -y install /tmp/mergerfs.rpm

# xmousepasteblock isn't packaged; build a pinned, checksum-verified commit (tag 1.4),
# then remove only the build deps the base image didn't already have.
XMPB_COMMIT=c4ee870d30af5c5a37f8d4a2eb05197ae7ec4a1e
XMPB_SHA256=31bd571b9ae3b700c1e4151fcb93b2167afbeab34fee5ec59a3b2e55679f6d97
XMPB_BUILD_DEPS=(gcc make pkgconf-pkg-config libX11-devel libXi-devel libev-devel)
XMPB_NEW_DEPS=$({ rpm -q "${XMPB_BUILD_DEPS[@]}" || true; } | awk '/is not installed/ {print $2}')
dnf5 -y install libev libXi "${XMPB_BUILD_DEPS[@]}"
curl -fsSLo /tmp/xmpb.tar.gz \
    "https://github.com/milaq/XMousePasteBlock/archive/${XMPB_COMMIT}.tar.gz"
echo "${XMPB_SHA256}  /tmp/xmpb.tar.gz" | sha256sum -c -
mkdir /tmp/xmpb
tar -xzf /tmp/xmpb.tar.gz -C /tmp/xmpb --strip-components=1
make -C /tmp/xmpb install PREFIX=/usr
install -Dm 0644 /tmp/xmpb/xmousepasteblock.service /usr/lib/systemd/user/xmousepasteblock.service
if [[ -n "${XMPB_NEW_DEPS}" ]]; then
    dnf5 -y remove ${XMPB_NEW_DEPS}
fi

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
systemctl enable tailscaled.service
systemctl enable dx-groups.service
systemctl enable system-flatpaks.service
systemctl --global enable xmousepasteblock.service

systemctl disable getty@tty1.service