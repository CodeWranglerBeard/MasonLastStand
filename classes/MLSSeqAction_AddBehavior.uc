/**
* Represents a kismet node to add given behaviors to the given MLSAIControllers. 
*/
class MLSSeqAction_AddBehavior extends SequenceAction
    dependson(MLSAIBehavior)
    dependson(MLSAIController);

event Activated()
{
    local array<Object> ObjVars;
    local Object Obj;
    local AOCPawn Pawn;
    local MLSAIController Controller;
    local MLSAIBehavior Behavior;
    local array<MLSAIController> Controllers;
    local array<MLSAIBehavior> Behaviors;

    if(CMWTO2(GetWorldInfo().Game) != none)
    {
        // Get Controllers to add behaviors to. 
        GetObjectVars(ObjVars, "MLSAIController(s)");
        foreach ObjVars(Obj)
        {
            Pawn = AOCPawn(GetPawn(Actor(Obj)));

            if (Pawn != none)
            {
                Controller = MLSAIController(Pawn.Controller);
            }
            else
            {
                Controller = MLSAIController(Actor(Obj));
            }

            if (Controller != none)
            {
                Controllers.AddItem(Controller);
            }
        }

        // Get behaviors to add. 
        ObjVars.Remove(0, ObjVars.Length);
        GetObjectVars(ObjVars, "Behavior(s)");
        foreach ObjVars(Obj)
        {
            Behavior = MLSAIBehavior(Obj);

            if (Behavior != none)
            {
                Behaviors.AddItem(Behavior);
            }
        }

        // Add behaviors to Controllers. 
        foreach Behaviors(Behavior)
        {
            foreach Controllers(Controller)
            {
                Controller.AddBehavior(Behavior);
            }
        }
    }
    
    ForceActivateOutput(0);
}

DefaultProperties
{
    InputLinks(0)=(LinkDesc="In")
    OutputLinks(0)=(LinkDesc="Out")
    VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="MLSAIController(s)")
    VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Behavior(s)")
    
    bAutoActivateOutputLinks = false
    
    ObjName="Add Behavior"
    ObjCategory="MLS Actions"
    bCallHandler=false
}