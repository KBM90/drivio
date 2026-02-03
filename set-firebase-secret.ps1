# PowerShell script to set Firebase service account secret
# Usage: .\set-firebase-secret.ps1

$jsonPath = "C:\Karim\secrets\drivio-f261a-firebase-adminsdk-fbsvc-01f5b8995f.json"

# Read the JSON file and compress it to a single line
$jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json | ConvertTo-Json -Compress

# Set the secret
Write-Host "Setting FIREBASE_SERVICE_ACCOUNT secret..."
supabase secrets set "FIREBASE_SERVICE_ACCOUNT=$jsonContent"

Write-Host "Done! Secret has been set."
