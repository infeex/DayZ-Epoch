/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

#include "gcam_uid.hpp"
fnc_keyDown={private["_handled","_ctrl","_dikCode","_shift","_ctrlKey","_alt"];_ctrl=_this select 0;_dikCode=_this select 1;_shift=_this select 2;_ctrlKey=_this select 3;_alt=_this select 4;_handled=false;if(!_shift&&!_ctrlKey&&!_alt)then{if(_dikCode==24)then{GCamKill=false;handle=[]spawn gcam_main;_handled=true;};if(_dikCode==25)then{GCamKill=true;_handled=true;dayz_ntg_follow={player};};};_handled};waitUntil{(!isNull Player)and(alive Player)and(player==player)};_uid=(getPlayerUID vehicle player);_isAdmin=(serverCommandAvailable"#kick");if((_isAdmin)&&((_uid)in ADMINS))then{waituntil{!(IsNull(findDisplay 46))};(findDisplay 46)displayAddEventHandler["keyDown","_this call fnc_keyDown"];}else{gcam_main=nil;fnc_keyDown=nil;};