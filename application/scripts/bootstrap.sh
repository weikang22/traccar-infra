#!/bin/bash

set -eu

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
MOUNT_POINT="/opt/traccar"

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

# retrieve secrets from AWS secrets manager and create .env file for docker-compose yaml

sudo apt-get install -y unzip jq

sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"

sudo unzip /tmp/awscliv2.zip -d /tmp

sudo /tmp/aws/install

AWS_REGION="eu-west-2"
SECRET_NAME="traccar/dev/database"

SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$AWS_REGION" \
    --query SecretString \
    --output text)

DB_NAME=$(printf '%s' "$SECRET_JSON" | jq -er '.database')
DB_USER=$(printf '%s' "$SECRET_JSON" | jq -er '.username')
DB_PASSWORD=$(printf '%s' "$SECRET_JSON" | jq -er '.password')
DB_ROOT_PASSWORD=$(printf '%s' "$SECRET_JSON" | jq -er '.root_password')

cat > /opt/traccar/.env <<EOF
MARIADB_DATABASE=${DB_NAME}
MARIADB_USER=${DB_USER}
MARIADB_PASSWORD=${DB_PASSWORD}
MARIADB_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
EOF

sudo chown root:root /opt/traccar/.env
sudo chmod 600 /opt/traccar/.env

# run traccar container

curl -fsSL https://raw.githubusercontent.com/weikang22/traccar-infra/main/docker-compose.yml -o /opt/traccar/docker-compose.yml

mkdir -p /opt/traccar/{conf,logs,database}

curl -fsSL https://raw.githubusercontent.com/weikang22/traccar-infra/main/traccar.xml -o /opt/traccar/conf/traccar.xml

sudo chown -R ubuntu:ubuntu /opt/traccar

cd /opt/traccar

docker compose up -d