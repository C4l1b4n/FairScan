# FairScan.sh
rip of someone elses work with some additions 


## Description
This Bash script automates port scans and enumerates basic services.
I wrote this "automator" because I found some in python, but I was searching for one written in bash. Moreover, I aimed to improve my skills in bash.
It can be used in CTFs like Vulnhub or HackTheBox and also in other penetration testing environments like OSCP.

First, this script performs a quick nmap SYN-TCP scan (all ports) and then a deep one (open ports previously discovered) plus a UDP scan on top ports.
Multiple NSE scripts are run on most important services.
Secondly, it runs multiple modules on TCP ports 80,139,389,443 and/or 445 if they are found open.
All these scans are saved into files, quick-scan's result is printed as console's output.

After the first scan, the remaining are done in parallel by default; otherwise you can specify a step-by-step scan, where they will be performed sequentially.


## New Version Update (23/04/2023)
New version of the tool released with new banner, modules, configurations and a completely refactored code.


## Supported modules (old and new)
Generals:
- OS detection through ping.
- Quick SYN-TCP nmap's scan, all ports.
- Deep SYN-TCP nmap's scan on discovered open ports.
- NSE namp's scan through selected scripts on most important services. No bruteforcing or autopwn scripts are on the list. 
- UDP nmap's scan on TOP N ports, choosen by you in the configurations.

HTTP and HTTPS (if 80/tcp or 443/tcp are discovered open):
- Nikto's scan.
- Gobuster's dir scan, with different wordlists based on OS discovered.
- Gobuster's vhost scan, if "hostname" parameter is specified.
- Robots.txt download, if present, through curl.
- Whatweb's scan.
- HTTP-Verbs enumeration, through curl, based on gobuster's dir scan results.

SMB & co (if 139/tcp ,389/tcp or 445/tcp are discovered open):
- Enum4linux's scan.


## Configurations
Configurations can be easily found at the top lines of the script. You can modify values with your preferences.
Here is an example of the configurations I'm currently using:
```
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
gobuster_dir_linux_wordlist="/opt/SecLists/Discovery/Web-Content/raft-small-words.txt"
# directory bruteforce extensions for detected linux machines
gobuster_dir_linux_extensions="php,html,txt"


## Windows
# directory bruteforce wordlist for detected windows machines
gobuster_dir_windows_wordlist="/opt/SecLists/Discovery/Web-Content/raft-small-words-lowercase.txt"
# directory bruteforce extensions for detected windows machines
gobuster_dir_windows_extensions="php,html,asp,aspx,jsp"


## Unknown OS
# directory bruteforce wordlist for NOT detected OS
gobuster_dir_unknown_wordlist="/opt/SecLists/Discovery/Web-Content/raft-small-words.txt"
# directory bruteforce extensions for NOT detected OS
gobuster_dir_unknown_extensions="php,html,txt,asp,aspx,jsp"


## All OSs
# vhost bruteforce wordlist
gobuster_vhost_wordlist="/opt/SecLists/Discovery/DNS/combined_subdomains.txt"
# number of threads
gobuster_threads="100"


### WHATWEB
# aggression level
whatweb_level="3"
```

If you want to quickly check your current configurations you can use this command:
```
head -n 54 FairScan/FairScan.sh | tail -n 48
```


## Requirements
```
ping
nmap
gobuster
nikto
curl
enum4linux
whatweb
hakrawler
```

## Usage
```
Usage: ./FairScan.sh [-h] [-s] [-f] [-w WORDLIST] -H [hostname] target_ip target_name
         target_ip        Ip address of the target
         target_name        Target name, a directory will be created using this path
Options: -w wordlist        Specify a wordlist for gobuster. (The default one is big.txt from dirb's lists)
         -H hostname    Specify hostname (fqdn). MUST BE IN QUOTES (add it to /etc/hosts)
         -h                Show this helper
         -s                Step-by-step: nmap scans are done first, then service port scans not in parallel, one by one.
         -f                Force-scans. It doesn't perform ping to check if the host is alive.
```

## Results
A directory with target_name as path/name will be created.
Inside it, a note_$name.txt file will be created, where you can write your notes, plus another directory, named /Scans.
Inside /Scans , output files will be stored in different folders.

## Examples
```
$ ./FairScan.sh 10.10.10.10 kioptrix1
$ ./FairScan.sh -s 10.10.10.10 kioptrix2
$ ./FairScan.sh -s -w /usr/share/wordlists/dirb/common.txt 10.10.10.10 kioptrix3
$ ./FairScan.sh -f -H kioptrix4.com 10.10.10.10 kioptrix4
$ ./FairScan.sh -h
```
## Notes
I wrote this script to automate my enumeration, therefore it performs only what I'm used to running during my CTFs.
I think I will add more features in the future.

## License
This project is licensed under MIT License - see the LICENSE.md file for details.
