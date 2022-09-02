global function FSU_ChatFilter_init
global function LevenshteinDistance
global function FSU_Mute
global function FSU_Unmute
global function FSU_IsMuted


struct messageStruct
{
  string message
  float time
}

array<string> Banned_words = ["Faggot","Retard","Fag","Nigger"]
bool shouldBlock = false
bool shouldInform = true
string ResponseOnBlock = "Your message contains offensive speach and was not send to the chat"
bool ShouldShamePlayer = true
string ShameMessage = "I am really bad at this game but my mom doesnt buy me a new one"
string ResponseOnReplace = "Your message contains offensive speach and was altered"


// FIFO style cache
// table < player UID, messages >
table < string, array < messageStruct > > message_cache

// UID, triggers
table< string, int > player_triggers

// List of muted UIDs
array<string> muted_players


void function FSU_ChatFilter_init ()
{
  if ( FSU_GetBool("FSU_ENABLE_SPAM_FILTER") )
    AddCallback_OnReceivedSayTextMessage( RunChatFilter )
}


ClServer_MessageStruct function RunChatFilter( ClServer_MessageStruct message )
{
  if ( message.message == "" )
    return message
  
  if( FSU_GetBool("FSU_EXCLUDE_ADMINS_FROM_CHAT_FILTER") )
    foreach ( admin in FSU_GetArray("FSU_ADMIN_UIDS") )
      if( admin == message.player.GetUID() )
        return message
  
  if ( ShouldBlock( message.player, message.message.tolower() ) )
    message.shouldBlock = true
  else
    AppendMessageToCache( message.player, message.message.tolower() )
  
  
  string LowerMessage  = message.message.tolower()
    foreach(string word in Banned_words)
    {
        if( LowerMessage.find( word.tolower() ) == null) 
            return message
        
        if(shouldBlock){
            message.shouldBlock = true
            if(shouldInform)
                Chat_ServerPrivateMessage(message.player , ResponseOnBlock , false)
            if(ShouldShamePlayer)
                Chat_Impersonate(message.player,ShameMessage,false)
            return message
        } else{
            message.message = StringReplace(LowerMessage, word.tolower(), GetAmoutOfStars(word), true, true)
            if(shouldInform)
                Chat_ServerPrivateMessage(message.player ,ResponseOnReplace   , false)
            if(ShouldShamePlayer)
                Chat_Impersonate(message.player, ShameMessage, false)
            return message
        }
    
    }
    message.message = AddMessageHighlighting(message.message)
    return message
}

bool function ShouldBlock( entity player, string message )
{
  if( FSU_IsMuted( player.GetUID() ) )
  {
    Chat_ServerPrivateMessage( player, "You are muted!", false )
    return true
  }
  
  if ( !( player.GetUID() in message_cache ) )
    return false
  
  if ( Time() - message_cache[ player.GetUID() ][ message_cache[ player.GetUID() ].len() - 1 ].time < FSU_GetFloat( "FSU_SPAM_MESSAGE_TIME_LIMIT" ) )
  {
    Chat_ServerPrivateMessage( player, "Whoah there! You're sending messages too fast!", false )
    if( player.GetUID() in player_triggers )
      player_triggers[ player.GetUID() ]++
    else
      player_triggers[ player.GetUID() ] <- 0
    
    if( player_triggers[ player.GetUID() ] > int(FSU_GetFloat("FSU_ALLOWED_CHAT_FILTER_TRIGGERS") ) )
    {
      if ( FSU_GetString( "FSU_CHAT_FILTER_TRIGGER_PUNISHMENT" ) == "mute" )
      {
        FSU_Mute( player.GetUID() )
        Chat_ServerPrivateMessage( player, "You were muted for spam!", false )
      }
    }
    return true
  }
  
  
  string longer = message
  string shorter = message_cache[ player.GetUID() ][ message_cache[ player.GetUID() ].len() - 1 ].message
  
  if ( longer.len() < shorter.len() )
  {
    string _temp = longer
    longer = shorter
    shorter = _temp
  }
  
  float sameness = ( longer.len() - LevenshteinDistance( longer, shorter ) ) / longer.len()
  
  
  if ( sameness > FSU_GetFloat( "FSU_SPAM_SIMMILAR_MESSAGE_WEIGHT" ) )
  {
    Chat_ServerPrivateMessage( player, "Message too similar!", false )
    if( player.GetUID() in player_triggers )
      player_triggers[ player.GetUID() ]++
    else
      player_triggers[ player.GetUID() ] <- 0
    
    if( player_triggers[ player.GetUID() ] > int(FSU_GetFloat("FSU_ALLOWED_CHAT_FILTER_TRIGGERS") ) )
    {
      if ( FSU_GetString( "FSU_CHAT_FILTER_TRIGGER_PUNISHMENT" ) == "mute" )
      {
        FSU_Mute( player.GetUID() )
        Chat_ServerPrivateMessage( player, "You were muted for spam!", false )
      }
    }
    return true
  }
  
  return false
}

