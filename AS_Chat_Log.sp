#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define SIZE_TAGTYPE    16
#define LOG_DIR_PATH    "logs/ChatLogAS"
#define LOG_PREFIX      "av_say"
#define VIP_OVERRIDE    "ws_vip"


enum struct SayType {
    char say[SIZE_TAGTYPE];
    char say_team[SIZE_TAGTYPE];
    char say_vip[SIZE_TAGTYPE];
    char sm_say[SIZE_TAGTYPE];
    char sm_chat[SIZE_TAGTYPE];
    char sm_csay[SIZE_TAGTYPE];
    char sm_tsay[SIZE_TAGTYPE];
    char sm_msay[SIZE_TAGTYPE];
    char sm_hsay[SIZE_TAGTYPE];
    char sm_psay[SIZE_TAGTYPE];
}

SayType TagType;

char filelog_basic[PLATFORM_MAX_PATH];
char filelog[PLATFORM_MAX_PATH];

public Plugin myinfo = {
    name = "[CS:GO] AS Chat Log",
    author = "Avgariat",
    description = "Chat Logger",
    version = "0.3",
    url = "https://arenaskilla.pl"
};

public void OnPluginStart() {
    LoadTranslations("common.phrases.txt");
    
    AddCommandListener(CommandsHook_sm, "sm_say");
    AddCommandListener(CommandsHook_sm, "sm_chat");
    AddCommandListener(CommandsHook_sm, "sm_csay");
    AddCommandListener(CommandsHook_sm, "sm_tsay");
    AddCommandListener(CommandsHook_sm, "sm_msay");
    AddCommandListener(CommandsHook_sm, "sm_hsay");
    AddCommandListener(CommandsHook_sm, "sm_psay");
    
    FormatEx(TagType.say, sizeof(TagType.say), "Chat        ");
    FormatEx(TagType.say_team, sizeof(TagType.say_team), "Team_Chat   ");
    FormatEx(TagType.say_vip, sizeof(TagType.say_vip), "Vip_Chat    ");
    FormatEx(TagType.sm_say, sizeof(TagType.sm_say), "All_Chat    ");
    FormatEx(TagType.sm_chat, sizeof(TagType.sm_chat), "Admin_Chat  ");
    FormatEx(TagType.sm_csay, sizeof(TagType.sm_csay), "Center_Chat ");
    FormatEx(TagType.sm_tsay, sizeof(TagType.sm_tsay), "Corner_Chat ");
    FormatEx(TagType.sm_msay, sizeof(TagType.sm_msay), "Panel_Chat  ");
    FormatEx(TagType.sm_hsay, sizeof(TagType.sm_hsay), "Hint_Chat   ");
    FormatEx(TagType.sm_psay, sizeof(TagType.sm_psay), "Private_Chat");
    
    setLogPath();
    CreateTimer(60.0, TimerDataChecker, _, TIMER_REPEAT);
}

