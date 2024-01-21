@echo off
setlocal

:: Initialize variables
:: PORT - The port number to check for processes
:: PID - To store the Process ID using the port
set PORT=8000
set PID=

:: Find the process ID using port 8000
:: The 'netstat -ano' command lists all ports and their corresponding process IDs
:: 'findstr /R /C:":%PORT% "' filters the list for the specified port
:: 'findstr /V "LISTENING"' excludes entries that are just listening on the port
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /R /C:":%PORT% " ^| findstr /V "LISTENING"') do (
    if defined PID (
        :: If PID is already set, it means multiple processes are using the port
        echo Multiple processes found using port %PORT%, using PID %%a.
        goto MultipleFound
    ) else (
        :: Set PID for the first found process using the port
        set PID=%%a
    )
)

:: Check if a PID was found
if not defined PID (
    :: No process is using the specified port
    echo No process found using port %PORT%.
    goto End
)

:: Kill the process
:: 'taskkill /PID %PID% /F' forcefully terminates the process with the found PID
echo Killing process with ID %PID%.
taskkill /PID %PID% /F
goto End

:MultipleFound
:: This section handles the scenario where multiple processes were found using the port
echo More than one process is using port %PORT%. Please check manually.
goto End

:End
:: End of script and local environment cleanup
endlocal