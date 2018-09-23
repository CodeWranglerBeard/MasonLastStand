/**
* An interface to be implemented by any classes that need to listen to specific trigger events. 
*/
interface IMLSTriggerListener;

function NotifyTouch(MLSTrigger aTrigger, Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal);
function NotifyUnTouch(MLSTrigger aTrigger, Actor Other);
function NotifyTriggered(MLSTrigger aTrigger);