public void SaveLogMessage(int client, const char[] type, const char[] message) {
    if (client < 1) {
        LogToFileEx(filelog, "%s | (STEAM_0:0:000000000)CONSOLE: %s", type, message);
        return;
    }
    
    if (!IsValidClient(client)) return;
    
    char authId[64];
    GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId));

    if (strlen(authId) < 19) Format(authId, sizeof(authId), "(%s) ", authId);
    else Format(authId, sizeof(authId), "(%s)", authId);

    LogToFileEx(filelog, "%s | %s%N: %s", type, authId, client, message);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
    int startpos = 0;
    char type[SIZE_TAGTYPE];

    //char type[64] = "Chat        ";
    strcopy(type, sizeof(type), TagType.say);

    if (sArgs[startpos] != '@') {
        if (!StrEqual("say_team", command) || sArgs[startpos] != '*') {
            SaveLogMessage(client, type, sArgs);
            return Plugin_Continue;
        }
        else if (!CheckCommandAccess(client, VIP_OVERRIDE, ADMFLAG_CUSTOM1)) {
            SaveLogMessage(client, type, sArgs);
            return Plugin_Continue;
        }
        else {
            startpos++;

            //type = "Vip_Chat    ";
            strcopy(type, sizeof(type), TagType.say_vip);

            SaveLogMessage(client, type, sArgs[startpos]);
            return Plugin_Continue;
        }
    }

    startpos++;
    
    if (StrEqual("say", command)) {
        // sm_say @
        if (sArgs[startpos] != '@') {
            if (!CheckCommandAccess(client, "sm_say", ADMFLAG_CHAT)) {
                SaveLogMessage(client, type, sArgs);
                return Plugin_Continue;
            }
            
            //type = "All_Chat    ";
            strcopy(type, sizeof(type), TagType.sm_say);

            SaveLogMessage(client, type, sArgs[startpos]);
            return Plugin_Continue;
        }

        startpos++;
        
        // sm_psay @@
        if (sArgs[startpos] != '@') {
            if (!CheckCommandAccess(client, "sm_psay", ADMFLAG_CHAT)) {
                SaveLogMessage(client, type, sArgs);
                return Plugin_Continue;
            }
            
            char arg[64];
            int len = BreakString(sArgs[startpos], arg, sizeof(arg));
            int target = FindTarget(client, arg, true, false);
            
            if (target == -1 || len == -1) {
                SaveLogMessage(client, type, sArgs);
                return Plugin_Continue;
            }
            
            char AlteredMessage[256];
            Format(AlteredMessage, sizeof(AlteredMessage), "(To %N) %s", target, sArgs[startpos+len]);

            //type = "Private_Chat";
            strcopy(type, sizeof(type), TagType.sm_psay);
            
            SaveLogMessage(client, type, AlteredMessage);
            return Plugin_Continue;
        }
        startpos++;
        
        //sm_csay @@@
        if (!CheckCommandAccess(client, "sm_csay", ADMFLAG_CHAT)) {
            SaveLogMessage(client, type, sArgs);
            return Plugin_Continue;
        }
        
        //type = "Center_Chat ";
        strcopy(type, sizeof(type), TagType.sm_csay);

        SaveLogMessage(client, type, sArgs[startpos]);
        return Plugin_Continue;
    }
    else if (StrEqual("say_team", command)) {
        //sm_chat u@, say_team @
        if (!CheckCommandAccess(client, "sm_chat", ADMFLAG_CHAT)) {
            //type = "Team_Chat   ";
            strcopy(type, sizeof(type), TagType.say_team);

            SaveLogMessage(client, type, sArgs);
            return Plugin_Continue;
        }
        
        //type = "Admin_Chat  ";
        strcopy(type, sizeof(type), TagType.sm_chat);

        SaveLogMessage(client, type, sArgs[startpos]);
        return Plugin_Continue;
    }
    
    return Plugin_Continue;
}

public Action CommandsHook_sm(int client, const char[] command, int args) {
    char message[256];
    GetCmdArgString(message, sizeof(message));
    //char type[64];
    char type[SIZE_TAGTYPE];
    
    if (StrEqual("sm_say", command)) {
        //type = "All_Chat    ";
        strcopy(type, sizeof(type), TagType.sm_say);
    }
    else if (StrEqual("sm_chat", command)) {
        //type = "Admin_Chat  ";
        strcopy(type, sizeof(type), TagType.sm_chat);
    }
    else if (StrEqual("sm_csay", command)) {
        //type = "Center_Chat ";
        strcopy(type, sizeof(type), TagType.sm_csay);
    }
    else if (StrEqual("sm_tsay", command)) {
        //type = "Corner_Chat ";
        strcopy(type, sizeof(type), TagType.sm_tsay);
    }
    else if (StrEqual("sm_msay", command)) {
        //type = "Panel_Chat  ";
        strcopy(type, sizeof(type), TagType.sm_msay);
    }
    else if (StrEqual("sm_hsay", command)) {
        //type = "Hint_Chat   ";
        strcopy(type, sizeof(type), TagType.sm_hsay);
    }
    else if (StrEqual("sm_psay", command)) {
        //type = "Private_Chat";
        strcopy(type, sizeof(type), TagType.sm_psay);
    }
    else return;

    SaveLogMessage(client, type, message);
}

public Action TimerDataChecker(Handle timer) {
    setLogDateSuffix();
}

void setLogDateSuffix() {
    char date[16];
    FormatTime(date, sizeof(date), "%Y-%m-%d", GetTime());
    Format(filelog, sizeof(filelog), "%s/%s_%s.log", filelog_basic, LOG_PREFIX, date);

    if (!FileExists(filelog)) {
        LogToFileEx(
            filelog,
            "\n///* This file has been generated by \"[CS:GO] AS Chat Log\" plugin \
            which has been created for game servers of ArenaSkilla.pl. *///\n///* \
            Author: Avgariat *///\n"
        );
    }
}

void setLogPath() {
    BuildPath(Path_SM, filelog_basic, sizeof(filelog_basic), LOG_DIR_PATH);

    CreateDirectory(filelog_basic, 488);
    if (!DirExists(filelog_basic)) {
        SetFailState("Failed to create directory at %s - Please, create it manually.", filelog_basic);
    }

    setLogDateSuffix();
}

stock bool IsValidClient(int client, bool isAlive = false) {
    if (client < 1 || client > MaxClients) return false;
    if (!IsClientInGame(client) || IsFakeClient(client)) return false;
    if (isAlive && !IsPlayerAlive(client)) return false;
    return true;
}