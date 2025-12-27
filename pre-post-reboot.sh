#!/bin/bash
#Purpose: Script to get backup master server pre reboot and post reboot check and also validates
lp1=`df -h | grep -i data01 | awk '{print $6}'`
lp=`df -h | grep -i nblog | awk '{print $6}'`
if [[ $lp == "/nblog" ]]
then
logpath=$lp
elif [[ $lp1 == "/data01" ]]
then
logpath=$lp1;
else
logpath=/tmp/
fi
echo "Enter 1 for Pre-reboot-check or 2 for Post-reboot-check"
read check

if [[ $check == 1 ]]
then
echo "" > /$logpath/pre-reboot-checks.txt

echo "############################################" > /$logpath/pre-reboot-checks.txt
echo "logpath=$logpath" >> /$logpath/pre-reboot-checks.txt
echo "hostname=$(hostname)" >>/$logpath/pre-reboot-checks.txt
echo "uptime=$(uptime)" >>/$logpath/pre-reboot-checks.txt
echo "Host status" >> /$logpath/pre-reboot-checks.txt
/usr/openv/volmgr/bin/vmoprcmd >> /$logpath/pre-reboot-checks.txt
echo "############################################" >> /$logpath/pre-reboot-checks.txt
echo -e "\n">> /$logpath/pre-reboot-checks.txt

echo "nbemmcmd output" >> /$logpath/pre-reboot-checks.txt
/usr/openv/netbackup/bin/admincmd/nbemmcmd -listhosts >>/$logpath/pre-reboot-checks.txt
echo "############################################" >> /$logpath/pre-reboot-checks.txt
echo -e "\n">> /$logpath/pre-reboot-checks.txt
echo "df-output" >> /$logpath/pre-reboot-checks.txt
df -h >> /$logpath/pre-reboot-checks.txt

echo "Finding if any mountpoint is above 80% usage">> /$logpath/pre-reboot-checks.txt
 df -h | sed 's/%//' > /tmp/df-out
cat /tmp/df-out | awk '{ if ($5 >= 80) print $ALL}' >> /$logpath/pre-reboot-checks.txt
echo "############################################" >> /$logpath/pre-reboot-checks.txt
echo -e "\n">> /$logpath/pre-reboot-checks.txt
echo "route details" >> /$logpath/pre-reboot-checks.txt
ip route show >> /$logpath/pre-reboot-checks.txt
ip route show > /tmp/routeshow
echo "############################################" >> /$logpath/pre-reboot-checks.txt
echo -e "\n">> /$logpath/pre-reboot-checks.txt
echo "ifconfig output" >> /$logpath/pre-reboot-checks.txt
ifconfig >> /$logpath/pre-reboot-checks.txt
ifconfig | grep -i inet > /tmp/ifconfigout
echo "############################################" >> /$logpath/pre-reboot-checks.txt
echo -e "\n">> /$logpath/pre-reboot-checks.txt
echo "/etc/fstab details" >> /$logpath/pre-reboot-checks.txt
cat /etc/fstab > /tmp/fstab
cat /etc/fstab >> /$logpath/pre-reboot-checks.txt
echo "############################################" >> /$logpath/pre-reboot-checks.txt
echo -e "\n">> /$logpath/pre-reboot-checks.txt
echo "suspending scheduling" >> /$logpath/pre-reboot-checks.txt
/usr/openv/netbackup/bin/admincmd/nbpemreq -suspend_scheduling
echo "Suspended scheduler" >> /$logpath/pre-reboot-checks.txt
echo "############################################" >> /$logpath/pre-reboot-checks.txt

