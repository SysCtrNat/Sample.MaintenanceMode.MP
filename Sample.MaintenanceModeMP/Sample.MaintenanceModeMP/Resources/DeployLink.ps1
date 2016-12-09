$TargetFile = "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"
$WScriptShell = New-Object -ComObject WScript.Shell
# Create a Shortcut on default Desktop
$ShortcutFile = "$env:Public\Desktop\OpsMgrMaintMode.lnk"
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Arguments="-executionpolicy bypass -windowstyle hidden -command c:\it\mom\mm\OpsMgrMM.ps1"
$Shortcut.WorkingDirectory="$env:windir\System32\WindowsPowerShell\v1.0"
$Shortcut.Save()

#Create a Shortcut on Public Startup
$ShortcutFile = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\OpsMgrMaintMode.lnk"
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Arguments="-executionpolicy bypass -windowstyle hidden -command c:\it\mom\mm\OpsMgrMM.ps1"
$Shortcut.WorkingDirectory="$env:windir\System32\WindowsPowerShell\v1.0"
$Shortcut.Save()
