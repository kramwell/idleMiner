# idleMiner
 11/JUN/2018 - A program to mine CPU coins when a computer is deemed idle.

The only TRUE idle detection software not just for one but multiple logged in users, RDP logins, Terminal logins 
and it also lets you define a type of idle detection state (see config.ini file)

Install Instructions

	Download AHK program and compile these scripts to exe
	Copy all to folder on homedrive (e.g. c:\idleMiner).
	Execute first-run.exe as Administrator.
	Execute idleMiner.exe as Administrator (or run from Task Scheduler).

--

Sample log file 

from idleOutput.log (changed default idleTime from 21 minutes to 25 seconds to test)

	[09/12/18 21:15:59] Starting App - idleMiner.exe
	[09/12/18 21:15:59] Task idleStateTask RAN OK
	exe miner name: cpuMiner.exe.
	args to run: -a ALGO -o stratum+tcp://somepool.com:9999 -u WALLETADDRESS -p c=IDONTKNOW.
	idleWait Time: 25000.
	loginWait Time: 120000.
	IdleLoop Time: 5000.
	[09/12/18 21:15:59] Owner is reporting as logged in via wmic
	[09/12/18 21:15:59][Owner][0m 0s] NOT IDLE
	[09/12/18 21:15:59] MNRPID 0
	[09/12/18 21:15:59] pc in-use and cpuMiner is not running
	[09/12/18 21:16:34][Owner][0m 28s] PC IS IDLE
	[09/12/18 21:16:34] Successfully running cpuMiner
	[09/12/18 21:17:19][Owner][0m 0s] NOT IDLE
	[09/12/18 21:17:19] MNRPID 688
	[09/12/18 21:17:19] MNRPID Closing with PID 688
	[09/12/18 21:17:19] Closed cpuMiner naturally
	[09/12/18 21:17:24][Owner][0m 0s] NOT IDLE
	[09/12/18 21:17:24] MNRPID 0
	[09/12/18 21:17:24] pc in-use and cpuMiner is not running