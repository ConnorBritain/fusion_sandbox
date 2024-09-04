# Define variables
$installerPath = "\\NetworkShare\CIPS_Installer.exe"
$logPath = "C:\Logs\CIPS_Install.log"
$silentArgs = "/S" # Adjust this based on CIPS installer's silent switch

# Function to install CIPS
function Install-CIPS {
    param($computerName)
    
    try {
        # Copy installer to remote machine
        Copy-Item -Path $installerPath -Destination "\\$computerName\C$\Temp\" -Force
        
        # Run installer remotely
        Invoke-Command -ComputerName $computerName -ScriptBlock {
            Start-Process "C:\Temp\CIPS_Installer.exe" -ArgumentList $using:silentArgs -Wait
        }
        
        # Log success
        Add-Content -Path $logPath -Value "$(Get-Date) - Installation successful on $computerName"
    }
    catch {
        # Log error
        Add-Content -Path $logPath -Value "$(Get-Date) - Installation failed on $computerName. Error: $($_.Exception.Message)"
    }
}

# List of target computers
$computers = Get-Content "C:\Scripts\TargetComputers.txt"

# Run installation on each computer
foreach ($computer in $computers) {
    Install-CIPS -computerName $computer
}