import os
import platform
import ctypes
import sys

class ProcessManager:
    def __init__(self, port):
        self.port = port
        self.system = platform.system()

    def is_admin(self):
        if self.system == "Windows":
            try:
                return ctypes.windll.shell32.IsUserAnAdmin()
            except:
                return False
        return os.getuid() == 0  # For Unix systems

    def get_process_info(self):
        process_info = None
        command = f"netstat -ano | findstr :{self.port}" if self.system == "Windows" else f"netstat -tulpn | grep :{self.port}"
        result = os.popen(command).read()
        lines = result.split('\n')

        for line in lines:
            if f":{self.port}" in line:
                tokens = line.split()
                if tokens:
                    pid = tokens[-1 if self.system in ["Linux", "Darwin"] else 4]
                    process_info = {"pid": pid, "name": self.get_process_name(pid)}
                    break  # Assuming only one process uses the port

        return process_info

    def get_process_name(self, pid):
        command = f"tasklist /fi \"pid eq {pid}\" /fo csv" if self.system == "Windows" else f"ps -p {pid} -o comm="
        result = os.popen(command).read()
        if self.system == "Windows" and len(result.split('\n')) > 1:
            return result.split('\n')[1].strip('"').split('","')[0]
        return result.strip()

    def kill_process(self, process_info):
        print(f"Killing process with ID {process_info['pid']} ({process_info['name'] or 'No name available'})")
        if self.system == "Windows":
            self.kill_windows_process(process_info)
        else:
            os.system(f"kill -9 {process_info['pid']}")

    def kill_windows_process(self, process_info):
        if self.is_admin():
            os.system(f"taskkill /F /PID {process_info['pid']}")
        else:
            ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)

def main():
    while True:
        port = input("Enter the port to check (press Enter to exit): ")
        if not port:
            break

        process_manager = ProcessManager(port)
        process_info = process_manager.get_process_info()

        if process_info:
            stop_process = input(f"Process with ID {process_info['pid']} and name '{process_info['name']}' is using port {port}. Do you want to stop it? (y/n): ").lower()
            if stop_process == "y":
                process_manager.kill_process(process_info)
            else:
                print("Process will not be stopped.")
        else:
            print(f"No process found using port {port}.")

if __name__ == "__main__":
    main()