/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/

private ["_object","_type","_objectID","_uid","_lastUpdate","_needUpdate","_object_position","_object_inventory","_object_damage","_isNotOk", "_i"];

#include "\z\addons\dayz_server\compile\server_toggle_debug.hpp"

_object = 	_this select 0;

if ((isNil "_object") OR {(isNull _object)}) exitWith {};

_type = 	_this select 1;
_isbuildable = _type in dayz_allowedObjects;
_forced = if (count _this == 3) then {_this select 2} else {false};

_getoid = {
	_objectID = _object getVariable ["ObjectID",nil];
	_uid = "0";
	if ((isNil "_objectID") OR {(typeName _objectID != "string")}) then {
		_objectID = "0";
		_uid = _object getVariable ["ObjectUID",nil];
		if ((isNil "_uid") OR {(typeName _uid != "string")}) then {
			_uid = "0";
		};
	};
};

_objectID = "0";
_uid = "0";
call _getoid;

if (((typeOf _object == "ParachuteWest") OR {((_uid != "0") AND {!_isbuildable})}) OR {(_objectID == "0" AND _uid == "0" )}) exitWith {
	diag_log format ["%1: Error: Won't save %2  ObjectID=%3(%7) ObjectUID=%4(%9) typeOf=%5 SafeObjects=%6", __FILE__, _object, _objectID, _uid, typeOf _object, SafeObjects, _object getVariable ["ObjectID", "?"], _object getVariable ["ObjectUID", "?"]];
};

_object_position = { // position and fuel
	private["_position","_worldspace","_fuel","_key"];

	_position = _object call fa_antiesp_realpos;
	if (isNil "_position") then { 
		if !(_object call fa_antiesp_check) then {
			_position = getPosATL _object;
		}
		else {
			diag_log format [ "%1: Error, wont save to the HIVE %2", __FILE__, _object call fa_obj2str];
		};
	};
	if !(isNil "_position") then { 
		_worldspace = [
			round(direction _object),
			[ round((_position select 0) * 20) / 20, round((_position select 1) * 20) / 20, ceil((_position select 2) * 20) / 20 ]
		];
		_fuel = 0;
		if (_object isKindOf "AllVehicles") then {
			_fuel = round((fuel _object) * 1000) / 1000;
		};
		_key = format["CHILD:305:%1:%2:%3:",_objectID,_worldspace,_fuel];
		if (_object getVariable["305", ""] != _key) then {
			_object setVariable["305", _key];
			_key call server_hiveWrite;
			diag_log _key;
		};
	};
};

_object_inventory = {
	private["_inventory","_previous","_key"];
//	if (_object isKindOf "TrapItems") then {
//		_inventory = [_object getVariable ["armed", false]];
//	} else {
		_inventory = [
			getWeaponCargo _object,
			getMagazineCargo _object,
			getBackpackCargo _object
		];
//	};
	_inventory = str _inventory;
	if (_object getVariable["lastInventory",""] != _inventory) then {
		_object setVariable["lastInventory",_inventory];
		if (_objectID == "0") then {
			_key = format["CHILD:309:%1:",_uid];
		} else {
			_key = format["CHILD:303:%1:",_objectID];
		};
		_key=_key+_inventory+":";
		_key call server_hiveWrite;
		diag_log _key;
	};
};

_object_damage = {
	//Allow dmg process
	private["_hitpoints","_array","_hit","_selection","_key","_damage","_allFixed"];
	_hitpoints = _object call vehicle_getHitpoints;
	_damage = damage _object;
	_damage = round (_damage * 1000) / 1000;
	_array = [];
	_allFixed = true;
	{
		_hit = [_object,_x] call object_getHit;
		_hit = round (_hit * 100) / 100;
		_selection = getText (configFile >> "CfgVehicles" >> (typeOf _object) >> "HitPoints" >> _x >> "name");
		if (_hit > 0) then {
			_array set [count _array,[_selection,_hit]];
			_allFixed = false;
			//diag_log format ["Section Part: %1, Dmg: %2",_selection,_hit]; 
		} else {
			_array set [count _array,[_selection,0]]; 
		};
	} forEach _hitpoints;
	
	if (_objectID == "0") then {
		_key = format["CHILD:306:%1:%2:%3:",_uid,_array,_damage];
	} else {
		_key = format["CHILD:306:%1:%2:%3:",_objectID,_array,_damage];
	};
	if (_object getVariable["306", ""] != _key) then {
		_object setVariable["306", _key];
		_key call server_hiveWrite;
		if (_allFixed) then {
			_object setDamage 0;
			_object setDamage _damage;
		};
		diag_log _key;
	};
};

_object_killed = {
	_object setDamage 1;
	_forced = true;
	call _object_damage;
};

_process = {
	switch (_type) do {
		case "all": {
			call _object_position;
			call _object_inventory;
			call _object_damage;
		};
		case "position": {
			call _object_position;
		};
		case "gear": {
			call _object_inventory;
		};
		case "damage"; case "repair" : {
			call _object_damage;
		};
		case "killed": {
			call _object_killed;
		};
	};
};

_mergetypes = {
	private["_p", "_t"];
	
	_p = _this select 0; // previous type of request
	_t = _this select 1; // new type
	
	switch true do {
		case  (_p == "killed" OR _t == "killed"):{"killed"};
		case  (_p == "all" OR _t == "all"):{"all"};
		case  (_p != _t):{"all"};
		default {_p};
	}
};


if (_object isKindOf "AllVehicles") then {
	if (isNil "fa_ao_stack_o") then { fa_ao_stack_o = []; fa_ao_stack_t = []; };
	_i = fa_ao_stack_o find _object;
	if (_i >= 0) then {
		fa_ao_stack_t set [ _i, [ fa_ao_stack_t select _i, _type ] call _mergetypes ];	
		//diag_log format [ "%1: update hive write request ""%2"" for object %3", __FILE__, fa_ao_stack_t select _i, _object ];
	}
	else {
		fa_ao_stack_o set [ count fa_ao_stack_o, _object ];
		fa_ao_stack_t set [ count fa_ao_stack_t, _type ];
		//diag_log format [ "%1: enqueue hive write request ""%2"" for object %3", __FILE__, _type, _object ];
	};
	if (_forced) then {
		{
			_object = _x;
			_type = fa_ao_stack_t select _forEachIndex;
			call _getoid;
			//diag_log format [ "%1: processing hive write request ""%2"" for object %3", __FILE__, _type, _object ];
			call _process;
		} forEach fa_ao_stack_o;
		//diag_log format [ "%1: processed forced hive write + %2 requests for vehicles already in cache", __FILE__, (count fa_ao_stack_o) -1 ];
		fa_ao_stack_o resize 0;
		fa_ao_stack_t resize 0;
	};
}
else {
	//diag_log format [ "%1: processing hive write request ""%2"" for object %3", __FILE__, _type, _object ];
	call _process;
};
