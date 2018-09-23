/**
* Represents a behavior for an NPC to get and stay close to an actor or a location. 
*/
class MLSAIBehavior_StayNear extends MLSAIBehavior_MoveTo
    ClassGroup(MLS)
    placeable;

/**********
* FIELDS
**********/

/**
* The distance threshold to the destination. If the pawn is farther than this distance away from the destination, 
* the pawn is then forced to get close to it again. 
* Values below 1 will be ignored. 
*/
var() float LeashRadius;

/**********
* FUNCTIONS
**********/

/**
* Returns true, if the pawn is within the leash radius around the destination. 
* @returns True, if the pawn is within the leash radius. 
*/
function bool IsInLeashRadius()
{
    local vector Dir;
    local float Dist;

    if (myController.myPawn == none)
    {
        return false;
    }

    Dir = myController.myPawn.Location - super.GetMoveLocation();
    Dist = VSize(Dir);

    if (Dist <= FMin(LeashRadius, 1.f)) 
    {
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
    if (IsInRadius() && !IsInLeashRadius())
        return true;

    return false;
}

/**********
* STATES
**********/

/**
* Active state, executes logic. 
*/
state Active
{
    /**
    * Returns true, if the final destination has been reached. 
    */
    function bool ReachedDestination()
    {
        return (Dist <= LeashRadius);
    }
}

DefaultProperties
{
    LeashRadius=150.f
}