#include <stdio.h>
#include <windows.h>
#include <psapi.h>
#include <tchar.h>
#include <conio.h>
#include <string>
#include <direct.h>
#include <fstream>

#pragma comment( lib, "psapi.lib" )

DWORD pProcessIds[500];
DWORD cb = sizeof(pProcessIds);
DWORD pBytesReturned = 0;
void EnableDebugPriv( void );

//global scanning variables
DWORD BadProcsFound = 0;
DWORD BadRegFound = 0;
DWORD BadFilesFound = 0;

//FUNCTION PROTOTYPES
//PROCESS SECTION
//find and stop malicious processes
void TermPPProcesses(void);
//Check the processes for the bad ones
void CheckProcess( DWORD processID );
//put all the search terms here
int IsMalicious(char * ProcName);

//REGISTRY SECTION
#ifndef KEY_WOW64_64KEY
#define KEY_WOW64_64KEY 0x0100
#endif

typedef BOOL (WINAPI *LPFN_ISWOW64PROCESS) (HANDLE, PBOOL);
void DelPPRegistry(void);
BOOL Is64Bit();
BOOL IsWindowsNT();
BOOL IsAtLeastWindowsXP();
BYTE* GetRegistryValue( HKEY hBase, LPCTSTR lpSubKey, LPCTSTR lpValueName );
int SetRegistryValueXKS( HKEY hBase, LPCTSTR lpSubKey, LPCTSTR lpValueName, DWORD dwType, CONST BYTE* lpData, DWORD cbData );
int DelRegistryValue( HKEY hBase, LPCTSTR lpSubKey, LPCTSTR lpValueName );
void DelBadKey(HKEY hBase, char* regKey, char* regVal);

//DLL SECTION
void DelPPDlls(void);
bool FileExists(char *filePath, char *fileName);
void UnregDLL(char* RegSvrPath, char* filePath, char* fileName);
void WipeDLLs(char* RegSvrPath, char* filePath);

//FILE SECTION
void DelPPFiles(void);
void WipeFiles(char *filePath);
void DelPPFile(char *filePath, char *fileName);
void DelPPDirs(void);
bool DirExists(char* pathName);
void DelPPDir(char *pathName);

int RebootWindows()
{
HANDLE hToken;
TOKEN_PRIVILEGES tkp;

(!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES |
TOKEN_QUERY, &hToken));
LookupPrivilegeValue(NULL, "SeShutdownPrivilege",
&tkp.Privileges[0].Luid);

tkp.PrivilegeCount = 1;
tkp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;


AdjustTokenPrivileges(hToken, FALSE, &tkp, 0,
(PTOKEN_PRIVILEGES)NULL, 0);

ExitWindowsEx(EWX_REBOOT | EWX_FORCEIFHUNG, SHTDN_REASON_MAJOR_OPERATINGSYSTEM | SHTDN_REASON_MINOR_SECURITYFIX | SHTDN_REASON_FLAG_PLANNED);

/*
EWX_FORCE, EWX_REBOOT, EWX_POWEROFF, EWX_LOGOFF, EWX_SHUTDOWN
*/

return 0;
}

