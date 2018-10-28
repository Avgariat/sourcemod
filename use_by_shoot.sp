#pragma semicolon 1
#include <sdktools>
#include <sourcemod>

public Plugin myinfo = 
{
	name = "Shoot_button",
	author = "Avgariat",
	description = "Press/Use button just by shoot",
	version = "1.0",
	url = "http://arenaskilla.pl/index.php"
}

public void OnPluginStart()
{
	HookEntityOutput("func_button", "OnDamaged", func_button);
}

public void func_button(const char[] output, int caller, int activator, float delay)
{
	AcceptEntityInput(caller, "Press");
}