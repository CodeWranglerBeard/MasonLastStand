/**
* Represents a placeable bomb. 
*/
class MLSBarrelBomb extends Actor
    dependson(AOCPawn)
    dependson(AOCGame)
    implements(IAOCUsable)
    implements(IMLSTriggerListener)
    ClassGroup(MLS)
    placeable;

/**
* The amount of damage to apply. 
*/
var() float Damage;

/**
* Radius to apply the damage in. Any actors inside this radius will be damaged. 
*/
var() float DamageRadius;

/**
* Radius that a pawn of the target faction has to enter in order to trigger the fuse. 
*/
var() float ActivationRadius;

/**
* If true, the damage will be linearly interpolated based on the origin of this actor and the DamageRadius. 
*/
var() bool bDamageFallOff;

/**
* In seconds, the delay between triggering the bomb and it actually exploding. 
* Must be > 0.f
*/
var() float FuseTimer;

/**
* The type of damage to apply. 
*/
var DamageType DamageType;

/**
* Pawns of this faction will cause the bomb to detonate. 
*/
var() EAOCFaction TargetFaction;

var() AudioComponent FuseSoundComp;
var() AudioComponent DetonateSoundComp;

var ParticleSystemComponent FusePSC;
var ParticleSystemComponent DetonatePSC;

/**
* Base cylinder component for collision
*/
var() editconst const CylinderComponent CylinderComponent;

var DrawCylinderComponent DrawActivation;
var DrawSphereComponent DrawDamage;

var MLSTrigger ActivationTrigger;
var MLSTrigger UseTrigger;

/**
* The Controller to be credited for any kills incurred by this bomb. 
*/
var Controller BombSetter;

/**
* The pawn that is currently carrying the bomb. 
*/
var AOCPawn CurrentUser;

simulated function bool CanBeUsed(optional int Faction, optional AOCPawn CheckUser, optional out int bHold)
{
    class'MasonLastStandGame'.static.BroadcastMessage_MLS("Can be used!", EFAC_ALL, , true);

    if (Faction != TargetFaction)
    {
        return true;
    }
    else
    {
        return false;
    }
}

simulated function bool UtilizeObject(AOCPawn User, bool bUseDrop, optional name BoneHit = 'none')
{
    return false;
}

simulated function EndUtilizeObject(AOCPawn User)
{
}

function NotifyTouch(MLSTrigger aTrigger, Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
    class'MasonLastStandGame'.static.BroadcastMessage_MLS("Touched the attached Trigger!", EFAC_ALL, , true);
}

function NotifyUnTouch(MLSTrigger aTrigger, Actor Other);
function NotifyTriggered(MLSTrigger aTrigger);

state Inactive
{
    function Activate()
    {
        GotoState('Active');
    }
}

auto state Active
{
    function Deactivate()
    {
        GotoState('Inactive');
    }

    /**
    * Causes the bomb to detonate after the fuse time runs out. 
    */
    function LightFuse()
    {
        local ParticleSystem FusePS;
        local vector Offset;

        Offset = vect(0.f, 0.f, 1.f);
        Offset = Offset * (40.f * DrawScale3D.Z);

        // Play fuse particle system and audio. 
        FuseSoundComp.Play();

        FusePS = ParticleSystem'WP_bow_Longbow.Particles.P_ArrFire_static';
        FusePSC = WorldInfo.MyEmitterPool.SpawnEmitter(FusePS, Location + Offset, Rotation, self);

        SetTimer(FuseTimer, false, 'Detonate');
    }

    /**
    * Causes the bomb to detonate. 
    */
    function Detonate()
    {
        local Controller C;
        local AOCPawn P;
        local float Dist;
        local float DamageFallOffMult;
        local float ColRadius, ColHeight;
        local vector Dir;
        local ParticleSystem DetonatePS;

        // Play explosion particle system and audio. 
        DetonateSoundComp.Play();

        DetonatePS = ParticleSystem'CHV_PartiPack.Particles.P_Fire_Burst';
        DetonatePSC = WorldInfo.MyEmitterPool.SpawnEmitter(DetonatePS, Location, Rotation, self);

        // Get Actors in range of the bomb. 
        foreach WorldInfo.AllControllers(class'Controller', C)
        {
            P = AOCPawn(C.Pawn);
            Dir = P.Location - Location;
            Dist = VSize(Dir);

            if (P != none && Dist <= DamageRadius)
            {
                // TODO: Cull Actors behind cover?


                // Get damage falloff multiplier. 
                if (bDamageFallOff)
                {
                    P.GetBoundingCylinder(ColRadius, ColHeight);
                    Dist = FMax(Dist - ColRadius,0.f);
                    DamageFallOffMult = FClamp(1.f - Dist/DamageRadius, 0.f, 1.f);
                }
                else
                {
                    DamageFallOffMult = 1.f;
                }

                // Apply damage. 
                P.TakeDamage(
                    (Damage*DamageFallOffMult), 
                    BombSetter, 
                    Location, 
                    (-Normal(Dir) * 1000.f), 
                    class'AOCDmgType_Generic'
                );
            }
        }
        
        FusePSC.DeactivateSystem();

        // Become invisible and non-colliding.
        SetPhysics(PHYS_None);
        SetHidden(True);
        SetCollision(false,false);
        // Destroy self after certain amount of time.
        SetTimer(2.f, false, 'Destroy');
    }

    event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
    {
        local AOCPawn P;
        local float CrosshairTextDistance;
        local string CrosshairText;
        local float Dist;
        local vector Dir;
        local EAOCFaction Fac;

        super.Touch(Other, OtherComp, HitLocation, HitNormal);

        P = AOCPawn(Other);
        Fac = P.PawnInfo.myFamily.FamilyFaction;

        if (P != none && (Fac == EFAC_ALL || Fac == TargetFaction))
        {
            LightFuse();
        }
        else
        {
            CrosshairTextDistance = 200.f;
            CrosshairText = "USE to pickup";
            Dir = P.Location - Location;
            Dist = VSize(Dir);

            if (Dist <= CrosshairTextDistance)
            {
                AOCPlayerController(P.Controller).ForceVolumeHintCrosshair(true, EVOL_None, CrosshairText);
            }
        }
        class'MasonLastStandGame'.static.BroadcastMessage_MLS(string(Dist), EFAC_ALL, , true);
    }

    event UnTouch( Actor Other )
    {
        local AOCPawn P;

        super.UnTouch(Other);

        P = AOCPawn(Other);
        AOCPlayerController(P.Controller).ForceVolumeHintCrosshair(false, EVOL_None, "");
    }

    simulated function bool UtilizeObject(AOCPawn User, bool bUseDrop, optional name BoneHit = 'none')
    {
        AOCPlayerController(User.Controller).CurrentObjectUsed = none;

        if(CurrentUser != none && CurrentUser != User) // Prevent other AOCPawns interfering. 
            return false;

        CurrentUser = User;
        class'MasonLastStandGame'.static.BroadcastMessage_MLS("Used", EFAC_ALL, , true);

        return true;
    }

    simulated function EndUtilizeObject(AOCPawn User)
    {
        CurrentUser = none;
        class'MasonLastStandGame'.static.BroadcastMessage_MLS("Unused", EFAC_ALL, , true);
    }
}

