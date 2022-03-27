#!/bin/bash

##                    ##
## Written by C4l1b4n ##
##                    ##

# defalut wordlist for gobuster
wordlist="/opt/SecLists/Discovery/Web-Content/raft-small-words.txt"

# NSE's scripts run by nmap
nse="dns-nsec-enum,dns-nsec3-enum,dns-nsid,dns-recursion,dns-service-discovery,dns-srv-enum,fcrdns,ftp-anon,ftp-bounce,ftp-libopie,ftp-syst,ftp-vuln-cve2010-4221,http-apache-negotiation,http-apache-server-status,http-aspnet-debug,http-backup-finder,http-bigip-cookie,http-cakephp-version,http-config-backup,http-cookie-flags,http-devframework,http-exif-spider,http-favicon,http-frontpage-login,http-generator,http-git,http-headers,http-hp-ilo-info,http-iis-webdav-vuln,http-internal-ip-disclosure,http-jsonp-detection,http-mcmp,http-ntlm-info,http-passwd,http-php-version,http-qnap-nas-info,http-sap-netweaver-leak,http-security-headers,http-server-header,http-svn-info,http-trane-info,http-userdir-enum,http-vlcstreamer-ls,http-vuln-cve2010-0738,http-vuln-cve2011-3368,http-vuln-cve2014-2126,http-vuln-cve2014-2127,http-vuln-cve2014-2128,http-vuln-cve2014-2129,http-vuln-cve2015-1427,http-vuln-cve2015-1635,http-vuln-cve2017-1001000,http-vuln-misfortune-cookie,http-webdav-scan,http-wordpress-enum,http-wordpress-users,https-redirect,imap-capabilities,imap-ntlm-info,ip-https-discover,membase-http-info,msrpc-enum,mysql-audit,mysql-databases,mysql-empty-password,mysql-info,mysql-users,mysql-variables,mysql-vuln-cve2012-2122,nfs-ls,nfs-showmount,nfs-statfs,pop3-capabilities,pop3-ntlm-info,pptp-version,rdp-ntlm-info,rdp-vuln-ms12-020,realvnc-auth-bypass,riak-http-info,rmi-vuln-classloader,rpc-grind,rpcinfo,smb-enum-domains,smb-enum-groups,smb-enum-processes,smb-enum-services,smb-enum-sessions,smb-enum-shares,smb-enum-users,smb-mbenum,smb-os-discovery,smb-print-text,smb-protocols,smb-security-mode,smb-vuln-cve-2017-7494,smb-vuln-ms10-061,smb-vuln-ms17-010,smb2-capabilities,smb2-security-mode,smb2-vuln-uptime,smtp-commands,smtp-ntlm-info,smtp-vuln-cve2011-1720,smtp-vuln-cve2011-1764,ssh-auth-methods,sshv1,ssl-ccs-injection,ssl-cert,ssl-heartbleed,ssl-poodle,sslv2-drown,sslv2,telnet-encryption,telnet-ntlm-info,tftp-enum,unusual-port,vnc-info,vnc-title"

version="1.2"
stepbystep="0"
force="0"
os=''
hostname=''

#usage helper
usage () {
	echo "Usage: ./FairScan.sh [ options ] target_ip target_name"
	echo "	 target_ip	Ip address of the target"
	echo "	 target_name	Target name, a dir will be created using this path"
	echo "Options: -w wordlist	Specify a wordlist for gobuster. (The default one is big.txt from dirb's lists)"
	echo "	 -H hostname    Specify hostname. (add it to /etc/passwd)"
	echo "	 -h		Show this helper"
	echo "   	 -s		Step-by-step: nmap scans are done first, then service port scans not in parallel, one by one."
	echo "   	 -f		Force-scans. It doesn't perform ping to check if the host is alive."
	exit
}

banner () {
	echo ""
	echo "[*] FairScan , script for automated enumeration [*]"
	echo ""
	echo "CODER:		C4l1b4n"
	echo "VERSION:	$version"
	echo "GITHUB:		https://github.com/C4l1b4n/FairScan"
	echo ""
}

#check correct order of parameters and assign $ip and $name
check_parameters () {
	while getopts "w:hH:sf" flag; do
	case "${flag}" in
		H) hostname=$OPTARG;;
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
		echo -e "[**] Wordlist $temp_wordlist doesn't exist! " 1>&2
    		exit 1
	fi
	if [[ -n "$temp_wordlist" ]] ; then
		wordlist=$temp_wordlist
	fi
}
#check if hostname is set in /etc/passwd
check_hostname () {
	if [[ -n "$hostname" ]] ; then
		temp_hostname=$(cat /etc/hosts | grep -E "(\s)+$hostname(\s|$)")
		if [[ -z "$temp_hostname" ]] ; then
			echo "You specified $hostname as hostname, but you didn't put it in /etc/hosts !"
			exit 1
		fi
	else
		hostname=$ip
	fi
}

#check if the host is alive
host_alive () {
	if [[ $force -ne "1" ]] ; then
		test_host=$(ping $ip -c 1 -W 3 | grep "ttl=" | awk -F 'ttl=' '{print $2}' | cut -d' ' -f1)
		if test -z "$test_host" ; then
			echo "[**] Oops, the target doesn't seem alive!" 1>&2
			exit 1
		else
			case "${test_host}" in
				6[34]) os="Linux";;
				12[78]) os="Windows";;
				25[45]) os="AIX/Cisco/FreeBSD/HP-UX/Irix/NetBSD/OpenBSD/Solaris";;
				*) os='';;
			esac
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
	if test -z $os ; then
		os="Unknown"
	fi
	banner
	echo ""
	echo "TARGET ADDRESS:	$ip"
	echo "TARGET OS:	$os"
	echo ""
	check=$(nmap -sS -T4 -p- --min-rate 3000 $ip | grep " open " )
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
	echo "[+] Running UDP Nmap scan on 100 common ports..."
	nmap -sU --top-ports 100 --version-all $ip > udpNmap_$name.txt
	echo "[-] UDP Nmap scan done!"
}
#nmap NSE scan
nse_nmap () {
	echo "[+] Running NSE Nmap scan..."
	ports=$(cat "quickNmap_$name.txt" | grep " open " | cut -d ' ' -f1 | cut -d '/' -f1 | tr '\n' ',' | rev | cut -c 2- | rev)
	nmap -sV --script "$nse" -p $ports $ip > nse_$name.txt
	echo "[-] NSE Nmap scan done!"
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
	gobuster dir -u http://$hostname -w $wordlist -x "php,html,txt,asp,aspx,jsp" -t 100 -q -k --output gobuster_80_$name.txt 1>/dev/null
	echo "[-] Gobuster on port 80 done!"
}
#searching robots.txt
robots_80 () {
	echo "[+] Searching robots.txt on port 80..."
	robot_80=$(curl -sSik "http://$hostname:80/robots.txt")
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
	gobuster dir -u https://$hostname -w $wordlist -x "php,html,txt,asp,aspx,jsp" -q -t 100 -k --output gobuster_443_$name.txt 1>/dev/null
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
	check_hostname
	check_dir
	check_w
	host_alive
}
all_scans() {
	if [[ $stepbystep -ne "1" ]] ; then
		quick_nmap
		slow_nmap &
		udp_nmap &
		nse_nmap &
		check_port_80
		check_port_443
		check_smb
		#add more scans!
	else
		quick_nmap
		udp_nmap &
		slow_nmap 
		nse_nmap
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
