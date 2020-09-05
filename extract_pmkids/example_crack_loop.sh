
WORDLIST="common.txt"
DIR=""

for f in $DIR*.hccapx; do
    hashcat -m2500 $f $WORDLIST
done

for h in $DIR*.hccapx; do
    hashcat -m2500 $h --show >> results.txt
done

for g in $DIR*.pmkid; do
    hashcat -m16800 $g $WORDLIST
done

for i in $DIR*.pmkid; do
    hashcat -m16800 $i --show >> results.txt
done
