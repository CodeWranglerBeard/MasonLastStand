/**
* Represents a kismet node to store and restore a pawn's weapon loadout. 
*/
class MLSSeqAction_StoreLoadout extends SequenceAction
    dependson(AOCPawn)
    dependson(AOCGame)
    dependson(MLSControllerAndLoadout);

var array<MLSControllerAndLoadout> Loadouts;

event Activated()
{
    local array<Object> ObjVars;
    local Object Obj;
    local AOCPawn P;

    if(CMWTO2(GetWorldInfo().Game) != none)
    {
        GetObjectVars(ObjVars, "Pawn(s)");
        foreach ObjVars(Obj)
        {
            P = AOCPawn(GetPawn(Actor(Obj)));

            if (InputLinks[0].bHasImpulse)
            {
                GetLoadout(P);
            }
            else if (InputLinks[1].bHasImpulse)
            {
                RestoreLoadout(P);
            }
        }
    }
    
    ForceActivateOutput(0);
}

/**
* Retrieves and stores the given AOCPawn's weapon loadout. 
*/
function GetLoadout(AOCPawn P)
{
    local MLSControllerAndLoadout Loadout;

    if (P != none)
    {
        Loadout = GetLoadoutEntry(P.Controller);

        if (Loadout != none)
        {
            Loadout.Primary = P.PawnInfo.myPrimary;
            Loadout.Secondary = P.PawnInfo.mySecondary;
            Loadout.Tertiary = P.PawnInfo.myTertiary;
        }
        else
        {
            Loadout = new class'MLSControllerAndLoadout';

            Loadout.ControllerInstance = P.Controller;
            Loadout.Primary = P.PawnInfo.myPrimary;
            Loadout.Secondary = P.PawnInfo.mySecondary;
            Loadout.Tertiary = P.PawnInfo.myTertiary;
            Loadouts.AddItem(Loadout);
        }
    }
}

/**
* Restores the given AOCPawn's weapon loadout. 
*/
function RestoreLoadout(AOCPawn P)
{
    local MLSControllerAndLoadout Loadout;

    if (P != none)
    {
        Loadout = GetLoadoutEntry(P.Controller);

        if (Loadout != none)
        {
            P.PawnInfo.myPrimary = Loadout.Primary;
            P.PawnInfo.myAlternatePrimary = Loadout.Primary.default.AlternativeMode;
            P.PawnInfo.mySecondary = Loadout.Secondary;
            P.PawnInfo.myTertiary = Loadout.Tertiary;
            AOCGame(GetWorldInfo().Game).AddDefaultInventory(P);
            P.ReplicatedEvent('PawnInfo');
        }
    }

}

/**
* Returns a stored entry for the given Controller, or none, if no loadout is stored. 
*/
function MLSControllerAndLoadout GetLoadoutEntry(Controller C)
{
    local MLSControllerAndLoadout Loadout;

    if (C != none)
    {
        foreach Loadouts(Loadout)
        {
            if (Loadout.ControllerInstance == C)
            {
                return Loadout;
            }
        }
    }
    else
    {
        return none;
    }
}

DefaultProperties
{
    InputLinks(0)=(LinkDesc="Store")
    InputLinks(1)=(LinkDesc="Restore")
    OutputLinks(0)=(LinkDesc="Out")
    VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Pawn(s)")
    
    bAutoActivateOutputLinks = false
    
    ObjName="ReStore Loadout"
    ObjCategory="MLS Actions"
    bCallHandler=false
}