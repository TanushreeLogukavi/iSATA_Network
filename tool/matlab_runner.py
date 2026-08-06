import os
import sys
import subprocess
import shutil

def find_matlab_executable():
    """
    Locates the MATLAB executable on system PATH or standard installation paths.
    """
    matlab_bin = shutil.which("matlab")
    if matlab_bin:
        return matlab_bin
    
    # Common Windows MATLAB install paths
    possible_paths = [
        r"C:\Program Files\MATLAB\R2024a\bin\matlab.exe",
        r"C:\Program Files\MATLAB\R2023b\bin\matlab.exe",
        r"C:\Program Files\MATLAB\R2023a\bin\matlab.exe",
        r"C:\Program Files\MATLAB\R2022b\bin\matlab.exe",
        r"C:\Program Files\MATLAB\R2022a\bin\matlab.exe",
    ]
    for p in possible_paths:
        if os.path.exists(p):
            return p
            
    return "matlab" # Fallback to system PATH

def run_matlab_command(cmd_string, cwd=None):
    """
    Executes a MATLAB command non-interactively using batch mode.
    """
    matlab_exe = find_matlab_executable()
    print(f"--> Executing MATLAB: {cmd_string}")
    
    full_cmd = [matlab_exe, "-batch", cmd_string]
    try:
        process = subprocess.Popen(
            full_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            cwd=cwd
        )
        for line in process.stdout:
            print(line, end="")
        process.wait()
        if process.returncode != 0:
            print(f"Warning: MATLAB process returned exit code {process.returncode}")
            return False
        return True
    except Exception as e:
        print(f"Error executing MATLAB command: {e}")
        return False
