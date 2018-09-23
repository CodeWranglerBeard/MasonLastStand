/**
* Represents a behavior for an NPC to engage in combat with other NPCs. 
*/
class MLSAIBehavior_CombatMelee extends MLSAIBehavior
    ClassGroup(MLS)
    placeable
    dependson(MLSAIEnemyMemory);

/**********
* FIELDS
**********/

/**
* The behavior will only activate if any enemies are within the given radius around the owner pawn. 
* <=0 for no limit. 
*/
var() float ActivationRadius;

/**** REACTIVE_SKILL ****/

// From 0.0 to 1.0, how likely this pawn is to read feints, when appropriate. 
var() float ReadSkill;

// From 0.0 to 1.0, how likely this pawn is to gamble on a feint punish, when appropriate. 
var() float GambleSkill;

// From 0.0 to 1.0, how likely this pawn is to parry and combo-feint-to-parry, when appropriate. 
var() float ParrySkill;

// From 0.0 to 1.0, how likely this pawn is to crouch or lean away from an attack, when appropriate. 
var() float LeanSkill;

// From 0.0 to 1.0, how likely this pawn is to perform a dodge. 
var() float DodgeSkill;

/**** PROACTIVE_SKILL ****/
// From 0.0 to 1.0, how likely this pawn is to execute a feint, when appropriate. 
var() float FeintSkill;

/**
* From 0.0 to 1.0, how likely this pawn is to execute an attack. 
*/
var() float AttackSkill;

/**
* From 0.0 to 1.0, how likely this pawn is to execute an advanced attack. 
* An advanced attack is, for example, running to one side of the opponent and starting an 
* horizontal attack over the shoulder that is facing the enemy. 
*/
var() float AttackAdvancedSkill;

// From 0.0 to 1.0, how likely this pawn is to switch targets, when appropriate. 
var() float SwitchSkill;

// From 0.0 to 1.0, how likely this pawn is to execute a reverse attack. 
var() float ReverseSkill;

// From 0.0 to 1.0, how likely this pawn is to perform a kick, when appropriate. 
var() float KickSkill;

// From 0.0 to 1.0, how likely this pawn is to wait for the enemy to act. 
var() float WaitChance;

/**** QUIRKS ****/

// From 0.0 to 1.0, how likely this pawn is to taunt enemies, when appropriate. 
var() float BattleCryChance;

/**** MEMORY ****/

/**
* The pawn currently being actively engaged. 
* This merely dictates who to actively attack, it doesn't exclude the ability to parry incoming 
* attacks from other enemies or the ability to switch targets. 
*/
var AOCPawn CurrentEnemy;

/**
* Holds information about all enemies that have engaged or been engaged by this pawn. 
*/
var array<MLSAIEnemyMemory> EnemyMemories;

/**** CHOREOGRAPHY ****/

/**
* Enum of possible actions to perform in combat. 
*/
enum EActions
{
    Action_Attack,          // Perform an attack. 
    Action_Feint,           // Perform a feint. 
    Action_Lean,            // Lean away from opponent. 
    Action_Dodge,           // Dodge away or around opponent. 
    Action_Parry,           // Parry or in the case of a shield, hold shield block. 
    Action_EndHold,         // Shield-specific, stop holding shield block. 
    Action_Wait,            // Wait for the enemy to act. 
    Action_Switch,          // Target switch to a different enemy. 
    Action_Battlecry,       // Play out a battlecry. 
    Action_Null             // No action to perform. 
};

/**
* Enum of possible attacks to perform in combat. 
*/
enum EAttacks
{
    Attack_Stab,
    Attack_Overhead,
    Attack_AltOverhead,
    Attack_Slash,
    Attack_AltSlash,
    Attack_OverheadReverse,
    Attack_AltOverheadReverse,
    Attack_SlashReverse,
    Attack_AltSlashReverse,
    /**** Keep these down here - not meant to be picked at random ****/
    Attack_Lunge,           // Sprinting lunge attack. 
    Attack_Shove,           // Kick opponent. 
    Attack_Null             // No attack to perform. 
};

/**
* Enum of possible relativities for movement and look locations. 
*/
enum ERelativities
{
    Relative_World,
    Relative_Self,
    Relative_Enemy,
    Relative_Null           // No change. 
};

/**
* Represents an action to perform in a choreography. 
*/
struct Action
{
    // The location to move to to perform this action. 
    var vector MoveLocation;

    // The new move relativity to set. 
    var ERelativities MoveRelativity;