echo -e "\n">> /$logpath/pre-reboot-checks.txt
echo "checking active jobs" >> /$logpath/pre-reboot-checks.txt
/usr/openv/netbackup/bin/admincmd/bpdbjobs | grep -i active >> /$logpath/pre-reboot-checks.txt
echo " Do you want to cancel running jobs and stop netbackup services? if yes, enter 1-yes, 2-no"
read chk
if [[ $chk == 1 ]]
then
/usr/openv/netbackup/bin/admincmd/bpdbjobs | grep -i active | awk '{print $1}' > /tmp/jobsactive;
for i in `/usr/openv/netbackup/bin/admincmd/bpdbjobs | grep -i active | awk '{print $1}'`; do bpdbjobs -cancel $i;done;
echo "Canceled active jobs, listed jobids below"
cat /tmp/jobsactive >> /$logpath/pre-reboot-checks.txt
echo -e "\n">> /$logpath/pre-reboot-checks.txt
echo "stopping nbu process" >>/$logpath/pre-reboot-checks.txt
service netbackup stop
sleep 60;
/opt/VRTSpbx/bin/vxpbx_exchanged stop
echo "checking if any process still running and killing  the same" >> /$logpath/pre-reboot-checks.txt
for i in `/usr/openv/netbackup/bin/bpps -x | awk '{print $2}' | egrep -v "Processes|Veritas"| uniq`;do kill -9 $i;done
echo "Stopped nbu processes" >>/$logpath/pre-reboot-checks.txt
/usr/openv/netbackup/bin/bpps -x >> /$logpath/pre-reboot-checks.txt
echo "############################################" >> /$logpath/pre-reboot-checks.txt
echo -e "\n">> /$logpath/pre-reboot-checks.txt
elif [[ $chk == 2 ]]
then
echo "Not proceeding to cancel active jobs and NBU services not stopped"

else
echo " enter 1-yes, 2-no for canceling active jobs and stopping nbu services"
fi

echo "Printing the PreReboot check output captured, please save it"
cat /$logpath/pre-reboot-checks.txt

elif [[ $check == 2 ]]
then

echo "" > /$logpath/post-reboot-checks.txt

echo "############################################" >> /$logpath/post-reboot-checks.txt
echo "logpath=$logpath" >> /$logpath/post-reboot-checks.txt
echo "hostname=$(hostname)" >>/$logpath/post-reboot-checks.txt
echo "uptime=$(uptime)" >>/$logpath/post-reboot-checks.txt
echo "Host status" >> /$logpath/post-reboot-checks.txt
/usr/openv/volmgr/bin/vmoprcmd >> /$logpath/post-reboot-checks.txt
echo "############################################" >> /$logpath/post-reboot-checks.txt
echo -e "\n" >> /$logpath/post-reboot-checks.txt

echo "nbemmcmd output" >> /$logpath/post-reboot-checks.txt
/usr/openv/netbackup/bin/admincmd/nbemmcmd -listhosts >>/$logpath/post-reboot-checks.txt
echo "############################################" >> /$logpath/post-reboot-checks.txt
echo -e "\n" >> /$logpath/post-reboot-checks.txt
echo "df-output" >> /$logpath/post-reboot-checks.txt
df -h >> /$logpath/post-reboot-checks.txt
echo "############################################" >> /$logpath/post-reboot-checks.txt
echo "Finding if any mountpoint is above 80% usage">> /$logpath/post-reboot-checks.txt
 df -h | sed 's/%//' > /tmp/df-out
cat /tmp/df-out | awk '{ if ($5 >= 80) print $ALL}' >> /$logpath/post-reboot-checks.txt
echo "############################################" >> /$logpath/post-reboot-checks.txt
echo -e "\n" >> /$logpath/post-reboot-checks.txt
echo "route details" >> /$logpath/post-reboot-checks.txt
ip route show >> /$logpath/post-reboot-checks.txt
ip route show > /tmp/routeshow1
echo "############################################" >> /$logpath/post-reboot-checks.txt
echo -e "\n" >> /$logpath/post-reboot-checks.txt
echo " Validating routes after reboot">> /$logpath/post-reboot-checks.txt
diff /tmp/routeshow /tmp/routeshow1 > /tmp/routediff
if [[ $(cat /tmp/routediff | egrep '<' | wc -l) -gt 0 ]]
then
echo "Below routes are missing based on precheck" >> /$logpath/post-reboot-checks.txt
cat /tmp/routediff | egrep '<' >> /$logpath/post-reboot-checks.txt
echo " Ensure to add the above mentioned routes and make it persistent" >> /$logpath/post-reboot-checks.txt
elif [[ $(cat /tmp/routediff | egrep '>' | wc -l) -gt 0 ]]
then
echo "Below routes are newly added after reboot based on precheck-data" >> /$logpath/post-reboot-checks.txt
cat /tmp/routediff | egrep '>' >> /$logpath/post-reboot-checks.txt
else
echo "No action required, routes are intact" >> /$logpath/post-reboot-checks.txt
fi
echo "############################################" >> /$logpath/post-reboot-checks.txt
echo -e "\n" >> /$logpath/post-reboot-checks.txt

