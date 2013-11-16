/*
        Created exclusively for ArmA2:OA - Epoch DayZ Mod.
        Please request permission to use/alter/distribute from the author (facoptere@gmail.com)
*/


sc_init = {
	diag_log format ["%1: server side FSM inited...", __FILE__ ];
	scu_lootpile_state = 0;
	scu_lootpile_time = 0;
	scu_frameno = 0;
	scu_diag_tickTime = diag_tickTime;
};

sc_corpses = {
	// EVERY 2 MINUTE
	// DELETE UNCONTROLLED ZOMBIES --- PUT FLIES ON FRESH PLAYER CORPSES --- REMOVE OLD FLIES & CORPSES
	if (scu_frameno % (4*2*60) == 0) then {
		_delQtyZ = 0;
		_delQtyP = 0;
		_addFlies = 0;
		{
			if (local _x) then {
				if (_x isKindOf "zZombie_Base") then { 
					// this code is useless, Zeds are deleted by server during "local" event, when player disconnects (see ViralZeds.hpp -> zombie_agent.fsm -> zombie_findOwner.sqf)
					_x call fa_deleteVehicle;
					_delQtyZ = _delQtyZ + 1;
				}
				else {
					if (_x isKindOf "CAManBase") then {
						_deathTime = _x getVariable ["scu_deathTime", -1];
						if (_deathTime == -1) then { 
							_x call fa_antiesp_add; // character's corpse has just been found, add it to anti-ESP system
							_deathTime = diag_tickTime;
							_x setVariable ["scu_deathTime", _deathTime];
							_x setVariable ["scu_fliesAdded", true];
							_addFlies = _addFlies + 1;
						};
						if (diag_tickTime - _deathTime > 40*60) then {
							if (_x getVariable ["scu_fliesDeleted", false]) then {
								// flies have been switched off, we can delete body
								_x call fa_antiesp_checkout; // remove from anti-esp system
								_x call fa_deleteVehicle;
								_delQtyP = _delQtyP + 1;
							}
							else {
								PVCDZ_flies = [ 0, _x ];
								publicVariable "PVCDZ_flies";
								_x setVariable  ["scu_fliesDeleted", true];
								// body will be deleted at next round
							};
						}
						else {
							// remove flies on heavy rain.
							// broadcast flies status for everyone periodically
							_onoff = 1;
							if ((!isNil "faw_target") AND {(faw_target select 2 > 0.25)}) then {
								_onoff = 0;
							};
							PVCDZ_flies = [ _onoff, _x ];
							publicVariable "PVCDZ_flies";
						};
					};
				};
			};
		} forEach allDead;
		_delQtyAnimal = 0;
		{
			if (local _x) then {
				_x call dayz_perform_purge;
				_delQtyAnimal = _delQtyAnimal + 1;
			};
		} forEach _animals;
		if (_delQtyZ+_delQtyP+_addFlies > 0) then {
			diag_log format ["%1: Deleted %2 uncontrolled zombies, %5 uncontrolled animals  and %3 dead character bodies, added %4 flies", __FILE__, _delQtyZ, _delQtyP, _addFlies, _delQtyAnimal ];
		};
	};
};

