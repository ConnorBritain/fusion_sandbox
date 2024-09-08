# CIPS TEST/UAT Session Identifier Script

# Define the output file path
$outputFolder = "$env:USERPROFILE\Documents\CIPS_UpdateLogs"
$outputFile = Join-Path $outputFolder ("CIPS-UAT_ActiveSessions_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

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
    Write-Log "Starting CIPS TEST/UAT session identification"

    # Get all user sessions
    $sessions = query session

    $activeSessions = @()
    $protectedSessions = @()

    foreach ($session in $sessions) {
        $sessionInfo = $session -split '\s+'
        $username = $sessionInfo[1]
        $sessionId = $sessionInfo[2]
        $sessionState = $sessionInfo[3]

        # Identify protected sessions
        if ($username -eq "USERNAME" -or 
            $sessionId -eq $currentSessionId -or 
            ($username -eq "" -and $sessionId -eq "0") -or 
            $sessionId -eq "0" -or
            $username -eq "services") {
            $protectedSessions += "User: $username, SessionID: $sessionId, State: $sessionState - Protected Session"
            continue
        }

        $activeProcessFound = $false
        $environment = ""

        foreach ($process in $processesToCheck) {
            foreach ($testFolder in $testFolders) {
                $runningProcesses = Get-WmiObject Win32_Process -Filter "Name = '$process.exe'" | 
                    Where-Object { $_.CommandLine -like "*Program Files (x86)\$testFolder\*" }

                foreach ($proc in $runningProcesses) {
                    if ($proc.GetOwner().User -eq $username) {
                        $activeSessions += "User: $username, SessionID: $sessionId, Process: $($proc.Name), Environment: $testFolder"
                        $activeProcessFound = $true
                        $environment = $testFolder
                        break 3  # Exit all loops if a match is found
                    }
                }
            }
        }

        if (-not $activeProcessFound) {
            $protectedSessions += "User: $username, SessionID: $sessionId, State: $sessionState - No CIPS processes found"
        }
    }

    # Output active and protected sessions to file
    "Active CIPS Sessions:" | Out-File -FilePath $outputFile
    $activeSessions | Out-File -FilePath $outputFile -Append
    "`nProtected or Inactive Sessions:" | Out-File -FilePath $outputFile -Append
    $protectedSessions | Out-File -FilePath $outputFile -Append

    Write-Log "CIPS TEST/UAT session identification completed. Results saved to $outputFile"
    Write-Output "Session identification complete. Results saved to $outputFile"
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Log "Error occurred: $errorMessage"
    Write-Error "An error occurred. Please check the log file: $logFile"
}