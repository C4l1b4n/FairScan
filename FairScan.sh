#!/bin/bash

##                    ##
## Written by C4l1b4n ##
##                    ##

# defalut wordlist for gobuster
wordlist="/usr/share/wordlists/dirb/big.txt"
stepbystep="0"
force="0"

#usage helper
usage () {
	echo "Usage: ./FairScan.sh [ options ] target_ip target_name"
	echo "	 target_ip	Ip address of the target"
	echo "	 target_name	Target name, a dir will be created using this path"
	echo "Options: -w wordlist	Specify a wordlist for gobuster. (The default one is big.txt from dirb's lists)"
	echo "	 -h		Show this helper"
	echo "   	 -s		Step-by-step: it does nmap scans first, then service port scans not in parallel, one by one."
	echo "   	 -f		Force-scans. It doesn't perform ping to check if the host is alive."
	exit
}
#check correct order of parameters and assign $ip and $name
check_parameters () {
	while getopts "w:hsf" flag; do
	case "${flag}" in
		w) temp_wordlist=$OPTARG;;
		h) usage
			exit;;
		s) stepbystep="1";;
		f) force="1";;
		?) echo "Wrong parameters, use -h to show the helper"
			exit;;
	esac
	done
	if [ $(( $# - $OPTIND )) -lt 1 ] ; then
		echo "Wrong parameters, use -h to show the helper"
		exit
	fi
	ip=${@:$OPTIND:1}
	name=${@:$OPTIND+1:1}
}
#check the correct format of the ip address
check_ip () {
	check_ip=$(echo "$ip" | tr '.' '\n')
	counter=0
	for part in $check_ip
	do
		counter=`expr $counter + 1`
		if [[ $part = *[!0-9]* ]] || [[ $part -gt 255 ]] ; then
			echo "[**] Wrong IP"
			exit 1
		fi
	done
	if [[ counter -ne 4 ]] ; then 
		echo "Wrong IP" 1>&2
		exit 1
	fi
}
#check if the $name path already exists
check_dir () {
	if [[ -d "$name" ]] ; then
		echo -e "[**] $name directory already exists!" 1>&2
    		exit 1
	fi
}
#check if the wordlist specified with -w exists
check_w () {
	if [[ -n "$temp_wordlist" ]] && ! [[ -f "$temp_wordlist" ]] ; then
		echo -e "[**] Wordlist $wordlist doesn't exists! " 1>&2
    		exit 1
	fi
	if [[ -n "$temp_wordlist" ]] ; then
		wordlist=$temp_wordlist
	fi
}
#check if the host is alive
host_alive () {
	if [[ $force -ne "1" ]] ; then
		test_host=$(ping $ip -c 1 -W 3 | grep "1 received")
		if test -z "$test_host" ; then
			echo "[**] Oops, the target doesn't seem alive!" 1>&2
			exit 1
		fi
	fi
}
#set the environment
set_env () {
	mkdir $name
	cd $name
	> note_$name.txt
	mkdir "Scans"
	cd "Scans"
}
#nmap quick scan
quick_nmap () {
	echo ""
	echo "TARGETING: $ip"
	echo ""
	check=$(nmap -sS -T4 -p- $ip | grep " open " )
	if [[ -z $check ]] ; then
		echo "[**] The target doesn't have any open ports... check manually!"
		cd ..
		cd ..
		rm -r $name
		exit
	else
		echo "PORT	STATE  SERVICE" > quickNmap_$name.txt
		echo "$check" >> quickNmap_$name.txt
		cat quickNmap_$name.txt
		echo " "
	fi
}
#nmap deep scan
slow_nmap () { 
	echo "[+] Running deep Nmap scan on $ip..."
	ports=$(cat "quickNmap_$name.txt" | grep " open " | cut -d ' ' -f1 | cut -d '/' -f1 | tr '\n' ',' | rev | cut -c 2- | rev)
	nmap -sS -A -p $ports $ip > deepNmap_$name.txt
	echo "[-] Deep Nmap scan done!"
}
#quick UDP scan
udp_nmap () {
	echo "[+] Running UDP Nmap scan on 20 common ports..."
	nmap -sU --top-ports 20 -A --version-all --max-retries 1 $ip > udpNmap_$name.txt
	echo "[-] UDP Nmap scan done!"
}
#check if port 80 is open
check_port_80 () {
	temp_80=$(cat "quickNmap_$name.txt" | grep -w "80/tcp")
	if [[ -n $temp_80 ]] ; then
		nikto_80 &
		gobuster_80 &
		robots_80 &
		#add more scans on port 80!
	fi
}
#nikto on port 80
nikto_80 () {
	echo "[+] Running Nikto on port 80..."
	nikto -port 80 -host $ip -maxtime 10m 2> /dev/null >> nikto_80_$name.txt
	echo "[-] Nikto on port 80 done!"
}
#gobuster on port 80
gobuster_80 () {
	echo "[+] Running gobuster on port 80..."
	gobuster dir -u http://$ip -w $wordlist -x "php,html,txt,asp,aspx,jsp" -t 50 -q -k >> gobuster_80_$name.txt
	echo "[-] Gobuster on port 80 done!"
}
#searching robots.txt
robots_80 () {
	echo "[+] Searching robots.txt on port 80..."
	robot_80=$(curl -sSik "http://$ip:80/robots.txt")
	temp=$(echo $robot_80 | grep "404")
	if [[ -z $temp ]] ; then 
		echo "$robot_80" >> robotsTxt_80_$name.txt
		echo "[-] Robots.txt on port 80 FOUND!"
	else
		echo "[-] Robots.txt on port 80 NOT found."
	fi
}
#check if port 443 is open
check_port_443 () {
	temp_443=$(cat "quickNmap_$name.txt" | grep -w "443/tcp")
	if [[ -n $temp_443 ]] ; then
		gobuster_443 &
		nikto_443 &
		#add more scans on port 443!
	fi
}
#gobuster on port 443
gobuster_443 () {
	echo "[+] Running gobuster on port 443..."
	gobuster dir -u https://$ip -w $wordlist -x "php,html,txt,asp,aspx,jsp" -q -t 50 -k >> gobuster_443_$name.txt
	echo "[-] Gobuster on port 443 done!"
}
#nikto on port 443
nikto_443 () {
	echo "[+] Running Nikto on port 443..."
	nikto -port 443 -host $ip -maxtime 10m 2> /dev/null >> nikto_443_$name.txt
	echo "[-] Nikto on port 443 done!"
}
#run enum4linux if ports 139,389 or 445 are open
check_smb() {
	temp_smb=$(cat quickNmap_$name.txt | grep -w -E '139/tcp|389/tcp|445/tcp')
	if [[ -n $temp_smb ]] ; then
		echo "[+] Running enum4linux..."
		enum4linux -a -M -l -d $ip 2> /dev/null >> enum4linux_$name.txt
		echo "[-] Enum4linux done!"
	fi
}
check_input(){
	check_parameters $@
	check_ip
	check_dir
	check_w
	host_alive
}
all_scans() {
	if [[ $stepbystep -ne "1" ]] ; then
		quick_nmap
		slow_nmap &
		udp_nmap &
		check_port_80
		check_port_443
		check_smb
		#add more scans!
	else
		quick_nmap
		udp_nmap &
		slow_nmap
		check_port_80
		wait
		check_port_443
		wait
		check_smb
		#add more scans!
	fi
}

#-------------------------- main ------------------------------------
check_input $@ #multiple check on input
set_env #setting working envirnoment
all_scans #do all scans
wait #wait all children
rm "quickNmap_$name.txt"
