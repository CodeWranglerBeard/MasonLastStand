class MasonLastStandGame extends CMWTO2
    notplaceable;

static event class<GameInfo> SetGameType(string MapName, string Options, string Portal)
{
    return default.class; //returns this object's own class, so this class is setting itself to be the game type used
}

/**
* Broadcasts a given message to all members of the given team. 
* Serves as a work-around for message broadcasting not working by default. 
* @param Message - A string representing the message to broadcast. 
* @param DesignatedTeam - The team to broadcast the message to. 
* @param Sender - Optional. A PlayerController to associate the sent message with. 
* @param bSystemMessage - Optional. Indicates whether to treat the message as a system message. 
* @param bUseCustomColor - Optional. Whether to use a custom color. 
* @param Col - Optional. A color in the color code format '#RRGGBB'. 
*/
static function BroadcastMessage_MLS(string Message, EAOCFaction DesignatedTeam, 
optional PlayerController Sender = none, optional bool bSystemMessage = false, optional bool bUseCustomColor = false, optional string Col)
{
    local AOCGame Game;

    if (!AllowDebugMessages())
        return;

    Game = AOCGame((class'Worldinfo'.static.GetWorldInfo()).Game);
    Game.BroadcastMessage(Sender, Message, DesignatedTeam, bSystemMessage, bUseCustomColor, Col);

    // AOCGame(GetWorldInfo().Game).BroadcastMessage(none, 'Message', EFAC_ALL, true); // <- GetWorldInfo() is unknown?!
}

/**
* Returns a bool indicating whether to allow debug messages being displayed. 
* TODO: LO - Change to false for production environment. 
*/
static function bool AllowDebugMessages()
{
    return true;
}

defaultproperties
{
    //This is the name that shows in the server browser for this mod:
    ModDisplayString="Horde: Mason's Last Stand"
}