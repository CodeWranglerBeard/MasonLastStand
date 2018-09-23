/**
* Spawns a custom bot with an MLSAIController, instead of an AOCAIController. 
*/
class MLSSeqAction_SpawnBot extends SequenceAction
    dependson(AOCNPC_New)
    dependson(AOCGame);
    
// var(General) string MyName;
// var(General) EAOCFaction MyTeam;

// /**
// * The FamilyInfo to use. Can be an instance placed in the level. 
// */
// var(General) AOCFamilyInfo FamilyInfo;

// /** Modifiable Combat Settings */
// var(Combat) class<AOCWeapon> PrimaryWeapon;
// var(Combat) class<AOCWeapon> SecondaryWeapon;
// var(Combat) class<AOCWeapon> TertiaryWeapon;

// var(AI) class<MLSAIController> ControllerClass;

// /** NPC Spawner Static Variables */
// // The actor at which to spawn. Also accessible by variable link.
// var(Spawner) NavigationPoint StartingNavigationPoint;
// // Enable to prevent spawn from failing due to collision
// var(Spawner) bool bNoCollisionFail;

// /** NPC Spawner Game-Time Variables */
// var AOCPawn NPC;
// var MLSAIController AI;

// //Customization lets you change pawn's appearance, including model, colors, emblem, ...
// var(Customization) bool bOverrideCustomization;
// var(Customization) int Character;
// var(Customization) byte Emblem;
// var(Customization) byte EmblemColor1;
// var(Customization) byte EmblemColor2;
// var(Customization) byte EmblemColor3;
// //var float EmblemU, EmblemV;
// var(Customization) byte Tabard;
// var(Customization) byte TabardColor1;
// var(Customization) byte TabardColor2;
// var(Customization) byte TabardColor3;
// var(Customization) byte Helmet;
// var(Customization) byte Shield;
// var(Customization) byte ShieldColor1;
// var(Customization) byte ShieldColor2;
// var(Customization) byte ShieldColor3;

// function Activated()
// {   
//     //Spawn the controller
//     AI = GetWorldInfo().Game.Spawn(ControllerClass);    
//     AI.PlayerReplicationInfo.PlayerID = GetWorldInfo().Game.GetNextPlayerID();

//     //Set up the controller
//     AI.SetFamily(FamilyInfo);
//     AI.SetLoadout(PrimaryWeapon, SecondaryWeapon, TertiaryWeapon);

//     //Set up spawn point
//     StartingNavigationPoint = NavigationPoint(SeqVar_Object(VariableLinks[0].LinkedVariables[0]).GetObjectValue());

//     if(StartingNavigationPoint == none)
//     {
//         StartingNavigationPoint = AOCGame(GetWorldInfo().Game).FindPlayerStart(AI, MyTeam);
//     }

//     if(StartingNavigationPoint == none)
//     {
//         ForceActivateOutput(1);
//         AI.Destroy();
//         return;
//     }

//     // Spawn the pawn
//     NPC = AOCPawn(GetWorldInfo().Game.SpawnDefaultPawnFor(AI, StartingNavigationPoint));
    
//     if(NPC == none)
//     {
//         ForceActivateOutput(1);
//         AI.Destroy();
//         return;
//     }
     
//     NPC.SetAnchor(StartingNavigationPoint);

//     AOCGame(GetWorldInfo().Game).ChangeName(AI,MyName,true);
//     AI.bIsPlayer = false; //Destroy controller on pawn death
//     AI.PlayerReplicationInfo.SetPlayerTeam(AOCGame(GetWorldInfo().Game).Teams[MyTeam]);
//     AOCPRI(AI.PlayerReplicationInfo).bDisplayOnScoreboard = false;

//     //Put the controller in possession of the pawn, and let the controller and pawn do the rest of the work
//     AI.myPawn = NPC;
//     AI.Possess(NPC, False);
    
//     NPC.iUniquePawnID = AOCGame(GetWorldInfo().Game).CurrentPawnID++;
//     GetWorldInfo().Game.AddDefaultInventory(NPC);
//     GetWorldInfo().Game.SetPlayerDefaults(NPC);

//     if(bOverrideCustomization)
//     {
//         NPC.PawnInfo.myCustomization.Character = Character;
//         NPC.PawnInfo.myCustomization.Emblem = Emblem;
//         NPC.PawnInfo.myCustomization.EmblemColor1 = EmblemColor1;
//         NPC.PawnInfo.myCustomization.EmblemColor2 = EmblemColor2;
//         NPC.PawnInfo.myCustomization.EmblemColor3 = EmblemColor3;
//         //var float EmblemU, EmblemV;
//         NPC.PawnInfo.myCustomization.Tabard = Tabard;
//         NPC.PawnInfo.myCustomization.TabardColor1 = TabardColor1;
//         NPC.PawnInfo.myCustomization.TabardColor2 = TabardColor2;
//         NPC.PawnInfo.myCustomization.TabardColor3 = TabardColor3;
//         NPC.PawnInfo.myCustomization.Helmet = Helmet;
//         NPC.PawnInfo.myCustomization.Shield = Shield;
//         NPC.PawnInfo.myCustomization.ShieldColor1 = ShieldColor1;
//         NPC.PawnInfo.myCustomization.ShieldColor2 = ShieldColor2;
//         NPC.PawnInfo.myCustomization.ShieldColor3 = ShieldColor3;

//         NPC.ReplicatedEvent('PawnInfo');
//     }
    
//     ForceActivateOutput(0);
// }

// DefaultProperties
// {
//     MyName = "My__Bot"
//     MyTeam = EFAC_Agatha
//     FamilyInfo=none
//     PrimaryWeapon=class'AOCWeapon_Halberd'
//     SecondaryWeapon=class'AOCWeapon_Dagesse'
//     TertiaryWeapon=class'AOCWeapon_ThrowingAxe'
//     ControllerClass=class'MLSAIController'

//     // the links to indicate which team finished an objective
//     InputLinks(0)=(LinkDesc="Spawn")
    
//     OutputLinks(0) = (LinkDesc="Success")
//     OutputLinks(1) = (LinkDesc="Failure")

//     // Which actor to spawn at
//     VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Spawn Point",PropertyName=StartingNavigationPoint)
//     // The spawned bot
//     VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Spawned",bWriteable=true,PropertyName=NPC)

//     ObjName="Spawn Custom Bot"
//     ObjCategory="MLS Actions"

//     bCallHandler=false
//     HandlerName="OnAISpawnStandardBot"
    
//     bNoCollisionFail = true;
    
//     bAutoActivateOutputLinks = false
// }