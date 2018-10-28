#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MAX_ALLOWED_ENTS 50
#define REMOVE_TIMER_FREQUENCY 30.0

public Plugin myinfo =
{
	name = "Entity remover",
	author = "Avgariat",
	description = "Removes entities from map",
	version = "1.0",
	url = "http://arenaskilla.pl"
};

enum EntityInfoType
{
	String:enclassname[64],
	String:enname[64]
}

char DATAFILE[256] = "configs/as_shop/removed_entities.cfg";
KeyValues g_kv;
char EntityInfo[MAX_ALLOWED_ENTS][EntityInfoType];
int MAX_REMOVED_ENTS;

public void OnPluginStart()
{
	char t_DATAFILE[256];
	strcopy(t_DATAFILE, sizeof(t_DATAFILE), DATAFILE);
	BuildPath(Path_SM, DATAFILE, sizeof(DATAFILE), t_DATAFILE);
	g_kv = new KeyValues("Arenaskilla - Removed Entities");
	g_kv.ImportFromFile(DATAFILE);
	if (!FileExists(DATAFILE))
		g_kv.ExportToFile(DATAFILE);
	
	RegAdminCmd("sm_ent_remove", RemoveEnt, ADMFLAG_ROOT);
	RegAdminCmd("sm_ent_get", GetAimingEnt, ADMFLAG_ROOT);
	RegAdminCmd("sm_ent_list", RemovedEntitiesListCMD, ADMFLAG_ROOT);
	
	HookEvent("round_start", RoundStart);
}

public void OnPluginEnd()
{
	g_kv.ExportToFile(DATAFILE);
	delete g_kv;
}

public void OnMapStart()
{
	LoadEntities();
	CreateTimer(15.0, TimerRemoveRepeat, _, TIMER_FLAG_NO_MAPCHANGE);
}


public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(10.0, TimerRemove, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	char name[64];
	GetEntityName(entity, name, sizeof(name));
	if(StrEqual(name, ""))
		return;
	for(int i=0; i < MAX_ALLOWED_ENTS; i++)	//Petla po entach zapisanych do usuniecia
	{
		if(StrEqual(EntityInfo[i][enname], ""))
			continue;
		if(!StrEqual(EntityInfo[i][enclassname], classname))
			continue;
		if(!StrEqual(EntityInfo[i][enname], name))
			continue;
		
		RemoveGivenEnt(entity);
		break;
	}
}

public Action RemoveEnt(int client, int args)
{
	int target = GetClientAimTarget(client, false);
	if(target == -2)
	{
		PrintToConsole(client, "Entity Remover is not supported.");
		PrintToChat(client, "Entity Remover is not supported.");
		return Plugin_Continue;
	}
	if(target == -1)
	{
		PrintToConsole(client, "No entity was found at aiming point.");
		PrintToChat(client, "No entity was found at aiming point.");
		return Plugin_Continue;
	}
	
	char clsname[64];
	GetEntityClassname(target, clsname, sizeof(clsname));
	if(StrEqual(clsname, "player"))
	{
		PrintToConsole(client, "Player cannot be targeted to be removed.");
		PrintToChat(client, "Player cannot be targeted to be removed.");
		return Plugin_Continue;
	}
	
	char name[64];
	GetEntityName(target, name, sizeof(name));
	if(strlen(name) == 0)
	{
		PrintToConsole(client, "Entity has no name, so it has not been saved.");
		PrintToChat(client, "Entity has no name, so it has not been saved.");
		PrintToConsole(client, "Entity removed. |ID: \"%i\" |ClassName: \"%s\" |Name: \"%s\"", target, clsname, name);
		PrintToChat(client, "Entity removed. |ID: \"%i\" |ClassName: \"%s\" |Name: \"%s\"", target, clsname, name);
		RemoveGivenEnt(target);
		return Plugin_Continue;
	}
	
	SaveEntity(name, clsname);
	RemoveGivenEnt(target);
	
	PrintToConsole(client, "Entity removed. |ID: \"%i\" |ClassName: \"%s\" |Name: \"%s\"", target, clsname, name);
	PrintToChat(client, "Entity removed. |ID: \"%i\" |ClassName: \"%s\" |Name: \"%s\"", target, clsname, name);
	return Plugin_Continue;
}

