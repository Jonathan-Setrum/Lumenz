#!/bin/bash
echo "*********************************************************************"
echo "*******************Primary server Post check/Audit*******************"
echo "*********************************************************************"
echo -e "\n"
echo "******Ensure to check the following manualy**********"
echo "1. Password portal"
echo "2. Confluence pages and DCIM portal are up-to-date with details"
echo "3. Ensure Opscenter reports created and Recipients  added"
echo "4. Ensure DNS entry added for Appliance mgmt on DMS portal"
echo "5. Vantive - Ensure xref is updated for ticket trapping (must match the display name of the master from opscenter), Set Appliance and Master to Installed"
echo "6. Ensure Data collection on Opscenter is enabled"
echo "7. Validate catalog passphrase"
echo "8. Ensure resource limit set with value 6 for vCenter, Datastore and ESXserver"
echo -e "\n"
echo " ######################################"
echo "Master version and media server details"
echo " ######################################"
echo "hostname = "$(hostname)"
/usr/openv/volmgr/bin/vmoprcmd -devmon hs
echo -e "\n"

echo " ##############"
echo "Opscenter check"
echo " ##############"
ops=`cat /usr/openv/netbackup/bp.conf | grep -i OPS_CENTER_SERVER_NAME |awk '{print $3}'`

if [ -z "$ops" ]
then
echo "!!!Incorrect, Opscenter entry doesn't exist"

elif [[ $ops == "dc2nbuctsops1.mgmt.savvis.net" ]]
then
echo "!!!Correct, Opscenter set for shared DPB,"$ops

elif [[ $ops == "dc2cpcnbuops1.na.msmps.net" ]]
then
echo "!!!Correct, Opscenter set for LPC build,"$ops

elif [[ $ops == "dc2sapnbuops1.na.msmps.net" ]]
then
echo "!!!Correct, Opscenter set for SAP,"$ops
else
echo "!!!Incorrect, Opscenter name set incorrectly, action required, "$ops
fi
echo -e "\n"
echo " #######################"
echo " Vcenter and VCD details"
echo " #######################"
if [[ -z $( tpconfig -dvirtualmachines | egrep -v 'SubType:' ) ]]
then
echo " No VCD policy detected "
else
echo " Printing VCD details"
tpconfig -dvirtualmachines | egrep -v 'SubType:'
echo -e "\n"
fi
echo " #####################################################################"
echo " Validating NB mount points details nbdb=750G, nblog=500G, nbapp=50G"
echo " #####################################################################"

if [ -d "/nbdb" ];
 then

dbsize=`df -Ph  /nbdb| grep -i /nbdb| awk '{print $2}'`
if [[ $( df -P | grep -i /nbdb | awk '{print $2}' ) -gt 703953992 ]];
 then
 echo " !!!Correct, nbdb mount point is set more than 670G,actual allocated size is "$dbsize;
else
echo "!!!Incorrect, nbdb mount point is less than 670G, action required,actual allocated size is "$dbsize;
fi
 else 
echo "!!!Incorrect -- nbdb dir not exists, action required";
 fi;

if [ -d "/nblog" ];
 then

logsize=`df -Ph  /nblog| grep -i /nblog| awk '{print $2}'`
if [[ $( df -P | grep -i /nblog | awk '{print $2}' ) -gt 505924224 ]];
 then
 echo " !!!Correct, nblog mount point is set more than 480G,actual allocated size is "$logsize;
else
echo " !!!Incorrect, nblog mount point is less than 480G, action required, actual allocated size is "$logsize;
fi
echo -e "\n"
 else 
echo "!!!Incorrect -- nblog dir not exists, action required";
 fi;


if [ -d "/nbapp" ];
 then
appsize=`df -Ph  /nbapp| grep -i /nbapp| awk '{print $2}'`
if [[ $( df -P| grep -i /nbapp | awk '{print $2}' ) -gt 50470816 ]];
 then
 echo " !!!Correct, nbapp mount point is set more than 48G,actual allocated size is "$appsize;
