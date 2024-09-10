# CIPS Service Management Script

$servicePrefixes = @("CIPS Live", "CIPS Test")
$stateFile = "$env:TEMP\CIPS_service_states.json"

function Get-CIPSServices {
    $services = @()
    foreach ($prefix in $servicePrefixes) {
        $services += Get-Service | Where-Object {$_.DisplayName -like "$prefix*"}
    }
    return $services
}

function Save-ServiceStates {
    $services = Get-CIPSServices
    $states = @{}
    foreach ($service in $services) {
        $states[$service.Name] = $service.Status
    }
    $states | ConvertTo-Json | Set-Content -Path $stateFile
    Write-Host "Service states saved to $stateFile"
}

function Stop-CIPSServices {
    Save-ServiceStates
    $services = Get-CIPSServices
    foreach ($service in $services) {
        if ($service.Status -eq "Running") {
            Stop-Service -Name $service.Name -Force
            Write-Host "Stopped service: $($service.DisplayName)"
        } else {
            Write-Host "Service already stopped: $($service.DisplayName)"
        }
    }
}

function Restore-CIPSServices {
    if (Test-Path $stateFile) {
        $states = Get-Content -Path $stateFile | ConvertFrom-Json
        $services = Get-CIPSServices
        foreach ($service in $services) {
            $desiredState = $states.($service.Name)
            if ($desiredState -eq "Running" -and $service.Status -ne "Running") {
                Start-Service -Name $service.Name
                Write-Host "Started service: $($service.DisplayName)"
            } elseif ($desiredState -ne "Running" -and $service.Status -eq "Running") {
                Stop-Service -Name $service.Name -Force
                Write-Host "Stopped service: $($service.DisplayName)"
            } else {
                Write-Host "Service $($service.DisplayName) already in desired state: $desiredState"
            }
        }
        Remove-Item -Path $stateFile
        Write-Host "Service states restored and state file removed"
    } else {
        Write-Host "No saved state file found. Cannot restore services to previous state."
    }
}

function Get-CIPSServicesStatus {
    $services = Get-CIPSServices
    foreach ($service in $services) {
        Write-Host "$($service.DisplayName): $($service.Status)"
    }
}

# Main script
$action = $args[0]

switch ($action) {
    "stop" { Stop-CIPSServices }
    "restore" { Restore-CIPSServices }
    "status" { Get-CIPSServicesStatus }
    default { Write-Host "Usage: .\cips-service-management.ps1 [stop|restore|status]" }
}