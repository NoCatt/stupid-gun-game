untyped
// Disabled for now





global function FSU_Admin_init
global function GetEntityByName
global function ArrayToString
// array< UID >
array<string> loggedin_admins
table<string, int> failedLoginAttempts

void function FSU_Admin_init()
{
  FSU_RegisterCommand( "login", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "login <password>\x1b[0m Login as admin", "admin", FSU_C_Login, [], CanBeAdmin )
  FSU_RegisterCommand( "logout", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "logout\x1b[0m Logout", "admin", FSU_C_Logout, [], IsLoggedIn )
  FSU_RegisterCommand( "mute", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "mute <player>\x1b[0m to mute player", "admin", FSU_C_Mute, [], IsLoggedIn )
  FSU_RegisterCommand( "unmute", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "unmute <player>\x1b[0m to unmute player", "admin", FSU_C_Unmute, [], IsLoggedIn )
  FSU_RegisterCommand( "ban", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "ban <player>\x1b[0m to ban a player", "admin", FSU_C_Ban, [], IsLoggedIn )
  FSU_RegisterCommand( "ForceKick", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "kick <player>\x1b[0m to kick a player", "admin", FSU_C_Kick, [], IsLoggedIn )
  FSU_RegisterCommand( "reload", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "reload\x1b[0m to reload the server", "admin", FSU_C_Reload, [], IsLoggedIn )
  FSU_RegisterCommand( "commandfor", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "reload\x1b[0m to reload the server", "admin", FSU_C_CommandFor, ["cmdFor"], IsLoggedIn )
  FSU_RegisterCommand( "speakfor", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "speakfor\x1b[0m to speak as another player", "admin", FSU_C_SpeakFor, [], IsLoggedIn )
  FSU_RegisterCommand( "meleeport", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "meleeport <player-name/all> <0/1>\x1b[0m to activate meleeport for someone", "admin", FSU_C_HS, ["hs"], IsLoggedIn )
  FSU_RegisterCommand( "servercommand", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "servercommand <command>\x1b[0m to execute a command on the server", "admin", FSU_C_ServerCommand, ["scmd"], IsLoggedIn )
  FSU_RegisterCommand( "serverboradcast", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "serverbroadcast <message>\x1b[0m to send a message as the server in the chat", "admin", FSU_C_Serverbroadcast, ["scast"], IsLoggedIn )
  FSU_RegisterCommand( "playerlist", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "playerlist <optional index>\x1b[0m to see the player array and the index for each player", "admin", FSU_C_Playerlist, ["pl"], IsLoggedIn )
  FSU_RegisterCommand( "script", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "script <code>\x1b[0m to execute code from the chat", "admin", FSU_C_Script, [], IsLoggedIn )
 // FSU_RegisterCommand( "quarantine", "\x1b[113m" + FSU_GetString("FSU_PREFIX") + "quaratine <optional time limit>\x1b[0m to stop anyone from joining", "admin", FSU_C_Quarantine, [], IsLoggedIn )
}

void function FSU_C_Script(entity player, array<string> args){
  if(args.len() == 0){
    Chat_ServerPrivateMessage(player, "Missing arguments: !script <code here>",false)
    return
  }
  try{
    compilestring(ArrayToString(args))()
    Chat_ServerPrivateMessage(player, "Your code seems to have compiled WHAT ARE THE ODDS",false)
    return
  }
  catch ( ex ){
    printt(ex)
    Chat_ServerPrivateMessage(player, "The code has caused an exception",false)
    return
  }
}

