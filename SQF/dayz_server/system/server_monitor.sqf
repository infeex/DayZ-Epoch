private ["_nul","_result","_pos","_wsDone","_dir","_block","_isOK","_countr","_objWpnTypes","_objWpnQty","_dam","_selection","_totalvehicles","_object","_idKey","_type","_ownerID","_worldspace","_intentory","_hitPoints","_fuel","_damage","_date","_key","_outcome","_vehLimit","_hiveResponse","_objectCount","_codeCount","_objectArray","_hour","_minute","_data","_status","_val","_traderid","_retrader","_traderData","_id","_lockable","_debugMarkerPosition","_vehicle_0"];

dayz_versionNo = 		getText(configFile >> "CfgMods" >> "DayZ" >> "version");
dayz_hiveVersionNo = 	getNumber(configFile >> "CfgMods" >> "DayZ" >> "hiveVersion");

if ((count playableUnits == 0) and !isDedicated) then {
	isSinglePlayer = true;
};

waitUntil{initialized}; //means all the functions are now defined

diag_log "HIVE: Starting";

waituntil{isNil "sm_done"}; // prevent server_monitor be called twice (bug during login of the first player)

#include "\z\addons\dayz_server\faco\fa_hiveMaintenance.sqf"
#include "\z\addons\dayz_server\faco\antiESP.sqf"
call fa_antiesp_init; // call early, before spawning anything;
//Set the Time
//Send request
_key = "CHILD:307:";
_result = _key call server_hiveReadWrite;
_outcome = _result select 0;
if(_outcome == "PASS") then {
	_date = _result select 1; 
		
	if(dayz_fullMoonNights) then {
		//date setup
		//_year = _date select 0;
		//_month = _date select 1;
		//_day = _date select 2;
		_hour = _date select 3;
		_minute = _date select 4;
		
		//Force full moon nights
		_date = [2013,8,3,_hour,_minute];
	};
		
	if(isDedicated) then {
		setDate _date;
		PVDZE_plr_SetDate = _date;
		publicVariable "PVDZE_plr_SetDate";
	};

	diag_log ("HIVE: Local Time set to " + str(_date));
};

// Custom Configs
if(isnil "MaxVehicleLimit") then {
	MaxVehicleLimit = 50;
};
if(isnil "MaxHeliCrashes") then {
	MaxHeliCrashes = 5;
};
if(isnil "MaxDynamicDebris") then {
	MaxDynamicDebris = 100;
};
if(isnil "MaxAmmoBoxes") then {
	MaxAmmoBoxes = 3;
};
if(isnil "MaxMineVeins") then {
	MaxMineVeins = 50;
};
// Custon Configs End

