# changes in version 1.1:
# added confirmation of shutdown and reboot
# added maintenance check before shutdown or reboot is performed
# changes in version 1.2:
# added stop maintenance mode button
# changes in version 1.3:
# new waiting Box

# script constants
$SCRIPT_NAME = "OpsMgrMM.ps1"
$SCRIPT_Version = "1.3"

# event constants
$EVENT_TYPE_SUCCESS = 0
$EVENT_TYPE_ERROR = 1
$EVENT_TYPE_WARNING = 2
$EVENT_TYPE_INFORMATION = 4

$EVENT_ID_SUCCESS = 997           # use IDs in the range 1 - 1000
$EVENT_ID_SCRIPTERROR = 999        # then you can use eventcreate.exe for testing
$EVENT_ID_PROCESSING_ERROR = 998

$msg = ""

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

cls

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

Function StartProgressBar ($CheckTime , $EventID)
{
 $pbrTest.PerformStep()
  
 $time = 300 - $pbrTest.Value
 [char[]]$mins = "{0}" -f ($time / 60)
 $secs = "{0:00}" -f ($time % 60)
    
 $label1.Text = "{0}:{1}" -f $mins[0], $secs
   
 if ($pbrTest.Value -eq $pbrTest.Maximum) {
    $timer.Enabled = $false
    $timer.Stop()
    $pbrTest.Value = 0
    [windows.forms.messagebox]::Show($objFailed)
    $Form.Close()
	$Form.Dispose()
    }

  $Rest = $time % 10
  
  if ($Rest -eq 1)
  {
      $event = get-eventlog -logname 'operations manager' -newest 1 -instanceID $EventID
      If ($event.TimeGenerated -gt $CheckTime)
        {
        $timer.Enabled = $false
        $timer.Stop()
        $pbrTest.Value = 0
        [windows.forms.messagebox]::Show($objSuccess)
        $Form.Close()
	    $Form.Dispose()
        }
  }

 }


Function CheckMaintenance ($CheckTime, $Command)
{

    if ($Command -eq 'Start')
    {
        $objText = "Check for Maintenance Mode Start Events"
        $instID = "1073743039"
        $objSuccess = "Server is in maintenance mode!"
        $objFailed = "Maintenance mode still not set, please check Operations Manager console!"
    }
    else
    {
        $objText = "Check for Maintenance Mode Stop Events"
        $instID = "1073743040"
        $objSuccess = "Maintenance mode stopped!"
        $objFailed = "Server still in Maintenance Mode, please check Operations Manager console!"
    }


    $Form = New-Object System.Windows.Forms.Form
    $Form.width = 290
    $Form.height = 200
    $Form.Text = $objText
    $Form.AutoSize = $True
    $Form.AutoSizeMode = "GrowAndShrink"

    # Text Label
    $label0 = New-Object System.Windows.Forms.Label
    $label0.AutoSize = $True
    $label0.Location = new-object System.Drawing.Size(10,20)
    $label0.Text = 'Waiting for Operations Manager ......'
    $label0.Font = New-Object System.Drawing.Font("Courier New",12,1,3,0)
    $Form.Controls.Add($label0)

    # Time Remaining Label
    $label1 = New-Object System.Windows.Forms.Label
    $label1.AutoSize = $True
    $label1.Location = new-object System.Drawing.Size(10,50)
    $label1.Text = '5:00'
    $label1.Font = New-Object System.Drawing.Font("Courier New",12,1,3,0)
    $Form.Controls.Add($label1)


    # Init ProgressBar
    $pbrTest = New-Object System.Windows.Forms.ProgressBar
    $pbrTest.Maximum = 300
    $pbrTest.Minimum = 0
    $pbrTest.Step = 1
    $pbrTest.Style=1
    $pbrTest.Location = new-object System.Drawing.Size(70,50)
    $pbrTest.size = new-object System.Drawing.Size(310,20)
    $Form.Controls.Add($pbrTest)

    # Button
    $btnStop = new-object System.Windows.Forms.Button
    $btnStop.Location = new-object System.Drawing.Size(140,80)
    $btnStop.Size = new-object System.Drawing.Size(100,30)
    $btnStop.Text = "Close Waiting"
    $Form.Controls.Add($btnStop)

    # Button
    $btnConfirm = new-object System.Windows.Forms.Button
    $btnConfirm.Location = new-object System.Drawing.Size(20,140)
    $btnConfirm.Size = new-object System.Drawing.Size(100,30)
    $btnConfirm.Text = "Start Progress"
    # $Form.Controls.Add($btnConfirm)

    $timer = New-Object System.Windows.Forms.Timer 
    $timer.Interval = 1000

    $timer.add_Tick({
    StartProgressBar $CheckTime $instID
    })

    $btnStop.Add_Click({
    
        $pbrTest.Value = 0
        $timer.Stop()
        $timer.Enabled = $false
        $label1.Text = '5:00'
        $Form.Close()
	    $Form.Dispose()

    
    })

    $timer.Enabled = $true
    $timer.Start()

    # Show Form
    $Form.Add_Shown({$Form.Activate()})
    $Form.ShowDialog()
}

