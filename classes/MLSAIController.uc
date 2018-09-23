/**
* Represents a custom AI Controller. 
* Doesn't do any decision-making on its own, but leaves that up to behavior objects. 
* Decides how to do something, now what or when. 
*/
class MLSAIController extends AOCAIController
    ClassGroup(MLS)
    implements(IMLSBehaviorListener)
    dependson(AOCPawn)
    dependson(MLSAIBehavior);

/**********
* FIELDS
**********/

/**** BEHAVIOR ****/

// A list of behaviors associated with this AIController. 
var() array<MLSAIBehavior> Behaviors;

// Currently executed behavior. 
var MLSAIBehavior CurrentBehavior;

// Last executed behavior. 
var MLSAIBehavior LastBehavior;

/**** DEBUG ****/

// A list of debug messages to draw. 
var array<String> DebugMessages;

/**** MOVEMENT ****/

// The world location to move to. 
var vector MoveLocation;

/**********
* EVENTS
**********/

/**
* Assigns the given pawn to this controller. 
* @param aPawn - The pawn to possess. 
* @param bVehicleTransition - 
*/
event Possess(Pawn aPawn, bool bVehicleTransition)
{
    super.Possess(aPawn, bVehicleTransition); 
    myPawn = AOCPawn(aPawn);
    myPawn.AddAIListener(self);
    Class'MasonLastStandGame'.static.BroadcastMessage_MLS("MLSAIController: Possessed pawn"@aPawn.GetHumanReadableName(), EFAC_ALL, , true);

    // Make sure the pawn has physics applied and can activate triggers. 
    if(myPawn.Physics == PHYS_None)
    {
        myPawn.SetPhysics(PHYS_Walking);
    }

    myPawn = AOCPawn(aPawn);
    myPawn.bIsBot = true;
    AOCPRI(myPawn.PlayerReplicationInfo).bIsBot = true;

    GotoState('Active',,,false);
}

/**
* Frees the possession of the currently possessed pawn. 
*/
event UnPossess()
{
    Class'MasonLastStandGame'.static.BroadcastMessage_MLS("MLSAIController: Unpossessed pawn"@myPawn.GetHumanReadableName(), EFAC_ALL, , true);
    myPawn = none;
    super(Controller).UnPossess();
}

event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
    super(UDKBot).Touch(Other, OtherComp, HitLocation, HitNormal);
}

/**********
* FUNCTIONS
**********/

/**** BEHAVIOR ****/

/**
* Returns a behavior to currently execute. 
*/
function MLSAIBehavior GetBehaviorToExecute()
{
    local array<MLSAIBehavior> Activatable; // Behaviors whose activation criteria has been met. 
    local MLSAIBehavior Behavior;           // Local var for behaviors. 
    local MLSAIBehavior TopBehavior;        // The behavior to choose as the new behavior to execute. 

    // Start with current behavior. 
    if (CurrentBehavior != none && CurrentBehavior.bBlocking) // Not allowed to switch behavior right now. 
    {
        return CurrentBehavior; // Continue executing current behavior. 
    }

    Activatable = GetActivatable();

    if (Activatable.Length > 0)
    {
        TopBehavior = Activatable[0];
    }

    // Determine new behavior. 
    foreach Activatable(Behavior)
    {
        if (Behavior.Priority > TopBehavior.Priority)
        {
            TopBehavior = Behavior;
        }
    }

    return TopBehavior;
}

/**
* Returns all behaviors whose activation criteria have currently been met. 
* @returns A list of behaviors. 
*/
function array<MLSAIBehavior> GetActivatable()
{
    local array<MLSAIBehavior> Activatable; // List of behaviors to return. 
    local MLSAIBehavior Behavior;           // Local var for behaviors. 

    // Populate list of activatable behaviors. 
    foreach Behaviors(Behavior)
    {
        if (Behavior.CanActivate())
        {
            Activatable.AddItem(Behavior);
        }
    }

    return Activatable;
}

/**
* Determines which behavior to currently execute. 
*/
function EvaluateBehaviorToExecute()
{
    local MLSAIBehavior NewBehavior;

    NewBehavior = GetBehaviorToExecute();

    LastBehavior = CurrentBehavior;
    CurrentBehavior = NewBehavior;
}

