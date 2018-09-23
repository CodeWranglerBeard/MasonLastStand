/**
* An interface to be implemented by any classes that need to listen to MLSAIBehavior events. 
*/
interface IMLSBehaviorListener;

function NotifyBehaviorCompleted(MLSAIBehavior Behavior);
function NotifyBehaviorError(MLSAIBehavior Behavior);
function NotifyBehaviorActivated(MLSAIBehavior Behavior);
function NotifyBehaviorDeactivated(MLSAIBehavior Behavior);