//main entry point
void main(void)
{
	//do intro text
	printf("     ====================================================================\n");
	printf("    |                     Windows Police Pro Fix 1.2                     |\n");
	printf("    |                                                                    |\n");
	printf("    |  This program was designed to remove Windows Police Pro Malware.   |\n");
	printf("    |   This software is provided AS-IS, with NO WARRANTY, EXPRESS OR    |\n");
	printf("    |       IMPLIED AS TO ANY FITNESS FOR ANY PARTICULAR PURPOSE.        |\n");
	printf("    | By Continuing, you agree the author will not be held liable for    |\n");
	printf("    | ANY damages to your system or data that may result from the use of |\n");
	printf("    |   this program. BY CONTINUING, YOU ARE DOING SO AT YOUR OWN RISK!  |\n");
	printf("    |                                                                    |\n");
	printf("    |                   Press C to Continue                              |\n");
	printf("    |                   Press X To eXit                                  |\n");
	printf("     ====================================================================\n");
	bool waiting = true;
	while(waiting)
	{
		int foo = getch();
		if(foo == 'x' || foo == 'X')
			return;
		if(foo == 'c' || foo == 'C')
			waiting = false;
	}

	system("cls");

	printf("Checking for Malicious Processes running on your system...\n");
	TermPPProcesses();

	printf("Scanning for Malicious Registry Keys...\n");
	DelPPRegistry();

	printf("Scanning for Malicious DLLs...\n");
	DelPPDlls();

	printf("Scanning for Other Malicious Files...\n");
	DelPPFiles();

	printf("Removing any Malicious Directories Found...\n");
	DelPPDirs();

	printf("Scan completed.\n\n");
	printf("\t\t ==============================\n");
	printf("\t\t|     SCAN RESULTS SUMMARY     |\n");
	printf("\t\t ============================== \n");
	printf("\t\t      Malicious Processes:  %d  \n",BadProcsFound);
	printf("\t\t  Malicious Registry Keys:  %d  \n",BadRegFound);
	printf("\t\t    Malicious Files Found:  %d  \n\n",BadFilesFound);

	//no infection found
	if(BadProcsFound == BadRegFound == BadFilesFound == 0)
	{
		printf("No Malicious Files were found during the scan.\n");
		printf("Press any key to exit the program...\n");
		while(!kbhit()){};
		return;
	}

	printf("The system should be restarted. Would you like to restart now?\n");
	printf("Press Y to Restart now\n");
	printf("Press X to eXit without restarting\n");

	waiting = true;
	while(waiting)
	{
		int foo = getch();
		if(foo == 'x' || foo == 'X')
			return;
		if(foo == 'y' || foo == 'Y')
			waiting = false;
	}
	//Restart Windows
	RebootWindows();
}

void DelPPDirs(void)
{
	char BadDir[MAX_PATH];
	char DriveName[MAX_PATH];
	GetWindowsDirectory(DriveName,MAX_PATH);

	//we have the windows path, so find the drive
	for(int i = 3; i< FILENAME_MAX; i++)
		DriveName[i] = '\0';

	//now we have the regsvr, let's search for bad files to unregister
	//sprintf_s(BadDir,"%sProgram Files\\Windows Police Pro\\",DriveName);
	char * env;

	//check stuff in program files directory
	env = getenv("PROGRAMFILES");
	if(env)
	{
		sprintf_s(BadDir,"%s\\WIndows Police Pro",env);
		DelPPDir(BadDir);

		sprintf_s(BadDir,"%s\\Windows Police Pro\\tmp",env);
		DelPPDir(BadDir);

		sprintf_s(BadDir,"%s\\Windows Police Pro\\tmp\\images",env);
		DelPPDir(BadDir);

		sprintf_s(BadDir,"%s\\LabelCommand",env);
		DelPPDir(BadDir);

		sprintf_s(BadDir,"%s",env);
		DelPPDir(BadDir);
	}

	env = getenv("SYSTEMROOT");
	if(env)
	{
		sprintf_s(BadDir,"%s\\Samples",env);
		DelPPDir(BadDir);

		sprintf_s(BadDir,"%s\\config\\systemprofile\\desktop\\",env);
		DelPPDir(BadDir);

		sprintf_s(BadDir,"%s\\config\\systemprofile\\start menu\\programs\\",env);
		DelPPDir(BadDir);

		sprintf_s(BadDir,"%s\\config\\systemprofile\\start menu\\programs\\windows police pro\\",env);
		DelPPDir(BadDir);
	}

	env = getenv("USERPROFILE");
	if(env)
	{
		sprintf_s(BadDir,"%s\\Local Settings\\Temp",env);
		DelPPDir(BadDir);
	}

	env = getenv("ALLUSERSPROFILE");
	if(env)
	{
		sprintf_s(BadDir,"%s\\Start Menu\\Programs\\Windows Police PRO",env);
		DelPPDir(BadDir);

		sprintf_s(BadDir,"%s\\Application Data\\Windows Police PRO",env);
		DelPPDir(BadDir);
	}
}

