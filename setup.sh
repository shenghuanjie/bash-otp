#!/usr/bin/env bash
sudo apt-get update
sudo apt-get install oathtool
sudo apt-get install libssl-dev
sudo apt-get install sshpass

THIS_DIR=$( dirname {0})
chmod 700 "$THIS_DIR"
chmod 700 "$THIS_DIR/otp.sh"
chmod 700 "$THIS_DIR/tokenfiles"
chmod 700 "$THIS_DIR/keys"
