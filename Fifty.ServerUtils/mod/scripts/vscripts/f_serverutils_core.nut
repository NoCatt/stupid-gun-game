global function FSU_init

global function FSU_RegisterCommand

global function FSU_CanCreatePoll
global function FSU_CreatePoll
global function FSU_GetPollResultIndex
global function FSU_IsDedicated
global function isPlayerInHardMode
global array < entity > playerWantingToActivateGNS
global array < entity > playerWantingToDeactivateGNS
global array < entity > EasyModePlayer
global array < entity > HMLightPlayers
global array < entity > HMMediumPlayers
global array < entity > HMExtremePlayers

struct commandStruct
{
  string usage
  void functionref( entity, array < string > ) callback // Callback when it's called
  array < string > abbreviations // Command abbreviations
  string group // Group, used for help
  bool functionref( entity ) visible // Should show to player ?
}

// List of registered commands
table < string, commandStruct > commands

// Poll stuff
// Used to check if a poll is on
array < string > poll_options
// other poll stuff
table < entity, int > votes
float poll_time
float poll_start
string poll_before
int poll_result
bool poll_show_result



// init
void function FSU_init ()
{
  AddCallback_OnClientConnected ( OnClientConnected )
  
  
  // Register commands
  FSU_RegisterCommand( "help", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "help <page>\x1b[0m Lists registered commands", "core", FSU_C_Help, [ "h" ] )
  FSU_RegisterCommand( "name", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "name\x1b[0m Returns the name of the current server", "core", FSU_C_Name )
  FSU_RegisterCommand( "owner", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "owner\x1b[0m Returns the name of the owner if provided", "core", FSU_C_Owner )
  FSU_RegisterCommand( "mods", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "mods <page>\x1b[0m Lists installed mods on server. This list has to be manually updated and may not be uptodate!","core", FSU_C_Mods )
  FSU_RegisterCommand( "rules", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "rules <page>\x1b[0m Lists rules", "core", FSU_C_Rules)
  FSU_RegisterCommand( "vote", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "vote <number>\x1b[0m Allows you to vote on polls", "core", FSU_C_Vote )
  FSU_RegisterCommand( "usage", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "usage\x1b[0m <command> Prints usage of provided command", "core", FSU_C_Usage )
  FSU_RegisterCommand( "discord", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "discord\x1b[0m Prints a discord invite", "core", FSU_C_Discord, [ "dc" ] )
  FSU_RegisterCommand( "report", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "report <player>\x1b[0m Creates a report and prints it in console so you can copy it", "core", FSU_C_Report )
  FSU_RegisterCommand( "gns", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "gns <on/off>\x1b[0m Votes if Guns and Stones should be turned on", "core", FSU_C_GNS )
  FSU_RegisterCommand("hardmode","\x1b[113m" + FSU_GetString("FSU_PREFIX")+ "Reduces <on/off>x1b[0m your health by 50% to make it more difficult","core",FSU_C_Hard_Mode)
  if( FSU_GetBool("FSU_ENABLE_SWITCH") )
    FSU_RegisterCommand( "switch", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "switch\x1b[0m switches team", "core", FSU_C_Switch )
  
  AddCallback_OnReceivedSayTextMessage( CheckForCommand )
  
  
  if ( FSU_GetBool( "FSU_ENABLE_REPEAT_BROADCAST" ) && GetMapName() != "mp_lobby" )
    thread RepeatBroadcastMessages_Threaded ()
}

