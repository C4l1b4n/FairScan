#!/bin/bash
echo "Hi! I'm painfully slow garbage!"
domain=$(echo "$1" | awk -F/ '{print $3}')
curl -silent  $1 | grep -o "https:\/\/$domain/[^\"]*" > seen$domain
tr ' ' '\n' < seen$domain | grep -o "https:\/\/$domain/[^\"]*" | sort -u -o seen$domain
stop=$(wc -l seen$domain | awk '{print $1}')
echo Starting found visited $stop links in $domain 
echo ""
start=0
while [ $start -ne $stop ];
do
  start=$stop
    for i in $(cat seen$domain)
      do
       test=$(grep  -E '(^|\s)'$i'($|\s)' $domain.txt)
          if [ "$i" == "$test" ];
          then 
            echo dup "$i"
          else
            echo crawling $i
            curl -A "Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/81.0" -silent $i | grep -o 'href=\"/[^\"]*\|https:\/\/$domain/[^\"]*' | sed "s|href=\"|$1|g" >> seen$domain
            echo "$i" >> $domain.txt
            tr ' ' '\n' < $domain.txt | grep -o "https:\/\/$domain/[^\"]*" | sort -u -o $domain.txt
            tr ' ' '\n' < seen$domain | grep -o "https:\/\/$domain/[^\"]*" | sort -u -o seen$domain
         fi
      done
  stop=$(wc -l seen$domain | awk '{print $1}')
  echo Progress! paths visited $stop at $domain
  echo ""
done
rm seen$domain
total=$(wc -l $domain.txt | awk '{print $1}')
echo Finished! $total total links hit
echo ""
cat $domain.txt
echo ""
echo Finished! $total total links hit