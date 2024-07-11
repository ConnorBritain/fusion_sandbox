# CIPS PROD Session Identifier Script

# Define the output file path
$outputFolder = "$env:USERPROFILE\Documents\CIPS_UpdateLogs"
$outputFile = Join-Path $outputFolder ("CIPS-PROD_ActiveSessions_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

# Ensure the output folder exists
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Define the log file path
$logFile = Join-Path $outputFolder "CIPS_ScriptLog.txt"

# Function to write to log
function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -Append -FilePath $logFile
}

# List of processes to check
$processesToCheck = @("Cips", "CipsRemote", "CipsServices")

try {
    Write-Log "Starting CIPS PROD session identification"

    # Get all user sessions
    $sessions = query session

    $activeSessions = @()

    foreach ($session in $sessions) {
        $sessionInfo = $session -split '\s+'
        $username = $sessionInfo[1]

        if ($username -ne "USERNAME") {  # Skip header
            $sessionId = $sessionInfo[2]

            foreach ($process in $processesToCheck) {
                $runningProcesses = Get-WmiObject Win32_Process -Filter "Name = '$process.exe'" | 
                    Where-Object { $_.CommandLine -like "*Program Files (x86)\CIPS\*" }

                foreach ($proc in $runningProcesses) {
                    if ($proc.GetOwner().User -eq $username) {
                        $activeSessions += "User: $username, SessionID: $sessionId, Process: $($proc.Name)"
                        break 2  # Exit both loops if a match is found
                    }
                }
            }
        }
    }

    # Output active sessions to file
    $activeSessions | Out-File -FilePath $outputFile

    Write-Log "CIPS PROD session identification completed. Results saved to $outputFile"
    Write-Output "Session identification complete. Results saved to $outputFile"
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Log "Error occurred: $errorMessage"
    Write-Error "An error occurred. Please check the log file: $logFile"
}