// callbacks
void function OnClientConnected ( entity player )
{
  if( FSU_GetBool( "FSU_WELCOME_ENABLE_MESSAGE_BEFORE" ) )
    Chat_ServerPrivateMessage( player, FSU_GetString("fsu_welcome_message_before"), false )
  
  string msg_hosted_by
  if( FSU_GetBool( "FSU_WECLOME_ENABLE_OWNER" ) )
  {
    msg_hosted_by += "Hosted by: \x1b[113m\"" + FSU_GetString("fsu_owner") + "\"\x1b[0m"
    Chat_ServerPrivateMessage( player, msg_hosted_by, false )
  }
  
  int list_count
  
  string msg_commands
  if( FSU_GetBool( "FSU_WELCOME_ENABLE_COMMANDS" ) )
  {
    msg_commands += "Commands:"
    foreach ( cmd in FSU_GetStringArray("fsu_commands") )
    {
      if( list_count > 4 )
        break
      
      msg_commands += "\n    \x1b[113m-\x1b[0m " + cmd
      
      list_count++
    }
    
    Chat_ServerPrivateMessage( player, msg_commands, false )
  }
  
  string msg_rules
  if( FSU_GetBool( "FSU_WELCOME_ENABLE_RULES" ) )
  {
    msg_rules += "Rules:"
    foreach ( _index, rule in FSU_GetStringArray("fsu_rules") )
    {
      if( list_count > 4 )
        break
      
      msg_rules += "\n    \x1b[113m" + ( _index + 1 ) + ".\x1b[0m " + rule
      
      list_count++
    }
    
    Chat_ServerPrivateMessage( player, msg_rules, false )
  }

  string msg_How_to_play
  if(FSU_GetBool("FSU_WELCOME_HOW_TO_PLAY"))
  {
    msg_How_to_play += "How to play:"
    foreach(_index_, guide in FSU_GetStringArray("fsu_how_to_play"))
    {
     if( list_count > 4 )
        break
      msg_How_to_play += "\n    \x1b[113m" + ( _index_ + 1 ) + ".\x1b[0m " + guide

      list_count++
    }
    Chat_ServerPrivateMessage( player, msg_How_to_play, false )
  }
  
  if ( FSU_GetBool( "FSU_WELCOME_ENABLE_MESSAGE_AFTER" ) )
    Chat_ServerPrivateMessage( player, FSU_GetString("fsu_welcome_message_after"), false )
  
  
  // If a poll is active try to show it to late joiners
  // This means we need to calc new length
  if ( FSU_CanCreatePoll() )
    return
  
  string poll_text
  foreach ( _index, line in poll_options )
    poll_text += _index + 1 + ". " + line + "\n"
  
  // Show poll to late joiners, we need to calculate new_length so it ends at the same time for all players
  // This is just visual
  SendHudMessage( player, poll_before + "\n" + poll_text , 0.005, 0.3, 240, 180, 40, 230, 0.2, poll_time - ( Time() - poll_start ), 0.2)
}

ClServer_MessageStruct function CheckForCommand( ClServer_MessageStruct message )
{
  // Unsure if needed, better to check before we do anything funny
  if ( message.message.len() == 0)
    return message
  
  // Check if message starts wit prefix
  if ( message.message.find( FSU_GetString("FSU_PREFIX") ) != 0 )
    return message
  
  // We now confirmed the user is trying to run a command
  array < string > splitMsg = split( message.message, " " )
  
  // Get args from message
  string command = splitMsg[0].tolower()
  array < string > args
  foreach ( _index, string arg in splitMsg )
    if ( _index != 0 )
      args.append( arg )
  
  
  // Log
  printt("[FSU]", message.player.GetPlayerName(), message.player.GetUID(), "ran command \"" + message.message +"\"")
  
  
  // Dont show their message to anyone
  // Also null out as many things as we can
  // This is to protect info such as passwords and such
  message.shouldBlock = true
  message.message = ""
  
  // Try to execute cammand
  if( command in commands )
  {
    if( commands[ command ].callback != null )
    {
      if( commands[ command ].visible != null && !commands[ command ].visible( message.player ) )
      {
        Chat_ServerPrivateMessage( message.player, "Unknown command: \x1b[113m\"" + command + "\"\x1b[0m", false )
        return message
      }
      commands[ command ].callback( message.player, args )
    }
  }
  // Check for abbreviations
  else
  {
    foreach ( cmd, cmdStruct in commands )
      foreach ( abv in cmdStruct.abbreviations )
        if ( FSU_GetString("FSU_PREFIX") + abv == command )
        {
          if( cmdStruct.visible != null && !cmdStruct.visible( message.player ) )
          {
            Chat_ServerPrivateMessage( message.player, "Unknown command: \x1b[113m\"" + command + "\"\x1b[0m", false )
            return message
          }
          cmdStruct.callback( message.player, args )
          printt("[FSU]", message.player.GetPlayerName(), message.player.GetUID(), "ran command \"" + message.message +"\"")
          return message
        }
    Chat_ServerPrivateMessage( message.player, "Unknown command: \x1b[113m\"" + command + "\"\x1b[0m", false )
  }
  
  
  return message
}

