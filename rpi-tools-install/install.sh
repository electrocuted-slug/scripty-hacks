sudo apt update
# macchanger
sudo apt install -y macchanger
# bettercap pre-requisites
sudo apt install -y golang git build-essential libpcap-dev libusb-1.0-0-dev libnetfilter-queue-dev 
# aircrack pre-requisites
sudo apt install -y autoconf automake libtool openssl libssl-dev shtool pkg-config rfkill ethtool libnl-3-dev libnl-genl-3-dev
# bettercap pre-requisites
go get -u -v github.com/bettercap/bettercap
# aircrack install
wget https://download.aircrack-ng.org/aircrack-ng-1.6.tar.gz
tar -zxvf aircrack-ng-1.6.tar.gz
cd aircrack-ng-1.6
autoreconf -i
./configure --with-experimental
make
sudo make install
sudo ldconfig
