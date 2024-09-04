# Define variables
$networkShare = "\\IHSSQL1\Updates"
$installerName = "2024-08-01-CIPS-Prod-Client-9.0.243.007.exe"
$installerPath = Join-Path $networkShare $installerName
$localTempPath = "C:\Temp"
$localInstallerPath = Join-Path $localTempPath "CIPS_Installer"
$logPath = Join-Path $localTempPath "Logs\CIPS_Install.log"
$silentArgs = "/S"
$targetComputersFile = Join-Path $localTempPath "Scripts\TargetComputers.txt"

# Ensure necessary local directories exist
$dirs = @($localTempPath, $localInstallerPath, (Split-Path $logPath), (Split-Path $targetComputersFile))
foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Function to install CIPS
function Install-CIPS {
    param($computerName)
    
    try {
        # Create remote temp directory if it doesn't exist
        Invoke-Command -ComputerName $computerName -ScriptBlock {
            if (!(Test-Path $using:localInstallerPath)) {
                New-Item -ItemType Directory -Path $using:localInstallerPath -Force | Out-Null
            }
        }

        # Copy installer to remote machine
        Copy-Item -Path $installerPath -Destination "\\$computerName\C$\Temp\CIPS_Installer\" -Force

        # Run installer remotely
        Invoke-Command -ComputerName $computerName -ScriptBlock {
            $localInstallerPath = Join-Path $using:localInstallerPath $using:installerName
            Start-Process $localInstallerPath -ArgumentList $using:silentArgs -Wait -NoNewWindow
        }
        
        # Log success
        Add-Content -Path $logPath -Value "$(Get-Date) - Installation successful on $computerName"
    }
    catch {
        # Log error
        Add-Content -Path $logPath -Value "$(Get-Date) - Installation failed on $computerName. Error: $($_.Exception.Message)"
    }
}

# Check if target computers file exists
if (!(Test-Path $targetComputersFile)) {
    Write-Host "Target computers file not found. Please create $targetComputersFile with a list of computer names, one per line."
    exit
}

# List of target computers
$computers = Get-Content $targetComputersFile

# Run installation on each computer
foreach ($computer in $computers) {
    Install-CIPS -computerName $computer
}

Write-Host "Installation process completed. Please check the log file at $logPath for details."