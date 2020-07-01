#FairScan.sh
Written by C4l1b4n.
(This is my username also on HackTheBox)

## Description
This is a bash script that automates port scans and enumeration of basic services.
I wrote this "automator" because I found some of them in python, while I was searching for a bash one, and to improve my skills in bash.
It can be used in CTFs like Vulnhub or HackTheBox and also in other penetration testing environments like OSCP.

Firstly, this script performs a quick nmap TCP scan (all ports) and then a deep one (open ports previously discovered) plus a UDP scan on the top 20 ports.
Then it runs nikto and gobuster on ports 80 and/or 443, if they are open, and search for robots.txt
Finally it runs enum4linux if at least one port among 139,389,445 is open.
All these scans are saved into files, the quick nmap scan is printed as console output.

After the first scan, all others are done in parallel by default; otherwise you can also specify a step-by-step scan, where they will be performed sequentially.

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
Usage: ./FairScan.sh [-h] [-s] [-w WORDLIST] target_ip target_name
	 target_ip	Ip address of the target
	 target_name	Target name, a dir will be created using this path
Options: -w wordlist	Specify a wordlist for gobuster. (The default one is big.txt from dirb's lists)
	 -h		Show this helper
   	 -s		Step-by-step: it does first nmap scans, and then service port scans not in parallel, but one by one.
   	 -f		Force-scans. It doesn't perform ping to check if the host is alive."
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
$ ./FairScan.sh -h
```
## Notes
I wrote this script to automate my enumeration, therefore it performs only what I'm used to running during my CTFs.
I think I will add more features in the future.

## License
This project is licensed under MIT License - see the LICENSE.md file for details.