public Action GetAimingEnt(int client, int args)
{
	int target = GetClientAimTarget(client, false);
	if(target == -2)
	{
		PrintToConsole(client, "Entity Remover is not supported.");
		PrintToChat(client, "Entity Remover is not supported.");
		return Plugin_Continue;
	}
	if(target == -1)
	{
		PrintToConsole(client, "No entity was found at aiming point.");
		PrintToChat(client, "No entity was found at aiming point.");
		return Plugin_Continue;
	}
	
	char clsname[64];
	GetEntityClassname(target, clsname, sizeof(clsname));
	
	char name[64];
	GetEntityName(target, name, sizeof(name));
	
	PrintToConsole(client, "Entity data. |ID: \"%i\" |ClassName: \"%s\" |Name: \"%s\"", target, clsname, name);
	PrintToChat(client, "Entity data. |ID: \"%i\" |ClassName: \"%s\" |Name: \"%s\"", target, clsname, name);
	return Plugin_Continue;
}

public Action RemovedEntitiesListCMD(int client, int args)
{
	RemovedEntitiesList(client);
}

public Action RemovedEntitiesList(int client)
{
	char WB[512];
	FormatEx(WB, 512, " ★ AremaSkilla.pl | Removed entities list");
	Format(WB, 512, "%s\n ", WB);
	
	Menu menu = CreateMenu(RemovedEntitiesList_Handler);
	SetMenuTitle(menu, WB);
	
	AddMenuItem(menu, "removeall", "Remove saved entities from map");
	
	for(int i=0; i < MAX_REMOVED_ENTS; i++)
	{
		if(StrEqual(EntityInfo[i][enname], ""))
			continue;
		char numerek[32], textline[128];
		Format(numerek, sizeof(numerek), "%i", i);
		Format(textline, sizeof(textline), "Delete |%s |%s", EntityInfo[i][enname], EntityInfo[i][enclassname]);
		AddMenuItem(menu, numerek, textline);
	}
	
	DisplayMenu(menu, client, 250);
}

public int RemovedEntitiesList_Handler(Handle classhandle, MenuAction action, int client, int Position)
{
	if(action == MenuAction_Select)
	{
		char Item[32];
		GetMenuItem(classhandle, Position, Item, sizeof(Item));
		if(StrEqual(Item, "removeall"))
		{
			RemoveSavedEntitiesFromMap();
		}
		else
		{
			int t_ent_id = StringToInt(Item);
			ConfirmDeletingEntity(client, EntityInfo[t_ent_id][enname], EntityInfo[t_ent_id][enclassname]);
		}
	}
	else if(action == MenuAction_End)
		CloseHandle(classhandle);
}

// No confirmation at the moment
public Action ConfirmDeletingEntity(int client, const char[] name, const char[] clsname)
{
	PrintToConsole(client, "Entity deleted. |Name: \"%s\" |ClassName: \"%s\" ", name, clsname);
	PrintToChat(client, "Entity deleted. |Name: \"%s\" |ClassName: \"%s\" ", name, clsname);
	DeleteEntity(name);
}

