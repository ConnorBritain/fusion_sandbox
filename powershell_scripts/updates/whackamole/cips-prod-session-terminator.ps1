# CIPS PROD Session Terminator Script

# Define the output file path
$outputFolder = "$env:USERPROFILE\Documents\CIPS_UpdateLogs"
$outputFile = Join-Path $outputFolder ("CIPS-PROD_TerminatedSessions_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

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

# Get current user's session ID
$currentSessionId = (Get-Process -PID $PID).SessionId

try {
    Write-Log "Starting CIPS PROD session termination process"

    # Get all user sessions
    $sessions = query session

    $terminatedSessions = @()

    foreach ($session in $sessions) {
        $sessionInfo = $session -split '\s+'
        $username = $sessionInfo[1]
        $sessionId = $sessionInfo[2]

        if ($username -ne "USERNAME" -and $sessionId -ne $currentSessionId) {  # Skip header and current user
            $terminateSession = $false

            foreach ($process in $processesToCheck) {
                $runningProcesses = Get-WmiObject Win32_Process -Filter "Name = '$process.exe'" | 
                    Where-Object { $_.CommandLine -like "*Program Files (x86)\CIPS\*" }

                foreach ($proc in $runningProcesses) {
                    if ($proc.GetOwner().User -eq $username) {
                        $terminateSession = $true
                        break 2  # Exit both loops if a match is found
                    }
                }
            }

            if ($terminateSession) {
                try {
                    # Attempt to log off the user session
                    logoff $sessionId
                    $terminatedSessions += "User: $username, SessionID: $sessionId - Terminated successfully"
                    Write-Log "Terminated session for User: $username, SessionID: $sessionId"
                }
                catch {
                    $errorMessage = $_.Exception.Message
                    $terminatedSessions += "User: $username, SessionID: $sessionId - Termination failed: $errorMessage"
                    Write-Log "Failed to terminate session for User: $username, SessionID: $sessionId. Error: $errorMessage"
                }
            }
        }
    }

    # Output terminated sessions to file
    $terminatedSessions | Out-File -FilePath $outputFile

    Write-Log "CIPS PROD session termination completed. Results saved to $outputFile"
    Write-Output "Session termination complete. Results saved to $outputFile"
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Log "Error occurred: $errorMessage"
    Write-Error "An error occurred. Please check the log file: $logFile"
}