sc_lootpiles = {
		// EVERY 5 MINUTES, ONE OF THESE TASKS SPACED BY 5 SECONDS:
		// LOOK FOR OLD LOOTPILES -OR- IGNORE LOOTPILES NEAR _plrBatch PLAYERS -OR- REMOVE REMAINING _chunkSize LOOTPILES 
		if (scu_frameno % (4*5) == 4) then {
			_chunkSize = 20;
			_plrBatch = 10;
			switch true do {
				case (scu_lootpile_state == 0): {  // build list of overdue loots
						if (diag_tickTime - scu_lootpile_time > 300) then {
							scu_lootpile_time = diag_tickTime;
							diag_log format ["%1: reset lootpiles check", __FILE__];
							scu_lootpile_list = [];
							scu_lootpile_lootTotal = 0;
							{
								_created = _x getVariable ["created",-1];
								if (_created == -1) then {
									_created = diag_tickTime;
									_x setVariable ["created",_created];
								};
								if (!(_x getVariable ["permaLoot",false]) AND {(diag_tickTime - _created > 1800)}) then {
									scu_lootpile_list set [ count scu_lootpile_list, _x ];
								};
								scu_lootpile_lootTotal = scu_lootpile_lootTotal + 1;
							} forEach allMissionObjects "ReammoBox";
							scu_lootpile_state = 1;
							scu_lootpile_var1 = 0;
							scu_players = +(playableUnits);
						};
						// else loop at state 0
					};
				case (scu_lootpile_state == 1): { // forEach players -> ignore nearby loot
						_imax = (count scu_players) min (scu_lootpile_var1 + _plrBatch);
						//diag_log format ["%1: lootpiles foreach players from:%2 to:%3 players:%4 old:%5 total:%6", __FILE__, scu_lootpile_var1, _imax, count scu_players, count scu_lootpile_list, scu_lootpile_lootTotal ];
						for "_i" from scu_lootpile_var1 to _imax-1 do {
							_plr = (scu_players select _i);
							if (!(isNull _plr) AND {(isPlayer _plr)}) then {
								_plr = vehicle _plr;
								{
									if (_x IN scu_lootpile_list) then {
										scu_lootpile_list = scu_lootpile_list - [_x];
									};
								} forEach ((getPosATL _plr) nearObjects ["ReammoBox",250]);
							}/*
							else {
								diag_log format [ "%1 player left? %2", __FILE__, _x ];
							}*/;
						};
						scu_lootpile_var1 = _imax;
						if (_imax == count scu_players) then { // catch the few players who entered meanwhile
							{
								if !(_x in scu_players) then { 
									scu_players set [ count scu_players, _x ];
								};
							} forEach playableUnits;
						};
						if (_imax == count scu_players) then {
							scu_lootpile_state = 2;
							scu_lootpile_var1 = 0;
							scu_lootpile_delQtyL = count scu_lootpile_list;
						};
					};
				case (scu_lootpile_state == 2): {  // forEAch remaining lootpiles -> delete 
						_imax = (scu_lootpile_delQtyL) min (scu_lootpile_var1 + _chunkSize);
						//diag_log format ["%1: lootpiles foreach loot to del from:%2 to:%3 old:%4 total:%5", __FILE__, scu_lootpile_var1, _imax, scu_lootpile_delQtyL, scu_lootpile_lootTotal ];
						for "_i" from scu_lootpile_var1 to _imax-1 do {
							_x = scu_lootpile_list select _i;
							deleteVehicle _x;
						};
						scu_lootpile_var1 = _imax;
						if (_imax == scu_lootpile_delQtyL) then {
							scu_lootpile_state = 0;
							if (scu_lootpile_delQtyL > 0) then {
								diag_log format ["%1: deleted %2 lootpiles from %3 total", __FILE__, scu_lootpile_delQtyL, scu_lootpile_lootTotal ];
							};
						};
					};
			};
		};		
};

sc_playershivewrite = {
		// EVERY 1 MINUTE
		// FORCE HIVE WRITE FOR PLAYERS WHO NEED IT (HUMANITY OR POSITION OR TIMEOUT CHANGE)
		if (scu_frameno % (4*60) == 8) then {
			_n = 0;
			{
				if ((isPlayer _x) AND {(alive _x)}) then {
					_damage = _x getVariable [ "USEC_BloodQty", -1 ];
					if (_damage >= 0) then { // not a character?
						_pos = eyePos _x; // genuine position, deals with player in vehicle or not
						_otime = _x getVariable [ "scu_sync_time", -1];
						_opos = _x getVariable [ "scu_sync_pos", _pos];
						_odamage = _x getVariable [ "scu_sync_dmg", _damage];	
						if (_otime == -1) then { 
							_otime = diag_tickTime;
							_x setVariable [ "scu_sync_time", _otime];
							_x setVariable [ "scu_sync_pos", _opos];
							_x setVariable [ "scu_sync_dmg", _odamage];
						};
						if ((diag_tickTime - _otime > 600) OR {((_pos distance _opos > 50) OR {(_odamage != _damage)})}) then {
							[_x, nil, true] call server_playerSync;
							_x setVariable [ "scu_sync_time", diag_tickTime];
							_x setVariable [ "scu_sync_pos", _pos];
							_x setVariable [ "scu_sync_dmg", _damage];
							_n = _n + 1;	
						};
					};
				};
			} forEach playableUnits;
			if (_n > 0) then {
				diag_log format ["%1: sync'ed %2 players to HIVE", __FILE__, _n];
			};
		};
};

