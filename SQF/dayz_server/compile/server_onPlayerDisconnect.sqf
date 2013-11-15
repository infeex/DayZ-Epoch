private ["_invehicle","_isplayernearby","_object","_myGroup","_id","_playerID","_playerName","_characterID","_playerIDtoarray","_timeout","_message","_magazines"];
_playerID = _this select 0;
_playerName = _this select 1;
_object = call compile format["player%1",_playerID];
_characterID =	_object getVariable ["CharacterID","0"];
_timeout = _object getVariable["combattimeout",0];

_playerIDtoarray = [];
_playerIDtoarray = toArray _playerID;

_invehicle = false;

if (vehicle _object != _object) then {
	_object action ["eject", vehicle _object];
	_invehicle = true;
};

if (59 in _playerIDtoarray) exitWith { };

if ((_timeout - time) > 0) then {

    _object setVariable["NORRN_unconscious",true, true];
    _object setVariable["unconsciousTime",300,true];
	
    diag_log format["COMBAT LOGGED: %1 (%2)", _playerName,_timeout];
	//diag_log format["SET UNCONCIOUSNESS: %1", _playerName];
	
	// Message whole server when player combat logs
	_message = format["PLAYER COMBAT LOGGED: %1",_playerName];
	[nil,nil,"per",rTITLETEXT,_message,"PLAIN DOWN"] call RE;
};

//dayz_disco = dayz_disco - [_playerID];
if (!isNull _object) then {

//	diag_log format["DISCONNECT: %1 (%2) Object: %3, _characterID: %4", _playerName,_playerID,_object,_characterID];
// FACO >>
	_lastDamage = _object getVariable["noatlf4",0];
	_lastDamage = round(diag_ticktime - _lastDamage);
	diag_log format["Player UID#%1 CID#%2 %3 as %4, logged off at %5%6", 
		getPlayerUID _object, _characterID, _object call fa_plr2str, typeOf _object, 
		(getPosATL _object) call fa_coor2str,
		if ((_lastDamage < 33) AND {((alive _object) AND {(_object distance (getMarkerpos "respawn_west") >= 2000)})}) then {" while in combat ("+str(_lastDamage)+" seconds left)"} else {""}
	]; 
// << FACO

	_id = [_playerID,_characterID,2] spawn dayz_recordLogin;

	if (alive _object) then {

		_isplayernearby = (DZE_BackpackGuard and!_invehicle and ({isPlayer _x} count (_object nearEntities ["AllVehicles", 5]) > 1));

		// prevent saving more than 20 magazine items
		_magazines = [(magazines _object),20] call array_reduceSize;

		[_object,_magazines,true,true,_isplayernearby] call server_playerSync;
		
		// maybe not needed just testing
		_object removeAllEventHandlers "MPHit";
		_object enableSimulation false;
		_object removeAllEventHandlers "HandleDamage";
		_object removeAllEventHandlers "Killed";
		_object removeAllEventHandlers "Fired";
		_object removeAllEventHandlers "FiredNear";
		
		_myGroup = group _object;
		deleteVehicle _object;
		deleteGroup _myGroup;
	} else {
		//Update Vehicle
		{ 
			[_x,"gear"] call server_updateObject;
		} foreach (nearestObjects [getPosATL _object, dayz_updateObjects, 10]);
	};
};