    // The location to look at. 
    var vector LookLocation;

    // The new look relativity to set. 
    var ERelativities LookRelativity;

    /**
    * Only perform this action if the pawn is at least this close to the move destination. 
    * Values below 0 mean executing the action regardless of distance to the move destination. 
    */
    var float MaxDistance;

    // The type of action to perform. 
    var EActions EAction;

    // The type of attack to perform. 
    var EAttacks EAttack;

    // Directional information for the action to perform. 
    var ETurning EDirection;

    structdefaultproperties
    {
        MoveRelativity=Relative_Null
        LookRelativity=Relative_Null
        EAction=Action_Null
        EAttack=Attack_Null
        EDirection=ETURN_None
        MaxDistance=30.f
    }
};

/**
* The current sequence of actions to perform. 
* Could for example hold a sequence of actions to run up to an enemy, perform a feint and then a combo of attacks. 
*/
var array<Action> Choreography;

// The current action to perform. 
var Action CurrentAction;

/**
* The set location to move to. 
* Could be interpreted as an absolute or relative location, depending on the move relativity. 
*/
var vector MoveLocation; // TODO: LO - Remove?

// The actual world space location to move to. 
var vector MoveLocationWorld;

// Sets the move location either as an absolute location or relative to self or the enemy pawn. 
var ERelativities MoveRelativity;

/**
* The set location to look at. 
* Could be interpreted as an absolute or relative location, depending on the look relativity. 
*/
var vector LookLocation; // TODO: LO - Remove?

// The actual world space location to look at. 
var vector LookLocationWorld;

// Sets the look location either as an absolute location or relative to self or the enemy pawn. 
var ERelativities LookRelativity;

/**********
* FUNCTIONS
**********/

/**
* Returns true, if the behavior can be activated. 
* @returns True, if the behavior can be activated. 
*/
function bool CanActivate()
{
    local array<AOCPawn> Enemies;

    Enemies = myController.GetEnemiesInRange(ActivationRadius);

    if (Enemies.Length > 0)
    {
        return true;
    }
    else
    {
        return false;
    }
}

/**** MEMORY ****/

/**
* Adds the given pawn to the enemy memory, if it isn't already contained. 
* @param Pawn - The pawn to add as an enemy. 
* @returns True, if the pawn was added to memory.
*/
function bool AddEnemyToMemory(AOCPawn Pawn)
{
    local MLSAIEnemyMemory MemoryExisting;
    local MLSAIEnemyMemory MemoryNew;

    MemoryExisting = GetEnemyMemory(Pawn);

    if (MemoryExisting == none)
    {
        MemoryNew = new class'MLSAIEnemyMemory';
        MemoryNew.Enemy = Pawn;
        EnemyMemories.AddItem(MemoryNew);
        return true;
    }
    else
    {
        return false;
    }
}

/**
* Returns an MLSAIEnemyMemory for the given pawn, or none, if there is no memory of the given pawn. 
* @param aPawn - The enemy for which to return the corresponding memory. 
* @returns An MLSAIEnemyMemory object, or none. 
*/
function MLSAIEnemyMemory GetEnemyMemory(AOCPawn aPawn)
{
    local MLSAIEnemyMemory EnemyMemory;

    foreach EnemyMemories(EnemyMemory)
    {
        if (EnemyMemory.Enemy == aPawn)
        {
            return EnemyMemory;
        }
    }
    
    return none;
}

/**
* Clears all memory of enemies. 
*/
function ClearEnemyMemory()
{
    local int i;
    local MLSAIEnemyMemory EnemyMemory;

    for (i = EnemyMemories.Length - 1; i >= 0; i--)
    {
        EnemyMemory = EnemyMemories[i];
        EnemyMemories.RemoveItem(EnemyMemory);
    }
}

/**** NOTIFICATIONS ****/

function NotifyPawnPerformMissedAttack (AOCPawn Sender)
{
    // TODO: MED
    if (myController.myPawn == Sender || myController.IsAllyPawn(Sender))
    {
        return;
    }
}

function NotifyPawnPerformSuccessfulAttack (AOCPawn Sender)
{
    // TODO: MED
    if (myController.myPawn == Sender || myController.IsAllyPawn(Sender))
    {
        return;
    }
}

function NotifyPawnReceiveHit (AOCPawn Sender, AOCPawn Attacker)
{
    // TODO: MED
    if (myController.myPawn == Sender || myController.IsAllyPawn(Sender))
    {
        return;
    }
}

