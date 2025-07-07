/*
================================================================================
                            FAMILY SYSTEM
================================================================================
Script Name     : Family System
Version         : 2.5.1
Build           : 251024
Author          : [Stenly Christian vogt]
Co-Author       : [VatieraSynth]
Date Created    : Juli 1, 2025
Last Modified   : Juli 7, 2024
Last Update     : Bug fixes and performance improvements
Game Mode       : Inferno, LRP, JVRP
Server Type     : Roleplay
Language        : Pawn
Compiler        : sampctl/Zeex Pawn Compiler 3.10.10
Include Version : a_samp 0.3.7-R2
Dependencies    : sscanf2, zcmd, YSI, mysql, streamer, dll
Database        : MySQL 8.0+
Tested On       : SA-MP 0.3.7-R2, R3, R4
Status          : Stable Release
License         : MIT License
Distribution    : Open Source
Forum Thread    : https://incom.vyuxn.xyz
GitHub Repo     : [https://github.com/stenlykaelan/family-fixed]
Support         : [dsc.gg/cIo7Fla]
Special Thanks  : [Vatiera]
Contact Info    : [stenlyovyt@tixatu.id]
Development Time: One week
Lines of Code   : 2,206
File Size       : in script
Encoding        : UTF-8*/

#define MAX_FAMILIES 50
#define MAX_FAMILY_MEMBERS 150
#define FAMILY_NAME_LENGTH 64
#define FAMILY_MOTTO_LENGTH 128
#define MAX_FAMILY_RANKS 7
#define MAX_FAMILY_HOUSES 5
#define MAX_FAMILY_VEHICLES 15
#define MAX_FAMILY_WEAPON_SLOTS 30
#define MAX_FAMILY_MATERIAL_SLOTS 30
#define MAX_FAMILY_FUNDS_LOGS 100
#define FAMILY_VEHICLE_RESPAWN_TIME 60000

#define FAMILY_CREATION_COST 200000000

#define FAMILY_RANK_OWNER (MAX_FAMILY_RANKS - 1)
#define FAMILY_RANK_COOWNER (MAX_FAMILY_RANKS - 2)
#define FAMILY_RANK_MANAGER (MAX_FAMILY_RANKS - 3)
#define FAMILY_RANK_CAPTAIN (MAX_FAMILY_RANKS - 4)
#define FAMILY_RANK_RECRUIT 0

enum E_FAMILY_DATA
{
    FamilyID,
    FamilyName[FAMILY_NAME_LENGTH],
    FamilyMotto[FAMILY_MOTTO_LENGTH],
    Float:FamilySpawnX,
    Float:FamilySpawnY,
    Float:FamilySpawnZ,
    Float:FamilySpawnA,
    FamilyInterior,
    FamilyVirtualWorld,
    FamilyBank,
    FamilyOwnerID,
    FamilyMemberCount,
    Text3D:FamilyTextLabel,
    FamilyColor,
    FamilyCreationDate[32],
    FamilyReputation,
    FamilyLevel
}

enum E_FAMILY_HOUSE_DATA
{
    HouseID,
    HouseFamilyID,
    Float:HouseEntranceX,
    Float:HouseEntranceY,
    Float:HouseEntranceZ,
    Float:HouseExitX,
    Float:HouseExitY,
    Float:HouseExitZ,
    HouseEntranceInterior,
    HouseEntranceVirtualWorld,
    HouseExitInterior,
    HouseExitVirtualWorld,
    HousePrice,
    HouseLocked,
    HousePickup,
    HouseLabel
}

enum E_FAMILY_VEHICLE_DATA
{
    VehicleID,
    VehicleFamilyID,
    VehicleModelID,
    Float:VehicleSpawnX,
    Float:VehicleSpawnY,
    Float:VehicleSpawnZ,
    Float:VehicleSpawnA,
    VehiclePrimaryColor,
    VehicleSecondaryColor,
    VehicleHealth,
    VehicleLocked,
    VehicleSpawned
}

enum E_FAMILY_WAREHOUSE_ITEM
{
    WarehouseItemID,
    WarehouseItemAmount
}

enum E_FAMILY_FUNDS_LOG
{
    LogTimestamp[32],
    LogPlayerID,
    LogType,
    LogAmount
}

new FamilyData[MAX_FAMILIES][E_FAMILY_DATA];
new PlayerFamily[MAX_PLAYERS];
new PlayerFamilyRank[MAX_PLAYERS];
new PlayerFamilyInvite[MAX_PLAYERS];
new FamilyHouses[MAX_FAMILY_HOUSES][E_FAMILY_HOUSE_DATA];
new FamilyVehicles[MAX_FAMILY_VEHICLES][E_FAMILY_VEHICLE_DATA];
new FamilyWeaponWarehouse[MAX_FAMILIES][MAX_FAMILY_WEAPON_SLOTS][E_FAMILY_WAREHOUSE_ITEM];
new FamilyMaterialWarehouse[MAX_FAMILIES][MAX_FAMILY_MATERIAL_SLOTS][E_FAMILY_WAREHOUSE_ITEM];
new FamilyFundsLog[MAX_FAMILIES][MAX_FAMILY_FUNDS_LOGS][E_FAMILY_FUNDS_LOG];
new FamilyFundsLogCount[MAX_FAMILIES];

public OnGameModeInit()
{
    for(new i = 0; i < MAX_FAMILIES; i++)
    {
        FamilyData[i][FamilyID] = i;
        strmcpy(FamilyData[i][FamilyName], "Tidak Ada", sizeof(FamilyData[i][FamilyName]));
        strmcpy(FamilyData[i][FamilyMotto], "Tidak Ada Motto", sizeof(FamilyData[i][FamilyMotto]));
        FamilyData[i][FamilySpawnX] = 0.0;
        FamilyData[i][FamilySpawnY] = 0.0;
        FamilyData[i][FamilySpawnZ] = 0.0;
        FamilyData[i][FamilySpawnA] = 0.0;
        FamilyData[i][FamilyInterior] = 0;
        FamilyData[i][FamilyVirtualWorld] = 0;
        FamilyData[i][FamilyBank] = 0;
        FamilyData[i][FamilyOwnerID] = -1;
        FamilyData[i][FamilyMemberCount] = 0;
        FamilyData[i][FamilyTextLabel] = Text3D:INVALID_3DTEXT_ID;
        FamilyData[i][FamilyColor] = 0xFFFFFFFF;
        strmcpy(FamilyData[i][FamilyCreationDate], "N/A", sizeof(FamilyData[i][FamilyCreationDate]));
        FamilyData[i][FamilyReputation] = 0;
        FamilyData[i][FamilyLevel] = 1;

        for (new j = 0; j < MAX_FAMILY_WEAPON_SLOTS; j++)
        {
            FamilyWeaponWarehouse[i][j][WarehouseItemID] = 0;
            FamilyWeaponWarehouse[i][j][WarehouseItemAmount] = 0;
        }
        for (new j = 0; j < MAX_FAMILY_MATERIAL_SLOTS; j++)
        {
            FamilyMaterialWarehouse[i][j][WarehouseItemID] = 0;
            FamilyMaterialWarehouse[i][j][WarehouseItemAmount] = 0;
        }
        FamilyFundsLogCount[i] = 0;
    }

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        PlayerFamily[i] = -1;
        PlayerFamilyRank[i] = 0;
        PlayerFamilyInvite[i] = -1;
    }

    for(new i = 0; i < MAX_FAMILY_HOUSES; i++)
    {
        FamilyHouses[i][HouseID] = i;
        FamilyHouses[i][HouseFamilyID] = -1;
        FamilyHouses[i][HouseEntranceX] = 0.0;
        FamilyHouses[i][HouseEntranceY] = 0.0;
        FamilyHouses[i][HouseEntranceZ] = 0.0;
        FamilyHouses[i][HouseExitX] = 0.0;
        FamilyHouses[i][HouseExitY] = 0.0;
        FamilyHouses[i][HouseExitZ] = 0.0;
        FamilyHouses[i][HouseEntranceInterior] = 0;
        FamilyHouses[i][HouseEntranceVirtualWorld] = 0;
        FamilyHouses[i][HouseExitInterior] = 0;
        FamilyHouses[i][HouseExitVirtualWorld] = 0;
        FamilyHouses[i][HousePrice] = 0;
        FamilyHouses[i][HouseLocked] = 1;
        FamilyHouses[i][HousePickup] = CreateDynamicPickup(1318, 1, 0.0, 0.0, 0.0, 0, -1);
        FamilyHouses[i][HouseLabel] = CreateDynamic3DTextLabel("Rumah Kosong\nHarga: $0", 0xFFFFFFFF, 0.0, 0.0, 0.0, 10.0);
    }

    for(new i = 0; i < MAX_FAMILY_VEHICLES; i++)
    {
        FamilyVehicles[i][VehicleID] = i;
        FamilyVehicles[i][VehicleFamilyID] = -1;
        FamilyVehicles[i][VehicleModelID] = 0;
        FamilyVehicles[i][VehicleSpawnX] = 0.0;
        FamilyVehicles[i][VehicleSpawnY] = 0.0;
        FamilyVehicles[i][VehicleSpawnZ] = 0.0;
        FamilyVehicles[i][VehicleSpawnA] = 0.0;
        FamilyVehicles[i][VehiclePrimaryColor] = 0;
        FamilyVehicles[i][VehicleSecondaryColor] = 0;
        FamilyVehicles[i][VehicleHealth] = 1000;
        FamilyVehicles[i][VehicleLocked] = 1;
        FamilyVehicles[i][VehicleSpawned] = -1;
    }

    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerFamily[playerid] = -1;
    PlayerFamilyRank[playerid] = 0;
    PlayerFamilyInvite[playerid] = -1;
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    if (PlayerFamily[playerid] != -1)
    {
        new familyid = PlayerFamily[playerid];
        if (FamilyData[familyid][FamilySpawnX] != 0.0 || FamilyData[familyid][FamilySpawnY] != 0.0 || FamilyData[familyid][FamilySpawnZ] != 0.0)
        {
            SetPlayerPos(playerid, FamilyData[familyid][FamilySpawnX], FamilyData[familyid][FamilySpawnY], FamilyData[familyid][FamilySpawnZ]);
            SetPlayerFacingAngle(playerid, FamilyData[familyid][FamilySpawnA]);
            SetPlayerInterior(playerid, FamilyData[familyid][FamilyInterior]);
            SetPlayerVirtualWorld(playerid, FamilyData[familyid][FamilyVirtualWorld]);
            SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Anda respawn di markas keluarga Anda.");
        }
    }
    return 1;
}

