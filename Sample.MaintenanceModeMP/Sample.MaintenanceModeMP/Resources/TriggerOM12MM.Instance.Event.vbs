Option Explicit
'***********************************************************************************************************
'* TriggerOM12MM.Instance.Event.vbs 1.0 2012120
'* TriggerOM12MM.Instance.Event.vbs 1.1 TPE  Maintenance Stop Parameter
'*
'* If the Maintenance Mode Sample MP is used this script will trigger the Ops Mgr 2012 Maintenance Mode through an event log entry
'* for a given period of time logging a given comment. The default reason is "PlannedOther".
'*
'* Usage
'* cscript.exe TriggerOM07MM.Instance.Event.vbs <maintenance mode duration in mins> <class> <instance> <comment for maintenance> [Start|Stop]
'*
'* with
'*     <maintenance mode duration in mins>   The period of time that the Agent should remain in the
'*                                           Maintenance Mode. It should be considered that it will take some time (up to several mins)
'*                                           before the Agent receives the confirmation for the maintenance mode
'*                                           from its Management Sever and will stop all monitoring activities.
'*                                           As soon as the Management Server receives the trigger it will suppress the Alerts from this Agent.
'*                                           The minimum duration is 5 mins.
'*
'*     <comment for maintenance>              Please state a comment for the Maintenance Mode, e.g. "Monthly server reboot."
'*     <Class>				     Enter Class name to set in maintenance mode, e.g. "Microsoft.Windows.Server.2003.LogicalDisk" or "" for no Class
'*     <Instance>			     Enter Instance name to set in maintenance mode, e.g. "C:" or "" for nothing
'*     [Start|Stop]				 optional Parameter - if missed Start is used. Stop will trigger the end of the Maintenance Mode
'*
'* Example
'* cscript.exe TriggerOM12MM.Instance.Event.vbs 15 "Monthly server reboot." "Microsoft.Windows.Server.2003.LogicalDisk" "C:" "Start"
'* cscript.exe TriggerOM12MM.Instance.Event.vbs 15 "Monthly server reboot." "Microsoft.Windows.Server.2003.LogicalDisk" "C:" "Stop"
'*
'* NH
'***************************************************************************************
Const SCRIPT_NAME = "TriggerOM12MM.Instance.vbs"
Const SCRIPT_VERSION = "1.1"
Const SEPARATOR = ";"
Const DEFAULTREASON ="PlannedOther"

    
'Event constants
Const EVENT_TYPE_SUCCESS = 0
Const EVENT_TYPE_ERROR = 1
Const EVENT_TYPE_WARNING = 2
Const EVENT_TYPE_INFORMATION = 4

Const EVENT_ID_SUCCESS = 997           'Use IDs in the range 1 - 1000
Const EVENT_ID_SCRIPTERROR = 999        'Then you can use eventcreate.exe to test the MP

Call SetLocale("en-us")

Call Main

Private Sub Main()
            
    Dim objArguments 'As Wscript.Arguments
    Dim lngDuration 'As Long
    Dim strComment 'As String
    Dim strClass 'As String
    Dim strInstance 'As String
    Dim START_ACTION_KEYWORD 'As String
    Dim objWSHNetwork 'As WScript.Network
    Dim objMomScriptAPI 'As MOM.ScriptAPI
    Dim Description 'As String
	
    On Error Resume Next
    
    Set objArguments = wscript.Arguments
    If objArguments.Count < 4 Then
        Call wscript.echo("Usage: " & vbCrLf & "cscript TriggerOM07MM.vbs <Duration in min> <comment> <Class> <Instance> 'Start'" & vbCrLf & vbCrLf & _
                          "Example: cscript TriggerOM12MM.vbs 20 ""Daily Reboot"" ""Microsoft.Windows.Server.2003.LogicalDisk"" ""C:""" & vbCrLf & _
                          "will set the Agent into maintenance for the next 20 mins, logging the comment ""Daily Reboot"".")
        Exit Sub
    End If

    'Get parameters and set global variables
    lngDuration = CLng(objArguments(0))
    strComment = Replace(objArguments(1), Chr(34), "")
    strClass = Replace(objArguments(2), Chr(34), "")
    strInstance = Replace(objArguments(3), Chr(34), "")

	' If the optional Parameter 5 is given -> use it; else set Start as command
    if (objArguments.Count > 4) then
		START_ACTION_KEYWORD = Replace(objArguments(4), Chr(34), "")
    else
		START_ACTION_KEYWORD = "Start"
    end if
	

    'Validate arguments
    If lngDuration < 5 Then
        Call wscript.echo("The minimum maintenance period is 5 mins!" & vbCrLf)
        Call wscript.echo("Usage: " & vbCrLf & "cscript TriggerOM07MM.vbs <Duration in min> <comment> <Class> <Instance>" & vbCrLf & vbCrLf & _
                          "Example: cscript TriggerOM12MM.vbs 20 ""Daily Reboot"" ""Microsoft.Windows.Server.2003.LogicalDisk"" ""C:""" & vbCrLf & _
                          "will set the Agent into maintenance for the next 20 mins, logging the comment ""Daily Reboot"".")
        Exit Sub
    ElseIf Len(strComment) = 0 Then
        Call wscript.echo("The comment is missing!" & vbCrLf)
        Call wscript.echo("Usage: " & vbCrLf & "cscript TriggerOM07MM.vbs <Duration in min> <comment> <Class> <Instance>" & vbCrLf & vbCrLf & _
                          "Example: cscript TriggerOM12MM.vbs 20 ""Daily Reboot"" ""Microsoft.Windows.Server.2003.LogicalDisk"" ""C:""" & vbCrLf & _
                          "will set the Agent into maintenance for the next 20 mins, logging the comment ""Daily Reboot"".")
        Exit Sub
    End If
            
    Set objMomScriptAPI = CreateObject("MOM.ScriptAPI")
    Set objWSHNetwork = CreateObject("WScript.Network")
	
    Description = START_ACTION_KEYWORD & SEPARATOR & CStr(lngDuration) & SEPARATOR & DEFAULTREASON & SEPARATOR & strClass & SEPARATOR & strInstance & SEPARATOR & strComment & ":" & objWSHNetwork.UserDomain & "\" & objWSHNetwork.UserName & SEPARATOR & Now
    Wscript.Echo Description
    Call objMomScriptAPI.LogScriptEvent(SCRIPT_NAME & " " & SCRIPT_VERSION, EVENT_ID_SUCCESS, EVENT_TYPE_INFORMATION, Description)
    
        
    If Err.Number = 0 Then
		if START_ACTION_KEYWORD = "Start" then
			Call wscript.echo("Successfully triggered the Operations Manager 2012 Agent Maintenance Mode.")
		else
			Call wscript.echo("Successfully triggered the End of the Operations Manager 2012 Agent Maintenance Mode.")
		end if
    Else
        Call wscript.echo("Failed to trigger the Operations Manager 2012 Agent Maintenance Mode.")
    End If

    Call WScript.Sleep(180000)

End Sub


