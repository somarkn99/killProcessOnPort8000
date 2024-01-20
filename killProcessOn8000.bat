@echo off
setlocal

:: Find the process ID using port 8000
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000') do set PID=%%a

:: Check if a PID was found
if not defined PID (
    echo No process found using port 8000.
    goto end
)

:: Kill the process
echo Killing process with ID %PID%
taskkill /PID %PID% /F

:end
endlocal
