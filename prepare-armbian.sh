#!/bin/bash

if [ -z ${HWADDR+x} ]; then
  echo "HWADDR not set"
  exit 1
fi

if [ -z ${ROOTFS+x} ]; then
  echo "ROOTFS not set"
  exit 1
fi

if [ -z "$ROOTFS" ]; then
  echo "ROOTFS empty - dangerous!"
  exit 1
fi

read -p "Preparing $ROOTFS. Setting eth0 MAC address to $HWADDR. Are you sure? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  if sudo test ! -f ${ROOTFS}/root/.not_logged_in_yet; then
    echo "${ROOTFS}/root/.not_logged_in_yet not found - exiting"
    exit 1
  fi

  echo "set root password"
  sudo sed -i '/root/c\root:$6$CymyQEKY$5ldzGkEg8VEDR/DGs6o17n.0t8SFPH./7PykZx/qzvJY07PnlYGk2wDVTu/jtctFq1.CQNMWd5R0FhbOXRIIe.:17635:0:99999:7:::' ${ROOTFS}/etc/shadow

  echo "add Ansible user and group"
  echo "ansible:x:1000:1000:Ansible Automation,,,:/home/ansible:/bin/bash" | sudo tee -a ${ROOTFS}/etc/passwd
  echo "ansible:x:1000:" | sudo tee -a ${ROOTFS}/etc/group
  echo "ansible:$6$BqQfrJEn$EOqVIn6ZoWwPQWKcioqovYP1SE3MT.HsW1qlcpG7N69B41zoiOHmKbJQlNzEyy4L5Y8F1sEpPdBQWjL9LBTn6/:17635:0:99999:7:::" | sudo tee -a ${ROOTFS}/etc/shadow

  echo "configure Ansible sudo access"
  echo "%wheel ALL=(ALL) NOPASSWD: ALL" | sudo tee ${ROOTFS}/etc/sudoers.d/wheel
  echo "wheel:x:115:ansible" | sudo tee -a ${ROOTFS}/etc/group

  echo "add SSH public key"
  sudo mkdir -p ${ROOTFS}/home/ansible/.ssh
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKehdCUgRwN3FYZwxTWgPTnarzzclKroEQ0Tr89CmkFjC3H7bqSDmy4k1QnfQTTH4azBWh4E8HRaqgFU87uLIFmAvioIRKkauXbmGvERHuVsbFpWioRA4ff3MQ6p9hWNZUoV6cN2nAkrOJ/TN8gew5wsQetl34lS1gKw6mx5WPegcT3ACgD0CbdOeFssOn7i640MTuCU/vv107BgFWpxjM1vSipX5TbLdL9a/o+GvJnQBrP3Eq6ZToo7OaiDpS+QmHprug9nYnqiGz8DcphovR2bbEZaRNZ1sH5Gp61IeS14n4TzF+/dTKlgYEYkfLp632W4wyu8AT7jAwn6PjkmKb tobru@aulait" | sudo tee ${ROOTFS}/home/ansible/.ssh/authorized_keys
  sudo chown -R 1000:1000 ${ROOTFS}/home/ansible
  sudo chmod 0644 ${ROOTFS}/home/ansible/.ssh/authorized_keys

  echo "spoof MAC address"
  sudo sed -i "/iface eth0 inet dhcp/a \ \ hwaddress ether $HWADDR" ${ROOTFS}/etc/network/interfaces

  echo "disable Armbian first-boot customization"
  sudo rm ${ROOTFS}/root/.not_logged_in_yet
fi
