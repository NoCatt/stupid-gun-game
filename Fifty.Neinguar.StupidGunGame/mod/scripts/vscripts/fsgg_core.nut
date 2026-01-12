untyped
globalize_all_functions


global const int HARD_MODE_LIGHT_HEALTH = 50
global const int HARD_MODE_MEDIUM_HEALTH = 25
global const int HARD_MODE_HARD_HEALTH = 1

const string FILE_TAG = "clanTags.json"

table playerTags
array<string> bannedWords = ["0wner","owner", "admin","adm1n", "pulse","puise", "nigger","nigga", "faggot", "blade", "dev", "developer", "mod", "moderator", "m0d"]

global struct hardmodeInfo{
  bool isInHardmode = false
  int health = 100
  int killsPerGun = 1
  int reduceScoreOnDeath = 0
  string infoMessage = "with hard mode off"
  int hardmodeKills = 0
}

global table<string, hardmodeInfo> PlayerInHardMode

hardmodeInfo standart ={...}

hardmodeInfo lightMode = {
  isInHardmode = true,
  health = 50,
  infoMessage =  "in hard mode light",
  ...
}
hardmodeInfo mediumMode = {
  isInHardmode = true,
  health = 25,
  killsPerGun = 2,
  reduceScoreOnDeath = 0,
  infoMessage = "in hard mode medium",
  ...
}
hardmodeInfo extremeMode = {
  isInHardmode = true,
  health = 1,
  killsPerGun = 2,
  reduceScoreOnDeath = 1,
  infoMessage = "in hard mode extreme",
  ...
}

#if FSCC_ENABLED && FSU_ENABLED

void function FSGG_Init() {

  AddCallback_OnClientConnected ( OnClientConnectedAddhardmode )
  AddCallback_OnClientConnected ( AddTagToPlayer )


  if( !NSDoesFileExist( FILE_TAG ) )
  {
    NSSaveJSONFile( FILE_TAG, {} )
  }
  else
  {
    NSLoadFile( FILE_TAG, void function ( string data ) : ()
    {
        table tags = DecodeJSON( data )
        playerTags = tags
    })
  }

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
	command.m_Abbreviations = ["r"]
	command.PlayerCanUse = null
	command.Callback = FSGG_CommandCallback_Reset
	FSCC_RegisterCommand( "reset", command )

  command.m_UsageUser = "SetTag"
	command.m_UsageAdmin = ""
	command.m_Description = "Set the tag of a user"
	command.m_Group = "SGG"
	command.m_Abbreviations = []
	command.PlayerCanUse = FSA_IsAdmin
	command.Callback = FSGG_CommandCallback_SetTag
	FSCC_RegisterCommand( "SetTag", command )

  command.m_UsageUser = "tag"
	command.m_UsageAdmin = ""
	command.m_Description = "Set the tag of a user"
	command.m_Group = "SGG"
	command.m_Abbreviations = []
	command.PlayerCanUse = null
	command.Callback = FSGG_CommandCallback_Tag
	FSCC_RegisterCommand( "tag", command )
}

void function FSGG_CommandCallback_Reset(entity player, array<string> args){
  player.AddToPlayerGameStat( PGS_ASSAULT_SCORE, -GameRules_GetTeamScore( player.GetTeam() ) )
  AddTeamScore( player.GetTeam(), -GameRules_GetTeamScore( player.GetTeam() ) ) // get absolutely fucking destroyed lol
  UpdateLoadout( player )
  NSSendInfoMessageToPlayer(player,"Score sucessfully reset")
}

void function OnClientConnectedAddhardmode(entity player) {
    hardmodeInfo test = {...};
	  PlayerInHardMode[player.GetPlayerName()] <- test;
}

void function AddTagToPlayer( entity player )
{
    // if( player.GetUID() in playerTags )
    //   SetPlayerTag( player, expect string( playerTags[ player.GetUID() ] ) )
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
    string Desc2 = "Reduces your health by 75, each gun now takes 2 kills"
    string Name3 = "Extreme"
    string Desc3 = "Reduces your healt by 99, each gun now takes 2 kills"


    if(args.len()==0){
      Chat_ServerPrivateMessage(player, "Type !hardmode <difficulty> \n -"+Name1+"\n \x1b[34m"+Desc1+"\n -\x1b[0m"+Name2+"\n \x1b[34m"+Desc2+"\n -\x1b[0m"+Name3+"\n \x1b[34m"+Desc3,false)
      Chat_ServerPrivateMessage(player,"If you are looking for a custom experience use \x1b[34m!hardmode custom <health> <kills> <reset on death>\x1b[0m",false)
      return
    }
    if(args[0]=="light"||args[0]=="Light"||args[0]=="LIGHT"||args[0]=="1"){
      PlayerInHardMode[player.GetPlayerName()] = lightMode
    }
    if(args[0]=="medium"||args[0]=="Medium"||args[0]=="MEDIUM"||args[0]=="2"){
      PlayerInHardMode[player.GetPlayerName()] = mediumMode
    }
    if(args[0]=="extreme"||args[0]=="Extreme"||args[0]=="EXTREME"||args[0]=="3"){
      PlayerInHardMode[player.GetPlayerName()] = extremeMode
    }
    if(args[0]=="off"||args[0]=="Off"||args[0]=="OFF"||args[0]=="-1"){
      PlayerInHardMode[player.GetPlayerName()] = standart
    }

    if(args[0] == "custom" || args[0] == "Custom"|| args[0] == "CUSTOM"){
      if(args.len()< 4){
        Chat_ServerPrivateMessage(player, "Usage: !hardmode custom \x1b[34m<health> <kills> <reset>\x1b[0m", false)
        return
      }
      int newHealth = int(args[1])
      int kills = int(args[2])
      int reset = int(args[3])
      if (newHealth <=0 || kills <=0 || reset <0){
        Chat_ServerPrivateMessage(player, "Given values must be integers at or above 0",false)
        return
      }
      hardmodeInfo customHM = { ...}
      customHM.isInHardmode = true
      customHM.health = newHealth
      customHM.killsPerGun = kills
      customHM.reduceScoreOnDeath = reset
      customHM.infoMessage = "in custom hard mode"

      PlayerInHardMode[player.GetPlayerName()] = customHM
    }

    ChangePlayerHealth(player, PlayerInHardMode[player.GetPlayerName()].health)
    Chat_ServerBroadcast("\x1b[38;5;51m"+player.GetPlayerName()+ "\x1b[0is now playing " + PlayerInHardMode[player.GetPlayerName()].infoMessage )
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

void function FSGG_CommandCallback_Tag(entity player, array<string> args)
{
  FSU_PrivateChatMessage( player, "Tags are currently unavailable due to Northstar being run without structure. I hate it as much as you do!")
}

void function FSGG_CommandCallback_SetTag(entity player, array<string> args)
{
 FSU_PrivateChatMessage( player, "Tags are currently unavailable due to Northstar being run without structure. I hate it as much as you do!")
}

entity function GetEntityFromUID( string UID )
{
  if( UID == "" )
    return null

  foreach ( entity player in GetPlayerArray() )
    if( player.GetUID() == UID )
      return player
  return null
}

#endif