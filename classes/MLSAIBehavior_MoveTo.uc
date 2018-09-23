/**
* Represents a behavior for an NPC to get close to an actor or a location. 
*/
class MLSAIBehavior_MoveTo extends MLSAIBehavior
    ClassGroup(MLS)
    placeable;

/**********
* FIELDS
**********/

/**** MOVEMENT_SETTINGS ****/

// The goal will be considered completed if the NPC is within this distance to the destination. 
var() float DistanceTolerance;

// Should the NPC be allowed to sprint to the destination?
var() bool bSprint;

/**
* This is the distance to the destination that the pawn must be above in order to allow sprinting. 
* If <= 0, will always sprint. 
*/
var() float SprintThreshold;

/**
* The behavior will only activate if the destination is within the given radius of the behavior owning pawn. 
* <=0 for no limit. 
*/
var() float ActivationRadius;

// The destination actor to move to. Takes precedence over a point to move to. 
var() Actor MoveActor;

// The destination point to move to. 
var() vector MoveLocation;

// If true, forces the pawn to look at either the given look location or look actor. 
var() bool bOverrideLookLocation;

// Optional, an actor to be facing. Takes precedence over a point to look at. 
var() Actor LookActor;

// Optional, a point to be facing. 
var() vector LookLocation;

/**
* If true, the pawn will go to a randomly picked location inside the random radius around the destination. 
* Requires that PathNodes be placed in the random radius around the destination in the level editor. 
*/
var() bool bRandomLocation;

// If RandomLocation is true, this is the radius around the destination within which to find a random location to move to. 
var() float RandomRadius;

/**** MOVEMENT_STUCK_DETECTION ****/
/**
* The distance threshold to re-evaluate a path to the destination. 
* If the destination moved from its original location by this margin, will cause a new path to be evaluated. 
*/
var float ReevaluationThreshold;

// The maximum number of times the pawn is allowed to be in the same spot until considered stuck. 
const MAX_SAME_TEMPDEST = 3;
// The current number of times the pawn is found to not have moved from the same spot. 
var int mySameTempDestCount;

/**********
* FUNCTIONS
**********/

/**
* Returns true, the destination is within the activation radius of the behavior. 
* @returns True, if the destination is contained. 
*/
function bool IsInRadius()
{
    local vector Dir;
    local float Dist;

    if (myController.myPawn == none)
    {
        return false;
    }
    if (ActivationRadius <= 0)
    {
        return true;
    }

    Dir = myController.myPawn.Location - GetMoveLocation();
    Dist = VSize(Dir);

    if (Dist <= ActivationRadius) {
        return true;
    }
    else
    {
        return false;
    }
}

/**
* Returns true, if the behavior can be activated. 
* @returns True, if the behavior can be activated. 
*/
function bool CanActivate()
{
    if (IsInRadius())
        return true;

    return false;
}

/**
* Returns the location to move to. 
* If a destination actor is set, returns its location, otherwise returns the destination point. 
*/
function vector GetMoveLocation()
{
    return (MoveActor != none) ? MoveActor.Location : MoveLocation;
}

/**
* Returns the location to look at. 
* If a look actor is set, returns its location, otherwise returns the look point. 
*/
function vector GetLookLocation()
{
    return (LookActor != none) ? LookActor.Location : LookLocation;
}

