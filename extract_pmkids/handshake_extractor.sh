#!/bin/bash

AIRCRACK_TIMEOUT=2 # How much time is given to aircrack-ng to read the file. Time is indicated in seconds.
# if you have a very large file or a very slow system, then increase this value
DIR="$(date +%s)"
ISDIRCREATED=0
CAP2="cap2hccapx"
CAP2C="cap2hccapx.c"

IGNORE_LIST_BSSID=()

if [[ "cap2hccapx" && -f "cap2hccapx" ]]; then
    echo "$CAP2 found"
else
    echo "Compiling cap2hccapx"
    if [[ "$CAP2C" && -f "$CAP2C" ]]; then
       gcc "$CAP2C" -o "$CAP2"
    else
       echo "Failed to compile $CAP2C"
       exit 1
    fi
fi

if [[ "$1" && -f "$1" ]]; then
    FILE="$1"
else
    echo 'Specify. (p) cap file to extract handshakes from.';
    echo 'Startup example:';
    echo -e "\tbash handshakes_extractor.sh wpa.cap";
    exit 1
fi

while read -r line; do
if [[ "$(echo $line | grep 'WPA' | grep '(1 handshake')" ]]; then
    if [ "$ISDIRCREATED" = "0" ]; then
        mkdir ./$DIR || (echo "Cannot create directory to save handshakes. Exit." && exit 1)
        ISDIRCREATED=1
    fi
    ESSID="$(echo $line | grep 'WPA' | grep 'handshake' | awk '{print $3}')"
    BSSID="$(echo $line | grep 'WPA' | grep 'handshake' | awk '{print $2}')"
    MYBSSID=$(echo $BSSID | sed 's|:|-|g')
    if [[ "${IGNORE_LIST_BSSID[@]}" =~ "$BSSID" ]]; then
       echo "$BSSID ignored"
       continue
    fi
    echo -e "A handshake was found for the $ESSID network ($BSSID). Saved to $DIR/$ESSID-$MYBSSID.pcap"
    tshark -r $FILE -R "(wlan.fc.type_subtype == 0x08 || wlan.fc.type_subtype == 0x05 || eapol) && wlan.addr == $BSSID" -2 -w ./$DIR/"$ESSID-$MYBSSID.pcap" -F pcap 2> /dev/null
    if [[ -f "$DIR/$ESSID-$MYBSSID.hccapx" || "$ESSID" = "hogan" || "$ESSID" = "SimplePlan" ]]; then
       echo "file already tested"
    else
       ./cap2hccapx ./$DIR/"$ESSID-$MYBSSID.pcap" ./$DIR/"$ESSID-$MYBSSID.hccapx"
       #hashcat -m2500 ./$DIR/"$ESSID-$MYBSSID.hccapx" ./wordlist/commoner_rockyou_wpa.txt --outfile-format 2 -o ./$DIR/$ESSID-$MYBSSID.result.txt
    fi
fi
if [[ "$(echo $line | grep 'WPA' | grep 'with PMKID')" ]]; then
     if [ "$ISDIRCREATED" = "0" ]; then
        mkdir ./$DIR || (echo "Cannot create directory to save handshakes. Exit." && exit 1)
        ISDIRCREATED=1
    fi
    ESSID="$(echo $line | grep 'WPA' | grep 'handshake' | awk '{print $3}')"
    BSSID="$(echo $line | grep 'WPA' | grep 'handshake' | awk '{print $2}')"
    MYBSSID=$(echo $BSSID | sed 's|:|-|g')
    if [[ "${IGNORE_LIST_BSSID[@]}" =~ "$BSSID" ]]; then
       echo "$BSSID ignored"
       continue
    fi
    echo -e "A handshake was found for the $ESSID network ($BSSID). Saved to $DIR/$ESSID-$MYBSSID.pcap"
    tshark -r $FILE -R "(wlan.fc.type_subtype == 0x08 || wlan.fc.type_subtype == 0x05 || wlan.rsn.ie.pmkid) && wlan.addr == $BSSID" -2 -w ./$DIR/"$ESSID-$MYBSSID.pcap" -F pcap 2> /dev/null
    if [[ -f "$DIR/$ESSID-$MYBSSID.pmkid" || "$ESSID" = "hogan" || "$ESSID" = "SimplePlan"  ]]; then
       echo "file already test"
    else
       hcxpcaptool -z ./$DIR/"$ESSID-$MYBSSID.pmkid" ./$DIR/"$ESSID-$MYBSSID.pcap"
       #hashcat -m16800 ./$DIR/"$ESSID-$MYBSSID.pmkid" ./wordlist/commoner_rockyou_wpa.txt --outfile-format 2 -o ./$DIR/$ESSID-$MYBSSID.result.txt
    fi
fi
done < <(timeout $AIRCRACK_TIMEOUT echo "q" | aircrack-ng $FILE)