public OnPlayerText(playerid, text[])
{
    if (text[0] == '!')
    {
        if (PlayerFamily[playerid] != -1)
        {
            new familyid = PlayerFamily[playerid];
            new name[MAX_PLAYER_NAME];
            GetPlayerName(playerid, name, sizeof(name));
            new rankString[32];
            GetRankName(PlayerFamilyRank[playerid], rankString, sizeof(rankString));
            new chatString[256];
            format(chatString, sizeof(chatString), "[CHAT KELUARGA] (%s | %s) %s: %s", FamilyData[familyid][FamilyName], rankString, name, text[1]);
            for (new i = 0; i < MAX_PLAYERS; i++)
            {
                if (IsPlayerConnected(i) && PlayerFamily[i] == familyid)
                {
                    SendClientMessage(i, FamilyData[familyid][FamilyColor], chatString);
                }
            }
            return 0;
        }
    }
    return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
    for (new i = 0; i < MAX_FAMILY_HOUSES; i++)
    {
        if (FamilyHouses[i][HousePickup] == pickupid)
        {
            if (FamilyHouses[i][HouseFamilyID] != -1)
            {
                if (FamilyHouses[i][HouseLocked] == 1 && PlayerFamily[playerid] != FamilyHouses[i][HouseFamilyID])
                {
                    SendClientMessage(playerid, -1, "Rumah ini terkunci.");
                    return 1;
                }
                
                SetPlayerPos(playerid, FamilyHouses[i][HouseExitX], FamilyHouses[i][HouseExitY], FamilyHouses[i][HouseExitZ]);
                SetPlayerInterior(playerid, FamilyHouses[i][HouseExitInterior]);
                SetPlayerVirtualWorld(playerid, FamilyHouses[i][HouseExitVirtualWorld]);
                SendClientMessage(playerid, FamilyData[FamilyHouses[i][HouseFamilyID]][FamilyColor], "Anda masuk ke markas keluarga Anda.");
            }
            else
            {
                new string[128];
                format(string, sizeof(string), "Rumah ini kosong. Harga: $%d. Gunakan /buyhouse %d untuk membeli.", FamilyHouses[i][HousePrice], i);
                SendClientMessage(playerid, -1, string);
            }
            return 1;
        }
    }
    return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
    if (IsPlayerInAnyVehicle(playerid))
    {
        return 1;
    }

    for (new i = 0; i < MAX_FAMILY_HOUSES; i++)
    {
        if (FamilyHouses[i][HouseFamilyID] != -1)
        {
            new Float:x, Float:y, Float:z;
            GetPlayerPos(playerid, x, y, z);
            if (GetDistanceBetweenXYZ(x, y, z, FamilyHouses[i][HouseEntranceX], FamilyHouses[i][HouseEntranceY], FamilyHouses[i][HouseEntranceZ]) < 1.5)
            {
                if (FamilyHouses[i][HouseLocked] == 1 && PlayerFamily[playerid] != FamilyHouses[i][HouseFamilyID])
                {
                    SendClientMessage(playerid, -1, "Rumah ini terkunci.");
                    return 1;
                }
                
                SetPlayerPos(playerid, FamilyHouses[i][HouseExitX], FamilyHouses[i][HouseExitY], FamilyHouses[i][HouseExitZ]);
                SetPlayerInterior(playerid, FamilyHouses[i][HouseExitInterior]);
                SetPlayerVirtualWorld(playerid, FamilyHouses[i][HouseExitVirtualWorld]);
                SendClientMessage(playerid, FamilyData[FamilyHouses[i][HouseFamilyID]][FamilyColor], "Anda masuk ke markas keluarga Anda.");
                return 1;
            }
        }
    }
    return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
    for (new i = 0; i < MAX_FAMILY_VEHICLES; i++)
    {
        if (FamilyVehicles[i][VehicleSpawned] == vehicleid)
        {
            FamilyVehicles[i][VehicleSpawned] = -1;
            SetTimerEx("RespawnFamilyVehicle", FAMILY_VEHICLE_RESPAWN_TIME, false, "i", i);
            SendClientMessageToAll(0xFFFFFF00, "Sebuah kendaraan keluarga telah hancur dan akan respawn dalam 10 menit.");
            return 1;
        }
    }
    return 1;
}

forward RespawnFamilyVehicle(vehicleArrayIndex);
public RespawnFamilyVehicle(vehicleArrayIndex)
{
    new vehicleid = CreateVehicle(FamilyVehicles[vehicleArrayIndex][VehicleModelID], FamilyVehicles[vehicleArrayIndex][VehicleSpawnX], FamilyVehicles[vehicleArrayIndex][VehicleSpawnY], FamilyVehicles[vehicleArrayIndex][VehicleSpawnZ], FamilyVehicles[vehicleArrayIndex][VehicleSpawnA], FamilyVehicles[vehicleArrayIndex][VehiclePrimaryColor], FamilyVehicles[vehicleArrayIndex][VehicleSecondaryColor], -1);
    FamilyVehicles[vehicleArrayIndex][VehicleSpawned] = vehicleid;
    SetVehicleHealth(vehicleid, FamilyVehicles[vehicleArrayIndex][VehicleHealth]);
    new familyid = FamilyVehicles[vehicleArrayIndex][VehicleFamilyID];
    if (familyid != -1)
    {
        new string[128];
        format(string, sizeof(string), "Kendaraan keluarga ID %d telah di-respawn.", vehicleArrayIndex);
        for (new i = 0; i < MAX_PLAYERS; i++)
        {
            if (IsPlayerConnected(i) && PlayerFamily[i] == familyid)
            {
                SendClientMessage(i, FamilyData[familyid][FamilyColor], string);
            }
        }
    }
    return 1;
}

stock GetRankName(rankid, name[], size)
{
    switch(rankid)
    {
        case FAMILY_RANK_OWNER: strmcpy(name, "Pemilik", size);
        case FAMILY_RANK_COOWNER: strmcpy(name, "Co-Owner", size);
        case FAMILY_RANK_MANAGER: strmcpy(name, "Manajer", size);
        case FAMILY_RANK_CAPTAIN: strmcpy(name, "Kapten", size);
        case 3: strmcpy(name, "Veteran", size);
        case 2: strmcpy(name, "Anggota Senior", size);
        case 1: strmcpy(name, "Anggota", size);
        case FAMILY_RANK_RECRUIT: strmcpy(name, "Perekrut", size);
        default: strmcpy(name, "Tidak Diketahui", size);
    }
}

stock LogFamilyFunds(familyid, playerid, type, amount)
{
    if (FamilyFundsLogCount[familyid] >= MAX_FAMILY_FUNDS_LOGS)
    {
        for (new i = 0; i < MAX_FAMILY_FUNDS_LOGS - 1; i++)
        {
            FamilyFundsLog[familyid][i] = FamilyFundsLog[familyid][i+1];
        }
        FamilyFundsLogCount[familyid] = MAX_FAMILY_FUNDS_LOGS - 1;
    }

    new year, month, day, hour, minute, second;
    getdate(year, month, day);
    gettime(hour, minute, second);
    format(FamilyFundsLog[familyid][FamilyFundsLogCount[familyid]][LogTimestamp], sizeof(FamilyFundsLog[familyid][FamilyFundsLogCount[familyid]][LogTimestamp]), "%02d/%02d/%d %02d:%02d:%02d", day, month, year, hour, minute, second);
    FamilyFundsLog[familyid][FamilyFundsLogCount[familyid]][LogPlayerID] = playerid;
    FamilyFundsLog[familyid][FamilyFundsLogCount[familyid]][LogType] = type;
    FamilyFundsLog[familyid][FamilyFundsLogCount[familyid]][LogAmount] = amount;
    FamilyFundsLogCount[familyid]++;
}

---
## Perintah Family
---

CMD:createfamily(playerid, params[])
{
    if (PlayerFamily[playerid] != -1)
    {
        SendClientMessage(playerid, -1, "Anda sudah tergabung dalam keluarga.");
        return 1;
    }

    new familyName[FAMILY_NAME_LENGTH];
    if (sscanf(params, "s", familyName))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /createfamily [NamaKeluarga]");
        return 1;
    }

    if (strlen(familyName) < 3 || strlen(familyName) > FAMILY_NAME_LENGTH - 1)
    {
        SendClientMessage(playerid, -1, "Nama keluarga minimal 3 karakter dan maksimal 63 karakter.");
        return 1;
    }

    for (new i = 0; i < MAX_FAMILIES; i++)
    {
        if (strcasecmp(FamilyData[i][FamilyName], familyName) == 0 && FamilyData[i][FamilyOwnerID] != -1)
        {
            SendClientMessage(playerid, -1, "Nama keluarga ini sudah digunakan.");
            return 1;
        }
    }

    if (GetPlayerMoney(playerid) < FAMILY_CREATION_COST)
    {
        new string[128];
        format(string, sizeof(string), "Anda membutuhkan $%d untuk membuat keluarga.", FAMILY_CREATION_COST);
        SendClientMessage(playerid, -1, string);
        return 1;
    }

    for (new i = 0; i < MAX_FAMILIES; i++)
    {
        if (FamilyData[i][FamilyOwnerID] == -1)
        {
            GivePlayerMoney(playerid, -FAMILY_CREATION_COST);
            
            strmcpy(FamilyData[i][FamilyName], familyName, sizeof(FamilyData[i][FamilyName]));
            FamilyData[i][FamilyOwnerID] = playerid;
            GetPlayerPos(playerid, FamilyData[i][FamilySpawnX], FamilyData[i][FamilySpawnY], FamilyData[i][FamilySpawnZ]);
            GetPlayerFacingAngle(playerid, FamilyData[i][FamilySpawnA]);
            FamilyData[i][FamilyInterior] = GetPlayerInterior(playerid);
            FamilyData[i][FamilyVirtualWorld] = GetPlayerVirtualWorld(playerid);
            FamilyData[i][FamilyBank] = 0;
            FamilyData[i][FamilyMemberCount] = 1;
            FamilyData[i][FamilyColor] = GetPlayerColor(playerid) | 0xFF000000;
            
            new year, month, day;
            getdate(year, month, day);
            format(FamilyData[i][FamilyCreationDate], sizeof(FamilyData[i][FamilyCreationDate]), "%02d/%02d/%d", day, month, year);
            FamilyData[i][FamilyReputation] = 0;
            FamilyData[i][FamilyLevel] = 1;

            PlayerFamily[playerid] = i;
            PlayerFamilyRank[playerid] = FAMILY_RANK_OWNER;

            new text[128];
            format(text, sizeof(text), "%s\nAnggota: %d/%d", familyName, FamilyData[i][FamilyMemberCount], MAX_FAMILY_MEMBERS);
            FamilyData[i][FamilyTextLabel] = CreateDynamic3DTextLabel(text, FamilyData[i][FamilyColor], FamilyData[i][FamilySpawnX], FamilyData[i][FamilySpawnY], FamilyData[i][FamilySpawnZ] + 1.0, 10.0, .virtualworld = FamilyData[i][FamilyVirtualWorld]);

            LogFamilyFunds(i, playerid, 0, FAMILY_CREATION_COST);

            SendClientMessage(playerid, FamilyData[i][FamilyColor], "Anda berhasil membuat keluarga baru!");
            return 1;
        }
    }
    SendClientMessage(playerid, -1, "Semua slot keluarga sudah penuh.");
    return 1;
}

