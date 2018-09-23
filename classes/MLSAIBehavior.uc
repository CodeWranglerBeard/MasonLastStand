/**
* Represents the base class for an MLSAIController. 
* Determines what to do, when to do it and when to stop doing it, but does not decide how to do it. 
*/
class MLSAIBehavior extends Actor 
    ClassGroup(MLS)
    implements(IAOCAIListener)
    abstract
    notplaceable;

/**********
* FIELDS
**********/

/**
* A name to identify the behavior with. 
*/
var() string myName;

/**
* The AIController associated with this behavior. 
*/
var MLSAIController myController;

/**
* The priority of the behavior. Higher priority behaviors will be executed earlier. 
*/
var() float Priority;

/**
* If true, the behavior should be removed upon completion. 
*/
var() bool bAutoExpires;

/**
* Is true, if the behavior is currently executing a behavior that must not be interrupted, such as 
* playing an animation or some other time-consuming task. 
*/
var bool bBlocking;

// List of objects to inform of events. 
var array<IMLSBehaviorListener> Listeners;

/**********
* FUNCTIONS
**********/

function NotifyPawnPerformMissedAttack (AOCPawn Sender);

function NotifyPawnPerformSuccessfulAttack (AOCPawn Sender);

function NotifyPawnReceiveHit (AOCPawn Sender, AOCPawn Attacker);

function NotifyPawnStartingAttack (AOCPawn Sender);

function NotifyPawnSuccessBlock (AOCPawn Sender, AOCPawn Attacker);

/**
* Returns true, if the behavior can be activated. 
* @returns True, if the behavior can be activated. 
*/
function bool CanActivate()
{
    return false;
}

/**********
* STATES
**********/

/**
* Transitions to the Active state. 
*/
function Activate()
{
    GotoState('Active');
}

/**
* Transitions to the Inactive state. 
*/
function Deactivate()
{
    myController.StopLatentExecution();
    GotoState('Inactive');
}

/**
* Inactive state, executing no logic. 
*/
auto state Inactive
{
    event BeginState(Name PreviousStateName)
    {       
        local IMLSBehaviorListener Listener;

        super.BeginState(PreviousStateName);
        foreach Listeners(Listener)
            Listener.NotifyBehaviorDeactivated(self);
    }
    event PushedState()
    {
        local IMLSBehaviorListener Listener;

        super.PushedState();
        foreach Listeners(Listener)
            Listener.NotifyBehaviorDeactivated(self);
    }
    event ContinuedState()
    {
        local IMLSBehaviorListener Listener;

        super.ContinuedState();
        foreach Listeners(Listener)
            Listener.NotifyBehaviorDeactivated(self);
    }
Begin:
    // Do nothing. This state should be overriden in child classes. 
}

/**
* Active state, executing behavior. 
*/
state Active
{
    event BeginState(Name PreviousStateName)
    {       
        local IMLSBehaviorListener Listener;

        super.BeginState(PreviousStateName);
        foreach Listeners(Listener)
            Listener.NotifyBehaviorActivated(self);
    }
    event PushedState()
    {
        local IMLSBehaviorListener Listener;

        super.PushedState();
        foreach Listeners(Listener)
            Listener.NotifyBehaviorActivated(self);
    }
    event ContinuedState()
    {
        local IMLSBehaviorListener Listener;

        super.ContinuedState();
        foreach Listeners(Listener)
            Listener.NotifyBehaviorActivated(self);
    }

    event PausedState()
    {       
        super.PausedState();
        myController.StopLatentExecution();
    }
    event EndState(Name NextStateName)
    {
        super.EndState(NextStateName);
        myController.StopLatentExecution();
    }
    event PoppedState()
    {
        super.PoppedState();
        myController.StopLatentExecution();
    }
Begin:
    // Do nothing. This state should be overriden in child classes. 
}

/**
* Completed state, the behavior has accomplished its goal. 
*/
state Completed
{
    event BeginState(Name PreviousStateName)
    {       
        local IMLSBehaviorListener Listener;

        super.BeginState(PreviousStateName);
        foreach Listeners(Listener)
            Listener.NotifyBehaviorCompleted(self);
    }
    event PushedState()
    {
        local IMLSBehaviorListener Listener;

        super.PushedState();
        foreach Listeners(Listener)
            Listener.NotifyBehaviorCompleted(self);
    }
    event ContinuedState()
    {
        local IMLSBehaviorListener Listener;

        super.ContinuedState();
        foreach Listeners(Listener)
            Listener.NotifyBehaviorCompleted(self);
    }
Begin:
    // Do nothing. This state should be overriden in child classes. 
}

/**
* Error state, the behavior could not execute. 
*/
state Error
{
    event BeginState(Name PreviousStateName)
    {
        local IMLSBehaviorListener Listener;

        super.BeginState(PreviousStateName);
        Class'MasonLastStandGame'.static.BroadcastMessage_MLS(myName$": Error occurred in "$PreviousStateName, EFAC_ALL, , true);
        myController.DrawDebugMessageTimed("Error occurred in "$PreviousStateName);

        foreach Listeners(Listener)
            Listener.NotifyBehaviorError(self);
    }
    event PushedState()
    {
        local IMLSBehaviorListener Listener;

        super.PushedState();
        foreach Listeners(Listener)
            Listener.NotifyBehaviorError(self);
    }
    event ContinuedState()
    {
        local IMLSBehaviorListener Listener;

        super.ContinuedState();
        foreach Listeners(Listener)
            Listener.NotifyBehaviorError(self);
    }
Begin:
    // Do nothing. This state should be overriden in child classes. 
}

DefaultProperties
{
    bAutoExpires=false
    Priority=1.f
    myName="Default__Behavior"
}