void function FSU_C_Playerlist(entity player, array<string> args){
    // I do not want to rist the message being too long, so if there are more than 10 players it will be broken into 2 strings that will be send to the chat
  if(GetPlayerArray().len()<=10){
    string returnMessage = ""
    foreach(index,entity p in GetPlayerArray()){
      returnMessage = returnMessage+ "["+index+"]: "+p.GetPlayerName() +"\n"
    }
    Chat_ServerPrivateMessage(player, returnMessage, false)
    return
  }

  string returnMessage1 = ""
  string returnMessage2 = ""
  foreach(index,entity p in GetPlayerArray()){
    if(index < 10)
      returnMessage1 = returnMessage1 + "["+index+"]: "+p.GetPlayerName() +"\n"
    else
      returnMessage2 = returnMessage2 + "["+index+"]: "+p.GetPlayerName() +"\n"
  }

  Chat_ServerPrivateMessage(player, returnMessage1,false)
  if(returnMessage2 != "") // dont want to send an epty message lol
    Chat_ServerPrivateMessage(player, returnMessage2,false)

}
/*
void function FSU_C_Quarantine(entity player, array<string> args){
  if(args.len()==0)
    thread FSU_C_Quarantine_thread(0.0)
  else
    thread FSU_C_Quarantine_thread( args[0].tofloat() )
}

void function FSU_C_Quarantine_thread(float countdown){
  SetConVarInt("sv_rejectConnections", 1)
  while(countdown > 0)
  {
    wait 1
    countdown -= 1.0
  }
  SetConVarInt("sv_rejectConnections", 0)
}
*/
void function FSU_C_Serverbroadcast(entity player, array<string> args){
  if(args.len()==0)
  {
    Chat_ServerPrivateMessage(player, "Missing arguments, cannot send empty message",false)
    return
  }
  Chat_ServerBroadcast(ArrayToString(args))
  Chat_ServerPrivateMessage(player, "Message sucessully send",false)
}

void function FSU_C_ServerCommand(entity player, array<string> args){
  if(args.len()==0)
  {
    Chat_ServerPrivateMessage(player, "Missing arguments",false)
    return
  }
  try{
    ServerCommand(ArrayToString(args))
  }
  catch(ex){
    Chat_ServerPrivateMessage(player,"The command has caused an exception",false)
  }
  Chat_ServerPrivateMessage(player, "Command executed", false)

}

