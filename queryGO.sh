#!/bin/bash
echo 'By default this searches for email addresses, original rex \b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b' 
echo 'But with anohter input you can append to the query like so \b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b|\bform.*'
echo ""
for i in $(cat $1)
  do
    echo querying $i
    echo $i : >> query.$1
    echo $i | hakrawler -u | grep -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b|$2" | sort -u >> query.$1
    echo "" >> query.$1
done
total=$(wc -l query.$1 | awk '{print $1}')
echo Finished! $total total keywords found
echo ""
cat query.$1
echo ""
echo Finished! $total total keywords found