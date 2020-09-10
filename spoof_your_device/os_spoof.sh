#!/bin/bash

set -e

ohnfn="orig_hostname.txt"

if [ -f $ohnfn ]
then
  org_hn=$(head -n 1 $ohnfn)
else
  org_hn=$HOSTNAME
  echo $org_hn > $ohnfn
fi

folder="network_spoof"
win_csv="Windows.csv"
app_csv="Apple.csv"
mac_csv="Mac_prefixes.csv"
nms_csv="Names.csv"
app_prd=( "Mac" "MacBook" "MacBook Pro" "MacBook Air" "iMac" "Mac Pro" "Mac mini" )


if [ ! -d $folder ]; then
	mkdir $folder
fi

cd $folder

win_7_suffix="-PC"
win_10_prefixes=("PC-" "DESKTOP-" "LAPTOP-")
size=${#win_10_prefixes[@]}
index=$(($RANDOM % $size))
win_10_prefix=${win_10_prefixes[$index]}
win_10_suffix=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 6 | head -n 1)
apple_name_suffix="'s"

mac_suffix=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 6 | head -n 1)

sudo apt install wget wireless-tools -y

if [ ! -f "$mac_csv" ]; then
	wget http://standards-oui.ieee.org/oui/oui.csv -O $mac_csv
fi

if [ ! -f "$nms_csv" ]; then
	wget https://pastebin.com/raw/j9fZaz5E -O $nms_csv
fi

if [ ! -f "$win_csv" ]; then
	cat $mac_csv | grep 'Dell Inc.\|Microsoft\|Huawei\|Hewlett\|Lenovo\|Acer\|Samsung|\Sony\|IBM\|ASUS\|Razer|\Toshiba' > $win_csv
fi

if [ ! -f "$app_csv" ]; then
	cat $mac_csv | grep 'Apple, Inc.' > $app_csv
fi

declare -a options=($(ls /sys/class/net))
declare -a opts=(${options[@]/lo/})
echo ${opts[@]}
match=false
while ! $match
do
	read -p "Please choice a device: " interface
	for i in "${opts[@]}"
	do
           if [[ $i == "$interface" ]]; then
		match=true
		break
	    fi
	done
done


PS3='Please enter your choice: '
options=("Windows 7" "Windows 10" "Apple" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Windows 7")
	    device=$(sort -R $win_csv | head -n 1)
	    mac_prefix=$(echo $device | cut -d ',' -f2)
	    name=$(sort -R $nms_csv | head -n 1)
	    pc_name=$(echo $name | cut -d ',' -f2)$win_7_suffix
	    mac_address=$mac_prefix$mac_suffix
	    break
            ;;
        "Windows 10")
	    device=$(sort -R $win_csv | head -n 1)
	    mac_prefix=$(echo $device | cut -d ',' -f2)
	    name=$(sort -R $nms_csv | head -n 1)
	    pc_name=$win_10_prefix$win_10_suffix
	    mac_address=$mac_prefix$mac_suffix
	    break
            ;;
        "Apple")
	    device=$(sort -R $app_csv | head -n 1)
	    mac_prefix=$(echo $device | cut -d ',' -f2)
	    name=$(sort -R $nms_csv | head -n 1)
	    pc_name="$(echo $name | cut -d ',' -f2)$apple_name_suffix ${app_prd[RANDOM%${#app_prd[@]}]}"
	    mac_address=$mac_prefix$mac_suffix
	    break
            ;;
        "Quit")
            exit 0
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

mac=$mac_address
first_name=$(echo $name | cut -d ',' -f2)

array=()
for (( CNTR=0; CNTR<${#mac}; CNTR+=2 )); do
  array+=( ${mac:CNTR:2} )
done
IFS=':'
mac_str="${array[*]}"

my_log="./spoof_log.txt"

device_prefix=${interface:0:1}

if [[ $device_prefix == "w" ]]; then

	read -p 'Please enter your wifi essid: ' my_essid

	my_script="${my_essid}_${first_name}.sh"

	cat << EOF > ../$my_script
#!/bin/bash

set -e

sleep 2
pr_hn=$(echo $pc_name | tr ' ' '-')
sudo hostnamectl set-hostname \$pr_hn

sudo sed "s|$org_hn|\$pr_hn|g" -i /etc/hosts
phnfn="prev_hostname.txt"
echo \$pr_hn > \$phnfn

sudo service systemd-hostnamed restart
sudo ifconfig $interface down
sudo macchanger -m $mac_str $interface
sudo ifconfig $interface up
echo "MAC Address has changed to: $mac_str" >> $my_log
echo "Hostname has changed to: $pc_name" >> $my_log
sleep 4
nmcli radio wifi on
sleep 2
nmcli device wifi rescan
sleep 2
nmcli device wifi connect $my_essid
echo "$my_essid connected" >> $my_log
EOF

else

	my_script="${interface}_${first_name}.sh"

	cat << EOF > ../$my_script
#!/bin/bash

set -e

sleep 2
pr_hn=$(echo $pc_name | tr ' ' '-')
sudo hostnamectl set-hostname \$pr_hn

sudo sed "s|$org_hn|\$pr_hn|g" -i /etc/hosts
phnfn="prev_hostname.txt"
echo \$pr_hn > \$phnfn

sudo service systemd-hostnamed restart
sudo ifconfig $interface down
sudo macchanger -m $mac_str $interface
sudo ifconfig $interface up
echo "MAC Address has changed to: $mac_str" >> $my_log
echo "Hostname has changed to: $pc_name" >> $my_log
sleep 3
nmcli device connect $interface
echo "$interface connected" >> $my_log
EOF

fi

sudo chmod +x ../$my_script

cat << EOF > ../deactivate_$my_script
#!/bin/bash

set -e

phnfn="prev_hostname.txt"

if [ -f \$phnfn ]
then
  pr_hn=\$(head -n 1 \$phnfn)
else
  pr_hn=\$HOSTNAME
  echo \$pr_hn > \$phnfn
fi

my_log="./spoof_log.txt"

sudo hostnamectl set-hostname "$org_hn"
sudo sed "s|\$pr_hn|$org_hn|g" -i /etc/hosts
nmcli device disconnect $i
sudo ifconfig $i down
sudo macchanger -p $i
sudo ifconfig $i up
echo "$i deactivated" >> $my_log

EOF

sudo chmod +x ../deactivate_$my_script

echo "${my_essid},${pc_name},${mac_str}" >> spoofs.txt

cd ~
