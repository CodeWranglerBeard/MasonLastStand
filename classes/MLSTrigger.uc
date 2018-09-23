class MLSTrigger extends Trigger;

var() array<IMLSTriggerListener> Listeners;

event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
    local IMLSTriggerListener Listener;

    foreach Listeners(Listener)
    {
        Listener.NotifyTouch(self, Other, OtherComp, HitLocation, HitNormal);
    }

    super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

event UnTouch(Actor Other)
{
    local IMLSTriggerListener Listener;

    foreach Listeners(Listener)
    {
        Listener.NotifyUnTouch(self, Other);
    }

    super.UnTouch(Other);
}

function NotifyTriggered()
{
    local IMLSTriggerListener Listener;

    foreach Listeners(Listener)
    {
        Listener.NotifyTriggered(self);
    }
    super.NotifyTriggered();
}

defaultproperties
{
    bStatic=false
}