else
echo "!!!Incorrect, nbapp mount point is less than 48G, action required,actual allocated size is "$appsize;
fi
 else 
echo "!!!Incorrect -- nbapp dir not exists, action required";
 fi;



echo -e "\n"
echo " ###################################"
echo " Displaying soft links"
echo " ###################################"
find /usr/openv/ -type l -ls|grep " /nb"
echo -e "\n"
echo " ###################################"
echo " Displaying DR path"
echo " ###################################"
for i in `bppllist`; do type=`bppllist $i -U | grep -i 'Policy Type:' | awk '{ print $3}'`; if [[ $type == "NBU-Catalog" ]]; then echo $i;cat_pol=`echo $i`;/usr/openv/netbackup/bin/admincmd/bppllist $i -U |grep -i 'Disk Path' ;fi;done
echo -e "\n"
echo " ###################################"
echo " validating NBUDR ownership"
echo " ###################################"
ver=`cat /usr/openv/netbackup/version  | grep -i VERSION | awk '{print $3}'`
if [[ $ver == "8.2" ]]
then
nbudr_path=`/usr/openv/netbackup/bin/admincmd/bppllist $cat_pol -U |grep -i 'Disk Path'|awk '{print $3}'| awk ' BEGIN {FS = "/"}; {print $2}'|sed 's/^/\//'`
nbudr_path1=`/usr/openv/netbackup/bin/admincmd/bppllist $cat_pol -U |grep -i 'Disk Path'|awk '{print $3}'| awk ' BEGIN {FS = "/"}; {print $3}'`
 if [[ $( ls -lrt $nbudr_path|grep -i $nbudr_path1|awk '{print $3,$4}' | sed 's/ /:/g' ) == "root:root" ]];
 then
  echo "!!!correct, ownership is set correctly, as current netbackup version is"$ver;
echo "to upgrade the master server from 8.2 to 9.x, make sure to have the DR location ownership set as nbsvcadm:bin"
  fi
elif [[ $ver == "9.1" || $ver == "9.1.0.1" ]]
then
cat_pol=`/usr/openv/netbackup/bin/admincmd/bppllist | grep -i catalog | grep -v Dedupe`
nbudr_path=`/usr/openv/netbackup/bin/admincmd/bppllist $cat_pol -U |grep -i 'Disk Path'|awk '{print $3}'| awk ' BEGIN {FS = "/"}; {print $2}'|sed 's/^/\//'`
nbudr_path1=`/usr/openv/netbackup/bin/admincmd/bppllist $cat_pol -U |grep -i 'Disk Path'|awk '{print $3}'| awk ' BEGIN {FS = "/"}; {print $3}'`
 if [[ $( ls -lrt $nbudr_path|grep -i $nbudr_path1|awk '{print $3,$4}' | sed 's/ /:/g' ) == "nbsvcadm:bin" ]];
 then
  echo "!!!correct, ownership is set correctly, as current netbackup version is"$ver;
 fi
else
  echo "!!!Incorrect, check the netbackup version and accordingly check ownership on DR location"
