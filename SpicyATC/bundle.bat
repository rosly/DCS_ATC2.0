@echo off
setlocal enabledelayedexpansion

:: Script to bundle audio files into a DCS .miz file
:: Assumes audios in .\SpicyATC\audios (relative to where .bat is run)
:: Pops a file dialog to select .miz from parent dir or wherever
:: Outputs _bundled.miz in same dir as selected .miz

echo Starting SpicyATC bundler...

:: Run PowerShell for file dialog and ZIP handling
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$audioDir = Join-Path -Path (Get-Location) -ChildPath 'audios'; " ^
"if (-not (Test-Path $audioDir -PathType Container)) { Write-Host 'Error: audios folder not found in SpicyATC.'; exit 1; } " ^
"Add-Type -AssemblyName System.Windows.Forms; " ^
"$dialog = New-Object System.Windows.Forms.OpenFileDialog; " ^
"$dialog.Filter = 'DCS Mission Files (*.miz)|*.miz'; " ^
"$dialog.Title = 'Select DCS .miz File'; " ^
"if ($dialog.ShowDialog() -eq 'OK') { $mizPath = $dialog.FileName; } else { Write-Host 'No .miz selected. Exiting.'; exit; } " ^
"$outputPath = Join-Path -Path (Split-Path $mizPath -Parent) -ChildPath ((Split-Path $mizPath -Leaf).Replace('.miz', '_bundled.miz')); " ^
"Copy-Item -Path $mizPath -Destination $outputPath; " ^
"Add-Type -AssemblyName System.IO.Compression.FileSystem; " ^
"$zip = [System.IO.Compression.ZipFile]::Open($outputPath, 'Update'); " ^
"$added = 0; " ^
"Get-ChildItem -Path $audioDir -Filter *.ogg | ForEach-Object { $arcPath = 'l10n/DEFAULT/' + $_.Name; $zip.CreateEntryFromFile($_.FullName, $arcPath); Write-Host ('Added ' + $_.Name + ' to ' + $arcPath); $added++; } " ^
"Get-ChildItem -Path $audioDir -Filter *.wav | ForEach-Object { $arcPath = 'l10n/DEFAULT/' + $_.Name; $zip.CreateEntryFromFile($_.FullName, $arcPath); Write-Host ('Added ' + $_.Name + ' to ' + $arcPath); $added++; } " ^
"$zip.Dispose(); " ^
"if ($added -eq 0) { Write-Host 'Warning: No .ogg or .wav files in audios folder.'; } " ^
"Write-Host ('Success! Bundled .miz saved to: ' + $outputPath);"

pause