/**
* Adds the given behavior, if it isn't already contained. 
* @param NewBehavior - The behavior to add. 
* @returns True, if the behavior could be added. 
*/
function bool AddBehavior(MLSAIBehavior NewBehavior)
{
    local bool AlreadyContained;
    local MLSAIBehavior Behavior;

    // Determine if the given behavior is already contained. 
    foreach Behaviors(Behavior)
    {
        if (Behavior == NewBehavior)
        {
            AlreadyContained = true;
            break;
        }
    }

    if (!AlreadyContained) // The given behavior can be safely added. 
    {
        Behaviors.AddItem(NewBehavior);
        NewBehavior.myController = self;
        NewBehavior.Listeners.AddItem(self);
        // TODO: MED - attach to IAOCAIListener related list of pawns?
    }

    if (!IsInState('Active'))
    {
        Activate();
    }

    return AlreadyContained;
}

/**
* Removes the given behavior. 
* @param Behavior - The behavior to remove. 
*/
function RemoveBehavior(MLSAIBehavior Behavior)
{
    Behaviors.RemoveItem(Behavior);
    Behavior.myController = none;
    Behavior.Listeners.RemoveItem(self);

    if (Behavior == CurrentBehavior)
    {
        CurrentBehavior = none;
    }

    if (Behaviors.Length == 0 && !IsInState('Inactive'))
    {
        Class'MasonLastStandGame'.static.BroadcastMessage_MLS("MLSAIController: No more behaviors to activate for pawn:"@myPawn.GetHumanReadableName(), EFAC_ALL, , true);
        Deactivate();
    }

    // TODO: MED - deattach from IAOCAIListener related list of pawns?
}

/**
* Removes all behaviors. 
*/
function ClearBehaviors()
{
    local int i;
    local MLSAIBehavior Behavior;

    for (i = Behaviors.Length - 1; i >= 0; i--)
    {
        Behavior = Behaviors[i];
        RemoveBehavior(Behavior);
    }
}

/**
* To be called by a behavior, upon its completion. 
* Will remove the behavior if it is set to auto expire. 
*/
function NotifyBehaviorCompleted(MLSAIBehavior Behavior)
{
    Class'MasonLastStandGame'.static.BroadcastMessage_MLS("NOTIFIED: Completed behavior:"@Behavior.myName, EFAC_ALL, , true);
    if (Behavior.bAutoExpires)
    {
        Class'MasonLastStandGame'.static.BroadcastMessage_MLS("NOTIFIED: Removing behavior:"@Behavior.myName, EFAC_ALL, , true);
        Behaviors.RemoveItem(Behavior);
    }
}

/**
* To be called by a behavior, upon it experiencing an error. 
*/
function NotifyBehaviorError(MLSAIBehavior Behavior)
{
    // Nothing yet. 
}

/**
* To be called by a behavior, upon it being activated. 
*/
function NotifyBehaviorActivated(MLSAIBehavior Behavior)
{
    // Nothing yet. 
}

/**
* To be called by a behavior, upon it being deactivated. 
*/
function NotifyBehaviorDeactivated(MLSAIBehavior Behavior)
{
    // Nothing yet. 
}

/**** PATHING ****/

/**
* Handles finding a path to the given actor. 
* @param Goal - The actor to find a path to. 
* @param WithinDistance - Distance to the target location the pawn has to be within in order to consider the goal as reached. 
* @param bAllowPartialPath - If true, allows an incomplete path to be found. The target location might not actually be reachable. 
* @returns True, if a path could be found. 
*/
function bool FindPathToActor(Actor Goal, out Actor NavPoint, optional float WithinDistance = 10.0f, optional bool bAllowPartialPath)
{
    return FindPathToWrapper(NavPoint, Goal, , WithinDistance, bAllowPartialPath);
}

/**
* Handles finding a path to the given point. 
* @param Goal - The point to find a path to. 
* @param NavPoint - If a path network path was found, this is the first (last?) NavigationPoint of the path. 
* @param WithinDistance - Distance to the target location the pawn has to be within in order to consider the goal as reached. 
* @param bAllowPartialPath - If true, allows an incomplete path to be found. The target location might not actually be reachable. 
* @returns True, if a path could be found. 
*/
function bool FindPathToPoint(Vector Goal, out Actor NavPoint, optional float WithinDistance = 10.0f, optional bool bAllowPartialPath)
{
    return FindPathToWrapper(NavPoint, , Goal, WithinDistance, bAllowPartialPath);
}

