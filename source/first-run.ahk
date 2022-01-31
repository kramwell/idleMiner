;Written by KramWell.com - 11/JUN/2018
;A program to mine CPU coins when a computer is deemed idle.

#NoEnv
SetWorkingDir %A_ScriptDir%


;###########################################################
/*
##Process for install##
create log folder
change log folder permissions
change idleState.exe permissions
install main app to Task scheduler
install idleLogonTask to Task scheduler
install idleStateTask to Task scheduler
*/
;###########################################################

FormatTime, TimeString, A_Now, dd/MM/yy HH:mm:ss
outputFile := A_ScriptDir "\" A_ComputerName "-install_log.txt"

;######################################
;create logs folder
;######################################
if !FileExist(A_ScriptDir "\logs")
{
	FileCreateDir, %A_ScriptDir%\logs
	If (ErrorLevel = 1){
		FileAppend, [%TimeString%] ERROR: Problem creating folder named logs`n, %outputFile%
		Goto, RollBack
	}else{
		FileAppend, [%TimeString%] Successfully created folder (logs)`n, %outputFile%
	}
}

;######################################
;add permissions to folder
;######################################
AddUsersPermission := RunWaitOne("CACLS " A_ScriptDir "\logs /E /G USERS:F 2>&1")
If InStr(AddUsersPermission, "processed dir:"){
	FileAppend, [%TimeString%] Successfully added user permissions to log file`n, %outputFile%
}else{
	FileAppend, [%TimeString%] ERROR: CACLS- %AddUsersPermission% - Maybe try deleting the folder?`n, %outputFile%
	Goto, RollBack
}

;######################################
;change idleState.exe permissions so any user can run.
;######################################
AddUsersPermission := RunWaitOne("CACLS " A_ScriptDir "\idleState.exe /E /G USERS:F 2>&1")
If InStr(AddUsersPermission, "processed file:"){
	FileAppend, [%TimeString%] Successfully added user permissions to idleState.exe`n, %outputFile%
}else{
	FileAppend, [%TimeString%] ERROR: idleState - %AddUsersPermission%`n, %outputFile%
	Goto, RollBack
}

;######################################
;install main app to Task scheduler
;######################################
FileDelete, %A_ScriptDir%\install.xml
FILETOSAVE := XMLINSTALL()
FileAppend, %FILETOSAVE%, %A_ScriptDir%\install.xml

COMMANDTORUN := "SCHTASKS /CREATE /TN ""\Idle Miner\IdleMiner"" /XML " A_ScriptDir "\install.xml"
If !InStr(RunWaitOne(COMMANDTORUN), "SUCCESS"){
	;did not install we must log and exit-
	FileAppend, [%TimeString%] ERROR: Could not install IdleMiner- program will exit`n, %outputFile%
	FileDelete, %A_ScriptDir%\install.xml
	Goto, RollBack
}else{
	FileAppend, [%TimeString%] Task IdleMiner installed OK`n, %outputFile%
}
FileDelete, %A_ScriptDir%\install.xml


;######################################
;install idleLogonTask to Task scheduler
;######################################
FileDelete, %A_ScriptDir%\idleLogonTask.xml
FILETOSAVE := XMLLOGON()
FileAppend, %FILETOSAVE%, %A_ScriptDir%\idleLogonTask.xml

COMMANDTORUN := "SCHTASKS /CREATE /TN ""\Idle Miner\idleLogonTask"" /XML " A_ScriptDir "\idleLogonTask.xml"
If !InStr(RunWaitOne(COMMANDTORUN), "SUCCESS"){
	;did not install we must log and exit-
	FileAppend, [%TimeString%] ERROR: Could not install idleLogonTask- program will exit`n, %outputFile%
	FileDelete, %A_ScriptDir%\idleLogonTask.xml	
	Goto, RollBack
}else{
	FileAppend, [%TimeString%] Task idleLogonTask installed OK`n, %outputFile%
}
FileDelete, %A_ScriptDir%\idleLogonTask.xml	
	
;######################################
;install idleStateTask to Task scheduler
;######################################
FileDelete, %A_ScriptDir%\idle.xml
FILETOSAVE := XMLIDLE()
FileAppend, %FILETOSAVE%, %A_ScriptDir%\idle.xml	

COMMANDTORUN := "SCHTASKS /CREATE /TN ""\Idle Miner\idleStateTask"" /XML " A_ScriptDir "\idle.xml"
If !InStr(RunWaitOne(COMMANDTORUN), "SUCCESS"){
	;did not install we must log and exit-
	FileAppend,[%TimeString%] ERROR: Could not install idleStateTask- program will exit`n, %outputFile%
	FileDelete, %A_ScriptDir%\idle.xml	
	Goto, RollBack
}else{
	FileAppend, [%TimeString%] Task idleStateTask installed OK`n, %outputFile%
}
FileDelete, %A_ScriptDir%\idle.xml