fi
echo -e "\n"
echo " ###################################"
echo " Displaying Storage server details"
echo " ###################################"
/usr/openv/netbackup/bin/admincmd/nbdevquery -liststs -U -stype PureDisk|egrep 'Storage Server|Storage Server Type|State'
echo -e "\n"
echo " ###################################"
echo " Displaying Diskpool details"
echo " ###################################"
/usr/openv/netbackup/bin/admincmd/nbdevquery -listdp -stype PureDisk -U |egrep 'Disk Pool Name|Disk Type|Status|Raw Size (GB)|Usable Size (GB)|Max IO Streams|Watermark|Storage Server'
echo -e "\n"
echo " ###################################"
echo " Displaying Diskvolume details"
echo " ###################################"
/usr/openv/netbackup/bin/admincmd/nbdevquery -listdv -stype PureDisk -U |egrep 'Disk Pool Name|Disk Type|Total Capacity|Free Space|Use%|Status'
echo -e "\n"
echo " ###################################"
echo " Displaying Storage unit details"
echo " ###################################"
for i in `bpstulist -l | awk '{print $1}'`
do
echo "label: "$i
/usr/openv/netbackup/bin/admincmd/bpstulist -label $i -U | egrep 'Label |Storage Unit Type:|Concurrent Jobs'
echo -e "\n"
done
echo -e "\n"
echo " ###################################"
echo " Displaying SLP details"
echo " ###################################"
for i in `/usr/openv/netbackup/bin/admincmd/nbstl -b`; do echo "====================="; nbstl $i -L |egrep -i 'Name: |Operation  | Storage:|State: |Retention Level:|Source Volume| Target Volume' | egrep -vi 'window Name'; done
echo -e "\n"
echo " ###################################"
echo " Displaying VCD query"
echo " ###################################"
for i in `bppllist`; do type=`bppllist $i -U | grep -i 'Policy Type:' | awk '{ print $3}'`;
if [[ $type == "VMware" ]]; then echo $i;
/usr/openv/netbackup/bin/admincmd/bppllist $i -U | egrep -i 'Policy Name:       |Policy Type:         |Active:              |Residence:           | HW/OS/Client:  |Include'
/usr/openv/netbackup/bin/admincmd/bpplsched $i -U |egrep 'Schedule:              |Type:                |Frequency:           '
echo -e "\n"
/usr/openv/netbackup/bin/admincmd/bpplsched $i -U |grep -A15 "Daily Windows"
echo -e "\n"

fi
done
echo " ###################################"
echo " Displaying FS policy"
echo " ###################################"
for i in `bppllist`
do
 type=`bppllist $i -U | grep -i 'Policy Type:' | awk '{ print $3}'`;
 if [[ $type == "Standard" ]]; 
then 
	if [[ $( bppllist $i -U | grep -i 'HW/OS/Client' |awk '{ print $4}'| cut -d "." -f 1|cut -d "-" -f 1 ) == $( hostname | cut -d "." -f 1|cut -d "-" -f 1 ) ]]; 
	then echo $i,$type;
	bppllist $i -U | grep -i active; 
	
	fi;
fi  ;	
done
echo " ###################################"
echo " Displaying Catalog policy"
echo " ###################################"
for i in `bppllist`; do type=`bppllist $i -U | grep -i 'Policy Type:' | awk '{ print $3}'`; if [[ $type == "NBU-Catalog" ]]; then echo $i;/usr/openv/netbackup/bin/admincmd/bppllist $i -U |grep -i 'Disk Path' ;

/usr/openv/netbackup/bin/admincmd/bppllist $i -U | egrep -i 'Policy Name:       |Policy Type:         |Active:              |Residence:           | HW/OS/Client:  |Include'
/usr/openv/netbackup/bin/admincmd/bpplsched $i -U |egrep 'Schedule:              |Type:                |Frequency:           '
echo -e "\n"
/usr/openv/netbackup/bin/admincmd/bpplsched $i -U |grep -A15 "Daily Windows"
echo -e "\n"
fi;
done
echo -e "\n"



echo " ###########################################"
echo " Displaying Mail relay and myorigin details"
echo " ###########################################"
cat /etc/postfix/main.cf | egrep -i 'relay|myorigin' | egrep -v '#'
echo -e "\n"
echo " ###########################################"
echo " Displaying Resolv and ntp.conf details"
echo " ###########################################"
echo -e "\n"
echo "/etc/resolv.conf output"
cat /etc/resolv.conf
echo -e "\n"
echo "/etc/ntp.conf output"
cat /etc/ntp.conf
echo " ###########################################"
echo " validating ntp"
echo " ###########################################"
ntpstat > /dev/null 2>&1
statout=`echo $?`
 if [[ $statout == 0 ]]
then
echo " !!!correct, Clock is synchronised"
elif [[ $statout == 1 ]]
then
echo " !!!Incorrect, Clock is not synchronised"
else
echo " !!!Incorrect, clock state is indeterminant, Action required"
fi
echo -e "\n"
echo " ###########################################"
echo " Displaying /etc/hosts details"
echo " ###########################################"