echo "ifconfig output" >> /$logpath/post-reboot-checks.txt
ifconfig >> /$logpath/post-reboot-checks.txt
echo "############################################" >> /$logpath/post-reboot-checks.txt
echo "Validating ifconfig output" >> /$logpath/post-reboot-checks.txt
ifconfig | grep -i inet > /tmp/ifconfigout1
diff /tmp/ifconfigout /tmp/ifconfigout1 > /tmp/ifconfigdiff
if [[ $(cat /tmp/ifconfigdiff | egrep '<' | wc -l) -gt 0 ]]
then
echo "Below IP details are missing based on precheck" >> /$logpath/post-reboot-checks.txt
cat /tmp/ifconfigdiff | egrep '<' >> /$logpath/post-reboot-checks.txt
echo " Ensure to check with unix team about the missing interface" >> /$logpath/post-reboot-checks.txt
elif [[ $(cat /tmp/ifconfigdiff | egrep '>' | wc -l) -gt 0 ]]
then
echo "Below IP is added newly after reboot" >> /$logpath/post-reboot-checks.txt
cat /tmp/ifconfigdiff | egrep '>' >> /$logpath/post-reboot-checks.txt
else
echo "No action required, Ifconfig output is intact" >> /$logpath/post-reboot-checks.txt
fi
echo "############################################" >> /$logpath/post-reboot-checks.txt
echo -e "\n" >> /$logpath/post-reboot-checks.txt
echo "/etc/fstab details" >> /$logpath/post-reboot-checks.txt
cat /etc/fstab > /tmp/fstab1
cat /etc/fstab >> /$logpath/post-reboot-checks.txt
echo "############################################" >> /$logpath/post-reboot-checks.txt
echo "Validating fstab output" >> /$logpath/post-reboot-checks.txt
diff /tmp/fstab /tmp/fstab1 > /tmp/fstabdiff
if [[ $(cat /tmp/fstabdiff | egrep '<' | wc -l) -gt 0 ]]
then
echo "Below mount details are missing based on precheck" >> /$logpath/post-reboot-checks.txt
cat /tmp/fstabdiff | egrep '<' >> /$logpath/post-reboot-checks.txt
echo " Ensure to check with unix team about the missing mountpoint and add the same in /etc/fstab" >> /$logpath/post-reboot-checks.txt
elif [[ $(cat /tmp/fstabdiff | egrep '>' | wc -l) -gt 0 ]]
then
echo "Below mounts are added newly after reboot" >> /$logpath/post-reboot-checks.txt
cat /tmp/fstabdiff | egrep '>' >> /$logpath/post-reboot-checks.txt
else
echo "No action required,/etc/fstab/ output is intact" >> /$logpath/post-reboot-checks.txt
fi
echo "############################################" >> /$logpath/post-reboot-checks.txt
echo -e "\n" >> /$logpath/post-reboot-checks.txt
echo "Resuming scheduler" >> /$logpath/post-reboot-checks.txt
/usr/openv/netbackup/bin/admincmd/nbpemreq -resume_scheduling
echo "Scheduler resumed" >>  /$logpath/post-reboot-checks.txt
echo "############################################" >> /$logpath/post-reboot-checks.txt
echo -e "\n" >> /$logpath/post-reboot-checks.txt
echo " netbackup services output" >>  /$logpath/post-reboot-checks.txt
/usr/openv/netbackup/bin/bpps -x >> /$logpath/post-reboot-checks.txt
echo "############################################" >> /$logpath/post-reboot-checks.txt
echo -e "\n" >> /$logpath/post-reboot-checks.txt
echo "Printing the PostReboot check output captured, please save it"
cat /$logpath/post-reboot-checks.txt

else
echo " Please enter number 1 or 2"
echo "Enter 1 for Pre-reboot-check or 2 for Post-reboot-check"
fi