void function FSU_C_HS(entity player, array<string> args){
  if(args.len()<2)
  {
    Chat_ServerPrivateMessage(player, "Missing arguments, format: !meleeport <player-name/all> <0/1>",false)
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
  entity foundPlayer = GetEntityByName(args[0])
  if(foundPlayer == null){
    Chat_ServerPrivateMessage(player, "Player not found",false)
    return
  }
  if( args[1]== "1"&& playerHSNames .find( foundPlayer.GetPlayerName() ) ==-1)
  {
    playerHSNames .append( foundPlayer.GetPlayerName() )
    UpdateLoadout(foundPlayer)
    Chat_ServerPrivateMessage(player, "Sucessfully added "+ foundPlayer.GetPlayerName(),false)
    return
  }
  if( args[1]== "1"&& playerHSNames .find( foundPlayer.GetPlayerName() ) !=-1)
  {
    Chat_ServerPrivateMessage(player, "Player: "+ foundPlayer.GetPlayerName()+ " already has meleeport",false)
    return
  }
  if( args[1]== "0" && playerHSNames .find( foundPlayer.GetPlayerName() ) ==-1)
  {
    Chat_ServerPrivateMessage(player, "Player: "+ foundPlayer.GetPlayerName()+" cannot be removoed as they don't have meleeport",false)
    return
  }
  if( args[1]== "0"&& playerHSNames .find( foundPlayer.GetPlayerName() ) !=-1)
  {
    playerHSNames .remove( playerHSNames .find( foundPlayer.GetPlayerName() ) )
    UpdateLoadout(foundPlayer)
    Chat_ServerPrivateMessage(player, "Sucessfully removed "+ foundPlayer.GetPlayerName(),false)
    return
  }
  Chat_ServerPrivateMessage(player, "Wrong format,format: !meleeport <player-name/all> <0/1>" ,false)
  return
  
}

void function FSU_C_SpeakFor(entity player, array<string> args){
  if(args.len() < 2){
    Chat_ServerPrivateMessage(player, "Wrong format, !speakfor",false)
    return
  }
  entity foundPlayer = GetEntityByName(args[0])
  if(foundPlayer == null){
    Chat_ServerPrivateMessage(player, "Player not found",false)
    return
  }
  Chat_Impersonate(foundPlayer, ArrayToString(args.slice(1)),false)
}

void function FSU_C_CommandFor(entity player, array<string> args){
  if(args.len()<2){
    Chat_ServerPrivateMessage(player, "Missing arguments !cmdFor <player name> <command> <command arguments>",false)
    return
  }
  entity foundPlayer = GetEntityByName(args[0])
  if(foundPlayer == null){
    Chat_ServerPrivateMessage(player, "Player not found",false)
    return
  }
  table < string, commandStruct > commands = GetCommands()
  if( args[1] in commands )
  {
    if( commands[ args[1] ].callback != null )
    {
      if( commands[ args[1] ].visible != null && !commands[ args[1] ].visible( foundPlayer ) )
      {
        Chat_ServerPrivateMessage( player, "Unknown command: \x1b[113m\"" + args[1] + "\"\x1b[0m", false )
        return
      }
    
      commands[ args[1] ].callback( foundPlayer, args.slice(2) )
    }
  }
  // Check for abbreviations
  else
  {
    foreach ( cmd, cmdStruct in commands )
      foreach ( abv in cmdStruct.abbreviations )
        if ( FSU_GetString("FSU_PREFIX") + abv == args[1] )
        {
          if( cmdStruct.visible != null && !cmdStruct.visible( foundPlayer ) )
          {
            Chat_ServerPrivateMessage( player, "Unknown command: \x1b[113m\"" + args[1] + "\"\x1b[0m", false )
            return
          }
          cmdStruct.callback( foundPlayer, args.slice(2) )
          printt("[FSU]", foundPlayer.GetPlayerName(), foundPlayer.GetUID(), "ran command \"" + args[1] +"\"")
          return
        }
    Chat_ServerPrivateMessage( player, "Unknown command: \x1b[113m\"" + args[1] + "\"\x1b[0m", false )
  }

}

entity function GetEntityByName(string name){
  if(name == "")
    return null

  if(name.find("index[")!= null && name.find("]")!= null)
  {
    int PlayerIndex = GetPlayerIndexFromString(name)
    if(GetPlayerArray().len()-1>= PlayerIndex && PlayerIndex > -1) // check if the index exits
      return GetPlayerArray()[PlayerIndex]
  }

  foreach(entity p in GetPlayerArray())
  {
    if(p.GetPlayerName().tolower() == name.tolower())
      return p 
  }
  return null
}

int function GetPlayerIndexFromString(string index){ // yeah reads like shit but it takes a index[x] and retuns the x as an int I hope
  return index.slice(index.find("[")+1, index.find("]")).tointeger()
}

void function FSU_C_Reload(entity player, array<string> args){
  if(args.len() == 0)
    thread FSU_C_Reload_thread(5.0)
  else{
    thread FSU_C_Reload_thread(args[0].tofloat())
  }

}

void function FSU_C_Reload_thread(float time){
  while(time > 0){
    Chat_ServerBroadcast("The server will reload in "+ time)
    wait 1.0
    time = time - 1.0
  }
  ServerCommand("reload")
}

void function FSU_C_Ban(entity player, array<string> args){
	entity toBan = null
	foreach(entity p in GetPlayerArray())
		if(p.GetPlayerName() == args[0])toBan = p
	if(toBan == null){NSSendPopUpMessageToPlayer(player, "Player not found"); return;}

	ServerCommand("ban " + toBan.GetUID())
  Chat_ServerPrivateMessage(player, "Sucessfully banned",false)
	return
}

void function FSU_C_Kick(entity player, array<string> args){
	string toBan = ""
  if(args.len()==0){
    Chat_ServerPrivateMessage(player, "Missing argument",false)
    return
  }
	foreach(entity p in GetPlayerArray())
		if(p.GetPlayerName() == args[0] )toBan = p.GetPlayerName()
	if(toBan == ""){Chat_ServerPrivateMessage(player, "Player not found",false); return;}

	ServerCommand("kick " + toBan)
  Chat_ServerPrivateMessage(player, "Sucessfully kicked",false)
	return
}

bool function CanBeAdmin( entity player )
{
  foreach ( admin in FSU_GetArray("FSU_ADMIN_UIDS") )
    if( admin == player.GetUID() )
      return true

  return false
}

bool function IsLoggedIn( entity player )
{
  // Check if already logged in
  foreach( uid in loggedin_admins )
  {
    if( player.GetUID() == uid )
    {
      return true
    }
  }

  return false
}

bool function Login( entity player )
{
  // Check if already logged in
  if( IsLoggedIn( player ) )
  {
    Chat_ServerPrivateMessage( player, "Already logged in!", false )
    return false
  }

  // Log in
  loggedin_admins.append( player.GetUID() )
  return true
}

bool function Logout( entity player )
{
  if( IsLoggedIn( player ) )
  {
    loggedin_admins.remove( loggedin_admins.find( player.GetUID() ) )
    Chat_ServerPrivateMessage( player, "Logged out!", false )
    return true
  }

  return false
}

bool function CheckPlayerDuplicates( entity player )
{
  int occurences = 0
  foreach( p in GetPlayerArray() )
  {
    if( p.GetUID() == player.GetUID() )
      occurences++
  }

  // more than one player with same UID, log everyone out
  if( occurences > 1 )
  {
    foreach( p in GetPlayerArray() )
    {
      Chat_ServerPrivateMessage( p, "Found duplicate UID, logging everyone out!", false )
      Logout( player )
    }
    return true
  }

  return false
}

// !mute
void function FSU_C_Mute ( entity player, array < string > args )
{
  if( CheckPlayerDuplicates( player ) )
    return

  if ( args.len() == 0 )
  {
    Chat_ServerPrivateMessage( player, "Missing argument!", false )
    return
  }

  foreach ( p in GetPlayerArray() )
  {
    if( p.GetPlayerName().tolower().find( args[0].tolower() ) != null )
    {
      FSU_Mute( p.GetUID() )
      Chat_ServerPrivateMessage( player, "Muted \x1b[113m" + p.GetPlayerName() + "\x1b[0m!", false )
      Chat_ServerPrivateMessage( p, "You were muted!", false )
      return
    }
  }

  Chat_ServerPrivateMessage( player, "Couldn't find \x1b[113m" +args[0] + "\x1b[0m!", false )
}

// !unmute
void function FSU_C_Unmute ( entity player, array < string > args )
{
  if( CheckPlayerDuplicates( player ) )
    return

  if ( args.len() == 0 )
  {
    Chat_ServerPrivateMessage( player, "Missing argument!", false )
    return
  }

  foreach ( p in GetPlayerArray() )
  {
    if( p.GetPlayerName().tolower().find( args[0].tolower() ) != null )
    {
      FSU_Unmute( p.GetUID() )
      Chat_ServerPrivateMessage( player, "Unmuted \x1b[113m" + p.GetPlayerName() + "\x1b[0m!", false )
      Chat_ServerPrivateMessage( p, "You were unmuted!", false )
      return
    }
  }

  Chat_ServerPrivateMessage( player, "Couldn't find \x1b[113m" + player.GetPlayerName() + "\x1b[0m!", false )
}

// !logout
void function FSU_C_Logout ( entity player, array < string > args )
{
  if( CheckPlayerDuplicates( player ) )
    return

  if ( !Logout( player ) )
    Chat_ServerPrivateMessage( player, "Already logged out!", false )
}

// !login
void function FSU_C_Login ( entity player, array < string > args )
{
  if( CheckPlayerDuplicates( player ) )
    return

  if ( args.len() == 0 )
  {
    Chat_ServerPrivateMessage( player, "Missing argument!", false )
    return
  }

  if ( FSU_GetArray("FSU_ADMIN_UIDS").len() != FSU_GetArray("FSU_ADMIN_PASSWORDS").len() )
  {
    Chat_ServerPrivateMessage( player, "\x1b[113mFSU_ADMIN_UIDS\x1b[0m doesnt match the size \x1b[113mFSU_ADMIN_PASSWORDS\x1b[0m, aborting!", false )
    return
  }

  for( int i = 0; i < FSU_GetArray("FSU_ADMIN_UIDS").len(); i++ )
  {
    if( player.GetUID() == FSU_GetArray("FSU_ADMIN_UIDS")[i] )
    {
      if(!CheckTooManyLoginAttempts(player.GetUID())){
        Chat_ServerPrivateMessage(player, "Too many login attempts try again next round",false)
        return
      }
      if ( args[0] == FSU_GetArray("FSU_ADMIN_PASSWORDS")[i])
      {
        if( Login( player ) )
          Chat_ServerPrivateMessage( player, "Logged in!", false )
        return
      }
      if(player.GetUID() in failedLoginAttempts)
        failedLoginAttempts[player.GetUID()] += 1
      else
        failedLoginAttempts[player.GetUID()]<- 1
    }
  }
  int attemptsLeft = GetConVarInt("FSU_ADMIN_LOGIN_ATTEMPTS") - failedLoginAttempts[player.GetUID()]
  Chat_ServerPrivateMessage( player, "Wrong password! " + attemptsLeft + " attempts left!", false )
}

bool function CheckTooManyLoginAttempts(string UID){
  if(!(UID in failedLoginAttempts))
    return true
  if(failedLoginAttempts[UID] >= GetConVarInt("FSU_ADMIN_LOGIN_ATTEMPTS"))
    return false
  return true
}

string function ArrayToString(array<string> args){
  string message = ""
  foreach(index, string word in args)
    message = message + args[index]+ " "
  return message
}