cat /etc/hosts
echo -e "\n"
echo " ###########################################"
echo " Displaying SIA details and status"
echo " ###########################################"
echo " event details"
cat /usr/local/monitor/gen_events.cfg | grep -i NetBackup |egrep -v "#"
echo "############"
echo " SIA status"
echo "############"
monitor status | grep -i NBU
echo -e "\n"
echo " ######################################################################################"
echo " Validating Max jobs per client is set to Max Simultaneous Jobs/Client = 10"
echo " ######################################################################################"
if [[ $( bpconfig -U | grep -i 'Max Simultaneous Jobs/Client:' |awk '{print $4}' ) == 10 ]]
then
echo "!!!Correct, Max job per client set correctly"
else
echo "!!!Incorrect, Max job per client not set correctly, action required"
fi

echo -e "\n"
echo " ###########################################"
echo " Validating log dirs"
echo " ###########################################"

for i in admin bpcd bpdbm bpjobd bprd tar;
 do
if [ -d "/usr/openv/netbackup/logs/$i" ];
 then
echo $i"!!!Correct -- dir exists";
 else 
echo $i"!!!Incorrect -- dir not exists, action required";
 fi;
done
echo -e "\n"
echo " ################################################################"
echo " Validating Client read and connect timeout is set to value 900"
echo " ################################################################"
echo " Current values "
cat /usr/openv/netbackup/bp.conf |egrep -i 'CLIENT_READ_TIMEOUT|CLIENT_CONNECT_TIMEOUT'
for i in `cat /usr/openv/netbackup/bp.conf |egrep -i 'CLIENT_READ_TIMEOUT|CLIENT_CONNECT_TIMEOUT'|sed 's/ //g'`;
 do
 if [[ $i == "CLIENT_READ_TIMEOUT=900" ]];
 then
 echo "!!!Correct, CLIENT_READ_TIMEOUT is set correctly";

  elif [[ $i == "CLIENT_CONNECT_TIMEOUT=900" ]];
then
echo "!!!Correct, CLIENT_CONNECT_TIMEOUT is set correctly";
 else
echo " !!!Incorrect, verify the Timeout values as its not having 900";
 fi;

done

echo -e "\n";
echo -e "\n";
echo "--------------------------------------------------------------------------------------------"

echo "*********************************************************************"
echo "*************Tuning parameter Check on Primary server****************"
echo "*********************************************************************"

echo "hostname = "$(hostname)
echo -e "\n"

echo "#####################################################"
echo "###To validate vm.overcommit_ratio=100 using sysctl###"
ocr=`sysctl vm.overcommit_ratio |awk '{print $3}'`
if [ -z "$ocr" ]
then
echo "!!!Incorrect, vm.overcommit_ratio parameter doesnt exists under /proc/sys/vm/overcommit_ratio"
elif [[ $ocr -eq 100 ]]
then
echo "!!!Correct, vm.overcommit_ratio setting is good under /proc/sys/vm/overcommit_ratio, current setting is " $ocr
else
echo "!!!Incorrect, vm.overcommit_ratio setting to be changed, current setting is " $ocr;
fi
echo -e "\n"

