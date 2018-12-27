#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[CS:GO] RedChatBugFix",
	author = "Avgariat",
	description = "Fix red chat bug",
	version = "1.0",
	url = "https://arenaskilla.pl/"
};

public Action OnChatMessage(int &client, Handle recipients, char[] name, char[] message) {
	if(StrContains(message, "") == -1)
		return Plugin_Continue;
	ReplaceString(message, 512 - strlen(name), "", "");
	return Plugin_Changed;
}