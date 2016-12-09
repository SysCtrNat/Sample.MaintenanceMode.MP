param ([string]$FilePaths)

  $api = New-Object -comObject 'MOM.ScriptAPI'
  $api.LogScriptEvent("DeployableFile.ps1", 5678, 0, "Script started")
  
    $TargetDirectory = "C:\IT\MOM\MM"

    If (!(Test-Path -Path "$TargetDirectory")) { New-Item -ItemType:Directory -Path:"$TargetDirectory" }

    [array]$ArFiles = $FilePaths.Split(",")
    ForEach ($FilePath in $ArFiles) {
      $ArFilePath = $FilePath.Split("\")
      $FileName = $arFilePath[$arFilePath.Length -1]

      $api.LogScriptEvent("DeployableFile.ps1", 5678, 0, "File Name: $FileName")

      If ((Test-Path -Path "$TargetDirectory") -and (Test-Path -Path "$FilePath")){
        $TargetFile = $TargetDirectory + "\" + $FileName
        If (!(Test-Path -Path $TargetFile)){
          Try{
            Copy-Item "$FilePath" "$TargetDirectory" -force
            $api.LogScriptEvent("DeployableFile.ps1", 5678, 0, "Copied agent file: $FilePath to the directory: $TargetDirectory")
          }
          Catch{
            $api.LogScriptEvent("DeployableFile.ps1", 5678, 0, "Failed to copy agent file: $FilePath to the directory: $TargetDirectory")
          }
        }
      }Else{
        Call $api.LogScriptEvent("DeployableFile.ps1", 5678, 4, "Failed to copy agent file: $FilePath to the directory: $TargetDirectory.  The source or target does not exist.")
      }
    }

$api.LogScriptEvent("DeployableFile.ps1", 5678, 0, "Script completed")