echo "###To validate vm.overcommit_ratio=100 under /etc/sysctl.conf###"
ocr1=`cat /etc/sysctl.conf| grep -i vm.overcommit_ratio`
if [ -z "$ocr1" ]
then
echo "!!!Incorrect, vm.overcommit_ratio parameter doesnt exists"
elif [[ $(cat /etc/sysctl.conf| grep -ic vm.overcommit_ratio) -ge 2 ]]
then
echo "Ensure to have one entry vm.overcommit_ratio, multiple lines detected";
elif [[ $ocr1 == "vm.overcommit_ratio = 100" ]]
then
echo "!!!Correct, vm.overcommit_ratio setting is good, current setting is " $ocr1;
elif [[ $ocr1 == "vm.overcommit_ratio= 100" ]]
then
echo "!!!Correct, vm.overcommit_ratio setting is good, current setting is " $ocr1;
elif [[ $ocr1 == "vm.overcommit_ratio=100" ]]
then
echo "!!!Correct, vm.overcommit_ratio setting is good, current setting is " $ocr1;
elif [[ $ocr1 == "vm.overcommit_ratio =100" ]]
then
echo "!!!Correct, vm.overcommit_ratio setting is good, current setting is " $ocr1;
else
echo "!!!Incorrect, vm.overcommit_ratio setting to be changed, current setting is " $ocr1;
fi
echo -e "\n"
echo "#####################################################"
echo -e "\n"
echo "###To validate kernel.sem=300 307200 32 1024 using sysctl###"
kersem1=`sysctl kernel.sem | awk '{print $3,$4,$5,$6}'`
if [ -z "$kersem1" ]
then
echo "!!!Incorrect, kernel.sem parameter doesnt exists under /proc/sys/kernel/sem"
echo "Kernel.sem Parameter to be added using sysctl"
elif [[ $kersem1 == "300        307200  32      1024" ]]
then
echo "!!!Correct, kernel.sem setting is good under /proc/sys/kernel/sem, current setting is " $kersem1
elif [[ $kersem1 == "300 307200 32 1024" ]]
then
echo "!!!Correct, kernel.sem setting is good under /proc/sys/kernel/sem, current setting is " $kersem1
else
echo "!!!Incorrect, kernel.sem setting to be changed, current setting is " $kersem1;
fi
echo -e "\n"


echo "###To validate kernel.sem=300 307200 32 1024 under /etc/sysctl.conf###"
kersem=`cat /etc/sysctl.conf | grep -i 'kernel.sem'`
kersem2=`cat /etc/sysctl.conf | grep -i 'kernel.sem'| sed 's/\s\+/ /g' |awk ' BEGIN{ FS = "=" };{print $2}'`
if [ -z "$kersem" ]
then
echo "!!!Incorrect, kernel sem parameter doesnt exists"
echo "Kernel.sem Parameter to be added to /etc/sysctl.conf "
elif [[ $(cat /etc/sysctl.conf| grep -ic kernel.sem) -ge 2 ]]
then
echo "Ensure to have one entry kernel.sem, multiple lines detected";
elif [[ $kersem == "300 307200 32 1024" ]]
then
echo "!!!Correct, kernel sem setting is good, current setting is " $kersem
elif [[ $kersem == "kernel.sem= 300 307200 32 1024" ]]
then
echo "!!!Correct, kernel sem setting is good, current setting is " $kersem
elif [[ $kersem == "kernel.sem =300 307200 32 1024" ]]
then
echo "!!!Correct, kernel sem setting is good, current setting is " $kersem
elif [[ $kersem2 == "300 307200 32 1024" ]]
then
echo "!!!Correct, kernel sem setting is good, current setting is " $kersem2;
elif [[ $kersem2 == " 300 307200 32 1024" ]]
then
echo "!!!Correct, kernel sem setting is good, current setting is " $kersem2;
else
echo "!!!Incorrect, kernel sem setting to be changed, current setting is " $kersem;
fi
echo -e "\n"

echo "#####################################################"

echo -e "\n"
echo "###Validate vm.swappiness=1 using sysctl ###"
vmswap1=`sysctl vm.swappiness`
if [ -z "$vmswap1" ]
then
echo "!!!Incorrect, vm.swappiness parameter doesnt exists under /proc/sys/vm/swappiness"
echo " vm.swappiness setting to be added using sysctl"
elif [[ $vmswap1 == "vm.swappiness = 1" ]]
then
echo "!!!Correct, vm.swappiness setting is good under /proc/sys/vm/swappiness, current setting is " $vmswap1;
else
echo "!!!Incorrect, vm.swappiness setting to be changed, current setting is " $vmswap1;
fi
echo -e "\n"


