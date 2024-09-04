# CIPS Silent Instructions

===

## Prior to Script Execution

1. Prepare the environment:
   - Create a network share containing the CIPS installer.
   - Create a text file (TargetComputers.txt) with the list of computer names, one per line.
   - Ensure you have appropriate permissions to run PowerShell remotely on target machines.

## Script Execution

2. Run the script:
   - Open PowerShell as an administrator.
   - Navigate to the script's location.
   - Execute the script: .\Install-CIPS.ps1

## Post-script

3. Monitor the installation:
   - Check the log file (C:\Logs\CIPS_Install.log) for installation status on each machine.

---

### Key considerations:

- Ensure PowerShell remoting is enabled on all target machines.
- The script uses the C:\Temp directory on remote machines; ensure it exists and is writable.
- Adjust the $silentArgs variable based on the specific silent install switch for CIPS.
- You may need to modify the script to handle any additional installation parameters or configurations specific to CIPS.

### Advantages of this method:

- Offers more granular control over the installation process.
- Provides detailed logging for troubleshooting.
- Can be easily modified to include pre-install checks or post-install verifications.
- Allows for targeting specific machines rather than OUs.