if (isServer and isNil "sm_done") then {

	serverVehicleCounter = [];
	_hiveResponse = [];

	for "_i" from 1 to 5 do {
		diag_log "HIVE: trying to get objects";
		_key = format["CHILD:302:%1:", dayZ_instance];
		_hiveResponse = _key call server_hiveReadWrite;  
		if ((((isnil "_hiveResponse") || {(typeName _hiveResponse != "ARRAY")}) || {((typeName (_hiveResponse select 1)) != "SCALAR")}) || {(_hiveResponse select 1 > 2000)}) then {
			if (!isNil "_hiveResponse") then {
			diag_log ("HIVE: connection problem... HiveExt response:"+str(_hiveResponse));
			} else {
				diag_log ("HIVE: connection problem... HiveExt NIL response:");
			};
			_hiveResponse = ["",0];
		} 
		else {
			diag_log ("HIVE: found "+str(_hiveResponse select 1)+" objects" );
			_i = 99; // break
		};
	};

	_objectArray = [];
	if ((_hiveResponse select 0) == "ObjectStreamStart") then {
		_objectCount = _hiveResponse select 1;
		diag_log ("HIVE: Commence Object Streaming...");
		for "_i" from 1 to _objectCount do { 
			_hiveResponse = _key call server_hiveReadWriteLarge;
			_objectArray set [_i - 1, _hiveResponse];
			//diag_log (format["HIVE dbg %1 %2", typeName _hiveResponse, _hiveResponse]);
		};
		diag_log ("HIVE: got " + str(count _objectArray) + " objects");
#ifdef EMPTY_TENTS_CHECK
		// check empty tents, remove some of them
		[_objectArray, EMPTY_TENTS_GLOBAL_LIMIT, EMPTY_TENTS_USER_LIMIT] call fa_removeExtraTents;
#endif
		// check vehicles count
		//[_objectArray] call fa_checkVehicles;
	};

	// # START OF STREAMING #
	_countr = 0;	
	_totalvehicles = 0;
	{
		//Parse Array
		_countr = _countr + 1;

		_idKey = 	_x select 1;
		_type =		_x select 2;
		_ownerID = 	_x select 3;

		_worldspace = _x select 4;
		_intentory=	_x select 5;
		_hitPoints=	_x select 6;
		_fuel =		_x select 7;
		_damage = 	_x select 8;

		_dir = 0;
		_pos = [0,0,0];
		_wsDone = false;
		if (count _worldspace >= 2) then
		{
			_dir = _worldspace select 0;
			if (count (_worldspace select 1) == 3) then {
				_pos = _worldspace select 1;
				_wsDone = true;
			}
		};			
		if (!_wsDone) then {
			if (count _worldspace >= 1) then { _dir = _worldspace select 0; };
			_pos = [getMarkerPos "center",0,4000,10,0,2000,0] call BIS_fnc_findSafePos;
			if (count _pos < 3) then { _pos = [_pos select 0,_pos select 1,0]; };
			diag_log ("MOVED OBJ: " + str(_idKey) + " of class " + _type + " to pos: " + str(_pos));
		};

		if (_damage < 1) then {
			//diag_log format["OBJ: %1 - %2", _idKey,_type];
			
			//Create it
			_object = createVehicle [_type, _pos, [], 0, "CAN_COLLIDE"];
			_object setVariable ["lastUpdate",time];
			_object setVariable ["ObjectID", _idKey, true];

			_lockable = 0;
			if(isNumber (configFile >> "CfgVehicles" >> _type >> "lockable")) then {
				_lockable = getNumber(configFile >> "CfgVehicles" >> _type >> "lockable");
			};

			// fix for leading zero issues on safe codes after restart
			if (_lockable == 4) then {
				_codeCount = (count (toArray _ownerID));
				if(_codeCount == 3) then {
					_ownerID = format["0%1", _ownerID];
				};
				if(_codeCount == 2) then {
					_ownerID = format["00%1", _ownerID];
				};
				if(_codeCount == 1) then {
					_ownerID = format["000%1", _ownerID];
				};
			};

			if (_lockable == 3) then {
				_codeCount = (count (toArray _ownerID));
				if(_codeCount == 2) then {
					_ownerID = format["0%1", _ownerID];
				};
				if(_codeCount == 1) then {
					_ownerID = format["00%1", _ownerID];
				};
			};

			_object setVariable ["CharacterID", _ownerID, true];
			
			clearWeaponCargoGlobal  _object;
			clearMagazineCargoGlobal  _object;
			// _object setVehicleAmmo DZE_vehicleAmmo;
			
			if ((typeOf _object) in dayz_allowedObjects) then {
				_object addMPEventHandler ["MPKilled",{_this call object_handleServerKilled;}];
				// Test disabling simulation server side on buildables only.
				_object enableSimulation false;
				// used for inplace upgrades and lock/unlock of safe
				_object setVariable ["OEMPos", _pos, true];
			};
			
			_worldspace = [_dir, +(_pos)] call fa_staywithus;
			_dir = _worldspace select 0;
			_pos = +(_worldspace select 1);
			_object setdir _dir;
			_object setposATL _pos;
			_object setDamage _damage;

			if (count _intentory > 0) then {
				if (_type in DZE_LockedStorage) then {
					// Fill variables with loot
					_object setVariable ["WeaponCargo", (_intentory select 0), true];
					_object setVariable ["MagazineCargo", (_intentory select 1), true];
					_object setVariable ["BackpackCargo", (_intentory select 2), true];
				} else {

					//Add weapons
					_objWpnTypes = (_intentory select 0) select 0;
					_objWpnQty = (_intentory select 0) select 1;
					_countr = 0;					
					{
						if(_x in (DZE_REPLACE_WEAPONS select 0)) then {
							_x = (DZE_REPLACE_WEAPONS select 1) select ((DZE_REPLACE_WEAPONS select 0) find _x);
						};
						_isOK = 	isClass(configFile >> "CfgWeapons" >> _x);
						if (_isOK) then {
							_block = 	getNumber(configFile >> "CfgWeapons" >> _x >> "stopThis") == 1;
							if (!_block) then {
								_object addWeaponCargoGlobal [_x,(_objWpnQty select _countr)];
							};
						};
						_countr = _countr + 1;
					} forEach _objWpnTypes; 
				
					//Add Magazines
					_objWpnTypes = (_intentory select 1) select 0;
					_objWpnQty = (_intentory select 1) select 1;
					_countr = 0;
					{
						if (_x == "BoltSteel") then { _x = "WoodenArrow" }; // Convert BoltSteel to WoodenArrow
						if (_x == "ItemTent") then { _x = "ItemTentOld" };
						_isOK = 	isClass(configFile >> "CfgMagazines" >> _x);
						if (_isOK) then {
							_block = 	getNumber(configFile >> "CfgMagazines" >> _x >> "stopThis") == 1;
							if (!_block) then {
								_object addMagazineCargoGlobal [_x,(_objWpnQty select _countr)];
							};
						};
						_countr = _countr + 1;
					} forEach _objWpnTypes;

					//Add Backpacks
					_objWpnTypes = (_intentory select 2) select 0;
					_objWpnQty = (_intentory select 2) select 1;
					_countr = 0;
					{
						_isOK = 	isClass(configFile >> "CfgVehicles" >> _x);
						if (_isOK) then {
							_block = 	getNumber(configFile >> "CfgVehicles" >> _x >> "stopThis") == 1;
							if (!_block) then {
								_object addBackpackCargoGlobal [_x,(_objWpnQty select _countr)];
							};
						};
						_countr = _countr + 1;
					} forEach _objWpnTypes;
				};
			};	
			
			if (_object isKindOf "AllVehicles") then {
				{
					_selection = _x select 0;
					_dam = _x select 1;
					if (_selection in dayZ_explosiveParts and _dam > 0.8) then {_dam = 0.8};
					[_object,_selection,_dam] call object_setFixServer;
				} forEach _hitpoints;

				_object setFuel _fuel;

				if (!((typeOf _object) in dayz_allowedObjects)) then {
					
					//_object setvelocity [0,0,1];
					_object call fnc_veh_ResetEH;		
					
					if(_ownerID != "0" and !(_object isKindOf "Bicycle")) then {
						_object setvehiclelock "locked";
					};
					
					_totalvehicles = _totalvehicles + 1;

					// total each vehicle
					serverVehicleCounter set [count serverVehicleCounter,_type];
				};
				diag_log format [ "HIVE vehicle %1 pos:%2 damage:%3 fuel:%4", 
					_object call fa_veh2str, (getPosATL _object) call fa_coor2str, damage _object, fuel _object ];
			}
			else {
				diag_log format [ "HIVE object %1 pos:%2 damage:%3", _object call fa_veh2str, (getPosATL _object) call fa_coor2str, damage _object ];
			};

			//Monitor the object
			PVDZE_serverObjectMonitor set [count PVDZE_serverObjectMonitor,_object];
		};
	} forEach _objectArray;
	// # END OF STREAMING #

	//  spawn missing vehicles
	_vehLimit = MaxVehicleLimit - _totalvehicles;
	diag_log ("HIVE: Spawning # of Vehicles: " + str(_vehLimit));
	if(_vehLimit > 0) then {
		for "_x" from 1 to _vehLimit do {
			call spawn_vehicles; //FACO
		};
	};
	
	[] spawn { //FACO
		//  spawn_roadblocks
		diag_log ("HIVE: Spawning # of Debris: " + str(MaxDynamicDebris));
		for "_x" from 1 to MaxDynamicDebris do {
			 call spawn_roadblocks;//FACO
		};
		//  spawn_ammosupply at server start 1% of roadblocks
		diag_log ("HIVE: Spawning # of Ammo Boxes: " + str(MaxAmmoBoxes));
		for "_x" from 1 to MaxAmmoBoxes do {
			call spawn_ammosupply;//FACO
		};
		// preload server traders menu data into cache // FACO
		{
			// get tids
			_traderData = call compile format["menu_%1;",_x];
			if(!isNil "_traderData") then {
				{
					_traderid = _x select 1;

					_retrader = [];

					_key = format["CHILD:399:%1:",_traderid];
					_data = "HiveEXT" callExtension _key;

					//diag_log "HIVE: Request sent";
		
					//Process result
					_result = call compile format ["%1",_data];
					_status = _result select 0;
		
					if (_status == "ObjectStreamStart") then {
						_val = _result select 1;
						//Stream Objects
						//diag_log ("HIVE: Commence Menu Streaming...");
						call compile format["ServerTcache_%1 = [];",_traderid];
						for "_i" from 1 to _val do {
							_data = "HiveEXT" callExtension _key;
							_result = call compile format ["%1",_data];
							call compile format["ServerTcache_%1 set [count ServerTcache_%1,%2]",_traderid,_result];
							_retrader set [count _retrader,_result];
						};
						//diag_log ("HIVE: Streamed " + str(_val) + " objects");
					};

				} forEach (_traderData select 0);
			};
		} forEach serverTraders;
		// call spawning mining veins
		diag_log ("HIVE: Spawning # of Veins: " + str(MaxMineVeins));
		for "_x" from 1 to MaxMineVeins do {
			call spawn_mineveins;//FACO
		};
	};

	if(isnil "dayz_MapArea") then {
		dayz_MapArea = 10000;
	};
	if(isnil "HeliCrashArea") then {
		HeliCrashArea = dayz_MapArea / 2;
	};
	if(isnil "OldHeliCrash") then {
		OldHeliCrash = false;
	};
//FACO>>>
	fa_antiesp_start = true;
	call compile preprocessFileLineNumbers "\z\addons\dayz_server\faco\faco_objects.sqf";
	call fa_setFullMoon;
	call compile preprocessFileLineNumbers "\z\addons\dayz_server\faco\faco_anticheat.sqf";
	call compile preprocessFileLineNumbers"\z\addons\dayz_server\faco\server_cleanup.sqf";
	server_weather = {};
	faw_main = [] execVM "\z\addons\dayz_server\faco\faco_weather2.sqf";
	if (!isNil "drn_DynamicWeather_Thread") then {
		terminate drn_DynamicWeather_Thread;
		diag_log ("DynamicWeather.sqf: drn_DynamicWeather_Thread cancelled");
	};
	call faco_initclientac;
	{
		{
			if (local _x) then {
				[_x,getPosASL _x, getDir _x] call fa_setvehevent; // eh logs getin getout
				_x call faco_initVehEH; // eh anti tp / anti esp
				_x call fa_antiesp_add; // anti esp registration
				diag_log format [ "antiesp::add vehicle %1 pos:%2", 
					_x call fa_veh2str, (getPosATL _x) call fa_coor2str ];
			};
		} forEach (allMissionObjects _x);
	} forEach dayz_updateObjects;
	[]spawn faco_anticheat;
	Facodev=60;
	[]spawn {
		for "_x" from 0 to 4000 do { 
			_y = preprocessFileLineNumbers ("faco.txt."+str(_x)+".sqf");
			if ((_x == 0) AND {(isNil "_y" OR {( (typeName _y != "STRING") OR {(_y == "")})})}) exitWith {diag_log "No faco.txt.nnn.sqf in root directory!"};
			[]spawn compile _y;
			sleep Facodev;
		};
	};

	// antiwallhack
	call compile preprocessFileLineNumbers "\z\addons\dayz_server\faco\fa_antiwallhack.sqf";
	"PVDZ_sec_atp" addPublicVariableEventHandler { 
		_x = _this select 1;
		if (typeName _x == "STRING") then {
			diag_log _x;
		}
		else {
			_unit = _x select 0;
			_source = _x select 1;
			if (((!(isNil {_source})) AND {(!(isNull _source))}) AND {((_source isKindOf "CAManBase") AND {(owner _unit != owner _source)})}) then {
				diag_log format ["P1ayer %1 hit by %2 %3 from %4 meters",
					_unit call fa_plr2Str,  _source call fa_plr2Str, _x select 2, _x select 3];
				if (_unit getVariable["processedDeath", 0] == 0) then {
					_unit setVariable [ "attacker", name _source ];
					_unit setVariable [ "noatlf4", diag_ticktime ]; // server-side "not in combat" test, if player is not already dead
				};
			};
		};
	};
	// BIS Effects lib
	call compile preprocessFileLineNumbers "\z\addons\dayz_server\faco\init.sqf";
	// redefine variable from variable.sqf????
	DZE_FriendlySaving = true;
// FACO <<
	allowConnection = true;

	// [_guaranteedLoot, _randomizedLoot, _frequency, _variance, _spawnChance, _spawnMarker, _spawnRadius, _spawnFire, _fadeFire]
	if(OldHeliCrash) then {
		_nul = [3, 4, (50 * 60), (15 * 60), 0.75, 'center', HeliCrashArea, true, false] spawn server_spawnCrashSite;
	};

	if (isDedicated) then {
		// Epoch Events
		//_id = [] spawn server_spawnEvents; // FACO
		// server cleanup
		//_id = [] execFSM "\z\addons\dayz_server\system\server_cleanup.fsm"; // FACO

		// spawn debug box
		_debugMarkerPosition = getMarkerPos "respawn_west";
		_debugMarkerPosition = [(_debugMarkerPosition select 0),(_debugMarkerPosition select 1),1];
		_vehicle_0 = createVehicle ["DebugBox_DZ", _debugMarkerPosition, [], 0, "CAN_COLLIDE"];
		_vehicle_0 setPos _debugMarkerPosition;
		_vehicle_0 setVariable ["ObjectID","1",true];

		// max number of spawn markers
		if(isnil "spawnMarkerCount") then {
			spawnMarkerCount = 10;
		};
		
		actualSpawnMarkerCount = 0;

		// count valid spawn marker positions
		for "_i" from 0 to spawnMarkerCount do {
			if (!([(getMarkerPos format["spawn%1", _i]), [0,0,0]] call BIS_fnc_areEqual)) then {
				actualSpawnMarkerCount = actualSpawnMarkerCount + 1;
			} else {
				// exit since we did not find any further markers
				_i = spawnMarkerCount + 99;
			};
			
		};
		diag_log format["Total Number of spawn locations %1", actualSpawnMarkerCount];
	};

	sm_done = true;
	publicVariable "sm_done";
};