void DelPPDir(char *pathName)
{
	if(DirExists(pathName))
	{
		char cmd[MAX_PATH];
		sprintf_s(cmd,"attrib -r -h \"%s\"",pathName);
		system(cmd);
		_rmdir(pathName);
	}
}

bool DirExists(char *pathName)
{
	int error = _chdir(pathName);
	if(error != 0)
		return 0;
	_chdir("..");

	return 1;
}

void DelPPFiles(void)
{
	char BadDir[MAX_PATH];
	char DriveName[MAX_PATH];
	GetWindowsDirectory(DriveName,MAX_PATH);

	//we have the windows path, so find the drive
	for(int i = 3; i< FILENAME_MAX; i++)
		DriveName[i] = '\0';

	//now we have the regsvr, let's search for bad files to unregister
	char *env;

	env = getenv("PROGRAMFILES");
	if(env)
	{
		sprintf_s(BadDir,"%s\\Windows Police Pro\\",env);
		WipeFiles(BadDir);

		sprintf_s(BadDir,"%s\\Windows Police Pro\\tmp\\",env);
		WipeFiles(BadDir);

		sprintf_s(BadDir,"%s\\Windows Police Pro\\tmp\\images\\",env);
		WipeFiles(BadDir);

		sprintf_s(BadDir,"%s\\LabelCommand\\",env);
		WipeFiles(BadDir);

		sprintf_s(BadDir,"%s",env);
		WipeFiles(BadDir);
	}

	env = getenv("SYSTEMROOT");
	if(env)
	{
		sprintf_s(BadDir,"%s\\Samples\\",env);
		WipeFiles(BadDir);

		sprintf_s(BadDir,"%s\\config\\systemprofile\\desktop\\",env);
		WipeFiles(BadDir);

		sprintf_s(BadDir,"%s\\config\\systemprofile\\start menu\\programs\\",env);
		WipeFiles(BadDir);

		sprintf_s(BadDir,"%s\\config\\systemprofile\\start menu\\programs\\windows police pro\\",env);
		WipeFiles(BadDir);
	}

	env = getenv("USERPROFILE");
	if(env)
	{
		sprintf_s(BadDir,"%s\\Local Settings\\Temp\\",env);
		WipeFiles(BadDir);
	}

	env = getenv("ALLUSERSPROFILE");
	if(env)
	{
		sprintf_s(BadDir,"%s\\Start Menu\\Programs\\Windows Police PRO\\",env);
		WipeFiles(BadDir);

		sprintf_s(BadDir,"%s\\Application Data\\Windows Police PRO\\",env);
		WipeFiles(BadDir);
	}

	sprintf_s(BadDir,"%sWindows\\system\\",DriveName);
	WipeFiles(BadDir);

	sprintf_s(BadDir,"%sWindows\\system32\\",DriveName);
	WipeFiles(BadDir);
}

void WipeFiles(char *filePath)
{
	DelPPFile(filePath,"svcm80.dll");
	DelPPFile(filePath,"msvcp80.dll");
	DelPPFile(filePath,"msvcr80.dll");
	DelPPFile(filePath,"dddesot.dll");
	DelPPFile(filePath,"msvcm80.dll");
	DelPPFile(filePath,"Windows Police Pro.exe");
	DelPPFile(filePath,"ANTI_files.exe");
	DelPPFile(filePath,"dbsinit.exe");
	DelPPFile(filePath,"wispex.html");
	DelPPFile(filePath,"i1.gif");
	DelPPFile(filePath,"i2.gif");
	DelPPFile(filePath,"i3.gif");
	DelPPFile(filePath,"j1.gif");
	DelPPFile(filePath,"j2.gif");
	DelPPFile(filePath,"j3.gif");
	DelPPFile(filePath,"jj1.gif");
	DelPPFile(filePath,"jj2.gif");
	DelPPFile(filePath,"jj3.gif");
	DelPPFile(filePath,"l1.gif");
	DelPPFile(filePath,"l2.gif");
	DelPPFile(filePath,"l3.gif");
	DelPPFile(filePath,"pix.gif");
	DelPPFile(filePath,"t1.gif");
	DelPPFile(filePath,"t2.gif");
	DelPPFile(filePath,"up1.gif");
	DelPPFile(filePath,"up2.gif");
	DelPPFile(filePath,"w11.gif");
	DelPPFile(filePath,"w1.gif");
	DelPPFile(filePath,"w2.gif");
	DelPPFile(filePath,"w3.gif");
	DelPPFile(filePath,"w3.jpg");
	DelPPFile(filePath,"wt1.gif");
	DelPPFile(filePath,"wt2.gif");
	DelPPFile(filePath,"wt3.gif");
	DelPPFile(filePath,"minix32.exe");
	DelPPFile(filePath,"desote.exe");
	DelPPFile(filePath,"windows police pro.lnk");
}

