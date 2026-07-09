#!/bin/bash

set -eux

sudo apt update -y && sudo apt upgrade -y

sudo apt install -y ca-certificates curl gnupg lsb-release

sudo install -m 755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

sudo apt update -y

sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable docker
sudo systemctl start docker

usermod -aG docker ubuntu

# EBS volume mount for data persistence

DEVICE="/dev/nvme1n1"
MOUNT_POINT="/opt/traccar/data"

mkdir -p $MOUNT_POINT

if ! blkid $DEVICE; then
    mkfs.ext4 $DEVICE
fi

UUID=$(blkid -s UUID -o value $DEVICE)

if ! grep -q $UUID /etc/fstab; then
    echo "UUID=$UUID $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
fi

sudo systemctl daemon-reload

sudo mount -a

# run traccar container

sudo apt install -y git

git clone https://github.com/weikang22/traccar-dockercompose.git /opt/traccar/docker

mkdir -p /opt/traccar/{conf,logs}

sudo chown -R ubuntu:ubuntu /opt/traccar

cd /opt/traccar/docker

docker compose up -d