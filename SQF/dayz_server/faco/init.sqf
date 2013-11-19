[] spawn {
	while {true} do {
		waitUntil {((isNil "BIS_Effects_Rifle") OR {(count(toArray(str(BIS_Effects_Rifle)))!=7)})};
		diag_log "Res3tting B!S effects...";
		/* BIS_Effects_* fixes from Dwarden */
		BIS_Effects_Rifle = {false};
		BIS_Effects_EH_Fired = {false};
		BIS_Effects_EH_Killed = {
#include "killed.sqf";
		};
		BIS_Effects_AirDestruction = {
#include "AirDestruction.sqf";
		};
		BIS_Effects_AirDestructionStage2 = {
#include "AirDestructionStage2.sqf";
		};
		BIS_Effects_Secondaries = {
#include "secondaries.sqf";
		};
		
		BIS_Effects_globalEvent = {
			BIS_effects_gepv = _this;
			publicVariable "BIS_effects_gepv";
			_this call BIS_Effects_startEvent;
		};

		BIS_Effects_startEvent = {
			switch (_this select 0) do {
				case "AirDestruction": {
						[_this select 1] spawn BIS_Effects_AirDestruction;
				};
				case "AirDestructionStage2": {
						[_this select 1, _this select 2, _this select 3] spawn BIS_Effects_AirDestructionStage2;
				};
				case "Burn": {
						[_this select 1, _this select 2, _this select 3, false, true] spawn BIS_Effects_Burn;
				};
			};
		};

		"BIS_effects_gepv" addPublicVariableEventHandler {
			(_this select 1) call BIS_Effects_startEvent;
		};

		sleep 1;
	};
};

