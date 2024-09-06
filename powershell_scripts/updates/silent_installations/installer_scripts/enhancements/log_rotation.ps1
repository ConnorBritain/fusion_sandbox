function Write-Log {
  param (
      [string]$ComputerName,
      [string]$Message,
      [string]$Status
  )
  $logFile = Join-Path $localTempPath "Logs\CIPS_Install_$(Get-Date -Format 'yyyyMMdd').csv"
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $logMessage = "$timestamp,$ComputerName,$Message,$Status"
  Add-Content -Path $logFile -Value $logMessage

  # Rotate logs if the current log file is larger than 10MB
  if ((Get-Item $logFile).Length -gt 10MB) {
      Compress-Archive -Path $logFile -DestinationPath "$logFile.zip" -Force
      Remove-Item $logFile -Force
  }
}