void function RepeatBroadcastMessages_Threaded ()
{
  int index
  
  array<string> messages
  
  for ( int i = 0; i < 5; i++ )
  {
    if ( FSU_GetString( "fsu_broadcast_message_" + i ) == "" )
      continue
    
    messages.append( FSU_GetString( "fsu_broadcast_message_" + i ) )
  }
  
  while ( true )
  {
    wait RandomIntRange( FSU_GetFloat( "FSU_REPEAT_BROADCAST_TIME_MIN" ), FSU_GetFloat( "FSU_REPEAT_BROADCAST_TIME_MAX" ) )
    
    
    if( FSU_GetBool( "FSU_REPEAT_BROADCAST_RANDOMISE" ) )
      index = RandomInt( messages.len() )
    
    Chat_ServerBroadcast( messages[ index ] )
    
    index++
    if ( index >= messages.len() )
      index = 0
  }
}

// command register
void function FSU_RegisterCommand ( string command, string usage, string group, void functionref( entity, array < string > ) callbackFunc, array < string > abbreviations = [], bool functionref( entity ) visibilityFunc = null )
{
  foreach( _index, abbv in abbreviations )
    abbreviations[ _index ] = abbv.tolower()
  
  commandStruct _command
  _command.usage = usage
  _command.group = group
  _command.callback = callbackFunc
  _command.abbreviations = abbreviations
  _command.visible = visibilityFunc
  
  
  commands[ FSU_GetString("FSU_PREFIX") + command.tolower() ] <- _command
  printt( "[FSU] Registered command:", command )
}

// poll stuff
//public
bool function FSU_CanCreatePoll ()
{
  return poll_options.len() == 0 ? true : false
}

void function FSU_CreatePoll ( array < string > options, string before, float duration, bool show_result )
{
  if ( options.len() > 7 )
    printt("[FSU] Polls larger than 7 may interfere with chat box!")
  
  poll_start = Time()
  poll_time = duration
  poll_before = before
  poll_show_result = show_result
  
  foreach( option in options )
    poll_options.append( option )
  
  string poll_text
  foreach ( _index, line in poll_options )
    poll_text += _index + 1 + ". " + line + "\n"
  
  
  foreach( player in GetPlayerArray() )
    SendHudMessage( player, poll_before + "\n" + poll_text , 0.005, 0.3, 240, 180, 40, 230, 0.2, poll_time, 0.2)
  
  thread FSU_PollEndTimeWatcher_Threaded ()
}

int function FSU_GetPollResultIndex ()
{
  return poll_result
}

// private
void function FSU_PollEndTimeWatcher_Threaded ()
{
  wait poll_time
  
  // Count votes
  if ( votes.len() == 0 )
  {
    poll_options.clear()
    poll_result = -1
    return
  }
  
  array < int > votes_counted
  foreach ( option in poll_options )
    votes_counted.append(0)
  
  
  foreach ( player, index in votes )
    votes_counted[ index - 1 ]++
  
  int poll_result_votes
  // Could sort but this is prob shorter
  foreach ( _index, count in votes_counted )
  {
    if ( poll_result_votes < count )
    {
      poll_result_votes = count
      poll_result = _index
    }
  }
  
  if ( poll_show_result )
    Chat_ServerBroadcast( "Poll ended! \x1b[113m" + poll_options[ FSU_GetPollResultIndex() ] + "\x1b[0m won!"  )
  
  poll_options.clear()
  votes.clear()
}

bool function FSU_IsDedicated()
{
  try
  {
    if( GetPlayerArray().len() == 0 )
      return true
    
    if( !IsValid(GetPlayerArray()[0]) )
      return true
    
    if ( NSIsPlayerIndexLocalPlayer(0) )
      return false
  }
  catch(ex){}
  
  return true
}

// !help
void function FSU_C_Help ( entity player, array < string > args )
{
  string returnMessage
  int page
  
  
  array < string > allowedCommands
  foreach ( cmd, cmdStruct in commands )
    if ( cmdStruct.visible == null || cmdStruct.visible( player ) )
      allowedCommands.append( cmd )
  
  
  int pages = allowedCommands.len() % 5 == 0 ? ( allowedCommands.len() / 5 ) : ( allowedCommands.len() / 5 + 1 )
  
  if ( args.len() != 0 )
    page = args[0].tointeger() - 1
  
  if ( args.len() != 0 && args[0].tointeger() > pages )
  {
    Chat_ServerPrivateMessage( player, "Maximum number of pages is \x1b[113m" + pages + "\x1b[0m!", false )
    return
  }
  
  if ( args.len() != 0 && !IsValidVoteInt( args[0], pages ) )
  {
    Chat_ServerPrivateMessage( player, "Invalid argument!", false )
    return
  }
  
  
  int _index = 0
  foreach ( cmd in allowedCommands )
  {
    if ( _index >= page * 5 && _index < ( page + 1 ) * 5 )
      returnMessage += "\n    \x1b[113m-\x1b[0m " + cmd
      
    _index++
  }
  
  returnMessage += "\nShowing page \x1b[113m[" + ( page + 1 ) + "/" + pages + "]\x1b[0m"
  
  Chat_ServerPrivateMessage( player, "Commands: " + returnMessage, false )
}