sc_vehicleshivewrite = {
		// EVERY 1 MINUTE
		// FORCE HIVE WRITE FOR VEHICLES WHO NEED IT (DAMAGE OR POSITION OR TIMEOUT CHANGE)
		if (scu_frameno % (4*60) == 12) then {
			_n = 0;
			{
				if (_x isKindOf "AllVehicles") then {
					_damage = damage _x;
					_pos = getPosASL _x;
					_otime = _x getVariable [ "scu_sync_time", -1];
					_opos = _x getVariable [ "scu_sync_pos", _pos];
					_odamage = _x getVariable [ "scu_sync_dmg", _damage];	
					if (_otime == -1) then { 
						_otime = diag_tickTime;
						_x setVariable [ "scu_sync_time", _otime];
						_x setVariable [ "scu_sync_pos", _opos];
						_x setVariable [ "scu_sync_dmg", _odamage];	
					};
					if ((diag_tickTime - _otime > 600) OR {((_pos distance _opos > 50) OR {(_odamage != _damage)})}) then {
						_x setVariable [ "scu_sync_time", diag_tickTime];
						_x setVariable [ "scu_sync_pos", _pos];
						_x setVariable [ "scu_sync_dmg", _damage];	
						[_x, "all", true] call server_updateObject;
						_n = _n + 1;	
					}/*
					else {
				diag_log format ["%1: veh %2   %3 %4 %5", __FILE__, _x, _otime, _opos, _odamage];
					}*/;
				};
			} forEach vehicles;		
			if (_n > 0) then {
				diag_log format ["%1: sync'ed %2 vehicles to HIVE", __FILE__, _n];
			};
		};
		//diag_log str scu_frameno;
};

sc_traps = {/*
		// EVERY 5 SECONDS
		// CHECK TRAPS STATE
		if (scu_frameno % (4*5) == 16) then {	
			_n = 0;
			{
				if ((isNil "_x") OR {(isNull _x)}) then {
					dayz_traps = dayz_traps - [_x];
				}
				else {
					if (_x getVariable ["armed", false]) then {
						if !(_x in dayz_traps_active) then {
							["arm", _x] call compile getText (configFile >> "CfgVehicles" >> typeOf _x >> "script");
							if !(_x in dayz_traps_active) then { dayz_traps_active set [ count dayz_traps_active, _x ]; };
							_n = _n + 1;
						};
					} else {
						if (_x in dayz_traps_active) then {
							["disarm", _x] call compile getText (configFile >> "CfgVehicles" >> typeOf _x >> "script");
							if (_x in dayz_traps_active) then { dayz_traps_active = dayz_traps_active - [_x]; };
							_n = _n + 1;
						};
					};
				};
			} forEach dayz_traps;
			if (_n > 0) then {
				diag_log format ["%1: traps polling, changed %2 states", __FILE__, _n];
			};
		};	*/
};

sc_timesync = {
		// EVERY 15 MINUTES
		// RESYNC TIME WITH HIVE DLL SYSTEM CALL
		if (scu_frameno % (4*60*15) == 20) then {
			diag_log format ["%1: resync time from HIVE DLL. FPS: %2", __FILE__, diag_fps];
			call fa_setFullMoon;
		};
};	

// (see ViralZeds.hpp -> zombie_agent.fsm -> zombie_findOwner.sqf), called when a zombie becomes "local" to the server after the player disconnected
zombie_findOwner = {
	(_this select 0) call fa_deleteVehicle;
};

objNull execFSM  "\z\addons\dayz_server\faco\server_cleanup.fsm";
