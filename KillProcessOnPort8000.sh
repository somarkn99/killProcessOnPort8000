#!/bin/bash

SUCCESSFUL_STATUS=0
NO_ROOT_PRIVILEGES_STATUS=1
NETSTAT_NOT_FOUND_STATUS=2

if [ "$EUID" -ne 0 ] # check if the running user is root
    then echo "This script must be run using as root";
    exit $NO_ROOT_PRIVILEGES_STATUS
fi

if [ -z $(command -v netstat) ] # check if the netstat utility is installed on the device
then
    echo "This script requires the netstat command line utility to be installed";
    exit $NETSTAT_NOT_FOUND_STATUS
fi

# get the list of all processes (pid/name) which has server sockets that listens to all TCP and UDP connections
# and filter only those that listen on port 8000, then extract the part that contains the process id and process name
PROCESS=$(netstat -tulpn | grep -i ":8000" | awk '{print $7}')

if [ -z $PROCESS ] # check if there are actual running processes from the result, if not then exit the script successfully
then
    echo "There are no processes that uses port 8000 on this device"
    exit $SUCCESSFUL_STATUS
fi

# normally, the seventh segment returned by the awk command from the previous command contains process information in
# the form (process id/process name), so we'll extract the process id and process name by splitting the string using
# forward slash (/) as a delimiter, this gives us an array which contains two elements
PROCESSID=$(echo $PROCESS | awk '{split($1,chunks, "/"); print chunks[1]}')     # the first element is the process id
PROCESSNAME=$(echo $PROCESS | awk '{split($1,chunks, "/"); print chunks[2]}')   # the second element is the process name

echo "Killing process ($PROCESSNAME) with ID ($PROCESSID) ..."  # print an informative message
kill -9 $PROCESSID                                              # send a kill signal to the process
echo "Process killed successfully"
exit $SUCCESSFUL_STATUS