function Shutdown($reason,$duration,$comment)
{
	$objShutdownForm = New-Object System.Windows.Forms.Form 
	$objShutdownForm.Text = "Confirm Shutdown"
	$objShutdownForm.Size = New-Object System.Drawing.Size(180,70)  
	$objShutdownForm.StartPosition = "CenterScreen"
	$objShutdownForm.FormBorderStyle = 'FixedDialog'
	$objShutdownForm.ControlBox =$false
	
	$ShutdownOkButton = New-Object System.Windows.Forms.Button
	$ShutdownOkButton.Location = New-Object System.Drawing.Size(20,10)
	$ShutdownOkButton.Size = New-Object System.Drawing.Size(60,20)
	$ShutdownOkButton.Text = "Ok"
	$ShutdownOkButton.Add_Click({
		$objShutdownForm.Close()
		If (WriteMaintenanceToLog -Command 'Start' -Reason $reason -Duration $duration -Comment $comment)
		{
		$result = $Null
		$result = Stop-Computer
		If ($result -eq $Null){[windows.forms.messagebox]::Show("Shutdown initialized successfully!")}
		Else {[windows.forms.messagebox]::Show("Failed to initialize shutdown!")}
		}
	})
	$objShutdownForm.Controls.Add($ShutdownOkButton)
	
	$ShutdownCancelButton = New-Object System.Windows.Forms.Button
	$ShutdownCancelButton.Location = New-Object System.Drawing.Size(100,10)
	$ShutdownCancelButton.Size = New-Object System.Drawing.Size(60,20)
	$ShutdownCancelButton.Text = "Cancel"
	$ShutdownCancelButton.Add_Click({
		$objShutdownForm.Close()
		mainform
	})
	$objShutdownForm.Controls.Add($ShutdownCancelButton)
	[void] $objShutdownForm.ShowDialog()
}

function Reboot($reason,$duration,$comment)
{
	$objRebootForm = New-Object System.Windows.Forms.Form 
	$objRebootForm.Text = "Confirm Reboot"
	$objRebootForm.Size = New-Object System.Drawing.Size(180,70)  
	$objRebootForm.StartPosition = "CenterScreen"
	$objRebootForm.FormBorderStyle = 'FixedDialog'
	$objRebootForm.ControlBox =$false
	
	$RebootOkButton = New-Object System.Windows.Forms.Button
	$RebootOkButton.Location = New-Object System.Drawing.Size(20,10)
	$RebootOkButton.Size = New-Object System.Drawing.Size(60,20)
	$RebootOkButton.Text = "Ok"
	$RebootOkButton.Add_Click({
		$objRebootForm.Close()
		If (WriteMaintenanceToLog -Command 'Start' -Reason $reason -Duration $duration -Comment $comment)
		{
		$result = $Null
		$result = Restart-Computer
		If ($result -eq $Null){[windows.forms.messagebox]::Show("Reboot initialized successfully!")}
		Else {[windows.forms.messagebox]::Show("Failed to initialize reboot!")}
		}
	})
	$objRebootForm.Controls.Add($RebootOkButton)
	
	$RebootCancelButton = New-Object System.Windows.Forms.Button
	$RebootCancelButton.Location = New-Object System.Drawing.Size(100,10)
	$RebootCancelButton.Size = New-Object System.Drawing.Size(60,20)
	$RebootCancelButton.Text = "Cancel"
	$RebootCancelButton.Add_Click({
		$objRebootForm.Close()
		mainform
	})
	$objRebootForm.Controls.Add($RebootCancelButton)
	[void] $objRebootForm.ShowDialog()
}

