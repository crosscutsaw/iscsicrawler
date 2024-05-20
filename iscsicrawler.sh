#!/bin/bash

bblue='\033[1;34m'
bbred='\033[1;31m'
bgreen='\033[1;32m'
bwhite='\033[1;37m'
reset='\033[0m'

echo ''
echo -e "${bblue}iscsicrawler v1.0${reset}"
echo ''

echo -e "${bbred}removing old files if they are exist or not.${reset}"
rm -rf /tmp/iscsicrawler
echo ''

echo -e "${bwhite}current working directory is: $(pwd)${reset}"
echo ''

if ! command -v iscsiadm &> /dev/null; then
    echo -e "${bbred}iscsiadm is not present.${reset}"
    echo ''
    echo -e "${bwhite}type y to install iscsiadm.${reset}"
    echo -e "${bwhite}type n to exit.${reset}"
    read response1
        if [ "$response1" = "y" ]; then
            echo ''
            echo -e "${bgreen}installing iscsiadm.${reset}"
            apt update
            apt install -y open-iscsi
            service iscsid restart
            clear
        elif [ "$response1" = "n" ]; then
            exit
        else
            echo 'deadass???'
            exit
        fi
else
    echo -e "${bgreen}iscsiadm is present.${reset}"
    service iscsid restart
    echo ''
fi

mkdir /tmp/iscsicrawler

echo -e "${bgreen}do you want to scan for iscsi ports or would you provide ip list?${reset}"
echo -e "${bgreen}for scanning iscsi ports, you have to put your subnets into \"$(pwd)/kapsam.txt\"${reset}"
echo -e "${bwhite}type y to scan iscsi ports"
echo -e "type n to provide iscsi ip list file${reset}"
read response1

if [ "$response1" = "y" ]; then
    echo ''
    echo -e "${bgreen}scanning iscsi ports. $(date)${reset}"
    nmap -p 3260 -T4 -n --open -Pn -oG /tmp/iscsicrawler/portsraw.txt -iL kapsam.txt -v0
    grep "3260/open" /tmp/iscsicrawler/portsraw.txt | cut -d " " -f2 >> /tmp/iscsicrawler/ports.txt
    rm -rf /tmp/iscsicrawler/portsraw.txt
    echo -e "${bgreen}scan complete. $(date)${reset}"
    echo ""
    
elif [ "$response1" = "n" ]; then
    echo ''
    echo -e "${bgreen}provide the iscsi ip list file${reset}"
    read file
    echo ''
    echo -e "${bgreen}script will use \"$file\".${reset}"    
    cat $file > /tmp/iscsicrawler/ports.txt
    echo ""

else
    echo 'deadass???'
    exit
fi    

echo -e "${bgreen}starting iscsi crawl. $(date)${reset}"
echo ''

for i in $(cat /tmp/iscsicrawler/ports.txt); do
    iscsiadm -m discovery -t sendtargets -p $i >> /tmp/iscsicrawler/targets.txt
done

while IFS= read -r line; do
    target_ip=$(echo "$line" | cut -d ':' -f 1)
    target_name=$(echo "$line" | awk '{print $2}')
    iscsiadm --mode node --targetname $target_name --portal $target_ip -u > /dev/null 2>&1
    iscsiadm --mode node --targetname $target_name --portal $target_ip --login > /dev/null
    sleep 3
    while IFS= read -r block; do
        if [ ! -d "/tmp/iscsicrawler/mount" ]; then
            mkdir /tmp/iscsicrawler/mount
        fi
        mount /dev/$block /tmp/iscsicrawler/mount 2> /dev/null
        if [ "$(ls -A /tmp/iscsicrawler/mount)" ]; then
            echo "/dev/$block"
            echo $line
            tree /tmp/iscsicrawler/mount
            echo ''
            umount /tmp/iscsicrawler/mount 2> /dev/null
            rm -rf /tmp/iscsicrawler/mount 2> /dev/null
        fi
     done < <(ls -t1 /dev | grep '^sd[^a]' | head -n 3)
     iscsiadm --mode node --targetname $target_name --portal $target_ip -u > /dev/null
done < /tmp/iscsicrawler/targets.txt

# iscsicrawler v1.0
# 
# contact options
# mail: https://blog.zurrak.com/contact.html
# twitter: https://twitter.com/tasiyanci
# linkedin: https://linkedin.com/in/aslanemreaslan