echo "###To validate vm.swappiness=1 under /etc/sysctl.conf###"
vmswap=`cat /etc/sysctl.conf | grep -i 'vm.swappiness'`
if [ -z "$vmswap" ]
then
echo "!!!Incorrect, vm.swappiness parameter doesnt exists";
elif [[ $(cat /etc/sysctl.conf| grep -ic vm.swappiness) -ge 2 ]]
then
echo "Ensure to have one entry vm.swappiness, multiple lines detected";
elif [[ $vmswap == "vm.swappiness = 1" ]]
then
echo "!!!Correct, vm.swappiness setting is good, current setting is " $vmswap
elif [[ $vmswap == "vm.swappiness=1" ]]
then
echo "!!!Correct, vm.swappiness setting is good, current setting is " $vmswap
elif [[ $vmswap == "vm.swappiness =1" ]]
then
echo "!!!Correct, vm.swappiness setting is good, current setting is " $vmswap
elif [[ $vmswap == "vm.swappiness= 1" ]]
then
echo "!!!Correct, vm.swappiness setting is good, current setting is " $vmswap
else
echo "!!!Incorrect, vm.swappiness setting to be changed, current setting is " $vmswap;
fi
echo -e "\n"

echo "#####################################################"
rhe=`cat /etc/redhat-release | awk '{print $7}'`
echo " redhat release " $rhe

echo "###Validate kernel.numa_balancing=0 using sysctl ###"
knb=`sysctl kernel.numa_balancing`
if [ -z "$knb" ]
then
echo "!!!Incorrect, kernel.numa_balancing parameter doesnt exists under /proc/sys/kernel/numa_balancing"
echo " value 0 to be added  using sysctl"
elif [[ $knb == "kernel.numa_balancing = 0" ]]
then
echo "!!!Correct, kernel.numa_balancing setting is good under /proc/sys/kernel/numa_balancing, current setting is " $knb;
else
echo "!!!Incorrect, kernel.numa_balancing setting to be changed, current setting is " $knb;
echo " value 0 to be added to kernel.numa_balancing using sysctl"
fi
echo -e "\n"


echo "###kernel.numa_balancing=0 under /etc/sysctl.conf###"
ker=`cat /etc/sysctl.conf | grep -i "kernel.numa_balancing"`
if [ -z "$ker" ]
then
echo "!!!Incorrect, kernel.numa_balancing parameter doesnt exist"
elif [[ $(cat /etc/sysctl.conf| grep -ic kernel.numa_balancing) -ge 2 ]]
then
echo "Ensure to have one entry kernel.numa_balancing, multiple lines detected";

elif [[ $ker ==  "kernel.numa_balancing = 0" ]]
then
echo "!!!Correct, kernel.numa_balancing setting is good, current setting is " $ker
elif [[ $ker ==  "kernel.numa_balancing=0" ]]
then
echo "!!!Correct, kernel.numa_balancing setting is good, current setting is " $ker
elif [[ $ker ==  "kernel.numa_balancing =0" ]]
then
echo "!!!Correct, kernel.numa_balancing setting is good, current setting is " $ker
elif [[ $ker ==  "kernel.numa_balancing= 0" ]]
then
echo "!!!Correct, kernel.numa_balancing setting is good, current setting is " $ker
else
echo "!!!Incorrect, kernel.numa_balancing setting change required"
fi
echo -e "\n"

echo -e "\n"

echo "#####################################################"

echo "###Validate vm.min_free_kbytes using sysctl###"

freekb1=`sysctl vm.min_free_kbytes | awk '{print $3}'`
RAM=`free -h | grep Mem |awk '{print $2}' |sed 's/[^0-9.]*//g' | awk '{print int($1+0.5)}'`
echo "Total RAM available is (GB)" $RAM
if [[ $RAM -ge 60  &&  $RAM -le 100 ]];
then
echo "vm.min_free_kbytes setting is eligible to have 1048576  under /proc/sys/vm/min_free_kbytes, current setting is " $freekb1

elif [[ $RAM -ge 101 && $RAM -le 130 ]];
then
echo "vm.min_free_kbytes setting is eligible to have 2097152 under /proc/sys/vm/min_free_kbytes, current setting is " $freekb1


elif [[ $RAM -ge 131 && $RAM -le 260 ]];
then
echo "vm.min_free_kbytes setting is eligible to have 3145728 under /proc/sys/vm/min_free_kbytes, current setting is " $freekb1