function WriteMaintenanceToLog ($Command, $Reason, $Duration, $Comment)
{
	$objForm.Dispose()
	$time = get-date
	$result = $Null
	switch ($Duration){
	'10 minutes' {$Duration = "10"; break}
	'30 minutes' {$Duration = "30"; break}
	'1 hour' {$Duration = "60"; break}
	'2 hours' {$Duration = "120"; break}
	'4 hours' {$Duration = "240"; break}
	'8 hours' {$Duration = "480"; break}
	'12 hours' {$Duration = "720"; break}
	'1 day' {$Duration = "1440"; break}
	'2 days' {$Duration = "2880"; break}
	'1 week' {$Duration = "10080"; break}
	'2 weeks' {$Duration = "20160"; break}
	'4 weeks' {$Duration = "40320"; break}
	}	

	$msg = $Command + ";" + $Duration + ";" + $Reason + ";" + $Comment
	# create MOM Script API COM object 
	$api = New-Object -comObject "MOM.ScriptAPI"; 
	If ($api -is [Object]){
		# write informational event with maintenance mode info
		$api.LogScriptEvent($SCRIPT_NAME + " " + $SCRIPT_VERSION,$EVENT_ID_SUCCESS,$EVENT_TYPE_INFORMATION,$msg)

		[windows.forms.messagebox]::Show("Successfully written to OpsManager Event Log!")
        If ($Command -eq 'Start')
        {
            CheckMaintenance -CheckTime $time -Command 'Start'
		    # CheckMaintenance -time $time -Command 'Start'
		    $result = $True
        }
        Else
        {
            CheckMaintenance  -CheckTime $time -Command 'Stop'			    
            # CheckMaintenance -time $time -Command 'Stop'
		    $result = $True
        }
    }
	Else {
		[windows.forms.messagebox]::Show("Failed to write to OpsManager Event Log!")
		$result = $False}
}