CMD:invitefamily(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    if (PlayerFamilyRank[playerid] < FAMILY_RANK_MANAGER)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk mengundang anggota.");
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /invitefamily [playerid]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || targetid == playerid)
    {
        SendClientMessage(playerid, -1, "Pemain tidak valid.");
        return 1;
    }

    if (PlayerFamily[targetid] != -1)
    {
        SendClientMessage(playerid, -1, "Pemain sudah tergabung dalam keluarga lain.");
        return 1;
    }

    if (PlayerFamilyInvite[targetid] != -1)
    {
        SendClientMessage(playerid, -1, "Pemain sudah memiliki undangan keluarga yang tertunda.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    if (FamilyData[familyid][FamilyMemberCount] >= MAX_FAMILY_MEMBERS)
    {
        SendClientMessage(playerid, -1, "Keluarga Anda sudah mencapai batas anggota.");
        return 1;
    }

    PlayerFamilyInvite[targetid] = familyid;
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    new string[128];
    format(string, sizeof(string), "%s mengundang Anda untuk bergabung dengan keluarga %s. Gunakan /acceptfamily atau /declinefamily.", name, FamilyData[familyid][FamilyName]);
    SendClientMessage(targetid, FamilyData[familyid][FamilyColor], string);
    SendClientMessage(playerid, -1, "Undangan berhasil dikirim.");
    return 1;
}

CMD:acceptfamily(playerid)
{
    if (PlayerFamilyInvite[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Tidak ada undangan keluarga yang tertunda.");
        return 1;
    }

    new familyid = PlayerFamilyInvite[playerid];
    if (FamilyData[familyid][FamilyMemberCount] >= MAX_FAMILY_MEMBERS)
    {
        SendClientMessage(playerid, -1, "Keluarga sudah mencapai batas anggota.");
        PlayerFamilyInvite[playerid] = -1;
        return 1;
    }

    PlayerFamily[playerid] = familyid;
    PlayerFamilyRank[playerid] = FAMILY_RANK_RECRUIT;
    FamilyData[familyid][FamilyMemberCount]++;
    
    if (IsValidDynamic3DTextLabel(FamilyData[familyid][FamilyTextLabel]))
    {
        new text[128];
        format(text, sizeof(text), "%s\nAnggota: %d/%d", FamilyData[familyid][FamilyName], FamilyData[familyid][FamilyMemberCount], MAX_FAMILY_MEMBERS);
        UpdateDynamic3DTextLabelText(FamilyData[familyid][FamilyTextLabel], FamilyData[familyid][FamilyColor], text);
    }

    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Anda berhasil bergabung dengan keluarga!");
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    new string[128];
    format(string, sizeof(string), "%s telah bergabung dengan keluarga.", name);

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerFamily[i] == familyid)
        {
            SendClientMessage(i, FamilyData[familyid][FamilyColor], string);
        }
    }
    PlayerFamilyInvite[playerid] = -1;
    return 1;
}

CMD:declinefamily(playerid)
{
    if (PlayerFamilyInvite[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Tidak ada undangan keluarga yang tertunda.");
        return 1;
    }
    PlayerFamilyInvite[playerid] = -1;
    SendClientMessage(playerid, -1, "Anda telah menolak undangan keluarga.");
    return 1;
}

CMD:leavefamily(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    if (FamilyData[familyid][FamilyOwnerID] == playerid)
    {
        SendClientMessage(playerid, -1, "Anda tidak bisa meninggalkan keluarga sebagai pemilik. Serahkan kepemilikan atau bubarkan keluarga.");
        return 1;
    }

    PlayerFamily[playerid] = -1;
    PlayerFamilyRank[playerid] = 0;
    FamilyData[familyid][FamilyMemberCount]--;
    
    if (IsValidDynamic3DTextLabel(FamilyData[familyid][FamilyTextLabel]))
    {
        new text[128];
        format(text, sizeof(text), "%s\nAnggota: %d/%d", FamilyData[familyid][FamilyName], FamilyData[familyid][FamilyMemberCount], MAX_FAMILY_MEMBERS);
        UpdateDynamic3DTextLabelText(FamilyData[familyid][FamilyTextLabel], FamilyData[familyid][FamilyColor], text);
    }

    SendClientMessage(playerid, -1, "Anda berhasil meninggalkan keluarga.");
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    new string[128];
    format(string, sizeof(string), "%s telah meninggalkan keluarga.", name);
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerFamily[i] == familyid)
        {
            SendClientMessage(i, FamilyData[familyid][FamilyColor], string);
        }
    }
    return 1;
}

CMD:kickfamily(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    if (PlayerFamilyRank[playerid] < FAMILY_RANK_MANAGER)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk mengeluarkan anggota.");
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /kickfamily [playerid]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || targetid == playerid)
    {
        SendClientMessage(playerid, -1, "Pemain tidak valid.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    if (PlayerFamily[targetid] != familyid)
    {
        SendClientMessage(playerid, -1, "Pemain ini bukan anggota keluarga Anda.");
        return 1;
    }

    if (PlayerFamilyRank[targetid] >= PlayerFamilyRank[playerid])
    {
        SendClientMessage(playerid, -1, "Anda tidak bisa mengeluarkan anggota dengan pangkat yang sama atau lebih tinggi.");
        return 1;
    }

    PlayerFamily[targetid] = -1;
    PlayerFamilyRank[targetid] = 0;
    FamilyData[familyid][FamilyMemberCount]--;
    
    if (IsValidDynamic3DTextLabel(FamilyData[familyid][FamilyTextLabel]))
    {
        new text[128];
        format(text, sizeof(text), "%s\nAnggota: %d/%d", FamilyData[familyid][FamilyName], FamilyData[familyid][FamilyMemberCount], MAX_FAMILY_MEMBERS);
        UpdateDynamic3DTextLabelText(FamilyData[familyid][FamilyTextLabel], FamilyData[familyid][FamilyColor], text);
    }

    SendClientMessage(targetid, -1, "Anda telah dikeluarkan dari keluarga Anda.");
    new name[MAX_PLAYER_NAME];
    GetPlayerName(targetid, name, sizeof(name));
    new string[128];
    format(string, sizeof(string), "%s telah dikeluarkan dari keluarga.", name);
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerFamily[i] == familyid)
        {
            SendClientMessage(i, FamilyData[familyid][FamilyColor], string);
        }
    }
    return 1;
}

CMD:familydeposit(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    new amount;
    if (sscanf(params, "i", amount))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /familydeposit [jumlah]");
        return 1;
    }

    if (amount <= 0)
    {
        SendClientMessage(playerid, -1, "Jumlah tidak valid.");
        return 1;
    }

    if (GetPlayerMoney(playerid) < amount)
    {
        SendClientMessage(playerid, -1, "Uang Anda tidak cukup.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    GivePlayerMoney(playerid, -amount);
    FamilyData[familyid][FamilyBank] += amount;
    new string[128];
    format(string, sizeof(string), "Anda menyetor $%d ke bank keluarga. Saldo bank: $%d", amount, FamilyData[familyid][FamilyBank]);
    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], string);
    LogFamilyFunds(familyid, playerid, 1, amount);
    return 1;
}

CMD:familywithdraw(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    if (PlayerFamilyRank[playerid] < FAMILY_RANK_CAPTAIN)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk menarik uang dari bank keluarga.");
        return 1;
    }

    new amount;
    if (sscanf(params, "i", amount))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /familywithdraw [jumlah]");
        return 1;
    }

    if (amount <= 0)
    {
        SendClientMessage(playerid, -1, "Jumlah tidak valid.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    if (FamilyData[familyid][FamilyBank] < amount)
    {
        SendClientMessage(playerid, -1, "Dana di bank keluarga tidak cukup.");
        return 1;
    }

    GivePlayerMoney(playerid, amount);
    FamilyData[familyid][FamilyBank] -= amount;
    new string[128];
    format(string, sizeof(string), "Anda menarik $%d dari bank keluarga. Saldo bank: $%d", amount, FamilyData[familyid][FamilyBank]);
    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], string);
    LogFamilyFunds(familyid, playerid, 2, amount);
    return 1;
}