function PreBeginPlay()
{
    super.PreBeginPlay();

    DrawActivation.CylinderRadius=ActivationRadius;
    DrawActivation.CylinderTopRadius=ActivationRadius;
    DrawDamage.SphereRadius=DamageRadius;

    // ActivationTrigger = Spawn(class'MLSTrigger', self);
    // ActivationTrigger.Listeners.AddItem(self);
    // ActivationTrigger.CylinderComponent.CollisionHeight = 100.f;
    // ActivationTrigger.CylinderComponent.CollisionRadius = ActivationRadius;
    // ActivationTrigger.CylinderComponent.CollisionType = COLLIDE_TouchAllButWeapons;
}

DefaultProperties
{
    Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
    End Object
    Components(0)=MyLightEnvironment
     
    Begin Object Class=StaticMeshComponent Name=StaticMeshComponent_0
        StaticMesh=StaticMesh'CHV_Deco1.Village.Barrel_01'
        LightEnvironment=MyLightEnvironment
    End Object
    Components.Add(StaticMeshComponent_0)
    CollisionComponent=StaticMeshComponent_0

    // Begin Object Class=CylinderComponent Name=CollisionCylinder
    //     CollideActors=true
    //     CollisionRadius=200.f
    //     CollisionHeight=100.f
    //     AlwaysLoadOnClient=True
    //     AlwaysLoadOnServer=True
    //     bAlwaysRenderIfSelected=true
    //     BlockNonZeroExtent=false
    //     BlockZeroExtent=false
    //     BlockActors=false
    //     BlockRigidBody=false
    // End Object
    // CylinderComponent=CollisionCylinder
    // Components.Add(CollisionCylinder)

    Begin Object Class=AudioComponent Name=FuseSound
        SoundCue=SoundCue'A_INT.Switch_01'
        bShouldRemainActiveIfDropped=true
        bStopWhenOwnerDestroyed=true
    End Object
    FuseSoundComp=FuseSound
    Components.Add(FuseSound);

    Begin Object Class=AudioComponent Name=DetonateSound
        SoundCue=SoundCue'A_INT_Battlegrounds.BG_Bombcart_Explode'
        bShouldRemainActiveIfDropped=true
        bStopWhenOwnerDestroyed=true
    End Object
    DetonateSoundComp=DetonateSound
    Components.Add(DetonateSound);

    Begin Object Class=DrawCylinderComponent Name=myDrawActivation
        CylinderColor=(B=255,G=70,R=64,A=255)
        CylinderRadius=200.f
        CylinderTopRadius=200.f
        CylinderHeight=100.f
    End Object
    Components.Add(myDrawActivation)
    DrawActivation=myDrawActivation

    Begin Object Class=DrawSphereComponent Name=myDrawDamage
        SphereColor=(B=70,G=70,R=255,A=255)
        SphereRadius=500.f
    End Object
    Components.Add(myDrawDamage)
    DrawDamage=myDrawDamage

    CollisionType=COLLIDE_TouchAllButWeapons
    bCollideActors=true
    bCollideWorld=true
    bBlockActors=false
    Damage=350.f
    DamageRadius=500.f
    ActivationRadius=200.f
    FuseTimer=2.5f
    TargetFaction=EFAC_None
    bDamageFallOff=true
    bEdShouldSnap=true
    Name="Default__MyBarrelBomb"
}