elif [[ $RAM -ge 17 && $RAM -le 59 ]]
then
echo " System RAM is low, please validate and add if required"
elif [[ $RAM -lt 16 ]];
then
echo " !!!Incorrect, System RAM is low and not eligible to be as master server, please validate. If test server then ignore"

else
echo "check with Veritas to get tuning parameter for vm.min_free_kbytes, as memory is more than 256"
fi

echo -e "\n"

echo "###To validate vm.min_free_kbytes under /etc/sysctl.conf###"

freekb=`cat /etc/sysctl.conf| grep -i vm.min_free_kbytes`
RAM=`free -h | grep Mem |awk '{print $2}' |sed 's/[^0-9.]*//g' | awk '{print int($1+0.5)}'`
if [ -z "$freekb" ]
then
echo "!!!Incorrect, Current vm.min_free_kbytes setting is Null"
echo " Add vm.min_free_kbytes setting to /etc/sysctl.conf based on RAM"
RAM=`free -h | grep Mem |awk '{print $2}' |sed 's/[^0-9.]*//g' | awk '{print int($1+0.5)}'`

elif [[ $(cat /etc/sysctl.conf| grep -ic vm.min_free_kbytes) -ge 2 ]]
then
echo " Ensure to have one entry vm.min_free_kbytes, multiple lines detected";

elif [[ $freekb1 -le 1048576 && ( "$RAM" -ge "1" && "$RAM" -le "59" ) ]]
then
echo "vm.min_free_kbytes current setting is low & not as per standards and RAM specification to be checked and tune this parameter with veritas recommendations"

elif [[ $freekb1 == 1048576 && ( "$RAM" -ge "60"  &&  "$RAM" -le "100" ) ]]
then
echo " vm.min_free_kbytes setting is good as per RAM specification, current setting is " $freekb1", RAM is " $RAM

elif [[ $freekb1 == 2097152 && ( "$RAM" -ge "101" && "$RAM" -le "130" ) ]]
then
echo " vm.min_free_kbytes setting is good as per RAM specification, current setting is " $freekb1", RAM is " $RAM

elif [[ $freekb1 == 3145728 && ( "$RAM" -ge "131" && "$RAM" -le "260" ) ]]
then
echo " vm.min_free_kbytes setting is good as per RAM specification, current setting is " $freekb1", RAM is " $RAM

else
echo "check with Veritas to get tuning parameter for vm.min_free_kbytes, as memory is more than 256"
fi

if [[ $freekb1 -le 1048576 && ( "$RAM" -ge "60"  &&  "$RAM" -le "100" ) ]]
then
echo " Add vm.min_free_kbytes = 1048576 to /etc/sysctl.conf, Current value is" $freekb1", RAM is " $RAM;


elif [[ $freekb1 -le 1048576 && ( "$RAM" -ge "101" && "$RAM" -le "130" ) ]]
then
echo " Add vm.min_free_kbytes = 2097152 to /etc/sysctl.conf, Current value is" $freekb1", RAM is " $RAM;


elif [[ $freekb1 -le 1048576 && ( "$RAM" -ge "131" && "$RAM" -le "260" ) ]]
then
echo " Add vm.min_free_kbytes = 3145728 to /etc/sysctl.conf, Current value is" $freekb1", RAM is " $RAM;


elif [[ $freekb1 -le 1048576 && ( "$RAM" -ge "16" && "$RAM" -le "59" ) ]]
then
echo "  System RAM is low, please validate and add if required and Fine tune vm.min_free_kbytes under /etc/sysctl.conf"

elif [[ $freekb1 -le 1048576 &&  $RAM -le 15 ]]
then
echo "  System RAM is low and not eligible to be as master server, please validate. If test server then ignore"


elif [[ ( "$freekb1" -ge "1048576" && "$freekb1" -le "2097152" )  && ( "$RAM" -ge "101" && "$RAM" -le "130" ) ]]
then
echo " Add vm.min_free_kbytes = 2097152 to /etc/sysctl.conf, Current value is" $freekb1", RAM is " $RAM;


