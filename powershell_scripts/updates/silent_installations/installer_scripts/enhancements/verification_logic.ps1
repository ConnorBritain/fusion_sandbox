# Add this to the verification logic section
$verificationResult = Invoke-Command -ComputerName $computerName -ScriptBlock {
  $cipsExePath = "C:\Program Files\CIPS\CIPS.exe"
  $cipsServiceName = "CIPSService"
  $cipsRegistryPath = "HKLM:\SOFTWARE\CIPS"
  $expectedVersion = "9.0.243.007"

  $checks = @{
      ExeExists = Test-Path $cipsExePath
      ServiceRunning = (Get-Service $cipsServiceName -ErrorAction SilentlyContinue).Status -eq 'Running'
      RegistryExists = Test-Path $cipsRegistryPath
      VersionCorrect = (Get-ItemProperty $cipsRegistryPath -ErrorAction SilentlyContinue).Version -eq $expectedVersion
  }

  # Additional functional test (example)
  try {
      $result = & $cipsExePath --version
      $checks.FunctionalTest = $result -match $expectedVersion
  } catch {
      $checks.FunctionalTest = $false
  }

  return $checks
}

if ($verificationResult.Values -notcontains $false) {
  Write-Log -ComputerName $computerName -Message "All verification checks passed" -Status "Success"
} else {
  $failedChecks = $verificationResult.Keys | Where-Object { -not $verificationResult[$_] }
  throw "Verification failed for: $($failedChecks -join ', ')"
}