# FairScan.sh
My first upload.

## Description
Bash script that automates port scans and enumerates basic services.
I wrote this "automator" because whilst I found some of them in python, I was searching for a bash one. Moreover, I wanted to improve my skills in bash.
It can be used in CTFs like Vulnhub or HackTheBox and also in other penetration testing environments like OSCP.

First, this script performs a quick nmap SYN-TCP scan (all ports) and then a deep one (open ports previously discovered) plus a UDP scan on the top 100 ports.
Afterwards, it runs nikto and gobuster on ports 80 and/or 443, if they are open, and search for robots.txt .
Finally it runs enum4linux if at least one port among 139,389 and 445 is open.
All these scans are saved into files, quick-scan's result is printed as console's output.

After the first scan, the remaining are done in parallel by default; otherwise you can specify a step-by-step scan, where they will be performed sequentially.

## Update (03/07/2021)
1. Now it performs OS "detection" through ping's response, from ttl.
2. Nmap all-ports-scan's speed increased by adding --min-rate 3000 (now it's very fast).
3. A bunch of selected NSE scripts are run after the all-ports-scan. No bruteforcing or autopwn scripts are on the list. 

## Update (25/01/2022)
Now target's hostname can be added using -H parameter. Hostname is used by gobuster and curl to get better results.

## Requirments
```
ping
nmap
gobuster
nikto
curl
enum4linux
```

## Usage
```
Usage: ./FairScan.sh [-h] [-s] [-f] [-w WORDLIST] -H [hostname] target_ip target_name
	 target_ip	Ip address of the target
	 target_name	Target name, a directory will be created using this path
Options: -w wordlist	Specify a wordlist for gobuster. (The default one is big.txt from dirb's lists)
	 -H hostname    Specify hostname. (add it to /etc/passwd)
	 -h		Show this helper
   	 -s		Step-by-step: nmap scans are done first, then service port scans not in parallel, one by one.
   	 -f		Force-scans. It doesn't perform ping to check if the host is alive.
```

## Results
A directory with target_name as path/name will be created.
Inside it, a note_$name.txt file will be created, where you can write your notes, plus another directory, named /Scans.
Inside /Scans , output files will be stored.

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