CMD:familyspawn(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    if (FamilyData[familyid][FamilySpawnX] == 0.0 && FamilyData[familyid][FamilySpawnY] == 0.0 && FamilyData[familyid][FamilySpawnZ] == 0.0)
    {
        SendClientMessage(playerid, -1, "Markas keluarga belum diatur.");
        return 1;
    }

    SetPlayerPos(playerid, FamilyData[familyid][FamilySpawnX], FamilyData[familyid][FamilySpawnY], FamilyData[familyid][FamilySpawnZ]);
    SetPlayerFacingAngle(playerid, FamilyData[familyid][FamilySpawnA]);
    SetPlayerInterior(playerid, FamilyData[familyid][FamilyInterior]);
    SetPlayerVirtualWorld(playerid, FamilyData[familyid][FamilyVirtualWorld]);
    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Anda telah diteleport ke markas keluarga Anda.");
    return 1;
}

CMD:familyinfo(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new ownerName[MAX_PLAYER_NAME];
    GetPlayerName(FamilyData[familyid][FamilyOwnerID], ownerName, sizeof(ownerName));

    new string[256];
    format(string, sizeof(string), "{%x}--- Informasi Keluarga Anda ---", FamilyData[familyid][FamilyColor]);
    SendClientMessage(playerid, -1, string);
    format(string, sizeof(string), "{%x}ID: %d", FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilyID]);
    SendClientMessage(playerid, -1, string);
    format(string, sizeof(string), "{%x}Nama Keluarga: %s", FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilyName]);
    SendClientMessage(playerid, -1, string);
    format(string, sizeof(string), "{%x}Motto: %s", FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilyMotto]);
    SendClientMessage(playerid, -1, string);
    format(string, sizeof(string), "{%x}Pemilik: %s", FamilyData[familyid][FamilyColor], ownerName);
    SendClientMessage(playerid, -1, string);
    format(string, sizeof(string), "{%x}Anggota: %d/%d", FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilyMemberCount], MAX_FAMILY_MEMBERS);
    SendClientMessage(playerid, -1, string);
    format(string, sizeof(string), "{%x}Bank: $%d", FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilyBank]);
    SendClientMessage(playerid, -1, string);
    new rankString[32];
    GetRankName(PlayerFamilyRank[playerid], rankString, sizeof(rankString));
    format(string, sizeof(string), "{%x}Pangkat Anda: %s (%d/%d)", FamilyData[familyid][FamilyColor], rankString, PlayerFamilyRank[playerid] + 1, MAX_FAMILY_RANKS);
    SendClientMessage(playerid, -1, string);
    format(string, sizeof(string), "{%x}Tanggal Dibuat: %s", FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilyCreationDate]);
    SendClientMessage(playerid, -1, string);
    format(string, sizeof(string), "{%x}Reputasi: %d | Level: %d", FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilyReputation], FamilyData[familyid][FamilyLevel]);
    SendClientMessage(playerid, -1, string);
    SendClientMessage(playerid, -1, "{%x}----------------------------", FamilyData[familyid][FamilyColor]);
    return 1;
}

CMD:setfamilyspawn(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    if (FamilyData[familyid][FamilyOwnerID] != playerid)
    {
        SendClientMessage(playerid, -1, "Hanya pemilik keluarga yang dapat mengatur spawn keluarga.");
        return 1;
    }

    GetPlayerPos(playerid, FamilyData[familyid][FamilySpawnX], FamilyData[familyid][FamilySpawnY], FamilyData[familyid][FamilySpawnZ]);
    GetPlayerFacingAngle(playerid, FamilyData[familyid][FamilySpawnA]);
    FamilyData[familyid][FamilyInterior] = GetPlayerInterior(playerid);
    FamilyData[familyid][FamilyVirtualWorld] = GetPlayerVirtualWorld(playerid);

    if (IsValidDynamic3DTextLabel(FamilyData[familyid][FamilyTextLabel]))
    {
        DestroyDynamic3DTextLabel(FamilyData[familyid][FamilyTextLabel]);
    }
    new text[128];
    format(text, sizeof(text), "%s\nAnggota: %d/%d", FamilyData[familyid][FamilyName], FamilyData[familyid][FamilyMemberCount], MAX_FAMILY_MEMBERS);
    FamilyData[familyid][FamilyTextLabel] = CreateDynamic3DTextLabel(text, FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilySpawnX], FamilyData[familyid][FamilySpawnY], FamilyData[familyid][FamilySpawnZ] + 1.0, 10.0, .virtualworld = FamilyData[familyid][FamilyVirtualWorld]);

    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Posisi spawn keluarga berhasil diatur!");
    return 1;
}

CMD:setfamilyrank(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    if (PlayerFamilyRank[playerid] < FAMILY_RANK_COOWNER)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk mengatur pangkat.");
        return 1;
    }

    new targetid, newRank;
    if (sscanf(params, "ui", targetid, newRank))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /setfamilyrank [playerid] [pangkat (1-7)]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || targetid == playerid)
    {
        SendClientMessage(playerid, -1, "Pemain tidak valid.");
        return 1;
    }

    if (PlayerFamily[targetid] != PlayerFamily[playerid])
    {
        SendClientMessage(playerid, -1, "Pemain ini bukan anggota keluarga Anda.");
        return 1;
    }

    if (newRank < 1 || newRank > MAX_FAMILY_RANKS)
    {
        SendClientMessage(playerid, -1, "Pangkat harus antara 1 dan 7.");
        return 1;
    }
    
    if (PlayerFamilyRank[targetid] >= PlayerFamilyRank[playerid])
    {
        SendClientMessage(playerid, -1, "Anda tidak bisa mengatur pangkat anggota dengan pangkat yang sama atau lebih tinggi dari Anda.");
        return 1;
    }
    if (newRank - 1 >= PlayerFamilyRank[playerid])
    {
        SendClientMessage(playerid, -1, "Anda tidak bisa mengatur pangkat ke tingkat yang sama atau lebih tinggi dari pangkat Anda.");
        return 1;
    }

    PlayerFamilyRank[targetid] = newRank - 1;
    new targetName[MAX_PLAYER_NAME];
    GetPlayerName(targetid, targetName, sizeof(targetName));
    new rankName[32];
    GetRankName(PlayerFamilyRank[targetid], rankName, sizeof(rankName));
    new string[128];
    format(string, sizeof(string), "Pangkat %s telah diubah menjadi %s (%d).", targetName, rankName, newRank);
    SendClientMessage(playerid, FamilyData[PlayerFamily[playerid]][FamilyColor], string);
    format(string, sizeof(string), "Pangkat Anda telah diubah menjadi %s (%d) oleh %s.", rankName, newRank, GetPlayerName(playerid));
    SendClientMessage(targetid, FamilyData[PlayerFamily[playerid]][FamilyColor], string);
    return 1;
}

CMD:deletefamily(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    if (FamilyData[familyid][FamilyOwnerID] != playerid)
    {
        SendClientMessage(playerid, -1, "Hanya pemilik keluarga yang dapat menghapus keluarga.");
        return 1;
    }

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerFamily[i] == familyid)
        {
            PlayerFamily[i] = -1;
            PlayerFamilyRank[i] = 0;
            SendClientMessage(i, -1, "Keluarga Anda telah dibubarkan oleh pemilik.");
        }
    }

    for (new i = 0; i < MAX_FAMILY_HOUSES; i++)
    {
        if (FamilyHouses[i][HouseFamilyID] == familyid)
        {
            FamilyHouses[i][HouseFamilyID] = -1;
            FamilyHouses[i][HouseLocked] = 1;
            new text[128];
            format(text, sizeof(text), "Rumah Kosong\nHarga: $%d", FamilyHouses[i][HousePrice]);
            UpdateDynamic3DTextLabelText(FamilyHouses[i][HouseLabel], 0xFFFFFFFF, text);
        }
    }

    for (new i = 0; i < MAX_FAMILY_VEHICLES; i++)
    {
        if (FamilyVehicles[i][VehicleFamilyID] == familyid)
        {
            if (IsValidVehicle(FamilyVehicles[i][VehicleSpawned]))
            {
                DestroyVehicle(FamilyVehicles[i][VehicleSpawned]);
            }
            FamilyVehicles[i][VehicleFamilyID] = -1;
            FamilyVehicles[i][VehicleModelID] = 0;
            FamilyVehicles[i][VehicleSpawned] = -1;
        }
    }

    if (IsValidDynamic3DTextLabel(FamilyData[familyid][FamilyTextLabel]))
    {
        DestroyDynamic3DTextLabel(FamilyData[familyid][FamilyTextLabel]);
    }

    strmcpy(FamilyData[familyid][FamilyName], "Tidak Ada", sizeof(FamilyData[familyid][FamilyName]));
    strmcpy(FamilyData[familyid][FamilyMotto], "Tidak Ada Motto", sizeof(FamilyData[familyid][FamilyMotto]));
    FamilyData[familyid][FamilySpawnX] = 0.0;
    FamilyData[familyid][FamilySpawnY] = 0.0;
    FamilyData[familyid][FamilySpawnZ] = 0.0;
    FamilyData[familyid][FamilySpawnA] = 0.0;
    FamilyData[familyid][FamilyInterior] = 0;
    FamilyData[familyid][FamilyVirtualWorld] = 0;
    FamilyData[familyid][FamilyBank] = 0;
    FamilyData[familyid][FamilyOwnerID] = -1;
    FamilyData[familyid][FamilyMemberCount] = 0;
    FamilyData[familyid][FamilyTextLabel] = Text3D:INVALID_3DTEXT_ID;
    FamilyData[familyid][FamilyColor] = 0xFFFFFFFF;
    strmcpy(FamilyData[familyid][FamilyCreationDate], "N/A", sizeof(FamilyData[familyid][FamilyCreationDate]));
    FamilyData[familyid][FamilyReputation] = 0;
    FamilyData[familyid][FamilyLevel] = 1;

    for (new j = 0; j < MAX_FAMILY_WEAPON_SLOTS; j++)
    {
        FamilyWeaponWarehouse[familyid][j][WarehouseItemID] = 0;
        FamilyWeaponWarehouse[familyid][j][WarehouseItemAmount] = 0;
    }
    for (new j = 0; j < MAX_FAMILY_MATERIAL_SLOTS; j++)
    {
        FamilyMaterialWarehouse[familyid][j][WarehouseItemID] = 0;
        FamilyMaterialWarehouse[familyid][j][WarehouseItemAmount] = 0;
    }
    FamilyFundsLogCount[familyid] = 0;

    SendClientMessage(playerid, -1, "Keluarga Anda berhasil dihapus.");
    return 1;
}

