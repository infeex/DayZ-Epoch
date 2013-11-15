#include "faco_anticheat.hpp"
// Logo watermark: adding a logo in the bottom left corner of the screen with the server name in it
if (!isNil "dayZ_serverName") then {
	[] spawn {
		waitUntil {(!isNull Player) and (alive Player) and (player == player)};
		waituntil {!(isNull (findDisplay 46))};
		5 cutRsc ["wm_disp","PLAIN"];
		((uiNamespace getVariable "wm_disp") displayCtrl 1) ctrlSetText dayZ_serverName;
	};
};

if(!isDedicated)then{Stringify(PVCLIENT)addPublicVariableEventHandler{
_initac={if(count _this>0)then{[] spawn (_this select 0);};true};(_this select 1)call _initac;};};