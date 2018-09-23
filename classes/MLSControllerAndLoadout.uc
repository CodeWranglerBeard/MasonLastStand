/**
* Represents either a Controller and their associated AOCPawn's weapon loadout. 
*/
class MLSControllerAndLoadout extends Object
    notplaceable;

var Controller ControllerInstance;
var class<AOCWeapon> Primary;
var class<AOCWeapon> Secondary;
var class<AOCWeapon> Tertiary;

DefaultProperties
{
    ControllerInstance = none
    Primary = class'AOCWeapon_None'
    Secondary = class'AOCWeapon_None'
    Tertiary = class'AOCWeapon_None'
}
