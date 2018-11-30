#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo =
{
	name = "CHMOD changer",
	author = "Avgariat",
	description = "Changes files chmod",
	version = "1.0",
	url = "http://arenaskilla.pl"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_change", ChangeChmod, ADMFLAG_ROOT);
}

public Action ChangeChmod(int client, int args)
{
	if(args != 2)
	{
		PrintToConsole(client, "Liczba argumentow jest niewlasciwa!");
		return Plugin_Continue;
	}
	bool gud = false;
	char arg1[64], arg2[8];
	int chmod = 770;
	GetCmdArg(1, arg1, sizeof(arg1));
	char sPath[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, sPath, sizeof(sPath), arg1);
	GetCmdArg(2, arg2, sizeof(arg2));
	chmod = StringToInt(arg2, 8);

	gud = SetFilePermissions(sPath, chmod);
	if(gud)
		PrintToConsole(client, "Zmieniono chmod na %i dla %s", chmod, arg1);
	return Plugin_Continue;
}