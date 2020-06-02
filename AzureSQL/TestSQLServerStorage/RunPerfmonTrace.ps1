<#
Commands to Create/Start/Stop/Delete a Performance Monitor (perfmon/sysmon) trace
#>
$blgfile="DiskSpd.blg"

#create a perfmon trace
logman create counter DiskSpd_PERF -f bin -si 5 -max 20000 --v -y -o $blgfile -cf DiskSpd_PERFCounters.config

#logman query DiskSpd_PERF
#start perfmon trace
logman start DiskSpd_PERF

#stop the perfmon trace
logman stop DiskSpd_PERF

#delete the perfmon trace
logman delete DiskSpd_PERF
