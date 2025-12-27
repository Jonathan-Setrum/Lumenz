#!/bin/bash

bppllist -allpolicies > /tmp/POLICIES
printf "CLIENT,POLICY NAME,BACKUP SELECTION,SCHEDULE" > /tmp/POLICYREPORT.csv
for i in `cat /tmp/POLICIES`
do
    for j in `bppllist $i |grep 'CLIENT'|awk '{print $2}'`
        do printf "\n$j, "; bppllist $i |grep 'CLASS '|awk '{print $2}'|tr '\n' ', '; bppllist $i |grep 'INCLUDE'|sed 's/INCLUDE/ /' |tr '\n' '; '
		printf ","; bppllist $i -L |grep 'Type:               \|Frequency:      \|Retention Level:'|tr '\n' '; '|sed 's/Type:                /TYPE:/g'|sed 's/Frequency:           /FREQ:/g'|sed 's/Retention Level:     /RL:/g'
        done
done >> /tmp/POLICYREPORT.csv
printf "\n\n" >> /tmp/POLICYREPORT.csv
