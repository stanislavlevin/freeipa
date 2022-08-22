#!/bin/bash -eu

# deps
printf "Install Host's tests requirements\n"
sudo apt-get update
sudo apt-get install -y \
    apparmor-utils \
    parallel \
    moreutils \
    rng-tools \
    systemd-coredump \
    python3-docker \

# Disable azsec services (clamav)
printf "Disable azsec services (clamav)\n"
# most of the time systemd killed azsecd with SIGKILL on timeout
# kill without waiting for graceful termination
sudo systemctl kill -s SIGKILL azsecd ||:
sudo systemctl disable --now azsecmond ||:
sudo systemctl disable --now azsecd ||:
sudo systemctl disable --now clamav-freshclam ||:

# apparmor
printf "Disable AppArmor conflicting profiles on Host.\n"
printf "current AppArmor status:\n"
sudo aa-status
printf "disable AppArmor conflicting profiles\n"
sudo aa-disable /etc/apparmor.d/usr.sbin.chronyd
printf "Recheck AppArmor status\n"
sudo aa-status

# entropy
printf "Available entropy: %s\n" $(cat /proc/sys/kernel/random/entropy_avail)
sudo service rng-tools start
sleep 3
printf "Recheck available entropy: %s\n" $(cat /proc/sys/kernel/random/entropy_avail)

# coredumps
printf "Allow coredumps\n"
date +'%Y-%m-%d %H:%M:%S' > coredumpctl.time.mark
systemd_conf="/etc/systemd/system.conf"
sudo sed -i 's/^DumpCore=.*/#&/g' "$systemd_conf"
sudo sed -i 's/^DefaultLimitCORE=.*/#&/g' "$systemd_conf"
echo -e 'DumpCore=yes\nDefaultLimitCORE=infinity' |
    sudo tee -a "$systemd_conf" >/dev/null
cat "$systemd_conf"
coredump_conf="/etc/systemd/coredump.conf"
cat "$coredump_conf"
sudo systemctl daemon-reexec
# for ns-slapd debugging
sudo sysctl -w fs.suid_dumpable=1

# nfs
printf "Configure Host to allow NFS server/client within containers\n"
sudo modprobe {nfs,nfsd}

printf "NFS mounts\n"
mount | grep -i nfs ||:

printf "request key confs\n"
ls -1R /etc/request-key* ||:

for f in /etc/request-key.d/* /etc/request-key.conf;
do
    printf "###\nOriginal content of %s\n" "$f"
    cat "$f"
    sudo sed -i 's/.*\sid_resolver\s.*/# &/' "$f"
    printf "###\nPatched content of %s\n" "$f"
    cat "$f"
done

# docker
printf "Configure Docker to allow IPv6 network\n"
echo '{ "ipv6": true, "fixed-cidr-v6": "2001:db8::/64" }' > docker-daemon.json
sudo mkdir -p /etc/docker
sudo cp docker-daemon.json /etc/docker/daemon.json
sudo chown root:root /etc/docker/daemon.json
sudo systemctl restart docker
sudo modprobe ip6_tables

# tests image
docker load --input "$GITHUB_WORKSPACE/$IPA_DOCKER_IMAGE-image.tar.gz"
docker images
docker inspect "$IPA_DOCKER_IMAGE":latest
