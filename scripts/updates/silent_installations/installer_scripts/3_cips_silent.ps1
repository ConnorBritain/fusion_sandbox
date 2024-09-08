# Define variables
$networkShare = "\\[Network Share]\Updates"
$installerName = "1999-12-31-CIPS-Prod-Client-9.0.XYZ.ABC.exe"
$installerPath = Join-Path $networkShare $installerName
$localTempPath = "C:\Temp"
$localInstallerPath = Join-Path $localTempPath "CIPS_Installer"
$logPath = Join-Path $localTempPath "Logs\CIPS_Install.csv"
$silentArgs = "/S"
$targetComputersFile = Join-Path $localTempPath "Scripts\TargetComputers.txt"
$minimumDiskSpace = 5GB
$minimumRAM = 4GB
$requiredOSVersion = "10.0"

# Email settings for notifications
$smtpServer = "smtp.yourdomain.com"
$emailFrom = "cips-installer@yourdomain.com"
$emailTo = "it-team@yourdomain.com"

# Ensure necessary local directories exist
$dirs = @($localTempPath, $localInstallerPath, (Split-Path $logPath), (Split-Path $targetComputersFile))
foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# Function to log messages
function Write-Log {
    param (
        [string]$ComputerName,
        [string]$Message,
        [string]$Status
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp,$ComputerName,$Message,$Status"
    Add-Content -Path $logPath -Value $logMessage
}

# Function to send email notification
function Send-EmailNotification {
    param (
        [string]$Subject,
        [string]$Body
    )
    Send-MailMessage -From $emailFrom -To $emailTo -Subject $Subject -Body $Body -SmtpServer $smtpServer
}

# Function to check system requirements
function Test-SystemRequirements {
    param($computerName)
    
    $result = Invoke-Command -ComputerName $computerName -ScriptBlock {
        $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'"
        $os = Get-WmiObject Win32_OperatingSystem
        $ram = $os.TotalVisibleMemorySize / 1MB
        
        @{
            DiskSpaceOK = ($disk.FreeSpace -ge $using:minimumDiskSpace)
            RAMOk = ($ram -ge $using:minimumRAM)
            OSVersionOK = ([version]$os.Version -ge [version]$using:requiredOSVersion)
        }
    }
    
    return $result.DiskSpaceOK -and $result.RAMOk -and $result.OSVersionOK
}

# Function to install CIPS
function Install-CIPS {
    param($computerName)
    
    try {
        # Check system requirements
        if (!(Test-SystemRequirements -computerName $computerName)) {
            throw "System requirements not met"
        }

        # Create remote temp directory if it doesn't exist
        Invoke-Command -ComputerName $computerName -ScriptBlock {
            if (!(Test-Path $using:localInstallerPath)) {
                New-Item -ItemType Directory -Path $using:localInstallerPath -Force | Out-Null
            }
        }

        # Copy installer to remote machine
        Copy-Item -Path $installerPath -Destination "\\$computerName\C$\Temp\CIPS_Installer\" -Force

        # Run installer remotely
        $result = Invoke-Command -ComputerName $computerName -ScriptBlock {
            $localInstallerPath = Join-Path $using:localInstallerPath $using:installerName
            $process = Start-Process $localInstallerPath -ArgumentList $using:silentArgs -Wait -NoNewWindow -PassThru
            return $process.ExitCode
        }

        if ($result -eq 0) {
            Write-Log -ComputerName $computerName -Message "Installation completed" -Status "Success"
        } else {
            throw "Installation failed with exit code: $result"
        }

        # Verify installation
        $verificationResult = Invoke-Command -ComputerName $computerName -ScriptBlock {
            # Add verification logic here (e.g., check for specific files or registry keys)
            $cipsExePath = "C:\Program Files\CIPS\CIPS.exe"
            return Test-Path $cipsExePath
        }

        if ($verificationResult) {
            Write-Log -ComputerName $computerName -Message "Installation verified" -Status "Success"
        } else {
            throw "Installation verification failed"
        }
    }
    catch {
        Write-Log -ComputerName $computerName -Message $_.Exception.Message -Status "Failure"
        Send-EmailNotification -Subject "CIPS Installation Failed on $computerName" -Body $_.Exception.Message
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
$jobs = @()
foreach ($computer in $computers) {
    $jobs += Start-Job -ScriptBlock ${function:Install-CIPS} -ArgumentList $computer
}

# Wait for all jobs to complete
$jobs | Wait-Job

# Process results
$failedInstalls = @()
foreach ($job in $jobs) {
    $result = Receive-Job -Job $job
    if ($result -match "Failure") {
        $failedInstalls += $job.Name
    }
}

# Send summary email
$summary = "CIPS Installation Summary:`n"
$summary += "Total computers: $($computers.Count)`n"
$summary += "Successful installs: $($computers.Count - $failedInstalls.Count)`n"
$summary += "Failed installs: $($failedInstalls.Count)`n"
if ($failedInstalls.Count -gt 0) {
    $summary += "Failed computers: $($failedInstalls -join ', ')`n"
}
Send-EmailNotification -Subject "CIPS Installation Summary" -Body $summary

Write-Host "Installation process completed. Please check the log file at $logPath for details."