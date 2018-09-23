/**
* Represents a kismet node to (de)activate an MLSAIController. 
*/
class MLSSeqAction_ToggleAIController extends SequenceAction
    dependson(MLSAIController);

event Activated()
{
    local array<Object> ObjVars;
    local Object Obj;
    local MLSAIController C;

    GetObjectVars(ObjVars, "MLSAIController(s)");
    foreach ObjVars(Obj)
    {
        C = MLSAIController(Obj);

        if (InputLinks[0].bHasImpulse)
        {
            C.Activate();
        }
        else if (InputLinks[1].bHasImpulse)
        {
            C.Deactivate();
        }
    }

    ForceActivateOutput(0);
}

DefaultProperties
{
    InputLinks(0)=(LinkDesc="Activate")
    InputLinks(1)=(LinkDesc="Deactivate")
    OutputLinks(0)=(LinkDesc="Out")
    VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="MLSAIController(s)")
    
    bAutoActivateOutputLinks = false
    
    ObjName="Toggle MLSAIController"
    ObjCategory="MLS Actions"
    bCallHandler=false
}