/**
* Active state, executes movement logic. 
* Checks if the pawn is stuck, has gone off the predetermined path or if the destination location has changed. 
*/
state Active
{
    local AOCPawn   myPawn;                 // The pawn to work with. 
    local vector    Dir;                    // Direction vector to destination. 
    local float     Dist;                   // Distance to destination. 
    local vector    CurrentDir;             // Direction current (/ next) destination (along current path). 
    local float     CurrentDist;            // Distance to current (/ next) destination (along current path). 
    local Actor     NavPoint;               // Current move destination. 
    local vector    MoveLocationCurrent;    // The current location to move to. 
    local vector    MoveLocationFinal;      // The actual move location to move to. 
    local vector    MoveLocationLast;       // The point the destination was last situated at. 
    local vector    PawnLocationLast;       // The last location the pawn was at. Used to detect whether the pawn got stuck. 
    local bool      PathFound;              // Is true, if a path could be found. 
    local bool      IsNavMeshPath;          // Is true, if the found path utilizes the nav mesh system. 
    local bool      HasNextDest;            // Is true, for as long as there is another destination along the path to traverse. 

    /**
    * Handles the situation of the pawn being stuck. 
    * Returns true, if the pawn has not moved from the same spot for a prolonged period of time, 
    * while actually expected to be moving. 
    */
    function bool HandleIfStuck()
    {
        local float StuckDist; // The distance the pawn has moved since the last call of this function. 

        StuckDist = VSize(myPawn.Location - PawnLocationLast);
        PawnLocationLast = myPawn.Location;

        if (StuckDist <= 10.0f)
        {
            mySameTempDestCount += 1;
            if (mySameTempDestCount > MAX_SAME_TEMPDEST)
            {
                // TODO: MED - Implement state.
                // PushState('Unstick'); // Navigate around obstacle. 
                myController.DrawDebugMessageTimed("Stuck!", 4);
                return true;
            }
        }
        else
        {   
            mySameTempDestCount = 0;
            return false;
        }
    }

    /**
    * Handles the situation of the move location having changed significantly. 
    * Returns true, if the move location has changed significantly. 
    */
    function bool HandleIfDestinationMoved()
    {
        local float MovedDist;              // The distance the location has moved since the last call of this function. 
        local vector MoveLocationDefined;   // The move location set (in the editor or through kismet or through script) to move to. 

        MoveLocationDefined = GetMoveLocation();
        MovedDist = VSize(MoveLocationDefined - MoveLocationLast);
        MoveLocationLast = MoveLocationDefined;

        if (MovedDist >= ReevaluationThreshold)
        {
            myController.DrawDebugMessageTimed("Destination has moved! Re-evaluating path", 4);
            DetermineNewActualLocation(); // Figure out where the move location is now. 
            DeterminePath();             // Re-evaluate path. 
            SetPawnMovement();      // Make sure the pawn has physics and is sprinting, if possible. 
            return true;
        }
        else
        {
            return false;
        }
    }

    /**
    * Returns true, if the move location has been reached. 
    */
    function bool ReachedDestination()
    {
        return (Dist <= DistanceTolerance);
    }

    /**
    * Sets the timers for handling if the pawn is stuck or the move location has moved. 
    */
    function BeginTimers()
    {
        SetTimer(1.f, true, 'HandleIfStuck');
        SetTimer(1.f, true, 'HandleIfDestinationMoved');
    }

    /**
    * Clears the timers for handling if the pawn is stuck or the move location has moved. 
    */
    function ClearTimers()
    {
        ClearTimer('HandleIfStuck');
        ClearTimer('HandleIfDestinationMoved');
    }

    /**
    * Sets up a new location to actually move to. 
    * In case of no random location choosing, will be exactly the same as the set move location. 
    * In case of random location choosing, will be a randomly chosen PathNode location inside a radius around 
    * the set move location. 
    */
    function DetermineNewActualLocation()
    {
        local vector MoveLocationDefined; // The move location set (in the editor or through kismet or through script) to move to. 

        MoveLocationDefined = GetMoveLocation();
        MoveLocationFinal = bRandomLocation ? myController.GetRandomLocation(MoveLocationDefined, RandomRadius) : MoveLocationDefined;
        MoveLocationLast = MoveLocationFinal;

        Dir =  myPawn.Location - MoveLocationFinal;
        Dist = VSize(Dir);
    }

    /**
    * Evaluates the path to the destination. 
    */
    function DeterminePath()
    {
        // Find path and determine location to move to. 
        if (MoveActor != none && !bRandomLocation) // Move to an actor. 
        {
            PathFound = myController.FindPathToActor(MoveActor, NavPoint, myPawn.GetCollisionRadius(), true);
        }
        else // Move to a (random) location. 
        {
            PathFound = myController.FindPathToPoint(MoveLocationFinal, NavPoint, myPawn.GetCollisionRadius(), true);
        }

        if (PathFound)
        {
            Class'MasonLastStandGame'.static.BroadcastMessage_MLS(myName$": Found path", EFAC_ALL, , true);
            myController.DrawDebugMessageTimed("Found path!", 2);
            HasNextDest = true; // Assume that a next destination initially exists. 

            if (NavPoint != none) // Received a NavigationPoint? -> Using network path system. 
            {
                MoveLocationCurrent = NavPoint.Location;
                IsNavMeshPath = false;
            }
            else
            {
                IsNavMeshPath = true;
            }
            Class'MasonLastStandGame'.static.BroadcastMessage_MLS(myName$": Nav mesh path:"@IsNavMeshPath, EFAC_ALL, , true);
        }
        else
        {
            Class'MasonLastStandGame'.static.BroadcastMessage_MLS(myName$": Could not find path", EFAC_ALL, , true);
            myController.DrawDebugMessageTimed("Could not find path!", 2);
            GoToState('Error');
        }
    }

    /**
    * Determines and applies the current look location. 
    */
    function DetermineLookLocation()
    {
        if (bOverrideLookLocation)
        {
            if (LookActor != none)
            {
                myController.FocusOnActor(LookActor);
            }
            else
            {
                myController.FocusOnLocation(LookLocation);
            }
        }
        else
        {
            if (IsNavMeshPath) // TODO: LO - Distinction unnecessary?
            {
                if(myPawn.bIsCrouching)
                {
                    myController.FocusOnLocation(MoveLocationCurrent + (vect(0,0,1) * (myPawn.BaseEyeHeight / 3.f)));
                }
                else
                {
                    myController.FocusOnLocation(MoveLocationCurrent + (vect(0,0,1) * myPawn.BaseEyeHeight));
                }
            }
            else
            {
                myController.FocusOnActor(NavPoint);
            }
        }
    }

    /**
    * Sets the physics and sprinting mode of the pawn. 
    */
    function SetPawnMovement()
    {
        if(myPawn.Physics == PHYS_None)
        {
            myPawn.SetPhysics(PHYS_Walking);
        }

        // Make the pawn sprint, if possible. 
        if (bSprint && (SprintThreshold <= 0 || Dist >= SprintThreshold))
        {
            Class'MasonLastStandGame'.static.BroadcastMessage_MLS(myName$": Sprinting", EFAC_ALL, , true);
            myController.DrawDebugMessageTimed("Sprinting", 4);
            myPawn.ServerSprintState(true);
        }
        else
        {
            Class'MasonLastStandGame'.static.BroadcastMessage_MLS(myName$": Walking", EFAC_ALL, , true);
            myController.DrawDebugMessageTimed("Walking", 4);
            myPawn.ServerSprintState(false);
        }
    }

    /**
    * Determines initial variable set up and sets up timers. 
    */
    function SetUp()
    {
        myPawn = myController.myPawn;
        DetermineNewActualLocation();
        DeterminePath();                // Evaluate path. 
        SetPawnMovement();              // Make sure the pawn has physics and is sprinting, if possible. 
        BeginTimers();
    }

    /**
    * Handles clean up when the behavior is canceled or paused. 
    */
    function CleanUp()
    {
        ClearTimers();
        myPawn.ServerSprintState(false);
        myController.FocusOnLocation(myPawn.Location + (20.0f * myPawn.GetForwardDirection()) + (vect(0,0,1) * myPawn.BaseEyeHeight));

        if(myPawn.Physics != PHYS_Falling)
        {
            myPawn.ZeroMovementVariables();
        }
    }

    /***********
    * Set up events
    ***********/
    event BeginState(Name PreviousStateName)
    {       
        super.BeginState(PreviousStateName);
        SetUp();
    }
    event PushedState()
    {
        super.PushedState();
        SetUp();
    }
    event ContinuedState()
    {
        super.ContinuedState();
        SetUp();
    }

    /***********
    * Clean up events
    ***********/
    event PausedState()
    {       
        super.PausedState();
        CleanUp();
    }
    event EndState(Name NextStateName)
    {
        super.EndState(NextStateName);
        CleanUp();
    }
    event PoppedState()
    {
        super.PoppedState();
        CleanUp();
    }
Begin:
    // Follow path, loop for as long as the destination location has not been reached. 
    while (true)
    {
        // Check if the move location has been reached. 
        Dir =  myPawn.Location - MoveLocationFinal;
        Dist = VSize(Dir);

        if (ReachedDestination()) // Reached move location. 
        {
            GoToState('PreCompleted');
            break;
        }
        else if(!HasNextDest) // No more intermediate destinations -> Error while pathing?
        {
            Class'MasonLastStandGame'.static.BroadcastMessage_MLS(myName$": No more intermediate destinations", EFAC_ALL, , true);
            myController.DrawDebugMessageTimed("No more intermediate destinations!", 2);
            GoToState('Error');
            break;
        }

        if (IsNavMeshPath) // Move on nav mesh. 
        {
            HasNextDest = myController.NavigationHandle.GetNextMoveLocation(MoveLocationCurrent, myPawn.GetCollisionRadius());

            if (HasNextDest)
            {
                myController.NavigationHandle.SuggestMovePreparation(MoveLocationCurrent, myController);
                myController.MoveTo(MoveLocationCurrent);
            }
        }
        else // Move on network path. 
        {
            // TODO: MED - Implement method of getting "next" destination. 
            myController.MoveToward(NavPoint);
        }

        // Determine look target. 
        DetermineLookLocation();

        Sleep(0.1f);
    }
}

state Error
{
Begin:
    Sleep(1.f);
    Class'MasonLastStandGame'.static.BroadcastMessage_MLS(myName$": Retrying path finding", EFAC_ALL, , true);
    myController.DrawDebugMessageTimed("Retrying path finding!", 3);

    GoToState('Active');
}

/**
* Pre-completed state, to be overridden by child classes. 
*/
state PreCompleted
{
Begin:
    GoToState('Completed');
}

state Completed
{
Begin:
    Class'MasonLastStandGame'.static.BroadcastMessage_MLS(myName$": Reached destination", EFAC_ALL, , true);
    myController.DrawDebugMessageTimed("Reached destination!", 2);
}

DefaultProperties
{
    Begin Object Class=SpriteComponent Name=Sprite
        Sprite=Texture2D'EditorResources.S_Actor'
        HiddenGame=TRUE
        AlwaysLoadOnClient=FALSE
        AlwaysLoadOnServer=FALSE
        SpriteCategoryName="Info"
    End Object
    Components.Add(Sprite)

    DistanceTolerance=30.f
    SprintThreshold=300.f
    ReevaluationThreshold=10.f
    bSprint=true
    bRandomLocation=false
    RandomRadius=100.f
}