/**
* Handles finding a path. 
* NOTE: Intended for internal use only! 
* @param NavPoint - If a path network path was found, this is the first (last?) NavigationPoint of the path. 
* @param GoalActor - Optional. An actor to path find to. 
* @param GoalPoint - Optional. A point to path find to. 
* @param WithinDistance - Optional. Distance to the target location the pawn has to be within in order to consider the goal as reached. 
* @param bAllowPartialPath - Optional. If true, allows an incomplete path to be found. The target location might not actually be reachable. 
* @returns True, if a path could be found. 
*/
function bool FindPathToWrapper(
    out Actor NavPoint, 
    optional Actor GoalActor = none, 
    optional Vector GoalPoint = vect(0,0,0), 
    optional float WithinDistance = 10.0f, 
    optional bool bAllowPartialPath
    )
{
    local bool  FoundPath;  // Is true, if a path could be found. 
    NavPoint = none;

    if (NavigationHandle == none)
        return false;

    // Clear previous constraints and goals. 
    NavigationHandle.ClearConstraints();

    if (bPrioritizeNavmesh)
    {
        if (GoalActor != none)
            FoundPath = FindPath_NavMesh_ToActor(GoalActor, WithinDistance, bAllowPartialPath);
        else
            FoundPath = FindPath_NavMesh_ToPoint(GoalPoint, WithinDistance, bAllowPartialPath);
    }
    else
    {
        if (GoalActor != none)
            NavPoint = FindPath_Network_ToActor(GoalActor, , , bAllowPartialPath);
        else
            NavPoint = FindPath_Network_ToPoint(GoalPoint, , bAllowPartialPath);

        if (NavPoint != none)
        {
            FoundPath = true;
        }
    }
    
    // Fall back to other pathing method. 
    if (!FoundPath) // Path not found using preferred method. 
    {
        if (bPrioritizeNavmesh)
        {
            if (GoalActor != none)
                NavPoint = FindPath_Network_ToActor(GoalActor, , , bAllowPartialPath);
            else
                NavPoint = FindPath_Network_ToPoint(GoalPoint, , bAllowPartialPath);

            if (NavPoint != none)
            {
                FoundPath = true;
            }
        }
        else
        {
            if (GoalActor != none)
                FoundPath = FindPath_NavMesh_ToActor(GoalActor, WithinDistance, bAllowPartialPath);
            else
                FoundPath = FindPath_NavMesh_ToPoint(GoalPoint, WithinDistance, bAllowPartialPath);
        }
    }

    return FoundPath;
}

/**
* Finds a path to the given point via nav mesh navigation. 
* @param Goal - The point to find a path to. 
* @param WithinDistance - Distance to the target location the pawn has to be within in order to consider the goal as reached. 
* @param bAllowPartialPath - If true, allows an incomplete path to be found. The target location might not actually be reachable. 
* @returns True, if a path could be found. 
*/
function bool FindPath_NavMesh_ToPoint(Vector Goal, optional float WithinDistance = 10.0f, optional bool bAllowPartialPath)
{
    class'NavMeshPath_Toward'.static.TowardPoint(NavigationHandle, Goal);
    class'NavMeshGoal_At'.static.AtLocation(NavigationHandle, Goal, WithinDistance, bAllowPartialPath);
    return NavigationHandle.FindPath();
}

/**
* Finds a path to the given actor via nav mesh navigation. 
* @param Goal - The actor to find a path to. 
* @param WithinDistance - Distance to the target location the pawn has to be within in order to consider the goal as reached. 
* @param bAllowPartialPath - If true, allows an incomplete path to be found. The target location might not actually be reachable. 
* @returns True, if a path could be found. 
*/
function bool FindPath_NavMesh_ToActor(Actor Goal, optional float WithinDistance = 10.0f, optional bool bAllowPartialPath)
{
    class'NavMeshPath_Toward'.static.TowardGoal(NavigationHandle, Goal);
    class'NavMeshGoal_At'.static.AtActor(NavigationHandle, Goal, WithinDistance, bAllowPartialPath);
    return NavigationHandle.FindPath();
}