elif [[ ( "$freekb1" -ge "1048576" && "$freekb1" -le "2097152" )  && ( "$RAM" -ge "131" && "$RAM" -le "260" ) ]]
then
echo " Add vm.min_free_kbytes = 3145728 to /etc/sysctl.conf, Current value is" $freekb1", RAM is " $RAM;

elif [[ ( "$freekb1" -ge "1048576" && "$freekb1" -le "2097152" )  && ( "$RAM" -ge "60"  &&  "$RAM" -le "100" ) ]]
then
echo " Add vm.min_free_kbytes = 1048576 to /etc/sysctl.conf, Current value is" $freekb1", RAM is " $RAM;



elif [[ ( "$freekb1" -ge "2097152" && "$freekb1" -le "3145728" )  && ( "$RAM" -ge "131" && "$RAM" -le "260" ) ]]
then
echo " Add vm.min_free_kbytes = 3145728 to /etc/sysctl.conf, Current value is" $freekb1", RAM is " $RAM;


elif [[ ( "$freekb1" -ge "2097152" && "$freekb1" -le "3145728" )  && ( "$RAM" -ge "101" && "$RAM" -le "130" ) ]]
then
echo " Add vm.min_free_kbytes = 2097152 to /etc/sysctl.conf, Current value is" $freekb1", RAM is " $RAM;


elif [[ ( "$freekb1" -ge "2097152" && "$freekb1" -le "3145728" )  && ( "$RAM" -ge "60"  &&  "$RAM" -le "100" ) ]]
then
echo " Add vm.min_free_kbytes = 1048576 to /etc/sysctl.conf, Current value is" $freekb1 ", RAM is " $RAM;


elif [[ $freekb1 -ge 3145728 && ( "$RAM" -ge "60"  &&  "$RAM" -le "100" ) ]]
then
echo " Add vm.min_free_kbytes = 1048576 to /etc/sysctl.conf, Current value is" $freekb1 ", RAM is " $RAM;


elif [[ $freekb1 -ge 3145728 && ( "$RAM" -ge "101" && "$RAM" -le "130" ) ]]
then
echo " Add vm.min_free_kbytes = 2097152 to /etc/sysctl.conf, Current value is" $freekb1", RAM is " $RAM;

elif [[ $freekb1 -ge 3145728 && ( "$RAM" -ge "131" && "$RAM" -le "260" ) ]]
then
echo " Add vm.min_free_kbytes = 3145728 to /etc/sysctl.conf, Current value is" $freekb1 ", RAM is " $RAM;

elif [[ $freekb1 -ge 3145728 && $RAM -ge 261 ]]
then
echo " Add vm.min_free_kbytes = 3145728 to /etc/sysctl.conf, Current value is" $freekb1 ", RAM is " $RAM;


else
echo "check with Veritas to get tuning parameter for vm.min_free_kbytes, as memory is more than 256"
fi

echo -e "\n"


echo -e "\n"
echo "#####################################################"
echo "###To validate Transperant_hugepage=never###"
hp=`cat /etc/default/grub | grep '\ transparent_hugepage=never"$' | grep -o never`
thpe=`cat /sys/kernel/mm/transparent_hugepage/enabled`
echo "/sys/kernel/mm/transparent_hugepage/enabled value is " $thpe;

thpd=`cat /sys/kernel/mm/transparent_hugepage/defrag`
echo "/sys/kernel/mm/transparent_hugepage/defrag value is " $thpd;
if [ -z "$hp" ]
then
echo "!!!Incorrect, transparent_hugepage doesnt exists under /etc/default/grub, ensure transparent_hugepage=never to the end of GRUB_CMDLINE_LINUX line"
elif [[ $hp -eq never ]]
then
echo " !!!Correct, transparent_hugepage is good as per requirement, current setting is "$hp;
else
echo "!!!Incorrect, transparent_hugepage required to change as per requirement, ensure transparent_hugepage=never to the end of GRUB_CMDLINE_LINUX line,current setting is " $hp;
fi

echo -e "\n"
echo "#####################################################"
