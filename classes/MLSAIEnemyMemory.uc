/**
* Holds information about a unique enemy pawn. 
*/
class MLSAIEnemyMemory extends Object
    notplaceable;

/**
* The enemy this struct holds memory information about. 
*/
var AOCPawn Enemy;

/**
* The amount of times the enemy has feinted so far. 
* Utilized by the gamble chance to determine whether to try punishing a sequence of feints. 
*/
var int FeintCount;

/**
* The amount of times the enemy has feinted multiple times in a row, so far. 
* Utilized by the gamble chance to determine whether to try punishing a sequence of feints. 
*/
var int FeintSequence;

/**
* How many times the enemy feints, per attack, on average. 
* Utilized by the gamble chance to determine whether to try punishing a potential feint. 
*/
var float FeintAverage;

/**
* The amount of times the enemy has damaged the owning pawn so far. 
* Used to determine threat assessment. 
*/
var int HurtCount;

/**
* The amount of times the enemy has started an attack so far, including feints. 
*/
var int AttackCount;

/**
* The amount of times the enemy has been attacked so far, regardless of successful hits. 
*/
var int HasBeenAttackedCount;

/**
* The amount of times the enemy fell for a feint. 
* Utilized by the feint chance to determine whether to try feinting again. 
*/
var int FellForFeintCount;

/**
* How many times the enemy falls for feints, per feint, on average. 
* Utilized by the feint chance to determine whether to try feinting again. 
*/
var float FallsForFeintAverage;