/**
* Finds a path to the given point via path network navigation. 
* @param Goal - The point to find a path to. 
* @param MaxPathLength - 
* @param bAllowPartialPath - If true, allows an incomplete path to be found. The target location might not actually be reachable. 
* @returns True, if a path could be found. 
*/
function Actor FindPath_Network_ToPoint(Vector Goal, optional int MaxPathLength, optional bool bAllowPartialPath)
{
    return FindPathTo(Goal, MaxPathLength, bAllowPartialPath);
}

/**
* Finds a path to the given actor via path network navigation. 
* @param Goal - The actor to find a path to. 
* @param bWeightDetours - 
* @param MaxPathLength - 
* @param bAllowPartialPath - If true, allows an incomplete path to be found. The target location might not actually be reachable. 
* @returns True, if a path could be found. 
*/
function Actor FindPath_Network_ToActor(Actor Goal, optional bool bWeightDetours, optional int MaxPathLength, optional bool bAllowPartialPath)
{
    return FindPathToward(Goal, bWeightDetours, MaxPathLength, bAllowPartialPath);
}

/**
* Returns a randomly picked location within the given radius around the given point. 
* Requires that PathNodes be placed in the radius around the point in the level editor. 
* @param Point - The location around which to pick a random location. 
* @param Radius - The radius around the point within which to pick a random location. Values below 1 are ignored. 
*/
function vector GetRandomLocation(vector Point, float Radius)
{
    local vector RandomLocation;            // The randomly chosen location. 
    local array<Actor> PossibleLocations;   // A list of locations that can be chosen from. 
    local PathNode PossibleLocation;        // For iterating possible locations. 
    local vector DirToLocation;
    local float DistToLocation;
    local int RandomChosen;                 // Random index of location to return. 

    RandomLocation = Point;
    Radius = FMin(Radius, 1.f);

    // Get all possible locations. 
    foreach AllActors(Class'PathNode', PossibleLocation)
    {
        DirToLocation = Point - PossibleLocation.Location;
        DistToLocation = VSize(DirToLocation);

        if (DistToLocation <= Radius)
        {
            PossibleLocations.AddItem(PossibleLocation);
        }
    }

    // Choose random location. 
    if (PossibleLocations.Length > 0) // Got at least one location to choose from. 
    {
        RandomChosen = Round(FRand() * PossibleLocations.Length);
        RandomLocation = PossibleLocations[RandomChosen].Location;
    }

    return RandomLocation;
}

/**** DEBUG ****/

/**
* Adds the given string to the debug message buffer to be displayed in the next display interval. 
*/
function AddDebugMessage(String Message)
{
    DebugMessages.AddItem(Message);
}

/**
* Displays all the messages contained in the list of debug messages. 
* @param Duration - Dutation, in seconds, to display the messages. 
*/
function DrawDebugMessages(optional float Duration = 3.f)
{
    local int VerticalOffset;   // Incrementing vertical offset to add to messages. 
    local String Message;       // Current message to display. 
    local int i;                // Iterator. 

    VerticalOffset = 1;

    // Draw messages. 
    foreach DebugMessages(Message)
    {
        if(Class'MasonLastStandGame'.static.AllowDebugMessages())
        {
            DrawDebugMessageTimed(Message, VerticalOffset, Duration); // TODO: MED - Bugged, figure out fix. 
            VerticalOffset++;
        }
    }

    // Clear list of messages. 
    for (i = DebugMessages.Length; i >= 0; i--)
    {
        Message = DebugMessages[i];
        DebugMessages.RemoveItem(Message);
    }
}

/**
* Draws a short-lived debugging message at the pawn location. 
* @param Message - The message to display. 
* @param Height - An additional height offset for the location of the message. 
* @param Duration - Dutation, in seconds, to display the message. 
*/
function DrawDebugMessageTimed(String Message, optional int Height = 1, optional float Duration = 3.f)
{
    local PlayerController PC;
    local color MessageColor;

    if(!Class'MasonLastStandGame'.static.AllowDebugMessages())
        return;

    MessageColor.A = 255;
    MessageColor.B = 117;
    MessageColor.G = 117;
    MessageColor.R = 220;

    foreach WorldInfo.LocalPlayerControllers(class'PlayerController', PC)
    {
        PC.AddDebugText(
            Message, 
            myPawn, 
            Duration, 
            myPawn.Location + (vect(0,0,15) * Height), 
            myPawn.Location + (vect(0,0,15) * Height), 
            MessageColor, 
            true, 
            true, 
            true
        );
    }
}

