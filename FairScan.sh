#!/bin/bash

##                    ##
## Written by C4l1b4n ##
##                    ##

#----------------------------------------------------------------------------------------------------------------------
##### CONFIGURATIONS - CHANGE THEM #####
#----------------------------------------------------------------------------------------------------------------------
### NMAP
# minimum rate for the quickest scan
nmap_min_rate="5000"
# top udp ports to scan
nmap_top_udp="100"


### NIKTO
# maximum time length for the scan
nikto_maxtime="10m"


### GOBUSTER
## Linux
# directory bruteforce wordlist for detected linux machines
gobuster_dir_linux_wordlist="/usr/share/seclists/Discovery/Web-Content/raft-small-words.txt"
# directory bruteforce extensions for detected linux machines
gobuster_dir_linux_extensions="php,html,txt"

## Windows
# directory bruteforce wordlist for detected windows machines
gobuster_dir_windows_wordlist="/usr/share/seclists/Discovery/Web-Content/raft-small-words-lowercase.txt"
# directory bruteforce extensions for detected windows machines
gobuster_dir_windows_extensions="php,html,asp,aspx,jsp"

## Unknown OS
# directory bruteforce wordlist for NOT detected OS
gobuster_dir_unknown_wordlist="/usr/share/seclists/Discovery/Web-Content/raft-small-words.txt"
# directory bruteforce extensions for NOT detected OS
gobuster_dir_unknown_extensions="php,html,txt,asp,aspx,jsp,pdf,wsdl,asmx"

## All OSs
# vhost bruteforce wordlist
gobuster_vhost_wordlist="/usr/share/seclists/Discovery/DNS/combined_subdomains.txt"
# number of threads
gobuster_threads="100"


### WHATWEB
# aggression level
whatweb_level="3"

#----------------------------------------------------------------------------------------------------------------------
##### CONFIGURATIONS' END #####
#----------------------------------------------------------------------------------------------------------------------



# NSE's scripts run by nmap
nse="dns-nsec-enum,dns-nsec3-enum,dns-nsid,dns-recursion,dns-service-discovery,dns-srv-enum,fcrdns,ftp-anon,ftp-bounce,ftp-libopie,ftp-syst,ftp-vuln-cve2010-4221,http-apache-negotiation,http-apache-server-status,http-aspnet-debug,http-backup-finder,http-bigip-cookie,http-cakephp-version,http-config-backup,http-cookie-flags,http-devframework,http-exif-spider,http-favicon,http-frontpage-login,http-generator,http-git,http-headers,http-hp-ilo-info,http-iis-webdav-vuln,http-internal-ip-disclosure,http-jsonp-detection,http-mcmp,http-ntlm-info,http-passwd,http-php-version,http-qnap-nas-info,http-sap-netweaver-leak,http-security-headers,http-server-header,http-svn-info,http-trane-info,http-userdir-enum,http-vlcstreamer-ls,http-vuln-cve2010-0738,http-vuln-cve2011-3368,http-vuln-cve2014-2126,http-vuln-cve2014-2127,http-vuln-cve2014-2128,http-vuln-cve2014-2129,http-vuln-cve2015-1427,http-vuln-cve2015-1635,http-vuln-cve2017-1001000,http-vuln-misfortune-cookie,http-webdav-scan,http-wordpress-enum,http-wordpress-users,https-redirect,imap-capabilities,imap-ntlm-info,ip-https-discover,membase-http-info,msrpc-enum,mysql-audit,mysql-databases,mysql-empty-password,mysql-info,mysql-users,mysql-variables,mysql-vuln-cve2012-2122,nfs-ls,nfs-showmount,nfs-statfs,pop3-capabilities,pop3-ntlm-info,pptp-version,rdp-ntlm-info,rdp-vuln-ms12-020,realvnc-auth-bypass,riak-http-info,rmi-vuln-classloader,rpc-grind,rpcinfo,smb-enum-domains,smb-enum-groups,smb-enum-processes,smb-enum-services,smb-enum-sessions,smb-enum-shares,smb-enum-users,smb-mbenum,smb-os-discovery,smb-print-text,smb-protocols,smb-security-mode,smb-vuln-cve-2017-7494,smb-vuln-ms10-061,smb-vuln-ms17-010,smb2-capabilities,smb2-security-mode,smb2-vuln-uptime,smtp-commands,smtp-ntlm-info,smtp-vuln-cve2011-1720,smtp-vuln-cve2011-1764,ssh-auth-methods,sshv1,ssl-ccs-injection,ssl-cert,ssl-heartbleed,ssl-poodle,sslv2-drown,sslv2,telnet-encryption,telnet-ntlm-info,tftp-enum,unusual-port,vnc-info,vnc-title"