function mainform()
{
	$objForm = New-Object System.Windows.Forms.Form 
	$objForm.Text = "Sample Operations Manager Maintenance Mode"
	$objForm.Size = New-Object System.Drawing.Size(650,460) 
	$objForm.StartPosition = "CenterScreen"
	$objForm.FormBorderStyle = 'FixedDialog'
	$objForm.ControlBox =$false
	$objForm.BackGroundImage =  [System.Drawing.Image]::FromFile($dir +'\OpsMgr2012.png')
	$objForm.BackGroundImageLayout = 0
	
	$objForm.KeyPreview = $True
	$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
	{
		$objForm.Close()
		WriteMaintenanceToLog -Command ("Start") -Reason ($objReasonBox.Text.Replace(" ", "")) -Duration $objDurationBox.Text -Comment (";;" + $objCommentInput.Text + $user + ";" + (Get-Date))
		}})
	$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
	    {$objForm.Close()}})

	$MaintenanceButton = New-Object System.Windows.Forms.Button
	$MaintenanceButton.Location = New-Object System.Drawing.Size(150,400)
	$MaintenanceButton.Size = New-Object System.Drawing.Size(105,23)
	$MaintenanceButton.Text = "Start Maintenance"
	$MaintenanceButton.Add_Click({
		$objForm.Close()
		WriteMaintenanceToLog -Command ("Start") -Reason ($objReasonBox.Text.Replace(" ", "")) -Duration $objDurationBox.Text -Comment (";;" + $objCommentInput.Text + ":" + $user + ";" + (Get-Date))

	})
	$objForm.Controls.Add($MaintenanceButton)

	$MaintenanceStopButton = New-Object System.Windows.Forms.Button
	$MaintenanceStopButton.Location = New-Object System.Drawing.Size(260,400)
	$MaintenanceStopButton.Size = New-Object System.Drawing.Size(105,23)
	$MaintenanceStopButton.Text = "Stop Maintenance"
	$MaintenanceStopButton.Add_Click({
		$objForm.Close()
		WriteMaintenanceToLog -Command ("Stop") -Reason ($objReasonBox.Text.Replace(" ", "")) -Duration $objDurationBox.Text -Comment (";;" + $objCommentInput.Text + ":" + $user + ";" + (Get-Date))

	})
	$objForm.Controls.Add($MaintenanceStopButton)

	
	$ShutdownButton = New-Object System.Windows.Forms.Button
	$ShutdownButton.Location = New-Object System.Drawing.Size(380,400)
	$ShutdownButton.Size = New-Object System.Drawing.Size(80,23)
	$ShutdownButton.Text = "Shutdown"
	$ShutdownButton.Add_Click({
		$objForm.Close()
		Shutdown -Command ("") -reason ($objReasonBox.Text.Replace(" ", "")) -duration $objDurationBox.Text -comment (";;" + $objCommentInput.Text + ":" + $user + ";" + (Get-Date))
	})
	$objForm.Controls.Add($ShutdownButton)
	
	$RebootButton = New-Object System.Windows.Forms.Button
	$RebootButton.Location = New-Object System.Drawing.Size(465,400)
	$RebootButton.Size = New-Object System.Drawing.Size(80,23)
	$RebootButton.Text = "Reboot"
	$RebootButton.Add_Click({
		$objForm.Close()
		Reboot -Command ("") -reason ($objReasonBox.Text.Replace(" ", "")) -duration $objDurationBox.Text -comment (";;" + $objCommentInput.Text + ":" + $user + ";" + (Get-Date))
	})
	$objForm.Controls.Add($RebootButton)

	$CancelButton = New-Object System.Windows.Forms.Button
	$CancelButton.Location = New-Object System.Drawing.Size(550,400)
	$CancelButton.Size = New-Object System.Drawing.Size(80,23)
	$CancelButton.Text = "Cancel"
	$CancelButton.Add_Click({$objForm.Close()})
	$objForm.Controls.Add($CancelButton)

	$objLabelImage = New-Object System.Windows.Forms.Label
	$objLabelImage.Location = New-Object System.Drawing.Size(400,10)
	$objLabelImage.Size = New-Object System.Drawing.Size(220,45)
	# change logo!
	$objLabelImage.Backgroundimage = [System.Drawing.Image]::FromFile('c:\it\mom\mm\logo.gif')
	$objLabelImage.BackColor = [System.Drawing.Color]::'Transparent'
	$objForm.Controls.Add($objLabelImage)

	$objLabelGen = New-Object System.Windows.Forms.Label
	$objLabelGen.Location = New-Object System.Drawing.Size(50,160)
	$objLabelGen.Size = New-Object System.Drawing.Size(500,100)
	$objLabelGen.Text = "Please use this tool to set this server into maintenance mode.`n`nIf you are running tests, install new software or perform any other action which puts this machine out of production, this tool will avoid unnecessary alerts which otherwise would trigger actions by the service desk.`n`nThank you for your assistance!"
	$objLabelGen.BackColor = [System.Drawing.Color]::'Transparent'
	$objForm.Controls.Add($objLabelGen)


	$objDuration = New-Object System.Windows.Forms.Label
	$objDuration.Location = New-Object System.Drawing.Size(50,280) 
	$objDuration.Size = New-Object System.Drawing.Size(100,20) 
	$objDuration.Text = "Duration: "
	$objDuration.BackColor = [System.Drawing.Color]::'Transparent'
	$objForm.Controls.Add($objDuration) 

	$objDurationBox = New-Object System.Windows.Forms.ComboBox
	$objDurationBox.DropDownStyle = 'DropDownList'
	$objDurationBox.Name = 'Duration'
	$objDurationBox.Location = New-Object System.Drawing.Size(160,280) 
	$objDurationBox.Size = New-Object System.Drawing.Size(100,20) 
	$objDurationBox.Items.Add('10 minutes')|Out-Null
	$objDurationBox.Items.Add('30 minutes')|Out-Null
	$objDurationBox.Items.Add('1 hour')|Out-Null
	$objDurationBox.Items.Add('2 hours')|Out-Null
	$objDurationBox.Items.Add('4 hours')|Out-Null
	$objDurationBox.Items.Add('8 hours')|Out-Null
	$objDurationBox.Items.Add('12 hours')|Out-Null
	$objDurationBox.Items.Add('1 day')|Out-Null
	$objDurationBox.Items.Add('2 days')|Out-Null
	$objDurationBox.Items.Add('1 week')|Out-Null
	$objDurationBox.Items.Add('2 weeks')|Out-Null
	$objDurationBox.Items.Add('4 weeks')|Out-Null
	$objDurationBox.SelectedIndex = 0
	$objForm.Controls.Add($objDurationBox) 

	$objReason = New-Object System.Windows.Forms.Label
	$objReason.Location = New-Object System.Drawing.Size(50,310) 
	$objReason.Size = New-Object System.Drawing.Size(100,20) 
	$objReason.Text = "Reason:"
	$objReason.BackColor = [System.Drawing.Color]::'Transparent'
	$objForm.Controls.Add($objReason) 

	$objReasonBox = New-Object System.Windows.Forms.ComboBox
	$objreasonbox.DropDownStyle = 'DropDownList'
	$objReasonBox.Items.Add('Application Installation')|Out-Null
	$objReasonBox.Items.Add('Application Unresponsive')|Out-Null
	$objReasonBox.Items.Add('Loss Of Network Connectivity')|Out-Null
	$objReasonBox.Items.Add('Planned Application Maintenance')|Out-Null
	$objReasonBox.Items.Add('PlannedHardwareInstallation')|Out-Null
	$objReasonBox.Items.Add('PlannedOperatingSystemReconfiguration')|Out-Null
	$objReasonBox.Items.Add('PlannedOther')|Out-Null
	$objReasonBox.Items.Add('Security Issue')|Out-Null
	$objReasonBox.Items.Add('Unplanned Application Maintenance')|Out-Null
	$objReasonBox.Items.Add('Unplanned Hardware Maintenance')|Out-Null
	$objReasonBox.Items.Add('Unplanned Other')|Out-Null
	$objreasonbox.SelectedIndex = 0
	$objReasonBox.Name = 'Reason'
	$objReasonBox.Location = New-Object System.Drawing.Size(160,310) 
	$objReasonBox.Size = New-Object System.Drawing.Size(200,20) 
	$objForm.Controls.Add($objReasonBox) 

	$objComment = New-Object System.Windows.Forms.Label
	$objComment.Location = New-Object System.Drawing.Size(50,340) 
	$objComment.Size = New-Object System.Drawing.Size(100,20) 
	$objComment.Text = "Comment:"
	$objComment.BackColor = [System.Drawing.Color]::'Transparent'
	$objForm.Controls.Add($objComment) 

	$objCommentInput = New-Object System.Windows.Forms.TextBox 
	$objCommentInput.Location = New-Object System.Drawing.Size(160,340) 
	$objCommentInput.Size = New-Object System.Drawing.Size(200,20) 
	$objForm.Controls.Add($objCommentInput) 

	$objContact = New-Object System.Windows.Forms.Label
	$objContact.Location = New-Object System.Drawing.Size(50,370)
	$objContact.Size = New-Object System.Drawing.Size(500,20)
	# change contact address
	$objContact.Text = "Please contact address@Sample.com for assistance."
	$objContact.BackColor = [System.Drawing.Color]::'Transparent'
	$objForm.Controls.Add($objContact)

	$objUsername = New-Object System.Windows.Forms.Label
	$objUsername.Location = New-Object System.Drawing.Size(50,400) 
	$objUsername.Size = New-Object System.Drawing.Size(100,30) 
	$objUsername.BackColor = [System.Drawing.Color]::'Transparent'
	$user = (Get-Content env:userdomain) + "\"+ (Get-Content env:username)
	$objUsername.Text = $user
	$objForm.Controls.Add($objUsername) 
	
	$objForm.Topmost = $False

	$objForm.Add_Shown({$objForm.Activate()})
	[void] $objForm.ShowDialog()
}

mainform