/**** PAWNS ****/

/**
* Returns true, if the given pawn and the owned pawn are on the same team. 
* @param aPawn - The pawn to check whether they're an ally. 
* @returns True, if the given pawn is an ally. 
*/
function bool IsAllyPawn(AOCPawn aPawn)
{

    if (myPawn.PawnFamily.FamilyFaction == aPawn.PawnFamily.FamilyFaction)
    {
        return true;
    }
    else
    {
        return false;
    }
}

/**
* Returns all enemy pawns in the given range around the owned pawn. 
* Doesn't currently consider "neutral" factions. 
* @param Radius - A radius around the owned pawn. Values of 0 or less mean infinite range (return all). 
*/
function array<AOCPawn> GetEnemiesInRange(float Radius)
{
    local array<AOCPawn> Pawns;
    local array<AOCPawn> Enemies;
    local AOCPawn aPawn;
    
    Pawns = GetPawnsInRange(Radius);

    foreach Pawns(aPawn)
    {
        if (IsAllyPawn(aPawn))
        {
            continue;
        }

        Enemies.AddItem(aPawn);
    }

    return Enemies;
}

/**
* Returns all pawns in the given radius around the owned pawn. 
* @param Radius - A radius around the owned pawn. Values of 0 or less mean infinite range (return all). 
*/
function array<AOCPawn> GetPawnsInRange(float Radius)
{
    local array<AOCPawn> Pawns;
    local vector DirToOther;
    local float DistToOther;
    local AOCPawn Other;

    foreach Worldinfo.AllPawns(class'AOCPawn', Other) // TODO: HI - Also returns dead pawns?
    {
        if (Other == none || Other == myPawn || !Other.IsAliveAndWell())
        {
            continue;
        }

        if (Radius <= 0)
        {
            Pawns.AddItem(Other);
            continue;
        }

        DirToOther =  myPawn.Location - Other.Location;
        DistToOther = VSize(DirToOther);

        if (DistToOther <= Radius)
        {
            Pawns.AddItem(Other);
        }
    }

    return Pawns;
}

/**
* Returns true, if the given pawn is facing the possessed pawn. 
* @param Other - The pawn to check whether it is facing the possessed pawn. 
*/
function bool FacedByPawn(AOCPawn Other)
{
    local rotator OtherRot;
    local vector DirToOther;

    DirToOther = myPawn.Location - Other.Location;
    OtherRot = Other.GetViewRotation();

    return Vector(OtherRot) dot Normal(DirToOther) >= 0.81f;
}

/**** COMBAT ****/

/**
* Plays out a battlecry for the pawn, if possible. 
*/
function PerformBattlecry()
{
    myPawn.PlayBattleCry(1);
}

/**
* Equips the weapon in the given slot. 
* @param NewGroup - The weapon slot to equip. Can be either 1, 2, 3 or 4. 
* @param EquipShield - Whether to equip a shield, if the pawn has one. Defaults to true. 
*/
function Equip(byte NewGroup, optional bool EquipShield = true)
{
    local bool bHasShield;
    local bool bShieldEquipped;

    myPawn.SwitchWeapon(NewGroup);

    // Equip shield, if desired. 
    if (EquipShield)
    {
        bHasShield = class<AOCWeapon_Shield>(myPawn.TertiaryWeapon) != none;
        bShieldEquipped = myPawn.StateVariables.bShieldEquipped;

        if (bHasShield && !bShieldEquipped) // Shield is not currently equipped, but equippable. 
        {
            myPawn.SwitchWeapon(3);
        }
    }
}

/**
* Ensures the pawn has their primary weapon and potentially their shield in hand. 
*/
function EquipPrimary()
{
    Equip(1, true);
}

/**
* Ensures the pawn has their secondary weapon and potentially their shield in hand. 
*/
function EquipSecondary()
{
    Equip(2, true);
}