version="1.3.1"
stepbystep="0"
force="0"
os=''
hostname=''
gobuster_wordlist=''
gobuster_extensions=''

#usage helper
usage () {
	echo "Usage: ./FairScan.sh [ options ] target_ip target_name"
	echo "	 target_ip	Ip address of the target"
	echo "	 target_name	Target name, a dir will be created using this path"
	echo ""
	echo "Options: -w wordlist	Specify a wordlist for gobuster. (The default one is big.txt from dirb's lists)"
	echo "	 -H hostname    Specify hostname (fqdn). MUST BE IN QUOTES! (add it to /etc/hosts)"
	echo "	 -h		Show this helper"
	echo "   	 -s		Step-by-step: nmap scans are done first, then service port scans not in parallel, one by one."
	echo "   	 -f		Force-scans. It doesn't perform ping to check if the host is alive."
	exit
}

banner () {
	title='
	    ______      _      _____
	   / ____/___ _(_)____/ ___/_________ _____ 
	  / /_  / __ `/ / ___/\__ \/ ___/ __ `/ __ \
	 / __/ / /_/ / / /   ___/ / /__/ /_/ / / / /
	/_/    \__,_/_/_/   /____/\___/\__,_/_/ /_/ 

'
	print_blue "$title"
	echo "	[*] FairScan , script for automated enumeration [*]"
	echo ""
	echo "	CODER:		C4l1b4n"
	echo "	MODDER:		chromefinch"
	echo "	VERSION:	$version"
	echo "	GITHUB:		https://github.com/C4l1b4n/FairScan"
	echo ""
}

#----------------------------------------------------------------------------------------------------------------------
##### SET ENV #####
#----------------------------------------------------------------------------------------------------------------------

