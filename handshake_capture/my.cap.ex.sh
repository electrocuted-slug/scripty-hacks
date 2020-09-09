sudo ifconfig INTR_PHmon down
sudo ifconfig INTR_PH down
sudo airmon-ng check kill
sudo macchanger -r INTR_PH
sudo ifconfig INTR_PH up
sudo airmon-ng check kill
sudo airmon-ng start INTR_PH
if [[ $(which bettercap) ]];
then
  sudo bettercap -iface INTR_PHmon -caplet WRKDIR_PH/my.cap
else
  sudo /home/USER_PH/go/bin/bettercap -iface INTR_PHmon -caplet WRKDIR_PH/my.cap
fi