/**
* Causes the pawn to lower their shield, both on server and client. 
*/
function DoLowerShield()
{
    if (myPawn.IsAliveAndWell()) // TODO: LO - Necessary?
    {
        ClientDoLowerShield();
        ServerDoLowerShield();
    }
}

/**
* Causes the pawn to lower their shield on the client. 
*/
reliable client function ClientDoLowerShield()
{
    AOCWeapon(myPawn.Weapon).LowerShield();
}

/**
* Causes the pawn to lower their shield on the server. 
*/
reliable server function ServerDoLowerShield()
{
    if (WorldInfo.NetMode != NM_STANDALONE && Worldinfo.NetMode != NM_ListenServer)
        AOCWeapon(myPawn.Weapon).LowerShield();
}

/**
* Causes the pawn to parry or raise their shield. 
* Will automatically lower their shield about a second later. 
*/
function DoParry()
{                   
    myPawn.StartFire(Attack_Parry);
    if(myPawn.StateVariables.bShieldEquipped)
    {
        ClearTimer('DoLowerShield');
        SetTimer(1.0, false, 'DoLowerShield');
    }
}

/**
* Causes the pawn to feint, if possible. 
*/
function DoFeint()
{
    if(myPawn.Weapon.IsInState('Windup')
        && (AOCWeapon(myPawn.Weapon).bCanFeint 
            && myPawn.HasEnoughStamina(AOCWeapon(myPawn.Weapon).iFeintStaminaCost) 
            && AOCWeapon(myPawn.Weapon).CurrentFireMode != Attack_Shove 
            && AOCWeapon(myPawn.Weapon).CurrentFireMode != Attack_Sprint))
    {
        AOCWeapon(myPawn.Weapon).DoFeintAttack();
    }
}


/**********
* STATES
**********/

/**
* Transitions to the Inactive state. 
*/
function Deactivate()
{
    Class'MasonLastStandGame'.static.BroadcastMessage_MLS("MLSAIController: deactivated:"@myPawn.GetHumanReadableName(), EFAC_ALL, , true);
    GotoState('Inactive');
}

/**
* Transitions to the Active state. 
*/
function Activate()
{
    Class'MasonLastStandGame'.static.BroadcastMessage_MLS("MLSAIController: activated:"@myPawn.GetHumanReadableName(), EFAC_ALL, , true);
    GotoState('Active');
}

/**
* Active state, evaluating and executing behaviors. 
*/
auto state Active
{
    /**
    * Causes a re-evaluation and potential update of the currently executed behavior. 
    */
    function UpdateBehavior()
    {
        EvaluateBehaviorToExecute();

        if (CurrentBehavior == none)
        {
            LastBehavior.Deactivate();
        }
        else if (CurrentBehavior != LastBehavior)
        {
            Class'MasonLastStandGame'.static.BroadcastMessage_MLS("MLSAIController: Activating behavior:"@CurrentBehavior.myName@"for pawn:"@myPawn.GetHumanReadableName(), EFAC_ALL, , true);
            AddDebugMessage("Activating behavior:"@CurrentBehavior.myName);

            LastBehavior.Deactivate();
            CurrentBehavior.Activate();
        }
    }

    /**
    * Checks whether the possessed pawn is alive and well. If not, unpossesses the pawn and destroys self. 
    */
    function CheckAlive()
    {
        if (!myPawn.IsAliveAndWell())
        {
            UnPossess();
        }
    }
Begin:
    if(Pawn.Physics != PHYS_Falling)
    {
        Pawn.ZeroMovementVariables();
    }
    SetTimer(0.5f, true, 'UpdateBehavior');
    SetTimer(0.5f, true, 'CheckAlive');
    // SetTimer(0.1f, true, 'DrawDebugMessages'); // TODO: LO - Doesn't work for some reason?
}

/**
* Inactive state, executing no logic. 
*/
state Inactive
{
Begin:
    // Do nothing.
}

/**
* Pawn died state, to unpossess and clean up. 
*/
state Dead
{
    function PawnDied(Pawn P)
    {
        super(Controller).PawnDied(P);
    }
Begin:
    Class'MasonLastStandGame'.static.BroadcastMessage_MLS("MLSAIController: Pawn died", EFAC_ALL, , true);
}

DefaultProperties
{
    bPrioritizeNavmesh=true
    bReplicateMovement=true
    CustomizationClass=class'AOCCustomization'
}