CMD:transferfamily(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    if (FamilyData[familyid][FamilyOwnerID] != playerid)
    {
        SendClientMessage(playerid, -1, "Hanya pemilik keluarga yang dapat menyerahkan kepemilikan.");
        return 1;
    }

    new targetid;
    if (sscanf(params, "u", targetid))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /transferfamily [playerid]");
        return 1;
    }

    if (!IsPlayerConnected(targetid) || targetid == playerid)
    {
        SendClientMessage(playerid, -1, "Pemain tidak valid.");
        return 1;
    }

    if (PlayerFamily[targetid] != familyid)
    {
        SendClientMessage(playerid, -1, "Pemain ini bukan anggota keluarga Anda.");
        return 1;
    }

    FamilyData[familyid][FamilyOwnerID] = targetid;
    PlayerFamilyRank[targetid] = FAMILY_RANK_OWNER;
    PlayerFamilyRank[playerid] = FAMILY_RANK_COOWNER;

    new targetName[MAX_PLAYER_NAME];
    GetPlayerName(targetid, targetName, sizeof(targetName));
    new string[128];
    format(string, sizeof(string), "Anda telah menyerahkan kepemilikan keluarga kepada %s.", targetName);
    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], string);
    format(string, sizeof(string), "Anda sekarang adalah pemilik keluarga %s!", FamilyData[familyid][FamilyName]);
    SendClientMessage(targetid, FamilyData[familyid][FamilyColor], string);
    return 1;
}

CMD:listfamilies(playerid)
{
    SendClientMessage(playerid, -1, "--- Daftar Keluarga ---");
    for (new i = 0; i < MAX_FAMILIES; i++)
    {
        if (FamilyData[i][FamilyOwnerID] != -1)
        {
            new ownerName[MAX_PLAYER_NAME];
            GetPlayerName(FamilyData[i][FamilyOwnerID], ownerName, sizeof(ownerName));
            new string[256];
            format(string, sizeof(string), "{%x}ID: %d | Nama: %s | Anggota: %d/%d | Pemilik: %s | Level: %d",
                FamilyData[i][FamilyColor], FamilyData[i][FamilyID], FamilyData[i][FamilyName],
                FamilyData[i][FamilyMemberCount], MAX_FAMILY_MEMBERS, ownerName, FamilyData[i][FamilyLevel]);
            SendClientMessage(playerid, -1, string);
        }
    }
    SendClientMessage(playerid, -1, "-----------------------");
    return 1;
}

CMD:setfamilymotto(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (PlayerFamilyRank[playerid] < FAMILY_RANK_COOWNER)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk mengubah motto keluarga.");
        return 1;
    }

    new motto[FAMILY_MOTTO_LENGTH];
    if (sscanf(params, "s", motto))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /setfamilymotto [MottoBaru]");
        return 1;
    }
    if (strlen(motto) < 5 || strlen(motto) > FAMILY_MOTTO_LENGTH - 1)
    {
        SendClientMessage(playerid, -1, "Motto minimal 5 karakter dan maksimal 127 karakter.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    strmcpy(FamilyData[familyid][FamilyMotto], motto, sizeof(FamilyData[familyid][FamilyMotto]));
    new string[128];
    format(string, sizeof(string), "Motto keluarga berhasil diubah menjadi: %s", motto);
    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], string);
    return 1;
}

CMD:familymembers(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new string[256];
    format(string, sizeof(string), "{%x}--- Anggota Keluarga %s (%d/%d) ---", FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilyName], FamilyData[familyid][FamilyMemberCount], MAX_FAMILY_MEMBERS);
    SendClientMessage(playerid, -1, string);

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerFamily[i] == familyid)
        {
            new name[MAX_PLAYER_NAME];
            GetPlayerName(i, name, sizeof(name));
            new rankString[32];
            GetRankName(PlayerFamilyRank[i], rankString, sizeof(rankString));
            format(string, sizeof(string), "{%x}ID: %d | Nama: %s | Pangkat: %s (%d)", FamilyData[familyid][FamilyColor], i, name, rankString, PlayerFamilyRank[i] + 1);
            SendClientMessage(playerid, -1, string);
        }
    }
    SendClientMessage(playerid, -1, "{%x}----------------------------", FamilyData[familyid][FamilyColor]);
    return 1;
}

CMD:familybank(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    new familyid = PlayerFamily[playerid];
    new string[64];
    format(string, sizeof(string), "{%x}Saldo bank keluarga Anda: $%d", FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilyBank]);
    SendClientMessage(playerid, -1, string);
    return 1;
}

CMD:familylock(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (PlayerFamilyRank[playerid] < FAMILY_RANK_MANAGER)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk mengunci/membuka kunci rumah keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new houseFound = -1;
    for (new i = 0; i < MAX_FAMILY_HOUSES; i++)
    {
        if (FamilyHouses[i][HouseFamilyID] == familyid)
        {
            houseFound = i;
            break;
        }
    }

    if (houseFound == -1)
    {
        SendClientMessage(playerid, -1, "Keluarga Anda tidak memiliki rumah.");
        return 1;
    }

    if (FamilyHouses[houseFound][HouseLocked] == 0)
    {
        FamilyHouses[houseFound][HouseLocked] = 1;
        SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Rumah keluarga berhasil dikunci.");
    }
    else
    {
        FamilyHouses[houseFound][HouseLocked] = 0;
        SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Rumah keluarga berhasil dibuka kuncinya.");
    }
    return 1;
}

CMD:buyhouse(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (FamilyData[PlayerFamily[playerid]][FamilyOwnerID] != playerid)
    {
        SendClientMessage(playerid, -1, "Hanya pemilik keluarga yang dapat membeli rumah.");
        return 1;
    }

    new houseid;
    if (sscanf(params, "i", houseid))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /buyhouse [houseid]");
        return 1;
    }

    if (houseid < 0 || houseid >= MAX_FAMILY_HOUSES)
    {
        SendClientMessage(playerid, -1, "ID rumah tidak valid.");
        return 1;
    }

    if (FamilyHouses[houseid][HouseFamilyID] != -1)
    {
        SendClientMessage(playerid, -1, "Rumah ini sudah dimiliki oleh keluarga lain.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    if (FamilyData[familyid][FamilyBank] < FamilyHouses[houseid][HousePrice])
    {
        SendClientMessage(playerid, -1, "Dana di bank keluarga tidak cukup untuk membeli rumah ini.");
        return 1;
    }

    FamilyData[familyid][FamilyBank] -= FamilyHouses[houseid][HousePrice];
    FamilyHouses[houseid][HouseFamilyID] = familyid;
    FamilyHouses[houseid][HouseLocked] = 0;
    
    new text[128];
    format(text, sizeof(text), "%s\nTerkunci: Tidak", FamilyData[familyid][FamilyName]);
    UpdateDynamic3DTextLabelText(FamilyHouses[houseid][HouseLabel], FamilyData[familyid][FamilyColor], text);
    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Anda berhasil membeli rumah untuk keluarga Anda!");
    
    new string[128];
    format(string, sizeof(string), "Keluarga Anda telah membeli rumah ID %d.", houseid);
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerFamily[i] == familyid)
        {
            SendClientMessage(i, FamilyData[familyid][FamilyColor], string);
        }
    }
    LogFamilyFunds(familyid, playerid, 3, FamilyHouses[houseid][HousePrice]);
    return 1;
}

CMD:sellhouse(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (FamilyData[PlayerFamily[playerid]][FamilyOwnerID] != playerid)
    {
        SendClientMessage(playerid, -1, "Hanya pemilik keluarga yang dapat menjual rumah.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new houseFound = -1;
    for (new i = 0; i < MAX_FAMILY_HOUSES; i++)
    {
        if (FamilyHouses[i][HouseFamilyID] == familyid)
        {
            houseFound = i;
            break;
        }
    }

    if (houseFound == -1)
    {
        SendClientMessage(playerid, -1, "Keluarga Anda tidak memiliki rumah.");
        return 1;
    }

    new refundAmount = FamilyHouses[houseFound][HousePrice / 2];
    FamilyData[familyid][FamilyBank] += refundAmount;
    FamilyHouses[houseFound][HouseFamilyID] = -1;
    FamilyHouses[houseFound][HouseLocked] = 1;
    
    new text[128];
    format(text, sizeof(text), "Rumah Kosong\nHarga: $%d", FamilyHouses[houseFound][HousePrice]);
    UpdateDynamic3DTextLabelText(FamilyHouses[houseFound][HouseLabel], 0xFFFFFFFF, text);
    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Anda berhasil menjual rumah keluarga. Uang masuk ke bank keluarga.");
    
    new string[128];
    format(string, sizeof(string), "Keluarga Anda telah menjual rumah ID %d.", houseFound);
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerFamily[i] == familyid)
        {
            SendClientMessage(i, FamilyData[familyid][FamilyColor], string);
        }
    }
    LogFamilyFunds(familyid, playerid, 4, refundAmount);
    return 1;
}