// !rules
void function FSU_C_Rules ( entity player, array < string > args )
{
  string returnMessage
  int page
  
  
  int pages = FSU_GetStringArray("fsu_rules").len() % 5 == 0 ? ( FSU_GetStringArray("fsu_rules").len() / 5 ) : ( FSU_GetStringArray("fsu_rules").len() / 5 + 1 )
  
  if ( args.len() != 0 )
    page = args[0].tointeger() - 1
  
  if ( args.len() != 0 && args[0].tointeger() > pages )
  {
    Chat_ServerPrivateMessage( player, "Maximum number of pages is \x1b[113m" + pages + "\x1b[0m!", false )
    return
  }
  
  if ( args.len() != 0 && !IsValidVoteInt( args[0], pages ) )
  {
    Chat_ServerPrivateMessage( player, "Invalid argument!", false )
    return
  }
  
  
  int _index = 0
  foreach ( cmd in FSU_GetStringArray("fsu_rules") )
  {
    if ( _index >= page * 5 && _index < ( page + 1 ) * 5 )
      returnMessage += "\n    \x1b[113m-\x1b[0m " + cmd
      
    _index++
  }
  
  returnMessage += "\nShowing page \x1b[113m[" + ( page + 1 ) + "/" + pages + "]\x1b[0m"
  
  Chat_ServerPrivateMessage( player, "Rules: " + returnMessage, false )
}

// !owner
void function FSU_C_Owner ( entity player, array < string > args )
{
  Chat_ServerPrivateMessage( player, "Owner: \x1b[113m\"" + FSU_GetString("fsu_owner") + "\"\x1b[0m", false )
}

// !name
void function FSU_C_Name ( entity player, array < string > args )
{
  Chat_ServerPrivateMessage( player, "Server name: \x1b[113m\"" + GetConVarString("ns_server_name") + "\"\x1b[0m", false )
}

// !mods
void function FSU_C_Mods ( entity player, array < string > args )
{
  string returnMessage
  int page
  
  
  int pages = FSU_GetStringArray("fsu_mods").len() % 5 == 0 ? ( FSU_GetStringArray("fsu_mods").len() / 5 ) : ( FSU_GetStringArray("fsu_mods").len() / 5 + 1 )
  
  if ( args.len() != 0 )
    page = args[0].tointeger() - 1
  
  if ( args.len() != 0 && args[0].tointeger() > pages )
  {
    Chat_ServerPrivateMessage( player, "Maximum number of pages is \x1b[113m" + pages + "\x1b[0m!", false )
    return
  }
  
  if ( args.len() != 0 && !IsValidVoteInt( args[0], pages ) )
  {
    Chat_ServerPrivateMessage( player, "Invalid argument!", false )
    return
  }
  
  
  int _index = 0
  foreach ( cmd in FSU_GetStringArray("fsu_mods") )
  {
    if ( _index >= page * 5 && _index < ( page + 1 ) * 5 )
      returnMessage += "\n    \x1b[113m-\x1b[0m " + cmd
      
    _index++
  }
  
  returnMessage += "\nShowing page \x1b[113m[" + ( page + 1 ) + "/" + pages + "]\x1b[0m"
  
  Chat_ServerPrivateMessage( player, "Mods: " + returnMessage, false )
}

// !discord
void function FSU_C_Discord ( entity player, array < string > args )
{
  Chat_ServerPrivateMessage( player, "Join our discord: \x1b[113m" + FSU_GetString("fsu_discord") + "\x1b[0m", false )
}

