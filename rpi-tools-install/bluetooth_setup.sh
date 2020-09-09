# install a few dependencies
sudo apt install -y pulseaudio pulseaudio-module-zeroconf alsa-utils avahi-daemon pulseaudio-module-bluetooth expect
git clone https://github.com/bablokb/pi-btnap.git
# install btnap as a server
sudo ./pi-btnap/tools/install-btnap server

sudo sed 's|/usr/lib/bluetooth/bluetoothd|/usr/lib/bluetooth/bluetoothd --noplugin=sap|g' -i /etc/systemd/system/bluetooth.target.wants/bluetooth.service

sed 's|#Name = BlueZ|Name = Headset|g' -i /etc/bluetooth/main.conf

sudo tee /etc/btnap.conf << EOF
MODE="server"
BR_DEV="br0"
BR_IP="192.168.20.99/24"
BR_GW="192.168.20.1" 
ADD_IF="lo" 
REMOTE_DEV="" 
DEBUG=""
EOF

sudo systemctl enable bluetooth
sudo systemctl enable btnap
sudo systemctl enable dnsmasq

sudo service bluetooth restart
sudo service dnsmasq restart
sudo service btnap restart

while true; do
   echo "Please get your phone's mac address from your phone via settings > about phone > status > bluetooth address"
   read -p "Please enter you phone's mac address: " address
   address=$(echo ${address^^})
   read -p "$address is correct (y/n)? " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) continue;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "PLEASE GET YOUR PHONE READ BY SELECTING 'PAIR NEW DEVICE' IN YOUR BLUETOOTH SETTINGS"

sudo expect bluetooth.expect.sh $address
sudo service wpa_supplicant stop
sudo systemctl disable wpa_supplicant