void WipeDLLs(char* RegSvrPath, char *BadDir)
{
	UnregDLL(RegSvrPath,BadDir,"svcm80.dll");
	UnregDLL(RegSvrPath,BadDir,"msvcp80.dll");
	UnregDLL(RegSvrPath,BadDir,"msvcr80.dll");
	UnregDLL(RegSvrPath,BadDir,"dddesot.dll");
	UnregDLL(RegSvrPath,BadDir,"msvcm80.dll");
}

void DelPPDlls(void)
{
	//first we have to find regsvr32.exe

	//figure out what directory Windows is on
	char DriveName[FILENAME_MAX];
	char RegSvrPath[FILENAME_MAX];
	bool foundRegSvr = false;
	char BadDir[MAX_PATH];

	GetWindowsDirectory(DriveName,MAX_PATH);

	//we have the windows path, so find the drive
	for(int i = 3; i< FILENAME_MAX; i++)
		DriveName[i] = '\0';

	//now we need to check for regsvr32
		
	//change dir to windows
	sprintf_s(RegSvrPath,"%s%s",DriveName,"windows\\");
	if(FileExists(RegSvrPath,"regsvr32.exe"))
		foundRegSvr = true;
	
	if(!foundRegSvr)
	{
		sprintf_s(RegSvrPath,"%s%s",DriveName,"windows\\system\\");
		if(FileExists(RegSvrPath,"regsvr32.exe"))
		foundRegSvr = true;
	}
	
	if(!foundRegSvr)
	{
		sprintf_s(RegSvrPath,"%s%s",DriveName,"windows\\system32\\");
		if(FileExists(RegSvrPath,"regsvr32.exe"))
		foundRegSvr = true;
	}

	//EPIC fail, could not find RegSvr32.exe
	if(!foundRegSvr)
		return;

	//now we have the regsvr, let's search for bad files to unregister
	char* env;
	env = getenv("PROGRAMFILES");
	if(env)
	{
		sprintf_s(BadDir,"%s\\Windows Police Pro",env);
		WipeDLLs(RegSvrPath,BadDir);

		sprintf_s(BadDir,"%s\\Windows Police Pro\\tmp",env);
		WipeDLLs(RegSvrPath,BadDir);

		sprintf_s(BadDir,"%s\\Windows Police Pro\\tmp\\images",env);
		WipeDLLs(RegSvrPath,BadDir);

		sprintf_s(BadDir,"%s\\LabelCommand",env);
		WipeDLLs(RegSvrPath,BadDir);

		sprintf_s(BadDir,"%s",env);
		WipeDLLs(RegSvrPath,BadDir);
	}

	env = getenv("SYSTEMROOT");
	if(env)
	{
		sprintf_s(BadDir,"%s\\Samples",env);
		WipeDLLs(RegSvrPath,BadDir);

		sprintf_s(BadDir,"%s\\config\\systemprofile\\desktop",env);
		WipeDLLs(RegSvrPath,BadDir);

		sprintf_s(BadDir,"%s\\config\\systemprofile\\start menu\\programs",env);
		WipeDLLs(RegSvrPath,BadDir);

		sprintf_s(BadDir,"%s\\config\\systemprofile\\start menu\\programs\\windows police pro",env);
		WipeDLLs(RegSvrPath,BadDir);
	}

	env = getenv("USERPROFILE");
	if(env)
	{
		sprintf_s(BadDir,"%s\\Local Settings\\temp",env);
		WipeDLLs(RegSvrPath,BadDir);
	}

	env = getenv("ALLUSERSPROFILE");
	if(env)
	{
		sprintf_s(BadDir,"%s\\Start Menu\\Programs\\Windows Police PRO",env);
		WipeDLLs(RegSvrPath,BadDir);

		sprintf_s(BadDir,"%s\\Application Data\\Windows Police Pro",env);
		WipeDLLs(RegSvrPath,BadDir);
	}
}