CMD:createfamilyvehicle(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (PlayerFamilyRank[playerid] < FAMILY_RANK_MANAGER)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk membuat kendaraan keluarga.");
        return 1;
    }

    new modelid, color1, color2;
    if (sscanf(params, "iii", modelid, color1, color2))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /createfamilyvehicle [modelid] [color1] [color2]");
        return 1;
    }

    if (modelid < 400 || modelid > 611 || !IsValidVehicleModel(modelid))
    {
        SendClientMessage(playerid, -1, "Model ID kendaraan tidak valid.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new emptySlot = -1;
    for (new i = 0; i < MAX_FAMILY_VEHICLES; i++)
    {
        if (FamilyVehicles[i][VehicleFamilyID] == -1)
        {
            emptySlot = i;
            break;
        }
    }

    if (emptySlot == -1)
    {
        SendClientMessage(playerid, -1, "Semua slot kendaraan keluarga sudah penuh.");
        return 1;
    }

    FamilyVehicles[emptySlot][VehicleFamilyID] = familyid;
    FamilyVehicles[emptySlot][VehicleModelID] = modelid;
    GetPlayerPos(playerid, FamilyVehicles[emptySlot][VehicleSpawnX], FamilyVehicles[emptySlot][VehicleSpawnY], FamilyVehicles[emptySlot][VehicleSpawnZ]);
    GetPlayerFacingAngle(playerid, FamilyVehicles[emptySlot][VehicleSpawnA]);
    FamilyVehicles[emptySlot][VehiclePrimaryColor] = color1;
    FamilyVehicles[emptySlot][VehicleSecondaryColor] = color2;
    FamilyVehicles[emptySlot][VehicleHealth] = 1000;
    FamilyVehicles[emptySlot][VehicleLocked] = 1;
    FamilyVehicles[emptySlot][VehicleSpawned] = CreateVehicle(modelid, FamilyVehicles[emptySlot][VehicleSpawnX], FamilyVehicles[emptySlot][VehicleSpawnY], FamilyVehicles[emptySlot][VehicleSpawnZ], FamilyVehicles[emptySlot][VehicleSpawnA], color1, color2, -1);
    SetVehicleHealth(FamilyVehicles[emptySlot][VehicleSpawned], FamilyVehicles[emptySlot][VehicleHealth]);

    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Kendaraan keluarga berhasil dibuat!");
    return 1;
}

CMD:destroyfamilyvehicle(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (PlayerFamilyRank[playerid] < FAMILY_RANK_COOWNER)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk menghancurkan kendaraan keluarga.");
        return 1;
    }

    new vehicleid_param;
    if (sscanf(params, "i", vehicleid_param))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /destroyfamilyvehicle [vehicleid]");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new foundVehicle = -1;
    for (new i = 0; i < MAX_FAMILY_VEHICLES; i++)
    {
        if (FamilyVehicles[i][VehicleFamilyID] == familyid && FamilyVehicles[i][VehicleID] == vehicleid_param)
        {
            foundVehicle = i;
            break;
        }
    }

    if (foundVehicle == -1)
    {
        SendClientMessage(playerid, -1, "Kendaraan keluarga dengan ID tersebut tidak ditemukan atau bukan milik keluarga Anda.");
        return 1;
    }

    if (IsValidVehicle(FamilyVehicles[foundVehicle][VehicleSpawned]))
    {
        DestroyVehicle(FamilyVehicles[foundVehicle][VehicleSpawned]);
    }

    FamilyVehicles[foundVehicle][VehicleFamilyID] = -1;
    FamilyVehicles[foundVehicle][VehicleModelID] = 0;
    FamilyVehicles[foundVehicle][VehicleSpawnX] = 0.0;
    FamilyVehicles[foundVehicle][VehicleSpawnY] = 0.0;
    FamilyVehicles[foundVehicle][VehicleSpawnZ] = 0.0;
    FamilyVehicles[foundVehicle][VehicleSpawnA] = 0.0;
    FamilyVehicles[foundVehicle][VehiclePrimaryColor] = 0;
    FamilyVehicles[foundVehicle][VehicleSecondaryColor] = 0;
    FamilyVehicles[foundVehicle][VehicleHealth] = 0;
    FamilyVehicles[foundVehicle][VehicleLocked] = 0;
    FamilyVehicles[foundVehicle][VehicleSpawned] = -1;

    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Kendaraan keluarga berhasil dihancurkan!");
    return 1;
}

CMD:listfamilyvehicles(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "--- Kendaraan Keluarga Anda ---");
    new foundAny = 0;
    for (new i = 0; i < MAX_FAMILY_VEHICLES; i++)
    {
        if (FamilyVehicles[i][VehicleFamilyID] == familyid)
        {
            new string[128];
            format(string, sizeof(string), "ID: %d | Model: %d | Spawned: %s | Terkunci: %s",
                FamilyVehicles[i][VehicleID], FamilyVehicles[i][VehicleModelID],
                (IsValidVehicle(FamilyVehicles[i][VehicleSpawned]) ? "Ya" : "Tidak"),
                (FamilyVehicles[i][VehicleLocked] == 1 ? "Ya" : "Tidak"));
            SendClientMessage(playerid, FamilyData[familyid][FamilyColor], string);
            foundAny = 1;
        }
    }
    if (!foundAny)
    {
        SendClientMessage(playerid, -1, "Keluarga Anda tidak memiliki kendaraan.");
    }
    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "--------------------------------");
    return 1;
}

CMD:spawnfamilyvehicle(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (PlayerFamilyRank[playerid] < FAMILY_RANK_CAPTAIN)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk menspawn kendaraan keluarga.");
        return 1;
    }

    new vehicleid_param;
    if (sscanf(params, "i", vehicleid_param))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /spawnfamilyvehicle [vehicleid]");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new foundVehicle = -1;
    for (new i = 0; i < MAX_FAMILY_VEHICLES; i++)
    {
        if (FamilyVehicles[i][VehicleFamilyID] == familyid && FamilyVehicles[i][VehicleID] == vehicleid_param)
        {
            foundVehicle = i;
            break;
        }
    }

    if (foundVehicle == -1)
    {
        SendClientMessage(playerid, -1, "Kendaraan keluarga dengan ID tersebut tidak ditemukan atau bukan milik keluarga Anda.");
        return 1;
    }

    if (IsValidVehicle(FamilyVehicles[foundVehicle][VehicleSpawned]))
    {
        SendClientMessage(playerid, -1, "Kendaraan ini sudah spawned.");
        return 1;
    }

    FamilyVehicles[foundVehicle][VehicleSpawned] = CreateVehicle(FamilyVehicles[foundVehicle][VehicleModelID], FamilyVehicles[foundVehicle][VehicleSpawnX], FamilyVehicles[foundVehicle][VehicleSpawnY], FamilyVehicles[foundVehicle][VehicleSpawnZ], FamilyVehicles[foundVehicle][VehicleSpawnA], FamilyVehicles[foundVehicle][VehiclePrimaryColor], FamilyVehicles[foundVehicle][VehicleSecondaryColor], -1);
    SetVehicleHealth(FamilyVehicles[foundVehicle][VehicleSpawned], FamilyVehicles[foundVehicle][VehicleHealth]);
    SetVehicleParamsForPlayer(FamilyVehicles[foundVehicle][VehicleSpawned], playerid, 0, (FamilyVehicles[foundVehicle][VehicleLocked] == 1 ? 0 : 1));

    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Kendaraan keluarga berhasil di-spawn!");
    return 1;
}

CMD:familyvehiclelock(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (PlayerFamilyRank[playerid] < FAMILY_RANK_CAPTAIN)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk mengunci/membuka kunci kendaraan keluarga.");
        return 1;
    }

    new vehicleid_param;
    if (sscanf(params, "i", vehicleid_param))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /familyvehiclelock [vehicleid]");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new foundVehicle = -1;
    for (new i = 0; i < MAX_FAMILY_VEHICLES; i++)
    {
        if (FamilyVehicles[i][VehicleFamilyID] == familyid && FamilyVehicles[i][VehicleID] == vehicleid_param)
        {
            foundVehicle = i;
            break;
        }
    }

    if (foundVehicle == -1)
    {
        SendClientMessage(playerid, -1, "Kendaraan keluarga dengan ID tersebut tidak ditemukan atau bukan milik keluarga Anda.");
        return 1;
    }

    if (!IsValidVehicle(FamilyVehicles[foundVehicle][VehicleSpawned]))
    {
        SendClientMessage(playerid, -1, "Kendaraan ini belum di-spawn.");
        return 1;
    }

    if (FamilyVehicles[foundVehicle][VehicleLocked] == 0)
    {
        FamilyVehicles[foundVehicle][VehicleLocked] = 1;
        SetVehicleParamsForPlayer(FamilyVehicles[foundVehicle][VehicleSpawned], playerid, 0, 0);
        SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Kendaraan keluarga berhasil dikunci.");
    }
    else
    {
        FamilyVehicles[foundVehicle][VehicleLocked] = 0;
        SetVehicleParamsForPlayer(FamilyVehicles[foundVehicle][VehicleSpawned], playerid, 0, 1);
        SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Kendaraan keluarga berhasil dibuka kuncinya.");
    }
    return 1;
}

