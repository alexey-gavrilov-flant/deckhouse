{{- if eq .cri "Docker" }}

bb-event-on 'bb-package-installed' 'post-install'
post-install() {
  if bb-flag? there-was-docker-installed; then
    bb-log-info "Setting reboot flag due to docker package was updated"
    bb-flag-set reboot
    bb-flag-unset there-was-docker-installed
  fi

  systemctl enable docker.service
{{ if ne .runType "ImageBuilding" -}}
  systemctl restart docker.service
{{- end }}
}

if bb-yum-package? containerd.io && ! bb-yum-package? docker-ce ; then
  bb-deckhouse-get-disruptive-update-approval
  systemctl stop kubelet.service
  systemctl stop containerd.service
  # Kill running containerd-shim processes
  kill $(ps ax | grep containerd-shim | grep -v grep |awk '{print $1}') 2>/dev/null || true
  # Remove mounts
  umount $(mount | grep "/run/containerd" | cut -f3 -d" ") 2>/dev/null || true
  bb-yum-remove containerd.io
  rm -rf /var/lib/containerd/ /var/run/containerd /usr/local/bin/crictl
  # Pod kubelet-eviction-thresholds-exporter in cri=Containerd mode mounts /var/run/docker.sock, /var/run/docker.sock will be a directory and newly installed docker won't run.
  rm -rf /var/run/docker.sock
  bb-log-info "Setting reboot flag due to cri being updated"
  bb-flag-set reboot
fi

desired_version="docker-ce-18.09.9-3.el7.x86_64"
allowed_versions_pattern=""

should_install_docker=true
version_in_use="$(rpm -q docker-ce | head -1 || true)"
if test -n "$allowed_versions_pattern" && test -n "$version_in_use" && grep -Eq "$allowed_versions_pattern" <<< "$version_in_use"; then
  should_install_docker=false
fi

if [[ "$version_in_use" == "$desired_version" ]]; then
  should_install_docker=false
fi

if [[ "$should_install_docker" == true ]]; then
  desired_version_cli="$(sed 's/docker-ce/docker-ce-cli/' <<< "$desired_version")"
  container_selinux_package="container-selinux-2.119.2-1.911c772.el7_8"

  if bb-yum-package? docker-ce; then
    bb-flag-set there-was-docker-installed
  fi

  bb-deckhouse-get-disruptive-update-approval

  # RHEL 7 hack — docker-ce package requires container-selinux >= 2.9 but it doesn't exist in rhel repos.
  . /etc/os-release
  if [[ "${ID}" == "rhel" ]] && ! bb-yum-package? "$container_selinux_package"; then
    yum install -y "http://mirror.centos.org/centos/7/extras/x86_64/Packages/$container_selinux_package.noarch.rpm"
  fi

  bb-yum-install $container_selinux_package $desired_version $desired_version_cli
fi

{{- end }}