void DelPPFile(char *filePath, char *fileName)
{
	char cmd[1024];
	if(FileExists(filePath, fileName))
	{
		BadFilesFound ++;
		//Delete the file
		printf("Deleting Malicious File: \n%s%s\n",filePath, fileName);
		//make it not read only or hidden
		sprintf_s(cmd,"attrib -r -h \"%s%s\"",filePath, fileName);
		system(cmd);
		//and delete it
		sprintf_s(cmd,"del \"%s%s\"",filePath, fileName);
		system(cmd);
		if(FileExists(filePath,fileName))
			printf("FAILED TO DELETE FILE: %s%s",filePath, fileName);
		else
			printf("SUCCESSFULY DELETED FILE: %s%s",filePath, fileName);
	}
}

void UnregDLL(char *RegSvrPath, char *filePath, char* fileName)
{
	char cmd[1024];
	if(FileExists(filePath, fileName))
	{
		//unregister the DLL
		printf("Unregistering Malicious DLL:\n %s\\%s\n",filePath, fileName);
		sprintf_s(cmd,"%sregsvr32.exe /u \"%s\\%s\"",RegSvrPath, filePath, fileName);
		system(cmd);
	}
}

bool FileExists(char *filePath, char *fileName)
{
	//make sure the path is valid
	if(!DirExists(filePath))
		return false;

	std::fstream foo;

	//change to the dir
	_chdir(filePath);

	//open the file
	foo.open(fileName,std::ios.in);
	if(foo.is_open())
	{
		foo.clear();
		foo.close();
		return true;
	}
	foo.clear();
	foo.close();
	return false;
}

void TermPPProcesses(void)
{
	//get list of process ids
	if(!EnumProcesses(pProcessIds,cb,&pBytesReturned))
		return;

	//calc # of processes
	DWORD count = pBytesReturned / sizeof(DWORD);

	EnableDebugPriv();

	//display the id's
	for(DWORD i = 0; i < count; i++)
		CheckProcess(pProcessIds[i]);
}

void CheckProcess( DWORD processID )
{
    TCHAR szProcessName[MAX_PATH] = TEXT("<unknown>");
	char ProcName[MAX_PATH] = "<unknown>";

    // Get a handle to the process.

    HANDLE hProcess = OpenProcess( PROCESS_QUERY_INFORMATION |
                                   PROCESS_VM_READ | PROCESS_TERMINATE,
                                   FALSE, processID );

    // Get the process name.

    if (NULL != hProcess )
    {
        HMODULE hMod;
        DWORD cbNeeded;

        if ( EnumProcessModules( hProcess, &hMod, sizeof(hMod), 
             &cbNeeded) )
        {
            GetModuleBaseName( hProcess, hMod, szProcessName, 
                               sizeof(szProcessName)/sizeof(TCHAR) );
			//convert the name to lowercase
			sprintf(ProcName,"%s",strlwr(szProcessName));
        }
    }

    // Print the process name and identifier.
	
    //_tprintf( TEXT("%s  (PID: %u)\n"), szProcessName, processID );
	if(IsMalicious(ProcName) == 1)
	{
		//print the message
		_tprintf( TEXT("%s - DETECTED, TERMINATING"), szProcessName );
		
		//add to the global var
		BadProcsFound++;

		//kill the process
		
		DWORD exitcode = STILL_ACTIVE;
		DWORD count = 0;
		while(exitcode == STILL_ACTIVE)
		{
			//kill the process
			TerminateProcess(hProcess,0);
			GetExitCodeProcess(hProcess,&exitcode);
			Sleep(30);
			//could not kill process, so bail in 5 seconds
			count++;
			if(count %33 == 0)
				printf(".");
			if(count == 100)
			{
				char bksp[26];
				memset(bksp,(char)8,sizeof(bksp));
				bksp[25] = '\0';
				printf(bksp);

				printf(" COULD NOT BE TERMINATED!\n");
				CloseHandle( hProcess );
				return;
			}
		}
		//show some user output
		char bksp[24];
		memset(bksp,(char)8,sizeof(bksp));
		bksp[23] = '\0';
		printf(bksp);
		printf(" TERMINATED SUCCESSFULLY!\n");
	}

	//close process handle
    CloseHandle( hProcess );
}