FileAppend,[%TimeString%] All Files were installed successfully`n, %outputFile%

Return

;#####################################################################
;ROLL BACK IF ERRORS
;#####################################################################

RollBack:

	FileAppend, [%TimeString%] ERROR: Rollingback`n, %outputFile%

	;Remove tasks
	If InStr(RunWaitOne("SCHTASKS /DELETE /TN ""\Idle Miner\idleMiner"" /F"), "SUCCESS"){
		;successfully deleted task
		FileAppend,[%TimeString%] Successfully deleted idleMiner`n, %outputFile%
	}
	
	If InStr(RunWaitOne("SCHTASKS /DELETE /TN ""\Idle Miner\idleLogonTask"" /F"), "SUCCESS"){
		;successfully deleted task
		FileAppend,[%TimeString%] Successfully deleted idleLogonTask`n, %outputFile%
	}
	
	If InStr(RunWaitOne("SCHTASKS /DELETE /TN ""\Idle Miner\idleStateTask"" /F"), "SUCCESS"){
		;successfully deleted task
		FileAppend,[%TimeString%] Successfully deleted idleStateTask`n, %outputFile%
	}
	
	FileDelete, %A_ScriptDir%\install.xml
	if !FileExist(A_ScriptDir "\install.xml")
	{
		FileAppend,[%TimeString%] install.xml Deleted `n, %outputFile%
	}

	FileAppend, [%TimeString%] Rollback Complete`n, %outputFile%

	ExitApp

Return

;######################################	
;RunWaitOne command
;######################################
RunWaitOne(command) {
shell := ComObjCreate("WScript.Shell")
	if (A_Is64bitOS){
		DllCall("Wow64DisableWow64FsRedirection", "uint*", OldValue)
		exec := shell.Exec(ComSpec " /C " command)
		DllCall("Wow64RevertWow64FsRedirection", "uint", OldValue)
	}else{
		exec := shell.Exec(ComSpec " /C " command)
	}	
return exec.StdOut.ReadAll()
}

;######################################	
;XML INSTALL FUNCTION
;######################################
XMLINSTALL(){
Return "<?xml version=""1.0"" encoding=""UTF-16""?>
<Task version=""1.3"" xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task"">
  <RegistrationInfo>
    <Author>KramWell Tech. (KramWell.com)</Author>
    <Description>idleMiner</Description>
  </RegistrationInfo>
<Triggers />
  <Principals>
    <Principal id=""Author"">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>false</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context=""Author"">
    <Exec>
      <Command>idleMiner.exe</Command>
      <WorkingDirectory>" A_ScriptDir "\</WorkingDirectory>
    </Exec>
  </Actions>
</Task>"
}

;######################################	
;XML XMLIDLE FUNCTION
;######################################
XMLIDLE(){
Return "<?xml version=""1.0"" encoding=""UTF-16""?>
<Task version=""1.3"" xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task"">
  <RegistrationInfo>
    <Author>KramWell Tech. (KramWell.com)</Author>
  </RegistrationInfo>
  <Triggers />
  <Principals>
    <Principal id=""Author"">
      <GroupId>S-1-5-32-545</GroupId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>false</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context=""Author"">
    <Exec>
      <Command>idleState.exe</Command>
      <WorkingDirectory>" A_ScriptDir "\</WorkingDirectory>
    </Exec>
  </Actions>
</Task>"

}

;######################################	
;XML XMLLOGON FUNCTION
;######################################
XMLLOGON(){
Return "<?xml version=""1.0"" encoding=""UTF-16""?>
<Task version=""1.3"" xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task"">
  <RegistrationInfo>
    <Author>KramWell Tech. (KramWell.com)</Author>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
    </LogonTrigger>
    <SessionStateChangeTrigger>
      <Enabled>true</Enabled>
      <StateChange>SessionUnlock</StateChange>
    </SessionStateChangeTrigger>
    <SessionStateChangeTrigger>
      <Enabled>true</Enabled>
      <StateChange>RemoteConnect</StateChange>
    </SessionStateChangeTrigger>
    <SessionStateChangeTrigger>
      <Enabled>true</Enabled>
      <StateChange>ConsoleConnect</StateChange>
    </SessionStateChangeTrigger>
  </Triggers>
  <Principals>
    <Principal id=""Author"">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>false</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>false</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context=""Author"">
    <Exec>
      <Command>idleLogon.exe</Command>
      <Arguments></Arguments>
      <WorkingDirectory>" A_ScriptDir "\</WorkingDirectory>
    </Exec>
  </Actions>
</Task>"
}