// !vote
void function FSU_C_Vote ( entity player, array < string > args )
{
  if ( FSU_CanCreatePoll() )
  {
    Chat_ServerPrivateMessage( player, "No vote currently open!", false )
    return
  }
  
  if ( player in votes )
  {
    Chat_ServerPrivateMessage( player, "You have already voted!", false )
    return
  }
  
  if ( args.len() == 0 )
  {
    string message = "Vote options:\n"
    foreach ( _index, string option in poll_options )
      message += "  \x1b[113m" + ( _index + 1 ) + ".\x1b[0m " + option + "\n"
    Chat_ServerPrivateMessage( player, message, false )
    return
  }
  
  if ( !IsValidVoteInt( args[0], poll_options.len() ) )
  {
    Chat_ServerPrivateMessage( player, "Invalid argument!", false )
    return
  }
  
  int index = args[0].tointeger()
  
  votes[ player ] <- index
  Chat_ServerBroadcast( "\x1b[113m[" + votes.len() + "/" + GetPlayerArray().len() + "]\x1b[0m players have voted!" )
  
  Chat_ServerPrivateMessage( player, "You have voted for \x1b[113m" + poll_options[ index - 1 ] + "\x1b[0m", false )
}

// !usage
void function FSU_C_Usage ( entity player, array < string > args )
{
  if ( args.len() == 0 )
  {
    Chat_ServerPrivateMessage( player, "Usage: !usage <command>", false )
    return
  }
  
  string cmd = args[0].find( FSU_GetString("FSU_PREFIX") ) == 0 ? args[0].tolower() : FSU_GetString("FSU_PREFIX") + args[0].tolower()
  
  if ( cmd in commands )
    Chat_ServerPrivateMessage( player, "Usage: " + commands[ cmd ].usage, false )
  else
  {
    Chat_ServerPrivateMessage( player, "Unknown command passed in!", false )
    return
  }
  
  if ( commands[ cmd ].visible != null && commands[ cmd ].visible( player ) )
  {
    Chat_ServerPrivateMessage( player, "Unknown command passed in!", false ) // Dont have rights
    return
  }
  
  if ( commands[ cmd ].abbreviations.len() == 0 )
    return
  
  
  string abbFinal
  foreach ( _index, abb in commands[ cmd ].abbreviations )
    abbFinal += _index == 0 ? "\x1b[113m" + FSU_GetString("FSU_PREFIX") + abb + "\x1b[0m" : ", \x1b[113m" + FSU_GetString("FSU_PREFIX") + abb + "\x1b[0m"
  Chat_ServerPrivateMessage( player, "Abbreviations: " + abbFinal, false )
}


bool function IsValidVoteInt( string arg, int max )
{
  int _index = arg.tointeger()
  
  if ( _index < 1 )
    return false
  
  if ( _index > max )
    return false
  
  return true
}

// !switch
void function FSU_C_Switch ( entity player, array < string > args )
{
  if ( GetGameState() != eGameState.Playing )
  {
    Chat_ServerPrivateMessage( player, "Can't switch in this game state", false )
    return
  }
  
  int maxTeamSize = GetPlayerArray().len() / 2
  
  if( GetPlayerArrayOfTeam( GetOtherTeam( player.GetTeam() ) ).len() > maxTeamSize )
  {
    Chat_ServerPrivateMessage( player, "Other team has too many players!", false )
    return
  }
  
  SetTeam( player, GetOtherTeam( player.GetTeam() ) )
  Chat_ServerPrivateMessage( player, "Switched teams!", false )
}