#check correct order of parameters and assign $ip and $name
check_parameters () {
	while getopts "w:hH:s:f" flag; do
	case "${flag}" in
		H) hostname=$OPTARG;
			print_green "Domain $hostname found";;
		w) temp_wordlist=$OPTARG;;
		h) usage
			exit;;
		s) stepbystep="1";;
		f) force="1";;
		*) print_red "Wrong parameters, use -h to show the helper"
			exit;;
	esac
	done
	if [ $(( $# - $OPTIND )) -lt 1 ] ; then
		print_red "Wrong parameters, use -h to show the helper"
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
			print_red "[**] Wrong IP"
			nslookup $ip
			exit 1
		fi
	done
	if [[ counter -ne 4 ]] ; then 
		print_red "[**] Wrong IP" 1>&2
		exit 1
	fi
}
#check if the $name path already exists
check_dir () {
	if [[ -d "$name" ]] ; then
		print_red "[**] $name directory already exists!" 1>&2
    		exit 1
	fi
}
#check if the wordlists specified exist
check_w () {
	if [[ -n "$gobuster_dir_linux_wordlist" ]] && ! [[ -f "$gobuster_dir_linux_wordlist" ]] ; then
		print_red "[**] Wordlist $gobuster_dir_linux_wordlist doesn't exist, fix the configurations! " 1>&2
    		exit 1
	fi
	if [[ -n "$gobuster_dir_windows_wordlist" ]] && ! [[ -f "$gobuster_dir_windows_wordlist" ]] ; then
		print_red "[**] Wordlist $gobuster_dir_windows_wordlist doesn't exist, fix the configurations! " 1>&2
    		exit 1
	fi
	if [[ -n "$gobuster_dir_unknown_wordlist" ]] && ! [[ -f "$gobuster_dir_unknown_wordlist" ]] ; then
		print_red "[**] Wordlist $gobuster_dir_unknown_wordlist doesn't exist, fix the configurations! " 1>&2
    		exit 1
	fi
	if [[ -n "$gobuster_vhost_wordlist" ]] && ! [[ -f "$gobuster_vhost_wordlist" ]] ; then
		print_red "[**] Wordlist $gobuster_vhost_wordlist doesn't exist, fix the configurations! " 1>&2
    		exit 1
	fi
	if [[ -n "$temp_wordlist" ]] && ! [[ -f "$temp_wordlist" ]] ; then
		print_red "[**] Wordlist $temp_wordlist doesn't exist! " 1>&2
    		exit 1
	fi	
}
#check if hostname is set in /etc/hosts
check_hostname () {
	if [[ -n "$hostname" ]] ; then
		temp_hostname=$(cat /etc/hosts | grep -E "(\s)+$hostname+(\s|$)")
		if [[ -z "$temp_hostname" ]] ; then
			print_red "You specified $hostname as hostname, but you didn't put it in /etc/hosts ! I've added $ip $hostname, but pls remove later!"
			sudo echo "$ip $hostname" >> /etc/hosts
		fi
	else
		hostname=$ip
		print_yellow "No hostname provided, remember they need to be in quotes"
	fi
}

#check if the host is alive
host_alive () {
	if [[ $force -ne "1" ]] ; then
		test_host=$(ping $ip -c 1 -W 3 | grep "ttl=" | awk -F 'ttl=' '{print $2}' | cut -d' ' -f1)
		if test -z "$test_host" ; then
			print_red "[**] Oops, the target doesn't seem alive! Use -f to override" 1>&2
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


#----------------------------------------------------------------------------------------------------------------------
##### NMAP SCANS #####
#----------------------------------------------------------------------------------------------------------------------

#nmap quick scan
quick_nmap () {
	if test -z $os ; then
		os="Unknown"
	fi
	
	if test $os == "Windows" ; then
		gobuster_wordlist=$gobuster_dir_windows_wordlist
		gobuster_extensions=$gobuster_dir_windows_extensions
	elif test $os == "Unknown" ; then
		gobuster_wordlist=$gobuster_dir_unknown_wordlist
		gobuster_extensions=$gobuster_dir_unknown_extensions
	else
		gobuster_wordlist=$gobuster_dir_linux_wordlist
		gobuster_extensions=$gobuster_dir_linux_extensions
	fi
	
	if [[ -n "$temp_wordlist" ]] ; then
		gobuster_wordlist=$temp_wordlist
	fi
	banner	
	if [ -z "$quickPorts" ] ; then
        portzdefault="--top-ports 10000"
        read -p "Enter desired ports to quick scan  [$portzdefault]:" portsv
        quickPorts=${portsv:-$portzdefault}
	fi
	echo ""
	read -p "Do you want to run gobuster? enter one of the folowing (dir/vhost/all/N) " gobusterAnswer
	echo ""
	echo ""
	echo "TARGET ADDRESS:	$ip $hostname"
	echo "TARGET OS:	$os"
	echo ""
	check=$(nmap -sS $quickPorts -n -Pn $ip | grep "/tcp" )
	if [[ -z $check ]] ; then
		print_red "[**] The target doesn't have any open ports... check manually!"
		cd ..
		cd ..
		rm -r $name
		exit
	else
		echo "PORT   STATE  SERVICE" #> quickNmap_$name.txt
		echo "$check" #>> quickNmap_$name.txt
		#cat quickNmap_$name.txt
		echo " "
		mkdir nmap
	fi
}
#nmap deep scan
slow_nmap () { 
	ports=$(echo "$check" | grep "/tcp" | cut -d ' ' -f1 | cut -d '/' -f1 | tr '\n' ',' | rev | cut -c 2- | rev)
	print_yellow "[+] Running deep Nmap scan on ports: $ports..."
	nmap -sS -A -p $ports $ip > nmap/deepNmap_$name.txt
	print_green "[-] Deep Nmap scan done!"
}
#namp UDP scan
udp_nmap () {
	print_yellow "[+] Running UDP Nmap scan on $nmap_top_udp common ports..."
	nmap -sU --top-ports $nmap_top_udp --version-all $ip > nmap/udpNmap_$name.txt
	print_green "[-] UDP Nmap scan done!"
}
#nmap NSE scan
nse_nmap () {
	print_yellow "[+] Running NSE Nmap scan..."
	ports=$(echo "$check" | grep " open " | cut -d ' ' -f1 | cut -d '/' -f1 | tr '\n' ',' | rev | cut -c 2- | rev)
	nmap -sV -n -O --script "$nse" -p $ports $ip > nmap/nse_$name.txt
	print_green "[-] NSE Nmap scan done!"
}
#nmap Vuln scan
vuln_nmap () {
	print_yellow "[+] Running Vuln Nmap scan..."
	ports=$(echo "$check" | grep " open " | cut -d ' ' -f1 | cut -d '/' -f1 | tr '\n' ',' | rev | cut -c 2- | rev)
	nmap -sV -n -O --script =default,vuln -p $ports $ip > nmap/vuln_$name.txt
	print_green "[-] Vuln Nmap scan done!"
}

#----------------------------------------------------------------------------------------------------------------------
##### SERVICES SCANS #####
#----------------------------------------------------------------------------------------------------------------------

#nikto scan, $1 --> protocol, $2 --> port
nikto_scan () {
	print_yellow "[+] Running Nikto on port $2..."
	nikto -port $2 -host $hostname -maxtime $nikto_maxtime -ask no 2> /dev/null >> $1/nikto_$2_$name.txt
	print_green "[-] Nikto on port $2 done!"
}
#gobuster dir scan, $1 --> protocol, $2 --> port

gobuster_dir () {
	print_yellow "[+] Running gobuster on port $2..."
	gobuster dir -u $1://$hostname:$2 -w $gobuster_wordlist -x $gobuster_extensions -t $gobuster_threads -q -k -d --output $1/gobuster_dir_$2_$name.txt 1>/dev/null
	if ! [ -s $1/gobuster_dir_$2_$name.txt ] ; then
		rm $1/gobuster_dir_$2_$name.txt
		print_red "[-] Gobuster dir on port $2 found nothing!"
	else
		print_green "[-] Gobuster dir on port $2 done!"
	fi
}
#gobuster vhost scan, $1 --> protocol, $2 --> port
gobuster_vhost () {
	if test $hostname != $ip ; then
		print_yellow "[+] Running gobuster vhost on port $2..."
		gobuster vhost -u $1://$hostname:$2 -w $gobuster_vhost_wordlist -t $gobuster_threads -q -k --append-domain --output $1/gobuster_subdomains_$2_$name.txt 1>/dev/null
		if ! [ -s $1/gobuster_subdomains_$2_$name.txt ] ; then
			rm $1/gobuster_subdomains_$2_$name.txt
			print_red "[-] Gobuster vhost on port $2 found nothing!"
		else
			print_green "[-] Gobuster vhost on port $2 done!"
		fi
	fi
}
#hakrawler scan, $1 --> protocol, $2 --> port
hakrawler_crawl () {
	print_yellow "[+] Running hakrawler on "$1://$hostname:$2"..."
	echo "$1://$hostname:$2" | hakrawler -d 0 -u | sort -u -o $1/hakrawler$2_$name.txt >/dev/null 2>&1
	if ! [ -s $1/hakrawler$2_$name.txt ] ; then
		rm $1/hakrawler$2_$name.txt
		print_red "[-] hakrawler on port $2 found nothing!"
	else
		print_green "[-] hakrawler on port $2 done!"
	fi
}


#download robots.txt, $1 --> protocol, $2 --> port
robots_txt () {
	print_yellow "[+] Searching robots.txt on port $2..."
	robot_=$(curl -sSik "$1://$hostname:$2/robots.txt")
	temp=$(echo $robot_ | grep "404")
	if [[ -z $temp ]] ; then 
		echo "$robot_" >> $1/robotsTxt_$2_$name.txt
		print_green "[-] Robots.txt on port $2 FOUND!"
	else
		print_red "[-] Robots.txt on port $2 NOT found."
	fi
}
# whatweb scan, $1 --> protocol, $2 --> port
whatweb_scan () {
	print_yellow "[+] Running whatweb on $1://$ip:$2..."
	whatweb $1://$ip:$2 -a $whatweb_level -v --color never --no-error 2>/dev/null >> $1/whatweb_$2_$name.txt
	print_green "[-] Whatweb on $1://$ip:$2 done!"
	print_yellow "[+] Running whatweb on $1://$hostname:$2..."
	whatweb $1://$hostname:$2 -a $whatweb_level -v --color never --no-error 2>/dev/null >> $1/whatweb_$2_$name.txt
	print_green "[-] Whatweb on $1://$hostname:$2 done!"
}
# enumerate http verbs, $1 --> protocol, $2 --> port
http_verbs () {
	if ! [ -e $1/gobuster_dir_$2_$name.txt ] ; then
		exit
	fi
	
	print_yellow "[+] Enumerating http-verbs from gobuster results on port $2..."
	not_redirected=$(cat $1/gobuster_dir_$2_$name.txt | grep "(Status: 2" | cut -d ' ' -f1)
	redirected=$(cat $1/gobuster_dir_$2_$name.txt | grep "(Status: 3" | awk -F' ' '{print $7}' | cut -d ']' -f 1)
	concatenation=""
	for i in $not_redirected ; do
		concatenation+="$1://$hostname:$2$i "
	done
	for i in $redirected ; do
		if [[ ${i:0:4} == "http" ]] ; then
			concatenation+="$i "
		else
			concatenation+="$1://$hostname:$2$i "
		fi
		
	done
	concatenation=$(echo $concatenation | xargs -n1 |sort -u)
	for i in $concatenation; do
		echo $i >> $1/$1-verbs.txt
		verb_result=$(curl -sSikI -X OPTIONS "$i" | grep -w -E 'HTTP|Allow:')
		echo $verb_result >> $1/$1-verbs.txt
		echo "---" >> $1/$1-verbs.txt
	done
	print_green "[-] Enumeration http-verbs on port $2 done!"
}
#run enum4linux if ports 139,389 or 445 are open
check_smb() {
	temp_smb=$(echo "$check" | grep -w -E '139/tcp|389/tcp|445/tcp')
	if [[ -n $temp_smb ]] ; then
		print_yellow "[+] Running enum4linux..."
		mkdir smb
		enum4linux -a -M -l -d $ip 2> /dev/null >> smb/enum4linux_$name.txt
		print_green "[-] Enum4linux done!"
	fi
}

#----------------------------------------------------------------------------------------------------------------------
##### UTILITIES #####
#----------------------------------------------------------------------------------------------------------------------
print_green (){
	echo -e "\033[0;32m$1\033[0m"
}
print_yellow (){
	echo -e "\033[0;33m$1\033[0m"
}
print_red (){
	echo -e "\033[0;31m$1\033[0m"
}
print_blue (){
        echo -e "\033[0;34m$1\033[0m"
}


#----------------------------------------------------------------------------------------------------------------------
##### MAIN #####
#----------------------------------------------------------------------------------------------------------------------

#check if port http is open
check_port_80 () {
	temp_80=$(echo "$check" | grep -v -we "443/tcp" -we '22/tcp' -we '445/tcp' -we '21/tcp' -we '139/tcp' -we '135/tcp' -we '3389/tcp')
	if [[ -n $temp_80 ]] ; then
	portz=$(echo "$temp_80" | grep "/tcp" | cut -d ' ' -f1 | cut -d '/' -f1  | rev | cut -c 1- | rev)
	mkdir http
	if [[ $gobusterAnswer == "dir" ]] ; then
		for i in ${portz[@]}; do
			hakrawler_crawl "http" $i &
			nikto_scan "http" $i &
			robots_txt "http" $i &
			whatweb_scan "http" $i &
			#gobuster_vhost "http" $i
			gobuster_dir "http" $i
			http_verbs "http" $i &
			#add more scans on port 80!
		done
	fi
	if [[ $gobusterAnswer == "vhost" ]] ; then
		for i in ${portz[@]}; do
			hakrawler_crawl "http" $i &
			nikto_scan "http" $i &
			robots_txt "http" $i &
			whatweb_scan "http" $i &
			gobuster_vhost "http" $i
			#gobuster_dir "http" $i
			http_verbs "http" $i &
			#add more scans on port 80!
		done
	fi
	if [[ $gobusterAnswer == "all" ]] ; then
		for i in ${portz[@]}; do
			hakrawler_crawl "http" $i &
			nikto_scan "http" $i &
			robots_txt "http" $i &
			whatweb_scan "http" $i &
			gobuster_vhost "http" $i
			gobuster_dir "http" $i
			http_verbs "http" $i &
			#add more scans on port 80!
		done
	fi
	if [[ $gobusterAnswer == "N" ]] ; then
		for i in ${portz[@]}; do
			hakrawler_crawl "http" $i &
			nikto_scan "http" $i &
			robots_txt "http" $i &
			whatweb_scan "http" $i &
			#gobuster_vhost "http" $i
			#gobuster_dir "http" $i
			http_verbs "http" $i &
			#add more scans on port 80!
		done
	fi
	if [[ -z $gobusterAnswer ]] ; then
		for i in ${portz[@]}; do
			hakrawler_crawl "http" $i &
			nikto_scan "http" $i &
			robots_txt "http" $i &
			whatweb_scan "http" $i &
			#gobuster_vhost "http" $i
			#gobuster_dir "http" $i
			http_verbs "http" $i &
			#add more scans on port 80!
		done
	fi
	fi
}

#check if port 443 is open
check_port_443 () {
	temp_443=$(echo "$check" | grep -w "443/tcp")
	if [[ -n $temp_443 ]] ; then
		mkdir https
		if [[ -z $gobusterAnswer ]] ; then
				hakrawler_crawl "https" "443" &
				nikto_scan "https" "443" &
				robots_txt "https" "443" &
				whatweb_scan "https" "443" &
				#gobuster_vhost "https" "443"
				#gobuster_dir "https" "443"
				http_verbs "https" "443" &
				hakrawler "https" "443" &
				#add more scans on port 443!
		fi
		if [[ $gobusterAnswer == "N" ]] ; then
				hakrawler_crawl "https" "443" &
				nikto_scan "https" "443" &
				robots_txt "https" "443" &
				whatweb_scan "https" "443" &
				#gobuster_vhost "https" "443"
				#gobuster_dir "https" "443"
				http_verbs "https" "443" &
				hakrawler "https" "443" &
				#add more scans on port 443!
		fi
		if [[ $gobusterAnswer == "all" ]] ; then
				hakrawler_crawl "https" "443" &
				nikto_scan "https" "443" &
				robots_txt "https" "443" &
				whatweb_scan "https" "443" &
				gobuster_vhost "https" "443"
				gobuster_dir "https" "443"
				http_verbs "https" "443" &
				hakrawler "https" "443" &
				#add more scans on port 443!
		fi
		if [[ $gobusterAnswer == "vhost" ]] ; then
				hakrawler_crawl "https" "443" &
				nikto_scan "https" "443" &
				robots_txt "https" "443" &
				whatweb_scan "https" "443" &
				gobuster_vhost "https" "443"
				#gobuster_dir "https" "443"
				http_verbs "https" "443" &
				hakrawler "https" "443" &
				#add more scans on port 443!
		fi
		if [[ $gobusterAnswer == "dir" ]] ; then
				hakrawler_crawl "https" "443" &
				nikto_scan "https" "443" &
				robots_txt "https" "443" &
				whatweb_scan "https" "443" &
				#gobuster_vhost "https" "443"
				gobuster_dir "https" "443"
				http_verbs "https" "443" &
				hakrawler "https" "443" &
				#add more scans on port 443!
		fi
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
		slow_nmap
		nse_nmap
		vuln_nmap
		udp_nmap &
		check_port_80
		check_port_443
		check_smb
		echo "all scans launched..."
		#add more scans!
	else
		quick_nmap
		slow_nmap 
		nse_nmap
		vuln_nmap
		udp_nmap &
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
