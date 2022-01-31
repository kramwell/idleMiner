;Written by KramWell.com - 11/JUN/2018
;A program to mine CPU coins when a computer is deemed idle.

#NoEnv
SetWorkingDir %A_ScriptDir%

#Persistent
#NoTrayIcon

	#SingleInstance OFF
	;check if task is running, this will run this program but with SYSTEM privileges.
	If !InStr(StdOutToVar("SCHTASKS /QUERY /TN ""\Idle Miner\idleMiner"" "), "Running"){
		If InStr(StdOutToVar("SCHTASKS /RUN /TN ""\Idle Miner\idleMiner"" "), "SUCCESS"){
			FileAppend,[%TimeString%] Ran schedule task ok - Reloading`n, %outputFile%
		}else{
			FileAppend,[%TimeString%] ERROR: could not run task schedule`n, %outputFile%
		}
		ExitApp
	}
	;sleep here for a second before checking for single instance to ensure if running as normal user that it has closed first to avoid any possible conflict
	Sleep, 2000 ;sleep 2 seconds
	#SingleInstance FORCE

	
;#############################

;check for ini file to load config.
INICONF := "config.ini"
;Check if ini file exists
if !FileExist(INICONF){
	FileAppend,[%TimeString%] ERROR: %INICONF% file does not exist. Program will exit.`n, %outputFile%
	Goto StopProgram
}

	IniRead, EXEminer, %A_ScriptDir%\%INICONF%, SETTINGS, EXEMINER
	if (EXEminer = "ERROR" OR !EXEminer){
		;no settings specified
		FileAppend,[%TimeString%] ERROR: EXEMINER value not set or present in ini.`n, %outputFile%
		Goto StopProgram
	}

	IniRead, timeToWaitTillIdle, %A_ScriptDir%\%INICONF%, SETTINGS, IDLEWAITTIME
	if (timeToWaitTillIdle = "ERROR" OR !timeToWaitTillIdle){
		;no settings specified
		FileAppend,[%TimeString%] ERROR: timeToWaitTillIdle value not set or present in ini using default (21 minutes).`n, %outputFile%
		timeToWaitTillIdle := "1260000"
	}
	if timeToWaitTillIdle is not integer
	{
		FileAppend,[%TimeString%] ERROR: timeToWaitTillIdle value is not numeric.`n, %outputFile%
		Goto StopProgram
	}	

	IniRead, LoginWaitTime, %A_ScriptDir%\%INICONF%, SETTINGS, LOGINWAITTIME
	if (LoginWaitTime = "ERROR" OR !LoginWaitTime){
		;no settings specified
		FileAppend,[%TimeString%] ERROR: LoginWaitTime value not set or present in ini using defaults (2 minutes).`n, %outputFile%
		LoginWaitTime := "120000"
	}
	if LoginWaitTime is not integer
	{
		FileAppend,[%TimeString%] ERROR: LoginWaitTime value is not numeric.`n, %outputFile%
		Goto StopProgram
	}	

	IniRead, ARGStoRun, %A_ScriptDir%\%INICONF%, SETTINGS, ARGSTORUN
	if (ARGStoRun = "ERROR" OR !ARGStoRun){
		;no settings specified
		FileAppend,[%TimeString%] ERROR: ARGSTORUN value not set or present in ini.`n, %outputFile%
		Goto StopProgram
	}

	IniRead, IdleTimer, %A_ScriptDir%\%INICONF%, SETTINGS, IDLELOOPTIMER
	if (IdleTimer = "ERROR" OR !IdleTimer){
		;no settings specified
		FileAppend,[%TimeString%] ERROR: IDLELOOPTIMER value not set or present in ini- using default.`n, %outputFile%
		IdleTimer := "5000"
	}
	
OldUserName := "NONE"
outputFile := A_ScriptDir "\idleOutput.log"

FileDelete, %A_ScriptDir%\logs\*-idleTime.log

FormatTime, TimeString, A_Now, dd/MM/yy HH:mm:ss

LogFileNum1 = 1
LogFileNum2 = 1
LogFileNum3 = 1
LogFileNum4 = 1
LogFileNum5 = 1

;EXEminer := "cpuMiner.exe"
TaskKillCommandToRun := "TASKKILL /F /IM " EXEminer " /T"

FileAppend,`n[%TimeString%] Starting App - %A_ScriptName%`n, %outputFile%

;#################
;done loading vars, now check if exist.

