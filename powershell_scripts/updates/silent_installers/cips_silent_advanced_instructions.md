# CIPS SILENT INSTALLS: ADVANCED

See "cips_silent_advanced.ps1" for the associated PowerShell script.

===

### This script incorporates the following changes and considerations:

1. Uses the correct silent install switch `/S`.
2. Sets the network share to `\\[SHARE_DRIVE_NAME]\Updates`. Make sure you update this value to reflect your specific network share drive name.
3. Uses the specific CIPS installer naming scheme. Similar to the last item, update the string inside your Powershell script to reflect the exact name of the installer that you will be executing (e.g. "2024-08-01-CIPS-Prod-Client-9.0.243.007.exe")
4. Nests all local file paths under `C:\Temp`:
   - Installer is copied to `C:\Temp\CIPS_Installer`
   - Logs are written to `C:\Temp\Logs`
   - The target computers list is expected to be in `C:\Temp\Scripts`
5. Creates necessary local directories if they don't exist.
6. Adds error handling and logging.
7. Checks for the existence of the target computers file before proceeding.

### To use this script:

1. Save it as `Install-CIPS.ps1` in a location of your choice.
2. Create a text file named `TargetComputers.txt` in `C:\Temp\Scripts` with a list of target computer names, one per line.
3. Ensure the CIPS installer is in the specified network share.
4. Run the script in PowerShell with administrator privileges.

This script assumes that the target computers have PowerShell remoting enabled and that the executing account has the necessary permissions to access the network share and perform remote operations.