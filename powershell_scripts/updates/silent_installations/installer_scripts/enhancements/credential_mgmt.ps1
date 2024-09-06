# At the beginning of your script, add:
$credentialPath = "C:\Secure\CIPS_cred.xml"

# Function to securely get or create credentials
function Get-SecureCredential {
    if (Test-Path $credentialPath) {
        $cred = Import-Clixml -Path $credentialPath
    } else {
        $cred = Get-Credential -Message "Enter credentials for network access"
        $cred | Export-Clixml -Path $credentialPath
    }
    return $cred
}

# Get the credential
$networkCred = Get-SecureCredential

# Modify your network access operations to use this credential
# For example, in your Copy-Item operations:
Copy-Item -Path $installerPath -Destination "\\$computerName\C$\Temp\CIPS_Installer\" -Force -Credential $networkCred

# And in your Invoke-Command operations:
Invoke-Command -ComputerName $computerName -Credential $networkCred -ScriptBlock { ... }