#include <sourcemod>
#include <emitsoundany>

#pragma newdecls required
#pragma semicolon 1

#define sSoundPath "arenaskilla/knifekill_loud.mp3"

char sSoundPathFull[PLATFORM_MAX_PATH];
float SoundVolume = 1.0;

public Plugin myinfo =
{
	name = "[CS:GO] Knife kill sound",
	description = "Plays sound after knife kill",
	author = "Avgariat",
	version = "1.0",
	url = "http://arenaskilla.pl"
};

public void OnPluginStart()
{ 
	Format(sSoundPathFull, sizeof(sSoundPathFull), "sound/%s", sSoundPath);
	HookEvent("player_death", PlayerDeath);
}

public void OnConfigsExecuted()
{
	PrecacheSoundAny(sSoundPath);
	AddFileToDownloadsTable(sSoundPathFull);
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidPlayer(attacker, true) || !IsValidPlayer(client))
		return;
	
	char weapon[64];
	GetClientWeapon(attacker, weapon, sizeof(weapon));
	if(StrContains(weapon, "weapon_knife") != -1 || StrContains(weapon, "bayonet") != -1)
			PlayMusicAll(sSoundPath);
	
}

//Code of Abner`s
public void PlayMusicAll(char[] szSound)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidPlayer(i))
		{
			ClientCommand(i, "playgamesound Music.StopAllMusic");
			EmitSoundToClientAny(i, szSound, -2, 0, 0, 0, SoundVolume, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		}
	}
}

stock bool IsValidPlayer(int client, bool bAlive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client) && (!bAlive || IsPlayerAlive(client)))
		return true;
	return false;
}