;Check if idleState.exe exists
if !FileExist(A_ScriptDir "\idleState.exe"){
	FileAppend, [%TimeString%] ERROR: Could not find idleState.exe`n, %outputFile%
	Goto StopProgram
}

;Check if idleLogon.exe exists
if !FileExist(A_ScriptDir "\idleLogon.exe"){
	FileAppend, [%TimeString%] ERROR: Could not find idleLogon.exe`n, %outputFile%
	Goto StopProgram
}

;run idleStateTask
If !InStr(StdOutToVar("SCHTASKS /RUN /TN ""\Idle Miner\idleStateTask"" "), "SUCCESS"){
	FileAppend, [%TimeString%] ERROR: Could not run idleStateTask- program will exit`n, %outputFile%
	Goto, StopProgram
}else{
	FileAppend, [%TimeString%] Task idleStateTask RAN OK`n, %outputFile%
}
	
;##################################

;possible future feature- to stop after x hours of running. just uncomment-
;Settimer,StopProgram,28800000 ;8hours stop program. ;stopped to keep program running


;here is where we dump the ini file settings to log for debugging.
FileAppend,     exe miner name: %EXEminer%.`n, %outputFile%
FileAppend,     args to run: %ARGStoRun%.`n, %outputFile%
FileAppend,     idleWait Time: %timeToWaitTillIdle%.`n, %outputFile%
FileAppend,     loginWait Time: %LoginWaitTime%.`n, %outputFile%
FileAppend,     IdleLoop Time: %IdleTimer%.`n, %outputFile%

;####################
SetTimer, IdleTime, %IdleTimer%
;####################

;####################
;run main loop
IdleTime:

	FormatTime, TimeString, A_Now, dd/MM/yy HH:mm:ss

	YoungestIdleTimeOverAll := "99999999999999"
	UserName := "NONE"


	colSettings := ComObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2").ExecQuery("Select UserName from Win32_ComputerSystem")._NewEnum

	While colSettings[strCSItem]
	{
		;Msgbox % strCSItem.UserName
		UserLoggedInViaWmic := StrSplit(strCSItem.UserName, "\")
		UserLoggedInViaWmic := UserLoggedInViaWmic[2]
	}

	
			;ReadOut := StdOutToVar("wmic computersystem get username")
			;SplitCommandByNewLine := StrSplit(ReadOut, "`n")
			;LoopAmount := SplitCommandByNewLine.maxindex()

			;Loop, %LoopAmount%
			;{
				;If InStr(SplitCommandByNewLine[A_Index], "UserName"){
				
					;try to get username of (a) logged in user
					;UserLoggedInViaWmic := StrSplit(SplitCommandByNewLine[A_Index+1], "\")
					;UserLoggedInViaWmic := UserLoggedInViaWmic[2]
					;StringReplace, UserLoggedInViaWmic, UserLoggedInViaWmic, `n, , All
					;StringReplace, UserLoggedInViaWmic, UserLoggedInViaWmic, `r, , All					
					;StringReplace, UserLoggedInViaWmic, UserLoggedInViaWmic, %A_Space%, , All
							
					;get time and set it back 30 seconds
					TimeThreshold := A_Now
					TimeThreshold += -30, seconds
					
					;loop the log files to try and find and get the youngest time and username of users idle time based on idleState.exe- irreverent of UserLoggedInViaWmic at this point
					Loop, %A_ScriptDir%\logs\*-idleTime.log
					{	;this is to delete log files older than 30 seconds.
						FileGetTime, ModTime, %A_ScriptDir%\logs\%A_LoopFileName%
						if (ModTime < TimeThreshold){
							FileDelete, %A_ScriptDir%\logs\%A_LoopFileName%
							FileAppend, [%TimeString%] Deleted file > %A_LoopFileName%`n, %outputFile%
						}else{
							Loop, read, %A_ScriptDir%\logs\%A_LoopFileName%
								{
									;FileName := A_LoopFileName
									SplitLine := StrSplit(A_LoopReadLine, ":::") ;reads lastline of textfile
								}
								if (YoungestIdleTimeOverAll > SplitLine[1]){
									YoungestIdleTimeOverAll := SplitLine[1]
									UserName := SplitLine[2]
								}
						}
					}
					
					;check if username has a value or not
					If (UserLoggedInViaWmic){
						;LoggedINAmount := LoopAmount - 3
						
						if (LogFileNum3 = 1){
						FileAppend, [%TimeString%] %UserLoggedInViaWmic% is reporting as logged in via wmic`n, %outputFile%
						LogFileNum1 = 1
						LogFileNum2 = 1
						LogFileNum3 = 0
						}
									
							if (UserName = "NONE"){ ;if username is still none but quser reports as another user then check to see if idelUser is running, if not attempt to start and reset. otherwise we could have an issue
								
								FileAppend, [%TimeString%] Someone is logged in but Username is still none`n, %outputFile%
								
								If !InStr(StdOutToVar("SCHTASKS /QUERY /TN ""\Idle Miner\idleStateTask"" "), "Running"){
									;if task is not running attempt to start and wait 5 seconds then restart
									
									If !InStr(StdOutToVar("SCHTASKS /RUN /TN ""\Idle Miner\idleStateTask"" "), "SUCCESS"){
										FileAppend, [%TimeString%] ERROR: Could not run idleStateTask- program will exit`n, %outputFile%
										Goto, StopProgram
									}else{
										FileAppend, [%TimeString%] Task idleStateTask running sleep and restart`n, %outputFile%
										SetTimer, IdleTime, off ;turn off idleTime and wait a few seconds
										Sleep, 10000 ;sleep 10 seconds
										SetTimer, IdleTime, %IdleTimer%
										Return										
									}
								}
							}
						;Break
					}else{
					;username has no value-
						;if wmic reports that no-one is logged on then check txtfile for username idle time. if that is 
					
						if (UserName = "NONE"){
						
							;if username contains no value and so does UserLoggedInViaWmic then assume noone is logged in.
							UserLoggedInViaWmic := "NONE"
							;UserName := "NONE"
							
							LogFileNum5 = 1
							if (LogFileNum4 = 1){
								FileAppend, [%TimeString%] user not present or logged off`n, %outputFile%
								LogFileNum4 = 0
							}								
							
							
						}else{
						
						;if username contains value but wmic does not then wait till username idle time is reached.

						
							LogFileNum4 = 1
							if (LogFileNum5 = 1){						
								FileAppend, [%TimeString%][%UserName%] idle contains value but wmic [%UserLoggedInViaWmic%] doesn't`n, %outputFile%	
								LogFileNum5 = 0
							}
								UserLoggedInViaWmic := UserName
						
						}
					
						
						LogFileNum3 = 1
				
					
						
						;FileAppend, >OUT>%ReadOut%`n, %outputFile%			
						;Goto, StopProgram
						;Break goto shutdown app
						;Break
					}
				;}else{
				;	FileAppend, [%TimeString%]ERROR READING USER LIST`n, %outputFile%
				;	FileAppend, >OUT>%ReadOut%`n, %outputFile%
				;	Goto, StopProgram
				;	;Break goto shutdown app
				;	Break
				;}
			;} ;end loop
			

	;if task is not running
	
	;delete after read file.

	IdleTimeOfUser := ConvertMSToMinSec(YoungestIdleTimeOverAll)

	if (YoungestIdleTimeOverAll > timeToWaitTillIdle){ ;21 minutes - pc is idle and miner can run.

		;pc is idle.
		
			LogFileNum2 = 1
			if (LogFileNum1 = 1){
				FileAppend, [%TimeString%][%UserName%][%IdleTimeOfUser%] PC IS IDLE`n, %outputFile%
			}
			
			;MNR_PID := checkForProcess(EXEminer)
			Process, Exist, %EXEminer%
			MNR_PID := ErrorLevel
			
			IF MNR_PID=0 ;if Miner is 0 then it is not running
			{
			
				;if (OldUserName <> UserName){ ; AND (OldUserName <> "NONE") AND (UserName <> "NONE")
				if (OldUserName <> UserName) AND (OldUserName <> "NONE"){
					FileAppend, [%TimeString%][%UserName%][%IdleTimeOfUser%] Username has changed`n, %outputFile%
					
					;if username has changed then this can be caused by someone logging off-we should wait for the user to login.
					
					SetTimer, IdleTime, off ;turn off idleTime and wait a few minutes 
					Sleep, LoginWaitTime ;2 mins ;we need to give enough time for a user to login?
					SetTimer, IdleTime, %IdleTimer%
					OldUserName := UserName
					Return
					
					;if someone has logged off they could just be logging off and not back on. if someone else is logged on it will take that- we need to wait to make sure its safe to run again.
				}
			
			
			;here we could say that if the username that is logged in doesn't match the idle user logged in then see if miner is running and start if not. note we placed this after LogFileNum1 so it is only run once after
				
				if (UserLoggedInViaWmic <> UserName){
				
					if (LogFileNum1 = 1){					
						FileAppend, [%TimeString%][ERROR][%UserName%][%UserLoggedInViaWmic%] Usernames are not the same (IDLE)`n, %outputFile%
					
					
						;here we could stop and start the task schedular idleUser to kick it back into action.	
						If !InStr(StdOutToVar("SCHTASKS /RUN /TN ""\Idle Miner\idleLogonTask"" "), "SUCCESS"){
							FileAppend, [%TimeString%] ERROR: Could not run idleLogonTask`n, %outputFile%
							;Goto, StopProgram
						}else{
							FileAppend, [%TimeString%][RESTART USERNAME] Task idleLogonTask RAN OK`n, %outputFile%
						}
					}
					
					;UserLoggedInViaWmic contains value- see if it matches UserName
				}else{
				
					PROGtoRun := EXEminer " " ARGStoRun
					Try
					{
						Run %PROGtoRun%,A_ScriptName "\" ,Min , MNR_PID
					}catch {
						FileAppend, [%TimeString%] Could not start cpuMiner!`n, %outputFile%
						Goto, StopProgram					
					}
					FileAppend, [%TimeString%] Successfully running cpuMiner`n, %outputFile%

				}
				LogFileNum1 = 0
			}else{			
				
				if (LogFileNum1 = 1){
					FileAppend, [%TimeString%] cpuMiner already running?`n, %outputFile%
					LogFileNum1 = 0
				}
			} ;end if miner already running									
		
	}else{
		;if idleTime has been reset
		;result is under 21 minutes-
		
		;MNR_PID := checkForProcess(EXEminer)
		Process, Exist, %EXEminer%
		MNR_PID := ErrorLevel
		
		LogFileNum1 = 1
		if (LogFileNum2 = 1){
			FileAppend, [%TimeString%][%UserName%][%IdleTimeOfUser%] NOT IDLE`n, %outputFile%
			FileAppend, [%TimeString%] MNRPID %MNR_PID%`n, %outputFile%
		}
		
		if (!MNR_PID = 0)
		{
		
			LogFileNum2 = 1
		
			Process, Close, %MNR_PID%
			MNR_PID := ErrorLevel
			;MNR_PID := "0"
			
			FileAppend, [%TimeString%] MNRPID Closing with PID %MNR_PID%`n, %outputFile%			
			
			if (MNR_PID = 0)
			{
				FileAppend, [%TimeString%] Could not close cpuMiner naturally`n, %outputFile%
				If !InStr(StdOutToVar(TaskKillCommandToRun), "SUCCESS"){
					FileAppend, [%TimeString%] Could not close cpuMiner forcefully`n, %outputFile%
					StdOutToVar(TaskKillCommandToRun)
					Goto, StopProgram
					;still did not close after force? need to log
				}else{
					FileAppend, [%TimeString%] Closed cpuMiner forcefully`n, %outputFile%
				}

				;MsgBox % "miner did not close" ;here we could force with taskkill /F /IM cmd.exe /T
			}else{
			FileAppend, [%TimeString%] Closed cpuMiner naturally`n, %outputFile%
			}	
		
		
		}else{			
		
			if (LogFileNum2 = 1){
				FileAppend, [%TimeString%] pc in-use and cpuMiner is not running`n, %outputFile%
				LogFileNum2 = 0
			}
			
		}		
		
		
	}

;change this to the same
OldUserName := UserName	

Return

;####################################

StopProgram:
	FileAppend, [%TimeString%] Closing Program`n, %outputFile%
	SetTimer, IdleTime, off
	
	Process, Exist, %EXEminer%
	MNR_PID := ErrorLevel
	
	FileAppend, [%TimeString%] MNRPID %MNR_PID%`n, %outputFile%

	
	;here we need to kill idleState.exe if running
	closeSMS := StdOutToVar("TASKKILL /F /IM idleState.exe /T")
	If InStr(closeSMS, "SUCCESS"){
		FileAppend, [%TimeString%] closed idleState successfully`n, %outputFile%
	}else If InStr(closeSMS, "ERROR: The process ""idleState.exe"" not found."){
		FileAppend, [%TimeString%] process idleState already closed`n, %outputFile%
	}else{
		FileAppend, [%TimeString%] ERROR: idleState- %closeSMS%`n, %outputFile%
	}
	
	;remove all files from log
	FileDelete, %A_ScriptDir%\logs\*-idleTime.log
	
	;ERROR: The process ""idleState.exe"" not found.
	
	IF MNR_PID=0 ;if Miner is 0 then it is not running
	{
		FileAppend, [%TimeString%] cpuMiner is not running`n, %outputFile%
		ExitApp
	}else{
		Process, Close, %MNR_PID%
		MNR_PID := ErrorLevel
		;MNR_PID := 0
		
		FileAppend, [%TimeString%] MNRPID Closing with PID %MNR_PID%`n, %outputFile%				

		if (!MNR_PID = 0){ ;process closed ok exit app
			FileAppend, [%TimeString%] cpuMiner closed ok- closing app`n, %outputFile%
			ExitApp
		}else{
			FileAppend, [%TimeString%] Could not close cpuMiner naturally`n, %outputFile%
			If !InStr(StdOutToVar(TaskKillCommandToRun), "SUCCESS"){
				FileAppend, [%TimeString%] Could not close cpuMiner forcefully`n, %outputFile%
				StdOutToVar(TaskKillCommandToRun)
				Goto, StopProgram
			}else{
				FileAppend, [%TimeString%] cpuMiner closed ok after forcing- closing app`n, %outputFile%
				ExitApp
			}
		}
	}
	
Return


;############################################################################################################
;Functions placed below here

ConvertMSToMinSec(ms){
  return floor(ms / 1000 / 60) "m " . round(mod(ms / 1000, 60)) "s"
}

StdOutToVar( sCmd ) { ;  GAHK32 ; Modified Version : SKAN 05-Jul-2013  http://goo.gl/j8XJXY                             
  Static StrGet := "StrGet"     ; Original Author  : Sean 20-Feb-2007  http://goo.gl/mxCdn  
   
  DllCall( "CreatePipe", UIntP,hPipeRead, UIntP,hPipeWrite, UInt,0, UInt,0 )
  DllCall( "SetHandleInformation", UInt,hPipeWrite, UInt,1, UInt,1 )

  VarSetCapacity( STARTUPINFO, 68, 0  )      ; STARTUPINFO          ;  http://goo.gl/fZf24
  NumPut( 68,         STARTUPINFO,  0 )      ; cbSize
  NumPut( 0x100,      STARTUPINFO, 44 )      ; dwFlags    =>  STARTF_USESTDHANDLES = 0x100 
  NumPut( hPipeWrite, STARTUPINFO, 60 )      ; hStdOutput
  NumPut( hPipeWrite, STARTUPINFO, 64 )      ; hStdError

  VarSetCapacity( PROCESS_INFORMATION, 16 )  ; PROCESS_INFORMATION  ;  http://goo.gl/b9BaI      
  
  If ! DllCall( "CreateProcess", UInt,0, UInt,&sCmd, UInt,0, UInt,0 ;  http://goo.gl/USC5a
              , UInt,1, UInt,0x08000000, UInt,0, UInt,0
              , UInt,&STARTUPINFO, UInt,&PROCESS_INFORMATION ) 
   Return "" 
   , DllCall( "CloseHandle", UInt,hPipeWrite ) 
   , DllCall( "CloseHandle", UInt,hPipeRead )
   , DllCall( "SetLastError", Int,-1 )     

  hProcess := NumGet( PROCESS_INFORMATION, 0 )                 
  hThread  := NumGet( PROCESS_INFORMATION, 4 )                      

  DllCall( "CloseHandle", UInt,hPipeWrite )

  AIC := ( SubStr( A_AhkVersion, 1, 3 ) = "1.0" )                   ;  A_IsClassic 
  VarSetCapacity( Buffer, 4096, 0 ), nSz := 0 
  
  While DllCall( "ReadFile", UInt,hPipeRead, UInt,&Buffer, UInt,4094, UIntP,nSz, UInt,0 )
   sOutput .= ( AIC && NumPut( 0, Buffer, nSz, "UChar" ) && VarSetCapacity( Buffer,-1 ) ) 
              ? Buffer : %StrGet%( &Buffer, nSz, "CP850" )
 
  DllCall( "GetExitCodeProcess", UInt,hProcess, UIntP,ExitCode )
  DllCall( "CloseHandle", UInt,hProcess  )
  DllCall( "CloseHandle", UInt,hThread   )
  DllCall( "CloseHandle", UInt,hPipeRead )

Return sOutput,  DllCall( "SetLastError", UInt,ExitCode )
}
