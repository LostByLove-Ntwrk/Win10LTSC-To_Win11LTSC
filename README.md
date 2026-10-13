# Win10 to Win11 update (LTSC versions)
This can be used to update WIN10 PCs/Laptops to a WIN11 version

## Features
- **Pre-Flight Validation:** 
  - Automatically creates a dedicated log directory (`$SystemRoot\Logs\Windows11Upgrade`).
  - Verifies that the Windows installation setup path exists before running.
  - Performs a disk space check to ensure a minimum of **64GB free space** is available on the C: drive.
- **Automated In-Place Upgrade:** Executes the Windows setup silently using tailored arguments (`/auto upgrade`, `/quiet`, `/eula accept`, etc.) to migrate apps and data smoothly.
- **Smart User Session Management:** Bridges the gap between automated system execution and the interactive user session by deploying a scheduled task at logon.
- **Friendly Custom Restart Prompts:** Utilizes a WPF (Windows Presentation Framework) message box to notify the user that the upgrade is complete, allowing them to postpone up to 2 times (15-minute intervals) to save their work before forcing a final reboot.
- **Concurrency Control:** Implements a system Mutex lock to prevent multiple instances of the prompt script from firing at the same time.

## Prerequisites
- Make sure you know the specs of the PCs/Laptops you are trying to update this assumes code assumes you have the correct specs to perform the update
- Clone or download this repository to your local machine.
- Run the script via powershell or RMM that allows powershell scripts:
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Main.ps1
```

Wait for the script to do it's work and ALWAYS check if it went through properly if not let me know so maybe i can edit the script or help with troubleshooting.