CMD:familysupply(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (PlayerFamilyRank[playerid] < FAMILY_RANK_CAPTAIN)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk mengelola suplai keluarga.");
        return 1;
    }

    new itemType, itemID, amount;
    if (sscanf(params, "iii", itemType, itemID, amount))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /familysupply [jenis(1=senjata, 2=material)] [IDitem] [jumlah]");
        return 1;
    }

    if (amount <= 0)
    {
        SendClientMessage(playerid, -1, "Jumlah tidak valid.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new string[128];
    new bool success = false;

    if (itemType == 1)
    {
        if (itemID < 22 || itemID > 46)
        {
            SendClientMessage(playerid, -1, "ID senjata tidak valid (22-46).");
            return 1;
        }
        
        new foundSlot = -1;
        for (new i = 0; i < MAX_FAMILY_WEAPON_SLOTS; i++)
        {
            if (FamilyWeaponWarehouse[familyid][i][WarehouseItemID] == 0 || FamilyWeaponWarehouse[familyid][i][WarehouseItemID] == itemID)
            {
                foundSlot = i;
                break;
            }
        }

        if (foundSlot == -1)
        {
            SendClientMessage(playerid, -1, "Gudang senjata penuh atau tidak ada slot untuk senjata ini.");
            return 1;
        }

        FamilyWeaponWarehouse[familyid][foundSlot][WarehouseItemID] = itemID;
        FamilyWeaponWarehouse[familyid][foundSlot][WarehouseItemAmount] += amount;
        format(string, sizeof(string), "Anda telah menambahkan %d buah senjata ID %d ke gudang senjata keluarga.", amount, itemID);
        success = true;
    }
    else if (itemType == 2)
    {
        new foundSlot = -1;
        for (new i = 0; i < MAX_FAMILY_MATERIAL_SLOTS; i++)
        {
            if (FamilyMaterialWarehouse[familyid][i][WarehouseItemID] == 0 || FamilyMaterialWarehouse[familyid][i][WarehouseItemID] == itemID)
            {
                foundSlot = i;
                break;
            }
        }

        if (foundSlot == -1)
        {
            SendClientMessage(playerid, -1, "Gudang material penuh atau tidak ada slot untuk material ini.");
            return 1;
        }

        FamilyMaterialWarehouse[familyid][foundSlot][WarehouseItemID] = itemID;
        FamilyMaterialWarehouse[familyid][foundSlot][WarehouseItemAmount] += amount;
        format(string, sizeof(string), "Anda telah menambahkan %d unit material ID %d ke gudang material keluarga.", amount, itemID);
        success = true;
    }
    else
    {
        SendClientMessage(playerid, -1, "Jenis item tidak valid. Gunakan 1 untuk senjata atau 2 untuk material.");
        return 1;
    }

    if (success)
    {
        SendClientMessage(playerid, FamilyData[familyid][FamilyColor], string);
    }
    return 1;
}

CMD:familytake(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (PlayerFamilyRank[playerid] < FAMILY_RANK_RECRUIT)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk mengambil suplai dari gudang keluarga.");
        return 1;
    }

    new itemType, itemID, amount;
    if (sscanf(params, "iii", itemType, itemID, amount))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /familytake [jenis(1=senjata, 2=material)] [IDitem] [jumlah]");
        return 1;
    }

    if (amount <= 0)
    {
        SendClientMessage(playerid, -1, "Jumlah tidak valid.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new string[128];
    new bool success = false;

    if (itemType == 1)
    {
        new foundSlot = -1;
        for (new i = 0; i < MAX_FAMILY_WEAPON_SLOTS; i++)
        {
            if (FamilyWeaponWarehouse[familyid][i][WarehouseItemID] == itemID)
            {
                foundSlot = i;
                break;
            }
        }

        if (foundSlot == -1 || FamilyWeaponWarehouse[familyid][foundSlot][WarehouseItemAmount] < amount)
        {
            SendClientMessage(playerid, -1, "Senjata tidak ditemukan atau jumlah tidak cukup di gudang senjata.");
            return 1;
        }

        GivePlayerWeapon(playerid, itemID, amount);
        FamilyWeaponWarehouse[familyid][foundSlot][WarehouseItemAmount] -= amount;
        
        if (FamilyWeaponWarehouse[familyid][foundSlot][WarehouseItemAmount] == 0)
        {
            FamilyWeaponWarehouse[familyid][foundSlot][WarehouseItemID] = 0;
        }

        format(string, sizeof(string), "Anda telah mengambil %d buah senjata ID %d dari gudang senjata keluarga.", amount, itemID);
        success = true;
    }
    else if (itemType == 2)
    {
        new foundSlot = -1;
        for (new i = 0; i < MAX_FAMILY_MATERIAL_SLOTS; i++)
        {
            if (FamilyMaterialWarehouse[familyid][i][WarehouseItemID] == itemID)
            {
                foundSlot = i;
                break;
            }
        }

        if (foundSlot == -1 || FamilyMaterialWarehouse[familyid][foundSlot][WarehouseItemAmount] < amount)
        {
            SendClientMessage(playerid, -1, "Material tidak ditemukan atau jumlah tidak cukup di gudang material.");
            return 1;
        }

        // Simulasikan pemberian material
        // Di sini Anda perlu menambahkan logika untuk memberikan material ke pemain.
        // Contoh: SetPlayerMaterial(playerid, itemID, GetPlayerMaterial(playerid, itemID) + amount);
        FamilyMaterialWarehouse[familyid][foundSlot][WarehouseItemAmount] -= amount;
        
        if (FamilyMaterialWarehouse[familyid][foundSlot][WarehouseItemAmount] == 0)
        {
            FamilyMaterialWarehouse[familyid][foundSlot][WarehouseItemID] = 0;
        }

        format(string, sizeof(string), "Anda telah mengambil %d unit material ID %d dari gudang material keluarga.", amount, itemID);
        success = true;
    }
    else
    {
        SendClientMessage(playerid, -1, "Jenis item tidak valid. Gunakan 1 untuk senjata atau 2 untuk material.");
        return 1;
    }

    if (success)
    {
        SendClientMessage(playerid, FamilyData[familyid][FamilyColor], string);
    }
    return 1;
}

CMD:familywarehouse(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new string[256];

    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "--- Gudang Senjata Keluarga ---");
    new foundWeapon = 0;
    for (new i = 0; i < MAX_FAMILY_WEAPON_SLOTS; i++)
    {
        if (FamilyWeaponWarehouse[familyid][i][WarehouseItemID] != 0)
        {
            format(string, sizeof(string), "ID Senjata: %d | Jumlah: %d", FamilyWeaponWarehouse[familyid][i][WarehouseItemID], FamilyWeaponWarehouse[familyid][i][WarehouseItemAmount]);
            SendClientMessage(playerid, FamilyData[familyid][FamilyColor], string);
            foundWeapon = 1;
        }
    }
    if (!foundWeapon)
    {
        SendClientMessage(playerid, -1, "Gudang senjata kosong.");
    }

    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "--- Gudang Material Keluarga ---");
    new foundMaterial = 0;
    for (new i = 0; i < MAX_FAMILY_MATERIAL_SLOTS; i++)
    {
        if (FamilyMaterialWarehouse[familyid][i][WarehouseItemID] != 0)
        {
            format(string, sizeof(string), "ID Material: %d | Jumlah: %d", FamilyMaterialWarehouse[familyid][i][WarehouseItemID], FamilyMaterialWarehouse[familyid][i][WarehouseItemAmount]);
            SendClientMessage(playerid, FamilyData[familyid][FamilyColor], string);
            foundMaterial = 1;
        }
    }
    if (!foundMaterial)
    {
        SendClientMessage(playerid, -1, "Gudang material kosong.");
    }
    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "--------------------------------");
    return 1;
}

CMD:setfamilycolor(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (FamilyData[PlayerFamily[playerid]][FamilyOwnerID] != playerid)
    {
        SendClientMessage(playerid, -1, "Hanya pemilik keluarga yang dapat mengatur warna keluarga.");
        return 1;
    }

    new color;
    if (sscanf(params, "i", color))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /setfamilycolor [warnaHEX]");
        SendClientMessage(playerid, -1, "Contoh: /setfamilycolor 0xFF0000FF (untuk merah)");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    FamilyData[familyid][FamilyColor] = color | 0xFF000000;

    if (IsValidDynamic3DTextLabel(FamilyData[familyid][FamilyTextLabel]))
    {
        new text[128];
        format(text, sizeof(text), "%s\nAnggota: %d/%d", FamilyData[familyid][FamilyName], FamilyData[familyid][FamilyMemberCount], MAX_FAMILY_MEMBERS);
        UpdateDynamic3DTextLabelText(FamilyData[familyid][FamilyTextLabel], FamilyData[familyid][FamilyColor], text);
    }
    
    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Warna keluarga berhasil diubah!");
    return 1;
}

CMD:listallhouses(playerid)
{
    SendClientMessage(playerid, -1, "--- Daftar Semua Rumah Keluarga ---");
    for (new i = 0; i < MAX_FAMILY_HOUSES; i++)
    {
        new string[256];
        if (FamilyHouses[i][HouseFamilyID] != -1)
        {
            new familyid = FamilyHouses[i][HouseFamilyID];
            format(string, sizeof(string), "ID: %d | Keluarga: %s | Terkunci: %s | Harga: $%d",
                FamilyHouses[i][HouseID], FamilyData[familyid][FamilyName],
                (FamilyHouses[i][HouseLocked] == 1 ? "Ya" : "Tidak"), FamilyHouses[i][HousePrice]);
            SendClientMessage(playerid, FamilyData[familyid][FamilyColor], string);
        }
        else
        {
            format(string, sizeof(string), "ID: %d | Status: Kosong | Harga: $%d",
                FamilyHouses[i][HouseID], FamilyHouses[i][HousePrice]);
            SendClientMessage(playerid, 0xFFFFFFFF, string);
        }
    }
    SendClientMessage(playerid, -1, "------------------------------------");
    return 1;
}

CMD:sethouseproperty(playerid, params[])
{
    if (IsPlayerAdmin(playerid))
    {
        new houseid;
        new Float:entranceX, Float:entranceY, Float:entranceZ;
        new Float:exitX, Float:exitY, Float:exitZ;
        new entInt, entVW, exInt, exVW, price;
        if (sscanf(params, "iFFFFFFFiiiii", houseid, entranceX, entranceY, entranceZ, exitX, exitY, exitZ, entInt, entVW, exInt, exVW, price))
        {
            SendClientMessage(playerid, -1, "Penggunaan: /sethouseproperty [houseid] [entrX] [entrY] [entrZ] [exitX] [exitY] [exitZ] [entInt] [entVW] [exInt] [exVW] [price]");
            return 1;
        }

        if (houseid < 0 || houseid >= MAX_FAMILY_HOUSES)
        {
            SendClientMessage(playerid, -1, "ID rumah tidak valid.");
            return 1;
        }

        FamilyHouses[houseid][HouseEntranceX] = entranceX;
        FamilyHouses[houseid][HouseEntranceY] = entranceY;
        FamilyHouses[houseid][HouseEntranceZ] = entranceZ;
        FamilyHouses[houseid][HouseExitX] = exitX;
        FamilyHouses[houseid][HouseExitY] = exitY;
        FamilyHouses[houseid][HouseExitZ] = exitZ;
        FamilyHouses[houseid][HouseEntranceInterior] = entInt;
        FamilyHouses[houseid][HouseEntranceVirtualWorld] = entVW;
        FamilyHouses[houseid][HouseExitInterior] = exInt;
        FamilyHouses[houseid][HouseExitVirtualWorld] = exVW;
        FamilyHouses[houseid][HousePrice] = price;
        
        SetDynamicPickupPos(FamilyHouses[houseid][HousePickup], entranceX, entranceY, entranceZ);
        SetDynamic3DTextLabelPos(FamilyHouses[houseid][HouseLabel], entranceX, entranceY, entranceZ + 1.0);
        SetDynamic3DTextLabelVirtualWorld(FamilyHouses[houseid][HouseLabel], entVW);

        new text[128];
        if (FamilyHouses[houseid][HouseFamilyID] != -1) {
            format(text, sizeof(text), "%s\nTerkunci: %s", FamilyData[FamilyHouses[houseid][HouseFamilyID]][FamilyName], (FamilyHouses[houseid][HouseLocked] == 1 ? "Ya" : "Tidak"));
            UpdateDynamic3DTextLabelText(FamilyHouses[houseid][HouseLabel], FamilyData[FamilyHouses[houseid][HouseFamilyID]][FamilyColor], text);
        } else {
            format(text, sizeof(text), "Rumah Kosong\nHarga: $%d", FamilyHouses[houseid][HousePrice]);
            UpdateDynamic3DTextLabelText(FamilyHouses[houseid][HouseLabel], 0xFFFFFFFF, text);
        }


        new string[128];
        format(string, sizeof(string), "Properti rumah ID %d berhasil diatur.", houseid);
        SendClientMessage(playerid, -1, string);
    }
    else
    {
        SendClientMessage(playerid, -1, "Anda bukan admin.");
    }
    return 1;
}

