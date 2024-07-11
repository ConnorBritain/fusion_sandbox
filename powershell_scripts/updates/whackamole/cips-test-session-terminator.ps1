# CIPS TEST/UAT Session Terminator Script

# Define the output file path
$outputFolder = "$env:USERPROFILE\Documents\CIPS_UpdateLogs"
$outputFile = Join-Path $outputFolder ("CIPS-UAT_TerminatedSessions_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

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

# List of possible TEST/UAT folder names
$testFolders = @("CIPS_UAT", "CIPS_TEST")

# Get current user's session ID
$currentSessionId = (Get-Process -PID $PID).SessionId

try {
    Write-Log "Starting CIPS TEST/UAT session termination process"

    # Get all user sessions
    $sessions = query session

    $terminatedSessions = @()

    foreach ($session in $sessions) {
        $sessionInfo = $session -split '\s+'
        $username = $sessionInfo[1]
        $sessionId = $sessionInfo[2]

        if ($username -ne "USERNAME" -and $sessionId -ne $currentSessionId) {  # Skip header and current user
            $terminateSession = $false
            $environment = ""

            foreach ($process in $processesToCheck) {
                foreach ($testFolder in $testFolders) {
                    $runningProcesses = Get-WmiObject Win32_Process -Filter "Name = '$process.exe'" | 
                        Where-Object { $_.CommandLine -like "*Program Files (x86)\$testFolder\*" }

                    foreach ($proc in $runningProcesses) {
                        if ($proc.GetOwner().User -eq $username) {
                            $terminateSession = $true
                            $environment = $testFolder
                            break 3  # Exit all loops if a match is found
                        }
                    }
                }
            }

            if ($terminateSession) {
                try {
                    # Attempt to log off the user session
                    logoff $sessionId
                    $terminatedSessions += "User: $username, SessionID: $sessionId, Environment: $environment - Terminated successfully"
                    Write-Log "Terminated session for User: $username, SessionID: $sessionId, Environment: $environment"
                }
                catch {
                    $errorMessage = $_.Exception.Message
                    $terminatedSessions += "User: $username, SessionID: $sessionId, Environment: $environment - Termination failed: $errorMessage"
                    Write-Log "Failed to terminate session for User: $username, SessionID: $sessionId, Environment: $environment. Error: $errorMessage"
                }
            }
        }
    }

    # Output terminated sessions to file
    $terminatedSessions | Out-File -FilePath $outputFile

    Write-Log "CIPS TEST/UAT session termination completed. Results saved to $outputFile"
    Write-Output "Session termination complete. Results saved to $outputFile"
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Log "Error occurred: $errorMessage"
    Write-Error "An error occurred. Please check the log file: $logFile"
}