public bool LoadEntities()
{
	MAX_REMOVED_ENTS = 0;
	
	for(int i=0; i < MAX_ALLOWED_ENTS; i++)
	{
		strcopy(EntityInfo[i][enclassname], 63, "");
		strcopy(EntityInfo[i][enname], 63, "");
	}
	
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	
	if (!g_kv.JumpToKey(mapname))
		return false;
	
	if (!g_kv.JumpToKey("entities"))
	{
		g_kv.Rewind();
		return false;
	}
	
	if (!g_kv.GotoFirstSubKey())
	{
		g_kv.Rewind();
		return false;
	}
	
	int pos = 0;
	do
	{
		char name[64], clsname[64];
		
		g_kv.GetSectionName(name, sizeof(name));
		g_kv.GetString("class", clsname, sizeof(clsname));
		
		strcopy(EntityInfo[pos][enclassname], 63, clsname);
		strcopy(EntityInfo[pos][enname], 63, name);
		
		pos++;
	} while (g_kv.GotoNextKey());
	MAX_REMOVED_ENTS = pos;
	
	g_kv.Rewind();
	
	return true;
}
 

public void RemoveSavedEntitiesFromMap()
{
	int MaxEntities = GetMaxEntities();
	char entclsname[64], entname[64];
	for (int i = MaxClients+1; i < MaxEntities; i++)	//Petla po dostepnych entach na mapie
	{
		if (!IsValidEntity(i))
			continue;
		GetEntityClassname(i, entclsname, sizeof(entclsname));
		GetEntityName(i, entname, sizeof(entname));
		for(int j=0; j < MAX_ALLOWED_ENTS; j++)	//Petla po entach zapisanych do usuniecia
		{
			if(StrEqual(EntityInfo[j][enname], ""))
				continue;
			if(!StrEqual(EntityInfo[j][enclassname], entclsname))
				continue;
			if(!StrEqual(EntityInfo[j][enname], entname))
				continue;
			
			RemoveGivenEnt(i);
		}
	}
}

public Action TimerRemove(Handle timer, any data)
{
	RemoveSavedEntitiesFromMap();
}

public Action TimerRemoveRepeat(Handle timer, any data)
{
	RemoveSavedEntitiesFromMap();
	
	CreateTimer(REMOVE_TIMER_FREQUENCY, TimerRemove, _, TIMER_FLAG_NO_MAPCHANGE);
}

stock void DeleteEntity(const char[] name)
{
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	g_kv.JumpToKey(mapname);
	g_kv.JumpToKey("entities");
	g_kv.JumpToKey(name);
	g_kv.DeleteThis();
	if (!g_kv.GotoFirstSubKey())
		g_kv.DeleteThis();
	g_kv.Rewind();
	g_kv.ExportToFile(DATAFILE);
	
	for(int i = 0; i < MAX_ALLOWED_ENTS; i++)
	{
		if(!StrEqual(EntityInfo[i][enname], name))
			continue;
		
		strcopy(EntityInfo[i][enclassname], 63, "");
		strcopy(EntityInfo[i][enname], 63, "");
		if(i == MAX_REMOVED_ENTS-1)
			MAX_REMOVED_ENTS--;
	}
}

stock void SaveEntityByID(int entity)
{
	char clsname[64], name[64];
	GetEntityClassname(entity, clsname, sizeof(clsname));
	GetEntityName(entity, name, sizeof(name));
	SaveEntity(name, clsname);
}

stock void SaveEntity(const char[] name, const char[] clsname)
{
	if(MAX_REMOVED_ENTS >= MAX_ALLOWED_ENTS)
		return;
	
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	
	g_kv.JumpToKey(mapname, true);
	g_kv.JumpToKey("entities", true);
	g_kv.JumpToKey(name, true);
	g_kv.SetString("class", clsname);
	g_kv.Rewind();
	g_kv.ExportToFile(DATAFILE);
	
	for(int i = 0; i < MAX_ALLOWED_ENTS; i++)
	{
		if(!StrEqual(EntityInfo[i][enname], ""))
			continue;
		
		strcopy(EntityInfo[i][enclassname], 63, clsname);
		strcopy(EntityInfo[i][enname], 63, name);
		if(i == MAX_REMOVED_ENTS)
			MAX_REMOVED_ENTS++;
		break;
	}
}