CMD:enterhouse(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new houseFound = -1;
    for (new i = 0; i < MAX_FAMILY_HOUSES; i++)
    {
        if (FamilyHouses[i][HouseFamilyID] == familyid)
        {
            houseFound = i;
            break;
        }
    }

    if (houseFound == -1)
    {
        SendClientMessage(playerid, -1, "Keluarga Anda tidak memiliki rumah.");
        return 1;
    }

    if (FamilyHouses[houseFound][HouseLocked] == 1)
    {
        SendClientMessage(playerid, -1, "Rumah keluarga terkunci.");
        return 1;
    }

    SetPlayerPos(playerid, FamilyHouses[houseFound][HouseExitX], FamilyHouses[houseFound][HouseExitY], FamilyHouses[houseFound][HouseExitZ]);
    SetPlayerInterior(playerid, FamilyHouses[houseFound][HouseExitInterior]);
    SetPlayerVirtualWorld(playerid, FamilyHouses[houseFound][HouseExitVirtualWorld]);
    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Anda masuk ke markas keluarga Anda.");
    return 1;
}

CMD:exithouse(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new houseFound = -1;
    for (new i = 0; i < MAX_FAMILY_HOUSES; i++)
    {
        if (FamilyHouses[i][HouseFamilyID] == familyid)
        {
            houseFound = i;
            break;
        }
    }

    if (houseFound == -1)
    {
        SendClientMessage(playerid, -1, "Keluarga Anda tidak memiliki rumah.");
        return 1;
    }

    if (GetPlayerVirtualWorld(playerid) != FamilyHouses[houseFound][HouseExitVirtualWorld] || GetPlayerInterior(playerid) != FamilyHouses[houseFound][HouseExitInterior])
    {
        SendClientMessage(playerid, -1, "Anda tidak berada di dalam rumah keluarga Anda.");
        return 1;
    }

    SetPlayerPos(playerid, FamilyHouses[houseFound][HouseEntranceX], FamilyHouses[houseFound][HouseEntranceY], FamilyHouses[houseFound][HouseEntranceZ]);
    SetPlayerInterior(playerid, FamilyHouses[houseFound][HouseEntranceInterior]);
    SetPlayerVirtualWorld(playerid, FamilyHouses[houseFound][HouseEntranceVirtualWorld]);
    SendClientMessage(playerid, FamilyData[familyid][FamilyColor], "Anda keluar dari markas keluarga Anda.");
    return 1;
}

CMD:familyfundslog(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (PlayerFamilyRank[playerid] < FAMILY_RANK_MANAGER)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk melihat log dana keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new string[256];
    format(string, sizeof(string), "{%x}--- Log Dana Keluarga %s ---", FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilyName]);
    SendClientMessage(playerid, -1, string);

    if (FamilyFundsLogCount[familyid] == 0)
    {
        SendClientMessage(playerid, -1, "Tidak ada log dana yang tersedia.");
        return 1;
    }

    for (new i = 0; i < FamilyFundsLogCount[familyid]; i++)
    {
        new actionType[32];
        new playerName[MAX_PLAYER_NAME];
        GetPlayerName(FamilyFundsLog[familyid][i][LogPlayerID], playerName, sizeof(playerName));

        switch(FamilyFundsLog[familyid][i][LogType])
        {
            case 0: strmcpy(actionType, "PEMBUATAN KELUARGA", sizeof(actionType));
            case 1: strmcpy(actionType, "SETORAN", sizeof(actionType));
            case 2: strmcpy(actionType, "PENARIKAN", sizeof(actionType));
            case 3: strmcpy(actionType, "BELI RUMAH", sizeof(actionType));
            case 4: strmcpy(actionType, "JUAL RUMAH", sizeof(actionType));
            default: strmcpy(actionType, "TIDAK DIKETAHUI", sizeof(actionType));
        }

        format(string, sizeof(string), "{%x}[%s] %s (%d): %s $%d",
            FamilyData[familyid][FamilyColor],
            FamilyFundsLog[familyid][i][LogTimestamp],
            playerName,
            FamilyFundsLog[familyid][i][LogPlayerID],
            actionType,
            FamilyFundsLog[familyid][i][LogAmount]);
        SendClientMessage(playerid, -1, string);
    }
    SendClientMessage(playerid, -1, "{%x}----------------------------", FamilyData[familyid][FamilyColor]);
    return 1;
}

CMD:familychatglobal(playerid, params[])
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (PlayerFamilyRank[playerid] < FAMILY_RANK_MANAGER)
    {
        SendClientMessage(playerid, -1, "Anda tidak memiliki izin untuk menggunakan obrolan global keluarga.");
        return 1;
    }

    new message[128];
    if (sscanf(params, "s", message))
    {
        SendClientMessage(playerid, -1, "Penggunaan: /familychatglobal [pesan]");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    new chatString[256];
    format(chatString, sizeof(chatString), "{%x}[GLOBAL FAMILY CHAT] (%s) %s: %s", FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilyName], name, message);
    SendClientMessageToAll(FamilyData[familyid][FamilyColor], chatString);
    return 1;
}

CMD:familylevel(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    new familyid = PlayerFamily[playerid];
    new string[128];
    format(string, sizeof(string), "{%x}Level keluarga Anda: %d", FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilyLevel]);
    SendClientMessage(playerid, -1, string);
    format(string, sizeof(string), "{%x}Reputasi keluarga: %d", FamilyData[familyid][FamilyColor], FamilyData[familyid][FamilyReputation]);
    SendClientMessage(playerid, -1, string);
    return 1;
}

CMD:addfamilyreputation(playerid, params[])
{
    if (IsPlayerAdmin(playerid))
    {
        new familyid_param, amount;
        if (sscanf(params, "ii", familyid_param, amount))
        {
            SendClientMessage(playerid, -1, "Penggunaan: /addfamilyreputation [familyid] [jumlah]");
            return 1;
        }

        if (familyid_param < 0 || familyid_param >= MAX_FAMILIES || FamilyData[familyid_param][FamilyOwnerID] == -1)
        {
            SendClientMessage(playerid, -1, "ID keluarga tidak valid.");
            return 1;
        }

        FamilyData[familyid_param][FamilyReputation] += amount;
        new string[128];
        format(string, sizeof(string), "Reputasi keluarga %s ditambahkan sebanyak %d. Reputasi saat ini: %d",
            FamilyData[familyid_param][FamilyName], amount, FamilyData[familyid_param][FamilyReputation]);
        SendClientMessage(playerid, -1, string);
    }
    else
    {
        SendClientMessage(playerid, -1, "Anda bukan admin.");
    }
    return 1;
}

CMD:levelupthefamily(playerid)
{
    if (PlayerFamily[playerid] == -1)
    {
        SendClientMessage(playerid, -1, "Anda tidak tergabung dalam keluarga.");
        return 1;
    }
    if (FamilyData[PlayerFamily[playerid]][FamilyOwnerID] != playerid)
    {
        SendClientMessage(playerid, -1, "Hanya pemilik keluarga yang dapat meningkatkan level keluarga.");
        return 1;
    }

    new familyid = PlayerFamily[playerid];
    new requiredReputation = FamilyData[familyid][FamilyLevel] * 1000;
    new levelUpCost = FamilyData[familyid][FamilyLevel] * 10000000;

    if (FamilyData[familyid][FamilyReputation] < requiredReputation)
    {
        new string[128];
        format(string, sizeof(string), "Reputasi keluarga Anda (%d) belum cukup. Dibutuhkan %d reputasi untuk level berikutnya.",
            FamilyData[familyid][FamilyReputation], requiredReputation);
        SendClientMessage(playerid, -1, string);
        return 1;
    }

    if (FamilyData[familyid][FamilyBank] < levelUpCost)
    {
        new string[128];
        format(string, sizeof(string), "Dana di bank keluarga Anda ($%d) belum cukup. Dibutuhkan $%d untuk level berikutnya.",
            FamilyData[familyid][FamilyBank], levelUpCost);
        SendClientMessage(playerid, -1, string);
        return 1;
    }

    FamilyData[familyid][FamilyBank] -= levelUpCost;
    FamilyData[familyid][FamilyReputation] = 0;
    FamilyData[familyid][FamilyLevel]++;
    
    new string[128];
    format(string, sizeof(string), "Keluarga Anda telah naik ke Level %d!", FamilyData[familyid][FamilyLevel]);
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (IsPlayerConnected(i) && PlayerFamily[i] == familyid)
        {
            SendClientMessage(i, FamilyData[familyid][FamilyColor], string);
        }
    }
    LogFamilyFunds(familyid, playerid, 5, levelUpCost);
    return 1;
}
