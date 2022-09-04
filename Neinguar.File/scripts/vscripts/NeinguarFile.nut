global function NeinguarFileInit

table SavePlayerData // table<int (UID) , PlayerData>
table PlayerLeaderboard // table<string (what leaderboard), array<PlayerData>>

global struct PlayerData{
    string Name
    int kills = 0
    int deahts = 0
    int winns = 0 
    int connects = 0
}

void function NeinguarFileInit()
{
    AddClientCommandCallback("GetData", GetDataCMD)
    SavePlayerData = NSLoadfile("Neinguar.File" , "savefile")
    //PlayerLeaderboard = NSLoadfile("Neinguar.File" , "saveLeaderboard")
    PrintDataDEBUG()
	AddCallback_OnPlayerKilled( OnPlayerKilled )
    AddCallback_OnClientConnected(OnClientConnected)
    AddCallback_GameStateEnter( eGameState.WinnerDetermined, OnWinnerDetermined )
}

bool function GetDataCMD(entity player, array<string> args){
    if(args[].len()==0)
        PrintDataDEBUG(player); return true
    
    if(GetPlayerEntityByName(args[0])==null) Chat_ServerPrivateMessage(player, "No player found",false); return true;
    
    Chat_ServerBroadcast(PrintDataDEBUG(GetPlayerEntityByName(args[0])))
    return true
        
}

void function OnPlayerKilled( entity victim, entity attacker, var damageInfo ){
    SavePlayerData[attacker.GetUID()].kills += 1
    SavePlayerData[victim.GetUID()].deahts += 1

    NSSaveFile("Neinguar.File" , "savefile", SavePlayerData)
}   

void function OnClientConnected(entity player){
    if(player.GetUID() in SavePlayerData)
        SavePlayerData[player.GetUID()].connects += 1
    else
        SavePlayerData[player.GetUID()] <- PlayerData p ={Name=player.GetPlayerName()}

    NSSaveFile("Neinguar.File" , "savefile", SavePlayerData)
}

void function OnWinnerDetermined(){
    SavePlayerData[GetWinningPlayer().GetUID()].winns += 1

    NSSaveFile("Neinguar.File" , "savefile", SavePlayerData)
}

entity function GetWinningPlayer()
{
	entity bestplayer

	foreach ( entity player in GetPlayerArray() ) {
		if (bestplayer == null)
			bestplayer = player

		if (GameRules_GetTeamScore(player.GetTeam()) > GameRules_GetTeamScore(bestplayer.GetTeam()))
			bestplayer = player
	}

	return bestplayer
}

void function PrintDataDEBUG(entity player){
    Chat_ServerBroadcast( SavePlayerData[player.GetUID()].Name +"has "+ SavePlayerData[player.GetUID()].Kills +"-lifetime kills" )
}

entity function GetPlayerEntityByName(string name){
    foreach(entity player in GetPlayerArray()
        if(player.GetPlayerName() == name) return player
    return null
}