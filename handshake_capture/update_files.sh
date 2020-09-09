cp my.cap.ex.sh my.cap.sh
cp my.ex.cap my.cap
cp my-cap.ex.service my-cap.service
ifconfig
usr=$USER
wrd=$(pwd)
dte=$(date +%s).pcap
tckr=8
read -p "WiFi Device Name?: " itf

sed "s|INTR_PH|$itf|g" -i my.cap.sh
sed "s|USER_PH|$usr|g" -i my.cap.sh
sed "s|WRKDIR_PH|$wrd|g" -i my.cap.sh
sed "s|WRKDIR_PH|$wrd|g" -i my.cap
sed "s|DATE_PH|$dte|g" -i my.cap
sed "s|TCKR_PH|$tckr|g" -i my.cap
sed "s|WRKDIR_PH|$wrd|g" -i my-cap.service

chmod +x my.cap.sh

readarray -t a < bssid.lst

b=$(printf ",%s" "${a[@]}")
b=${b:1}
sed -i "s|^set wifi.deauth.skip |set wifi.deauth.skip $b|g" my.cap
sed -i "s|^set wifi.assoc.skip |set wifi.assoc.skip $b|g" my.cap

sudo systemctl stop my-cap
sudo cp my-cap.service /etc/systemd/system/my-cap.service
sudo systemctl daemon-reload
sudo systemctl enable my-cap
sudo systemctl start my-cap
sudo systemctl status my-cap

