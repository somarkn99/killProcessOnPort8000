#!/bin/bash

# Define exit status constants
SUCCESSFUL_STATUS=0
NO_ROOT_PRIVILEGES_STATUS=1
NETSTAT_NOT_FOUND_STATUS=2

# Check if the running user is root. If not, exit with an appropriate status.
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root"
    exit $NO_ROOT_PRIVILEGES_STATUS
fi

# Check if the netstat utility is installed. If not, exit with an appropriate status.
if ! command -v netstat &> /dev/null; then
    echo "This script requires the netstat command line utility to be installed"
    exit $NETSTAT_NOT_FOUND_STATUS
fi

# Get the list of all processes that use port 8000.
# The netstat command lists network connections, protocols, and listening ports.
# The output is filtered to find entries with port 8000, and awk extracts the process info.
PROCESS_LIST=$(netstat -tulpn | grep -i ":8000" | awk '{print $7}')

# Check if there are actual running processes using port 8000.
if [ -z "$PROCESS_LIST" ]; then
    echo "There are no processes using port 8000 on this device"
    exit $SUCCESSFUL_STATUS
fi

# Check for multiple processes using the same port.
# If found, it prompts manual checking.
if echo "$PROCESS_LIST" | grep -q " "; then
    echo "Multiple processes are using port 8000. Please check manually."
    exit $SUCCESSFUL_STATUS
fi

# Extract the process ID and name from the process list.
# The 'cut' command splits the string (process id/name) using '/' as delimiter.
PROCESS_ID=$(echo "$PROCESS_LIST" | cut -d'/' -f1)   # Extracts the process ID
PROCESS_NAME=$(echo "$PROCESS_LIST" | cut -d'/' -f2) # Extracts the process name

# Informing the user about the process being killed.
echo "Killing process ($PROCESS_NAME) with ID ($PROCESS_ID) ..."

# Attempt to kill the process with the extracted process ID.
# If successful, prints a confirmation message. Otherwise, prints an error message.
if kill -9 "$PROCESS_ID"; then
    echo "Process killed successfully"
else
    echo "Failed to kill process. Please check manually."
    exit 1
fi

# Exit the script successfully if everything goes as planned.
exit $SUCCESSFUL_STATUS