int IsMalicious(char * ProcName)
{
	if(strcmp(ProcName,"windows police pro.exe") == 0)
		return 1;
	if(strcmp(ProcName,"anti_files.exe") == 0)
		return 1;
	if(strcmp(ProcName,"dbsinit.exe") == 0)
		return 1;
	if(strcmp(ProcName,"minix32.exe") == 0)
		return 1;
	if(strcmp(ProcName,"svchast.exe") == 0)
		return 1;
	if(strcmp(ProcName,"desote.exe") == 0)
		return 1;
	//nothing found
	return 0;
}

//REGISTRY SECTION
void DelPPRegistry(void)
{
	char* regKey = new char[256];
	char* regVal = new char[256];

	//Test first key area	
	//set what we're searching for
	strcpy(regKey, "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run");
	strcpy(regVal,"Windows Police Pro");
	DelBadKey(HKEY_CURRENT_USER,regKey, regVal);
	strcpy(regVal,"minix32");
	DelBadKey(HKEY_CURRENT_USER,regKey, regVal);
	
	//Test 2nd Key Area
	strcpy(regKey, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Run");
	strcpy(regVal,"Windows Police Pro");
	DelBadKey(HKEY_CURRENT_USER,regKey, regVal);
	strcpy(regVal,"minix32");
	DelBadKey(HKEY_CURRENT_USER,regKey, regVal);

	//Test 3rd Key Area
	strcpy(regKey, "Software");
	strcpy(regVal,"Windows Police Pro");
	DelBadKey(HKEY_CURRENT_USER,regKey, regVal);
	DelBadKey(HKEY_LOCAL_MACHINE,regKey, regVal);
	strcpy(regVal,"minix32");
	DelBadKey(HKEY_CURRENT_USER,regKey, regVal);
	DelBadKey(HKEY_LOCAL_MACHINE, regKey, regVal);

	//Test 4th Key area
	strcpy(regKey, "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall");
	strcpy(regVal,"Windows Police Pro");
	DelBadKey(HKEY_LOCAL_MACHINE,regKey, regVal);
	strcpy(regVal,"minix32");
	DelBadKey(HKEY_LOCAL_MACHINE,regKey, regVal);

	//Test 5th Key Area
	strcpy(regKey, "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Uninstall");
	strcpy(regVal,"Windows Police Pro");
	DelBadKey(HKEY_LOCAL_MACHINE,regKey, regVal);
	strcpy(regVal,"minix32");
	DelBadKey(HKEY_LOCAL_MACHINE,regKey, regVal);

	//test 6th Key Area
	strcpy(regKey,"Software\\microsoft\\windows\\shellnoroam\\muicache");
	DelBadKey(HKEY_CURRENT_USER,"C:\\windows\\system32\\desote.exe","desote");
	DelBadKey(HKEY_CURRENT_USER,"C:\\program files\\windows police pro\\windows police pro.exe","TODO: <File description>");
	DelBadKey(HKEY_USERS,"C:\\windows\\system32\\desote.exe","desote");
	DelBadKey(HKEY_USERS,"C:\\program files\\windows police pro\\windows police pro.exe","TODO: <File description>");


	//Fix the Desote Registry Entries
	char val[MAX_PATH];
	strcpy(val,"\"%1\" %*");
	SetRegistryValueXKS(HKEY_CLASSES_ROOT,"exefile\\shell\\open\\command",NULL,REG_SZ,(const BYTE*) val, strlen(val));
	SetRegistryValueXKS(HKEY_CLASSES_ROOT,"exefile\\shell\\runas\\command",NULL,REG_SZ,(const BYTE*) val, strlen(val));
	SetRegistryValueXKS(HKEY_LOCAL_MACHINE,"software\\classes\\exefile\\shell\\open\\command",NULL,REG_SZ,(const BYTE*) val, strlen(val));
	SetRegistryValueXKS(HKEY_LOCAL_MACHINE,"software\\classes\\exefile\\shell\\runas\\command",NULL,REG_SZ,(const BYTE*) val, strlen(val));
		
	//clean up
	delete [] regKey;
	delete [] regVal;
}

void DelBadKey(HKEY hBase, char* regKey, char* regVal)
{
	BYTE* BadOne = NULL;
	BadOne = GetRegistryValue(hBase, regKey, regVal);
	if(BadOne != NULL)
	{
		printf("Found Key - %s\\%s\nAttempting To Delete...\n",regKey,regVal);
		BadRegFound++;
		//try to delete it
		if(DelRegistryValue(hBase, regKey, regVal) == 0)
		{
			printf("ERROR Deleting Key %s\\%s\n",regKey, regVal);
			return;
		}

		//try to open it again to verify it was deleted
		BadOne = GetRegistryValue(hBase, regKey, regVal);
		if(BadOne != NULL)
		{
			printf("ERROR Deleting Key %s\\%s\n",regKey, regVal);
			return;
		}
		else
			//success?
			printf("SUCCESS Deleting Key %s\\%s\n",regKey, regVal);
	}
}

BYTE* GetRegistryValue( HKEY hBase, LPCTSTR lpSubKey, LPCTSTR lpValueName )
{
	HKEY hKey;
	BYTE* szValue		= NULL;
	REGSAM samDesired	= KEY_QUERY_VALUE;
	
	// If we are on Windows XP or later and are running on a 64-bit operating system,
	// we'll need to disable registry redirection to access the required registry keys.
	if ( IsAtLeastWindowsXP() && Is64Bit() )
	{
		samDesired |= KEY_WOW64_64KEY;
	}

	long lResult = RegOpenKeyEx(hBase, lpSubKey, NULL, samDesired, &hKey);
	if ( lResult == ERROR_SUCCESS )
	{
		DWORD cbData;
		DWORD dwType;

		lResult = RegQueryValueEx(hKey, lpValueName, NULL, &dwType, NULL, &cbData);
		if ( lResult == ERROR_SUCCESS )
		{
			szValue = new BYTE[cbData];
			
			lResult = RegQueryValueEx(hKey, lpValueName, NULL, &dwType, szValue, &cbData);
			if ( lResult != ERROR_SUCCESS )
			{
				delete[] szValue;
				szValue = NULL;
			}
		}
	}

	RegCloseKey(hKey);
	return szValue;
}

int SetRegistryValueXKS( HKEY hBase, LPCTSTR lpSubKey, LPCTSTR lpValueName, DWORD dwType, CONST BYTE* lpData, DWORD cbData )
{
	HKEY hKey;
	BYTE* szValue		= NULL;
	REGSAM samDesired	= KEY_SET_VALUE;
	
	// If we are on Windows XP or later and are running on a 64-bit operating system,
	// we'll need to disable registry redirection to access the required registry keys.
	if ( IsAtLeastWindowsXP() && Is64Bit() )
	{
		samDesired |= KEY_WOW64_64KEY;
	}

	long lResult = RegOpenKeyEx(hBase, lpSubKey, NULL, samDesired, &hKey);
	if ( lResult == ERROR_SUCCESS )
	{

		lResult = RegSetValueEx(hKey, lpValueName, NULL, dwType, lpData, cbData);
		if ( lResult != ERROR_SUCCESS )
		{
			//attempt to make it human readable
			char* msg=new char[1024];
			FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,
						  NULL, 
						  lResult,
						  0,
						  msg,
						  1024,
						  NULL);
			//attempt to tell the world about it
			MessageBox(NULL,msg,"Error",MB_OK);
			
			//clean up
			delete[] msg;

			//close the key
			RegCloseKey(hKey);
			return 0;//failure
		}
	}

	RegCloseKey(hKey);
	return 1;//success
}