void function FSU_Mute ( string UID )
{
  if( FSU_IsMuted( UID ) )
    return
  
  muted_players.append( UID )
}

void function FSU_Unmute ( string UID )
{
  if( !FSU_IsMuted( UID ) )
    return
  
  if( UID in player_triggers )
    player_triggers[ UID ] = 0
  
  muted_players.remove( muted_players.find( UID ) )
}

bool function FSU_IsMuted ( string UID )
{
  foreach( player in muted_players )
    if ( player == UID )
      return true
  
  return false
}
// https://www.lemoda.net/c/levenshtein/
float function LevenshteinDistance ( string word1, string word2 )
{
  int len1 = word1.len()
  int len2 = word2.len()
  
  
  // Init the matrix
  array < array < int > > matrix
  for ( int i = 0; i <= len1; i++ )
  {
    matrix.append( [] )
    for ( int j = 0; j <= len2; j++ )
      matrix[i].append( 0 )
  }
  
  int i;
  for (i = 0; i <= len1; i++) {
      matrix[i][0] = i;
  }
  for (i = 0; i <= len2; i++) {
      matrix[0][i] = i;
  }
  for (i = 1; i <= len1; i++) {
      int j;
      var c1;

      c1 = word1[i-1];
      for (j = 1; j <= len2; j++) {
          var c2;

          c2 = word2[j-1];
          if (c1 == c2) {
              matrix[i][j] = matrix[i-1][j-1];
          }
          else {
              int _delete;
              int _insert;
              int substitute;
              int minimum;

              _delete = matrix[i-1][j] + 1;
              _insert = matrix[i][j-1] + 1;
              substitute = matrix[i-1][j-1] + 1;
              minimum = _delete;
              if (_insert < minimum) {
                  minimum = _insert;
              }
              if (substitute < minimum) {
                  minimum = substitute;
              }
              matrix[i][j] = minimum;
          }
      }
  }
  return float ( matrix[len1][len2] ) ;
}


// Append message to cache
void function AppendMessageToCache ( entity player, string message )
{
  messageStruct _temp
  _temp.message = message
  _temp.time = Time()
  
  if ( player.GetUID() in message_cache )
    message_cache[ player.GetUID() ].append ( _temp )
  else
    message_cache[ player.GetUID() ] <- [ _temp ]
  
  if ( message_cache[ player.GetUID() ].len() > 3 )
    message_cache[ player.GetUID() ].remove( 0 )
  
  //print( message_cache[ player ].len() )
  
  //foreach ( string msg in message_cache[ player ] )
    //print( msg )
}

string function GetAmoutOfStars(string word) {
    string reply = ""
    for (int a; a < word.len() ; a++ ) {
     reply = reply + "*"
    }
    return reply
}

bool function StringStartWith(string s, string char){
  if(s.find(char) == 0)
  	return true
  return false
}

bool function isPlayerName(string name) {
  foreach (entity player in GetPlayerArray()) {
    if(player.GetPlayerName().find(name) != null )
      return true
  }
  return false
}
string function ArrayToString(array<string> sarray){
  string message = ""
  foreach (string s in sarray) {
    message = message + s + " "
  }
  return message
}

string function AddMessageHighlighting(string message) {
  int colour = 21 //https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
  array<string> messageArray = split(message , " ")
  foreach(index,string s in messageArray)
    if( StringStartWith(s, "@") ||  isPlayerName(s) ) messageArray = AddHightlighAt(index,messageArray, colour)
  return ArrayToString(messageArray)
}

array<string> function AddHightlighAt(int index,array<string> message, int colour) {
  message[index] = "\x1b[38;5;"+ colour +"m"+ message[index]+ "\x1b[0m"
  return message
}
