import ctypes
import sys
import subprocess

def run_as_admin():
    if not ctypes.windll.shell32.IsUserAnAdmin():
        print("Administrator permission required. Requesting access...")
        ctypes.windll.shell32.ShellExecuteW(
            None,
            "runas",
            sys.executable,
            " ".join(sys.argv),
            None,
            1
        )
        sys.exit()

def main():
    print("current tool --> problem scanner")
    run_as_admin()
    print("Running as Administrator!")
    # run SFC
    subprocess.run(["sfc", "/scannow"])

if __name__ == "__main__":
    main()