int DelRegistryValue( HKEY hBase, LPCTSTR lpSubKey, LPCTSTR lpValueName )
{
	HKEY hKey;
	BYTE* szValue		= NULL;
	REGSAM samDesired	= KEY_SET_VALUE;
	
	// If we are on Windows XP or later and are running on a 64-bit operating system,
	// we'll need to disable registry redirection to access the required registry keys.
	if ( IsAtLeastWindowsXP() && Is64Bit() )
	{
		samDesired |= KEY_WOW64_64KEY;
	}

	long lResult = RegOpenKeyEx(hBase, lpSubKey, NULL, samDesired, &hKey);
	if ( lResult == ERROR_SUCCESS )
	{

		lResult = RegDeleteValue(hKey, lpValueName);
		if ( lResult != ERROR_SUCCESS )
		{
			//attempt to make it human readable
			char* msg=new char[1024];
			FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM,
						  NULL, 
						  lResult,
						  0,
						  msg,
						  1024,
						  NULL);
			//attempt to tell the world about it
			MessageBox(NULL,msg,"Error",MB_OK);
			
			//clean up
			delete[] msg;

			//close the key
			RegCloseKey(hKey);
			return 0;//failure
		}
	}

	RegCloseKey(hKey);
	return 1;//success
}

BOOL Is64Bit()
{
	BOOL bIsWow64 = FALSE;
	LPFN_ISWOW64PROCESS fnIsWow64Process;

    fnIsWow64Process = (LPFN_ISWOW64PROCESS)GetProcAddress(
						GetModuleHandle("kernel32.dll"), "IsWow64Process");
						
	if ( fnIsWow64Process != NULL )
    {
        fnIsWow64Process(GetCurrentProcess(), &bIsWow64);
    }
	
    return bIsWow64;
}

