globalize_all_functions

global table<string, int> PlayerInHardMode
global table<string, int> HardModeKills
global const int HARD_MODE_LIGHT_HEALTH = 50
global const int HARD_MODE_MEDIUM_HEALTH = 25
global const int HARD_MODE_HARD_HEALTH = 1

#if FSCC_ENABLED && FSU_ENABLED

void function FSGG_Init() {

  AddCallback_OnClientConnected ( OnClientConnectedAddhardmode )

  FSCC_CommandStruct command

  command.m_UsageUser = "hardmode <difficulty>"
	command.m_UsageAdmin = ""
	command.m_Description = "puts you in hardmode"
	command.m_Group = "SGG"
	command.m_Abbreviations = ["hm"]
	command.Callback = FSCC_CommandCallback_Hardmode
	FSCC_RegisterCommand( "hardmode", command )

  command.m_UsageUser = "serverBroadcast <message>"
	command.m_UsageAdmin = ""
	command.m_Description = "Sends a message as the server to the chat"
	command.m_Group = "SGG"
	command.m_Abbreviations = ["scast"]
	command.PlayerCanUse = FSA_IsAdmin
	command.Callback = FSCC_CommandCallback_ServerBroadcast
	FSCC_RegisterCommand( "serverBroadcast", command )

	command.m_UsageUser = "speakFor <player name> <message>"
	command.m_UsageAdmin = ""
	command.m_Description = "Sends a messasge in the server as the player"
	command.m_Group = "SGG"
	command.m_Abbreviations = []
	command.PlayerCanUse = FSA_IsAdmin
	command.Callback = FSCC_CommandCallback_SpeakFor
	FSCC_RegisterCommand( "speakFor", command )

  command.m_UsageUser = "meleeport <player name/all> <0/1>"
	command.m_UsageAdmin = ""
	command.m_Description = "activates meleeport for a player"
	command.m_Group = "SGG"
	command.m_Abbreviations = ["hs"]
	command.PlayerCanUse = FSA_IsAdmin
	command.Callback = FSCC_CommandCallback_Meleeport
	FSCC_RegisterCommand( "meleeport", command )

  command.m_UsageUser = "doxx <player name>"
	command.m_UsageAdmin = ""
	command.m_Description = "prints a players IP address in chat"
	command.m_Group = "SGG"
	command.m_Abbreviations = []
	command.PlayerCanUse = FSA_IsAdmin
	command.Callback = FSCC_CommandCallback_doxx
	FSCC_RegisterCommand( "doxx", command )

  command.m_UsageUser = "reset"
	command.m_UsageAdmin = ""
	command.m_Description = "resets your score"
	command.m_Group = "SGG"
	command.m_Abbreviations = []
	command.PlayerCanUse = null
	command.Callback = FSGG_CommandCallback_Reset
	FSCC_RegisterCommand( "reset", command )
}

void function FSGG_CommandCallback_Reset(entity player, array<string> args){
  player.AddToPlayerGameStat( PGS_ASSAULT_SCORE, -GameRules_GetTeamScore( player.GetTeam() ) )
  AddTeamScore( player.GetTeam(), -GameRules_GetTeamScore( player.GetTeam() ) ) // get absolutely fucking destroyed lol
  UpdateLoadout( player )
  NSSendInfoMessageToPlayer(player,"Score sucessfully reset")
}

void function OnClientConnectedAddhardmode(entity player) {
    PlayerInHardMode[player.GetPlayerName()]<- -1
}

void function FSCC_CommandCallback_ServerBroadcast(entity player, array<string> args){
	if(args.len()==0)
	{
		FSU_PrivateChatMessage(player, "Missing arguments, cannot send empty message")
	  	return
	}
	Chat_ServerBroadcast(FSU_ArrayToString(args))
}

void function FSCC_CommandCallback_SpeakFor(entity player, array<string> args){
	if(args.len() < 2){
		FSU_PrivateChatMessage(player, "Wrong format, !speakfor")
	  return
	}
	entity foundPlayer = FSA_GetPlayerEntityByName(args[0])
	if(foundPlayer == null){
		FSU_PrivateChatMessage(player, "Player not found")
	  return
	}
	Chat_Impersonate(foundPlayer, FSU_ArrayToString(args.slice(1)),false)
}