/**
* Used to react to opponent(s) starting an attack. 
* @param Sender - The pawn that started the attack. 
*/
function NotifyPawnStartingAttack (AOCPawn Sender)
{
    local float Decider;    // Random number to decide how to react. 

    // TODO: MED
    if (myController.myPawn == Sender || myController.IsAllyPawn(Sender))
    {
        return;
    }

    // Decide to parry. 
    Decider = FRand();
    if (Decider <= ParrySkill)
    {
        // TODO: MED - Modify choreography. 
        return;
    }

    // Decide to dodge instead. 
    Decider = FRand();
    if (Decider <= DodgeSkill)
    {
        // TODO: MED - Modify choreography. 
        return;
    }

    // Decide to lean. 
    Decider = FRand();
    if (Decider <= LeanSkill)
    {
        // TODO: MED - Modify choreography. 
        return;
    }
}

function NotifyPawnSuccessBlock (AOCPawn Sender, AOCPawn Attacker)
{
    // TODO: MED
    if (myController.myPawn == Sender || myController.IsAllyPawn(Sender))
    {
        return;
    }
}

/**
* Returns the next action from the list and removes it from the list. 
*/
function Action PopAction()
{
    local Action NewAction;

    NewAction = Choreography[0];
    Choreography.RemoveItem(NewAction);

    return NewAction;
}

/**
* Returns an enum value for a random attack for an action. 
* @param AllowStab - Optional: If true, allows a stab to be returned. Defaults to true. 
* @param AllowSlash - Optional: If true, allows a slash to be returned. Defaults to true. 
* @param AllowOverhead - Optional: If true, allows an overhead to be returned. Defaults to true. 
* @param AllowReverseSlash - Optional: If true, allows a reverse slash to be returned. Defaults to true. 
* @param AllowReverseOverhead - Optional: If true, allows a reverse overhead to be returned. Defaults to true. 
*/
function EAttacks GetRandomAttack(
    optional bool AllowStab = true, 
    optional bool AllowSlash = true,
    optional bool AllowOverhead = true,
    optional bool AllowReverseSlash = true,
    optional bool AllowReverseOverhead = true
)
{
    local array<EAttacks> AvailableAttacks;

    if (AllowStab)
    {
        AvailableAttacks.AddItem(Attack_Stab);
    }
    if (AllowSlash)
    {
        AvailableAttacks.AddItem(Attack_Slash);
        AvailableAttacks.AddItem(Attack_AltSlash);
    }
    if (AllowOverhead)
    {
        AvailableAttacks.AddItem(Attack_Overhead);
        AvailableAttacks.AddItem(Attack_AltOverhead);
    }
    if (AllowReverseSlash)
    {
        AvailableAttacks.AddItem(Attack_SlashReverse);
        AvailableAttacks.AddItem(Attack_AltSlashReverse);
    }
    if (AllowReverseOverhead)
    {
        AvailableAttacks.AddItem(Attack_OverheadReverse);
        AvailableAttacks.AddItem(Attack_AltOverheadReverse);
    }

    return AvailableAttacks[Rand(AvailableAttacks.Length)];
}

/**
* Returns true, if kicking the current enemy is appropriate, such as when they are blocking with a shield 
* or close to a hazard, such as wall spikes or a pit. 
*/
function bool IsKickAppropriate()
{
    // TODO: MED - Implement
    return false;
}

/**********
* STATES
**********/