stock void GetEntityName(int entity, char[] name, int maxlen)
{
	GetEntPropString(entity, Prop_Data, "m_iName", name, maxlen);
}

stock void RemoveGivenEnt(int ent)
{
	//SetEntProp(ent, Prop_Data, "m_CollisionGroup", 5);
	//SetEntProp(ent, Prop_Data, "m_usSolidFlags", 28);
	SetEntityRenderMode(ent, RENDER_NONE);
	SetEntProp(ent, Prop_Data, "m_nSolidType", 0);
	AcceptEntityInput(ent, "Kill");
}

/*
enum Collision_Group_t
{
    COLLISION_GROUP_NONE  = 0,
    COLLISION_GROUP_DEBRIS,            // Collides with nothing but world and static stuff
    COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
    COLLISION_GROUP_INTERACTIVE_DEBRIS,    // Collides with everything except other interactive debris or debris
    COLLISION_GROUP_INTERACTIVE,    // Collides with everything except interactive debris or debris
    COLLISION_GROUP_PLAYER,
    COLLISION_GROUP_BREAKABLE_GLASS,
    COLLISION_GROUP_VEHICLE,
    COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player
                                        
    COLLISION_GROUP_NPC,            // Generic NPC group
    COLLISION_GROUP_IN_VEHICLE,        // for any entity inside a vehicle
    COLLISION_GROUP_WEAPON,            // for any weapons that need collision detection
    COLLISION_GROUP_VEHICLE_CLIP,    // vehicle clip brush to restrict vehicle movement
    COLLISION_GROUP_PROJECTILE,        // Projectiles!
    COLLISION_GROUP_DOOR_BLOCKER,    // Blocks entities not permitted to get near moving doors
    COLLISION_GROUP_PASSABLE_DOOR,    // Doors that the player shouldn't collide with
    COLLISION_GROUP_DISSOLVING,        // Things that are dissolving are in this group
    COLLISION_GROUP_PUSHAWAY,        // Nonsolid on client and server, pushaway in player code

    COLLISION_GROUP_NPC_ACTOR,        // Used so NPCs in scripts ignore the player.

    LAST_SHARED_COLLISION_GROUP
};

enum SolidFlags_t
{
    FSOLID_CUSTOMRAYTEST        = 0x0001,    // Ignore solid type + always call into the entity for ray tests
    FSOLID_CUSTOMBOXTEST        = 0x0002,    // Ignore solid type + always call into the entity for swept box tests
    FSOLID_NOT_SOLID            = 0x0004,    // Are we currently not solid?
    FSOLID_TRIGGER                = 0x0008,    // This is something may be collideable but fires touch functions
                                            // even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
    FSOLID_NOT_STANDABLE        = 0x0010,    // You can't stand on this
    FSOLID_VOLUME_CONTENTS        = 0x0020,    // Contains volumetric contents (like water)
    FSOLID_FORCE_WORLD_ALIGNED    = 0x0040,    // Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
    FSOLID_USE_TRIGGER_BOUNDS    = 0x0080,    // Uses a special trigger bounds separate from the normal OBB
    FSOLID_ROOT_PARENT_ALIGNED    = 0x0100,    // Collisions are defined in root parent's local coordinate space

    FSOLID_MAX_BITS    = 9
};


enum SolidType_t
{
    SOLID_NONE            = 0,    // no solid model
    SOLID_BSP            = 1,    // a BSP tree
    SOLID_BBOX            = 2,    // an AABB
    SOLID_OBB            = 3,    // an OBB (not implemented yet)
    SOLID_OBB_YAW        = 4,    // an OBB, constrained so that it can only yaw
    SOLID_CUSTOM        = 5,    // Always call into the entity for tests
    SOLID_VPHYSICS        = 6,    // solid vphysics object, get vcollide from the model and collide with that
    SOLID_LAST,
};
*/

