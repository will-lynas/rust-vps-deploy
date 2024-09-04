#!/bin/bash
set -e

GITHUB_REPOSITORY=$1
REPO_NAME=$(echo $GITHUB_REPOSITORY | cut -d'/' -f2)

# TODO: factor out this path
mkdir -p ~/deploy

if [ -d ~/deploy/$REPO_NAME ]; then
  cd ~/deploy/$REPO_NAME
  git fetch origin
  git reset --hard origin/main
else
  git clone -b main git@github.com:$GITHUB_REPOSITORY.git ~/deploy/$REPO_NAME
  cd ~/deploy/$REPO_NAME
fi

cargo build --release

cat << EOF > /tmp/$REPO_NAME.service
[Unit]
Description=Web Server for $REPO_NAME
After=network.target

[Service]
ExecStart=/home/$(whoami)/deploy/$REPO_NAME/target/release/$REPO_NAME
Restart=on-failure
WorkingDirectory=/home/$(whoami)/deploy/$REPO_NAME

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/$REPO_NAME.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable $REPO_NAME.service
sudo systemctl restart $REPO_NAME.service