/**
* Active state, executing behavior. 
*/
state Active
{
    local vector DirToAction;   // Direction to action location. 
    local float DistToAction;   // Distance to action location. 
    local vector Dir;           // Direction to move location. 
    local float Dist;           // Distance to move location. 

    /**
    * Returns the pawn to currently actively engage. 
    * Can optionally ignore a given pawn. Useful for switching targets, for example. 
    * @param Ignore - A pawn to ignore when finding a new enemy. 
    */
    function AOCPawn GetNewEnemy(optional AOCPawn Ignore = none)
    {
        local array<AOCPawn> Enemies;
        local AOCPawn Enemy;            // Iterator for enemies. 
        local AOCPawn TopEnemy;         // The enemy chosen to engage. 
        local MLSAIEnemyMemory Memory;    // A memory of an enemy. 
        local float Value;              // Iterator for enemy value. 
        local float TopValue;           // The highest value for an enemy so far. 
        local float DistToEnemy;        // Distance to enemy. 
        // local float TopDistToEnemy;     // Closest distance to enemy. 

        Enemies = myController.GetEnemiesInRange(ActivationRadius);
        foreach Enemies(Enemy)
        {
            if (Enemy == Ignore)
            {
                continue;
            }

            DistToEnemy = VSize(myController.myPawn.Location - Enemy.Location);
            Value -= (DistToEnemy / 100.f); // Arbitrary scoring system to prefer closer enemies. Might need a rework if it ends up too simple a system. 

            // Get memory of enemy, if there is one. 
            Memory = GetEnemyMemory(Enemy);

            if (Memory != none)
            {
                Value += Memory.HurtCount; // Enemies that have hurt this pawn are more considered higher value targets. 
            }
            else
            {
                AddEnemyToMemory(Enemy);
            }

            if (TopEnemy == none || Value > TopValue)
            {
                TopEnemy = Enemy;
                // TopDistToEnemy = DistToEnemy;
                TopValue = Value;
            }
        }

        return TopEnemy;
    }

    /**
    * Clears the current choreography. 
    */
    function ClearChoreography()
    {
        local int i;
        local Action aAction;

        for (i = Choreography.Length; i >= 0; i--)
        {
            Choreography.RemoveItem(aAction);
        }
    }
    
    /**
    * Returns a new choreography. 
    * @param ActionsToPlan - Optional: The amount of actions to pre-plan. Defaults to 5. 
    */
    function array<Action> GetChoreography(optional int ActionsToPlan = 5)
    {
        local array<Action> NewChoreography;    // Thew new choreography to return. 
        local Action NewAction;                 // A new action to add to the choreography. 
        local float Decider;                    // Random number to make decisions with. 
        local int ActionsPlanned;               // The amount of actions that have been planned so far. 
        local float EffectiveDistance;          // The distance to the enemy to stay at, in order to be able to attack effectively. 
        local vector DirToEnemy;                // Direction from owning pawn to enemy. 
        local vector DirToSelf;                 // Direction from enemy to owning pawn. 
        // local float DistToEnemy;                // Distance to enemy. 
        local vector Perp;                      // 
        local float AdjacencyDistance;          // Distance from the enemy that would place the owning pawn right next to the enemy. 
        local bool AllowSlash;                  // Is only false for javelins. 
        local MLSAIEnemyMemory Memory;    // A memory of an enemy. 

        ActionsPlanned = 0;
        EffectiveDistance = AOCWeapon(myController.myPawn.Weapon).EffectiveDistance;
        DirToEnemy = myController.myPawn.Location - CurrentEnemy.Location;
        DirToSelf = -DirToEnemy;
        // DistToEnemy = VSize(DirToEnemy);
        AdjacencyDistance = CurrentEnemy.GetCollisionRadius() + myController.myPawn.GetCollisionRadius();
        AllowSlash = true;
        Memory = GetEnemyMemory(CurrentEnemy);

        // Exclude slash for javelins - slash would result in a ranged attack. 
        if(AOCWeapon_JavelinMelee(myController.myPawn.Weapon) != none)
        {
            AllowSlash = false;
        }

        while(ActionsPlanned < ActionsToPlan)
        {
            ActionsPlanned++;
            Decider = FRand();

            // Switch enemy
            if (Decider <= FClamp(SwitchSkill, 0.f, 1.f))
            {
                NewAction.EAction = Action_Switch;
                NewChoreography.AddItem(NewAction);
                continue;
            }

            // Default behavior - stay close-ish to the enemy and look at them. 
            NewAction.MoveLocation = Normal(DirToSelf) * EffectiveDistance;
            NewAction.MoveRelativity = Relative_Enemy; // TODO: LO - May need another variant - Reacquire direction to enemy, instead of just applying an offset. 
            NewAction.LookLocation = vect(0,0,1) * CurrentEnemy.BaseEyeHeight;
            NewAction.LookRelativity = Relative_Enemy;

            // Stay at distance from enemy and wait to act. 
            Decider = FRand();
            if (Decider <= FClamp(WaitChance, 0.f, 1.f))
            {
                NewAction.EAction = Action_Wait;
                NewChoreography.AddItem(NewAction);
                continue;
            }

            // Attack
            Decider = FRand();
            if (Decider <= FClamp(AttackSkill, 0.f, 1.f))
            {
                NewAction.EAction = Action_Attack;
                NewAction.EAttack = GetRandomAttack(true, AllowSlash, true, false, false);

                Decider = FRand();
                if (Decider <= FClamp(AttackAdvancedSkill, 0.f, 1.f)) // AttackAdvanced
                {
                    Perp = DirToSelf cross vect(0,0,1);
                    // Move to left? side of enemy and slash. TODO: MED - Confirm direction correct. 
                    NewAction.MoveLocation = Normal(Perp) * AdjacencyDistance;
                    NewAction.EAttack = Attack_Slash;
                    if (FRand() <= 0.5f) // Move to right? side of enemy and alt slash. TODO: MED - Confirm direction correct. 
                    {
                        NewAction.MoveLocation = -NewAction.MoveLocation;
                        NewAction.EAttack = Attack_AltSlash;
                    }
                    NewAction.LookLocation = NewAction.MoveLocation * (vect(0,0,1) * CurrentEnemy.BaseEyeHeight);
                }                
                else if (Decider <= FClamp(ReverseSkill, 0.f, 1.f)) // Reverse
                {
                    NewAction.MoveLocation = Normal(DirToSelf) * AdjacencyDistance;
                    NewAction.EAttack = GetRandomAttack(false, false, false, true, true);
                }

                // Feint
                /*
                Example:
                Skill = 0.5f
                Decider = 0.8f
                FallsForFeintAverage = 0.6f
                Decider = FMin(0.8f, Abs(1.f - 0.6f))
                Decider = 0.4f
                */
                Decider = FMin(Decider, Abs(1.f - Memory.FallsForFeintAverage));
                if (Decider <= FClamp(FeintSkill, 0.f, 1.f))
                {
                    NewAction.EAction = Action_Feint;
                    Decider = FRand();
                }

                NewChoreography.AddItem(NewAction);
                continue;
            }

            // Kick
            Decider = FRand();
            if (Decider <= FClamp(KickSkill, 0.f, 1.f) && IsKickAppropriate())
            {
                // 
                continue;
            }

            // Battlecry
            Decider = FRand();
            if (Decider <= FClamp(BattleCryChance, 0.f, 1.f))
            {
                NewAction.EAction = Action_Battlecry;
                continue;
            }
        }

        return NewChoreography;
    }

    /**
    * Determines a new choreography to play out. 
    */
    function DetermineChoreography()
    {
        Choreography = GetChoreography();
    }
    /**
    * Updates the move location. 
    */
    function UpdateMoveLocation()
    {
        switch (MoveRelativity)
        {
            case Relative_World: // The location is absolute. 
                MoveLocationWorld = MoveLocation;
                break;

            case Relative_Enemy: // Keep location relative to enemy location. 
                MoveLocationWorld = CurrentEnemy.Location + MoveLocation;
                break;

            case Relative_Self: // Keep location relative to own location. 
                MoveLocationWorld = myController.myPawn.Location + MoveLocation;
                break;

            default:
        }
        MoveLocation = MoveLocationWorld;
    }

    /**
    * Updates the look location. 
    */
    function UpdateLookLocation()
    {
        switch (LookRelativity)
        {
            case Relative_World: // The location is absolute. 
                LookLocationWorld = LookLocation;
                break;

            case Relative_Enemy: // Keep location relative to enemy location. 
                LookLocationWorld = CurrentEnemy.Location + LookLocation;
                break;

            case Relative_Self: // Keep location relative to own location. 
                LookLocationWorld = myController.myPawn.Location + LookLocation;
                break;

            default:
        }
    }

    /**
    * Sets the timers for updating relative locations. 
    */
    function BeginTimers()
    {
        SetTimer(1.f, true, 'UpdateMoveLocation');
        SetTimer(1.f, true, 'UpdateLookLocation');
    }

    /**
    * Clears the timers for updating relative locations. 
    */
    function ClearTimers()
    {
        ClearTimer('UpdateMoveLocation');
        ClearTimer('UpdateLookLocation');
    }

Begin:
    myController.EquipPrimary();
    CurrentEnemy = GetNewEnemy();

    // while(CurrentEnemy != none)
    // {
    //     // Check if the world destination has been reached. 
    //     Dir =  myController.myPawn.Location - MoveLocationWorld;
    //     Dist = VSize(Dir);

    //     if (Choreography.Length == 0) // New choreography required. 
    //     {
    //         DetermineChoreography();
    //         CurrentAction = PopAction();
    //     }

    //     UpdateMoveLocation();
    //     UpdateLookLocation();

    //     /***** Keep in sync with original MoveTo behavior *****/ // TODO: MED - Find superior solution. 
    //     if (IsNavMeshPath) // Move on nav mesh. 
    //     {
    //         HasNextDest = myController.NavigationHandle.GetNextMoveLocation(MoveLocationWorld, myController.myPawn.GetCollisionRadius());
    //         myController.NavigationHandle.SuggestMovePreparation(MoveLocationWorld, myController);
            
    //         myController.MoveTo(MoveLocationWorld);
    //     }
    //     else // Move on network path. 
    //     {
    //         // TODO: MED - Implement method of getting "next" destination. 
    //         myController.MoveToward(NavPoint);
    //     }
    //     /**********/
    //     myController.FocusOnLocation(LookLocationWorld);

    //     DirToAction = myController.myPawn.Location - LookLocationWorld;
    //     DistToAction = VSize(DirToAction);

    //     // Perform action. 
    //     if (CurrentAction.MaxDistance <= 0 || DistToAction <= CurrentAction.MaxDistance)
    //     {
    //         switch(CurrentAction.EAction)
    //         {
    //             case Action_Attack:
    //                 // TODO: HI - Implement state
    // // if(Pawn.Weapon.IsInState('Release'))
    // // else if(Pawn.Weapon.IsInState('Recovery') || Pawn.Weapon.IsInState('Active'))
    //                 // PushState('Attack_Stab');
    //                 break;
    //             default:
    //                 GoToState('Error');
    //         }
    //         // Get new action, as the current action is presumed completed. 
    //         CurrentAction = PopAction();
    //         MoveLocation = CurrentAction.MoveLocation;
    //         LookLocation = CurrentAction.LookLocation;

    //         if (CurrentAction.MoveRelativity != Relative_Null)
    //             MoveRelativity = CurrentAction.MoveRelativity;

    //         if (CurrentAction.LookRelativity != Relative_Null)
    //             LookRelativity = CurrentAction.LookRelativity;
    //     }

    //     // Get new enemy, if necessary. 
    //     if (CurrentEnemy.Controller.IsDead()) // TODO: MED - Check if IsAliveAndWell() should be used instead. 
    //     {
    //         CurrentEnemy = GetNewEnemy();
    //     }

    //     Sleep(0.1f);
    // }

    GoToState('Completed');
}