BOOL IsAtLeastWindowsXP()
{
	OSVERSIONINFO os;
	ZeroMemory(&os, sizeof(OSVERSIONINFO));
	os.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
	GetVersionEx(&os);
	
	return ((os.dwMajorVersion > 5) || ((os.dwMajorVersion == 5) && (os.dwMinorVersion >= 1)));
}

void EnableDebugPriv( void )
{
	HANDLE hToken;
	LUID sedebugnameValue;
	TOKEN_PRIVILEGES tkp;

	if ( ! OpenProcessToken( GetCurrentProcess(),
		TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken ) )
			return;
	
	if ( ! LookupPrivilegeValue( NULL, SE_DEBUG_NAME, &sedebugnameValue ) )
	{
		CloseHandle( hToken );
		return;
	}

	tkp.PrivilegeCount = 1;
	tkp.Privileges[0].Luid = sedebugnameValue;
	tkp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED;

	if ( ! AdjustTokenPrivileges( hToken, FALSE, &tkp, sizeof tkp, NULL, NULL ) )
		printf("SeDebugPrivilege is not available.\n");
	else
		printf("SeDebufPrivilege Successfully Enabled!\n");

	CloseHandle( hToken );
}


/*BOOL IsWindowsNT()
{
	OSVERSIONINFO os;
	ZeroMemory(&os, sizeof(OSVERSIONINFO));
	os.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
	GetVersionEx(&os);

	return (os.dwPlatformId == VER_PLATFORM_WIN32_NT);
}*/
