$fslogixInstallerUrl = "https://aka.ms/fslogix_download"
$fslogixInstallerPath = "$env:TEMP\FSLogixAppsSetup.zip"

Invoke-WebRequest -Uri $fslogixInstallerUrl -OutFile $fslogixInstallerPath
Expand-Archive -Path $fslogixInstallerPath -DestinationPath "$env:TEMP\FSLogix"
Start-Process -FilePath "$env:TEMP\FSLogix\x64\Release\FSLogixAppsSetup.exe" -ArgumentList "/install /quiet /norestart" -Wait