void function FSCC_CommandCallback_Meleeport(entity player, array<string> args){
    if(args.len()<2)
    {
        FSU_PrivateChatMessage(player, "Missing arguments, format: !meleeport <player-name/all> <0/1>")
      return
    }
    if(args[0]=="all"&& args[1]=="1")
    {
      foreach(entity p in GetPlayerArray()){
        if(playerHSNames.find( p.GetPlayerName() )==-1){
          playerHSNames.append(p.GetPlayerName())
          UpdateLoadout(p)
        }
      }
      return
    }
    if(args[0]=="all"&& args[1]=="0")
    {
      foreach(entity p in GetPlayerArray()){
        if(playerHSNames.find( p.GetPlayerName() )!=-1){
          playerHSNames.remove( playerHSNames.find(p.GetPlayerName()) )
          UpdateLoadout(p)
        }
      }
      return
    }
    entity foundPlayer = FSA_GetPlayerEntityByName(args[0])
    if(foundPlayer == null){
        FSU_PrivateChatMessage(player, "Player not found")
      return
    }
    if( args[1]== "1"&& playerHSNames .find( foundPlayer.GetPlayerName() ) ==-1)
    {
      playerHSNames .append( foundPlayer.GetPlayerName() )
      UpdateLoadout(foundPlayer)
      FSU_PrivateChatMessage(player, "Sucessfully added "+ foundPlayer.GetPlayerName())
      return
    }
    if( args[1]== "1"&& playerHSNames .find( foundPlayer.GetPlayerName() ) !=-1)
    {
        FSU_PrivateChatMessage(player, "Player: "+ foundPlayer.GetPlayerName()+ " already has meleeport")
        return
    }
    if( args[1]== "0" && playerHSNames .find( foundPlayer.GetPlayerName() ) ==-1)
    {
        FSU_PrivateChatMessage(player, "Player: "+ foundPlayer.GetPlayerName()+" cannot be removoed as they don't have meleeport")
        return
    }
    if( args[1]== "0"&& playerHSNames .find( foundPlayer.GetPlayerName() ) !=-1)
    {
      playerHSNames .remove( playerHSNames .find( foundPlayer.GetPlayerName() ) )
      UpdateLoadout(foundPlayer)
      FSU_PrivateChatMessage(player, "Sucessfully removed "+ foundPlayer.GetPlayerName())
      return
    }
    FSU_PrivateChatMessage(player, "Wrong format,format: !meleeport <player-name/all> <0/1>" )
    return

  }


void function FSCC_CommandCallback_Hardmode (entity player, array < string > args){
    string Name1 = "Light"
    string Desc1 = "Reduces your health by 50"
    string Name2 = "Medium"
    string Desc2 = "Reduces your health by 75 "
    string Name3 = "Extreme"
    string Desc3 = "Reduces your healt by 99, each gun now takes 2 kills"


    if(args.len()==0){
       Chat_ServerPrivateMessage(player, "Type !hardmode <difficulty> \n -"+Name1+"\n \x1b[34m"+Desc1+"\n -\x1b[0m"+Name2+"\n \x1b[34m"+Desc2+"\n -\x1b[0m"+Name3+"\n \x1b[34m"+Desc3,false)
       return
    }
    if(args[0]=="light"||args[0]=="Light"||args[0]=="LIGHT"||args[0]=="1"){
      PlayerInHardMode[player.GetPlayerName()] = 1
      ChangePlayerHealth(player, HARD_MODE_LIGHT_HEALTH)
      Chat_ServerBroadcast("\x1b[38;5;51m"+player.GetPlayerName()+ " \x1b[0is now playing in hardmode light")
    }
    if(args[0]=="medium"||args[0]=="Medium"||args[0]=="MEDIUM"||args[0]=="2"){
      PlayerInHardMode[player.GetPlayerName()] = 2
      ChangePlayerHealth(player, HARD_MODE_MEDIUM_HEALTH)
      Chat_ServerBroadcast("\x1b[38;5;51m"+player.GetPlayerName()+ " \x1b[0is now playing in hardmode medium")
    }
    if(args[0]=="extreme"||args[0]=="Extreme"||args[0]=="EXTREME"||args[0]=="3"){
      PlayerInHardMode[player.GetPlayerName()] = 3
      ChangePlayerHealth(player, HARD_MODE_HARD_HEALTH)
      Chat_ServerBroadcast("\x1b[38;5;51m"+player.GetPlayerName()+ " \x1b[0is now playing in hardmode extreme")
    }
    if(args[0]=="off"||args[0]=="Off"||args[0]=="OFF"||args[0]=="-1"){
      PlayerInHardMode[player.GetPlayerName()] = -1
      ChangePlayerHealth(player, 100)
      Chat_ServerBroadcast("\x1b[38;5;51m"+player.GetPlayerName()+ " \x1b[0is no longer playing in hardmode")
    }
    if(PlayerInHardMode[player.GetPlayerName()]>0){
      if( !(player.GetPlayerName() in HardModeKills ))
        HardModeKills[player.GetPlayerName()] <- 0
    }
    return
  }

  void function ChangePlayerHealth(entity player, int health){
    player.SetMaxHealth(health)
    player.SetHealth(health)
    NSSendPopUpMessageToPlayer(player, "Your health is now at "+ player.GetMaxHealth())
  }

void function FSCC_CommandCallback_doxx(entity player, array<string> args)
{
  #if !NETLIB
  FSU_PrivateChatMessage(player, "fvnkhead Netlib is required for this command")
  return
  #else // !NETLIB
  if(args.len() < 1 )
  {
    FSU_PrivateChatMessage(player, "wrong format, use !doxx <player name> ")
    return
  }
  entity victim = FSA_GetPlayerEntityByName(args[0])
  if(!victim)
  {
    FSU_PrivateChatMessage(player, "player not found")
    return 
  }
  string ip = NL_GetPlayerIPv4String(victim)
  if(ip == "")
  {
    FSU_PrivateChatMessage(player, "IP could not be localized")
    return 
  }
  Chat_ServerBroadcast(victim.GetPlayerName()+ "\'s IP address is: " + ip + " :)")
  #endif // NETLIB
  }
#endif