// !report
void function FSU_C_Report ( entity player, array < string > args )
{
  if ( args.len() == 0 )
  {
    Chat_ServerPrivateMessage( player, "Usage: \x1b[113m!report <player>\x1b[0m", false )
    return
  }
  
  string message = "\\n\\n////////PLAYER REPORT////////"
  string name = ""
  string uid = ""
  
  foreach ( p in GetPlayerArray() )
  {
    if( p.GetPlayerName().tolower().find( args[0].tolower() ) != null )
    {
      name = "Name: " + p.GetPlayerName()
      uid = "UID: " + p.GetUID()
      break
    }
  }
  
  if ( name == "" )
  {
    Chat_ServerPrivateMessage( player, "Player not found!", false )
    return
  }
  
  
  
  string msg = "script_client print(\"" + message + "\\n" + name + "\\nServer: " + GetConVarString( "ns_server_name" ) + "\\n" + uid + "\\n\")"
  print( msg )
  ClientCommand( player, msg )
  
  Chat_ServerPrivateMessage( player, "Report created! Check your console.", false )
}
//!gns
void function FSU_C_GNS( entity player, array < string > args)
{
	try{
	if(gnsOn == false){

		if(playerWantingToActivateGNS.find(player)!= -1){
			Chat_ServerPrivateMessage( player, "You already voted", false )
			return
		}
		if(args[0]!="on"&&args[0]!="ON"&&args[0]!="On"&&args[0]!="1"){
      Chat_ServerPrivateMessage(player,"Not a vali command \n Syntax is: !gns <on/off>",false	)
      return
    }

		playerWantingToActivateGNS.append(player)
    foreach( entity playerMessage in GetPlayerArray())
      Chat_ServerPrivateMessage( playerMessage, "Vote to activate Guns and Stones,["+ playerWantingToActivateGNS.len() + "/" + amoutOfVotesNedded() +"] have casted votes", false )
		
    if(playerWantingToActivateGNS.len()< amoutOfVotesNedded())
      return 

		gnsOn = true
		foreach(entity playerVote in GetPlayerArray() ){
			Chat_ServerPrivateMessage( playerVote, "Guns and stones is now activated", false )
      UpdateLoadout(playerVote)
      playerWantingToActivateGNS.clear()
    }
		
		return
	}
  if(gnsOn == true){

		if(playerWantingToDeactivateGNS.find(player)!= -1){
			Chat_ServerPrivateMessage( player, "You already voted", false )
			return
		}
		if(args[0]!="off"&&args[0]!="OFF"&&args[0]!="Off"&&args[0]!="0"){
      Chat_ServerPrivateMessage(player,"Not a vali command \n Syntax is: !gns <on/off>",false)
      return
    }

		playerWantingToDeactivateGNS.append(player)
    foreach( entity playerMessage in GetPlayerArray())
      Chat_ServerPrivateMessage( playerMessage, "Vote to deactivate Guns and Stones,["+ playerWantingToActivateGNS.len() + "/" + amoutOfVotesNedded() +"] have casted votes, tye !gns off to vote ", false )
		
    if(playerWantingToDeactivateGNS.len()< amoutOfVotesNedded())
      return 
      
		gnsOn = false
		foreach(entity playerVote in GetPlayerArray() ){
			Chat_ServerPrivateMessage( playerVote, "Guns and stones is now deactivated", false )
      UpdateLoadout(playerVote)
      playerWantingToDeactivateGNS.clear()
    }
		
		return
	}
   }
   catch(ex){}
}