/**
* Base state for the exection of action sub-states. 
*/
state ExecuteAction extends Active
{

}

/**
* Causes a new enemy to become the current target, if possible. 
* @Note: Only push and pop this state, don't GoToState to this!
*/
state SwitchEnemy extends ExecuteAction
{
Begin:
    CurrentEnemy = GetNewEnemy(CurrentEnemy);

    if (CurrentEnemy == none) // No other enemies to switch to. 
    {
        CurrentEnemy = GetNewEnemy();
    }
    PopState();
}

// state ScriptedFeint
// {
// Begin:
//     while(!Pawn.Weapon.IsInState('Active'))
//     {
//         sleep(0.1f);
//     }
//     Pawn.StartFire(ForcedAttackType);
//     Sleep(AOCWeapon(Pawn.Weapon).GetRealAnimLength(AOCWeapon(Pawn.Weapon).WindupAnimations[Pawn.Weapon.CurrentFireMode]) * 0.90);
    
//     AOCWeapon(Pawn.Weapon).DoFeintAttack();
    
//     OnFeintComplete(self);
//     PopState();
// }

// myController.myPawn.Dodge(NewDir);
// state ScriptedDodge
// {
// Begin:
//     if(Pawn.Physics == PHYS_None) //bots go into PHYS_None sometimes when they're standing around. Can't dodge in PHYS_None.
//     {
//         Pawn.SetPhysics(PHYS_Walking);
//     }

//     while(!Pawn.Weapon.IsInState('Active'))
//     {
//         sleep(0.1f);
//     }
//     AOCPawn(Pawn).Dodge(ScriptedDodgeDirection);
//     while(!AOCPawn(Pawn).StateVariables.bCanAttack)
//     {
//         sleep(0.1f);
//     }
//     if(Pawn.Physics != PHYS_Falling)
//     {
//         Pawn.ZeroMovementVariables();
//     }
//     OnScriptedDodgeComplete(self);
//     PopState();
// }

DefaultProperties
{
    bAutoExpires=false
    Priority=50.f
    ActivationRadius=300.f
    FeintSkill=0.5f
    ReadSkill=0.5f
    GambleSkill=0.5f
    ParrySkill=0.5f
    LeanSkill=0.5f
    AttackSkill=0.7f
    SwitchSkill=0.1f
    ReverseSkill=0.5f
    AttackAdvancedSkill=0.5f
    DodgeSkill=0.5f
    KickSkill=0.5f
    WaitChance=0.5f
    BattleCryChance=0.5f
}