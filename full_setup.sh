#!/bin/bash
set -e

echo ">>> Removing old container if exists..."
sudo docker rm -f mydesktop 2>/dev/null || true

echo ">>> Starting fresh Ubuntu 20.04 desktop container with fixed 1920x1080 resolution..."
sudo docker run -d --name mydesktop -p 6080:80 -e RESOLUTION=1920x1080 dorowu/ubuntu-desktop-lxde-vnc:focal

echo ">>> Waiting for desktop to boot up..."
sleep 20

echo ">>> Installing Zoom, OBS and audio system inside the container (this takes a few minutes)..."
sudo docker exec mydesktop bash -c '
export DEBIAN_FRONTEND=noninteractive

echo "--- Updating package list ---"
apt update

echo "--- Installing base tools ---"
apt install -y wget software-properties-common

echo "--- Installing Zoom ---"
wget -O /root/zoom_amd64.deb https://zoom.us/client/latest/zoom_amd64.deb
apt install -y /root/zoom_amd64.deb

echo "--- Adding OBS Studio PPA ---"
add-apt-repository ppa:obsproject/obs-studio -y
apt update

echo "--- Installing OBS Studio ---"
apt install -y ffmpeg obs-studio

echo "--- Installing audio system ---"
apt install -y pulseaudio pavucontrol alsa-utils

echo "--- Cleaning any old pulseaudio state ---"
pkill -9 pulseaudio || true
rm -f /var/run/pulse/native

echo "--- Fixing PulseAudio config for anonymous access ---"
sed -i "/load-module module-native-protocol-unix/d" /etc/pulse/system.pa
echo "load-module module-native-protocol-unix auth-anonymous=1" >> /etc/pulse/system.pa

echo "--- Starting PulseAudio in system mode ---"
pulseaudio --system --daemonize --disallow-exit --disable-shm=1
sleep 3

echo "--- Creating named virtual audio sink ---"
pactl load-module module-null-sink sink_name=virtual_speaker sink_properties=device.description=Virtual_Speaker
pactl set-default-sink virtual_speaker

echo "--- Verifying audio system ---"
pactl info
'

echo ">>> ALL DONE!"
echo ">>> Go to the Ports tab, open port 6080."
echo ">>> Inside the desktop terminal, type: zoom   or   obs"
echo ">>> In OBS Settings > Audio, select Virtual_Speaker as Desktop Audio."
echo ">>> In Zoom Settings > Audio, select Virtual_Speaker as the speaker."
echo ">>> Screen resolution is fixed at 1920x1080 - maximize windows for best fit."