//!hardmode
void function FSU_C_Hard_Mode (entity player, array < string > args){
  string Name1 = "Light"
  string Desc1 = "Reduces your health by 50"
  string Name2 = "Medium"
  string Desc2 = "Reduces your health by 75 and pulse blade deaths remove more points"
  string Name3 = "Extreme"
  string Desc3 = "Reduces your healt by 99 and pulse blade deaths remove your enitre score"

  try{
    if(args.len()==0){
      Chat_ServerPrivateMessage(player, "Type !hardmode <difficulty> \n -"+Name1+"\n \x1b[34m"+Desc1+"\n -\x1b[0m"+Name2+"\n \x1b[34m"+Desc2+"\n -\x1b[0m"+Name3+"\n \x1b[34m"+Desc3,false)
      return
    }
    if(isPlayerInHardMode(player)){
        Chat_ServerPrivateMessage(player, "You are already in hard mode you cant change the difficulty until the next match",false)
        return
    }
    if(args[0]=="light"||args[0]=="Light"||args[0]=="LIGHT"){
      HMLightPlayers.append(player)
      player.SetMaxHealth(50)
      player.SetHealth(player.GetMaxHealth())
      Chat_ServerPrivateMessage(player, "You're now in light hard mode, your health is at"+player.GetMaxHealth(),false)
      return
    }
    if(args[0]=="Medium"||args[0]=="medium"){
      HMLightPlayers.append(player)
      player.SetMaxHealth(25)
      player.SetHealth(player.GetMaxHealth())
      Chat_ServerPrivateMessage(player, "You're now in medium hard mode, your health is at"+player.GetMaxHealth(),false)
      return
    }
    if(args[0]=="Extreme"||args[0]="etreme"){
      HMLightPlayers.append(player)
      player.SetMaxHealth(1)
      player.SetHealth(player.GetMaxHealth())
      Chat_ServerPrivateMessage(player, "You're now in extreme hard mode, your health is at"+player.GetMaxHealth(),false)
      return
    }
    if(args[0]=="off"|| args[0]=="Off"){
      int mode_player_is_in = isPlayerInHardModeInt(player)
      if(mode_player_is_in==-1){
        Chat_ServerPrivateMessage(player, "You need to be in hard mode to deactivate it",false)
        return
      }
      if(mode_player_is_in==1){
        HMLightPlayers.remove(HMLightPlayers.find(player))
        return
      }
      if(mode_player_is_in==2){
        HMMediumPlayers.remove(HMLMediumPlayers.find(player))
        return
      }
      if(mode_player_is_in==3){
        HMExtremePlayers.remove(HMExtremePlayers.find(player))
        return
      }
      return
    }
    else{
      Chat_ServerPrivateMessage(player, "Type !hardmode <difficulty> \n -"+Name1+"\n \x1b[34m"+Desc1+"\n -\x1b[0m"+Name2+"\n \x1b[34m"+Desc2+"\n -\x1b[0m"+Name3+"\n \x1b[34m"+Desc3,false)
      return
    }
    return
    }catch(ex){
    }
}
/*
void function FSU_C_EZMODE(entity player, array < string > args){
  try{
    if(isPlaserInBottomFive(player)== false){
       Chat_ServerPrivateMessage(player, "You are too good to be allowed in easy mode",false )
       return
    }
      
    if(args[0]=="on"||args[0]=="On"||args[0]=="ON"||args[0]=="1"){
      EasyModePlayer.append(player)
      player.SetMaxHealth(125)
      player.SetHealth(player.GetMaxHealth())
       Chat_ServerPrivateMessage(player,"Your health is not at "+player.GetMaxHealth()+"hp to make it a bit easier for you ",false)
       return
    }
    if(args[0]=="Off"||args[0]=="OFF"||args[0]=="off"||args[0]=="0"){
      if(EasyModePlayer.find(player)==-1){
         Chat_ServerPrivateMessage(player, "You need to be in esay mode to deactivate it",false)
         return
      }
      EasyModePlayer.remove(EasyModePlayer.find(player))
      player.SetMaxHealth(100)
      player.SetHealth(player.GetMaxHealth())
      Chat_ServerPrivateMessage(player,"Your health is not at "+player.GetMaxHealth()+"hp",false)
    }
    
  }catch(ex){}
}
*/

//jesus i hate this solution but, in order to get the player score sorted in an array i need to make 2 arrays and sort one of them and apply the same changes to the other array :(
/*
bool function isPlaserInBottomFive(entity player){
  if(GetPlayerArray().len()<5)
    return true
  array< entity > PlayersToSort = GetPlayerArray()
  array< int > scoreOfPlayersToSort
  foreach(entity player in GetPlayerArray)
    scoreOfPlayersToSort.append( GameRules_GetTeamScore(player.getTeam()))
  for(int a = 0; a<GetPlayerArray().len()-1 ; a++){
    for(int b = 0 ; b<GetPlayerArray().len() ; b++){
      if(scoreOfPlayersToSort[a]>scoreOfPlayersToSort[b]){
        int placeholderScore
        entity placeholderPlayer

        placeholderScore = scoreOfPlayersToSort[a]
        scoreOfPlayersToSort[a] = scoreOfPlayersToSort[b]
        scoreOfPlayersToSort[b] = placeholderScore

        placeholderPlayer = PlayersToSort[a]
        PlayersToSort[a] = PlayersToSort[b]
        PlayersToSort[b] = placeholderPlayer

      }
    }
  }
  if(PlayersToSort.find(player)>5)
    return true
  return false
}
*/

bool function isPlayerInHardMode(entity player){
  if(HMLightPlayers.find(player)==-1 && HMMediumPlayers.find(player)==-1 && HMExtremePlayers.find(player)==-1)
    return false
  return true
}
int function isPlayerInHardModeInt(entity player){
  if(HMLightPlayers.find(player)!=-1)
    return 1
  if(HMMediumPlayers.find(player)!=-1)
    return 2
  if(HMExtremePlayers.find(player)!=-1)
    return 3
  return -1
}

int function amoutOfVotesNedded(){
switch(GetPlayerArray().len()){
case(1): return 1
case(2): return 1
case(3): return 1
case(4): return 2
case(5): return 2
case(6): return 3
case(7): return 3
case(8): return 4
case(9): return 4
case(10): return 5
case(11): return 5
case(12): return 5
case(13): return 5
case(14): return 6
case(15): return 6
case(16): return 6

}
return 0
}
